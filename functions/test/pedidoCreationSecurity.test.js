const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('pedidos_createSecure targeted provider eligibility', function () {
  this.timeout(300000);

  const db = __test__.getDb();
  const { createSecurePedidoCore, reviewPedidoServiceCore } = __test__.pedidos;
  const legalVersion = __test__.legal.LEGAL_DOCUMENT_VERSION;
  const clientAuth = {
    uid: 'client-targeted-create',
    token: { phone_number: '+258840000101' },
  };
  const adminAuth = {
    uid: 'admin-targeted-create',
    token: { admin: true },
  };
  const collections = [
    'pedidos',
    'service_moderation_queue',
    'service_catalog_policies',
    'provider_public',
    'provider_private',
    'provider_dispatch_private',
    'pilot_participants',
    'users_private',
  ];

  async function clearCollection(name) {
    const snapshot = await db.collection(name).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }

  async function seedProvider(uid, overrides = {}) {
    const {
      public: publicOverrides = {},
      private: privateOverrides = {},
      dispatch: dispatchOverrides = {},
      participant: participantOverrides = {},
      user: userOverrides = {},
    } = overrides;
    await Promise.all([
      db.collection('provider_public').doc(uid).set({
        uid,
        isSearchable: true,
        servicos: ['plumbing'],
        ...publicOverrides,
      }),
      db.collection('provider_private').doc(uid).set({
        providerId: uid,
        financialStatus: 'active',
        ...privateOverrides,
      }),
      db.collection('provider_dispatch_private').doc(uid).set({
        providerId: uid,
        acceptingNewJobs: true,
        ...dispatchOverrides,
      }),
      db.collection('pilot_participants').doc(uid).set({
        status: 'active',
        roles: ['prestador'],
        city: 'Maputo',
        ...participantOverrides,
      }),
      db.collection('users_private').doc(uid).set({
        phoneVerified: true,
        accountStatus: 'active',
        legalConsent: {
          version: legalVersion,
          termsAccepted: true,
          privacyAccepted: true,
          ageConfirmed: true,
        },
        ...userOverrides,
      }),
    ]);
  }

  function pedidoData(providerId) {
    return {
      prestadorId: providerId,
      servicoId: 'plumbing',
      titulo: 'Reparacao de canalizacao',
      descricao: 'A torneira precisa de reparacao.',
      modo: 'IMEDIATO',
      tipoPreco: 'a_combinar',
      tipoPagamento: 'dinheiro',
      anexos: [],
    };
  }

  async function createTargeted(providerId, auth = clientAuth) {
    return createSecurePedidoCore({
      database: db,
      auth,
      data: pedidoData(providerId),
    });
  }

  async function assertNoPedidoCreated() {
    const snapshot = await db.collection('pedidos').get();
    assert.strictEqual(snapshot.empty, true, 'a failed invitation must not create a pedido');
  }

  beforeEach(async () => {
    for (const collection of collections) await clearCollection(collection);
    await db.collection('service_catalog_policies').doc('plumbing').set({
      isActive: true,
      name: 'Canalizacao',
      riskLevel: 'normal',
      approvalRequired: false,
    });
  });

  it('creates the targeted invitation only for a fully eligible provider', async () => {
    await seedProvider('provider-eligible');

    const result = await createTargeted('provider-eligible');
    const pedido = (await db.collection('pedidos').doc(result.pedidoId).get()).data();

    assert.strictEqual(pedido.prestadorId, 'provider-eligible');
    assert.strictEqual(pedido.status, 'aguarda_resposta_prestador');
    assert.strictEqual(pedido.moderationStatus, 'approved');
  });

  it('does not create an invitation for an offboarded pilot provider', async () => {
    await seedProvider('provider-offboarded', {
      participant: { status: 'inactive' },
    });

    await assert.rejects(
      () => createTargeted('provider-offboarded'),
      (error) => error.code === 'permission-denied',
    );
    await assertNoPedidoCreated();
  });

  it('does not create an invitation for a provider ineligible for the service', async () => {
    await seedProvider('provider-wrong-service', {
      public: { servicos: ['electrical'] },
    });

    await assert.rejects(
      () => createTargeted('provider-wrong-service'),
      (error) => error.code === 'failed-precondition',
    );
    await assertNoPedidoCreated();
  });

  it('does not create a self-dealing invitation', async () => {
    await seedProvider(clientAuth.uid);

    await assert.rejects(
      () => createTargeted(clientAuth.uid),
      (error) => error.code === 'invalid-argument',
    );
    await assertNoPedidoCreated();
  });

  it('does not create an invitation without an authoritative verified phone', async () => {
    await seedProvider('provider-no-phone', {
      user: { phoneVerified: false },
    });

    await assert.rejects(
      () => createTargeted('provider-no-phone'),
      (error) => error.code === 'failed-precondition',
    );
    await assertNoPedidoCreated();
  });

  it('does not create an invitation while new work is financially suspended', async () => {
    await seedProvider('provider-suspended', {
      private: { financialStatus: 'suspended_new_jobs' },
    });

    await assert.rejects(
      () => createTargeted('provider-suspended'),
      (error) => error.code === 'failed-precondition',
    );
    await assertNoPedidoCreated();
  });

  it('does not create an invitation when dispatch has disabled new work', async () => {
    await seedProvider('provider-dispatch-disabled', {
      dispatch: { acceptingNewJobs: false },
    });

    await assert.rejects(
      () => createTargeted('provider-dispatch-disabled'),
      (error) => error.code === 'failed-precondition',
    );
    await assertNoPedidoCreated();
  });

  it('revalidates an approved moderated target before generating its invitation', async () => {
    await seedProvider('provider-moderated', {
      public: { servicos: ['custom_servico_personalizado'] },
    });
    const created = await createSecurePedidoCore({
      database: db,
      auth: clientAuth,
      data: {
        prestadorId: 'provider-moderated',
        titulo: 'Servico personalizado',
        descricao: 'Atividade local sujeita a revisao.',
        modo: 'IMEDIATO',
        tipoPreco: 'a_combinar',
        tipoPagamento: 'dinheiro',
        isCustomService: true,
        customServiceName: 'Servico personalizado',
        customServiceDescription: 'Atividade local a combinar.',
        anexos: [],
      },
    });
    const pending = (await db.collection('pedidos').doc(created.pedidoId).get()).data();
    assert.strictEqual(pending.prestadorId, null);
    assert.strictEqual(pending.requestedProviderId, 'provider-moderated');

    await db.collection('pilot_participants').doc('provider-moderated').update({
      status: 'inactive',
    });
    await assert.rejects(
      () => reviewPedidoServiceCore({
        database: db,
        auth: adminAuth,
        data: {
          pedidoId: created.pedidoId,
          decision: 'approved',
          contentRevision: 1,
        },
      }),
      (error) => error.code === 'permission-denied',
    );
    const unchanged = (await db.collection('pedidos').doc(created.pedidoId).get()).data();
    assert.strictEqual(unchanged.moderationStatus, 'pending_review');
    assert.strictEqual(unchanged.prestadorId, null);
  });

  it('revokes every stale grant marker when moderation creates an invitation', async () => {
    await seedProvider('provider-reviewed', {
      public: { servicos: ['custom_servico_personalizado'] },
    });
    const created = await createSecurePedidoCore({
      database: db,
      auth: clientAuth,
      data: {
        prestadorId: 'provider-reviewed',
        titulo: 'Servico personalizado',
        descricao: 'Atividade local sujeita a revisao.',
        modo: 'IMEDIATO',
        tipoPreco: 'a_combinar',
        tipoPagamento: 'dinheiro',
        isCustomService: true,
        customServiceName: 'Servico personalizado',
        customServiceDescription: 'Atividade local a combinar.',
        anexos: [],
      },
    });
    await db.collection('pedidos').doc(created.pedidoId).update({
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider-reviewed',
      providerAccessGrantedAt: new Date(),
    });

    await reviewPedidoServiceCore({
      database: db,
      auth: adminAuth,
      data: {
        pedidoId: created.pedidoId,
        decision: 'approved',
        contentRevision: 1,
      },
    });

    const reviewed = (await db.collection('pedidos').doc(created.pedidoId).get()).data();
    assert.strictEqual(reviewed.prestadorId, 'provider-reviewed');
    assert.strictEqual(reviewed.status, 'aguarda_resposta_prestador');
    assert.strictEqual(reviewed.providerAccessGranted, false);
    assert.strictEqual(reviewed.providerAccessGrantedTo, null);
    assert.strictEqual(reviewed.providerAccessGrantedAt, null);
  });
});
