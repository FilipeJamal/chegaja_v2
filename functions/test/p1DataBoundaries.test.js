const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'chegaja-ac88d';
const FIRESTORE_RULES = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8',
);

describe('P1 public/private data boundaries', function () {
  this.timeout(120000);
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
    const owner = testEnv.authenticatedContext('client1');
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
  });

  it('isolates users_private from every other signed-in user', async () => {
    const owner = testEnv.authenticatedContext('client1');
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
    const provider = testEnv.authenticatedContext('provider1');
    const outsider = testEnv.authenticatedContext('outsider');
    await assertSucceeds(provider.firestore()
      .collection('provider_dispatch_private')
      .doc('provider1')
      .set({
        providerId: 'provider1',
        isOnline: true,
        lastLocation: { lat: -25.9, lng: 32.5 },
      }));
    await assertFails(outsider.firestore()
      .collection('provider_dispatch_private')
      .doc('provider1')
      .get());
  });

  it('rejects private fields in provider_public', async () => {
    const provider = testEnv.authenticatedContext('provider1');
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

  it('denies both legacy mixed collections', async () => {
    const user = testEnv.authenticatedContext('user1');
    const userDb = user.firestore();
    await assertFails(userDb.collection('users').doc('user1').get());
    await assertFails(userDb.collection('prestadores').doc('user1').get());
    await assertFails(userDb.collection('users').doc('user1').set({ uid: 'user1' }));
  });

  it('lets a provider read only the sanitized open-request projection', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('provider_public').doc('provider1').set({
        uid: 'provider1',
        displayName: 'Marta',
        servicos: ['plumbing'],
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
        status: 'criado',
        estado: 'criado',
        prestadorId: null,
        zoneLabel: 'Matola A',
        latitude: -25.97,
        longitude: 32.59,
      });
    });

    const providerDb = testEnv.authenticatedContext('provider1', {
      phone_number: '+258840000000',
    }).firestore();
    await assertSucceeds(providerDb.collection('pedido_dispatch').doc('pedido1').get());
    await assertFails(providerDb.collection('pedidos').doc('pedido1').get());
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

  it('requires the backend for acceptance and final financial confirmation', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('provider_public').doc('provider1').set({
        uid: 'provider1',
        isSearchable: true,
        servicos: ['plumbing'],
      });
      await db.collection('pedidos').doc('open_order').set({
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
        version: 'legal-2026-07-20-pilot-v2',
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

  it('protects pilot allowlist and aggregate metrics while exposing own opportunities', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('pilot_participants').doc('provider1').set({
        uid: 'provider1',
        status: 'active',
        roles: ['prestador'],
        city: 'Maputo',
      });
      await db.collection('provider_opportunities').doc('opp1').set({
        providerId: 'provider1',
        pedidoId: 'order1',
      });
      await db.collection('pilot_metrics_daily').doc('latest').set({
        mission: { numerator: 1, denominator: 2 },
      });
    });
    const providerDb = testEnv.authenticatedContext('provider1').firestore();
    const outsiderDb = testEnv.authenticatedContext('outsider').firestore();
    const adminDb = testEnv.authenticatedContext('admin1', { admin: true }).firestore();
    await assertFails(providerDb.collection('pilot_participants').doc('provider1').get());
    await assertFails(providerDb.collection('pilot_participants').doc('provider1').update({
      status: 'active',
    }));
    await assertSucceeds(providerDb.collection('provider_opportunities').doc('opp1').get());
    await assertFails(outsiderDb.collection('provider_opportunities').doc('opp1').get());
    await assertFails(providerDb.collection('pilot_metrics_daily').doc('latest').get());
    await assertSucceeds(adminDb.collection('pilot_metrics_daily').doc('latest').get());
  });
});
