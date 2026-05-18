const assert = require('assert');

const {
  applyCleanupPlan,
  buildCleanupPlan,
  formatPlanReport,
  resolveCleanupOptions,
} = require('../admin/cleanup_smoke_data');

const defaultOptions = resolveCleanupOptions(['--prefix=m274_smoke_']);
assert.strictEqual(defaultOptions.prefix, 'm274_smoke_');
assert.strictEqual(defaultOptions.dryRun, true);
assert.strictEqual(defaultOptions.confirm, false);
assert.strictEqual(defaultOptions.verbose, false);
assert.strictEqual(defaultOptions.json, false);

const verboseOptions = resolveCleanupOptions(['--prefix=m274_smoke_', '--verbose', '--json']);
assert.strictEqual(verboseOptions.verbose, true);
assert.strictEqual(verboseOptions.json, true);

const confirmedOptions = resolveCleanupOptions([
  '--prefix',
  'm274_smoke_',
  '--confirm',
  '--confirm-prefix=m274_smoke_',
]);
assert.strictEqual(confirmedOptions.prefix, 'm274_smoke_');
assert.strictEqual(confirmedOptions.dryRun, false);
assert.strictEqual(confirmedOptions.confirm, true);
assert.strictEqual(confirmedOptions.confirmPrefix, 'm274_smoke_');

assert.throws(
  () => resolveCleanupOptions([]),
  /--prefix is required/,
);

assert.throws(
  () => resolveCleanupOptions(['--prefix=abc']),
  /too short/,
);

assert.throws(
  () => resolveCleanupOptions(['--prefix=m274_smoke_/bad']),
  /plain smoke id prefix/,
);

assert.throws(
  () => resolveCleanupOptions(['--prefix=m274_smoke_', '--unknown']),
  /Unknown argument/,
);

assert.throws(
  () => resolveCleanupOptions(['--prefix=m274_smoke_', '--confirm']),
  /--confirm-prefix is required/,
);

assert.throws(
  () => resolveCleanupOptions([
    '--prefix=m274_smoke_',
    '--confirm',
    '--confirm-prefix=wrong_prefix_',
  ]),
  /must match --prefix/,
);

const plan = buildCleanupPlan({
  pedidos: [
    {
      id: 'm274_smoke_1_pedido',
      data: { clienteId: 'client1', prestadorId: 'provider1' },
    },
  ],
  users: [
    { id: 'client1', data: { smokeRunId: 'm274_smoke_1' } },
    { id: 'outsider1', data: { smokeRunId: 'm274_smoke_1' } },
  ],
  prestadores: [
    { id: 'provider1', data: { smokeRunId: 'm274_smoke_1' } },
  ],
  storageFiles: [
    'pedidos/m274_smoke_1_pedido/anexos/m274_smoke_1.png',
    'temp/client1/anexos/m274_smoke_1.png',
  ],
});

assert.deepStrictEqual(plan.firestorePaths.sort(), [
  'pedidos/m274_smoke_1_pedido',
  'prestadores/provider1',
  'users/client1',
  'users/outsider1',
].sort());
assert.deepStrictEqual(plan.authUids.sort(), ['client1', 'outsider1'].sort());
assert.deepStrictEqual(plan.storageFiles.sort(), [
  'pedidos/m274_smoke_1_pedido/anexos/m274_smoke_1.png',
  'temp/client1/anexos/m274_smoke_1.png',
].sort());

const verboseReport = formatPlanReport(plan, { verbose: true });
assert(verboseReport.includes('pedidos/m274_smoke_1_pedido'));
assert(verboseReport.includes('storage: pedidos/m274_smoke_1_pedido/anexos/m274_smoke_1.png'));
assert(verboseReport.includes('auth: client1'));

const jsonReport = JSON.parse(formatPlanReport(plan, { json: true }));
assert.deepStrictEqual(jsonReport.summary, {
  firestoreDocs: 4,
  storageFiles: 2,
  authUsers: 2,
});
assert.deepStrictEqual(jsonReport.firestorePaths, plan.firestorePaths);
assert.deepStrictEqual(jsonReport.storageFiles, plan.storageFiles);
assert.deepStrictEqual(jsonReport.authUids, plan.authUids);

const deletes = [];
const fakeDeps = {
  deleteFirestorePath: async (path) => deletes.push(`doc:${path}`),
  deleteStorageFile: async (name) => deletes.push(`file:${name}`),
  deleteAuthUsers: async (uids) => deletes.push(`auth:${uids.join(',')}`),
};

applyCleanupPlan(plan, fakeDeps, { dryRun: true, confirm: false }).then((result) => {
  assert.deepStrictEqual(deletes, []);
  assert.strictEqual(result.firestoreDocs, 4);
  assert.strictEqual(result.storageFiles, 2);
  assert.strictEqual(result.authUsers, 2);

  return assert.rejects(
    () => applyCleanupPlan(plan, fakeDeps, { dryRun: false, confirm: false }),
    /--confirm is required/,
  );
}).then(() => {
  console.log('cleanup_smoke_data safeguards ok');
}).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
