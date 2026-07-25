const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('Pedido moderation content revisions', function () {
  this.timeout(300000);

  const originalMarketId = process.env.PILOT_MARKET_ID;
  const originalCurrency = process.env.DEFAULT_CURRENCY_CODE;
  const db = __test__.getDb();
  const {
    createSecurePedidoCore,
    reviewPedidoServiceCore,
    updateSecurePedidoCore,
  } = __test__.pedidos;
  const clientAuth = {
    uid: 'client-revision',
    token: { phone_number: '+351910000001' },
  };
  const adminAuth = {
    uid: 'admin-revision',
    token: { admin: true },
  };
  const collections = [
    'pedidos',
    'service_moderation_queue',
    'adminAuditLogs',
  ];

  function customPedidoData(overrides = {}) {
    return {
      titulo: 'Apoio personalizado',
      descricao: 'Pedido sujeito a revisao humana.',
      modo: 'IMEDIATO',
      tipoPreco: 'a_combinar',
      tipoPagamento: 'dinheiro',
      isCustomService: true,
      customServiceName: 'Servico personalizado',
      customServiceDescription: 'Atividade local a combinar.',
      latitude: -25.9692,
      longitude: 32.5732,
      zoneId: 'maputo',
      anexos: [],
      ...overrides,
    };
  }

  async function createPendingPedido(overrides = {}) {
    return createSecurePedidoCore({
      database: db,
      auth: clientAuth,
      data: customPedidoData(overrides),
    });
  }

  beforeEach(async () => {
    process.env.PILOT_MARKET_ID = 'mz-maputo';
    process.env.DEFAULT_CURRENCY_CODE = 'MZN';
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  after(() => {
    if (originalMarketId === undefined) delete process.env.PILOT_MARKET_ID;
    else process.env.PILOT_MARKET_ID = originalMarketId;
    if (originalCurrency === undefined) delete process.env.DEFAULT_CURRENCY_CODE;
    else process.env.DEFAULT_CURRENCY_CODE = originalCurrency;
  });

  it('initializes the pedido and moderation queue at the same revision', async () => {
    const result = await createPendingPedido();
    const [pedidoSnap, queueSnap] = await Promise.all([
      db.collection('pedidos').doc(result.pedidoId).get(),
      db.collection('service_moderation_queue').doc(result.pedidoId).get(),
    ]);

    assert.strictEqual(result.contentRevision, 1);
    assert.strictEqual(pedidoSnap.data().contentRevision, 1);
    assert.strictEqual(queueSnap.data().contentRevision, 1);
    assert.strictEqual(queueSnap.data().status, 'pending_review');
  });

  it('increments pedido and queue revisions atomically on an editable update', async () => {
    const created = await createPendingPedido();
    const result = await updateSecurePedidoCore({
      database: db,
      auth: clientAuth,
      data: customPedidoData({
        pedidoId: created.pedidoId,
        titulo: 'Apoio personalizado atualizado',
      }),
    });
    const [pedidoSnap, queueSnap] = await Promise.all([
      db.collection('pedidos').doc(created.pedidoId).get(),
      db.collection('service_moderation_queue').doc(created.pedidoId).get(),
    ]);

    assert.strictEqual(result.contentRevision, 2);
    assert.strictEqual(pedidoSnap.data().contentRevision, 2);
    assert.strictEqual(queueSnap.data().contentRevision, 2);
    assert.strictEqual(pedidoSnap.data().titulo, 'Apoio personalizado atualizado');
    assert.strictEqual(queueSnap.data().status, 'pending_review');
  });

  it('rejects an edit when provider access was granted after the initial state', async () => {
    const created = await createPendingPedido();
    await db.collection('pedidos').doc(created.pedidoId).update({
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider-revision',
      providerAccessGrantedAt: new Date(),
    });

    await assert.rejects(
      () => updateSecurePedidoCore({
        database: db,
        auth: clientAuth,
        data: customPedidoData({
          pedidoId: created.pedidoId,
          titulo: 'Alteracao depois do grant',
        }),
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('prevents concurrent edits from silently overwriting each other', async () => {
    const created = await createPendingPedido();
    const updates = await Promise.allSettled([
      updateSecurePedidoCore({
        database: db,
        auth: clientAuth,
        data: customPedidoData({ pedidoId: created.pedidoId, titulo: 'Primeira versao' }),
      }),
      updateSecurePedidoCore({
        database: db,
        auth: clientAuth,
        data: customPedidoData({ pedidoId: created.pedidoId, titulo: 'Segunda versao' }),
      }),
    ]);
    const fulfilled = updates.filter((result) => result.status === 'fulfilled');
    const rejected = updates.filter((result) => result.status === 'rejected');
    const pedido = (await db.collection('pedidos').doc(created.pedidoId).get()).data();
    const queue = (await db.collection('service_moderation_queue').doc(created.pedidoId).get()).data();

    assert.strictEqual(fulfilled.length, 1);
    assert.strictEqual(rejected.length, 1);
    assert.strictEqual(rejected[0].reason.code, 'failed-precondition');
    assert.strictEqual(pedido.contentRevision, 2);
    assert.strictEqual(queue.contentRevision, 2);
  });

  it('refuses moderation when queue and pedido revisions differ', async () => {
    const created = await createPendingPedido();
    await db.collection('pedidos').doc(created.pedidoId).update({ contentRevision: 2 });

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
      (error) => error.code === 'failed-precondition',
    );
    const pedido = (await db.collection('pedidos').doc(created.pedidoId).get()).data();
    assert.strictEqual(pedido.moderationStatus, 'pending_review');
  });

  it('refuses a stale review and approves only the revision actually reviewed', async () => {
    const created = await createPendingPedido();
    await updateSecurePedidoCore({
      database: db,
      auth: clientAuth,
      data: customPedidoData({
        pedidoId: created.pedidoId,
        titulo: 'Conteudo revisto na versao dois',
      }),
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
      (error) => error.code === 'failed-precondition',
    );

    const result = await reviewPedidoServiceCore({
      database: db,
      auth: adminAuth,
      data: {
        pedidoId: created.pedidoId,
        decision: 'approved',
        contentRevision: 2,
      },
    });
    const [pedidoSnap, queueSnap, auditSnap] = await Promise.all([
      db.collection('pedidos').doc(created.pedidoId).get(),
      db.collection('service_moderation_queue').doc(created.pedidoId).get(),
      db.collection('adminAuditLogs').where('targetId', '==', created.pedidoId).get(),
    ]);

    assert.strictEqual(result.contentRevision, 2);
    assert.strictEqual(pedidoSnap.data().moderationStatus, 'approved');
    assert.strictEqual(pedidoSnap.data().contentRevision, 2);
    assert.strictEqual(queueSnap.data().status, 'approved');
    assert.strictEqual(queueSnap.data().contentRevision, 2);
    assert.strictEqual(auditSnap.size, 1);
    assert.strictEqual(auditSnap.docs[0].data().metadata.contentRevision, '2');
  });
});
