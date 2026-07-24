const assert = require('assert');
const { Timestamp } = require('firebase-admin/firestore');

process.env.FUNCTIONS_EMULATOR = 'true';
process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || 'chegaja-ac88d';

const { __test__ } = require('../index');

describe('authoritative Stripe payment security', function () {
  this.timeout(300000);
  const db = __test__.getDb();
  const originalEnv = { ...process.env };
  const collections = [
    'pedidos',
    'payments',
    'payment_ledger',
    'payment_webhook_quarantine',
    'stripe_webhook_events',
    'users_private',
    'pilot_participants',
    'provider_public',
    'provider_private',
    'provider_dispatch_private',
  ];

  function legalConsent() {
    return {
      version: __test__.legal.LEGAL_DOCUMENT_VERSION,
      termsAccepted: true,
      privacyAccepted: true,
      ageConfirmed: true,
    };
  }

  async function clearCollections() {
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
  }

  async function seedEligiblePayment(pedidoId, overrides = {}) {
    await Promise.all([
      db.collection('users_private').doc('client-pay').set({
        legalConsent: legalConsent(),
        accountStatus: 'active',
      }),
      db.collection('users_private').doc('provider-pay').set({
        legalConsent: legalConsent(),
        accountStatus: 'active',
      }),
      db.collection('pilot_participants').doc('client-pay').set({
        status: 'active',
        roles: ['cliente'],
        city: 'Maputo',
      }),
      db.collection('pilot_participants').doc('provider-pay').set({
        status: 'active',
        roles: ['prestador'],
        city: 'Maputo',
      }),
      db.collection('provider_public').doc('provider-pay').set({
        isSearchable: true,
        servicos: ['service-pay'],
      }),
      db.collection('provider_private').doc('provider-pay').set({
        providerId: 'provider-pay',
        stripeAccountId: 'acct_provider_pay',
        financialStatus: 'active',
      }),
      db.collection('provider_dispatch_private').doc('provider-pay').set({
        providerId: 'provider-pay',
        acceptingNewJobs: true,
      }),
    ]);
    await db.collection('pedidos').doc(pedidoId).set({
      clienteId: 'client-pay',
      prestadorId: 'provider-pay',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider-pay',
      providerAccessGrantedAt: Timestamp.now(),
      servicoId: 'service-pay',
      status: 'aguarda_confirmacao_valor',
      estado: 'aguarda_confirmacao_valor',
      statusConfirmacaoValor: 'pendente_cliente',
      moderationStatus: 'approved',
      tipoPagamento: 'stripe',
      currency: 'MZN',
      precoPropostoPrestador: 1000,
      ...overrides,
    });
  }

  function createFakeStripe({ accountReady = true } = {}) {
    const intents = new Map();
    const calls = { accountRetrieve: 0, create: [], retrieve: [], cancel: [] };
    return {
      calls,
      intents,
      accounts: {
        async retrieve(id) {
          calls.accountRetrieve += 1;
          return {
            id,
            charges_enabled: accountReady,
            payouts_enabled: accountReady,
          };
        },
      },
      paymentIntents: {
        async create(payload, options) {
          calls.create.push({ payload, options });
          const intent = {
            id: 'pi_secure_1',
            client_secret: 'pi_secure_1_secret',
            status: 'requires_payment_method',
            ...payload,
          };
          intents.set(intent.id, intent);
          return intent;
        },
        async retrieve(id) {
          calls.retrieve.push(id);
          return intents.get(id);
        },
        async cancel(id, payload, options) {
          calls.cancel.push({ id, payload, options });
          const current = intents.get(id);
          if (current) intents.set(id, { ...current, status: 'canceled' });
        },
      },
    };
  }

  beforeEach(async () => {
    process.env.ENABLE_STRIPE = 'true';
    process.env.STRIPE_MZN_VALIDATED = 'true';
    process.env.DEFAULT_CURRENCY_CODE = 'MZN';
    process.env.DEFAULT_DIGITAL_COMMISSION_RATE = '0.15';
    process.env.PILOT_REQUIRE_ALLOWLIST = 'true';
    await clearCollections();
  });

  after(() => {
    for (const key of [
      'ENABLE_STRIPE',
      'STRIPE_MZN_VALIDATED',
      'DEFAULT_CURRENCY_CODE',
      'DEFAULT_DIGITAL_COMMISSION_RATE',
      'PILOT_REQUIRE_ALLOWLIST',
    ]) {
      if (originalEnv[key] === undefined) delete process.env[key];
      else process.env[key] = originalEnv[key];
    }
  });

  it('creates one compatible intent with a deterministic idempotency key and reuses it', async () => {
    await seedEligiblePayment('pedido-secure');
    const stripe = createFakeStripe();

    const first = await __test__.payments.createPaymentIntentCore({
      database: db,
      stripe,
      uid: 'client-pay',
      pedidoId: 'pedido-secure',
    });
    const second = await __test__.payments.createPaymentIntentCore({
      database: db,
      stripe,
      uid: 'client-pay',
      pedidoId: 'pedido-secure',
    });

    assert.strictEqual(first.paymentIntentId, 'pi_secure_1');
    assert.deepStrictEqual(second, first);
    assert.strictEqual(stripe.calls.create.length, 1);
    assert.strictEqual(stripe.calls.retrieve.length, 1);
    assert.match(stripe.calls.create[0].options.idempotencyKey, /^chegaja:pedido:[a-f0-9]{64}$/);
    assert.strictEqual(
      stripe.calls.create[0].payload.metadata.paymentSpecHash,
      stripe.calls.create[0].options.idempotencyKey.split(':').pop(),
    );

    const pedido = (await db.collection('pedidos').doc('pedido-secure').get()).data();
    const payment = (await db.collection('payments').doc('pi_secure_1').get()).data();
    assert.strictEqual(pedido.paymentIntentId, 'pi_secure_1');
    assert.strictEqual(pedido.paymentAmount, 100000);
    assert.strictEqual(pedido.paymentFeeAmount, 15000);
    assert.strictEqual(payment.paymentSpecHash, pedido.paymentSpecHash);
    const ledger = await db.collection('payment_ledger')
      .where('eventType', '==', 'payment_intent_created')
      .get();
    assert.strictEqual(ledger.size, 1);
  });

  it('rejects invalid workflow state before contacting Stripe', async () => {
    await seedEligiblePayment('pedido-invalid-state', {
      status: 'em_andamento',
      estado: 'em_andamento',
    });
    const stripe = createFakeStripe();
    await assert.rejects(
      () => __test__.payments.createPaymentIntentCore({
        database: db,
        stripe,
        uid: 'client-pay',
        pedidoId: 'pedido-invalid-state',
      }),
      (error) => error.code === 'failed-precondition',
    );
    assert.strictEqual(stripe.calls.accountRetrieve, 0);
    assert.strictEqual(stripe.calls.create.length, 0);
  });

  it('rejects self-dealing and a provider account that cannot charge and pay out', async () => {
    await seedEligiblePayment('pedido-self-deal', {
      clienteId: 'provider-pay',
    });
    const stripe = createFakeStripe();
    await assert.rejects(
      () => __test__.payments.createPaymentIntentCore({
        database: db,
        stripe,
        uid: 'provider-pay',
        pedidoId: 'pedido-self-deal',
      }),
      (error) => error.code === 'permission-denied',
    );
    assert.strictEqual(stripe.calls.create.length, 0);

    await seedEligiblePayment('pedido-account-disabled');
    const disabledStripe = createFakeStripe({ accountReady: false });
    await assert.rejects(
      () => __test__.payments.createPaymentIntentCore({
        database: db,
        stripe: disabledStripe,
        uid: 'client-pay',
        pedidoId: 'pedido-account-disabled',
      }),
      (error) => error.code === 'failed-precondition',
    );
    assert.strictEqual(disabledStripe.calls.create.length, 0);
  });

  it('blocks an incompatible pre-existing payment instead of creating a second intent', async () => {
    await seedEligiblePayment('pedido-existing', {
      paymentIntentId: 'pi_existing',
      paymentAmount: 100000,
      paymentCurrency: 'mzn',
      paymentFeeAmount: 15000,
    });
    await db.collection('payments').doc('pi_existing').set({
      paymentIntentId: 'pi_existing',
      pedidoId: 'pedido-existing',
      clienteId: 'client-pay',
      prestadorId: 'provider-pay',
      amount: 99999,
      feeAmount: 15000,
      currency: 'mzn',
      status: 'requires_payment_method',
    });
    const stripe = createFakeStripe();
    await assert.rejects(
      () => __test__.payments.createPaymentIntentCore({
        database: db,
        stripe,
        uid: 'client-pay',
        pedidoId: 'pedido-existing',
      }),
      (error) => error.code === 'failed-precondition',
    );
    assert.strictEqual(stripe.calls.create.length, 0);
    assert.strictEqual(stripe.calls.retrieve.length, 0);
  });

  it('processes a valid webhook exactly once with an event-bound ledger entry', async () => {
    await seedEligiblePayment('pedido-webhook');
    const stripe = createFakeStripe();
    await __test__.payments.createPaymentIntentCore({
      database: db,
      stripe,
      uid: 'client-pay',
      pedidoId: 'pedido-webhook',
    });
    const intent = stripe.intents.get('pi_secure_1');
    const event = {
      id: 'evt_payment_succeeded_1',
      type: 'payment_intent.succeeded',
      created: 1721510400,
      data: {
        object: {
          ...intent,
          status: 'succeeded',
          amount_received: intent.amount,
        },
      },
    };

    const first = await __test__.payments.processStripePaymentEventCore({ database: db, event });
    const second = await __test__.payments.processStripePaymentEventCore({ database: db, event });
    assert.strictEqual(first.status, 'processed');
    assert.strictEqual(second.status, 'processed');
    assert.strictEqual(second.idempotent, true);
    assert.strictEqual(
      (await db.collection('pedidos').doc('pedido-webhook').get()).data().paymentStatus,
      'succeeded',
    );
    const ledger = await db.collection('payment_ledger')
      .where('eventId', '==', event.id)
      .get();
    assert.strictEqual(ledger.size, 1);
  });

  it('quarantines inconsistent webhook metadata without mutating pedido or payment', async () => {
    await seedEligiblePayment('pedido-quarantine');
    const stripe = createFakeStripe();
    await __test__.payments.createPaymentIntentCore({
      database: db,
      stripe,
      uid: 'client-pay',
      pedidoId: 'pedido-quarantine',
    });
    const intent = stripe.intents.get('pi_secure_1');
    const beforePedido = (await db.collection('pedidos').doc('pedido-quarantine').get()).data();
    const beforePayment = (await db.collection('payments').doc('pi_secure_1').get()).data();
    const event = {
      id: 'evt_payment_bad_actor',
      type: 'payment_intent.succeeded',
      created: 1721510401,
      data: {
        object: {
          ...intent,
          status: 'succeeded',
          amount_received: intent.amount,
          metadata: { ...intent.metadata, clienteId: 'attacker' },
        },
      },
    };

    const result = await __test__.payments.processStripePaymentEventCore({ database: db, event });
    assert.strictEqual(result.status, 'quarantined');
    assert.ok(result.reasons.includes('cliente_mismatch'));
    const quarantine = await db.collection('payment_webhook_quarantine').doc(event.id).get();
    assert.strictEqual(quarantine.exists, true);
    const afterPedido = (await db.collection('pedidos').doc('pedido-quarantine').get()).data();
    const afterPayment = (await db.collection('payments').doc('pi_secure_1').get()).data();
    assert.strictEqual(afterPedido.paymentStatus, beforePedido.paymentStatus);
    assert.strictEqual(afterPayment.status, beforePayment.status);
    const ledger = await db.collection('payment_ledger').where('eventId', '==', event.id).get();
    assert.strictEqual(ledger.size, 0);
  });
});
