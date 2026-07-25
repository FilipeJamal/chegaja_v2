const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
const { __test__ } = require('../index');

describe('pilot payment policy', () => {
  const original = { ...process.env };

  function configureMarket(marketId, currency) {
    process.env.PILOT_MARKET_ID = marketId;
    process.env.DEFAULT_CURRENCY_CODE = currency;
  }

  afterEach(() => {
    for (const key of [
      'PILOT_MARKET_ID',
      'DEFAULT_CURRENCY_CODE',
      'ENABLE_MPESA',
      'ENABLE_EMOLA',
      'ENABLE_STRIPE',
      'STRIPE_MARKET_VALIDATED',
      'STRIPE_MZN_VALIDATED',
      'ENABLE_SUBSCRIPTIONS',
      'DEFAULT_CASH_COMMISSION_RATE',
      'COMMISSION_FREE_FIRST_JOBS',
    ]) {
      if (original[key] === undefined) delete process.env[key];
      else process.env[key] = original[key];
    }
  });

  it('waives the first two cash commissions and then uses the pilot rate', () => {
    configureMarket('pt-coimbra', 'EUR');
    process.env.DEFAULT_CASH_COMMISSION_RATE = '0.10';
    process.env.COMMISSION_FREE_FIRST_JOBS = '2';
    assert.strictEqual(__test__.pedidos.cashCommissionPolicy({ completedJobsCount: 0 }).commissionRate, 0);
    assert.strictEqual(__test__.pedidos.cashCommissionPolicy({ completedJobsCount: 1 }).commissionRate, 0);
    const chargedPolicy = __test__.pedidos.cashCommissionPolicy({ completedJobsCount: 2 });
    assert.strictEqual(chargedPolicy.commissionRate, 0.10);
    assert.strictEqual(chargedPolicy.commissionCap, null);
    const result = __test__.pedidos.calculatePedidoEconomics(1000, { commissionRate: 0.10 });
    assert.strictEqual(result.commissionPlatform, 100);
    assert.strictEqual(result.earningsProvider, 900);
    assert.strictEqual(result.currency, 'EUR');
  });

  it('requires an explicit rate instead of silently charging a default', () => {
    configureMarket('pt-coimbra', 'EUR');
    delete process.env.DEFAULT_CASH_COMMISSION_RATE;
    assert.throws(
      () => __test__.pedidos.cashCommissionPolicy({ completedJobsCount: 2 }),
      (error) => error.code === 'failed-precondition',
    );
  });

  it('accepts only a succeeded authoritative payment for the exact order', () => {
    configureMarket('pt-coimbra', 'EUR');
    const payment = {
      pedidoId: 'order-1',
      clienteId: 'client-1',
      prestadorId: 'provider-1',
      amount: 100000,
      feeAmount: 10000,
      marketId: 'pt-coimbra',
      currency: 'eur',
      status: 'succeeded',
    };
    const expected = {
      pedidoId: 'order-1',
      clienteId: 'client-1',
      prestadorId: 'provider-1',
      amount: 100000,
      currency: 'EUR',
    };
    assert.strictEqual(
      __test__.payments.authoritativeDigitalPaymentMatches(payment, expected),
      true,
    );
    assert.strictEqual(
      __test__.payments.authoritativeDigitalPaymentMatches({
        ...payment,
        status: 'requires_payment_method',
      }, expected),
      false,
    );
    assert.strictEqual(
      __test__.payments.authoritativeDigitalPaymentMatches({
        ...payment,
        pedidoId: 'other-order',
      }, expected),
      false,
    );
    assert.strictEqual(
      __test__.payments.authoritativeDigitalPaymentMatches({
        ...payment,
        feeAmount: 100001,
      }, expected),
      false,
    );
  });

  it('keeps unvalidated payment providers disabled server-side', () => {
    configureMarket('mz-maputo', 'MZN');
    process.env.ENABLE_MPESA = 'false';
    process.env.ENABLE_STRIPE = 'true';
    process.env.STRIPE_MARKET_VALIDATED = 'false';
    process.env.STRIPE_MZN_VALIDATED = 'false';
    process.env.ENABLE_SUBSCRIPTIONS = 'true';
    assert.strictEqual(__test__.payments.paymentMethodEnabled('dinheiro'), true);
    assert.strictEqual(__test__.payments.paymentMethodEnabled('mpesa'), false);
    assert.strictEqual(__test__.payments.paymentMethodEnabled('stripe'), false);
    assert.strictEqual(__test__.payments.subscriptionsEnabled(), false);
    process.env.ENABLE_MPESA = 'true';
    assert.strictEqual(__test__.payments.paymentMethodEnabled('mpesa'), true);
    process.env.STRIPE_MZN_VALIDATED = 'true';
    assert.strictEqual(__test__.payments.paymentMethodEnabled('stripe'), true);
    assert.strictEqual(__test__.payments.subscriptionsEnabled(), true);
    process.env.ENABLE_SUBSCRIPTIONS = 'false';
    assert.strictEqual(__test__.payments.subscriptionsEnabled(), false);
  });
});
