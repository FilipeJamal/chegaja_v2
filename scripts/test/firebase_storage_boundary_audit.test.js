const assert = require('assert');

const {
  accessClass,
  hasDownloadToken,
  hasSuspiciousPublicName,
  resolveOptions,
  summarize,
} = require('../qa/firebase_storage_boundary_audit');

assert.strictEqual(accessClass('kyc_pending/u1/s1/front.jpg'), 'restricted');
assert.strictEqual(accessClass('pedidos/p1/anexos/photo.jpg'), 'participant_private');
assert.strictEqual(accessClass('portfolio/u1/work.jpg'), 'public_portfolio');
assert.strictEqual(accessClass('profile_public/u1/avatar.jpg'), 'public_profile');
assert.strictEqual(
  accessClass('migration_quarantine/2026-07-20/hash/file.jpg'),
  'restricted_quarantine',
);
assert.strictEqual(accessClass('unknown/u1/file.bin'), 'unknown');
assert.strictEqual(hasDownloadToken({
  metadata: { firebaseStorageDownloadTokens: 'secret-token-not-printed' },
}), true);
assert.strictEqual(hasDownloadToken({ metadata: {} }), false);
assert.strictEqual(hasSuspiciousPublicName('portfolio/u1/documento-frente.jpg'), true);
assert.strictEqual(hasSuspiciousPublicName('portfolio/u1/cozinha-pintada.jpg'), false);
assert.strictEqual(hasSuspiciousPublicName('kyc/u1/documento.jpg'), false);

const safe = summarize([
  { name: 'portfolio/u1/cozinha.jpg', size: '10', contentType: 'image/jpeg', metadata: {} },
], 'chegaja-ac88d', 'chegaja-ac88d.firebasestorage.app');
assert.strictEqual(safe.passed, true);
assert.strictEqual(safe.objectNamesIncluded, false);

const shapes = summarize([
  { name: 'users/u1/profile_1.jpg', size: '10', contentType: 'image/jpeg', metadata: {} },
  { name: 'chats/p1/images/photo.jpg', size: '10', contentType: 'image/jpeg', metadata: {} },
], 'chegaja-ac88d', 'chegaja-ac88d.firebasestorage.app');
assert.strictEqual(shapes.objectShapes.userProfileImage, 1);
assert.strictEqual(shapes.objectShapes.chatImage, 1);

const unsafe = summarize([
  {
    name: 'kyc_pending/u1/s1/front.jpg',
    size: '20',
    metadata: { firebaseStorageDownloadTokens: 'secret-token-not-printed' },
  },
  { name: 'stories/u2/story.jpg', size: '30', metadata: {} },
], 'chegaja-ac88d', 'chegaja-ac88d.firebasestorage.app');
assert.strictEqual(unsafe.passed, false);
assert.strictEqual(unsafe.blockers.restrictedObjectsWithDownloadTokens, 1);
assert.strictEqual(unsafe.blockers.disabledStoryObjects, 1);
assert.strictEqual(JSON.stringify(unsafe).includes('front.jpg'), false);
assert.throws(
  () => resolveOptions(['--project=wrong-project']),
  /Refusing unexpected project/,
);

console.log('firebase_storage_boundary_audit safeguards ok');
