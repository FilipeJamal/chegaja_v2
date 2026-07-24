const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const {
  buildEvidence,
  buildInputSnapshot,
  collectLocalPackageInputs,
  collectReleaseInputs,
  collectVirtualReleaseInputs,
  releaseInputSchema,
  releaseSourceFingerprint,
} = require('../qa/release_source_fingerprint');

function writeFixture(workspaceRoot, relativePath, contents = relativePath) {
  const destination = path.join(workspaceRoot, relativePath);
  fs.mkdirSync(path.dirname(destination), { recursive: true });
  fs.writeFileSync(destination, contents);
}

const fixtureRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'release-inputs-v2-'));
const secretValue = 'maps-secret-must-never-be-serialized';

try {
  for (const relativePath of [
    '.env',
    '.metadata',
    'pubspec.yaml',
    'pubspec.lock',
    'scripts/build_android_release.ps1',
    'android/app/build.gradle.kts',
    'android/app/google-services.json',
    'android/app/proguard-rules.pro',
    'android/build.gradle.kts',
    'android/settings.gradle.kts',
    'android/gradle.properties',
    'android/gradlew',
    'android/gradlew.bat',
    'android/gradle/wrapper/gradle-wrapper.jar',
    'android/gradle/wrapper/gradle-wrapper.properties',
    'android/app/src/main/AndroidManifest.xml',
    'lib/main.dart',
    'assets/logo.png',
    'build/app/outputs/flutter-apk/app-release.apk',
  ]) writeFixture(fixtureRoot, relativePath);

  writeFixture(fixtureRoot, '.env', [
    'ENABLE_KYC=false',
    'LEGAL_CONTACT_EMAIL=not-configured',
  ].join('\n'));
  writeFixture(fixtureRoot, 'android/local.properties', [
    'sdk.dir=private-path',
    `GOOGLE_MAPS_API_KEY=${secretValue}`,
  ].join('\n'));
  writeFixture(fixtureRoot, 'android/key.properties', 'storePassword=secret');
  writeFixture(fixtureRoot, 'android/app/upload-keystore.jks', 'keystore-secret');
  writeFixture(
    fixtureRoot,
    'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
  );

  writeFixture(fixtureRoot, 'packages/local_plugin/pubspec.yaml');
  writeFixture(fixtureRoot, 'packages/local_plugin/lib/local_plugin.dart');
  writeFixture(fixtureRoot, 'packages/local_plugin/android/src/plugin.kt');
  writeFixture(fixtureRoot, 'packages/local_plugin/test/plugin_test.dart');
  writeFixture(fixtureRoot, 'packages/local_plugin/build/generated.txt');
  writeFixture(fixtureRoot, 'packages/local_plugin/.gradle/cache.bin');
  writeFixture(fixtureRoot, 'packages/local_plugin/.dart_tool/state.json');
  writeFixture(fixtureRoot, 'outside_plugin/lib/outside.dart');

  const packageConfigPath = path.join(fixtureRoot, '.dart_tool/package_config.json');
  writeFixture(
    fixtureRoot,
    '.dart_tool/package_config.json',
    JSON.stringify({
      configVersion: 2,
      packages: [
        { name: 'app', rootUri: '../', packageUri: 'lib/' },
        {
          name: 'local_plugin',
          rootUri: '../packages/local_plugin',
          packageUri: 'lib/',
        },
        {
          name: 'outside_plugin',
          rootUri: pathToFileUrl(path.join(fixtureRoot, '..', 'outside_plugin')),
          packageUri: 'lib/',
        },
      ],
    }),
  );
  assert.ok(fs.existsSync(packageConfigPath));

  const localPackageInputs = collectLocalPackageInputs(fixtureRoot);
  assert.ok(localPackageInputs.includes('packages/local_plugin/lib/local_plugin.dart'));
  assert.ok(localPackageInputs.includes('packages/local_plugin/android/src/plugin.kt'));
  assert.ok(!localPackageInputs.some((item) => item.includes('/test/')));
  assert.ok(!localPackageInputs.some((item) => item.includes('/build/')));
  assert.ok(!localPackageInputs.some((item) => item.includes('/.gradle/')));
  assert.ok(!localPackageInputs.some((item) => item.includes('/.dart_tool/')));
  assert.ok(!localPackageInputs.some((item) => item.includes('outside_plugin')));

  const files = collectReleaseInputs(fixtureRoot);
  for (const requiredInput of [
    '.metadata',
    'scripts/build_android_release.ps1',
    'android/app/google-services.json',
    'android/app/proguard-rules.pro',
    'android/gradlew',
    'android/gradlew.bat',
    'android/gradle/wrapper/gradle-wrapper.jar',
  ]) assert.ok(files.includes(requiredInput), `${requiredInput} must be fingerprinted`);
  assert.ok(files.includes('.env'));
  assert.ok(!files.some((item) => item.endsWith('local.properties')));
  assert.ok(!files.some((item) => item.endsWith('key.properties')));
  assert.ok(!files.some((item) => /\.(jks|keystore)$/.test(item)));
  assert.ok(!files.some((item) => item.includes('GeneratedPluginRegistrant.java')));
  assert.ok(!files.some((item) => item.startsWith('build/')));
  assert.strictEqual(files.join('\n'), [...files].sort().join('\n'));

  const virtualInputs = collectVirtualReleaseInputs({}, fixtureRoot);
  assert.strictEqual(virtualInputs.length, 1);
  assert.strictEqual(virtualInputs[0].name, 'GOOGLE_MAPS_API_KEY');
  assert.match(virtualInputs[0].sha256, /^[a-f0-9]{64}$/);
  assert.ok(!JSON.stringify(virtualInputs).includes(secretValue));
  assert.strictEqual(
    collectVirtualReleaseInputs({
      GOOGLE_MAPS_API_KEY: 'environment-must-not-override-local',
    }, fixtureRoot)[0].sha256,
    virtualInputs[0].sha256,
  );
  writeFixture(fixtureRoot, 'android/local.properties', [
    'sdk.dir=private-path',
    'GOOGLE_MAPS_API_KEY=',
  ].join('\n'));
  assert.notStrictEqual(
    collectVirtualReleaseInputs({
      GOOGLE_MAPS_API_KEY: secretValue,
    }, fixtureRoot)[0].sha256,
    virtualInputs[0].sha256,
  );

  const fingerprint = releaseSourceFingerprint(files, virtualInputs, fixtureRoot);
  assert.match(fingerprint, /^[a-f0-9]{64}$/);
  assert.strictEqual(
    releaseSourceFingerprint(files, virtualInputs, fixtureRoot),
    fingerprint,
  );
  writeFixture(fixtureRoot, 'android/local.properties', [
    'sdk.dir=private-path',
    'GOOGLE_MAPS_API_KEY=different-maps-key',
  ].join('\n'));
  const changedMapsKey = collectVirtualReleaseInputs({}, fixtureRoot);
  assert.notStrictEqual(
    releaseSourceFingerprint(files, changedMapsKey, fixtureRoot),
    fingerprint,
  );

  const preBuildSnapshot = buildInputSnapshot({
    workspaceRoot: fixtureRoot,
    environment: {},
    capturedAt: '2026-07-21T00:00:00.000Z',
    sourceRevision: 'a'.repeat(40),
    sourceTreeClean: true,
  });
  const evidence = buildEvidence({
    workspaceRoot: fixtureRoot,
    environment: {},
    generatedAt: '2026-07-21T00:01:00.000Z',
    preBuildSnapshot,
    sourceRevision: 'a'.repeat(40),
    sourceTreeClean: true,
  });
  const serializedEvidence = JSON.stringify(evidence);
  assert.strictEqual(evidence.fingerprintSchema, releaseInputSchema);
  assert.strictEqual(evidence.fingerprintSchema, 'android-release-inputs-v3');
  assert.strictEqual(
    evidence.attestationSchema,
    'android-release-build-attestation-v1',
  );
  assert.strictEqual(evidence.sourceStableDuringBuild, true);
  assert.strictEqual(evidence.sourceRevision, 'a'.repeat(40));
  assert.strictEqual(evidence.sourceTreeClean, true);
  assert.strictEqual(
    evidence.preBuildSourceFingerprint,
    evidence.postBuildSourceFingerprint,
  );
  assert.strictEqual(evidence.releaseVirtualInputs, 1);
  assert.strictEqual(evidence.localPathsSerialized, false);
  assert.strictEqual(evidence.secretValuesSerialized, false);
  assert.ok(!serializedEvidence.includes(secretValue));
  assert.ok(!serializedEvidence.includes(fixtureRoot));

  writeFixture(fixtureRoot, 'lib/main.dart', 'changed during build');
  assert.throws(
    () => buildEvidence({
      workspaceRoot: fixtureRoot,
      environment: {},
      generatedAt: '2026-07-21T00:02:00.000Z',
      preBuildSnapshot,
      sourceRevision: 'a'.repeat(40),
      sourceTreeClean: true,
    }),
    /changed while the APK was being built/,
  );
} finally {
  fs.rmSync(fixtureRoot, { recursive: true, force: true });
}

function pathToFileUrl(filePath) {
  const normalized = filePath.replace(/\\/g, '/');
  return `file:///${normalized.replace(/^\//, '')}`;
}

console.log('release_source_fingerprint safeguards ok');
