const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { GeoPoint, serverTimestamp } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'chegaja-ac88d';
const FIRESTORE_RULES = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);

describe('Firestore Security Rules — current P1 model', function () {
  this.timeout(300000);
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: FIRESTORE_RULES,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) await testEnv.cleanup();
  });

  beforeEach(async () => testEnv.clearFirestore());

  function user(uid, claims = {}) {
    return testEnv.authenticatedContext(uid, claims).firestore();
  }

  async function seed(callback) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await callback(context.firestore());
    });
  }

  it('isolates private identity and permanently closes mixed legacy documents', async () => {
    const alice = user('alice', { phone_number: '+351910000010' });
    const bob = user('bob');
    const anonymous = testEnv.unauthenticatedContext().firestore();

    await assertSucceeds(alice.collection('users_private').doc('alice').set({
      uid: 'alice',
      phoneE164: '+258840000000',
    }));
    await assertSucceeds(alice.collection('users_private').doc('alice').get());
    await assertFails(bob.collection('users_private').doc('alice').get());
    await assertFails(anonymous.collection('users_private').doc('alice').get());
    await assertFails(alice.collection('users').doc('alice').get());
    await assertFails(alice.collection('prestadores').doc('alice').set({ uid: 'alice' }));
  });

  it('exposes only deliberately public profiles and rejects private fields', async () => {
    const provider = user('provider1', {
      phone_number: '+351910000011',
    });
    const visitor = testEnv.unauthenticatedContext().firestore();

    await assertSucceeds(provider.collection('provider_public').doc('provider1').set({
      uid: 'provider1',
      displayName: 'Marta',
      city: 'Maputo',
      isSearchable: false,
    }));
    await assertFails(visitor.collection('provider_public').doc('provider1').get());
    await assertFails(provider.collection('provider_public').doc('provider1').update({
      isSearchable: true,
    }));
    await assertFails(provider.collection('provider_public').doc('provider1').update({
      phoneE164: '+258850000000',
    }));

    await seed((db) => db.collection('provider_public').doc('provider1').update({
      isSearchable: true,
    }));
    await assertSucceeds(visitor.collection('provider_public').doc('provider1').get());
  });

  it('keeps exact provider dispatch data owner/admin-only', async () => {
    await seed((db) => db.collection('provider_dispatch_private').doc('provider1').set({
      providerId: 'provider1',
      lastLocation: { latitude: -25.96, longitude: 32.58 },
      activeClientIds: ['client1'],
    }));
    await assertSucceeds(user('provider1').collection('provider_dispatch_private').doc('provider1').get());
    await assertFails(user('client1').collection('provider_dispatch_private').doc('provider1').get());
    await assertFails(user('outsider').collection('provider_dispatch_private').doc('provider1').get());
    await assertSucceeds(user('admin1', { admin: true })
      .collection('provider_dispatch_private').doc('provider1').get());
  });

  it('allows owner dispatch merges while preserving backend-owned fields', async () => {
    const provider = user('provider1', {
      phone_number: '+351910000011',
    });
    const dispatchRef = provider
      .collection('provider_dispatch_private')
      .doc('provider1');

    await assertSucceeds(dispatchRef.set({
      providerId: 'provider1',
      isOnline: false,
      lastLocationAt: serverTimestamp(),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
    await assertFails(user('provider2')
      .collection('provider_dispatch_private')
      .doc('provider2')
      .set({
        providerId: 'provider2',
        activeClientIds: ['client1'],
      }));
    await assertFails(user('provider3')
      .collection('provider_dispatch_private')
      .doc('provider3')
      .set({
        providerId: 'another-provider',
        isOnline: true,
      }));

    await seed((db) => db.collection('provider_dispatch_private').doc('provider1').set({
      providerId: 'provider1',
      isOnline: false,
      activeClientIds: ['client1'],
      acceptingRequests: false,
      financialStatus: 'suspended_new_jobs',
      backendDecision: 'manual_review',
      createdAt: new Date(),
      updatedAt: new Date(),
    }));

    await assertSucceeds(dispatchRef.set({
      providerId: 'provider1',
      isOnline: true,
      lastLocation: { lat: -25.96, lng: 32.58 },
      geo: {
        geohash: 'ke7zd4k',
        geopoint: new GeoPoint(-25.96, 32.58),
      },
      radiusKm: 12,
      workingHours: { monday: ['08:00-17:00'] },
      blockedDates: [],
      lastSeenAt: serverTimestamp(),
      lastLocationAt: serverTimestamp(),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }, { merge: true }));

    await assertFails(dispatchRef.update({ activeClientIds: [] }));
    await assertFails(dispatchRef.update({ acceptingRequests: true }));
    await assertFails(dispatchRef.update({ financialStatus: 'active' }));
    await assertFails(dispatchRef.update({ backendDecision: 'approved' }));
    await assertFails(dispatchRef.update({ providerId: 'provider2' }));
    await assertFails(dispatchRef.update({ radiusKm: 51 }));
    await assertFails(dispatchRef.update({ radiusKm: '12' }));
    await assertFails(dispatchRef.update({
      isOnline: true,
      lastLocation: { lat: -25.96, lng: 32.58 },
      geo: {
        geohash: 'ke7zd4k',
        geopoint: new GeoPoint(-24.00, 31.00),
      },
      lastLocationAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
    await assertFails(dispatchRef.update({
      isOnline: true,
      lastLocation: { lat: -25.96, lng: 32.58 },
      geo: {
        geohash: 'bad',
        geopoint: new GeoPoint(-25.96, 32.58),
      },
      lastLocationAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
    await assertFails(user('provider2')
      .collection('provider_dispatch_private')
      .doc('provider1')
      .update({ isOnline: false }));

    await assertSucceeds(user('admin1', { admin: true })
      .collection('provider_dispatch_private')
      .doc('provider1')
      .update({ acceptingRequests: true }));
  });

  it('allows participants to read raw orders but denies open-order scraping and direct creation', async () => {
    await seed(async (db) => {
      await db.collection('pedidos').doc('order1').set({
        clienteId: 'client1',
        prestadorId: 'provider1',
        providerAccessGranted: true,
        providerAccessGrantedTo: 'provider1',
        providerAccessGrantedAt: new Date(),
        status: 'aceito',
        estado: 'aceito',
        enderecoTexto: 'Rua privada 123',
      });
      await db.collection('pilot_participants').doc('client1').set({
        status: 'active', roles: ['cliente'], city: 'Maputo',
      });
      await db.collection('pilot_participants').doc('provider1').set({
        status: 'active', roles: ['prestador'], city: 'Maputo',
      });
    });
    const client = user('client1', { phone_number: '+258840000001' });
    const provider = user('provider1', { phone_number: '+258840000002' });
    const outsider = user('provider2', { phone_number: '+258840000003' });

    await assertSucceeds(client.collection('pedidos').doc('order1').get());
    await assertSucceeds(provider.collection('pedidos').doc('order1').get());
    await assertFails(outsider.collection('pedidos').doc('order1').get());
    await assertFails(client.collection('pedidos').doc('forged').set({
      clienteId: 'client1',
      status: 'criado',
      estado: 'criado',
    }));
  });

  it('exposes only the sanitized dispatch projection to verified providers', async () => {
    await seed(async (db) => {
      await db.collection('provider_public').doc('provider1').set({
        uid: 'provider1',
        isSearchable: true,
        marketId: 'pt-coimbra',
        currency: 'EUR',
      });
      await db.collection('pilot_participants').doc('provider1').set({
        status: 'active', roles: ['prestador'], city: 'Coimbra', marketId: 'pt-coimbra',
      });
      await db.collection('pedido_dispatch').doc('order1').set({
        pedidoId: 'order1',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        zoneLabel: 'Matola A',
        approximateDistanceKm: 3.4,
        status: 'criado',
        prestadorId: null,
        targetProviderId: null,
      });
    });
    const verified = user('provider1', { phone_number: '+258840000002' });
    const unverified = user('provider2');
    await assertSucceeds(verified.collection('pedido_dispatch').doc('order1').get());
    await assertFails(unverified.collection('pedido_dispatch').doc('order1').get());
    await assertFails(verified.collection('pedido_dispatch').doc('order1').update({
      latitude: -25.965432,
    }));
  });

  it('allows phone-verified order participants to chat and blocks outsiders', async () => {
    await seed(async (db) => {
      await db.collection('pedidos').doc('order1').set({
        clienteId: 'client1',
        prestadorId: 'provider1',
        providerAccessGranted: true,
        providerAccessGrantedTo: 'provider1',
        providerAccessGrantedAt: new Date(),
        status: 'aceito',
        estado: 'aceito',
      });
      await db.collection('chats').doc('order1').set({
        pedidoId: 'order1',
        clienteId: 'client1',
        prestadorId: 'provider1',
      });
      await db.collection('pilot_participants').doc('client1').set({
        status: 'active', roles: ['cliente'], city: 'Maputo',
      });
      await db.collection('pilot_participants').doc('provider1').set({
        status: 'active', roles: ['prestador'], city: 'Maputo',
      });
    });
    const client = user('client1', { phone_number: '+258840000001' });
    const provider = user('provider1', { phone_number: '+258840000002' });
    const outsider = user('outsider', { phone_number: '+258840000003' });

    await assertSucceeds(client.collection('chats').doc('order1').get());
    await assertFails(client.collection('chats').doc('order1').update({
      prestadorId: 'outsider',
    }));
    await assertSucceeds(provider.collection('chats').doc('order1')
      .collection('messages').doc('m1').set({
        pedidoId: 'order1',
        type: 'text',
        senderId: 'provider1',
        senderRole: 'prestador',
        text: 'Estou a caminho.',
        createdAt: serverTimestamp(),
      }));
    await assertSucceeds(provider.collection('chats').doc('order1')
      .collection('messages').doc('m2').set({
        pedidoId: 'order1',
        senderId: 'provider1',
        senderRole: 'prestador',
        type: 'image',
        mediaPath: 'chats/order1/images/photo.jpg',
        createdAt: serverTimestamp(),
      }));
    await assertFails(provider.collection('chats').doc('order1')
      .collection('messages').doc('m3').set({
        pedidoId: 'order1',
        senderId: 'provider1',
        senderRole: 'prestador',
        type: 'image',
        mediaUrl: 'https://storage.invalid/private?token=persistent',
        createdAt: serverTimestamp(),
      }));
    await assertFails(provider.collection('chats').doc('order1')
      .collection('messages').doc('m4').set({
        pedidoId: 'order1',
        senderId: 'provider1',
        senderRole: 'prestador',
        type: 'image',
        mediaPath: 'chats/another-order/images/photo.jpg',
        createdAt: serverTimestamp(),
      }));
    await assertSucceeds(client.collection('chats').doc('order1')
      .collection('messages').doc('m1').update({ seenByCliente: true }));
    await assertFails(client.collection('chats').doc('order1')
      .collection('messages').doc('m1').update({ senderId: 'client1' }));
    await assertFails(client.collection('chats').doc('order1')
      .collection('messages').doc('m2').update({
        mediaPath: 'chats/order1/images/replaced.jpg',
      }));
    await assertSucceeds(client.collection('chats').doc('order1')
      .collection('messages').get());
    await assertFails(outsider.collection('chats').doc('order1').get());
    await assertFails(outsider.collection('chats').doc('order1')
      .collection('messages').get());

    await seed((db) => db.collection('pedidos').doc('order1').update({
      status: 'concluido',
      estado: 'concluido',
    }));
    await assertSucceeds(provider.collection('chats').doc('order1').get());
    await assertSucceeds(provider.collection('chats').doc('order1')
      .collection('messages').get());
    await assertFails(provider.collection('chats').doc('order1')
      .collection('messages').doc('after-completion').set({
        pedidoId: 'order1',
        type: 'text',
        senderId: 'provider1',
        senderRole: 'prestador',
        text: 'Mensagem tardia.',
        createdAt: serverTimestamp(),
      }));
    await assertFails(client.collection('chats').doc('order1')
      .collection('messages').doc('m1').update({ seenByCliente: true }));
  });

  it('allows one server-timestamped review from the owning client only', async () => {
    await seed((db) => db.collection('pedidos').doc('order1').set({
      clienteId: 'client1',
      prestadorId: 'provider1',
      status: 'concluido',
      estado: 'concluido',
    }));
    const client = user('client1', { phone_number: '+258840000001' });
    const other = user('client2', { phone_number: '+258840000002' });
    const review = {
      pedidoId: 'order1',
      clienteId: 'client1',
      prestadorId: 'provider1',
      estrelas: 5,
      comentario: 'Excelente serviço.',
      createdAt: serverTimestamp(),
    };
    await assertSucceeds(client.collection('avaliacoes').doc('order1_client1').set(review));
    await assertFails(other.collection('avaliacoes').doc('order1_client2').set({
      ...review,
      clienteId: 'client2',
      createdAt: serverTimestamp(),
    }));
    await assertFails(client.collection('avaliacoes').doc('duplicate').set({
      ...review,
      createdAt: serverTimestamp(),
    }));
  });

  it('creates Trust & Safety reports with authoritative initial status and private ownership', async () => {
    const reporter = user('client1', { phone_number: '+258840000001' });
    const outsider = user('outsider', { phone_number: '+258840000002' });
    const moderator = user('moderator1', { moderator: true });
    const validReport = {
      reporterId: 'client1',
      targetType: 'provider_profile',
      targetId: 'provider1',
      reasonCode: 'fraud',
      severity: 'high',
      status: 'pending_review',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };

    await assertSucceeds(reporter.collection('reports').doc('report1').set(validReport));
    await assertSucceeds(reporter.collection('reports').doc('report1').get());
    await assertFails(outsider.collection('reports').doc('report1').get());
    await assertFails(reporter.collection('reports').doc('forged').set({
      ...validReport,
      status: 'resolved',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(moderator.collection('reports').doc('report1').update({
      status: 'reviewed',
    }));
  });

  it('keeps blocked-user lists private and prevents self-blocking or forged ownership', async () => {
    const alice = user('alice');
    const bob = user('bob');
    const ref = alice.collection('users_private').doc('alice')
      .collection('blockedUsers').doc('bob');
    await assertSucceeds(ref.set({
      blockedUid: 'bob',
      createdAt: serverTimestamp(),
      reason: 'Assédio',
    }));
    await assertSucceeds(ref.get());
    await assertFails(bob.collection('users_private').doc('alice')
      .collection('blockedUsers').doc('bob').get());
    await assertFails(alice.collection('users_private').doc('alice')
      .collection('blockedUsers').doc('alice').set({
        blockedUid: 'alice',
        createdAt: serverTimestamp(),
      }));
    await assertSucceeds(ref.delete());
  });

  it('reserves handles, financial state, stories and calls for trusted backend paths', async () => {
    const provider = user('provider1', { phone_number: '+258840000001' });
    await assertSucceeds(provider.collection('handles').doc('marta').get());
    await assertFails(provider.collection('handles').doc('marta').set({
      uid: 'provider1',
      status: 'active',
    }));
    await assertFails(provider.collection('provider_private').doc('provider1')
      .collection('financialTransactions').doc('tx1').set({ amount: 100 }));
    await assertFails(provider.collection('stories').doc('story1').set({
      prestadorId: 'provider1',
      mediaUrl: 'https://example.invalid/story.jpg',
    }));
    await assertFails(provider.collection('calls').doc('call1').set({
      callerId: 'provider1',
      calleeId: 'client1',
    }));
  });
});
