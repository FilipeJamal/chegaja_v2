const assert = require('assert');

const {
  buildHealthReport,
  parseAuditSummary,
  parseFunctionsList,
  validateAuditSummary,
  validateFunctionsHealth,
} = require('../health/firebase_production_health');

const functionsListJson = JSON.stringify({
  result: [
    { id: 'europe-west1-proporValorFinalPedido', runtime: 'nodejs22' },
    { id: 'europe-west1-confirmarValorFinalPedido', runtime: 'nodejs22' },
  ],
});

const functionsSummary = parseFunctionsList(functionsListJson);
assert.strictEqual(functionsSummary.functionCount, 2);
assert.deepStrictEqual(functionsSummary.runtimes, { nodejs22: 2 });

assert.doesNotThrow(() => validateFunctionsHealth(functionsSummary, {
  expectedRuntime: 'nodejs22',
  expectedFunctionCount: 2,
}));

assert.throws(
  () => validateFunctionsHealth(functionsSummary, {
    expectedRuntime: 'nodejs22',
    expectedFunctionCount: 27,
  }),
  /Expected 27 Functions/,
);

assert.throws(
  () => validateFunctionsHealth(
    { functionCount: 2, runtimes: { nodejs20: 1, nodejs22: 1 } },
    { expectedRuntime: 'nodejs22', expectedFunctionCount: 2 },
  ),
  /Unexpected Function runtimes/,
);

const auditOkJson = JSON.stringify({
  metadata: {
    vulnerabilities: {
      critical: 0,
      high: 0,
      moderate: 0,
      low: 9,
      info: 0,
    },
  },
});

const auditSummary = parseAuditSummary(auditOkJson);
assert.deepStrictEqual(auditSummary, {
  critical: 0,
  high: 0,
  moderate: 0,
  low: 9,
  info: 0,
});
assert.doesNotThrow(() => validateAuditSummary(auditSummary));

assert.throws(
  () => validateAuditSummary({
    critical: 1,
    high: 0,
    moderate: 0,
    low: 0,
    info: 0,
  }),
  /critical\/high\/moderate/,
);

const report = buildHealthReport({
  firebaseLogin: 'ok',
  project: 'chegaja-ac88d',
  functionCount: 27,
  runtimes: { nodejs22: 27 },
  audit: {
    critical: 0,
    high: 0,
    moderate: 0,
    low: 9,
    info: 0,
  },
});

assert(report.includes('firebaseLogin=ok'));
assert(report.includes('project=chegaja-ac88d'));
assert(report.includes('functionCount=27'));
assert(report.includes('runtimes=nodejs22=27'));
assert(report.includes('auditLow=9'));
assert(report.includes('status=OK'));

console.log('firebase_production_health parsing ok');
