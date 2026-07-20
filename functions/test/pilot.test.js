const assert = require('assert');
const { Timestamp } = require('firebase-admin/firestore');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('controlled Maputo pilot', function () {
  this.timeout(120000);
  const db = __test__.getDb();
  const originalAllowlist = process.env.PILOT_REQUIRE_ALLOWLIST;
  const originalMaputoOnly = process.env.PILOT_MAPUTO_ONLY;
  const collections = [
    'pilot_participants',
    'provider_opportunities',
    'pedidos',
    'commission_payments',
    'reports',
    'support_tickets',
    'users_private',
    'provider_public',
    'provider_dispatch_private',
    'adminAuditLogs',
  ];

  beforeEach(async () => {
    process.env.PILOT_REQUIRE_ALLOWLIST = 'true';
    process.env.PILOT_MAPUTO_ONLY = 'true';
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  });

  after(() => {
    if (originalAllowlist === undefined) delete process.env.PILOT_REQUIRE_ALLOWLIST;
    else process.env.PILOT_REQUIRE_ALLOWLIST = originalAllowlist;
    if (originalMaputoOnly === undefined) delete process.env.PILOT_MAPUTO_ONLY;
    else process.env.PILOT_MAPUTO_ONLY = originalMaputoOnly;
  });

  it('requires an active allowlisted participant with the correct role', async () => {
    await db.collection('pilot_participants').doc('provider1').set({
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

  it('accepts Maputo/Matola coordinates and rejects locations outside the pilot', () => {
    assert.doesNotThrow(() => __test__.pilot.enforcePilotOrderLocation({
      latitude: -25.9692,
      longitude: 32.5732,
    }));
    assert.doesNotThrow(() => __test__.pilot.enforcePilotOrderLocation({
      enderecoTexto: 'Matola A, Matola',
    }));
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
    assert.strictEqual(
      (await db.collection('provider_public').doc('provider1').get()).data().isSearchable,
      true,
    );
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
        status: 'active', roles: ['prestador'], city: 'Maputo', enrolledAt: days(20),
      }),
      db.collection('pilot_participants').doc('provider2').set({
        status: 'active', roles: ['prestador'], city: 'Matola', enrolledAt: days(40),
      }),
      db.collection('pilot_participants').doc('client1').set({
        status: 'active', roles: ['cliente'], city: 'Maputo', enrolledAt: days(20),
      }),
      db.collection('provider_opportunities').doc('opp1').set({
        providerId: 'provider1', pedidoId: 'order1', deliveredAt: days(18),
      }),
      db.collection('pedidos').doc('order1').set({
        clienteId: 'client1', prestadorId: 'provider1', status: 'concluido',
        precoFinal: 1000, earningsProvider: 900, commissionPlatform: 100,
        updatedAt: days(15), createdAt: days(18),
      }),
      db.collection('pedidos').doc('order2').set({
        clienteId: 'client1', prestadorId: 'provider2', status: 'concluido',
        precoFinal: 2000, earningsProvider: 1800, commissionPlatform: 200,
        updatedAt: days(5), createdAt: days(10),
      }),
      db.collection('commission_payments').doc('receipt1').set({
        providerId: 'provider1', amount: 50, createdAt: days(1),
      }),
      db.collection('reports').doc('report1').set({
        reporterId: 'client1', targetOwnerId: 'provider1', status: 'resolved',
      }),
      db.collection('support_tickets').doc('ticket1').set({
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
    assert.strictEqual(metrics.requests.completed, 2);
    assert.strictEqual(metrics.value.gmvMzn, 3000);
    assert.strictEqual(metrics.value.providerEarningsMzn, 2700);
    assert.strictEqual(metrics.value.commissionsCollectedMzn, 50);
    assert.strictEqual(metrics.clients.returning, 1);
    assert.strictEqual(metrics.trustSafety.disputesOpened, 2);
    assert.strictEqual(metrics.trustSafety.disputesResolved, 1);
    assert.strictEqual(Object.prototype.hasOwnProperty.call(metrics, 'participants'), false);
  });
});
