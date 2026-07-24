const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const {
  canonicalText,
  collectP1SourceHashes,
  discoverFunctionsRuntimeFiles,
  functionsRuntimeSchema,
  hashAlgorithm,
  sha256CanonicalText,
} = require('../qa/p1_source_hashes');

const lf = 'primeira\nsegunda\n';
const crlf = 'primeira\r\nsegunda\r\n';
const legacyCr = 'primeira\rsegunda\r';

assert.strictEqual(canonicalText(`\uFEFF${crlf}`), lf);
assert.strictEqual(canonicalText(legacyCr), lf);
assert.strictEqual(sha256CanonicalText(lf), sha256CanonicalText(crlf));

const hashes = collectP1SourceHashes();
assert.strictEqual(hashes.hashAlgorithm, hashAlgorithm);
assert.strictEqual(hashes.functionsRuntimeSchema, functionsRuntimeSchema);
assert.ok(Number.isInteger(hashes.functionsRuntimeFileCount));
assert.ok(hashes.functionsRuntimeFileCount > 0);
for (const key of [
  'firestoreRulesSha256',
  'storageRulesSha256',
  'functionsIndexSha256',
  'functionsRuntimeSourceFingerprintSha256',
  'functionsPackageSha256',
  'functionsPackageLockSha256',
  'functionsDeployFingerprintSha256',
]) {
  const value = hashes[key];
  assert.match(value, /^[a-f0-9]{64}$/);
}

const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'p1-source-hashes-'));
try {
  fs.mkdirSync(path.join(temporaryRoot, 'functions', 'lib'), {recursive: true});
  fs.mkdirSync(path.join(temporaryRoot, 'functions', 'test'), {recursive: true});
  fs.mkdirSync(path.join(temporaryRoot, 'functions', 'node_modules', 'dependency'), {
    recursive: true,
  });
  fs.writeFileSync(path.join(temporaryRoot, 'firestore.rules'), 'rules_version = "2";\n');
  fs.writeFileSync(path.join(temporaryRoot, 'storage.rules'), 'rules_version = "2";\n');
  fs.writeFileSync(path.join(temporaryRoot, 'functions', 'index.js'), 'exports.main = 1;\n');
  fs.writeFileSync(
    path.join(temporaryRoot, 'functions', 'lib', 'worker.cjs'),
    'exports.worker = true;\n',
  );
  fs.writeFileSync(
    path.join(temporaryRoot, 'functions', 'test', 'ignored.js'),
    'throw new Error("ignored test");\n',
  );
  fs.writeFileSync(
    path.join(temporaryRoot, 'functions', 'node_modules', 'dependency', 'ignored.mjs'),
    'throw new Error("ignored dependency");\n',
  );
  fs.writeFileSync(path.join(temporaryRoot, 'functions', 'package.json'), '{"name":"fixture"}\n');
  fs.writeFileSync(path.join(temporaryRoot, 'functions', 'package-lock.json'), '{}\n');

  const initialFiles = discoverFunctionsRuntimeFiles(temporaryRoot);
  assert.deepStrictEqual(initialFiles, [
    'functions/index.js',
    'functions/lib/worker.cjs',
  ]);

  const initial = collectP1SourceHashes({rootDir: temporaryRoot});
  assert.strictEqual(initial.functionsRuntimeSchema, 'functions-runtime-js-v2');
  assert.strictEqual(initial.functionsRuntimeFileCount, 2);

  fs.writeFileSync(
    path.join(temporaryRoot, 'functions', 'lib', 'worker.cjs'),
    'exports.worker = true;\r\n',
  );
  const withCrLf = collectP1SourceHashes({rootDir: temporaryRoot});
  assert.strictEqual(
    withCrLf.functionsRuntimeSourceFingerprintSha256,
    initial.functionsRuntimeSourceFingerprintSha256,
  );
  assert.strictEqual(
    withCrLf.functionsDeployFingerprintSha256,
    initial.functionsDeployFingerprintSha256,
  );

  fs.writeFileSync(
    path.join(temporaryRoot, 'functions', 'test', 'ignored.js'),
    'module.exports = "changed test";\n',
  );
  const withChangedTest = collectP1SourceHashes({rootDir: temporaryRoot});
  assert.strictEqual(
    withChangedTest.functionsRuntimeSourceFingerprintSha256,
    initial.functionsRuntimeSourceFingerprintSha256,
  );
  assert.strictEqual(
    withChangedTest.functionsDeployFingerprintSha256,
    initial.functionsDeployFingerprintSha256,
  );

  fs.writeFileSync(
    path.join(temporaryRoot, 'functions', 'lib', 'new-runtime.mjs'),
    'export const runtime = true;\n',
  );
  const withNewModule = collectP1SourceHashes({rootDir: temporaryRoot});
  assert.strictEqual(withNewModule.functionsRuntimeFileCount, 3);
  assert.strictEqual(withNewModule.functionsIndexSha256, initial.functionsIndexSha256);
  assert.notStrictEqual(
    withNewModule.functionsRuntimeSourceFingerprintSha256,
    initial.functionsRuntimeSourceFingerprintSha256,
  );
  assert.notStrictEqual(
    withNewModule.functionsDeployFingerprintSha256,
    initial.functionsDeployFingerprintSha256,
  );

  fs.writeFileSync(
    path.join(temporaryRoot, 'functions', 'lib', 'new-runtime.mjs'),
    'export const runtime = false;\n',
  );
  const withChangedModule = collectP1SourceHashes({rootDir: temporaryRoot});
  assert.notStrictEqual(
    withChangedModule.functionsRuntimeSourceFingerprintSha256,
    withNewModule.functionsRuntimeSourceFingerprintSha256,
  );
  assert.notStrictEqual(
    withChangedModule.functionsDeployFingerprintSha256,
    withNewModule.functionsDeployFingerprintSha256,
  );

  fs.writeFileSync(
    path.join(temporaryRoot, 'functions', 'package.json'),
    '{"name":"fixture","version":"1.0.0"}\n',
  );
  const withChangedManifest = collectP1SourceHashes({rootDir: temporaryRoot});
  assert.strictEqual(
    withChangedManifest.functionsRuntimeSourceFingerprintSha256,
    withChangedModule.functionsRuntimeSourceFingerprintSha256,
  );
  assert.notStrictEqual(
    withChangedManifest.functionsDeployFingerprintSha256,
    withChangedModule.functionsDeployFingerprintSha256,
  );
} finally {
  fs.rmSync(temporaryRoot, {recursive: true, force: true});
}

console.log('p1 canonical source hashes safeguards ok');
