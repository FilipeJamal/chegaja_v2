const assert = require('assert');

const {
  partitionProvider,
  partitionUser,
  resolveOptions,
} = require('../admin/migrate_p1_data_boundaries');

const user = partitionUser('u1', {
  displayName: 'Ana',
  city: 'Maputo',
  phoneE164: '+258840000000',
  stripeCustomerId: 'cus_secret',
});
assert.strictEqual(user.publicProfile.displayName, 'Ana');
assert.strictEqual(user.publicProfile.city, 'Maputo');
assert.strictEqual(user.publicProfile.phoneE164, undefined);
assert.strictEqual(user.privateUser.phoneE164, '+258840000000');
assert.strictEqual(user.privateUser.stripeCustomerId, 'cus_secret');

const provider = partitionProvider('p1', {
  nome: 'Marta',
  city: 'Matola',
  phone: '+258850000000',
  isOnline: true,
  lastLocation: { lat: -25.9, lng: 32.5 },
  geo: { geohash: 'k7' },
  kycDocs: { front: 'secret-url' },
  stripeAccountId: 'acct_secret',
});
assert.strictEqual(provider.publicProvider.nome, 'Marta');
assert.strictEqual(provider.publicProvider.city, 'Matola');
assert.strictEqual(provider.publicProvider.phone, undefined);
assert.strictEqual(provider.publicProvider.lastLocation, undefined);
assert.strictEqual(provider.dispatchProvider.isOnline, true);
assert.deepStrictEqual(provider.dispatchProvider.lastLocation, { lat: -25.9, lng: 32.5 });
assert.strictEqual(provider.privateProvider.phone, '+258850000000');
assert.deepStrictEqual(provider.privateProvider.kycDocs, { front: 'secret-url' });
assert.strictEqual(provider.privateProvider.stripeAccountId, 'acct_secret');

const dryRun = resolveOptions(['--project=test-project']);
assert.strictEqual(dryRun.dryRun, true);
assert.throws(
  () => resolveOptions(['--project=test-project', '--confirm']),
  /confirm-project/,
);
const confirmed = resolveOptions([
  '--project=test-project',
  '--confirm',
  '--confirm-project=test-project',
]);
assert.strictEqual(confirmed.dryRun, false);

console.log('migrate_p1_data_boundaries safeguards ok');
