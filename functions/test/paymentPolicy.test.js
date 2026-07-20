const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
const { __test__ } = require('../index');

describe('pilot payment policy', () => {
  const original = { ...process.env };

  afterEach(() => {
    for (const key of [
      'ENABLE_MPESA',
      'ENABLE_EMOLA',
      'ENABLE_STRIPE',
      'STRIPE_MZN_VALIDATED',
      'DEFAULT_CASH_COMMISSION_RATE',
      'COMMISSION_FREE_FIRST_JOBS',
    ]) {
      if (original[key] === undefined) delete process.env[key];
      else process.env[key] = original[key];
    }
  });

  it('waives the first two cash commissions and then uses the pilot rate', () => {
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
    assert.strictEqual(result.currency, 'MZN');
  });

  it('keeps unvalidated payment providers disabled server-side', () => {
    process.env.ENABLE_MPESA = 'false';
    process.env.ENABLE_STRIPE = 'true';
    process.env.STRIPE_MZN_VALIDATED = 'false';
    assert.strictEqual(__test__.payments.paymentMethodEnabled('dinheiro'), true);
    assert.strictEqual(__test__.payments.paymentMethodEnabled('mpesa'), false);
    assert.strictEqual(__test__.payments.paymentMethodEnabled('stripe'), false);
    process.env.ENABLE_MPESA = 'true';
    assert.strictEqual(__test__.payments.paymentMethodEnabled('mpesa'), true);
  });
});
