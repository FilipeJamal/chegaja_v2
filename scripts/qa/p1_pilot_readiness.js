/* eslint-disable no-console */
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const {
  buildAttestationSchema,
  collectReleaseInputs,
  collectVirtualReleaseInputs,
  releaseInputSchema,
  releaseSourceFingerprint,
} = require('./release_source_fingerprint');
const { collectP1SourceHashes } = require('./p1_source_hashes');

const root = path.resolve(__dirname, '../..');
const expectedFirebaseProjectId = 'chegaja-ac88d';
const expectedFirebaseProjectNumber = '767588494857';
const expectedAndroidPackage = 'com.chegaja.app';
const expectedAndroidFirebaseAppId = '1:767588494857:android:4198384a2a6387055252d8';
const expectedSigningCertificate =
  '1336ff14c1ddf09440387bbdf9f48d5a09602a87d1062ae6fce2a5072bac1f81';
const deploymentEvidenceSchema = 'p1-deployment-evidence-v4';
const firestoreIndexDeploymentSchema = 'firestore-index-deployment-v3';
const firestoreIndexCloudOutputSchema = 'firestore-index-cloud-output-v2';
const backendConfigSchema = 'p1-effective-backend-config-v1';
const auditReferenceSchema = 'p1-audit-reference-v1';
const auditArtifactSchema = 'p1-provider-audit-v1';
const physicalEvidenceSchema = 'p1-physical-android-evidence-v2';
const realPilotEvidenceSchema = 'p1-real-pilot-evidence-v2';
const versionedAndroidEvidenceDirectory = 'docs/android/evidence/u0-2026-07-21';
const versionedAndroidScreenshot = `${versionedAndroidEvidenceDirectory}/p1_8_launch.png`;
const versionedAndroidUi = `${versionedAndroidEvidenceDirectory}/p1_8_ui.xml`;
const versionedAndroidRuntimeLog =
  `${versionedAndroidEvidenceDirectory}/p1_8_runtime_redacted.log`;
const versionedReleaseProvenance =
  `${versionedAndroidEvidenceDirectory}/p1_release_provenance.json`;
const requiredBackendRiskFlags = [
  'ENABLE_KYC',
  'ENABLE_STRIPE',
  'STRIPE_MZN_VALIDATED',
  'ENABLE_MPESA',
  'ENABLE_EMOLA',
];
const requiredBackendSecrets = [
  'ACCOUNT_DELETION_PEPPER',
  'GOOGLE_MAPS_API_KEY',
  'GOOGLE_PLACES_API_KEY',
];
const requiredProviderGrantIndex = {
  collectionGroup: 'pedidos',
  queryScope: 'COLLECTION',
  fields: [
    { fieldPath: 'prestadorId', order: 'ASCENDING' },
    { fieldPath: 'providerAccessGranted', order: 'ASCENDING' },
    { fieldPath: 'providerAccessGrantedTo', order: 'ASCENDING' },
    { fieldPath: 'status', order: 'ASCENDING' },
    { fieldPath: 'providerAccessGrantedAt', order: 'DESCENDING' },
  ],
};
const requiredPhysicalCases = [
  'clean_install',
  'notifications_denied',
  'notifications_granted',
  'location_denied',
  'location_approximate',
  'location_precise',
  'camera_denied',
  'camera_granted',
  'permission_permanently_denied',
  'background_notification',
  'weak_or_offline_network',
  'restart_state_preserved',
];

function read(relativePath) {
  try {
    return fs.readFileSync(path.join(root, relativePath), 'utf8');
  } catch (_) {
    return '';
  }
}

function exists(relativePath) {
  return fs.existsSync(path.join(root, relativePath));
}

function readJson(relativePath) {
  try {
    return JSON.parse(read(relativePath));
  } catch (_) {
    return null;
  }
}

function envValues(relativePath) {
  const values = {};
  read(relativePath).split(/\r?\n/).forEach((line) => {
    const match = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (match) values[match[1]] = match[2].trim();
  });
  return values;
}

function sha256File(relativePath) {
  try {
    return crypto
      .createHash('sha256')
      .update(fs.readFileSync(path.join(root, relativePath)))
      .digest('hex');
  } catch (_) {
    return '';
  }
}

function androidSdkPath() {
  const sdkMatch = read('android/local.properties').match(/^sdk\.dir=(.+)$/m);
  return sdkMatch ? sdkMatch[1].replace(/\\\\/g, '\\').trim() : '';
}

