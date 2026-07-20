/* eslint-disable no-console */
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../..');
const apkRelativePath = 'build/app/outputs/flutter-apk/app-release.apk';
const evidenceRelativePath = 'build/p1_release_provenance.json';

function walk(relativeDirectory, predicate = () => true) {
  const absolute = path.join(root, relativeDirectory);
  if (!fs.existsSync(absolute)) return [];
  const results = [];
  const visit = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const fullPath = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(fullPath);
      else {
        const relative = path.relative(root, fullPath).replace(/\\/g, '/');
        if (predicate(relative)) results.push(relative);
      }
    }
  };
  visit(absolute);
  return results;
}

function collectReleaseInputs() {
  const fixed = [
    '.env',
    'pubspec.yaml',
    'pubspec.lock',
    'android/app/build.gradle.kts',
    'android/build.gradle.kts',
    'android/settings.gradle.kts',
    'android/gradle.properties',
    'android/gradle/wrapper/gradle-wrapper.properties',
  ];
  const generatedRegistrant =
    'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java';
  return [...new Set([
    ...fixed.filter((item) => fs.existsSync(path.join(root, item))),
    ...walk('lib', (item) => item.endsWith('.dart')),
    ...walk('assets'),
    ...walk('android/app/src', (item) => item !== generatedRegistrant),
  ])].sort();
}

function sha256File(relativePath) {
  return crypto.createHash('sha256')
    .update(fs.readFileSync(path.join(root, relativePath)))
    .digest('hex');
}

function releaseSourceFingerprint(files = collectReleaseInputs()) {
  const hash = crypto.createHash('sha256');
  for (const relativePath of files) {
    hash.update(relativePath, 'utf8');
    hash.update('\0');
    hash.update(fs.readFileSync(path.join(root, relativePath)));
    hash.update('\0');
  }
  return hash.digest('hex');
}

function buildEvidence() {
  const files = collectReleaseInputs();
  return {
    generatedAt: new Date().toISOString(),
    apkSha256: sha256File(apkRelativePath),
    releaseSourceFingerprint: releaseSourceFingerprint(files),
    releaseInputFiles: files.length,
    generatedRegistrantExcluded: true,
  };
}

function main() {
  const write = process.argv.includes('--write-build-evidence');
  const evidence = buildEvidence();
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
  buildEvidence,
  collectReleaseInputs,
  evidenceRelativePath,
  releaseSourceFingerprint,
};
