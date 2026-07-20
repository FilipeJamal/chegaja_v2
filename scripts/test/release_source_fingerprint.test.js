const assert = require('assert');

const {
  collectReleaseInputs,
  releaseSourceFingerprint,
} = require('../qa/release_source_fingerprint');

const files = collectReleaseInputs();
assert.ok(files.includes('lib/main.dart'));
assert.ok(files.includes('android/app/src/main/AndroidManifest.xml'));
assert.ok(!files.some((item) => item.includes('GeneratedPluginRegistrant.java')));
assert.ok(!files.some((item) => item.startsWith('build/')));
assert.strictEqual(files.join('\n'), [...files].sort().join('\n'));
assert.match(releaseSourceFingerprint(files), /^[a-f0-9]{64}$/);
assert.strictEqual(
  releaseSourceFingerprint(files),
  releaseSourceFingerprint(files),
);

console.log('release_source_fingerprint safeguards ok');
