/* eslint-disable no-console */
const crypto = require('crypto');
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const { fileURLToPath, pathToFileURL } = require('url');

const root = path.resolve(__dirname, '../..');
const apkRelativePath = 'build/app/outputs/flutter-apk/app-release.apk';
const evidenceRelativePath = 'build/p1_release_provenance.json';
const releaseInputSchema = 'android-release-inputs-v3';
const buildAttestationSchema = 'android-release-build-attestation-v1';
const generatedRegistrant =
  'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java';
const excludedDirectoryNames = new Set([
  '.dart_tool',
  '.gradle',
  'build',
  'test',
]);

function normalizeRelativePath(relativePath) {
  return relativePath.replace(/\\/g, '/');
}

function isSensitiveLocalFile(relativePath) {
  const basename = path.posix.basename(normalizeRelativePath(relativePath))
    .toLowerCase();
  return basename === 'local.properties'
    || basename === 'key.properties'
    || basename.endsWith('.jks')
    || basename.endsWith('.keystore');
}

function isExcludedRelativePath(relativePath) {
  const normalized = normalizeRelativePath(relativePath);
  const segments = normalized.split('/');
  return segments.some((segment) => excludedDirectoryNames.has(segment))
    || normalized === generatedRegistrant
    || isSensitiveLocalFile(normalized);
}

function walk(relativeDirectory, predicate = () => true, workspaceRoot = root) {
  const absolute = path.join(workspaceRoot, relativeDirectory);
  if (!fs.existsSync(absolute)) return [];
  const results = [];
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const fullPath = path.join(directory, entry.name);
      const relative = normalizeRelativePath(path.relative(workspaceRoot, fullPath));
      if (entry.isDirectory()) {
        if (!isExcludedRelativePath(relative)) visit(fullPath);
      } else if (!isExcludedRelativePath(relative) && predicate(relative)) {
        results.push(relative);
      }
    }
  };
  visit(absolute);
  return results;
}

function isInsideWorkspace(candidate, workspaceRoot) {
  const relative = path.relative(path.resolve(workspaceRoot), path.resolve(candidate));
  return relative !== '' && relative !== '..'
    && !relative.startsWith(`..${path.sep}`)
    && !path.isAbsolute(relative);
}

function resolvePackageRoot(packageConfigPath, rootUri) {
  try {
    const packageUrl = new URL(rootUri, pathToFileURL(packageConfigPath));
    if (packageUrl.protocol !== 'file:') return null;
    return path.resolve(fileURLToPath(packageUrl));
  } catch (_) {
    return null;
  }
}

function collectLocalPackageInputs(workspaceRoot = root) {
  const packageConfigPath = path.join(
    workspaceRoot,
    '.dart_tool',
    'package_config.json',
  );
  if (!fs.existsSync(packageConfigPath)) return [];

  const packageConfig = JSON.parse(fs.readFileSync(packageConfigPath, 'utf8'));
  const inputs = [];
  for (const packageEntry of packageConfig.packages || []) {
    const packageRoot = resolvePackageRoot(packageConfigPath, packageEntry.rootUri);
    if (!packageRoot || !isInsideWorkspace(packageRoot, workspaceRoot)) continue;
    const relativePackageRoot = normalizeRelativePath(
      path.relative(workspaceRoot, packageRoot),
    );
    inputs.push(...walk(relativePackageRoot, () => true, workspaceRoot));
  }
  return inputs;
}

function collectReleaseInputs(workspaceRoot = root) {
  const fixed = [
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
  ];
  return [...new Set([
    ...fixed.filter((item) => fs.existsSync(path.join(workspaceRoot, item))),
    ...walk('lib', (item) => item.endsWith('.dart'), workspaceRoot),
    ...walk('assets', () => true, workspaceRoot),
    ...walk('android/app/src', () => true, workspaceRoot),
    ...collectLocalPackageInputs(workspaceRoot),
  ])].filter((item) => !isExcludedRelativePath(item)).sort();
}

