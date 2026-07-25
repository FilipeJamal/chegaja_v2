const assert = require('assert');
const { Timestamp } = require('firebase-admin/firestore');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('controlled pilot markets', function () {
  this.timeout(300000);
  const db = __test__.getDb();
  const managedEnvKeys = [
    'PILOT_REQUIRE_ALLOWLIST',
    'PILOT_MARKET_ID',
    'PILOT_MAPUTO_ONLY',
    'PILOT_ALLOWED_ZONES',
    'PILOT_MIN_LAT',
    'PILOT_MAX_LAT',
    'PILOT_MIN_LNG',
    'PILOT_MAX_LNG',
    'DEFAULT_CURRENCY_CODE',
  ];
  const originalEnv = Object.fromEntries(
    managedEnvKeys.map((key) => [key, process.env[key]]),
  );
  const collections = [
    'pilot_participants',
    'provider_opportunities',
    'pedidos',
    'commission_payments',
    'reports',
    'support_tickets',
    'users_private',
    'provider_public',
    'provider_private',
    'provider_dispatch_private',
    'adminAuditLogs',
  ];

  beforeEach(async () => {
    process.env.PILOT_REQUIRE_ALLOWLIST = 'true';
    process.env.PILOT_MARKET_ID = 'mz-maputo';
    process.env.PILOT_MAPUTO_ONLY = 'true';
    process.env.DEFAULT_CURRENCY_CODE = 'MZN';
    for (const key of [
      'PILOT_ALLOWED_ZONES',
      'PILOT_MIN_LAT',
      'PILOT_MAX_LAT',
      'PILOT_MIN_LNG',
      'PILOT_MAX_LNG',
    ]) {
      delete process.env[key];
    }
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  after(() => {
    for (const [key, value] of Object.entries(originalEnv)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  });

  it('keeps Maputo explicit and uses Coimbra as the shared safe default', () => {
    const market = __test__.pilot.configuredPilotMarket();
    assert.strictEqual(market.id, 'mz-maputo');
    assert.strictEqual(market.countryCode, 'MZ');
    assert.strictEqual(market.currency, 'MZN');
    assert.strictEqual(market.locale, 'pt_MZ');
    assert.strictEqual(market.timeZone, 'Africa/Maputo');
    assert.strictEqual(market.callingCode, '+258');

    delete process.env.PILOT_MARKET_ID;
    process.env.PILOT_MAPUTO_ONLY = 'false';
    process.env.DEFAULT_CURRENCY_CODE = 'EUR';
    assert.strictEqual(__test__.pilot.configuredPilotMarket().id, 'pt-coimbra');
    assert.throws(
      () => __test__.pilot.enforcePilotOrderLocation({
        enderecoTexto: 'Lisboa, Portugal',
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('rejects ambiguous legacy records outside the explicit reconciler', () => {
    const maputo = __test__.pilot.PILOT_MARKETS['mz-maputo'];
    assert.strictEqual(
      __test__.pilot.recordBelongsToPilotMarket(
        {},
        { market: maputo, requireCurrency: true },
      ),
      false,
    );
    assert.strictEqual(
      __test__.pilot.recordBelongsToPilotMarket(
        { marketId: 'mz-maputo', currency: 'MZN' },
        { market: maputo, requireCurrency: true },
      ),
      true,
    );
  });

  it('fails closed for an unknown market and derives calendar dates by market time zone', () => {
    process.env.PILOT_MARKET_ID = 'unknown-market';
    assert.throws(
      () => __test__.pilot.configuredPilotMarket(),
      /PILOT_MARKET_ID invalido/,
    );

    process.env.PILOT_MARKET_ID = 'pt-coimbra';
    process.env.DEFAULT_CURRENCY_CODE = 'MZN';
    assert.throws(
      () => __test__.pilot.pilotCurrencyCode(),
      (error) => error.code === 'failed-precondition',
    );
    process.env.DEFAULT_CURRENCY_CODE = 'EUR';
    const nearMidnightUtc = Date.parse('2026-07-24T23:30:00.000Z');
    assert.strictEqual(
      __test__.pilot.calendarDateInTimeZone(nearMidnightUtc, 'Europe/Lisbon'),
      '2026-07-25',
    );
  });

  it('uses the authoritative Coimbra contract across access, location, admin and metrics', async () => {
    process.env.PILOT_MARKET_ID = 'pt-coimbra';
    process.env.DEFAULT_CURRENCY_CODE = 'EUR';
    const market = __test__.pilot.configuredPilotMarket();
    assert.deepStrictEqual({
      id: market.id,
      countryCode: market.countryCode,
      currency: market.currency,
      locale: market.locale,
      timeZone: market.timeZone,
      callingCode: market.callingCode,
      primaryCity: market.primaryCity,
    }, {
      id: 'pt-coimbra',
      countryCode: 'PT',
      currency: 'EUR',
      locale: 'pt_PT',
      timeZone: 'Europe/Lisbon',
      callingCode: '+351',
      primaryCity: 'Coimbra',
    });
    assert.strictEqual(__test__.pilot.pilotCurrencyCode(), 'EUR');
    const secureOrder = __test__.pedidos.buildSecurePedidoData({
      uid: 'coimbra-client',
      input: {
        titulo: 'Limpeza de apartamento',
        descricao: 'Limpeza geral.',
        modo: 'IMEDIATO',
        tipoPreco: 'a_combinar',
        tipoPagamento: 'dinheiro',
        latitude: 40.2033,
        longitude: -8.4103,
        zoneId: 'coimbra',
        enderecoTexto: 'Rua privada que nao pode definir a zona publica',
      },
      policy: {
        id: 'home_cleaning',
        name: 'Limpeza',
        riskLevel: 'normal',
        approvalRequired: false,
      },
      moderationStatus: 'approved',
    });
    assert.strictEqual(secureOrder.marketId, 'pt-coimbra');
    assert.strictEqual(secureOrder.countryCode, 'PT');
    assert.strictEqual(secureOrder.currency, 'EUR');
    assert.strictEqual(secureOrder.dispatchZoneId, 'coimbra');
    assert.strictEqual(secureOrder.dispatchZone, 'Coimbra');
    assert.strictEqual(secureOrder.dispatchZoneSource, 'server_allowlisted_zone_id');

    assert.doesNotThrow(() => __test__.pilot.enforcePilotOrderLocation({
      latitude: 40.2033,
      longitude: -8.4103,
    }));
    assert.throws(
      () => __test__.pilot.enforcePilotOrderLocation({
        enderecoTexto: 'Santo Antonio dos Olivais, Coimbra',
      }),
      (error) => error.code === 'failed-precondition',
    );
    assert.throws(
      () => __test__.pilot.enforcePilotOrderLocation({
        latitude: 38.7223,
        longitude: -9.1393,
      }),
      (error) => error.code === 'failed-precondition',
    );
    assert.throws(
      () => __test__.pilot.enforcePilotOrderLocation({
        enderecoTexto: 'Maputo, Mocambique',
      }),
      (error) => error.code === 'failed-precondition',
    );

    await Promise.all([
      db.collection('pilot_participants').doc('coimbra-client').set({
        marketId: 'pt-coimbra',
        status: 'active',
        roles: ['cliente'],
        city: 'Coimbra',
      }),
      db.collection('pilot_participants').doc('maputo-provider').set({
        marketId: 'mz-maputo',
        status: 'active',
        roles: ['prestador'],
        city: 'Maputo',
      }),
    ]);
    const activeClient = await __test__.pilot.requirePilotParticipant({
      database: db,
      uid: 'coimbra-client',
      role: 'cliente',
    });
    assert.strictEqual(activeClient.active, true);
    await assert.rejects(
      () => __test__.pilot.requirePilotParticipant({
        database: db,
        uid: 'maputo-provider',
        role: 'prestador',
      }),
      (error) => error.code === 'permission-denied',
    );

    const authAdmin = { getUser: async () => ({ uid: 'coimbra-provider' }) };
    await __test__.pilot.adminSetPilotParticipantCore({
      database: db,
      auth: { uid: 'admin1', token: { admin: true } },
      authAdmin,
      data: {
        uid: 'coimbra-provider',
        status: 'active',
        roles: ['prestador'],
      },
    });
    const provider = (await db.collection('pilot_participants')
      .doc('coimbra-provider')
      .get()).data();
    assert.strictEqual(provider.marketId, 'pt-coimbra');
    assert.strictEqual(provider.countryCode, 'PT');
    assert.strictEqual(provider.city, 'Coimbra');
    assert.strictEqual(provider.cohort, 'pt-coimbra-pilot-1');

    await Promise.all([
      db.collection('pedidos').doc('coimbra-order').set({
        clienteId: 'coimbra-client',
        prestadorId: 'coimbra-provider',
        marketId: 'pt-coimbra',
        status: 'concluido',
        currency: 'EUR',
        earningsTotal: 100,
        earningsProvider: 90,
        commissionPlatform: 10,
      }),
      db.collection('pedidos').doc('wrong-currency-order').set({
        clienteId: 'coimbra-client',
        prestadorId: 'coimbra-provider',
        marketId: 'pt-coimbra',
        status: 'concluido',
        currency: 'MZN',
        earningsTotal: 5000,
        earningsProvider: 4500,
        commissionPlatform: 500,
      }),
      db.collection('pedidos').doc('legacy-maputo-history-same-users').set({
        clienteId: 'coimbra-client',
        prestadorId: 'coimbra-provider',
        status: 'concluido',
        earningsTotal: 9000,
        earningsProvider: 8000,
        commissionPlatform: 1000,
      }),
      db.collection('pedidos').doc('explicit-maputo-history-same-users').set({
        clienteId: 'coimbra-client',
        prestadorId: 'coimbra-provider',
        marketId: 'mz-maputo',
        status: 'concluido',
        currency: 'MZN',
        earningsTotal: 7000,
        earningsProvider: 6000,
        commissionPlatform: 1000,
      }),
      db.collection('provider_opportunities').doc('coimbra-opportunity').set({
        providerId: 'coimbra-provider',
        pedidoId: 'coimbra-order',
        marketId: 'pt-coimbra',
        currency: 'EUR',
      }),
      db.collection('provider_opportunities').doc('legacy-maputo-opportunity').set({
        providerId: 'coimbra-provider',
        pedidoId: 'legacy-maputo-history-same-users',
      }),
      db.collection('commission_payments').doc('coimbra-receipt').set({
        providerId: 'coimbra-provider',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        amount: 10,
      }),
      db.collection('commission_payments').doc('wrong-currency-receipt').set({
        providerId: 'coimbra-provider',
        marketId: 'pt-coimbra',
        currency: 'MZN',
        amount: 500,
      }),
      db.collection('commission_payments').doc('legacy-maputo-receipt').set({
        providerId: 'coimbra-provider',
        amount: 1000,
      }),
      db.collection('reports').doc('coimbra-report').set({
        reporterId: 'coimbra-client',
        targetOwnerId: 'coimbra-provider',
        marketId: 'pt-coimbra',
        status: 'resolved',
      }),
      db.collection('reports').doc('legacy-maputo-report').set({
        reporterId: 'coimbra-client',
        targetOwnerId: 'coimbra-provider',
        status: 'resolved',
      }),
      db.collection('support_tickets').doc('coimbra-ticket').set({
        uid: 'coimbra-client',
        marketId: 'pt-coimbra',
        category: 'order',
        status: 'open',
      }),
      db.collection('support_tickets').doc('legacy-maputo-ticket').set({
        uid: 'coimbra-client',
        category: 'payment',
        status: 'resolved',
      }),
    ]);
    const metrics = await __test__.pilot.buildPilotMetricsCore({ database: db });
    assert.strictEqual(metrics.marketId, 'pt-coimbra');
    assert.strictEqual(metrics.currency, 'EUR');
    assert.strictEqual(metrics.locale, 'pt_PT');
    assert.strictEqual(metrics.timeZone, 'Europe/Lisbon');
    assert.strictEqual(metrics.scope, 'Coimbra controlled pilot');
    assert.strictEqual(metrics.providers.enrolled, 1);
    assert.strictEqual(metrics.providers.receivedFirstOpportunity, 1);
    assert.strictEqual(metrics.requests.completed, 1);
    assert.strictEqual(metrics.value.gmv, 100);
    assert.strictEqual(metrics.value.providerEarnings, 90);
    assert.strictEqual(metrics.value.commissionDue, 10);
    assert.strictEqual(metrics.value.commissionsCollected, 10);
    assert.strictEqual(metrics.trustSafety.disputesOpened, 2);
    assert.strictEqual(metrics.trustSafety.disputesResolved, 1);
    assert.strictEqual(Object.prototype.hasOwnProperty.call(metrics.value, 'gmvMzn'), false);
  });

  it('requires an active allowlisted participant with the correct role', async () => {
    await db.collection('pilot_participants').doc('provider1').set({
      marketId: 'mz-maputo',
      status: 'active',
      roles: ['prestador'],
      city: 'Maputo',
    });
    const result = await __test__.pilot.requirePilotParticipant({
      database: db,
      uid: 'provider1',
      role: 'prestador',
    });
    assert.strictEqual(result.active, true);
    await assert.rejects(
      () => __test__.pilot.requirePilotParticipant({
        database: db,
        uid: 'provider1',
        role: 'cliente',
      }),
      (error) => error.code === 'permission-denied',
    );
    await assert.rejects(
      () => __test__.pilot.requirePilotParticipant({
        database: db,
        uid: 'not-enrolled',
        role: 'cliente',
      }),
      (error) => error.code === 'permission-denied',
    );
  });

  it('requires phone, current consent, cohort and role before payment actions', async () => {
    await Promise.all([
      db.collection('pilot_participants').doc('provider-payment').set({
        marketId: 'mz-maputo',
        status: 'active',
        roles: ['prestador'],
        city: 'Maputo',
      }),
      db.collection('users_private').doc('provider-payment').set({
        legalConsent: {
          version: __test__.legal.LEGAL_DOCUMENT_VERSION,
          termsAccepted: true,
          privacyAccepted: true,
          ageConfirmed: true,
        },
        accountStatus: 'active',
      }),
    ]);

    const auth = {
      uid: 'provider-payment',
      token: { phone_number: '+258840000004' },
    };
    const uid = await __test__.payments.requirePaymentActor({
      auth,
      role: 'prestador',
      database: db,
    });
    assert.strictEqual(uid, 'provider-payment');

    await assert.rejects(
      () => __test__.payments.requirePaymentActor({
        auth: { uid: 'provider-payment', token: {} },
        role: 'prestador',
        database: db,
      }),
      (error) => error.code === 'failed-precondition',
    );
    await assert.rejects(
      () => __test__.payments.requirePaymentActor({
        auth,
        role: 'cliente',
        database: db,
      }),
      (error) => error.code === 'permission-denied',
    );

    await db.collection('users_private').doc('provider-payment').update({
      accountStatus: 'deletion_pending',
    });
    await assert.rejects(
      () => __test__.payments.requirePaymentActor({
        auth,
        role: 'prestador',
        database: db,
      }),
      (error) => error.code === 'failed-precondition',
    );
    await db.collection('users_private').doc('provider-payment').update({
      accountStatus: 'inactive',
    });
    await assert.rejects(
      () => __test__.payments.requirePaymentActor({
        auth,
        role: 'prestador',
        database: db,
      }),
      (error) => error.code === 'failed-precondition',
    );

    await db.collection('users_private').doc('provider-payment').delete();
    await assert.rejects(
      () => __test__.payments.requirePaymentActor({
        auth,
        role: 'prestador',
        database: db,
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('accepts Maputo/Matola coordinates and rejects locations outside the pilot', () => {
    assert.doesNotThrow(() => __test__.pilot.enforcePilotOrderLocation({
      latitude: -25.9692,
      longitude: 32.5732,
    }));
    const maputoFallback = __test__.pilot.resolvePilotOrderLocation({
      latitude: -25.9692,
      longitude: 32.5732,
      enderecoTexto: 'Rua privada 123, porta azul',
    });
    assert.deepStrictEqual({
      zoneId: maputoFallback.dispatchZoneId,
      zone: maputoFallback.dispatchZone,
      source: maputoFallback.dispatchZoneSource,
    }, {
      zoneId: 'maputo',
      zone: 'Maputo',
      source: 'server_validated_market_fallback',
    });
    const matolaZone = __test__.pilot.resolvePilotOrderLocation({
      latitude: -25.9622,
      longitude: 32.4589,
      zoneId: 'matola',
    });
    assert.strictEqual(matolaZone.dispatchZoneId, 'matola');
    assert.strictEqual(matolaZone.dispatchZone, 'Matola');
    assert.throws(
      () => __test__.pilot.enforcePilotOrderLocation({
        enderecoTexto: 'Matola A, Matola',
      }),
      (error) => error.code === 'failed-precondition',
    );
    assert.throws(
      () => __test__.pilot.enforcePilotOrderLocation({
        latitude: -25.9692,
        longitude: 32.5732,
        zoneId: 'rua-das-flores-123',
      }),
      (error) => error.code === 'invalid-argument',
    );
    assert.throws(
      () => __test__.pilot.enforcePilotOrderLocation({
        latitude: -19.8436,
        longitude: 34.8389,
      }),
      (error) => error.code === 'failed-precondition',
    );
    assert.throws(
      () => __test__.pilot.enforcePilotOrderLocation({
        enderecoTexto: 'Beira, Sofala',
      }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('enrolls and deactivates a provider through an audited admin operation', async () => {
    await db.collection('provider_public').doc('provider1').set({
      servicos: ['home_cleaning'],
      isSearchable: false,
    });
    const authAdmin = { getUser: async () => ({ uid: 'provider1' }) };
    const adminAuth = { uid: 'admin1', token: { admin: true } };
    await __test__.pilot.adminSetPilotParticipantCore({
      database: db,
      auth: adminAuth,
      authAdmin,
      data: {
        uid: 'provider1',
        status: 'active',
        roles: ['prestador'],
        city: 'Maputo',
        cohort: 'cohort-a',
      },
    });
    const activeProvider = (
      await db.collection('provider_public').doc('provider1').get()
    ).data();
    assert.strictEqual(activeProvider.isSearchable, true);
    assert.strictEqual(activeProvider.marketId, 'mz-maputo');
    assert.strictEqual(activeProvider.countryCode, 'MZ');
    assert.strictEqual(activeProvider.currency, 'MZN');
    const activeDispatch = (
      await db.collection('provider_dispatch_private').doc('provider1').get()
    ).data();
    assert.strictEqual(activeDispatch.marketId, 'mz-maputo');
    assert.strictEqual(activeDispatch.currency, 'MZN');
    await __test__.pilot.adminSetPilotParticipantCore({
      database: db,
      auth: adminAuth,
      authAdmin,
      data: {
        uid: 'provider1',
        status: 'inactive',
        roles: ['prestador'],
        city: 'Maputo',
      },
    });
    assert.strictEqual(
      (await db.collection('provider_public').doc('provider1').get()).data().isSearchable,
      false,
    );
    const audit = await db.collection('adminAuditLogs')
      .where('targetId', '==', 'provider1')
      .get();
    assert.strictEqual(audit.size, 2);
  });

  it('calculates the mission metric from real pilot events without exposing users', async () => {
    const nowMs = Date.now();
    const days = (value) => Timestamp.fromMillis(nowMs - value * 24 * 60 * 60 * 1000);
    await Promise.all([
      db.collection('pilot_participants').doc('provider1').set({
        marketId: 'mz-maputo', status: 'active', roles: ['prestador'],
        city: 'Maputo', enrolledAt: days(20),
      }),
      db.collection('pilot_participants').doc('provider2').set({
        marketId: 'mz-maputo', status: 'active', roles: ['prestador'],
        city: 'Matola', enrolledAt: days(40),
      }),
      db.collection('pilot_participants').doc('client1').set({
        marketId: 'mz-maputo', status: 'active', roles: ['cliente'],
        city: 'Maputo', enrolledAt: days(20),
      }),
      db.collection('provider_opportunities').doc('opp1').set({
        marketId: 'mz-maputo', currency: 'MZN',
        providerId: 'provider1', pedidoId: 'order1', deliveredAt: days(18),
      }),
      db.collection('pedidos').doc('order1').set({
        marketId: 'mz-maputo', currency: 'MZN',
        clienteId: 'client1', prestadorId: 'provider1', status: 'concluido',
        precoFinal: 1000, earningsTotal: 1000,
        earningsProvider: 900, commissionPlatform: 100,
        updatedAt: days(15), createdAt: days(18),
      }),
      db.collection('pedidos').doc('order2').set({
        marketId: 'mz-maputo', currency: 'MZN',
        clienteId: 'client1', prestadorId: 'provider2', status: 'concluido',
        precoFinal: 2000, earningsTotal: 2000,
        earningsProvider: 1800, commissionPlatform: 200,
        updatedAt: days(5), createdAt: days(10),
      }),
      db.collection('pedidos').doc('order3').set({
        marketId: 'mz-maputo', currency: 'MZN',
        clienteId: 'client1', prestadorId: 'provider1', status: 'concluido',
        precoFinal: 500,
        updatedAt: days(2), createdAt: days(3),
      }),
      db.collection('commission_payments').doc('receipt1').set({
        marketId: 'mz-maputo', currency: 'MZN',
        providerId: 'provider1', amount: 50, createdAt: days(1),
      }),
      db.collection('reports').doc('report1').set({
        marketId: 'mz-maputo',
        reporterId: 'client1', targetOwnerId: 'provider1', status: 'resolved',
      }),
      db.collection('support_tickets').doc('ticket1').set({
        marketId: 'mz-maputo',
        uid: 'client1', category: 'order', status: 'open',
      }),
    ]);

    const metrics = await __test__.pilot.buildPilotMetricsCore({
      database: db,
      now: Timestamp.fromMillis(nowMs),
    });
    assert.strictEqual(metrics.mission.numerator, 1);
    assert.strictEqual(metrics.mission.denominator, 2);
    assert.strictEqual(metrics.mission.rate, 0.5);
    assert.strictEqual(metrics.providers.receivedFirstOpportunity, 1);
    assert.strictEqual(metrics.providers.completedFirstPaidWork, 2);
    assert.strictEqual(metrics.requests.completed, 3);
    assert.strictEqual(metrics.marketId, 'mz-maputo');
    assert.strictEqual(metrics.currency, 'MZN');
    assert.strictEqual(metrics.value.gmv, 3500);
    assert.strictEqual(metrics.value.providerEarnings, 2700);
    assert.strictEqual(metrics.value.commissionDue, 300);
    assert.strictEqual(metrics.value.commissionsCollected, 50);
    assert.strictEqual(metrics.value.gmvMzn, 3500);
    assert.strictEqual(metrics.value.providerEarningsMzn, 2700);
    assert.strictEqual(metrics.value.commissionDueMzn, 300);
    assert.strictEqual(metrics.value.financialRecordsComplete, 2);
    assert.strictEqual(metrics.value.financialRecordsIncomplete, 1);
    assert.strictEqual(metrics.value.commissionsCollectedMzn, 50);
    assert.strictEqual(metrics.clients.returning, 1);
    assert.strictEqual(metrics.trustSafety.disputesOpened, 2);
    assert.strictEqual(metrics.trustSafety.disputesResolved, 1);
    assert.strictEqual(Object.prototype.hasOwnProperty.call(metrics, 'participants'), false);
  });
});
