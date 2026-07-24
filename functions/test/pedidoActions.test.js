const assert = require('assert');
const { GeoPoint, Timestamp } = require('firebase-admin/firestore');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('pedidos_applyActionSecure', () => {
  const db = __test__.getDb();
  const {
    acceptPedidoDispatchCore,
    applyPedidoActionSecureCore,
    matchPedidoToProvidersCore,
    opportunityDocumentId,
    syncProviderActiveClients,
  } = __test__.pedidos;
  const legalVersion = __test__.legal.LEGAL_DOCUMENT_VERSION;
  const collections = [
    'pedidos',
    'provider_public',
    'provider_private',
    'provider_dispatch_private',
    'provider_opportunities',
    'provider_acceptance_limits',
    'pilot_participants',
    'users_private',
  ];

  const phoneAuth = (uid) => ({
    uid,
    token: { phone_number: '+258840000001' },
  });

  async function clearCollection(name) {
    const snapshot = await db.collection(name).get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }

  async function seedActor(uid, roles) {
    await Promise.all([
      db.collection('users_private').doc(uid).set({
        legalConsent: {
          version: legalVersion,
          termsAccepted: true,
          privacyAccepted: true,
          ageConfirmed: true,
        },
      }),
      db.collection('pilot_participants').doc(uid).set({
        status: 'active',
        roles: Array.isArray(roles) ? roles : [roles],
        city: 'Maputo',
      }),
    ]);
  }

  async function seedProvider(uid, serviceId = 'plumbing') {
    const latitude = -25.9653;
    const longitude = 32.5892;
    await Promise.all([
      db.collection('provider_public').doc(uid).set({
        uid,
        isSearchable: true,
        servicos: [serviceId],
      }),
      db.collection('provider_private').doc(uid).set({
        providerId: uid,
        financialStatus: 'active',
      }),
      db.collection('provider_dispatch_private').doc(uid).set({
        providerId: uid,
        acceptingRequests: true,
        acceptingNewJobs: true,
        isOnline: true,
        servicos: [serviceId],
        radiusKm: 10,
        lastLocation: { lat: latitude, lng: longitude },
        geo: {
          geohash: 'kerhm9',
          geopoint: new GeoPoint(latitude, longitude),
        },
        lastLocationAt: Timestamp.now(),
      }),
    ]);
  }

  async function seedPedido(id, overrides = {}) {
    await db.collection('pedidos').doc(id).set({
      clienteId: 'client1',
      prestadorId: null,
      providerAccessGranted: false,
      providerAccessGrantedTo: null,
      providerAccessGrantedAt: null,
      servicoId: 'plumbing',
      servicoNome: 'Canalizacao',
      moderationStatus: 'approved',
      status: 'criado',
      estado: 'criado',
      statusProposta: 'nenhuma',
      statusConfirmacaoValor: 'nenhum',
      tipoPreco: 'a_combinar',
      tipoPagamento: 'dinheiro',
      latitude: -25.9654,
      longitude: 32.5893,
      geo: {
        geohash: 'kerhm9',
        geopoint: new GeoPoint(-25.9654, 32.5893),
      },
      historico: [],
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      ...overrides,
    });
  }

  async function seedOpportunity(pedidoId, providerId, overrides = {}) {
    await db.collection('provider_opportunities')
      .doc(opportunityDocumentId(pedidoId, providerId)).set({
      pedidoId,
      providerId,
      approximateDistanceKm: 2,
      matchedRadiusKm: 10,
      channel: 'matching_push',
      status: 'active',
      expiresAt: Timestamp.fromMillis(Date.now() + 15 * 60 * 1000),
      deliveredAt: Timestamp.now(),
      ...overrides,
    });
  }

  async function apply(uid, data, options = {}) {
    return applyPedidoActionSecureCore({
      database: db,
      auth: options.auth || phoneAuth(uid),
      data,
      now: options.now || Timestamp.now(),
    });
  }

  beforeEach(async () => {
    for (const collection of collections) await clearCollection(collection);
  });

  it('grants all private-access fields on open and invited acceptance only', async () => {
    await Promise.all([
      seedActor('provider1', 'prestador'),
      seedProvider('provider1'),
      seedPedido('open_accept'),
      seedOpportunity('open_accept', 'provider1'),
      seedPedido('invite_accept', {
        clienteId: 'client2',
        prestadorId: 'provider1',
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
      }),
      seedPedido('legacy_inconsistent', {
        clienteId: 'client-secret',
        prestadorId: 'provider1',
        providerAccessGranted: false,
        providerAccessGrantedTo: null,
        providerAccessGrantedAt: null,
        status: 'aceito',
        estado: 'aceito',
      }),
    ]);
    const staleOpenPedido = (
      await db.collection('pedidos').doc('open_accept').get()
    ).data();

    await acceptPedidoDispatchCore({
      database: db,
      auth: phoneAuth('provider1'),
      pedidoId: 'open_accept',
    });
    await acceptPedidoDispatchCore({
      database: db,
      auth: phoneAuth('provider1'),
      pedidoId: 'invite_accept',
    });
    const replayNotifications = [];
    const staleReplay = await matchPedidoToProvidersCore({
      database: db,
      pedidoId: 'open_accept',
      pedido: staleOpenPedido,
      now: Timestamp.now(),
      notifyProvider: async (providerId) => replayNotifications.push(providerId),
    });
    assert.strictEqual(staleReplay.reason, 'pedido_not_open');
    assert.deepStrictEqual(staleReplay.providerIds, []);
    assert.deepStrictEqual(replayNotifications, []);
    assert.strictEqual(
      (await db.collection('pedido_dispatch').doc('open_accept').get()).exists,
      false,
    );

    for (const pedidoId of ['open_accept', 'invite_accept']) {
      const pedido = (await db.collection('pedidos').doc(pedidoId).get()).data();
      assert.strictEqual(pedido.prestadorId, 'provider1');
      assert.strictEqual(pedido.providerAccessGranted, true);
      assert.strictEqual(pedido.providerAccessGrantedTo, 'provider1');
      assert.ok(pedido.providerAccessGrantedAt.toMillis() > 0);
      assert.strictEqual(pedido.status, 'aceito');
    }
    const activeClients = (
      await db.collection('provider_dispatch_private').doc('provider1').get()
    ).data().activeClientIds.sort();
    assert.deepStrictEqual(activeClients, ['client1', 'client2']);
    assert.strictEqual(
      (await db.collection('provider_opportunities')
        .doc(opportunityDocumentId('open_accept', 'provider1')).get())
        .data().status,
      'accepted',
    );
  });

  it('revalidates fresh current location and radius instead of trusting opportunity distance', async () => {
    await Promise.all([
      seedActor('provider1', 'prestador'),
      seedProvider('provider1'),
      seedPedido('without_opportunity'),
      seedPedido('expired_opportunity'),
      seedPedido('moved_outside_radius'),
      seedPedido('stale_location'),
      seedPedido('offline_provider'),
      seedOpportunity('expired_opportunity', 'provider1', {
        expiresAt: Timestamp.fromMillis(Date.now() - 1000),
      }),
      seedOpportunity('moved_outside_radius', 'provider1'),
      seedOpportunity('stale_location', 'provider1'),
      seedOpportunity('offline_provider', 'provider1'),
    ]);

    for (const pedidoId of ['without_opportunity', 'expired_opportunity']) {
      await assert.rejects(
        () => acceptPedidoDispatchCore({
          database: db,
          auth: phoneAuth('provider1'),
          pedidoId,
        }),
        (error) => error.code === 'permission-denied',
      );
    }

    await db.collection('provider_dispatch_private').doc('provider1').update({
      lastLocation: { lat: -25.80, lng: 32.80 },
      geo: {
        geohash: 'kerm4r',
        geopoint: new GeoPoint(-25.80, 32.80),
      },
      lastLocationAt: Timestamp.now(),
    });
    await assert.rejects(
      () => acceptPedidoDispatchCore({
        database: db,
        auth: phoneAuth('provider1'),
        pedidoId: 'moved_outside_radius',
      }),
      (error) => error.code === 'failed-precondition',
    );

    await db.collection('provider_dispatch_private').doc('provider1').update({
      lastLocation: { lat: -25.9653, lng: 32.5892 },
      geo: {
        geohash: 'kerhm9',
        geopoint: new GeoPoint(-25.9653, 32.5892),
      },
      lastLocationAt: Timestamp.fromMillis(Date.now() - 31 * 60 * 1000),
    });
    await assert.rejects(
      () => acceptPedidoDispatchCore({
        database: db,
        auth: phoneAuth('provider1'),
        pedidoId: 'stale_location',
      }),
      (error) => error.code === 'failed-precondition',
    );

    await db.collection('provider_dispatch_private').doc('provider1').update({
      lastLocationAt: Timestamp.now(),
      isOnline: false,
    });
    await assert.rejects(
      () => acceptPedidoDispatchCore({
        database: db,
        auth: phoneAuth('provider1'),
        pedidoId: 'offline_provider',
      }),
      (error) => error.code === 'failed-precondition',
    );

    for (const pedidoId of [
      'without_opportunity',
      'expired_opportunity',
      'moved_outside_radius',
      'stale_location',
      'offline_provider',
    ]) {
      const pedido = (await db.collection('pedidos').doc(pedidoId).get()).data();
      assert.strictEqual(pedido.status, 'criado');
      assert.strictEqual(pedido.providerAccessGranted, false);
    }
  });

  it('rejects suspended, inactive and non-accepting providers before an open grant', async () => {
    await Promise.all([
      seedActor('provider1', 'prestador'),
      seedProvider('provider1'),
      seedPedido('financially_suspended'),
      seedPedido('account_suspended'),
      seedPedido('not_accepting'),
      seedOpportunity('financially_suspended', 'provider1'),
      seedOpportunity('account_suspended', 'provider1'),
      seedOpportunity('not_accepting', 'provider1'),
    ]);

    await db.collection('provider_private').doc('provider1').update({
      financialStatus: 'suspended_new_jobs',
    });
    await assert.rejects(
      () => acceptPedidoDispatchCore({
        database: db,
        auth: phoneAuth('provider1'),
        pedidoId: 'financially_suspended',
      }),
      (error) => error.code === 'failed-precondition',
    );

    await db.collection('provider_private').doc('provider1').update({ financialStatus: 'active' });
    await db.collection('users_private').doc('provider1').set({
      accountStatus: 'suspended',
    }, { merge: true });
    await assert.rejects(
      () => acceptPedidoDispatchCore({
        database: db,
        auth: phoneAuth('provider1'),
        pedidoId: 'account_suspended',
      }),
      (error) => error.code === 'failed-precondition',
    );

    await db.collection('users_private').doc('provider1').set({
      accountStatus: 'active',
    }, { merge: true });
    await db.collection('provider_dispatch_private').doc('provider1').update({
      acceptingRequests: false,
    });
    await assert.rejects(
      () => acceptPedidoDispatchCore({
        database: db,
        auth: phoneAuth('provider1'),
        pedidoId: 'not_accepting',
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('filters stale, suspended and inactive providers during initial matching', async () => {
    await Promise.all([
      seedActor('eligible', 'prestador'),
      seedActor('stale', 'prestador'),
      seedActor('financially_suspended', 'prestador'),
      seedActor('inactive', 'prestador'),
      seedProvider('eligible'),
      seedProvider('stale'),
      seedProvider('financially_suspended'),
      seedProvider('inactive'),
      seedPedido('matching_filter'),
    ]);
    await Promise.all([
      db.collection('provider_dispatch_private').doc('stale').update({
        lastLocationAt: Timestamp.fromMillis(Date.now() - 31 * 60 * 1000),
      }),
      db.collection('provider_private').doc('financially_suspended').update({
        financialStatus: 'suspended_new_jobs',
      }),
      db.collection('pilot_participants').doc('inactive').update({ status: 'inactive' }),
    ]);

    const pedido = (await db.collection('pedidos').doc('matching_filter').get()).data();
    const result = await matchPedidoToProvidersCore({
      database: db,
      pedidoId: 'matching_filter',
      pedido,
      now: Timestamp.now(),
      notifyProvider: async () => {},
    });

    assert.deepStrictEqual(result.providerIds, ['eligible']);
    const eligibleOpportunityRef = db.collection('provider_opportunities')
      .doc(opportunityDocumentId('matching_filter', 'eligible'));
    const eligibleOpportunity = await eligibleOpportunityRef.get();
    assert.strictEqual(eligibleOpportunity.exists, true);
    assert.strictEqual(eligibleOpportunity.data().status, 'active');
    for (const providerId of ['stale', 'financially_suspended', 'inactive']) {
      assert.strictEqual(
        (await db.collection('provider_opportunities')
          .doc(opportunityDocumentId('matching_filter', providerId)).get()).exists,
        false,
      );
    }

    await eligibleOpportunityRef.update({ status: 'accepted' });
    const replayNotifications = [];
    const terminalReplay = await matchPedidoToProvidersCore({
      database: db,
      pedidoId: 'matching_filter',
      pedido,
      now: Timestamp.now(),
      notifyProvider: async (providerId) => replayNotifications.push(providerId),
    });
    assert.deepStrictEqual(terminalReplay.providerIds, []);
    assert.deepStrictEqual(replayNotifications, []);
    assert.strictEqual((await eligibleOpportunityRef.get()).data().status, 'accepted');
  });

  it('paginates every valid active-client grant beyond 500 pedidos', async () => {
    await seedProvider('provider_many');
    for (let page = 0; page < 2; page += 1) {
      const batch = db.batch();
      const start = page * 500;
      const end = page === 0 ? 500 : 501;
      for (let index = start; index < end; index += 1) {
        batch.set(db.collection('pedidos').doc(`active_${String(index).padStart(3, '0')}`), {
          clienteId: `client_${index}`,
          prestadorId: 'provider_many',
          providerAccessGranted: true,
          providerAccessGrantedTo: 'provider_many',
          providerAccessGrantedAt: Timestamp.now(),
          status: 'aceito',
          estado: 'aceito',
        });
      }
      await batch.commit();
    }

    await syncProviderActiveClients(db, 'provider_many');
    const dispatch = (
      await db.collection('provider_dispatch_private').doc('provider_many').get()
    ).data();
    assert.strictEqual(dispatch.activeClientIds.length, 501);
    assert.ok(dispatch.activeClientIds.includes('client_500'));
  });

  it('limits grants per hour while preserving an offline direct invitation', async () => {
    const previousLimit = process.env.PROVIDER_ACCEPTANCES_PER_HOUR;
    process.env.PROVIDER_ACCEPTANCES_PER_HOUR = '2';
    try {
      await Promise.all([
        seedActor('provider1', 'prestador'),
        seedProvider('provider1'),
        seedPedido('quota_1'),
        seedPedido('quota_2'),
        seedPedido('quota_3'),
        seedOpportunity('quota_1', 'provider1'),
        seedOpportunity('quota_2', 'provider1'),
        seedOpportunity('quota_3', 'provider1'),
      ]);
      for (const pedidoId of ['quota_1', 'quota_2']) {
        await acceptPedidoDispatchCore({
          database: db,
          auth: phoneAuth('provider1'),
          pedidoId,
        });
      }
      await assert.rejects(
        () => acceptPedidoDispatchCore({
          database: db,
          auth: phoneAuth('provider1'),
          pedidoId: 'quota_3',
        }),
        (error) => error.code === 'resource-exhausted',
      );
      assert.strictEqual(
        (await db.collection('pedidos').doc('quota_3').get()).data().providerAccessGranted,
        false,
      );
    } finally {
      if (previousLimit == null) delete process.env.PROVIDER_ACCEPTANCES_PER_HOUR;
      else process.env.PROVIDER_ACCEPTANCES_PER_HOUR = previousLimit;
    }

    await clearCollection('provider_acceptance_limits');
    await seedPedido('offline_invite', {
      clienteId: 'client2',
      prestadorId: 'provider1',
      status: 'aguarda_resposta_prestador',
      estado: 'aguarda_resposta_prestador',
    });
    await db.collection('provider_dispatch_private').doc('provider1').update({ isOnline: false });
    await acceptPedidoDispatchCore({
      database: db,
      auth: phoneAuth('provider1'),
      pedidoId: 'offline_invite',
    });
    assert.strictEqual(
      (await db.collection('pedidos').doc('offline_invite').get()).data().providerAccessGranted,
      true,
    );
  });

  it('submits and accepts a quote with authoritative state, expiry and history', async () => {
    await Promise.all([
      seedActor('provider1', 'prestador'),
      seedActor('client1', 'cliente'),
      seedProvider('provider1'),
      seedPedido('quote_accept', { tipoPreco: 'por_orcamento' }),
    ]);

    const quoteResult = await apply('provider1', {
      action: 'provider_submit_quote',
      pedidoId: 'quote_accept',
      valorMin: 750,
      valorMax: 1000,
      mensagem: 'Inclui materiais basicos.',
      validadeMinutos: 60,
    });
    assert.strictEqual(quoteResult.status, 'aguarda_resposta_cliente');

    let pedido = (await db.collection('pedidos').doc('quote_accept').get()).data();
    assert.strictEqual(pedido.prestadorId, 'provider1');
    assert.strictEqual(pedido.statusProposta, 'pendente_cliente');
    assert.strictEqual(pedido.valorMinEstimadoPrestador, 750);
    assert.strictEqual(pedido.valorMaxEstimadoPrestador, 1000);
    assert.strictEqual(pedido.providerAccessGranted, false);
    assert.strictEqual(pedido.providerAccessGrantedTo, null);
    assert.strictEqual(pedido.providerAccessGrantedAt, null);
    assert.strictEqual(pedido.lastAuthoritativeFunction, 'pedidos_applyActionSecure');
    assert.strictEqual(pedido.historico[0].evento, 'proposta_enviada');
    assert.strictEqual(pedido.historico[0].userId, 'provider1');

    const acceptResult = await apply('client1', {
      action: 'client_accept_quote',
      pedidoId: 'quote_accept',
    });
    assert.strictEqual(acceptResult.status, 'aceito');
    pedido = (await db.collection('pedidos').doc('quote_accept').get()).data();
    assert.strictEqual(pedido.status, 'aceito');
    assert.strictEqual(pedido.statusProposta, 'aceita_cliente');
    assert.strictEqual(pedido.providerAccessGranted, true);
    assert.strictEqual(pedido.providerAccessGrantedTo, 'provider1');
    assert.ok(pedido.providerAccessGrantedAt);
    assert.strictEqual(pedido.historico[1].evento, 'proposta_aceita');
  });

  it('rejects quote renegotiation after acceptance and preserves the active grant', async () => {
    const grantedAt = Timestamp.now();
    await Promise.all([
      seedActor('provider1', 'prestador'),
      seedProvider('provider1'),
      seedPedido('accepted_quote_renegotiation', {
        tipoPreco: 'por_orcamento',
        prestadorId: 'provider1',
        status: 'aceito',
        estado: 'aceito',
        statusProposta: 'aceita_cliente',
        providerAccessGranted: true,
        providerAccessGrantedTo: 'provider1',
        providerAccessGrantedAt: grantedAt,
      }),
    ]);

    await assert.rejects(
      () => apply('provider1', {
        action: 'provider_submit_quote',
        pedidoId: 'accepted_quote_renegotiation',
        valorMin: 1200,
        valorMax: 1400,
      }),
      (error) => error.code === 'failed-precondition',
    );
    const pedido = (
      await db.collection('pedidos').doc('accepted_quote_renegotiation').get()
    ).data();
    assert.strictEqual(pedido.status, 'aceito');
    assert.strictEqual(pedido.statusProposta, 'aceita_cliente');
    assert.strictEqual(pedido.providerAccessGranted, true);
    assert.strictEqual(pedido.providerAccessGrantedTo, 'provider1');
    assert.strictEqual(pedido.providerAccessGrantedAt.toMillis(), grantedAt.toMillis());
  });

  it('rejects a pending quote and reopens the pedido without stale economics', async () => {
    await seedActor('client1', 'cliente');
    await seedPedido('quote_reject', {
      prestadorId: 'provider1',
      status: 'aguarda_resposta_cliente',
      estado: 'aguarda_resposta_cliente',
      statusProposta: 'pendente_cliente',
      valorMinEstimadoPrestador: 100,
      valorMaxEstimadoPrestador: 150,
      propostaExpiresAt: Timestamp.fromMillis(Date.now() + 3600000),
      precoFinal: 999,
      commissionPlatform: 99,
    });

    await apply('client1', {
      action: 'client_reject_quote',
      pedidoId: 'quote_reject',
    });
    const pedido = (await db.collection('pedidos').doc('quote_reject').get()).data();
    assert.strictEqual(pedido.status, 'criado');
    assert.strictEqual(pedido.prestadorId, null);
    assert.strictEqual(pedido.statusProposta, 'rejeitada_cliente');
    assert.strictEqual(pedido.precoFinal, null);
    assert.strictEqual(pedido.commissionPlatform, null);
    assert.strictEqual(pedido.historico[0].evento, 'proposta_rejeitada');
  });

  it('invites an eligible pilot provider and lets only that provider decline', async () => {
    await Promise.all([
      seedActor('client1', 'cliente'),
      seedActor('provider1', 'prestador'),
      seedProvider('provider1'),
      seedPedido('invite_decline'),
    ]);

    await apply('client1', {
      action: 'client_invite_provider',
      pedidoId: 'invite_decline',
      prestadorId: 'provider1',
    });
    let pedido = (await db.collection('pedidos').doc('invite_decline').get()).data();
    assert.strictEqual(pedido.status, 'aguarda_resposta_prestador');
    assert.strictEqual(pedido.prestadorId, 'provider1');

    await apply('provider1', {
      action: 'provider_decline_invite',
      pedidoId: 'invite_decline',
    });
    pedido = (await db.collection('pedidos').doc('invite_decline').get()).data();
    assert.strictEqual(pedido.status, 'criado');
    assert.strictEqual(pedido.prestadorId, null);
    assert.strictEqual(pedido.ultimoCancelamentoPrestadorId, 'provider1');
    assert.strictEqual(pedido.historico[1].evento, 'convite_recusado');
  });

  it('replaces a pending invited provider atomically and invalidates the old invite', async () => {
    await Promise.all([
      seedActor('client1', 'cliente'),
      seedActor('provider1', 'prestador'),
      seedActor('provider2', 'prestador'),
      seedProvider('provider1'),
      seedProvider('provider2'),
      seedPedido('invite_replace', {
        prestadorId: 'provider1',
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
        valorMinEstimadoPrestador: 400,
        valorMaxEstimadoPrestador: 500,
        statusProposta: 'pendente_cliente',
      }),
    ]);

    const result = await apply('client1', {
      action: 'client_replace_invited_provider',
      pedidoId: 'invite_replace',
      prestadorId: 'provider2',
    });
    assert.strictEqual(result.status, 'aguarda_resposta_prestador');

    const pedido = (await db.collection('pedidos').doc('invite_replace').get()).data();
    assert.strictEqual(pedido.prestadorId, 'provider2');
    assert.strictEqual(pedido.providerAccessGranted, false);
    assert.strictEqual(pedido.providerAccessGrantedTo, null);
    assert.strictEqual(pedido.providerAccessGrantedAt, null);
    assert.strictEqual(pedido.valorMinEstimadoPrestador, null);
    assert.strictEqual(pedido.valorMaxEstimadoPrestador, null);
    assert.strictEqual(pedido.statusProposta, 'nenhuma');
    assert.strictEqual(pedido.historico[0].evento, 'convite_substituido');

    await assert.rejects(
      () => apply('provider1', {
        action: 'provider_decline_invite',
        pedidoId: 'invite_replace',
      }),
      (error) => error.code === 'permission-denied',
    );
  });

  it('starts an accepted service and lets the client reject a pending final value', async () => {
    await Promise.all([
      seedActor('provider1', 'prestador'),
      seedActor('client1', 'cliente'),
    ]);
    await seedPedido('start_service', {
      prestadorId: 'provider1',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider1',
      providerAccessGrantedAt: Timestamp.now(),
      status: 'aceito',
      estado: 'aceito',
    });
    await apply('provider1', {
      action: 'provider_start_service',
      pedidoId: 'start_service',
    });
    assert.strictEqual(
      (await db.collection('pedidos').doc('start_service').get()).data().status,
      'em_andamento',
    );

    await seedPedido('reject_final', {
      prestadorId: 'provider1',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider1',
      providerAccessGrantedAt: Timestamp.now(),
      status: 'aguarda_confirmacao_valor',
      estado: 'aguarda_confirmacao_valor',
      statusConfirmacaoValor: 'pendente_cliente',
      precoPropostoPrestador: 1200,
    });
    await apply('client1', {
      action: 'client_reject_final_value',
      pedidoId: 'reject_final',
      motivo: 'O valor precisa de ser revisto.',
    });
    const rejected = (await db.collection('pedidos').doc('reject_final').get()).data();
    assert.strictEqual(rejected.status, 'em_andamento');
    assert.strictEqual(rejected.statusConfirmacaoValor, 'rejeitado_cliente');
    assert.strictEqual(rejected.precoPropostoPrestador, 1200);
  });

  it('applies client cancellation and both provider withdrawal/cancellation branches', async () => {
    await Promise.all([
      seedActor('client1', 'cliente'),
      seedActor('provider1', 'prestador'),
    ]);
    await seedPedido('client_cancel', {
      prestadorId: 'provider1',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider1',
      providerAccessGrantedAt: Timestamp.now(),
      status: 'aceito',
      estado: 'aceito',
    });
    await apply('client1', {
      action: 'client_cancel',
      pedidoId: 'client_cancel',
      motivo: 'mudanca_de_planos',
      motivoDetalhe: 'Ja nao preciso do servico.',
    });
    let pedido = (await db.collection('pedidos').doc('client_cancel').get()).data();
    assert.strictEqual(pedido.status, 'cancelado');
    assert.strictEqual(pedido.canceladoPor, 'cliente');
    assert.strictEqual(pedido.providerAccessGranted, false);
    assert.strictEqual(pedido.providerAccessGrantedTo, null);
    assert.strictEqual(pedido.providerAccessGrantedAt, null);

    await seedPedido('provider_withdraw', {
      prestadorId: 'provider1',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider1',
      providerAccessGrantedAt: Timestamp.now(),
      status: 'aceito',
      estado: 'aceito',
    });
    await apply('provider1', {
      action: 'provider_cancel',
      pedidoId: 'provider_withdraw',
      motivo: 'indisponivel',
    });
    pedido = (await db.collection('pedidos').doc('provider_withdraw').get()).data();
    assert.strictEqual(pedido.status, 'criado');
    assert.strictEqual(pedido.prestadorId, null);
    assert.strictEqual(pedido.ultimoCancelamentoPrestadorMotivo, 'indisponivel');

    await seedPedido('provider_cancel_late', {
      prestadorId: 'provider1',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider1',
      providerAccessGrantedAt: Timestamp.now(),
      status: 'em_andamento',
      estado: 'em_andamento',
    });
    await apply('provider1', {
      action: 'provider_cancel',
      pedidoId: 'provider_cancel_late',
      motivo: 'problema_tecnico',
    });
    pedido = (await db.collection('pedidos').doc('provider_cancel_late').get()).data();
    assert.strictEqual(pedido.status, 'cancelado');
    assert.strictEqual(pedido.canceladoPor, 'prestador');
    assert.strictEqual(pedido.providerAccessGranted, false);
    assert.strictEqual(pedido.providerAccessGrantedTo, null);
    assert.strictEqual(pedido.providerAccessGrantedAt, null);
  });

  it('expires every stale pending page with aligned state and revoked access', async () => {
    const now = Timestamp.now();
    const stale = Timestamp.fromMillis(now.toMillis() - 31 * 60 * 1000);
    await Promise.all([
      seedPedido('expired_1', {
        updatedAt: stale,
        providerAccessGranted: true,
        providerAccessGrantedTo: 'legacy-provider',
        providerAccessGrantedAt: stale,
      }),
      seedPedido('expired_2', { updatedAt: stale }),
      seedPedido('expired_3', {
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
        prestadorId: 'provider1',
        updatedAt: stale,
      }),
      seedPedido('fresh_pending', { updatedAt: now }),
    ]);

    const result = await __test__.pedidos.expireRequestsCore({
      database: db,
      now,
      pageSize: 2,
    });
    assert.strictEqual(result.expired, 3);
    for (const id of ['expired_1', 'expired_2', 'expired_3']) {
      const expired = (await db.collection('pedidos').doc(id).get()).data();
      assert.strictEqual(expired.status, 'cancelado');
      assert.strictEqual(expired.estado, 'cancelado');
      assert.strictEqual(expired.providerAccessGranted, false);
      assert.strictEqual(expired.providerAccessGrantedTo, null);
      assert.strictEqual(expired.providerAccessGrantedAt, null);
    }
    assert.strictEqual(
      (await db.collection('pedidos').doc('fresh_pending').get()).data().status,
      'criado',
    );
  });

  it('records no-show with the authenticated participant identity, never admin', async () => {
    const previousFlag = process.env.ENABLE_NO_SHOW_REPORTING;
    process.env.ENABLE_NO_SHOW_REPORTING = 'true';
    await Promise.all([
      seedActor('client1', 'cliente'),
      seedActor('provider1', 'prestador'),
    ]);
    await seedPedido('client_no_show', {
      prestadorId: 'provider1',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider1',
      providerAccessGrantedAt: Timestamp.now(),
      status: 'aceito',
      estado: 'aceito',
    });
    await apply('client1', {
      action: 'client_report_no_show',
      pedidoId: 'client_no_show',
      motivo: 'O prestador nao apareceu.',
    });
    let pedido = (await db.collection('pedidos').doc('client_no_show').get()).data();
    assert.strictEqual(pedido.noShowReportedBy, 'cliente');
    assert.strictEqual(pedido.historico[0].userId, 'client1');

    await seedPedido('provider_no_show', {
      prestadorId: 'provider1',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider1',
      providerAccessGrantedAt: Timestamp.now(),
      status: 'em_andamento',
      estado: 'em_andamento',
    });
    await apply('provider1', {
      action: 'provider_report_no_show',
      pedidoId: 'provider_no_show',
    });
    pedido = (await db.collection('pedidos').doc('provider_no_show').get()).data();
    assert.strictEqual(pedido.noShowReportedBy, 'prestador');
    assert.strictEqual(pedido.historico[0].userId, 'provider1');
    if (previousFlag == null) delete process.env.ENABLE_NO_SHOW_REPORTING;
    else process.env.ENABLE_NO_SHOW_REPORTING = previousFlag;
  });

  it('requires verified phone, current legal consent and the exact pilot role', async () => {
    await seedPedido('auth_guards', {
      prestadorId: 'provider1',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider1',
      providerAccessGrantedAt: Timestamp.now(),
      status: 'aceito',
      estado: 'aceito',
    });
    await seedActor('provider1', 'prestador');

    await assert.rejects(
      () => apply('provider1', {
        action: 'provider_start_service',
        pedidoId: 'auth_guards',
      }, { auth: { uid: 'provider1', token: {} } }),
      (error) => error.code === 'failed-precondition',
    );

    await db.collection('users_private').doc('provider1').delete();
    await assert.rejects(
      () => apply('provider1', {
        action: 'provider_start_service',
        pedidoId: 'auth_guards',
      }),
      (error) => error.code === 'failed-precondition',
    );

    await seedActor('provider1', 'cliente');
    await assert.rejects(
      () => apply('provider1', {
        action: 'provider_start_service',
        pedidoId: 'auth_guards',
      }),
      (error) => error.code === 'permission-denied',
    );
  });

  it('blocks hostile actors and invalid state transitions', async () => {
    await Promise.all([
      seedActor('client2', 'cliente'),
      seedActor('provider1', 'prestador'),
    ]);
    await seedPedido('hostile_actor', {
      prestadorId: 'provider1',
      status: 'aguarda_resposta_cliente',
      estado: 'aguarda_resposta_cliente',
      statusProposta: 'pendente_cliente',
      propostaExpiresAt: Timestamp.fromMillis(Date.now() + 3600000),
    });
    await assert.rejects(
      () => apply('client2', {
        action: 'client_accept_quote',
        pedidoId: 'hostile_actor',
      }),
      (error) => error.code === 'permission-denied',
    );

    await seedPedido('invalid_state', {
      prestadorId: 'provider1',
      status: 'criado',
      estado: 'criado',
    });
    await assert.rejects(
      () => apply('provider1', {
        action: 'provider_start_service',
        pedidoId: 'invalid_state',
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('rejects forged or unknown fields before any pedido mutation', async () => {
    await seedActor('client1', 'cliente');
    await seedPedido('forged_fields');
    await assert.rejects(
      () => apply('client1', {
        action: 'client_cancel',
        pedidoId: 'forged_fields',
        motivo: 'mudanca_de_planos',
        precoFinal: 1,
        historico: [{ userId: 'forged-admin' }],
      }),
      (error) => error.code === 'invalid-argument',
    );
    const pedido = (await db.collection('pedidos').doc('forged_fields').get()).data();
    assert.strictEqual(pedido.status, 'criado');
    assert.deepStrictEqual(pedido.historico, []);
  });

  it('keeps fixed-price jobs out of the quote flow and requires a full grant to start', async () => {
    await Promise.all([
      seedActor('provider1', 'prestador'),
      seedProvider('provider1'),
      seedPedido('fixed_quote'),
      seedPedido('missing_grant', {
        prestadorId: 'provider1',
        status: 'aceito',
        estado: 'aceito',
      }),
    ]);

    await assert.rejects(
      () => apply('provider1', {
        action: 'provider_submit_quote',
        pedidoId: 'fixed_quote',
        valorMin: 100,
        valorMax: 120,
      }),
      (error) => error.code === 'failed-precondition',
    );
    await assert.rejects(
      () => apply('provider1', {
        action: 'provider_start_service',
        pedidoId: 'missing_grant',
      }),
      (error) => error.code === 'permission-denied',
    );
  });

  it('blocks pending moderation, self-dealing and accounts being deleted', async () => {
    await Promise.all([
      seedActor('provider1', 'prestador'),
      seedActor('client1', 'cliente'),
      seedProvider('provider1'),
      seedPedido('pending_moderation', {
        tipoPreco: 'por_orcamento',
        moderationStatus: 'pending_review',
      }),
      seedPedido('self_dealing', {
        clienteId: 'provider1',
        tipoPreco: 'por_orcamento',
      }),
    ]);

    for (const pedidoId of ['pending_moderation', 'self_dealing']) {
      await assert.rejects(
        () => apply('provider1', {
          action: 'provider_submit_quote',
          pedidoId,
          valorMin: 100,
          valorMax: 120,
        }),
        (error) => ['failed-precondition', 'permission-denied'].includes(error.code),
      );
    }

    await db.collection('users_private').doc('client1').set({
      accountStatus: 'deletion_pending',
    }, { merge: true });
    await seedPedido('deleting_client');
    await assert.rejects(
      () => apply('client1', {
        action: 'client_invite_provider',
        pedidoId: 'deleting_client',
        prestadorId: 'provider1',
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('rejects an expired sensitive-category approval authoritatively', async () => {
    await Promise.all([
      seedActor('provider1', 'prestador'),
      seedProvider('provider1', 'regulated'),
      seedPedido('expired_approval', {
        servicoId: 'regulated',
        tipoPreco: 'por_orcamento',
        categoryApprovalRequired: true,
        categoryRequirementId: 'regulated',
      }),
    ]);
    await db.collection('provider_public').doc('provider1').set({
      approvedSensitiveCategoryIds: ['regulated'],
    }, { merge: true });
    await db.collection('provider_private').doc('provider1')
      .collection('categoryApprovals').doc('regulated').set({
        status: 'approved',
        expiresAt: Timestamp.fromMillis(Date.now() - 60000),
      });

    await assert.rejects(
      () => apply('provider1', {
        action: 'provider_submit_quote',
        pedidoId: 'expired_approval',
        valorMin: 100,
        valorMax: 120,
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('keeps no-show disabled unless both pilot layers enable it', async () => {
    const previousFlag = process.env.ENABLE_NO_SHOW_REPORTING;
    process.env.ENABLE_NO_SHOW_REPORTING = 'false';
    await Promise.all([
      seedActor('client1', 'cliente'),
      seedActor('provider1', 'prestador'),
      seedPedido('no_show_disabled', {
        prestadorId: 'provider1',
        providerAccessGranted: true,
        providerAccessGrantedTo: 'provider1',
        providerAccessGrantedAt: Timestamp.now(),
        status: 'aceito',
        estado: 'aceito',
      }),
    ]);
    await assert.rejects(
      () => apply('client1', {
        action: 'client_report_no_show',
        pedidoId: 'no_show_disabled',
      }),
      (error) => error.code === 'failed-precondition',
    );
    if (previousFlag == null) delete process.env.ENABLE_NO_SHOW_REPORTING;
    else process.env.ENABLE_NO_SHOW_REPORTING = previousFlag;
  });
});
