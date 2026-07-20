const assert = require('assert');

const {
  buildPlan,
  collectReferences,
  firebaseDownloadUrl,
  quarantinePath,
  resolveOptions,
  storagePathFromReference,
} = require('../admin/migrate_p1_storage_boundaries');

const bucket = 'chegaja-ac88d.firebasestorage.app';
const source = 'users/u1/profile photo.jpg';
const encodedUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/`
  + `${encodeURIComponent(source)}?alt=media&token=secret`;
assert.strictEqual(storagePathFromReference(encodedUrl, bucket), source);
assert.strictEqual(storagePathFromReference('temp/u1/anexos/a.pdf', bucket),
  'temp/u1/anexos/a.pdf');
assert.ok(firebaseDownloadUrl(bucket, 'profile_public/u1/p.jpg', 'token')
  .includes('profile_public%2Fu1%2Fp.jpg'));
assert.ok(quarantinePath('temp/u1/anexos/a.pdf').startsWith(
  'migration_quarantine/2026-07-20/',
));

const references = collectReferences({
  firestoreDocuments: [{
    name: 'projects/p/databases/(default)/documents/public_profiles/u1',
    fields: { photoUrl: { stringValue: encodedUrl } },
  }],
  authUsers: [],
  bucket,
});
const plan = buildPlan({
  objects: [
    { name: source, metadata: { firebaseStorageDownloadTokens: 'secret' } },
    { name: 'temp/u2/anexos/orphan.pdf', metadata: {} },
    { name: 'pedidos/p1/anexos/referenced.pdf', metadata: {} },
  ],
  references: new Map([
    ...references,
    ['pedidos/p1/anexos/referenced.pdf', [{ kind: 'pedido_attachment' }]],
  ]),
});
assert.strictEqual(plan.counts.migrate_public_profile, 1);
assert.strictEqual(plan.counts.quarantine_unreferenced, 1);
assert.strictEqual(plan.referencedPrivateObjects, 1);
assert.strictEqual(JSON.stringify({ counts: plan.counts }).includes('u1'), false);

assert.strictEqual(resolveOptions([]).confirm, false);
assert.throws(() => resolveOptions(['--confirm']), /confirm-project/);
assert.strictEqual(resolveOptions([
  '--confirm',
  '--confirm-project=chegaja-ac88d',
]).confirm, true);
assert.throws(() => resolveOptions(['--project=wrong']), /Refusing unexpected/);

console.log('migrate_p1_storage_boundaries safeguards ok');
