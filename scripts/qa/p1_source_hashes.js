/* eslint-disable no-console */
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../..');
const hashAlgorithm = 'sha256-canonical-text-v1';
const functionsRuntimeSchema = 'functions-runtime-js-v2';
const functionsPackageManifestFiles = [
  'functions/package.json',
  'functions/package-lock.json',
];
const functionsRuntimeExtensions = new Set(['.js', '.cjs', '.mjs']);
const functionsRuntimeExcludedDirectories = new Set(['node_modules', 'test']);

function canonicalText(value) {
  return String(value).replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n');
}

function sha256CanonicalText(value) {
  return crypto.createHash('sha256').update(canonicalText(value), 'utf8').digest('hex');
}

function normalizeRelativePath(relativePath) {
  return relativePath.replace(/\\/g, '/');
}

function comparePaths(left, right) {
  if (left < right) return -1;
  if (left > right) return 1;
  return 0;
}

function discoverFunctionsRuntimeFiles(baseRoot = root) {
  const functionsRoot = path.join(baseRoot, 'functions');
  const files = [];

  function visit(directory, relativeDirectory) {
    const entries = fs.readdirSync(directory, {withFileTypes: true})
      .sort((left, right) => comparePaths(left.name, right.name));

    for (const entry of entries) {
      const entryPath = path.join(directory, entry.name);
      const relativePath = normalizeRelativePath(path.join(relativeDirectory, entry.name));

      if (entry.isDirectory()) {
        if (!functionsRuntimeExcludedDirectories.has(entry.name.toLowerCase())) {
          visit(entryPath, relativePath);
        }
        continue;
      }

      if (entry.isFile()
          && functionsRuntimeExtensions.has(path.extname(entry.name).toLowerCase())) {
        files.push(relativePath);
      }
    }
  }

  visit(functionsRoot, 'functions');
  return files.sort(comparePaths);
}

function readCanonicalText(relativePath, baseRoot = root) {
  return canonicalText(fs.readFileSync(path.join(baseRoot, relativePath), 'utf8'));
}

function sha256CanonicalTextFile(relativePath, baseRoot = root) {
  return sha256CanonicalText(readCanonicalText(relativePath, baseRoot));
}

function sha256CanonicalTextFiles(relativePaths, baseRoot = root) {
  const hash = crypto.createHash('sha256');
  for (const relativePath of relativePaths) {
    hash.update(normalizeRelativePath(relativePath), 'utf8');
    hash.update('\0');
    hash.update(readCanonicalText(relativePath, baseRoot), 'utf8');
    hash.update('\0');
  }
  return hash.digest('hex');
}

function collectP1SourceHashes(options = {}) {
  const baseRoot = options.rootDir ? path.resolve(options.rootDir) : root;
  const runtimeFiles = discoverFunctionsRuntimeFiles(baseRoot);
  const deployFiles = [...runtimeFiles, ...functionsPackageManifestFiles];

  return {
    hashAlgorithm,
    functionsRuntimeSchema,
    functionsRuntimeFileCount: runtimeFiles.length,
    firestoreRulesSha256: sha256CanonicalTextFile('firestore.rules', baseRoot),
    storageRulesSha256: sha256CanonicalTextFile('storage.rules', baseRoot),
    functionsIndexSha256: sha256CanonicalTextFile('functions/index.js', baseRoot),
    functionsRuntimeSourceFingerprintSha256: sha256CanonicalTextFiles(runtimeFiles, baseRoot),
    functionsPackageSha256: sha256CanonicalTextFile('functions/package.json', baseRoot),
    functionsPackageLockSha256: sha256CanonicalTextFile(
      'functions/package-lock.json',
      baseRoot,
    ),
    functionsDeployFingerprintSha256: sha256CanonicalTextFiles(deployFiles, baseRoot),
  };
}

const functionsRuntimeFiles = discoverFunctionsRuntimeFiles();
const functionsDeployFiles = [...functionsRuntimeFiles, ...functionsPackageManifestFiles];

function main() {
  console.log(JSON.stringify(collectP1SourceHashes(), null, 2));
}

if (require.main === module) {
  try {
    main();
  } catch (error) {
    console.error(`[p1_source_hashes] FAILED: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = {
  canonicalText,
  collectP1SourceHashes,
  discoverFunctionsRuntimeFiles,
  functionsDeployFiles,
  functionsPackageManifestFiles,
  functionsRuntimeFiles,
  functionsRuntimeSchema,
  hashAlgorithm,
  sha256CanonicalText,
  sha256CanonicalTextFile,
  sha256CanonicalTextFiles,
};