function latestBuildTool(name) {
  const sdk = androidSdkPath();
  const buildTools = sdk && path.join(sdk, 'build-tools');
  if (!buildTools || !fs.existsSync(buildTools)) return '';
  const executable = process.platform === 'win32' ? `${name}.bat` : name;
  const versions = fs.readdirSync(buildTools, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort((a, b) => b.localeCompare(a, undefined, { numeric: true }));
  for (const version of versions) {
    const candidate = path.join(buildTools, version, executable);
    if (fs.existsSync(candidate)) return candidate;
  }
  return '';
}

function verifyReleaseApk() {
  const relativePath = 'build/app/outputs/flutter-apk/app-release.apk';
  const digest = sha256File(relativePath);
  const signer = latestBuildTool('apksigner');
  if (!digest || !signer) return { passed: false, digest, certificate: '' };
  try {
    const apkPath = path.join(root, relativePath);
    const signerJar = path.join(path.dirname(signer), 'lib', 'apksigner.jar');
    const java = process.env.JAVA_HOME
      ? path.join(process.env.JAVA_HOME, 'bin', process.platform === 'win32' ? 'java.exe' : 'java')
      : 'java';
    if (!fs.existsSync(signerJar)) return { passed: false, digest, certificate: '' };
    const output = execFileSync(
      java,
      ['-jar', signerJar, 'verify', '--verbose', '--print-certs', apkPath],
      { encoding: 'utf8', timeout: 30000 },
    );
    const certificateMatch = output.match(/certificate SHA-256 digest:\s*([a-f0-9]+)/i);
    const certificate = certificateMatch ? certificateMatch[1].toLowerCase() : '';
    return {
      passed: output.includes('Verifies')
        && /Verified using v2 scheme .*:\s*true/i.test(output)
        && /Number of signers:\s*1/i.test(output)
        && certificate === expectedSigningCertificate,
      digest,
      certificate,
    };
  } catch (_) {
    return { passed: false, digest, certificate: '' };
  }
}

function validIsoDate(value) {
  return typeof value === 'string'
    && /^\d{4}-\d{2}-\d{2}(?:T.*Z)?$/.test(value)
    && !Number.isNaN(Date.parse(value));
}

function sha256Content(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

function validIsoTimestamp(value) {
  if (typeof value !== 'string'
    || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z$/.test(value)) return false;
  const parsed = Date.parse(value);
  if (Number.isNaN(parsed)) return false;
  const canonical = new Date(parsed).toISOString();
  return value.includes('.') ? canonical === value : canonical.replace('.000Z', 'Z') === value;
}

function realPastTimestamp(value, nowMs = Date.now()) {
  return validIsoTimestamp(value) && Date.parse(value) <= nowMs + 5 * 60 * 1000;
}

function realEvidenceId(value) {
  if (typeof value !== 'string') return false;
  const normalized = value.trim();
  return normalized.length >= 8
    && /^[a-z0-9][a-z0-9._:/%-]*$/i.test(normalized)
    && !/(todo|tbd|placeholder|example)/i.test(normalized);
}

function realText(value, minimumLength = 2) {
  return typeof value === 'string'
    && value.trim().length >= minimumLength
    && !/(todo|tbd|placeholder|example)/i.test(value.trim());
}

function referenceWithPrefix(value, prefix) {
  return realEvidenceId(value) && value.startsWith(prefix);
}

function isPlainObject(value) {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

function hasExactKeys(value, expectedKeys) {
  if (!isPlainObject(value)) return false;
  const actual = Object.keys(value).sort();
  const expected = [...expectedKeys].sort();
  return actual.length === expected.length
    && actual.every((key, index) => key === expected[index]);
}

function canonicalJson(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(',')}]`;
  if (isPlainObject(value)) {
    return `{${Object.keys(value).sort().map((key) => (
      `${JSON.stringify(key)}:${canonicalJson(value[key])}`
    )).join(',')}}`;
  }
  return JSON.stringify(value);
}

function safeAuditArtifactPath(value) {
  if (typeof value !== 'string') return false;
  const normalized = value.replace(/\\/g, '/');
  return normalized.startsWith('docs/pilot/evidence/audits/')
    && normalized.endsWith('.json')
    && !normalized.includes('../')
    && !path.isAbsolute(value);
}

function auditArtifactContent(relativePath, expected) {
  const injected = expected?.auditArtifacts?.[relativePath];
  return typeof injected === 'string' ? injected : read(relativePath);
}

function validateAuditReference(audit, expected, {
  provider,
  eventType,
  earliestAt,
  latestAt,
  operationReference,
}) {
  if (!hasExactKeys(audit, [
    'schemaVersion',
    'provider',
    'logReference',
    'capturedAt',
    'artifactPath',
    'artifactSha256',
    'reviewReference',
    'redacted',
    'containsParticipantIdentifiers',
  ])) return false;
  if (!expected || !realPastTimestamp(audit.capturedAt, expected.nowMs)) return false;
  const referencePrefixes = {
    'google-cloud-audit-logs': `projects/${expectedFirebaseProjectId}/logs/`,
    'android-test-run': 'android-test-runs/',
    'chegaja-pilot-audit': 'pilot-audit/',
  };
  if (audit.schemaVersion !== auditReferenceSchema
    || audit.provider !== provider
    || !String(audit.logReference || '').startsWith(referencePrefixes[provider] || '__invalid__')
    || !realEvidenceId(audit.logReference)
    || !realEvidenceId(audit.reviewReference)
    || !safeAuditArtifactPath(audit.artifactPath)
    || !/^[a-f0-9]{64}$/.test(String(audit.artifactSha256 || ''))
    || audit.redacted !== true
    || audit.containsParticipantIdentifiers !== false
    || containsPiiKeys(audit)) return false;

  const content = auditArtifactContent(audit.artifactPath, expected);
  if (!content || sha256Content(content) !== audit.artifactSha256) return false;
  let artifact;
  try {
    artifact = JSON.parse(content);
  } catch (_) {
    return false;
  }
  if (!hasExactKeys(artifact, [
    'schemaVersion',
    'projectId',
    'projectNumber',
    'sourceRevision',
    'eventType',
    'occurredAt',
    'providerReference',
    'operationReference',
    'result',
    'redacted',
    'containsParticipantIdentifiers',
  ])) return false;
  const occurredAt = Date.parse(artifact.occurredAt);
  const capturedAt = Date.parse(audit.capturedAt);
  return artifact.schemaVersion === auditArtifactSchema
    && artifact.projectId === expected.projectId
    && artifact.projectNumber === expected.projectNumber
    && artifact.sourceRevision === expected.sourceRevision
    && artifact.eventType === eventType
    && realPastTimestamp(artifact.occurredAt, expected.nowMs)
    && artifact.providerReference === audit.logReference
    && artifact.operationReference === operationReference
    && artifact.result === 'SUCCESS'
    && artifact.redacted === true
    && artifact.containsParticipantIdentifiers === false
    && !containsPiiKeys(artifact)
    && occurredAt >= Date.parse(earliestAt)
    && occurredAt <= Date.parse(latestAt)
    && capturedAt >= occurredAt
    && capturedAt <= Date.parse(latestAt);
}

function validateBackendConfigManifest(manifest, manifestSha256, expected, {
  earliestAt,
  latestAt,
}) {
  if (!hasExactKeys(manifest, [
    'schemaVersion',
    'projectId',
    'projectNumber',
    'sourceRevision',
    'capturedAt',
    'environment',
    'pilotRequireAllowlist',
    'riskFlags',
    'configVersions',
    'secretVersions',
    'redacted',
    'containsSecretValues',
    'containsParticipantIdentifiers',
  ])
    || !hasExactKeys(manifest.riskFlags, requiredBackendRiskFlags)
    || !hasExactKeys(manifest.configVersions, ['functionsEnvironment', 'pilotPolicy'])
    || !Array.isArray(manifest.secretVersions)
    || manifest.secretVersions.length !== requiredBackendSecrets.length) return false;

  const secretNames = new Set();
  for (const secret of manifest.secretVersions) {
    if (!hasExactKeys(secret, ['secret', 'versionId', 'state'])
      || !requiredBackendSecrets.includes(secret.secret)
      || secretNames.has(secret.secret)
      || !/^[1-9]\d*$/.test(String(secret.versionId || ''))
      || secret.state !== 'ENABLED') return false;
    secretNames.add(secret.secret);
  }
  const capturedAt = Date.parse(manifest.capturedAt);
  return manifest.schemaVersion === backendConfigSchema
    && manifest.projectId === expected.projectId
    && manifest.projectNumber === expected.projectNumber
    && manifest.sourceRevision === expected.sourceRevision
    && realPastTimestamp(manifest.capturedAt, expected.nowMs)
    && capturedAt >= Date.parse(earliestAt)
    && capturedAt <= Date.parse(latestAt)
    && manifest.environment === 'production'
    && manifest.pilotRequireAllowlist === true
    && requiredBackendRiskFlags.every((key) => manifest.riskFlags[key] === false)
    && String(manifest.configVersions.functionsEnvironment).startsWith(
      `projects/${expected.projectId}/locations/`,
    )
    && String(manifest.configVersions.functionsEnvironment).includes('/revisions/')
    && String(manifest.configVersions.pilotPolicy).startsWith('pilot-policies/')
    && realEvidenceId(manifest.configVersions.functionsEnvironment)
    && realEvidenceId(manifest.configVersions.pilotPolicy)
    && requiredBackendSecrets.every((name) => secretNames.has(name))
    && manifest.redacted === true
    && manifest.containsSecretValues === false
    && manifest.containsParticipantIdentifiers === false
    && !containsPiiKeys(manifest)
    && /^[a-f0-9]{64}$/.test(String(manifestSha256 || ''))
    && sha256Content(canonicalJson(manifest)) === manifestSha256;
}

function deployedArtifactsMatch(artifacts, expected) {
  if (!artifacts || !expected) return false;
  const hashFields = [
    'firestoreRulesSha256',
    'storageRulesSha256',
    'functionsIndexSha256',
    'functionsRuntimeSourceFingerprintSha256',
    'functionsPackageSha256',
    'functionsPackageLockSha256',
    'functionsDeployFingerprintSha256',
  ];
  return hasExactKeys(artifacts, [
    'hashAlgorithm',
    'functionsRuntimeSchema',
    'functionsRuntimeFileCount',
    ...hashFields,
  ])
    && !containsPiiKeys(artifacts)
    && hashFields.every((key) => (
    typeof artifacts[key] === 'string'
      && /^[a-f0-9]{64}$/i.test(artifacts[key])
      && artifacts[key] === expected[key]
  ))
    && artifacts.hashAlgorithm === 'sha256-canonical-text-v1'
    && artifacts.hashAlgorithm === expected.hashAlgorithm
    && artifacts.functionsRuntimeSchema === 'functions-runtime-js-v2'
    && artifacts.functionsRuntimeSchema === expected.functionsRuntimeSchema
    && Number.isInteger(artifacts.functionsRuntimeFileCount)
    && artifacts.functionsRuntimeFileCount > 0
    && artifacts.functionsRuntimeFileCount === expected.functionsRuntimeFileCount;
}

function validateFirestoreIndexDeployment(indexDeployment, expected, {
  earliestAt,
  latestAt,
}) {
  if (!expected) return false;
  if (!hasExactKeys(indexDeployment, [
    'schemaVersion',
    'projectId',
    'checkedAt',
    'manifestSha256',
    'allDeclaredIndexesReady',
    'allDeclaredFieldOverridesReady',
    'cloudOutputArtifactPath',
    'cloudOutputArtifactSha256',
    'declaredIndexes',
    'declaredFieldOverrides',
  ])
    || indexDeployment.schemaVersion !== firestoreIndexDeploymentSchema
    || indexDeployment.projectId !== expectedFirebaseProjectId
    || indexDeployment.projectId !== expected.projectId
    || !realPastTimestamp(indexDeployment.checkedAt, expected.nowMs)
    || Date.parse(indexDeployment.checkedAt) < Date.parse(earliestAt)
    || Date.parse(indexDeployment.checkedAt) > Date.parse(latestAt)
    || !/^[a-f0-9]{64}$/.test(String(indexDeployment.manifestSha256 || ''))
    || indexDeployment.manifestSha256 !== sha256File('firestore.indexes.json')
    || indexDeployment.allDeclaredIndexesReady !== true
    || indexDeployment.allDeclaredFieldOverridesReady !== true
    || !safeAuditArtifactPath(indexDeployment.cloudOutputArtifactPath)
    || !/^[a-f0-9]{64}$/.test(String(indexDeployment.cloudOutputArtifactSha256 || ''))
    || !Array.isArray(indexDeployment.declaredIndexes)
    || indexDeployment.declaredIndexes.length === 0
    || !Array.isArray(indexDeployment.declaredFieldOverrides)
    || containsPiiKeys(indexDeployment)) return false;

  const manifest = readJson('firestore.indexes.json');
  const manifestIndexes = manifest?.indexes;
  if (!hasExactKeys(manifest, ['indexes', 'fieldOverrides'])
    || !Array.isArray(manifestIndexes)
    || manifestIndexes.length === 0
    || !Array.isArray(manifest.fieldOverrides)) return false;

  const indexDefinitionKey = (index) => canonicalJson({
    collectionGroup: index.collectionGroup,
    queryScope: index.queryScope,
    fields: index.fields,
  });
  const validateReadyIndex = (index) => {
    if (!hasExactKeys(index, [
      'collectionGroup',
      'queryScope',
      'fields',
      'state',
    ])
      || typeof index.collectionGroup !== 'string'
      || index.collectionGroup.length === 0
      || !['COLLECTION', 'COLLECTION_GROUP'].includes(index.queryScope)
      || !Array.isArray(index.fields)
      || index.fields.length === 0
      || index.state !== 'READY') return false;

    for (const field of index.fields) {
      const hasOrder = hasExactKeys(field, ['fieldPath', 'order'])
        && ['ASCENDING', 'DESCENDING'].includes(field.order);
      const hasArrayConfig = hasExactKeys(field, ['fieldPath', 'arrayConfig'])
        && field.arrayConfig === 'CONTAINS';
      if (typeof field?.fieldPath !== 'string'
        || field.fieldPath.length === 0
        || (!hasOrder && !hasArrayConfig)) return false;
    }
    return true;
  };
  const fieldOverrideDefinitionKey = (fieldOverride) => canonicalJson({
    collectionGroup: fieldOverride.collectionGroup,
    fieldPath: fieldOverride.fieldPath,
    ttl: fieldOverride.ttl,
    indexes: fieldOverride.indexes,
  });
  const validateReadyFieldOverride = (fieldOverride) => {
    if (!hasExactKeys(fieldOverride, [
      'collectionGroup',
      'fieldPath',
      'ttl',
      'indexes',
      'state',
    ])
      || typeof fieldOverride.collectionGroup !== 'string'
      || fieldOverride.collectionGroup.length === 0
      || typeof fieldOverride.fieldPath !== 'string'
      || fieldOverride.fieldPath.length === 0
      || fieldOverride.ttl !== true
      || !Array.isArray(fieldOverride.indexes)
      || fieldOverride.state !== 'READY') return false;

    return fieldOverride.indexes.every((index) => {
      const hasOrder = hasExactKeys(index, ['order'])
        && ['ASCENDING', 'DESCENDING'].includes(index.order);
      const hasArrayConfig = hasExactKeys(index, ['arrayConfig'])
        && index.arrayConfig === 'CONTAINS';
      return hasOrder || hasArrayConfig;
    });
  };
  const manifestDefinitionsValid = manifestIndexes.every((index) => (
    validateReadyIndex({ ...index, state: 'READY' })
      && hasExactKeys(index, ['collectionGroup', 'queryScope', 'fields'])
  ));
  const manifestFieldOverridesValid = manifest.fieldOverrides.every((fieldOverride) => (
    validateReadyFieldOverride({ ...fieldOverride, state: 'READY' })
      && hasExactKeys(fieldOverride, [
        'collectionGroup',
        'fieldPath',
        'ttl',
        'indexes',
      ])
  ));
  if (!manifestDefinitionsValid
    || !manifestFieldOverridesValid
    || !indexDeployment.declaredIndexes.every(validateReadyIndex)
    || !indexDeployment.declaredFieldOverrides.every(validateReadyFieldOverride)) return false;

  const manifestKeys = manifestIndexes.map(indexDefinitionKey);
  const declaredKeys = indexDeployment.declaredIndexes.map(indexDefinitionKey);
  const manifestKeySet = new Set(manifestKeys);
  const declaredKeySet = new Set(declaredKeys);
  if (manifestKeySet.size !== manifestKeys.length
    || declaredKeySet.size !== declaredKeys.length
    || declaredKeys.length !== manifestKeys.length
    || declaredKeys.some((key) => !manifestKeySet.has(key))
    || !manifestKeySet.has(canonicalJson(requiredProviderGrantIndex))) return false;
  const manifestFieldOverrideKeys = manifest.fieldOverrides.map(fieldOverrideDefinitionKey);
  const declaredFieldOverrideKeys = indexDeployment.declaredFieldOverrides
    .map(fieldOverrideDefinitionKey);
  const manifestFieldOverrideKeySet = new Set(manifestFieldOverrideKeys);
  const declaredFieldOverrideKeySet = new Set(declaredFieldOverrideKeys);
  if (manifestFieldOverrideKeySet.size !== manifestFieldOverrideKeys.length
    || declaredFieldOverrideKeySet.size !== declaredFieldOverrideKeys.length
    || declaredFieldOverrideKeys.length !== manifestFieldOverrideKeys.length
    || declaredFieldOverrideKeys.some((key) => !manifestFieldOverrideKeySet.has(key))) {
    return false;
  }

  const artifactContent = auditArtifactContent(
    indexDeployment.cloudOutputArtifactPath,
    expected,
  );
  if (!artifactContent
    || sha256Content(artifactContent) !== indexDeployment.cloudOutputArtifactSha256) return false;

  let artifact;
  try {
    artifact = JSON.parse(artifactContent);
  } catch (_) {
    return false;
  }
  if (!hasExactKeys(artifact, [
    'schemaVersion',
    'projectId',
    'checkedAt',
    'sourceCommands',
    'redacted',
    'containsParticipantIdentifiers',
    'indexes',
    'fieldOverrides',
  ])
    || artifact.schemaVersion !== firestoreIndexCloudOutputSchema
    || artifact.projectId !== expectedFirebaseProjectId
    || artifact.projectId !== expected.projectId
    || artifact.projectId !== indexDeployment.projectId
    || artifact.checkedAt !== indexDeployment.checkedAt
    || !Array.isArray(artifact.sourceCommands)
    || artifact.sourceCommands.length !== 2
    || artifact.sourceCommands[0]
      !== `gcloud firestore indexes composite list --project=${expectedFirebaseProjectId} --format=json`
    || artifact.sourceCommands[1]
      !== `gcloud firestore fields list --project=${expectedFirebaseProjectId} --format=json`
    || artifact.redacted !== true
    || artifact.containsParticipantIdentifiers !== false
    || !Array.isArray(artifact.indexes)
    || !Array.isArray(artifact.fieldOverrides)
    || containsPiiKeys(artifact)
    || !artifact.indexes.every(validateReadyIndex)
    || !artifact.fieldOverrides.every(validateReadyFieldOverride)) return false;

  const artifactKeys = artifact.indexes.map((index) => canonicalJson(index));
  const proofKeys = indexDeployment.declaredIndexes.map((index) => canonicalJson(index));
  const proofKeySet = new Set(proofKeys);
  const artifactFieldOverrideKeys = artifact.fieldOverrides.map((fieldOverride) => (
    canonicalJson(fieldOverride)
  ));
  const proofFieldOverrideKeys = indexDeployment.declaredFieldOverrides.map((fieldOverride) => (
    canonicalJson(fieldOverride)
  ));
  const proofFieldOverrideKeySet = new Set(proofFieldOverrideKeys);
  return new Set(artifactKeys).size === artifactKeys.length
    && new Set(proofKeys).size === proofKeys.length
    && artifactKeys.length === proofKeys.length
    && artifactKeys.every((key) => proofKeySet.has(key))
    && new Set(artifactFieldOverrideKeys).size === artifactFieldOverrideKeys.length
    && new Set(proofFieldOverrideKeys).size === proofFieldOverrideKeys.length
    && artifactFieldOverrideKeys.length === proofFieldOverrideKeys.length
    && artifactFieldOverrideKeys.every((key) => proofFieldOverrideKeySet.has(key));
}

function validateCutoverMigrationEvidence(evidence, expected) {
  if (!evidence || !expected) return false;
  if (!hasExactKeys(evidence, [
    'schemaVersion',
    'status',
    'dryRun',
    'projectId',
    'projectNumber',
    'sourceRevision',
    'cutoverWindowId',
    'cutoverReference',
    'migrationExecutionReference',
    'deploymentReference',
    'writesFrozenAt',
    'migrationStartedAt',
    'migrationCompletedAt',
    'migrationRerunAt',
    'capturedAt',
    'deploymentCompletedAt',
    'containsParticipantIdentifiers',
    'additiveMigration',
    'pedidoGrantReconciliation',
    'pedidoDispatchReconciliation',
    'storageBoundaryMigration',
    'backendConfigManifest',
    'backendConfigManifestSha256',
    'deploymentAudit',
    'firestoreIndexDeployment',
    'deployedArtifacts',
  ])) return false;
  const additive = evidence.additiveMigration || {};
  const grants = evidence.pedidoGrantReconciliation || {};
  const dispatch = evidence.pedidoDispatchReconciliation || {};
  const storage = evidence.storageBoundaryMigration || {};
  const timestamps = [
    evidence.writesFrozenAt,
    evidence.migrationStartedAt,
    evidence.migrationCompletedAt,
    evidence.capturedAt,
    evidence.deploymentCompletedAt,
  ];
  if (!timestamps.every((value) => realPastTimestamp(value, expected.nowMs))) return false;
  const times = timestamps.map((value) => Date.parse(value));
  const ordered = times[0] < times[1]
    && times[1] < times[2]
    && times[2] <= times[3]
    && times[3] < times[4];
  const windowEndsAt = times[0] + 24 * 60 * 60 * 1000;
  const withinTwentyFourHours = times[times.length - 1] <= windowEndsAt;

  return evidence.schemaVersion === deploymentEvidenceSchema
    && String(evidence.status).toUpperCase() === 'COMPLETED'
    && evidence.dryRun === false
    && evidence.projectId === expected.projectId
    && evidence.projectNumber === expected.projectNumber
    && evidence.sourceRevision === expected.sourceRevision
    && /^[a-f0-9]{40}$/.test(String(evidence.sourceRevision || ''))
    && referenceWithPrefix(evidence.cutoverWindowId, 'cutover-')
    && referenceWithPrefix(evidence.cutoverReference, 'change-request-')
    && referenceWithPrefix(evidence.migrationExecutionReference, 'migration-run-')
    && referenceWithPrefix(evidence.deploymentReference, 'firebase-deploy-')
    && new Set([
      evidence.cutoverWindowId,
      evidence.cutoverReference,
      evidence.migrationExecutionReference,
      evidence.deploymentReference,
    ]).size === 4
    && evidence.migrationRerunAt === evidence.migrationCompletedAt
    && evidence.containsParticipantIdentifiers === false
    && !containsPiiKeys(evidence)
    && hasExactKeys(additive, [
      'executed',
      'deletesPerformed',
      'publicDocumentsWithForbiddenSensitiveFieldNames',
    ])
    && additive.executed === true
    && additive.deletesPerformed === 0
    && additive.publicDocumentsWithForbiddenSensitiveFieldNames === 0
    && hasExactKeys(grants, [
      'schemaVersion',
      'executed',
      'dryRun',
      'scanned',
      'collectionTotalObserved',
      'backfilled',
      'revoked',
      'unchanged',
      'manualReview',
      'inconsistentAfter',
      'deletesPerformed',
      'executionOutputSha256',
    ])
    && grants.schemaVersion === 'pedido-grant-reconciliation-v1'
    && grants.executed === true
    && grants.dryRun === false
    && [
      grants.scanned,
      grants.collectionTotalObserved,
      grants.backfilled,
      grants.revoked,
      grants.unchanged,
      grants.manualReview,
      grants.inconsistentAfter,
      grants.deletesPerformed,
    ].every((value) => Number.isInteger(value) && value >= 0)
    && grants.scanned > 0
    && grants.collectionTotalObserved === grants.scanned
    && grants.scanned === (
      grants.backfilled + grants.revoked + grants.unchanged + grants.manualReview
    )
    && /^[a-f0-9]{64}$/.test(String(grants.executionOutputSha256 || ''))
    && grants.manualReview === 0
    && grants.inconsistentAfter === 0
    && grants.deletesPerformed === 0
    && hasExactKeys(dispatch, [
      'schemaVersion',
      'hashAlgorithm',
      'executed',
      'dryRun',
      'documentIdsIncluded',
      'scanned',
      'collectionTotalObserved',
      'dispatchScanned',
      'eligibleOpen',
      'eligibleTargeted',
      'upserted',
      'deletedTerminalOrStale',
      'deletedOrphan',
      'unchanged',
      'inconsistentBefore',
      'inconsistentAfter',
      'executionOutputSha256',
    ])
    && dispatch.schemaVersion === 'pedido-dispatch-reconciliation-v1'
    && dispatch.hashAlgorithm === 'sha256-canonical-json-v1'
    && dispatch.executed === true
    && dispatch.dryRun === false
    && dispatch.documentIdsIncluded === false
    && [
      dispatch.scanned,
      dispatch.collectionTotalObserved,
      dispatch.dispatchScanned,
      dispatch.eligibleOpen,
      dispatch.eligibleTargeted,
      dispatch.upserted,
      dispatch.deletedTerminalOrStale,
      dispatch.deletedOrphan,
      dispatch.unchanged,
      dispatch.inconsistentBefore,
      dispatch.inconsistentAfter,
    ].every((value) => Number.isInteger(value) && value >= 0)
    && dispatch.scanned > 0
    && dispatch.collectionTotalObserved === dispatch.scanned
    && dispatch.eligibleOpen + dispatch.eligibleTargeted <= dispatch.scanned
    && dispatch.unchanged <= dispatch.eligibleOpen + dispatch.eligibleTargeted
    && dispatch.inconsistentAfter === 0
    && /^[a-f0-9]{64}$/.test(String(dispatch.executionOutputSha256 || ''))
    && hasExactKeys(storage, [
      'executed',
      'objectsDeleted',
      'restrictedObjectsWithPersistentDownloadTokens',
      'nonPublicObjectsWithPersistentDownloadTokens',
    ])
    && storage.executed === true
    && storage.objectsDeleted === 0
    && storage.restrictedObjectsWithPersistentDownloadTokens === 0
    && storage.nonPublicObjectsWithPersistentDownloadTokens === 0
    && validateBackendConfigManifest(
      evidence.backendConfigManifest,
      evidence.backendConfigManifestSha256,
      expected,
      { earliestAt: evidence.writesFrozenAt, latestAt: evidence.deploymentCompletedAt },
    )
    && validateAuditReference(evidence.deploymentAudit, expected, {
      provider: 'google-cloud-audit-logs',
      eventType: 'firebase-deployment',
      earliestAt: evidence.deploymentCompletedAt,
      latestAt: new Date(windowEndsAt).toISOString(),
      operationReference: evidence.deploymentReference,
    })
    && validateFirestoreIndexDeployment(evidence.firestoreIndexDeployment, expected, {
      earliestAt: evidence.deploymentCompletedAt,
      latestAt: new Date(windowEndsAt).toISOString(),
    })
    && deployedArtifactsMatch(evidence.deployedArtifacts, expected)
    && ordered
    && withinTwentyFourHours;
}

function validateLegalApproval(content) {
  if (!content) return false;
  const field = (key) => {
    const match = content.match(new RegExp(`^${key}:\\s*(.+?)\\s*$`, 'im'));
    return match ? match[1].trim() : '';
  };
  const isRealValue = (value) => Boolean(value)
    && !/^(todo|tbd|placeholder|example)(?:\b|[-_])/i.test(value);
  return field('status').toUpperCase() === 'APPROVED'
    && isRealValue(field('legal_entity'))
    && isRealValue(field('reviewer'))
    && /^\d{4}-\d{2}-\d{2}$/.test(field('reviewed_at'))
    && field('document_version') === 'legal-2026-07-20-pilot-v3'
    && isRealValue(field('approval_reference'));
}

function validateLegalIdentity(values) {
  if (!values) return false;
  const realValue = (value) => typeof value === 'string'
    && value.trim().length > 0
    && !/(piloto controlado|por confirmar|todo|tbd|placeholder|example)/i.test(value);
  const email = String(values.LEGAL_CONTACT_EMAIL || '').trim();
  const allowedTypes = new Set([
    'individual_project_promoter',
    'individual_entrepreneur',
    'incorporated_company',
  ]);
  return realValue(values.LEGAL_ENTITY_NAME)
    && allowedTypes.has(String(values.LEGAL_ENTITY_TYPE || '').trim())
    && realValue(email)
    && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    && realValue(values.LEGAL_CONTACT_ADDRESS);
}

function validateAppCheckEvidence(evidence, expected) {
  if (!hasExactKeys(evidence, [
    'schemaVersion',
    'projectId',
    'projectNumber',
    'sourceRevision',
    'capturedAt',
    'cutoverWindowId',
    'cutoverReference',
    'migrationExecutionReference',
    'migrationRerunAt',
    'deploymentCompletedAt',
    'apkSha256',
    'services',
    'functionsCallablesEnforceAppCheck',
    'deploymentReference',
    'enforcementReference',
    'backendConfigManifestSha256',
    'enforcementAudit',
    'deployedArtifacts',
  ]) || !realPastTimestamp(evidence.capturedAt, expected?.nowMs)) return false;
  if (!expected || !expected.apkSha256) return false;
  const cutover = expected.cutoverEvidence;
  if (!validateCutoverMigrationEvidence(cutover, expected)) return false;
  const services = evidence.services || {};
  const artifacts = evidence.deployedArtifacts || {};
  const enforced = (key) => String(services[key] || '').toUpperCase() === 'ENFORCED';
  const appCheckAt = Date.parse(evidence.capturedAt);
  const writesFrozenAt = Date.parse(cutover.writesFrozenAt);
  const deploymentCompletedAt = Date.parse(cutover.deploymentCompletedAt);
  const windowEndsAt = writesFrozenAt + 24 * 60 * 60 * 1000;
  const chronologyValid = deploymentCompletedAt < appCheckAt
    && appCheckAt - writesFrozenAt <= 24 * 60 * 60 * 1000;
  return evidence.schemaVersion === deploymentEvidenceSchema
    && evidence.projectId === expected.projectId
    && evidence.projectId === cutover.projectId
    && evidence.projectNumber === expected.projectNumber
    && evidence.projectNumber === cutover.projectNumber
    && evidence.sourceRevision === expected.sourceRevision
    && evidence.sourceRevision === cutover.sourceRevision
    && /^[a-f0-9]{40}$/.test(String(evidence.sourceRevision || ''))
    && hasExactKeys(services, ['firestore', 'storage', 'authentication'])
    && enforced('firestore')
    && enforced('storage')
    && enforced('authentication')
    && evidence.functionsCallablesEnforceAppCheck === true
    && evidence.cutoverWindowId === cutover.cutoverWindowId
    && evidence.cutoverReference === cutover.cutoverReference
    && evidence.migrationExecutionReference
      === cutover.migrationExecutionReference
    && evidence.migrationRerunAt === cutover.migrationRerunAt
    && evidence.deploymentCompletedAt === cutover.deploymentCompletedAt
    && evidence.deploymentReference === cutover.deploymentReference
    && referenceWithPrefix(evidence.enforcementReference, 'appcheck-enforcement-')
    && evidence.enforcementReference !== evidence.deploymentReference
    && evidence.apkSha256 === expected.apkSha256
    && evidence.backendConfigManifestSha256 === cutover.backendConfigManifestSha256
    && /^[a-f0-9]{64}$/.test(String(evidence.backendConfigManifestSha256 || ''))
    && realEvidenceId(evidence.deploymentReference)
    && !containsPiiKeys(evidence)
    && chronologyValid
    && validateAuditReference(evidence.enforcementAudit, expected, {
      provider: 'google-cloud-audit-logs',
      eventType: 'app-check-enforcement',
      earliestAt: evidence.capturedAt,
      latestAt: new Date(windowEndsAt).toISOString(),
      operationReference: evidence.enforcementReference,
    })
    && deployedArtifactsMatch(artifacts, expected);
}

function validateDeletionSecretEvidence(evidence, source) {
  if (!evidence || !validIsoDate(evidence.capturedAt)) return false;
  return evidence.projectId === 'chegaja-ac88d'
    && evidence.projectNumber === '767588494857'
    && evidence.secretName === 'ACCOUNT_DELETION_PEPPER'
    && /^\d+$/.test(String(evidence.activeVersion?.versionId || ''))
    && evidence.activeVersion?.state === 'ENABLED'
    && validIsoDate(evidence.activeVersion?.createTime)
    && evidence.secretValueStoredInRepository === false
    && source.includes("defineSecret('ACCOUNT_DELETION_PEPPER')")
    && source.includes('secrets: [ACCOUNT_DELETION_PEPPER]');
}

function validateStorageBoundaryEvidence(evidence) {
  if (!evidence || !validIsoDate(evidence.capturedAt)) return false;
  const audit = evidence.audit || {};
  const lifecycle = evidence.quarantineLifecycle || {};
  const temporary = evidence.temporaryUploadLifecycle || {};
  return evidence.projectId === 'chegaja-ac88d'
    && evidence.bucket === 'chegaja-ac88d.firebasestorage.app'
    && evidence.privacySafeOutput === true
    && evidence.objectNamesIncluded === false
    && audit.passed === true
    && audit.restrictedObjectsWithDownloadTokens === 0
    && audit.nonPublicObjectsWithDownloadTokens === 0
    && audit.suspiciousObjectsInPublicPaths === 0
    && audit.disabledStoryObjects === 0
    && audit.unknownObjects === 0
    && lifecycle.action === 'Delete'
    && Number(lifecycle.ageDays) === 30
    && lifecycle.matchesPrefix === 'migration_quarantine/'
    && temporary.action === 'Delete'
    && Number(temporary.ageDays) === 2
    && temporary.matchesPrefix === 'temp/';
}

function validatePreparationSourceEvidence(evidence, expected) {
  if (!evidence || !validIsoDate(evidence.capturedAt) || !expected) return false;
  const hashes = evidence.localArtifactHashes || {};
  return evidence.projectId === 'chegaja-ac88d'
    && evidence.containsParticipantIdentifiers === false
    && evidence.additiveMigration?.rerunRequiredImmediatelyBeforeCutover === true
    && hashes.firestoreRulesSha256 === expected.firestoreRulesSha256
    && hashes.storageRulesSha256 === expected.storageRulesSha256
    && hashes.functionsIndexSha256 === expected.functionsIndexSha256
    && hashes.functionsPackageSha256 === expected.functionsPackageSha256
    && hashes.functionsPackageLockSha256 === expected.functionsPackageLockSha256
    && hashes.functionsRuntimeSchema === expected.functionsRuntimeSchema
    && hashes.functionsRuntimeFileCount === expected.functionsRuntimeFileCount
    && hashes.functionsRuntimeSourceFingerprintSha256
      === expected.functionsRuntimeSourceFingerprintSha256
    && hashes.functionsDeployFingerprintSha256
      === expected.functionsDeployFingerprintSha256
    && hashes.hashAlgorithm === expected.hashAlgorithm;
}

function validateReleaseProvenance(evidence, apkDigest) {
  if (!hasExactKeys(evidence, [
    'attestationSchema',
    'fingerprintSchema',
    'generatedAt',
    'apkSha256',
    'releaseSourceFingerprint',
    'preBuildSourceFingerprint',
    'postBuildSourceFingerprint',
    'sourceStableDuringBuild',
    'sourceRevision',
    'sourceTreeClean',
    'preBuildCapturedAt',
    'postBuildCapturedAt',
    'releaseInputFiles',
    'releaseVirtualInputs',
    'generatedRegistrantExcluded',
    'localPathsSerialized',
    'secretValuesSerialized',
  ]) || !apkDigest) return false;
  const inputs = collectReleaseInputs();
  const virtualInputs = collectVirtualReleaseInputs();
  const preBuildAt = Date.parse(evidence.preBuildCapturedAt);
  const postBuildAt = Date.parse(evidence.postBuildCapturedAt);
  const generatedAt = Date.parse(evidence.generatedAt);
  return evidence.attestationSchema === buildAttestationSchema
    && evidence.fingerprintSchema === releaseInputSchema
    && realPastTimestamp(evidence.preBuildCapturedAt)
    && realPastTimestamp(evidence.postBuildCapturedAt)
    && realPastTimestamp(evidence.generatedAt)
    && preBuildAt <= postBuildAt
    && postBuildAt <= generatedAt
    && evidence.apkSha256 === apkDigest
    && evidence.releaseSourceFingerprint
      === releaseSourceFingerprint(inputs, virtualInputs)
    && evidence.preBuildSourceFingerprint === evidence.releaseSourceFingerprint
    && evidence.postBuildSourceFingerprint === evidence.releaseSourceFingerprint
    && evidence.sourceStableDuringBuild === true
    && /^[a-f0-9]{40}$/.test(String(evidence.sourceRevision || ''))
    && evidence.sourceTreeClean === true
    && Number(evidence.releaseInputFiles) === inputs.length
    && Number(evidence.releaseVirtualInputs) === virtualInputs.length
    && evidence.generatedRegistrantExcluded === true
    && evidence.localPathsSerialized === false
    && evidence.secretValuesSerialized === false
    && !containsPiiKeys(evidence);
}

function validateAndroidRuntimeEvidence({
  evidence,
  uiEvidence,
  runtimeLogEvidence,
  releaseProvenance,
  apkDigest,
  applicationId = expectedAndroidPackage,
}) {
  if (!hasExactKeys(evidence, [
    'status',
    'capturedAt',
    'apkSha256',
    'fingerprintSchema',
    'releaseSourceFingerprint',
    'releaseInputFiles',
    'releaseVirtualInputs',
    'packageId',
    'activity',
    'activityInForeground',
    'processAliveAfterInteraction',
    'device',
    'screen',
    'startupPermissionPrompt',
    'interactionCheck',
    'fatalMatchPolicy',
    'fatalPatternsChecked',
    'fatalPatternsMatched',
    'runtimeLogSha256',
    'nonFatalDiagnostics',
    'environmentDiagnostics',
    'artifacts',
  ]) || !releaseProvenance || !apkDigest || !uiEvidence || !realText(runtimeLogEvidence)) {
    return false;
  }
  const capturedAt = Date.parse(evidence.capturedAt);
  const provenanceGeneratedAt = Date.parse(releaseProvenance.generatedAt);
  const device = evidence.device || {};
  const screen = evidence.screen || {};
  const artifacts = Array.isArray(evidence.artifacts) ? evidence.artifacts : [];
  const diagnostics = Array.isArray(evidence.nonFatalDiagnostics)
    ? evidence.nonFatalDiagnostics : [];
  const normalizedRuntimeLog = runtimeLogEvidence.toUpperCase();
  if (!hasExactKeys(device, [
    'physical',
    'manufacturer',
    'model',
    'androidVersion',
    'apiLevel',
    'abi',
    'avdName',
    'buildFingerprint',
    'bootCompleted',
  ]) || !hasExactKeys(screen, [
    'physicalSize',
    'title',
    'clientAction',
    'providerAction',
  ]) || diagnostics.some((item) => !hasExactKeys(
    item,
    ['pattern', 'count', 'level', 'classification'],
  ))) return false;

  return evidence.status === 'COMPLETED'
    && validateReleaseProvenance(releaseProvenance, apkDigest)
    && realPastTimestamp(evidence.capturedAt)
    && validIsoTimestamp(releaseProvenance.generatedAt)
    && capturedAt >= provenanceGeneratedAt
    && evidence.apkSha256 === apkDigest
    && evidence.fingerprintSchema === releaseInputSchema
    && evidence.fingerprintSchema === releaseProvenance.fingerprintSchema
    && evidence.releaseSourceFingerprint === releaseProvenance.releaseSourceFingerprint
    && Number(evidence.releaseInputFiles) === Number(releaseProvenance.releaseInputFiles)
    && Number(evidence.releaseVirtualInputs) === Number(releaseProvenance.releaseVirtualInputs)
    && evidence.packageId === applicationId
    && evidence.activity === `${applicationId}/.MainActivity`
    && evidence.activityInForeground === true
    && evidence.processAliveAfterInteraction === true
    && evidence.startupPermissionPrompt === false
    && evidence.interactionCheck === 'vertical_scroll_without_navigation'
    && device.physical === false
    && device.bootCompleted === true
    && Number.isInteger(Number(device.apiLevel))
    && Number(device.apiLevel) >= 33
    && typeof device.abi === 'string'
    && device.abi.length > 0
    && screen.title === 'Bem-vindo ao ChegaJá'
    && screen.clientAction === 'Sou cliente'
    && screen.providerAction === 'Sou prestador'
    && uiEvidence.includes(`package="${applicationId}"`)
    && uiEvidence.includes('Bem-vindo ao ChegaJá')
    && uiEvidence.includes('Sou cliente')
    && uiEvidence.includes('Sou prestador')
    && Array.isArray(evidence.fatalPatternsMatched)
    && evidence.fatalPatternsMatched.length === 0
    && Array.isArray(evidence.fatalPatternsChecked)
    && evidence.fatalPatternsChecked.length > 0
    && evidence.fatalPatternsChecked.every((value) => realText(value))
    && /^[a-f0-9]{64}$/.test(String(evidence.runtimeLogSha256 || ''))
    && evidence.runtimeLogSha256 === sha256Content(runtimeLogEvidence)
    && evidence.fatalPatternsChecked.every((value) => (
      !normalizedRuntimeLog.includes(value.toUpperCase())
    ))
    && realText(evidence.fatalMatchPolicy)
    && diagnostics.every((item) => (
      realText(item.pattern)
      && Number.isInteger(item.count)
      && item.count >= 0
      && realText(item.level)
      && realText(item.classification)
    ))
    && Array.isArray(evidence.environmentDiagnostics)
    && evidence.environmentDiagnostics.every((value) => realText(value))
    && !containsPiiKeys(evidence)
    && artifacts.length === 4
    && artifacts.includes(versionedAndroidScreenshot)
    && artifacts.includes(versionedAndroidUi)
    && artifacts.includes(versionedAndroidRuntimeLog)
    && artifacts.includes(versionedReleaseProvenance);
}

function validateAndroidProductionIdentity(identity) {
  const googleServices = identity.googleServices || {};
  const androidClients = Array.isArray(googleServices.client) ? googleServices.client : [];
  const productionClient = androidClients.find((client) => (
    client?.client_info?.android_client_info?.package_name === expectedAndroidPackage
  ));
  const flutterConfig = identity.firebaseFlutter?.flutter?.platforms || {};
  const localConfig = identity.firebaseLocal?.flutter?.platforms || {};
  const assetTargets = Array.isArray(identity.assetLinks) ? identity.assetLinks : [];
  const productionAssetTarget = assetTargets.find((entry) => (
    entry?.target?.namespace === 'android_app'
      && entry.target.package_name === expectedAndroidPackage
  ));
  const assetCertificates = productionAssetTarget?.target?.sha256_cert_fingerprints || [];
  const normalizedAssetCertificates = assetCertificates.map((value) => (
    String(value).replace(/:/g, '').toLowerCase()
  ));

  return identity.applicationId === expectedAndroidPackage
    && identity.namespace === expectedAndroidPackage
    && identity.mainActivity.includes(`package ${expectedAndroidPackage}`)
    && productionClient?.client_info?.mobilesdk_app_id === expectedAndroidFirebaseAppId
    && identity.firebaseOptions.includes(`appId: '${expectedAndroidFirebaseAppId}'`)
    && flutterConfig.android?.default?.appId === expectedAndroidFirebaseAppId
    && flutterConfig.dart?.['lib/firebase_options.dart']?.configurations?.android
      === expectedAndroidFirebaseAppId
    && localConfig.android?.default?.appId === expectedAndroidFirebaseAppId
    && localConfig.dart?.['lib/firebase_options.dart']?.configurations?.android
      === expectedAndroidFirebaseAppId
    && normalizedAssetCertificates.includes(expectedSigningCertificate);
}

function validatePhysicalEvidence(evidence, expected) {
  if (!hasExactKeys(evidence, [
    'schemaVersion',
    'status',
    'projectId',
    'projectNumber',
    'sourceRevision',
    'executedAt',
    'apkSha256',
    'testRunReference',
    'device',
    'cases',
    'evidenceBundle',
    'logsRedacted',
    'containsParticipantIdentifiers',
  ]) || String(evidence.status).toUpperCase() !== 'COMPLETED' || !expected) return false;
  const device = evidence.device || {};
  const results = Array.isArray(evidence.cases) ? evidence.cases : [];
  if (!hasExactKeys(device, [
    'physical',
    'apiLevel',
    'androidVersion',
    'manufacturer',
    'model',
    'network',
  ]) || results.length !== requiredPhysicalCases.length) return false;
  const passedCases = new Set();
  const caseReferences = new Set();
  for (const item of results) {
    if (!hasExactKeys(item, ['id', 'result', 'evidenceReference'])
      || !requiredPhysicalCases.includes(item.id)
      || passedCases.has(item.id)
      || item.result !== 'passed'
      || !realEvidenceId(item.evidenceReference)
      || caseReferences.has(item.evidenceReference)) return false;
    passedCases.add(item.id);
    caseReferences.add(item.evidenceReference);
  }
  if (!realPastTimestamp(evidence.executedAt, expected.nowMs)) return false;
  const executedAt = Date.parse(evidence.executedAt);
  const evidenceDeadline = new Date(executedAt + 24 * 60 * 60 * 1000).toISOString();
  return evidence.schemaVersion === physicalEvidenceSchema
    && evidence.projectId === expected.projectId
    && evidence.projectNumber === expected.projectNumber
    && evidence.sourceRevision === expected.sourceRevision
    && /^[a-f0-9]{40}$/.test(String(evidence.sourceRevision || ''))
    && evidence.apkSha256 === expected.apkSha256
    && referenceWithPrefix(evidence.testRunReference, 'android-run-')
    && device.physical === true
    && Number.isInteger(device.apiLevel)
    && device.apiLevel >= 33
    && realText(device.androidVersion)
    && realText(device.manufacturer)
    && realText(device.model)
    && realText(device.network)
    && requiredPhysicalCases.every((id) => passedCases.has(id))
    && evidence.logsRedacted === true
    && evidence.containsParticipantIdentifiers === false
    && !containsPiiKeys(evidence)
    && validateAuditReference(evidence.evidenceBundle, expected, {
      provider: 'android-test-run',
      eventType: 'android-physical-validation',
      earliestAt: evidence.executedAt,
      latestAt: evidenceDeadline,
      operationReference: evidence.testRunReference,
    });
}

function containsPiiKeys(value) {
  if (Array.isArray(value)) return value.some(containsPiiKeys);
  if (!value || typeof value !== 'object') return false;
  const forbiddenSuffixes = [
    'fullname',
    'email',
    'phone',
    'telephone',
    'address',
    'street',
    'house',
    'document',
    'documentnumber',
    'token',
    'uid',
    'userid',
    'participantid',
    'clientid',
    'providerid',
    'latitude',
    'longitude',
    'coordinates',
    'gps',
    'ipaddress',
    'nuit',
    'nif',
    'taxid',
    'imei',
    'serialnumber',
  ];
  return Object.entries(value).some(([key, child]) => {
    const normalized = key.replace(/[^a-z0-9]/gi, '').toLowerCase();
    return normalized === 'name'
      || forbiddenSuffixes.some((suffix) => normalized === suffix || normalized.endsWith(suffix))
      || containsPiiKeys(child);
  });
}

function validateRealPilotEvidence(evidence, expected) {
  if (!hasExactKeys(evidence, [
    'schemaVersion',
    'status',
    'projectId',
    'projectNumber',
    'sourceRevision',
    'startedAt',
    'completedAt',
    'capturedAt',
    'apkSha256',
    'cohort',
    'metrics',
    'cohortReference',
    'consentAuditReference',
    'metricsSnapshotReference',
    'closureReference',
    'participantConsentRecorded',
    'aggregatedDataOnly',
    'containsParticipantIdentifiers',
    'closureApproved',
    'closureAudit',
  ]) || String(evidence.status).toUpperCase() !== 'COMPLETED' || !expected) return false;
  const cohort = evidence.cohort || {};
  const metrics = evidence.metrics || {};
  const requiredMetrics = [
    'providersReceivedFirstOpportunity',
    'providersCompletedFirstPaidJob',
    'percentFirstPaidJobWithin30Days',
    'requestsPublished',
    'requestsWithResponse',
    'requestsCompleted',
    'providerValueGeneratedMzn',
    'returningClients',
    'disputesOpened',
    'disputesResolved',
  ];
  if (!hasExactKeys(cohort, ['providers', 'clients'])
    || !hasExactKeys(metrics, requiredMetrics)
    || !requiredMetrics.every((key) => Number.isFinite(metrics[key]))
    || !realPastTimestamp(evidence.startedAt, expected.nowMs)
    || !realPastTimestamp(evidence.completedAt, expected.nowMs)
    || !realPastTimestamp(evidence.capturedAt, expected.nowMs)) return false;
  const integerMetrics = requiredMetrics.filter((key) => (
    key !== 'percentFirstPaidJobWithin30Days' && key !== 'providerValueGeneratedMzn'
  ));
  const startedAt = Date.parse(evidence.startedAt);
  const completedAt = Date.parse(evidence.completedAt);
  const capturedAt = Date.parse(evidence.capturedAt);
  const duration = completedAt - startedAt;
  const expectedPercent = (metrics.providersCompletedFirstPaidJob / cohort.providers) * 100;
  const references = [
    ['cohortReference', 'pilot-cohorts/'],
    ['consentAuditReference', 'pilot-consent/'],
    ['metricsSnapshotReference', 'pilot-metrics/'],
    ['closureReference', 'pilot-closures/'],
  ];
  const referenceValues = references.map(([key]) => evidence[key]);
  const closureDeadline = new Date(completedAt + 24 * 60 * 60 * 1000).toISOString();
  return evidence.schemaVersion === realPilotEvidenceSchema
    && evidence.projectId === expected.projectId
    && evidence.projectNumber === expected.projectNumber
    && evidence.sourceRevision === expected.sourceRevision
    && /^[a-f0-9]{40}$/.test(String(evidence.sourceRevision || ''))
    && evidence.apkSha256 === expected.apkSha256
    && duration >= 30 * 24 * 60 * 60 * 1000
    && duration <= 120 * 24 * 60 * 60 * 1000
    && capturedAt >= completedAt
    && capturedAt <= Date.parse(closureDeadline)
    && Number.isInteger(cohort.providers)
    && Number.isInteger(cohort.clients)
    && cohort.providers > 0
    && cohort.clients > 0
    && integerMetrics.every((key) => Number.isInteger(metrics[key]) && metrics[key] >= 0)
    && metrics.providersReceivedFirstOpportunity > 0
    && metrics.providersReceivedFirstOpportunity <= cohort.providers
    && metrics.providersCompletedFirstPaidJob > 0
    && metrics.providersCompletedFirstPaidJob <= metrics.providersReceivedFirstOpportunity
    && metrics.percentFirstPaidJobWithin30Days > 0
    && metrics.percentFirstPaidJobWithin30Days <= 100
    && Math.abs(metrics.percentFirstPaidJobWithin30Days - expectedPercent) <= 0.01
    && metrics.requestsPublished > 0
    && metrics.requestsWithResponse > 0
    && metrics.requestsWithResponse <= metrics.requestsPublished
    && metrics.requestsCompleted > 0
    && metrics.requestsCompleted <= metrics.requestsWithResponse
    && metrics.requestsPublished >= metrics.providersCompletedFirstPaidJob
    && metrics.requestsCompleted >= metrics.providersCompletedFirstPaidJob
    && metrics.providerValueGeneratedMzn > 0
    && metrics.returningClients <= cohort.clients
    && metrics.disputesOpened <= metrics.requestsPublished
    && metrics.disputesResolved <= metrics.disputesOpened
    && references.every(([key, prefix]) => (
      realEvidenceId(evidence[key]) && evidence[key].startsWith(prefix)
    ))
    && new Set(referenceValues).size === referenceValues.length
    && evidence.participantConsentRecorded === true
    && evidence.aggregatedDataOnly === true
    && evidence.containsParticipantIdentifiers === false
    && evidence.closureApproved === true
    && !containsPiiKeys(evidence)
    && evidence.closureAudit.reviewReference === evidence.metricsSnapshotReference
    && validateAuditReference(evidence.closureAudit, expected, {
      provider: 'chegaja-pilot-audit',
      eventType: 'pilot-closure',
      earliestAt: evidence.capturedAt,
      latestAt: closureDeadline,
      operationReference: evidence.closureReference,
    });
}

function run() {
  const strict = process.argv.includes('--strict');
  const json = process.argv.includes('--json');
  const clientEnv = envValues('.env');
  const functionEnv = {
    ...envValues('functions/.env'),
    ...envValues('functions/.env.local'),
  };
  const functionsSource = read('functions/index.js');
  const p1SourceHashes = collectP1SourceHashes();
  const gradle = read('android/app/build.gradle.kts');
  const packageMatch = gradle.match(/applicationId\s*=\s*"([^"]+)"/);
  const applicationId = packageMatch ? packageMatch[1] : '';
  const namespaceMatch = gradle.match(/namespace\s*=\s*"([^"]+)"/);
  const namespace = namespaceMatch ? namespaceMatch[1] : '';
  const mergedManifest = read(
    'build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml',
  );
  const forbiddenPermissions = [
    'android.permission.RECORD_AUDIO',
    'android.permission.MODIFY_AUDIO_SETTINGS',
    'android.permission.BLUETOOTH_CONNECT',
    'com.google.android.gms.permission.AD_ID',
    'android.permission.ACCESS_ADSERVICES_AD_ID',
  ];
  const apk = verifyReleaseApk();
  const releaseProvenance = readJson(versionedReleaseProvenance);
  const deploymentExpected = {
    projectId: expectedFirebaseProjectId,
    projectNumber: expectedFirebaseProjectNumber,
    sourceRevision: releaseProvenance?.sourceRevision || '',
    apkSha256: apk.digest,
    ...p1SourceHashes,
  };
  const uiEvidence = read(versionedAndroidUi);
  const runtimeLogEvidence = read(versionedAndroidRuntimeLog);
  const emulatorEvidence = readJson('docs/android/p1-8-emulator-validation.json');
  const cutoverEvidence = readJson('docs/pilot/evidence/p1-cutover-migration.json');

  const checks = [];
  function check(id, passed, severity, detail) {
    checks.push({ id, passed: Boolean(passed), severity, detail });
  }

  check('signed_apk', apk.passed && validateReleaseProvenance(releaseProvenance, apk.digest),
    'blocker',
    `APK v2 assinada e ligada aos fontes release atuais; SHA-256: ${apk.digest || 'indisponível'}`);
  check('android_runtime_evidence', exists(versionedAndroidScreenshot)
    && exists(versionedAndroidRuntimeLog)
    && validateAndroidRuntimeEvidence({
      evidence: emulatorEvidence,
      uiEvidence,
      runtimeLogEvidence,
      releaseProvenance,
      apkDigest: apk.digest,
      applicationId,
    }),
  'blocker', 'captura, hierarquia e logcat redigido comprovam o seletor Android em português');
  check('manifest_permissions', mergedManifest
    && forbiddenPermissions.every((permission) => !mergedManifest.includes(permission)),
  'blocker', 'manifesto release não contém áudio, Bluetooth ou identificadores publicitários');
  check('production_package', validateAndroidProductionIdentity({
    applicationId,
    namespace,
    mainActivity: read('android/app/src/main/kotlin/com/chegaja/app/MainActivity.kt'),
    googleServices: readJson('android/app/google-services.json'),
    firebaseOptions: read('lib/firebase_options.dart'),
    firebaseFlutter: readJson('firebase.flutter.json'),
    firebaseLocal: readJson('firebase.local.json'),
    assetLinks: readJson('web/.well-known/assetlinks.json'),
  }), 'blocker', `identidade Android/Firebase/App Links alinhada em ${expectedAndroidPackage}`);
  check('legal_identity', validateLegalIdentity(clientEnv), 'blocker',
    'responsável, tipo, email e endereço jurídicos reais configurados sem expor valores');
  check('deletion_pepper', validateDeletionSecretEvidence(
    readJson('docs/pilot/evidence/firebase-account-deletion-secret.json'), functionsSource,
  ), 'blocker', 'ACCOUNT_DELETION_PEPPER ativo no Secret Manager e ligado à função agendada');
  check('storage_boundaries', validateStorageBoundaryEvidence(
    readJson('docs/security/firebase-storage-boundary-status-2026-07-20.json'),
  ), 'blocker', 'Storage sem tokens privados; perfis públicos separados e quarentena com 30 dias');
  check('p1_source_provenance', validateCutoverMigrationEvidence(
    cutoverEvidence,
    deploymentExpected,
  ), 'blocker', 'cutover real concluído em até 24h, sem deletes/exposição e ligado aos fontes atuais');
  check('pilot_allowlist', functionEnv.PILOT_REQUIRE_ALLOWLIST !== 'false'
    && read('functions/index.js').includes("envFlagEnabled('PILOT_REQUIRE_ALLOWLIST', !useEmulators)"),
  'blocker', 'allowlist obrigatória por defeito e não desativada no ambiente de deploy');
  check('risk_features_off', [
    'ENABLE_KYC', 'ENABLE_STRIPE', 'ENABLE_STORIES', 'ENABLE_CALLS', 'ENABLE_SUBSCRIPTIONS',
  ].every((key) => clientEnv[key] !== 'true'), 'blocker',
  'KYC, Stripe, stories, chamadas e subscrições não ativados no cliente');
  check('legal_review', validateLegalApproval(read('docs/pilot/evidence/legal-approval.md')),
    'blocker', 'aprovação jurídica estruturada, versionada e referenciada');
  check('app_check_enforcement', validateAppCheckEvidence(
    readJson('docs/pilot/evidence/firebase-app-check-enforcement.json'),
    {
      ...deploymentExpected,
      cutoverEvidence,
    },
  ), 'blocker', 'App Check ligado exatamente à migração e ao deploy da mesma janela de cutover');
  check('physical_android', validatePhysicalEvidence(
    readJson('docs/pilot/evidence/android-physical-validation.json'), deploymentExpected,
  ), 'blocker', 'matriz de 12 casos aprovada em Android físico API 33+ para esta APK');
  check('real_pilot_execution', validateRealPilotEvidence(
    readJson('docs/pilot/evidence/real-pilot-execution.json'), deploymentExpected,
  ), 'blocker', 'piloto real concluído com consentimento e métricas apenas agregadas');
  check('runbooks', [
    'docs/pilot/maputo-pilot-runbook.md',
    'docs/pilot/kpi-dictionary.md',
    'docs/pilot/incident-playbook.md',
    'docs/legal/data-retention-and-deletion.md',
  ].every(exists), 'blocker', 'runbooks operacionais obrigatórios existem');

  const blockers = checks.filter((item) => !item.passed && item.severity === 'blocker');
  const result = {
    generatedAt: new Date().toISOString(),
    apkSha256: apk.digest,
    readyForExternalPilot: blockers.length === 0,
    passed: checks.filter((item) => item.passed).length,
    total: checks.length,
    checks,
  };

  if (json) console.log(JSON.stringify(result, null, 2));
  else {
    console.log(`# P1 pilot readiness: ${result.readyForExternalPilot ? 'READY' : 'NOT READY'}`);
    checks.forEach((item) => console.log(`${item.passed ? 'PASS' : 'FAIL'} ${item.id}: ${item.detail}`));
  }
  if (strict && blockers.length > 0) process.exitCode = 2;
  return result;
}

if (require.main === module) run();

module.exports = {
  canonicalJson,
  containsPiiKeys,
  requiredPhysicalCases,
  validateAndroidRuntimeEvidence,
  validateAndroidProductionIdentity,
  validateAppCheckEvidence,
  validateCutoverMigrationEvidence,
  validateFirestoreIndexDeployment,
  validateDeletionSecretEvidence,
  validateLegalApproval,
  validateLegalIdentity,
  validatePhysicalEvidence,
  validatePreparationSourceEvidence,
  validateRealPilotEvidence,
  validateReleaseProvenance,
  validateStorageBoundaryEvidence,
};