function readAndroidLocalProperty(workspaceRoot, key) {
  const propertiesPath = path.join(workspaceRoot, 'android', 'local.properties');
  if (!fs.existsSync(propertiesPath)) return null;
  const lines = fs.readFileSync(propertiesPath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const separator = trimmed.indexOf('=');
    if (separator < 0) continue;
    const name = trimmed.slice(0, separator).replace(/^export\s+/, '').trim();
    if (name !== key) continue;
    let value = trimmed.slice(separator + 1).trim();
    if (
      value.length >= 2
      && ((value.startsWith('"') && value.endsWith('"'))
        || (value.startsWith("'") && value.endsWith("'")))
    ) {
      value = value.slice(1, -1);
    } else {
      value = value.replace(/\s+#.*$/, '').trim();
    }
    return value;
  }
  return null;
}

function collectVirtualReleaseInputs(
  environment = process.env,
  workspaceRoot = root,
) {
  const name = 'GOOGLE_MAPS_API_KEY';
  // Gradle gives local.properties precedence over the environment. The
  // fingerprint must hash the exact value selected by the build.
  const localValue = readAndroidLocalProperty(workspaceRoot, name);
  const value = localValue === null
    ? String(environment[name] ?? '')
    : localValue;
  return [{
    name,
    sha256: crypto.createHash('sha256')
      .update(`${name}\0`, 'utf8')
      .update(value, 'utf8')
      .digest('hex'),
  }];
}

function collectGitSourceState(files, workspaceRoot = root) {
  const git = (args) => execFileSync('git', args, {
    cwd: workspaceRoot,
    encoding: 'utf8',
    maxBuffer: 16 * 1024 * 1024,
    windowsHide: true,
  });
  const sourceRevision = git(['rev-parse', 'HEAD']).trim();
  const tracked = new Set(
    git(['ls-files', '-z']).split('\0').filter(Boolean).map(normalizeRelativePath),
  );
  const changed = new Set([
    ...git(['diff', '--name-only', '-z', 'HEAD']).split('\0'),
    ...git(['ls-files', '--others', '--exclude-standard', '-z']).split('\0'),
  ].filter(Boolean).map(normalizeRelativePath));
  const localBuildInputs = new Set(['.env']);
  const committedInputs = files.filter((item) => !localBuildInputs.has(item));
  const sourceTreeClean = /^[a-f0-9]{40}$/i.test(sourceRevision)
    && committedInputs.every((item) => tracked.has(item) && !changed.has(item));
  return { sourceRevision, sourceTreeClean };
}

function buildInputSnapshot({
  workspaceRoot = root,
  environment = process.env,
  capturedAt = new Date().toISOString(),
  sourceRevision,
  sourceTreeClean,
} = {}) {
  const files = collectReleaseInputs(workspaceRoot);
  const virtualInputs = collectVirtualReleaseInputs(environment, workspaceRoot);
  const gitState = sourceRevision === undefined || sourceTreeClean === undefined
    ? collectGitSourceState(files, workspaceRoot)
    : { sourceRevision, sourceTreeClean };
  return {
    fingerprintSchema: releaseInputSchema,
    capturedAt,
    releaseSourceFingerprint: releaseSourceFingerprint(
      files,
      virtualInputs,
      workspaceRoot,
    ),
    releaseInputFiles: files.length,
    releaseVirtualInputs: virtualInputs.length,
    sourceRevision: gitState.sourceRevision,
    sourceTreeClean: gitState.sourceTreeClean,
    generatedRegistrantExcluded: true,
    localPathsSerialized: false,
    secretValuesSerialized: false,
  };
}

function inputSnapshotsMatch(before, after) {
  return Boolean(before && after)
    && before.fingerprintSchema === releaseInputSchema
    && after.fingerprintSchema === releaseInputSchema
    && before.releaseSourceFingerprint === after.releaseSourceFingerprint
    && before.releaseInputFiles === after.releaseInputFiles
    && before.releaseVirtualInputs === after.releaseVirtualInputs
    && before.sourceRevision === after.sourceRevision
    && before.sourceTreeClean === true
    && after.sourceTreeClean === true;
}

function sha256File(relativePath, workspaceRoot = root) {
  return crypto.createHash('sha256')
    .update(fs.readFileSync(path.join(workspaceRoot, relativePath)))
    .digest('hex');
}

function releaseSourceFingerprint(
  files = collectReleaseInputs(),
  virtualInputs = collectVirtualReleaseInputs(),
  workspaceRoot = root,
) {
  const hash = crypto.createHash('sha256');
  hash.update(`${releaseInputSchema}\0`, 'utf8');
  for (const relativePath of [...files].sort()) {
    hash.update(relativePath, 'utf8');
    hash.update('\0');
    hash.update(fs.readFileSync(path.join(workspaceRoot, relativePath)));
    hash.update('\0');
  }
  for (const virtualInput of [...virtualInputs]
    .sort((left, right) => left.name.localeCompare(right.name))) {
    hash.update(`virtual:${virtualInput.name}\0`, 'utf8');
    hash.update(virtualInput.sha256, 'utf8');
    hash.update('\0');
  }
  return hash.digest('hex');
}

function buildEvidence({
  workspaceRoot = root,
  environment = process.env,
  generatedAt = new Date().toISOString(),
  preBuildSnapshot,
  sourceRevision,
  sourceTreeClean,
} = {}) {
  const postBuildSnapshot = buildInputSnapshot({
    workspaceRoot,
    environment,
    capturedAt: generatedAt,
    sourceRevision,
    sourceTreeClean,
  });
  if (!preBuildSnapshot) {
    throw new Error('Pre-build source snapshot is required for APK attestation.');
  }
  if (!inputSnapshotsMatch(preBuildSnapshot, postBuildSnapshot)) {
    throw new Error('Release inputs changed while the APK was being built.');
  }
  return {
    attestationSchema: buildAttestationSchema,
    fingerprintSchema: postBuildSnapshot.fingerprintSchema,
    generatedAt,
    apkSha256: sha256File(apkRelativePath, workspaceRoot),
    releaseSourceFingerprint: postBuildSnapshot.releaseSourceFingerprint,
    preBuildSourceFingerprint: preBuildSnapshot.releaseSourceFingerprint,
    postBuildSourceFingerprint: postBuildSnapshot.releaseSourceFingerprint,
    sourceStableDuringBuild: true,
    sourceRevision: postBuildSnapshot.sourceRevision,
    sourceTreeClean: postBuildSnapshot.sourceTreeClean,
    preBuildCapturedAt: preBuildSnapshot.capturedAt,
    postBuildCapturedAt: postBuildSnapshot.capturedAt,
    releaseInputFiles: postBuildSnapshot.releaseInputFiles,
    releaseVirtualInputs: postBuildSnapshot.releaseVirtualInputs,
    generatedRegistrantExcluded: true,
    localPathsSerialized: false,
    secretValuesSerialized: false,
  };
}

function main() {
  const write = process.argv.includes('--write-build-evidence');
  const snapshotWriteIndex = process.argv.indexOf('--write-input-snapshot');
  const snapshotReadIndex = process.argv.indexOf('--input-snapshot');
  if (snapshotWriteIndex >= 0) {
    const relativeDestination = process.argv[snapshotWriteIndex + 1];
    if (!relativeDestination) throw new Error('Missing input snapshot path.');
    const snapshot = buildInputSnapshot();
    if (snapshot.sourceTreeClean !== true) {
      throw new Error('Release source inputs must match a committed Git revision.');
    }
    const destination = path.resolve(root, relativeDestination);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    fs.writeFileSync(destination, `${JSON.stringify(snapshot, null, 2)}\n`, 'utf8');
    console.log(JSON.stringify(snapshot, null, 2));
    return;
  }
  if (snapshotReadIndex < 0 || !process.argv[snapshotReadIndex + 1]) {
    throw new Error('Use --input-snapshot to bind evidence to pre-build inputs.');
  }
  const snapshotPath = path.resolve(root, process.argv[snapshotReadIndex + 1]);
  const preBuildSnapshot = JSON.parse(fs.readFileSync(snapshotPath, 'utf8'));
  const evidence = buildEvidence({ preBuildSnapshot });
  if (write) {
    const destination = path.join(root, evidenceRelativePath);
    fs.mkdirSync(path.dirname(destination), { recursive: true });
    fs.writeFileSync(destination, `${JSON.stringify(evidence, null, 2)}\n`, 'utf8');
  }
  console.log(JSON.stringify(evidence, null, 2));
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(`[release_source_fingerprint] FAILED: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = {
  apkRelativePath,
  buildAttestationSchema,
  buildEvidence,
  buildInputSnapshot,
  collectGitSourceState,
  collectLocalPackageInputs,
  collectReleaseInputs,
  collectVirtualReleaseInputs,
  evidenceRelativePath,
  inputSnapshotsMatch,
  releaseInputSchema,
  releaseSourceFingerprint,
};
