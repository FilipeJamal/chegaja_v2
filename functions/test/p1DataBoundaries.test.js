const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const assert = require('assert');
const { GeoPoint, Timestamp, serverTimestamp } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'chegaja-ac88d';
const FIRESTORE_RULES = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);

describe('P1 public/private data boundaries', function () {
  this.timeout(300000);
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules: FIRESTORE_RULES, host: '127.0.0.1', port: 8080 },
    });
  });

  after(async () => {
    if (testEnv) await testEnv.cleanup();
  });
  beforeEach(async () => testEnv.clearFirestore());

  it('allows public profile reads but never phone fields in owner writes', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('pilot_participants').doc('client1').set({
        status: 'active', roles: ['cliente'], city: 'Coimbra',
      });
      await db.collection('users_private').doc('client1').set({
        uid: 'client1', accountStatus: 'active',
      });
    });
    const owner = testEnv.authenticatedContext('client1', {
      phone_number: '+351910000000',
    });
    const visitor = testEnv.unauthenticatedContext();
    const ownerDb = owner.firestore();
    const visitorDb = visitor.firestore();
    await assertSucceeds(ownerDb.collection('public_profiles').doc('client1').set({
      uid: 'client1',
      displayName: 'Ana',
      city: 'Maputo',
    }));
    await assertSucceeds(visitorDb.collection('public_profiles').doc('client1').get());
    await assertFails(ownerDb.collection('public_profiles').doc('client1').set({
      uid: 'client1',
      displayName: 'Ana',
      phoneE164: '+258840000000',
    }));
    await assertFails(testEnv.authenticatedContext('anonymous-client')
      .firestore()
      .collection('public_profiles')
      .doc('anonymous-client')
      .set({ uid: 'anonymous-client', displayName: 'Spam' }));
    await assertFails(testEnv.authenticatedContext('outside-cohort', {
      phone_number: '+351910000099',
    }).firestore()
      .collection('public_profiles')
      .doc('outside-cohort')
      .set({ uid: 'outside-cohort', displayName: 'Outside' }));
  });

  it('isolates users_private from every other signed-in user', async () => {
    const owner = testEnv.authenticatedContext('client1', {
      phone_number: '+351910000001',
    });
    const outsider = testEnv.authenticatedContext('outsider');
    const ownerDb = owner.firestore();
    const outsiderDb = outsider.firestore();
    await assertSucceeds(ownerDb.collection('users_private').doc('client1').set({
      uid: 'client1',
      phoneE164: '+258840000000',
    }));
    await assertSucceeds(ownerDb.collection('users_private').doc('client1').get());
    await assertFails(outsiderDb.collection('users_private').doc('client1').get());
  });

  it('keeps exact dispatch location private', async () => {
    const provider = testEnv.authenticatedContext('provider1', {
      phone_number: '+351910000002',
    });
    const outsider = testEnv.authenticatedContext('outsider');
    await assertSucceeds(provider.firestore()
      .collection('provider_dispatch_private')
      .doc('provider1')
      .set({
        providerId: 'provider1',
        isOnline: true,
        lastLocation: { lat: -25.9, lng: 32.5 },
        geo: {
          geohash: 'kz4sr',
          geopoint: new GeoPoint(-25.9, 32.5),
        },
        lastLocationAt: serverTimestamp(),
      }));
    await assertFails(outsider.firestore()
      .collection('provider_dispatch_private')
      .doc('provider1')
      .get());
  });

  it('rejects private fields in provider_public', async () => {
    const provider = testEnv.authenticatedContext('provider1', {
      phone_number: '+351910000002',
    });
    const providerDb = provider.firestore();
    await assertSucceeds(providerDb.collection('provider_public').doc('provider1').set({
      uid: 'provider1',
      displayName: 'Marta',
      city: 'Matola',
      isSearchable: false,
    }));
    await assertFails(providerDb.collection('provider_public').doc('provider1').set({
      uid: 'provider1',
      displayName: 'Marta',
      phone: '+258850000000',
    }));
    await assertFails(providerDb.collection('provider_public').doc('provider1').set({
      uid: 'provider1',
      displayName: 'Marta',
      lastLocation: { lat: -25.9, lng: 32.5 },
    }));
  });

  it('requires a verified phone before private or provider owner writes', async () => {
    const anonymous = testEnv.authenticatedContext('temporary-session').firestore();

    await assertFails(
      anonymous.collection('users_private').doc('temporary-session').set({
        uid: 'temporary-session',
        isAnonymous: true,
      }),
    );
    await assertFails(
      anonymous.collection('provider_public').doc('temporary-session').set({
        uid: 'temporary-session',
        isSearchable: false,
      }),
    );
    await assertFails(
      anonymous
        .collection('provider_dispatch_private')
        .doc('temporary-session')
        .set({
          providerId: 'temporary-session',
          isOnline: false,
        }),
    );
    await assertFails(
      anonymous
        .collection('users_private')
        .doc('temporary-session')
        .collection('fcmTokens')
        .doc('token')
        .set({ token: 'not-authorized' }),
    );
  });

  it('denies both legacy mixed collections', async () => {
    const user = testEnv.authenticatedContext('user1');
    const userDb = user.firestore();
    await assertFails(userDb.collection('users').doc('user1').get());
    await assertFails(userDb.collection('prestadores').doc('user1').get());
    await assertFails(userDb.collection('users').doc('user1').set({ uid: 'user1' }));
  });

  it('lets a provider read only sanitized open or targeted projections', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('provider_public').doc('provider1').set({
        uid: 'provider1',
        displayName: 'Marta',
        isSearchable: true,
        servicos: ['plumbing'],
        marketId: 'pt-coimbra',
        currency: 'EUR',
      });
      await db.collection('provider_public').doc('provider2').set({
        uid: 'provider2',
        displayName: 'Jose',
        isSearchable: true,
        servicos: ['plumbing'],
        marketId: 'pt-coimbra',
        currency: 'EUR',
      });
      await db.collection('pilot_participants').doc('provider1').set({
        status: 'active', roles: ['prestador'], city: 'Coimbra', marketId: 'pt-coimbra',
      });
      await db.collection('pilot_participants').doc('provider2').set({
        status: 'active', roles: ['prestador'], city: 'Coimbra', marketId: 'pt-coimbra',
      });
      await db.collection('pedidos').doc('pedido1').set({
        clienteId: 'client1',
        status: 'criado',
        estado: 'criado',
        prestadorId: null,
        enderecoTexto: 'Rua privada 123',
        latitude: -25.965432,
        longitude: 32.589876,
      });
      await db.collection('pedido_dispatch').doc('pedido1').set({
        pedidoId: 'pedido1',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'criado',
        estado: 'criado',
        prestadorId: null,
        targetProviderId: null,
        zoneLabel: 'Matola A',
        latitude: -25.97,
        longitude: 32.59,
      });
      await db.collection('pedido_dispatch').doc('directed_provider1').set({
        pedidoId: 'directed_provider1',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
        prestadorId: null,
        targetProviderId: 'provider1',
        valorMinEstimadoPrestador: 800,
        valorMaxEstimadoPrestador: 1000,
        statusProposta: 'pendente_cliente',
        propostaExpiresAt: new Date(Date.now() + 60 * 60 * 1000),
        zoneLabel: 'Matola A',
        enderecoTexto: 'Matola A',
      });
      await db.collection('pedido_dispatch').doc('directed_provider2').set({
        pedidoId: 'directed_provider2',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
        prestadorId: null,
        targetProviderId: 'provider2',
        valorMinEstimadoPrestador: 700,
        valorMaxEstimadoPrestador: 900,
        statusProposta: 'pendente_cliente',
        propostaExpiresAt: new Date(Date.now() + 60 * 60 * 1000),
        zoneLabel: 'Matola A',
        enderecoTexto: 'Matola A',
      });
      await db.collection('pedido_dispatch').doc('unsafe_targeted_message').set({
        pedidoId: 'unsafe_targeted_message',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'aguarda_resposta_prestador',
        prestadorId: null,
        targetProviderId: 'provider1',
        valorMinEstimadoPrestador: 800,
        valorMaxEstimadoPrestador: 1000,
        statusProposta: 'pendente_cliente',
        propostaExpiresAt: new Date(Date.now() + 60 * 60 * 1000),
        zoneLabel: 'Matola A',
        enderecoTexto: 'Matola A',
        mensagemPropostaPrestador: 'Liga-me no numero privado.',
      });
      await db.collection('pedido_dispatch').doc('unsafe_targeted_address').set({
        pedidoId: 'unsafe_targeted_address',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'aguarda_resposta_prestador',
        prestadorId: null,
        targetProviderId: 'provider1',
        valorMinEstimadoPrestador: 800,
        valorMaxEstimadoPrestador: 1000,
        statusProposta: 'pendente_cliente',
        propostaExpiresAt: new Date(Date.now() + 60 * 60 * 1000),
        zoneLabel: 'Matola A',
        enderecoTexto: 'Rua Privada 123, porta azul',
      });
      await db.collection('pedido_dispatch').doc('unsafe_projection').set({
        pedidoId: 'unsafe_projection',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'criado',
        prestadorId: null,
        targetProviderId: null,
        zoneLabel: 'Matola A',
        clienteId: 'client-secret',
      });
      await db.collection('pedido_dispatch').doc('other_market').set({
        pedidoId: 'other_market',
        marketId: 'mz-maputo',
        currency: 'MZN',
        status: 'criado',
        prestadorId: null,
        targetProviderId: null,
      });
      await db.collection('pedido_dispatch').doc('missing_market').set({
        pedidoId: 'missing_market',
        currency: 'EUR',
        status: 'criado',
        prestadorId: null,
        targetProviderId: null,
      });
      await db.collection('pedido_dispatch').doc('wrong_currency').set({
        pedidoId: 'wrong_currency',
        marketId: 'pt-coimbra',
        currency: 'MZN',
        status: 'criado',
        prestadorId: null,
        targetProviderId: null,
      });
    });

    const providerDb = testEnv.authenticatedContext('provider1', {
      phone_number: '+258840000000',
    }).firestore();
    const outsiderDb = testEnv.authenticatedContext('provider2', {
      phone_number: '+258840000002',
    }).firestore();
    const adminDb = testEnv.authenticatedContext('admin_dispatch', {
      admin: true,
    }).firestore();
    await assertSucceeds(providerDb.collection('pedido_dispatch').doc('pedido1').get());
    await assertSucceeds(providerDb.collection('pedido_dispatch')
      .doc('directed_provider1').get());
    await assertFails(providerDb.collection('pedido_dispatch')
      .doc('directed_provider2').get());
    await assertFails(outsiderDb.collection('pedido_dispatch')
      .doc('directed_provider1').get());
    await assertFails(providerDb.collection('pedido_dispatch')
      .doc('unsafe_targeted_message').get());
    await assertFails(providerDb.collection('pedido_dispatch')
      .doc('unsafe_targeted_address').get());
    await assertFails(providerDb.collection('pedido_dispatch')
      .doc('unsafe_projection').get());
    await assertFails(providerDb.collection('pedido_dispatch')
      .doc('other_market').get());
    await assertFails(providerDb.collection('pedido_dispatch')
      .doc('missing_market').get());
    await assertFails(providerDb.collection('pedido_dispatch')
      .doc('wrong_currency').get());
    await assertSucceeds(adminDb.collection('pedido_dispatch')
      .doc('unsafe_projection').get());
    await assertFails(providerDb.collection('pedidos').doc('pedido1').get());
  });

  it('authorizes the exact open-dispatch query used by the provider app', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('provider_public').doc('provider1').set({
        uid: 'provider1',
        displayName: 'Marta',
        isSearchable: true,
        servicos: ['plumbing'],
        marketId: 'pt-coimbra',
        currency: 'EUR',
      });
      await db.collection('provider_public').doc('provider_offboarded').set({
        uid: 'provider_offboarded',
        displayName: 'Perfil desativado',
        isSearchable: false,
        servicos: ['plumbing'],
        marketId: 'pt-coimbra',
        currency: 'EUR',
      });
      await db.collection('provider_public').doc('provider_suspended').set({
        uid: 'provider_suspended',
        displayName: 'Perfil suspenso',
        isSearchable: true,
        servicos: ['plumbing'],
        marketId: 'pt-coimbra',
        currency: 'EUR',
      });
      await db.collection('pilot_participants').doc('provider1').set({
        status: 'active', roles: ['prestador'], city: 'Coimbra', marketId: 'pt-coimbra',
      });
      await db.collection('pilot_participants').doc('provider_offboarded').set({
        status: 'active', roles: ['prestador'], city: 'Coimbra', marketId: 'pt-coimbra',
      });
      await db.collection('pilot_participants').doc('provider_suspended').set({
        status: 'active', roles: ['prestador'], city: 'Coimbra', marketId: 'pt-coimbra',
      });
      await db.collection('provider_private').doc('provider_suspended').set({
        providerId: 'provider_suspended',
        financialStatus: 'suspended_new_jobs',
      });
      await db.collection('pedido_dispatch').doc('open_query').set({
        pedidoId: 'open_query',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'criado',
        estado: 'criado',
        prestadorId: null,
        targetProviderId: null,
        zoneLabel: 'Matola A',
        enderecoTexto: 'Matola A',
        createdAt: new Date(),
      });
      await db.collection('pedido_dispatch').doc('target_query').set({
        pedidoId: 'target_query',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
        prestadorId: null,
        targetProviderId: 'provider1',
        statusProposta: 'nenhuma',
        propostaExpiresAt: null,
        zoneLabel: 'Matola A',
        enderecoTexto: 'Matola A',
        createdAt: new Date(),
      });
      await db.collection('pedido_dispatch').doc('created_target_other').set({
        pedidoId: 'created_target_other',
        marketId: 'pt-coimbra',
        currency: 'EUR',
        status: 'criado',
        estado: 'criado',
        prestadorId: null,
        targetProviderId: 'provider2',
        zoneLabel: 'Matola A',
        enderecoTexto: 'Matola A',
        createdAt: new Date(),
      });
    });

    const providerDb = testEnv.authenticatedContext('provider1', {
      phone_number: '+258840000000',
    }).firestore();
    const offboardedDb = testEnv.authenticatedContext('provider_offboarded', {
      phone_number: '+351910000003',
    }).firestore();
    const suspendedDb = testEnv.authenticatedContext('provider_suspended', {
      phone_number: '+351910000004',
    }).firestore();
    const exactQuery = providerDb.collection('pedido_dispatch')
      .where('marketId', '==', 'pt-coimbra')
      .where('currency', '==', 'EUR')
      .where('status', '==', 'criado')
      .where('prestadorId', '==', null)
      .where('targetProviderId', '==', null)
      .orderBy('createdAt', 'desc')
      .limit(100);
    await assertSucceeds(exactQuery.get());
    await assertFails(offboardedDb.collection('pedido_dispatch')
      .where('marketId', '==', 'pt-coimbra')
      .where('currency', '==', 'EUR')
      .where('status', '==', 'criado')
      .where('prestadorId', '==', null)
      .where('targetProviderId', '==', null)
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get());
    await assertFails(suspendedDb.collection('pedido_dispatch')
      .where('marketId', '==', 'pt-coimbra')
      .where('currency', '==', 'EUR')
      .where('status', '==', 'criado')
      .where('prestadorId', '==', null)
      .where('targetProviderId', '==', null)
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get());
    await assertSucceeds(providerDb.collection('pedido_dispatch')
      .where('marketId', '==', 'pt-coimbra')
      .where('currency', '==', 'EUR')
      .where('targetProviderId', '==', 'provider1')
      .where('prestadorId', '==', null)
      .limit(100)
      .get());

    const underConstrained = providerDb.collection('pedido_dispatch')
      .where('marketId', '==', 'pt-coimbra')
      .where('currency', '==', 'EUR')
      .where('status', '==', 'criado')
      .where('prestadorId', '==', null)
      .orderBy('createdAt', 'desc')
      .limit(100);
    await assertFails(underConstrained.get());
    await assertFails(providerDb.collection('pedido_dispatch')
      .where('currency', '==', 'EUR')
      .where('status', '==', 'criado')
      .where('prestadorId', '==', null)
      .where('targetProviderId', '==', null)
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get());
    await assertFails(providerDb.collection('pedido_dispatch')
      .where('marketId', '==', 'mz-maputo')
      .where('currency', '==', 'MZN')
      .where('status', '==', 'criado')
      .where('prestadorId', '==', null)
      .where('targetProviderId', '==', null)
      .orderBy('createdAt', 'desc')
      .limit(100)
      .get());
  });

  it('authorizes only the exact bounded private pedido queries used by the app', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('pilot_participants').doc('client_query').set({
        status: 'active', roles: ['cliente'], city: 'Coimbra',
      });
      await db.collection('pilot_participants').doc('provider_query').set({
        status: 'active', roles: ['prestador'], city: 'Coimbra',
      });
      await db.collection('pedidos').doc('client_private_query').set({
        clienteId: 'client_query',
        prestadorId: null,
        status: 'criado',
        estado: 'criado',
        createdAt: new Date(),
      });
      await db.collection('pedidos').doc('provider_private_query').set({
        clienteId: 'another_client',
        prestadorId: 'provider_query',
        providerAccessGranted: true,
        providerAccessGrantedTo: 'provider_query',
        providerAccessGrantedAt: new Date(),
        status: 'aceito',
        estado: 'aceito',
        createdAt: new Date(),
      });
      await db.collection('pedidos').doc('provider_without_grant_query').set({
        clienteId: 'another_client',
        prestadorId: 'provider_query',
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
        createdAt: new Date(),
      });
      await db.collection('pedidos').doc('provider_false_grant_marker').set({
        clienteId: 'another_client',
        prestadorId: 'provider_query',
        providerAccessGranted: false,
        providerAccessGrantedTo: 'provider_query',
        providerAccessGrantedAt: new Date(),
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
        createdAt: new Date(),
      });
      await db.collection('pedidos').doc('provider_malformed_grant_timestamp').set({
        clienteId: 'another_client',
        prestadorId: 'provider_query',
        providerAccessGranted: true,
        providerAccessGrantedTo: 'provider_query',
        providerAccessGrantedAt: 'not-a-timestamp',
        status: 'aceito',
        estado: 'aceito',
        createdAt: new Date(),
      });
    });

    const clientDb = testEnv.authenticatedContext('client_query', {
      phone_number: '+351910000001',
    }).firestore();
    const providerDb = testEnv.authenticatedContext('provider_query', {
      phone_number: '+351910000002',
    }).firestore();

    await assertSucceeds(clientDb.collection('pedidos')
      .where('clienteId', '==', 'client_query')
      .limit(200)
      .get());
    const providerSnapshot = await assertSucceeds(providerDb.collection('pedidos')
      .where('prestadorId', '==', 'provider_query')
      .where('providerAccessGranted', '==', true)
      .where('providerAccessGrantedTo', '==', 'provider_query')
      .where('status', 'in', [
        'aceito',
        'em_andamento',
        'aguarda_confirmacao_valor',
        'concluido',
      ])
      .where('providerAccessGrantedAt', '>', new Date(0))
      .where('providerAccessGrantedAt', '<', new Date('2100-01-01T00:00:00.000Z'))
      .orderBy('providerAccessGrantedAt', 'desc')
      .limit(200)
      .get());
    assert.deepStrictEqual(
      providerSnapshot.docs.map((doc) => doc.id).sort(),
      ['provider_private_query'],
    );

    await assertFails(clientDb.collection('pedidos')
      .where('clienteId', '==', 'client_query')
      .get());
    await assertFails(providerDb.collection('pedidos')
      .where('prestadorId', '==', 'provider_query')
      .limit(200)
      .get());
    await assertFails(providerDb.collection('pedidos')
      .where('prestadorId', '==', 'provider_query')
      .where('providerAccessGrantedTo', '==', 'provider_query')
      .limit(200)
      .get());
    await assertFails(providerDb.collection('pedidos')
      .where('prestadorId', '==', 'provider_query')
      .where('providerAccessGranted', '==', true)
      .where('providerAccessGrantedTo', '==', 'provider_query')
      .limit(200)
      .get());
    await assertFails(providerDb.collection('pedidos')
      .where('prestadorId', '==', 'provider_query')
      .where('providerAccessGranted', '==', true)
      .where('providerAccessGrantedTo', '==', 'provider_query')
      .where('providerAccessGrantedAt', '>', new Date(0))
      .orderBy('providerAccessGrantedAt', 'desc')
      .limit(200)
      .get());
    await assertFails(providerDb.collection('pedidos')
      .where('prestadorId', '==', 'provider_query')
      .where('providerAccessGranted', '==', true)
      .where('providerAccessGrantedTo', '==', 'provider_query')
      .where('status', 'in', [
        'aceito',
        'em_andamento',
        'aguarda_confirmacao_valor',
        'concluido',
      ])
      .where('providerAccessGrantedAt', '>', new Date(0))
      .orderBy('providerAccessGrantedAt', 'desc')
      .limit(200)
      .get());
    await assertFails(providerDb.collection('pedidos')
      .where('prestadorId', '==', 'provider_query')
      .where('providerAccessGranted', '==', true)
      .where('providerAccessGrantedTo', '==', 'provider_query')
      .where('status', 'in', [
        'aceito',
        'em_andamento',
        'aguarda_confirmacao_valor',
        'concluido',
      ])
      .where('providerAccessGrantedAt', '>', new Date(0))
      .where('providerAccessGrantedAt', '<', new Date('2100-01-01T00:00:00.000Z'))
      .orderBy('providerAccessGrantedAt', 'desc')
      .limit(201)
      .get());
  });

  it('requires an explicit provider grant for full pedido and chat access', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('pilot_participants').doc('client_grant').set({
        status: 'active', roles: ['cliente'], city: 'Maputo',
      });
      await db.collection('pilot_participants').doc('provider_grant').set({
        status: 'active', roles: ['prestador'], city: 'Maputo',
      });
      await db.collection('pedidos').doc('invite_pending').set({
        clienteId: 'client_grant',
        prestadorId: 'provider_grant',
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
      });
      await db.collection('pedidos').doc('quote_pending').set({
        clienteId: 'client_grant',
        prestadorId: 'provider_grant',
        providerAccessGranted: true,
        providerAccessGrantedTo: 'provider_grant',
        providerAccessGrantedAt: 'not-a-timestamp',
        status: 'aguarda_resposta_cliente',
        estado: 'aguarda_resposta_cliente',
      });
      await db.collection('pedidos').doc('accepted_granted').set({
        clienteId: 'client_grant',
        prestadorId: 'provider_grant',
        providerAccessGranted: true,
        providerAccessGrantedTo: 'provider_grant',
        providerAccessGrantedAt: new Date(),
        status: 'aceito',
        estado: 'aceito',
      });
      await db.collection('pedidos').doc('cancelled_grant').set({
        clienteId: 'client_grant',
        prestadorId: 'provider_grant',
        providerAccessGranted: true,
        providerAccessGrantedTo: 'provider_grant',
        providerAccessGrantedAt: new Date(),
        status: 'cancelado',
        estado: 'cancelado',
      });
      for (const pedidoId of [
        'invite_pending',
        'quote_pending',
        'accepted_granted',
        'cancelled_grant',
      ]) {
        await db.collection('chats').doc(pedidoId).set({
          pedidoId,
          clienteId: 'client_grant',
          prestadorId: 'provider_grant',
        });
      }
    });

    const providerDb = testEnv.authenticatedContext('provider_grant', {
      phone_number: '+258840000020',
    }).firestore();
    const clientDb = testEnv.authenticatedContext('client_grant', {
      phone_number: '+258840000021',
    }).firestore();

    await assertFails(providerDb.collection('pedidos').doc('invite_pending').get());
    await assertFails(providerDb.collection('pedidos').doc('quote_pending').get());
    await assertFails(providerDb.collection('chats').doc('invite_pending').get());
    await assertFails(providerDb.collection('chats').doc('quote_pending').get());
    await assertFails(providerDb.collection('pedidos').doc('cancelled_grant').get());
    await assertFails(providerDb.collection('chats').doc('cancelled_grant').get());
    await assertSucceeds(clientDb.collection('pedidos').doc('invite_pending').get());
    await assertSucceeds(providerDb.collection('pedidos').doc('accepted_granted').get());
    await assertSucceeds(providerDb.collection('chats').doc('accepted_granted').get());
    await assertSucceeds(clientDb.collection('pedidos').doc('cancelled_grant').get());
  });

  it('rejects direct request creation and edits of authoritative request details', async () => {
    const clientDb = testEnv.authenticatedContext('client1', {
      phone_number: '+258840000000',
    }).firestore();
    await assertFails(clientDb.collection('pedidos').doc('forged').set({
      clienteId: 'client1',
      status: 'criado',
      estado: 'criado',
      titulo: 'Pedido forjado',
    }));
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('pedidos').doc('secure').set({
        clienteId: 'client1',
        prestadorId: null,
        status: 'criado',
        estado: 'criado',
        titulo: 'Limpeza de casa',
        servicoId: 'home_cleaning',
        createdAt: new Date(),
        lastAuthoritativeFunction: 'pedidos_createSecure',
      });
    });
    await assertFails(clientDb.collection('pedidos').doc('secure').update({
      titulo: 'Venda de armas',
    }));
  });

  it('denies direct order transitions regardless of phone or pilot role', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      for (const clientId of ['client_active', 'client_unverified', 'client_outside']) {
        await db.collection('pedidos').doc(`order_${clientId}`).set({
          clienteId: clientId,
          prestadorId: null,
          status: 'criado',
          estado: 'criado',
          createdAt: new Date(),
        });
      }
      await db.collection('pilot_participants').doc('client_active').set({
        status: 'active', roles: ['cliente'], city: 'Maputo',
      });
      await db.collection('pilot_participants').doc('client_unverified').set({
        status: 'active', roles: ['cliente'], city: 'Maputo',
      });
    });

    const cancelPatch = () => ({
      status: 'cancelado',
      estado: 'cancelado',
      updatedAt: serverTimestamp(),
      canceladoPor: 'cliente',
      motivoCancelamento: 'Mudanca de planos',
    });
    const active = testEnv.authenticatedContext('client_active', {
      phone_number: '+258840000001',
    }).firestore();
    const unverified = testEnv.authenticatedContext('client_unverified').firestore();
    const outside = testEnv.authenticatedContext('client_outside', {
      phone_number: '+258840000003',
    }).firestore();

    await assertFails(active.collection('pedidos').doc('order_client_active')
      .update(cancelPatch()));
    await assertFails(unverified.collection('pedidos').doc('order_client_unverified')
      .update(cancelPatch()));
    await assertFails(outside.collection('pedidos').doc('order_client_outside')
      .update(cancelPatch()));
  });

  it('makes every participant pedido update callable-only while allowing admins', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('pilot_participants').doc('client_guard').set({
        status: 'active', roles: ['cliente'], city: 'Maputo',
      });
      await db.collection('pilot_participants').doc('provider_guard').set({
        status: 'active', roles: ['prestador'], city: 'Maputo',
      });
      await db.collection('pedidos').doc('cancel_guard').set({
        clienteId: 'client_guard',
        prestadorId: null,
        status: 'criado',
        estado: 'criado',
        createdAt: new Date('2026-07-20T10:00:00.000Z'),
        historico: [],
      });
      await db.collection('pedidos').doc('start_guard').set({
        clienteId: 'client_guard',
        prestadorId: 'provider_guard',
        status: 'aceito',
        estado: 'aceito',
        createdAt: new Date('2026-07-20T10:00:00.000Z'),
        historico: [],
      });
      await db.collection('pedidos').doc('no_show_guard').set({
        clienteId: 'client_guard',
        prestadorId: 'provider_guard',
        status: 'aceito',
        estado: 'aceito',
        createdAt: new Date('2026-07-20T10:00:00.000Z'),
      });
    });

    const client = testEnv.authenticatedContext('client_guard', {
      phone_number: '+258840000011',
    }).firestore();
    const provider = testEnv.authenticatedContext('provider_guard', {
      phone_number: '+258840000012',
    }).firestore();
    const cancelRef = client.collection('pedidos').doc('cancel_guard');
    const safeCancelPatch = () => ({
      status: 'cancelado',
      estado: 'cancelado',
      updatedAt: serverTimestamp(),
      canceladoPor: 'cliente',
      motivoCancelamento: 'Mudanca de planos',
    });

    await assertFails(cancelRef.update({
      ...safeCancelPatch(), paymentStatus: 'succeeded',
    }));
    await assertFails(cancelRef.update({
      ...safeCancelPatch(),
      paymentIntentId: 'pi_forged',
      paidAt: serverTimestamp(),
    }));
    await assertFails(cancelRef.update({
      ...safeCancelPatch(),
      precoPropostoPrestador: 1000,
      precoFinal: 1000,
      preco: 1000,
      commissionPlatform: 0,
      earningsProvider: 1000,
      earningsTotal: 1000,
    }));
    await assertFails(cancelRef.update({
      ...safeCancelPatch(), historico: [{ evento: 'forged' }],
    }));
    await assertFails(cancelRef.update({
      ...safeCancelPatch(),
      lastAuthoritativeFunction: 'forged_client',
      ultimoCancelamentoPrestadorEm: serverTimestamp(),
    }));
    await assertFails(cancelRef.update({
      ...safeCancelPatch(),
      concluidoEm: serverTimestamp(),
      completedAt: serverTimestamp(),
    }));
    await assertFails(cancelRef.update({
      ...safeCancelPatch(), tipoReembolso: 'total',
    }));
    await assertFails(cancelRef.update({
      ...safeCancelPatch(), updatedAt: new Date('2000-01-01T00:00:00.000Z'),
    }));
    await assertFails(cancelRef.update(safeCancelPatch()));

    const startRef = provider.collection('pedidos').doc('start_guard');
    await assertFails(startRef.update({
      status: 'em_andamento',
      estado: 'em_andamento',
      updatedAt: serverTimestamp(),
      historico: [{ evento: 'servico_iniciado_forjado' }],
    }));
    await assertFails(client.collection('pedidos').doc('start_guard').update({
      status: 'em_andamento',
      estado: 'em_andamento',
      updatedAt: serverTimestamp(),
    }));
    await assertFails(startRef.update({
      status: 'em_andamento',
      estado: 'em_andamento',
      updatedAt: serverTimestamp(),
    }));

    const noShowRef = client.collection('pedidos').doc('no_show_guard');
    await assertFails(noShowRef.update({
      noShowReportedBy: 'cliente',
      noShowReason: 'Prestador nao apareceu',
      noShowAt: new Date('2000-01-01T00:00:00.000Z'),
      updatedAt: serverTimestamp(),
    }));
    await assertFails(noShowRef.update({
      noShowReportedBy: 'cliente',
      noShowReason: 'Prestador nao apareceu',
      noShowAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));

    const admin = testEnv.authenticatedContext('admin_guard', {
      admin: true,
    }).firestore();
    await assertSucceeds(admin.collection('pedidos').doc('cancel_guard').update({
      status: 'cancelado',
      estado: 'cancelado',
      updatedAt: serverTimestamp(),
      lastAuthoritativeFunction: 'admin_manual_intervention',
    }));
  });

  it('rejects client-controlled provider services and category approvals', async () => {
    const providerDb = testEnv.authenticatedContext('provider1', {
      phone_number: '+258840000000',
    }).firestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('provider_public').doc('provider1').set({
        uid: 'provider1',
        isSearchable: true,
      });
    });
    await assertFails(providerDb.collection('provider_public').doc('provider1').update({
      servicos: ['electricity'],
    }));
    await assertFails(providerDb.collection('sensitiveCategoryRequests').doc('forged').set({
      providerId: 'provider1',
      categoryId: 'electricity',
      categoryName: 'Eletricidade',
      status: 'approved',
      evidenceTypes: [],
      portfolioUrls: [],
      documentRefs: [],
    }));
  });

  it('requires callables for invite, proposal, acceptance and completion', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('provider_public').doc('provider1').set({
        uid: 'provider1',
        isSearchable: true,
        servicos: ['plumbing'],
      });
      await db.collection('pilot_participants').doc('client1').set({
        status: 'active', roles: ['cliente'], city: 'Maputo',
      });
      await db.collection('pilot_participants').doc('provider1').set({
        status: 'active', roles: ['prestador'], city: 'Maputo',
      });
      await db.collection('pedidos').doc('open_order').set({
        clienteId: 'client1',
        prestadorId: null,
        servicoId: 'plumbing',
        status: 'criado',
        estado: 'criado',
        createdAt: new Date(),
      });
      await db.collection('pedidos').doc('invite_order').set({
        clienteId: 'client1',
        prestadorId: null,
        servicoId: 'plumbing',
        status: 'criado',
        estado: 'criado',
        createdAt: new Date(),
      });
      await db.collection('pedidos').doc('quote_order').set({
        clienteId: 'client1',
        prestadorId: null,
        servicoId: 'plumbing',
        status: 'criado',
        estado: 'criado',
        createdAt: new Date(),
      });
      await db.collection('pedidos').doc('finish_order').set({
        clienteId: 'client1',
        prestadorId: 'provider1',
        status: 'aguarda_confirmacao_valor',
        estado: 'aguarda_confirmacao_valor',
        statusConfirmacaoValor: 'pendente_cliente',
        precoPropostoPrestador: 1000,
        createdAt: new Date(),
      });
    });
    const providerDb = testEnv.authenticatedContext('provider1', {
      phone_number: '+258840000000',
    }).firestore();
    const clientDb = testEnv.authenticatedContext('client1', {
      phone_number: '+258850000000',
    }).firestore();
    await assertFails(clientDb.collection('pedidos').doc('invite_order').update({
      prestadorId: 'provider1',
      status: 'aguarda_resposta_prestador',
      estado: 'aguarda_resposta_prestador',
      updatedAt: serverTimestamp(),
      statusProposta: 'nenhuma',
      statusConfirmacaoValor: 'nenhum',
    }));
    await assertFails(providerDb.collection('pedidos').doc('quote_order').update({
      prestadorId: 'provider1',
      valorMinEstimadoPrestador: 800,
      valorMaxEstimadoPrestador: 1000,
      mensagemPropostaPrestador: 'Posso executar hoje.',
      statusProposta: 'pendente_cliente',
      propostaExpiresAt: new Date(Date.now() + 60 * 60 * 1000),
      statusConfirmacaoValor: 'nenhum',
      status: 'aguarda_resposta_cliente',
      estado: 'aguarda_resposta_cliente',
      updatedAt: serverTimestamp(),
    }));
    await assertFails(providerDb.collection('pedidos').doc('open_order').update({
      prestadorId: 'provider1',
      status: 'aceito',
      estado: 'aceito',
    }));
    await assertFails(clientDb.collection('pedidos').doc('finish_order').update({
      status: 'concluido',
      estado: 'concluido',
      statusConfirmacaoValor: 'confirmado_cliente',
      precoFinal: 1000,
      preco: 1000,
      commissionPlatform: 0,
      earningsProvider: 1000,
      earningsTotal: 1000,
    }));
  });

  it('keeps support ticket identity and status server-authoritative', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('support_tickets').doc('ticket1').set({
        uid: 'client1',
        category: 'account',
        subject: 'Conta e acesso',
        message: 'Mensagem criada pelo backend.',
        status: 'open',
        createdAt: new Date(),
      });
    });
    const ownerDb = testEnv.authenticatedContext('client1').firestore();
    const outsiderDb = testEnv.authenticatedContext('outsider').firestore();
    await assertSucceeds(ownerDb.collection('support_tickets').doc('ticket1').get());
    await assertFails(outsiderDb.collection('support_tickets').doc('ticket1').get());
    await assertFails(ownerDb.collection('support_tickets').doc('forged').set({
      uid: 'client1',
      status: 'resolved',
      message: 'Estado forjado no cliente.',
    }));
    await assertFails(ownerDb.collection('support_tickets').doc('ticket1').update({
      status: 'resolved',
    }));
  });

  it('makes account deletion and consent audits server-only', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('account_deletion_requests').doc('client1').set({
        uid: 'client1',
        status: 'pending',
        executeAt: new Date(Date.now() + 10000),
      });
      await db.collection('legal_consent_audit').doc('audit1').set({
        uid: 'client1',
        version: 'legal-2026-07-20-pilot-v3',
      });
    });
    const ownerDb = testEnv.authenticatedContext('client1').firestore();
    const outsiderDb = testEnv.authenticatedContext('outsider').firestore();
    await assertSucceeds(
      ownerDb.collection('account_deletion_requests').doc('client1').get(),
    );
    await assertFails(
      outsiderDb.collection('account_deletion_requests').doc('client1').get(),
    );
    await assertFails(
      ownerDb.collection('account_deletion_requests').doc('client1').update({ status: 'cancelled' }),
    );
    await assertFails(ownerDb.collection('legal_consent_audit').doc('audit1').get());
    await assertFails(ownerDb.collection('legal_consent_audit').doc('forged').set({
      uid: 'client1',
      version: 'forged',
    }));
  });

  it('keeps disabled stories and calls unavailable to modified clients', async () => {
    const providerDb = testEnv.authenticatedContext('provider1', {
      phone_number: '+258840000001',
    }).firestore();
    await assertFails(providerDb.collection('stories').doc('story1').set({
      prestadorId: 'provider1',
      mediaUrl: 'https://example.invalid/story.jpg',
    }));
    await assertFails(providerDb.collection('calls').doc('call1').set({
      callerId: 'provider1',
      calleeId: 'client1',
      status: 'ringing',
    }));
  });

  it('exposes only active, unexpired opportunities to an eligible owner with bounded queries', async () => {
    const future = Timestamp.fromMillis(Date.now() + 15 * 60 * 1000);
    const past = Timestamp.fromMillis(Date.now() - 1000);
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('pilot_participants').doc('provider1').set({
        uid: 'provider1',
        status: 'active',
        roles: ['prestador'],
        city: 'Maputo',
      });
      await db.collection('users_private').doc('provider1').set({
        uid: 'provider1',
        accountStatus: 'active',
      });
      await db.collection('provider_public').doc('provider1').set({
        uid: 'provider1',
        isSearchable: true,
        servicos: ['plumbing'],
      });
      await db.collection('provider_private').doc('provider1').set({
        providerId: 'provider1',
        financialStatus: 'active',
      });
      await db.collection('provider_dispatch_private').doc('provider1').set({
        providerId: 'provider1',
        acceptingRequests: true,
        acceptingNewJobs: true,
        isOnline: true,
        radiusKm: 10,
        lastLocation: { lat: -25.9653, lng: 32.5892 },
        geo: {
          geohash: 'kmp7v5',
          geopoint: new GeoPoint(-25.9653, 32.5892),
        },
        lastLocationAt: Timestamp.now(),
      });
      await db.collection('provider_opportunities').doc('opp1').set({
        providerId: 'provider1',
        pedidoId: 'order1',
        serviceId: 'plumbing',
        status: 'active',
        expiresAt: future,
      });
      await db.collection('provider_opportunities').doc('accepted').set({
        providerId: 'provider1',
        pedidoId: 'order2',
        serviceId: 'plumbing',
        status: 'accepted',
        expiresAt: future,
      });
      await db.collection('provider_opportunities').doc('expired').set({
        providerId: 'provider1',
        pedidoId: 'order3',
        serviceId: 'plumbing',
        status: 'active',
        expiresAt: past,
      });
      await db.collection('pilot_metrics_daily').doc('latest').set({
        mission: { numerator: 1, denominator: 2 },
      });
    });
    const providerDb = testEnv.authenticatedContext('provider1', {
      phone_number: '+258840000001',
    }).firestore();
    // A future lower bound lets Rules prove every potential result remains
    // unexpired relative to request.time, including small client/server skew.
    const queryThreshold = Timestamp.fromMillis(Date.now() + 60 * 1000);
    const outsiderDb = testEnv.authenticatedContext('outsider').firestore();
    const adminDb = testEnv.authenticatedContext('admin1', { admin: true }).firestore();
    await assertFails(providerDb.collection('pilot_participants').doc('provider1').get());
    await assertFails(providerDb.collection('pilot_participants').doc('provider1').update({
      status: 'active',
    }));
    await assertSucceeds(providerDb.collection('provider_opportunities').doc('opp1').get());
    await assertFails(providerDb.collection('provider_opportunities').doc('accepted').get());
    await assertFails(providerDb.collection('provider_opportunities').doc('expired').get());
    await assertFails(outsiderDb.collection('provider_opportunities').doc('opp1').get());
    await assertSucceeds(
      providerDb.collection('provider_opportunities')
        .where('providerId', '==', 'provider1')
        .where('status', '==', 'active')
        .where('expiresAt', '>', queryThreshold)
        .orderBy('expiresAt', 'asc')
        .limit(50)
        .get(),
    );
    await assertFails(
      providerDb.collection('provider_opportunities')
        .where('providerId', '==', 'provider1')
        .where('status', '==', 'active')
        .where('expiresAt', '>', queryThreshold)
        .orderBy('expiresAt', 'asc')
        .limit(51)
        .get(),
    );
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('provider_private').doc('provider1').update({
        financialStatus: 'suspended_new_jobs',
      });
    });
    await assertFails(providerDb.collection('provider_opportunities').doc('opp1').get());
    await assertFails(
      providerDb.collection('provider_opportunities')
        .where('providerId', '==', 'provider1')
        .where('status', '==', 'active')
        .where('expiresAt', '>', queryThreshold)
        .orderBy('expiresAt', 'asc')
        .limit(50)
        .get(),
    );
    await assertFails(providerDb.collection('pilot_metrics_daily').doc('latest').get());
    await assertSucceeds(adminDb.collection('pilot_metrics_daily').doc('latest').get());
  });
});
