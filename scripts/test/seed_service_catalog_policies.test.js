const assert = require('assert');

const {
  exportPolicies,
  firestoreFields,
  optionsFrom,
} = require('../admin/seed_service_catalog_policies');

const policies = exportPolicies();
assert(policies.length >= 10);
assert(policies.every((policy) => policy.id && policy.name));
assert(policies.some((policy) => policy.approvalRequired));

assert.deepStrictEqual(firestoreFields({
  enabled: true,
  count: 2,
  labels: ['a', 'b'],
}), {
  enabled: { booleanValue: true },
  count: { integerValue: '2' },
  labels: {
    arrayValue: {
      values: [{ stringValue: 'a' }, { stringValue: 'b' }],
    },
  },
});

assert.throws(
  () => optionsFrom(['--confirm', '--project=prod', '--confirm-project=other']),
  /confirm-project/,
);
assert.strictEqual(optionsFrom(['--project=test']).confirm, false);

console.log('seed_service_catalog_policies safeguards ok');
