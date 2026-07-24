const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const {
  buildAttestationSchema,
  collectReleaseInputs,
  collectVirtualReleaseInputs,
  releaseInputSchema,
  releaseSourceFingerprint,
} = require('../qa/release_source_fingerprint');

const {
  canonicalJson,
  containsPiiKeys,
  requiredPhysicalCases,
  validateAndroidRuntimeEvidence,
  validateAndroidProductionIdentity,
  validateAppCheckEvidence,
  validateCutoverMigrationEvidence,
  validateDeletionSecretEvidence,
  validateFirestoreIndexDeployment,
  validateLegalApproval,
  validateLegalIdentity,
  validatePhysicalEvidence,
  validatePreparationSourceEvidence,
  validateRealPilotEvidence,
  validateReleaseProvenance,
  validateStorageBoundaryEvidence,
} = require('../qa/p1_pilot_readiness');

const digest = 'a'.repeat(64);
const sourceRevision = '9'.repeat(40);
const nowMs = Date.parse('2026-07-21T12:00:00.000Z');
const auditArtifacts = {};
const firestoreIndexesBytes = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.indexes.json'),
);
const firestoreIndexesManifest = JSON.parse(firestoreIndexesBytes.toString('utf8'));
const firestoreIndexesSha256 = crypto
  .createHash('sha256')
  .update(firestoreIndexesBytes)
  .digest('hex');

function sha256(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

function auditFixture({
  artifactPath,
  provider,
  logReference,
  eventType,
  occurredAt,
  capturedAt,
  operationReference,
  reviewReference,
}) {
  const artifact = {
    schemaVersion: 'p1-provider-audit-v1',
    projectId: 'chegaja-ac88d',
    projectNumber: '767588494857',
    sourceRevision,
    eventType,
    occurredAt,
    providerReference: logReference,
    operationReference,
    result: 'SUCCESS',
    redacted: true,
    containsParticipantIdentifiers: false,
  };
  const content = JSON.stringify(artifact, null, 2);
  auditArtifacts[artifactPath] = content;
  return {
    schemaVersion: 'p1-audit-reference-v1',
    provider,
    logReference,
    capturedAt,
    artifactPath,
    artifactSha256: sha256(content),
    reviewReference,
    redacted: true,
    containsParticipantIdentifiers: false,
  };
}

const sourceHashes = {
  hashAlgorithm: 'sha256-canonical-text-v1',
  functionsRuntimeSchema: 'functions-runtime-js-v2',
  functionsRuntimeFileCount: 7,
  firestoreRulesSha256: 'b'.repeat(64),
  storageRulesSha256: 'c'.repeat(64),
  functionsIndexSha256: 'd'.repeat(64),
  functionsRuntimeSourceFingerprintSha256: '2'.repeat(64),
  functionsPackageSha256: 'e'.repeat(64),
  functionsPackageLockSha256: 'f'.repeat(64),
  functionsDeployFingerprintSha256: '1'.repeat(64),
};
const deployedHashes = {
  projectId: 'chegaja-ac88d',
  projectNumber: '767588494857',
  sourceRevision,
  nowMs,
  auditArtifacts,
  apkSha256: digest,
  ...sourceHashes,
};

const preparationEvidence = {
  capturedAt: '2026-07-20T08:00:00.000Z',
  projectId: 'chegaja-ac88d',
  containsParticipantIdentifiers: false,
  additiveMigration: { rerunRequiredImmediatelyBeforeCutover: true },
  localArtifactHashes: { ...sourceHashes },
};

assert.strictEqual(validatePreparationSourceEvidence(
  preparationEvidence,
  deployedHashes,
), true);
assert.strictEqual(validatePreparationSourceEvidence({
  ...preparationEvidence,
  localArtifactHashes: {
    ...preparationEvidence.localArtifactHashes,
    firestoreRulesSha256: '0'.repeat(64),
  },
}, deployedHashes), false);

const backendConfigManifest = {
  schemaVersion: 'p1-effective-backend-config-v1',
  projectId: 'chegaja-ac88d',
  projectNumber: '767588494857',
  sourceRevision,
  capturedAt: '2026-07-20T07:35:00.000Z',
  environment: 'production',
  pilotRequireAllowlist: true,
  riskFlags: {
    ENABLE_KYC: false,
    ENABLE_STRIPE: false,
    STRIPE_MZN_VALIDATED: false,
    ENABLE_MPESA: false,
    ENABLE_EMOLA: false,
  },
  configVersions: {
    functionsEnvironment: 'projects/chegaja-ac88d/locations/europe-west1/services/chegaja/revisions/functions-00042',
    pilotPolicy: 'pilot-policies/maputo-controlled-v3',
  },
  secretVersions: [
    { secret: 'ACCOUNT_DELETION_PEPPER', versionId: '2', state: 'ENABLED' },
    { secret: 'GOOGLE_MAPS_API_KEY', versionId: '4', state: 'ENABLED' },
    { secret: 'GOOGLE_PLACES_API_KEY', versionId: '3', state: 'ENABLED' },
  ],
  redacted: true,
  containsSecretValues: false,
  containsParticipantIdentifiers: false,
};
const backendConfigManifestSha256 = sha256(canonicalJson(backendConfigManifest));
const deploymentReference = 'firebase-deploy-2026-001';
const deploymentAudit = auditFixture({
  artifactPath: 'docs/pilot/evidence/audits/cutover-2026-001.json',
  provider: 'google-cloud-audit-logs',
  logReference: 'projects/chegaja-ac88d/logs/cloudaudit.googleapis.com%2Factivity/entries/deploy-2026-001',
  eventType: 'firebase-deployment',
  occurredAt: '2026-07-20T07:46:00.000Z',
  capturedAt: '2026-07-20T07:47:00.000Z',
  operationReference: deploymentReference,
  reviewReference: 'reviews/cutover-2026-001',
});
const readyFirestoreIndexes = firestoreIndexesManifest.indexes.map((index) => ({
  ...index,
  fields: index.fields.map((field) => ({ ...field })),
  state: 'READY',
}));
const readyFirestoreFieldOverrides = firestoreIndexesManifest.fieldOverrides.map(
  (fieldOverride) => ({
    ...fieldOverride,
    indexes: fieldOverride.indexes.map((index) => ({ ...index })),
    state: 'READY',
  }),
);
const providerGrantIndex = readyFirestoreIndexes.find((index) => (
  index.collectionGroup === 'pedidos'
    && index.fields.some(({ fieldPath }) => fieldPath === 'providerAccessGrantedAt')
));
assert.ok(providerGrantIndex, 'the committed manifest must contain the provider grant index');
const firestoreIndexCloudArtifactPath =
  'docs/pilot/evidence/audits/firestore-indexes-2026-001.json';
const firestoreIndexCloudArtifact = {
  schemaVersion: 'firestore-index-cloud-output-v2',
  projectId: 'chegaja-ac88d',
  checkedAt: '2026-07-20T07:48:00.000Z',
  sourceCommands: [
    'gcloud firestore indexes composite list --project=chegaja-ac88d --format=json',
    'gcloud firestore fields list --project=chegaja-ac88d --format=json',
  ],
  redacted: true,
  containsParticipantIdentifiers: false,
  indexes: readyFirestoreIndexes,
  fieldOverrides: readyFirestoreFieldOverrides,
};
const firestoreIndexCloudArtifactContent = JSON.stringify(
  firestoreIndexCloudArtifact,
  null,
  2,
);
auditArtifacts[firestoreIndexCloudArtifactPath] = firestoreIndexCloudArtifactContent;
const firestoreIndexDeployment = {
  schemaVersion: 'firestore-index-deployment-v3',
  projectId: 'chegaja-ac88d',
  checkedAt: '2026-07-20T07:48:00.000Z',
  manifestSha256: firestoreIndexesSha256,
  allDeclaredIndexesReady: true,
  allDeclaredFieldOverridesReady: true,
  cloudOutputArtifactPath: firestoreIndexCloudArtifactPath,
  cloudOutputArtifactSha256: sha256(firestoreIndexCloudArtifactContent),
  declaredIndexes: readyFirestoreIndexes,
  declaredFieldOverrides: readyFirestoreFieldOverrides,
};

const cutoverEvidence = {
  schemaVersion: 'p1-deployment-evidence-v4',
  status: 'COMPLETED',
  dryRun: false,
  projectId: 'chegaja-ac88d',
  projectNumber: '767588494857',
  sourceRevision,
  cutoverWindowId: 'cutover-2026-07-20-001',
  cutoverReference: 'change-request-2026-001',
  migrationExecutionReference: 'migration-run-2026-001',
  deploymentReference,
  writesFrozenAt: '2026-07-20T07:00:00.000Z',
  migrationStartedAt: '2026-07-20T07:05:00.000Z',
  migrationCompletedAt: '2026-07-20T07:30:00.000Z',
  migrationRerunAt: '2026-07-20T07:30:00.000Z',
  capturedAt: '2026-07-20T07:31:00.000Z',
  deploymentCompletedAt: '2026-07-20T07:45:00.000Z',
  containsParticipantIdentifiers: false,
  additiveMigration: {
    executed: true,
    deletesPerformed: 0,
    publicDocumentsWithForbiddenSensitiveFieldNames: 0,
  },
  pedidoGrantReconciliation: {
    schemaVersion: 'pedido-grant-reconciliation-v1',
    executed: true,
    dryRun: false,
    scanned: 29,
    collectionTotalObserved: 29,
    backfilled: 7,
    revoked: 4,
    unchanged: 18,
    manualReview: 0,
    inconsistentAfter: 0,
    deletesPerformed: 0,
    executionOutputSha256: '6'.repeat(64),
  },
  pedidoDispatchReconciliation: {
    schemaVersion: 'pedido-dispatch-reconciliation-v1',
    hashAlgorithm: 'sha256-canonical-json-v1',
    executed: true,
    dryRun: false,
    documentIdsIncluded: false,
    scanned: 29,
    collectionTotalObserved: 29,
    dispatchScanned: 20,
    eligibleOpen: 10,
    eligibleTargeted: 5,
    upserted: 4,
    deletedTerminalOrStale: 2,
    deletedOrphan: 1,
    unchanged: 11,
    inconsistentBefore: 7,
    inconsistentAfter: 0,
    executionOutputSha256: '7'.repeat(64),
  },
  storageBoundaryMigration: {
    executed: true,
    objectsDeleted: 0,
    restrictedObjectsWithPersistentDownloadTokens: 0,
    nonPublicObjectsWithPersistentDownloadTokens: 0,
  },
  backendConfigManifest,
  backendConfigManifestSha256,
  deploymentAudit,
  firestoreIndexDeployment,
  deployedArtifacts: { ...sourceHashes },
};

assert.strictEqual(validateCutoverMigrationEvidence(cutoverEvidence, deployedHashes), true);
assert.strictEqual(validateFirestoreIndexDeployment(
  firestoreIndexDeployment,
  deployedHashes,
  {
    earliestAt: cutoverEvidence.deploymentCompletedAt,
    latestAt: '2026-07-21T07:00:00.000Z',
  },
), true);
assert.strictEqual(validateFirestoreIndexDeployment({
  ...firestoreIndexDeployment,
  declaredIndexes: [providerGrantIndex],
}, deployedHashes, {
  earliestAt: cutoverEvidence.deploymentCompletedAt,
  latestAt: '2026-07-21T07:00:00.000Z',
}), false);
assert.strictEqual(validateFirestoreIndexDeployment({
  ...firestoreIndexDeployment,
  declaredIndexes: readyFirestoreIndexes.slice(0, -1),
}, deployedHashes, {
  earliestAt: cutoverEvidence.deploymentCompletedAt,
  latestAt: '2026-07-21T07:00:00.000Z',
}), false);
assert.strictEqual(validateFirestoreIndexDeployment({
  ...firestoreIndexDeployment,
  declaredIndexes: [...readyFirestoreIndexes, readyFirestoreIndexes[0]],
}, deployedHashes, {
  earliestAt: cutoverEvidence.deploymentCompletedAt,
  latestAt: '2026-07-21T07:00:00.000Z',
}), false);
assert.strictEqual(validateFirestoreIndexDeployment({
  ...firestoreIndexDeployment,
  declaredIndexes: [...readyFirestoreIndexes, {
    collectionGroup: 'unexpected_collection',
    queryScope: 'COLLECTION',
    fields: [{ fieldPath: 'status', order: 'ASCENDING' }],
    state: 'READY',
  }],
}, deployedHashes, {
  earliestAt: cutoverEvidence.deploymentCompletedAt,
  latestAt: '2026-07-21T07:00:00.000Z',
}), false);
assert.strictEqual(validateFirestoreIndexDeployment({
  ...firestoreIndexDeployment,
  declaredFieldOverrides: readyFirestoreFieldOverrides.slice(0, -1),
}, deployedHashes, {
  earliestAt: cutoverEvidence.deploymentCompletedAt,
  latestAt: '2026-07-21T07:00:00.000Z',
}), false);
assert.strictEqual(validateFirestoreIndexDeployment({
  ...firestoreIndexDeployment,
  declaredFieldOverrides: [
    ...readyFirestoreFieldOverrides,
    readyFirestoreFieldOverrides[0],
  ],
}, deployedHashes, {
  earliestAt: cutoverEvidence.deploymentCompletedAt,
  latestAt: '2026-07-21T07:00:00.000Z',
}), false);
assert.strictEqual(validateFirestoreIndexDeployment({
  ...firestoreIndexDeployment,
  cloudOutputArtifactSha256: '0'.repeat(64),
}, deployedHashes, {
  earliestAt: cutoverEvidence.deploymentCompletedAt,
  latestAt: '2026-07-21T07:00:00.000Z',
}), false);
assert.strictEqual(validateFirestoreIndexDeployment(
  firestoreIndexDeployment,
  { ...deployedHashes, auditArtifacts: {} },
  {
    earliestAt: cutoverEvidence.deploymentCompletedAt,
    latestAt: '2026-07-21T07:00:00.000Z',
  },
), false);

function validateIndexDeploymentWithCloudArtifact(artifact) {
  const content = JSON.stringify(artifact, null, 2);
  return validateFirestoreIndexDeployment({
    ...firestoreIndexDeployment,
    cloudOutputArtifactSha256: sha256(content),
  }, {
    ...deployedHashes,
    auditArtifacts: {
      ...auditArtifacts,
      [firestoreIndexCloudArtifactPath]: content,
    },
  }, {
    earliestAt: cutoverEvidence.deploymentCompletedAt,
    latestAt: '2026-07-21T07:00:00.000Z',
  });
}

assert.strictEqual(validateIndexDeploymentWithCloudArtifact({
  ...firestoreIndexCloudArtifact,
  projectId: 'another-project',
}), false);
assert.strictEqual(validateIndexDeploymentWithCloudArtifact({
  ...firestoreIndexCloudArtifact,
  checkedAt: '2026-07-20T07:49:00.000Z',
}), false);
assert.strictEqual(validateIndexDeploymentWithCloudArtifact({
  ...firestoreIndexCloudArtifact,
  indexes: firestoreIndexCloudArtifact.indexes.map((index, position) => (
    position === 0 ? { ...index, state: 'BUILDING' } : index
  )),
}), false);
assert.strictEqual(validateIndexDeploymentWithCloudArtifact({
  ...firestoreIndexCloudArtifact,
  indexes: firestoreIndexCloudArtifact.indexes.slice(1),
}), false);
assert.strictEqual(validateIndexDeploymentWithCloudArtifact({
  ...firestoreIndexCloudArtifact,
  fieldOverrides: firestoreIndexCloudArtifact.fieldOverrides.slice(1),
}), false);
assert.strictEqual(validateIndexDeploymentWithCloudArtifact({
  ...firestoreIndexCloudArtifact,
  operatorEmail: 'hidden@example.com',
}), false);
assert.strictEqual(validateCutoverMigrationEvidence(null, deployedHashes), false);
const { firestoreIndexDeployment: _omittedIndexProof, ...cutoverWithoutIndexProof } = cutoverEvidence;
assert.strictEqual(validateCutoverMigrationEvidence(
  cutoverWithoutIndexProof,
  deployedHashes,
), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  status: 'PENDING',
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  dryRun: true,
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  cutoverWindowId: 'example-cutover-window',
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  additiveMigration: { ...cutoverEvidence.additiveMigration, deletesPerformed: 1 },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  pedidoGrantReconciliation: {
    ...cutoverEvidence.pedidoGrantReconciliation,
    manualReview: 1,
    unchanged: 17,
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  pedidoDispatchReconciliation: {
    ...cutoverEvidence.pedidoDispatchReconciliation,
    inconsistentAfter: 1,
  },
}, deployedHashes), false);
const {
  pedidoDispatchReconciliation: _omittedDispatchReconciliation,
  ...cutoverWithoutDispatchReconciliation
} = cutoverEvidence;
assert.strictEqual(validateCutoverMigrationEvidence(
  cutoverWithoutDispatchReconciliation,
  deployedHashes,
), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  pedidoGrantReconciliation: {
    ...cutoverEvidence.pedidoGrantReconciliation,
    scanned: 0,
    collectionTotalObserved: 0,
    backfilled: 0,
    revoked: 0,
    unchanged: 0,
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  pedidoGrantReconciliation: {
    ...cutoverEvidence.pedidoGrantReconciliation,
    collectionTotalObserved: 30,
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  pedidoGrantReconciliation: {
    ...cutoverEvidence.pedidoGrantReconciliation,
    executionOutputSha256: 'not-a-sha256',
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  firestoreIndexDeployment: {
    ...firestoreIndexDeployment,
    manifestSha256: '0'.repeat(64),
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  firestoreIndexDeployment: {
    ...firestoreIndexDeployment,
    declaredIndexes: readyFirestoreIndexes.map((index) => (
      index === providerGrantIndex ? { ...index, state: 'BUILDING' } : index
    )),
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  firestoreIndexDeployment: {
    ...firestoreIndexDeployment,
    declaredIndexes: readyFirestoreIndexes.filter((index) => index !== providerGrantIndex),
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  firestoreIndexDeployment: {
    ...firestoreIndexDeployment,
    declaredIndexes: [...readyFirestoreIndexes, readyFirestoreIndexes[0]],
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  pedidoGrantReconciliation: {
    ...cutoverEvidence.pedidoGrantReconciliation,
    inconsistentAfter: 1,
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  additiveMigration: {
    ...cutoverEvidence.additiveMigration,
    publicDocumentsWithForbiddenSensitiveFieldNames: 1,
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  storageBoundaryMigration: {
    ...cutoverEvidence.storageBoundaryMigration,
    restrictedObjectsWithPersistentDownloadTokens: 1,
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  storageBoundaryMigration: {
    ...cutoverEvidence.storageBoundaryMigration,
    objectsDeleted: null,
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  migrationStartedAt: '2026-07-20T07:35:00.000Z',
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  deployedArtifacts: {
    ...cutoverEvidence.deployedArtifacts,
    functionsRuntimeFileCount: '7',
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  deployedArtifacts: { ...sourceHashes, unexpectedField: 'not-allowed' },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  deployedArtifacts: {
    ...cutoverEvidence.deployedArtifacts,
    storageRulesSha256: '0'.repeat(64),
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  sourceRevision: '8'.repeat(40),
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  operatorPhone: '+258000000000',
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  backendConfigManifest: {
    ...backendConfigManifest,
    riskFlags: { ...backendConfigManifest.riskFlags, ENABLE_KYC: true },
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  backendConfigManifest: {
    ...backendConfigManifest,
    secretVersions: backendConfigManifest.secretVersions.map((secret, index) => (
      index === 0 ? { ...secret, value: 'must-never-be-accepted' } : secret
    )),
  },
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  backendConfigManifestSha256: '0'.repeat(64),
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  deploymentAudit: { ...deploymentAudit, artifactSha256: '0'.repeat(64) },
}, deployedHashes), false);
const cutoverAuditWithPii = JSON.stringify({
  ...JSON.parse(auditArtifacts[deploymentAudit.artifactPath]),
  operatorEmail: 'hidden@example.com',
});
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  deploymentAudit: {
    ...deploymentAudit,
    artifactSha256: sha256(cutoverAuditWithPii),
  },
}, {
  ...deployedHashes,
  auditArtifacts: {
    ...auditArtifacts,
    [deploymentAudit.artifactPath]: cutoverAuditWithPii,
  },
}), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  writesFrozenAt: cutoverEvidence.migrationStartedAt,
}, deployedHashes), false);
assert.strictEqual(validateCutoverMigrationEvidence({
  ...cutoverEvidence,
  deploymentCompletedAt: '2026-07-22T07:45:00.000Z',
}, deployedHashes), false);

const androidIdentity = {
  applicationId: 'com.chegaja.app',
  namespace: 'com.chegaja.app',
  mainActivity: 'package com.chegaja.app',
  googleServices: {
    client: [{
      client_info: {
        mobilesdk_app_id: '1:767588494857:android:4198384a2a6387055252d8',
        android_client_info: { package_name: 'com.chegaja.app' },
      },
    }],
  },
  firebaseOptions: "appId: '1:767588494857:android:4198384a2a6387055252d8'",
  firebaseFlutter: {
    flutter: { platforms: {
      android: { default: { appId: '1:767588494857:android:4198384a2a6387055252d8' } },
      dart: { 'lib/firebase_options.dart': { configurations: {
        android: '1:767588494857:android:4198384a2a6387055252d8',
      } } },
    } },
  },
  firebaseLocal: {
    flutter: { platforms: {
      android: { default: { appId: '1:767588494857:android:4198384a2a6387055252d8' } },
      dart: { 'lib/firebase_options.dart': { configurations: {
        android: '1:767588494857:android:4198384a2a6387055252d8',
      } } },
    } },
  },
  assetLinks: [{
    target: {
      namespace: 'android_app',
      package_name: 'com.chegaja.app',
      sha256_cert_fingerprints: [
        '13:36:FF:14:C1:DD:F0:94:40:38:7B:BD:F9:F4:8D:5A:09:60:2A:87:D1:06:2A:E6:FC:E2:A5:07:2B:AC:1F:81',
      ],
    },
  }],
};

assert.strictEqual(validateAndroidProductionIdentity(androidIdentity), true);
assert.strictEqual(validateAndroidProductionIdentity({
  ...androidIdentity,
  applicationId: 'com.example.chegaja_v2',
}), false);

assert.strictEqual(validateReleaseProvenance(null, digest), false);
const releaseInputs = collectReleaseInputs();
const releaseVirtualInputs = collectVirtualReleaseInputs();
const releaseProvenance = {
  attestationSchema: buildAttestationSchema,
  fingerprintSchema: releaseInputSchema,
  generatedAt: '2026-07-20T09:00:00.000Z',
  apkSha256: digest,
  releaseSourceFingerprint: releaseSourceFingerprint(
    releaseInputs,
    releaseVirtualInputs,
  ),
  preBuildSourceFingerprint: releaseSourceFingerprint(
    releaseInputs,
    releaseVirtualInputs,
  ),
  postBuildSourceFingerprint: releaseSourceFingerprint(
    releaseInputs,
    releaseVirtualInputs,
  ),
  sourceStableDuringBuild: true,
  sourceRevision,
  sourceTreeClean: true,
  preBuildCapturedAt: '2026-07-20T08:55:00.000Z',
  postBuildCapturedAt: '2026-07-20T09:00:00.000Z',
  releaseInputFiles: releaseInputs.length,
  releaseVirtualInputs: releaseVirtualInputs.length,
  generatedRegistrantExcluded: true,
  localPathsSerialized: false,
  secretValuesSerialized: false,
};
assert.strictEqual(validateReleaseProvenance(releaseProvenance, digest), true);
assert.strictEqual(validateReleaseProvenance({
  generatedAt: '2026-07-20T09:00:00.000Z',
  apkSha256: digest,
  releaseSourceFingerprint: 'wrong',
  releaseInputFiles: 1,
  generatedRegistrantExcluded: true,
}, digest), false);
assert.strictEqual(validateReleaseProvenance({
  ...releaseProvenance,
  postBuildSourceFingerprint: '0'.repeat(64),
  sourceStableDuringBuild: false,
}, digest), false);
assert.strictEqual(validateReleaseProvenance({
  ...releaseProvenance,
  sourceRevision: 'not-a-git-revision',
}, digest), false);
assert.strictEqual(validateReleaseProvenance({
  ...releaseProvenance,
  sourceTreeClean: false,
}, digest), false);

const runtimeUiEvidence = `
<hierarchy>
  <node package="com.chegaja.app" content-desc="Bem-vindo ao ChegaJá" />
  <node package="com.chegaja.app" content-desc="Sou cliente" />
  <node package="com.chegaja.app" content-desc="Sou prestador" />
</hierarchy>`;
const runtimeLogEvidence = [
  'ChegaJa Android runtime validation',
  'Package com.chegaja.app remained alive after selector interaction.',
  'No package-level crash was observed.',
  '',
].join('\n');
const runtimeEvidence = {
  status: 'COMPLETED',
  capturedAt: '2026-07-20T10:00:00.000Z',
  apkSha256: digest,
  fingerprintSchema: releaseInputSchema,
  releaseSourceFingerprint: releaseProvenance.releaseSourceFingerprint,
  releaseInputFiles: releaseProvenance.releaseInputFiles,
  releaseVirtualInputs: releaseProvenance.releaseVirtualInputs,
  packageId: 'com.chegaja.app',
  activity: 'com.chegaja.app/.MainActivity',
  activityInForeground: true,
  processAliveAfterInteraction: true,
  device: {
    physical: false,
    manufacturer: 'Google',
    model: 'sdk_gphone64_x86_64',
    androidVersion: '15',
    apiLevel: 35,
    abi: 'x86_64',
    avdName: 'chegaja_u0_api35',
    buildFingerprint: 'google/sdk_gphone64_x86_64/test:userdebug/dev-keys',
    bootCompleted: true,
  },
  screen: {
    physicalSize: '1080x2400',
    title: 'Bem-vindo ao ChegaJá',
    clientAction: 'Sou cliente',
    providerAction: 'Sou prestador',
  },
  startupPermissionPrompt: false,
  interactionCheck: 'vertical_scroll_without_navigation',
  fatalMatchPolicy: 'Only fatal package crashes are classified as matches.',
  fatalPatternsChecked: ['FATAL EXCEPTION', 'ANR in com.chegaja.app'],
  fatalPatternsMatched: [],
  runtimeLogSha256: sha256(runtimeLogEvidence),
  nonFatalDiagnostics: [{
    pattern: 'E/FlutterGeolocator',
    count: 2,
    level: 'ERROR_TAG',
    classification: 'Lifecycle diagnostic without a package crash.',
  }],
  environmentDiagnostics: ['Offline emulator completed the selector flow.'],
  artifacts: [
    'docs/android/evidence/u0-2026-07-21/p1_8_launch.png',
    'docs/android/evidence/u0-2026-07-21/p1_8_ui.xml',
    'docs/android/evidence/u0-2026-07-21/p1_8_runtime_redacted.log',
    'docs/android/evidence/u0-2026-07-21/p1_release_provenance.json',
  ],
};
const runtimeValidation = (evidence, overrides = {}) => validateAndroidRuntimeEvidence({
  evidence,
  uiEvidence: runtimeUiEvidence,
  runtimeLogEvidence,
  releaseProvenance,
  apkDigest: digest,
  ...overrides,
});

assert.strictEqual(runtimeValidation(runtimeEvidence), true);
assert.strictEqual(runtimeValidation({ ...runtimeEvidence, apkSha256: 'b'.repeat(64) }), false);
assert.strictEqual(runtimeValidation({
  ...runtimeEvidence,
  releaseSourceFingerprint: 'c'.repeat(64),
}), false);
assert.strictEqual(runtimeValidation({
  ...runtimeEvidence,
  capturedAt: '2026-07-20T08:59:59.000Z',
}), false);
assert.strictEqual(runtimeValidation({ ...runtimeEvidence, packageId: 'com.example.app' }), false);
assert.strictEqual(runtimeValidation({
  ...runtimeEvidence,
  device: { ...runtimeEvidence.device, physical: true },
}), false);
assert.strictEqual(runtimeValidation({
  ...runtimeEvidence,
  device: { ...runtimeEvidence.device, apiLevel: 32 },
}), false);
assert.strictEqual(runtimeValidation({
  ...runtimeEvidence,
  processAliveAfterInteraction: false,
}), false);
assert.strictEqual(runtimeValidation({
  ...runtimeEvidence,
  runtimeLogSha256: '0'.repeat(64),
}), false);
assert.strictEqual(runtimeValidation(runtimeEvidence, {
  runtimeLogEvidence: `${runtimeLogEvidence}FATAL EXCEPTION\n`,
}), false);
assert.strictEqual(runtimeValidation({
  ...runtimeEvidence,
  artifacts: [
    'build/p1_8_launch.png',
    'build/p1_8_ui.xml',
    'build/p1_8_runtime_redacted.log',
    'build/p1_release_provenance.json',
  ],
}), false);
assert.strictEqual(runtimeValidation(runtimeEvidence, {
  uiEvidence: runtimeUiEvidence.replace('Sou prestador', 'Prestador'),
}), false);

assert.strictEqual(validateLegalApproval(`
status: APPROVED
legal_entity: ChegaJá Sociedade, Lda.
reviewer: Revisora Legal
reviewed_at: 2026-07-20
document_version: legal-2026-07-20-pilot-v3
approval_reference: parecer-2026-001
`), true);
assert.strictEqual(validateLegalApproval(`
status: APPROVED
legal_entity: TODO
reviewer: TODO
reviewed_at: 2026-07-20
document_version: legal-2026-07-20-pilot-v3
approval_reference: TODO
`), false);

assert.strictEqual(validateLegalIdentity({
  LEGAL_ENTITY_NAME: 'Filipe Bento Jamal',
  LEGAL_ENTITY_TYPE: 'individual_project_promoter',
  LEGAL_CONTACT_EMAIL: 'privacidade@chegaja.app',
  LEGAL_CONTACT_ADDRESS: 'Avenida e número confirmados, Maputo, Moçambique',
}), true);
assert.strictEqual(validateLegalIdentity({
  LEGAL_ENTITY_NAME: 'Filipe Bento Jamal',
  LEGAL_ENTITY_TYPE: 'individual_project_promoter',
  LEGAL_CONTACT_EMAIL: '',
  LEGAL_CONTACT_ADDRESS: '',
}), false);
assert.strictEqual(validateLegalIdentity({
  LEGAL_ENTITY_NAME: 'ChegaJá - piloto controlado',
  LEGAL_ENTITY_TYPE: 'individual_project_promoter',
  LEGAL_CONTACT_EMAIL: 'privacidade@chegaja.app',
  LEGAL_CONTACT_ADDRESS: 'Maputo, Moçambique',
}), false);

const enforcementReference = 'appcheck-enforcement-2026-001';
const enforcementAudit = auditFixture({
  artifactPath: 'docs/pilot/evidence/audits/appcheck-2026-001.json',
  provider: 'google-cloud-audit-logs',
  logReference: 'projects/chegaja-ac88d/logs/cloudaudit.googleapis.com%2Factivity/entries/appcheck-2026-001',
  eventType: 'app-check-enforcement',
  occurredAt: '2026-07-20T08:01:00.000Z',
  capturedAt: '2026-07-20T08:02:00.000Z',
  operationReference: enforcementReference,
  reviewReference: 'reviews/appcheck-2026-001',
});
const appCheckEvidence = {
  schemaVersion: 'p1-deployment-evidence-v4',
  projectId: 'chegaja-ac88d',
  projectNumber: '767588494857',
  sourceRevision,
  capturedAt: '2026-07-20T08:00:00.000Z',
  cutoverWindowId: cutoverEvidence.cutoverWindowId,
  cutoverReference: cutoverEvidence.cutoverReference,
  migrationExecutionReference: cutoverEvidence.migrationExecutionReference,
  migrationRerunAt: cutoverEvidence.migrationRerunAt,
  deploymentCompletedAt: cutoverEvidence.deploymentCompletedAt,
  apkSha256: digest,
  services: {
    firestore: 'ENFORCED',
    storage: 'ENFORCED',
    authentication: 'ENFORCED',
  },
  functionsCallablesEnforceAppCheck: true,
  deploymentReference: cutoverEvidence.deploymentReference,
  enforcementReference,
  backendConfigManifestSha256,
  enforcementAudit,
  deployedArtifacts: { ...sourceHashes },
};
const appCheckExpected = { ...deployedHashes, cutoverEvidence };

assert.strictEqual(validateAppCheckEvidence(appCheckEvidence, appCheckExpected), true);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  services: { ...appCheckEvidence.services, firestore: 'UNENFORCED' },
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  deploymentReference: 'TODO',
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  cutoverWindowId: 'different-cutover',
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  cutoverReference: 'different-reference',
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  migrationExecutionReference: 'different-migration',
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  migrationRerunAt: '2026-07-20T07:31:00.000Z',
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  deploymentCompletedAt: '2026-07-20T07:46:00.000Z',
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  capturedAt: '2026-07-21T07:00:00.001Z',
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  deployedArtifacts: {
    ...sourceHashes,
    firestoreRulesSha256: '0'.repeat(64),
  },
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  sourceRevision: '7'.repeat(40),
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  backendConfigManifestSha256: '0'.repeat(64),
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  enforcementAudit: { ...enforcementAudit, logReference: 'self-declared-reference' },
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence({
  ...appCheckEvidence,
  participantEmail: 'hidden@example.com',
}, appCheckExpected), false);
assert.strictEqual(validateAppCheckEvidence(appCheckEvidence, deployedHashes), false);

assert.strictEqual(validateDeletionSecretEvidence({
  capturedAt: '2026-07-20T08:17:10.000Z',
  projectId: 'chegaja-ac88d',
  projectNumber: '767588494857',
  secretName: 'ACCOUNT_DELETION_PEPPER',
  activeVersion: {
    versionId: '2',
    createTime: '2026-07-20T08:17:03.048970Z',
    state: 'ENABLED',
  },
  secretValueStoredInRepository: false,
}, "defineSecret('ACCOUNT_DELETION_PEPPER')\nsecrets: [ACCOUNT_DELETION_PEPPER]"), true);
assert.strictEqual(validateDeletionSecretEvidence({
  capturedAt: '2026-07-20T08:17:10.000Z',
  projectId: 'chegaja-ac88d',
  projectNumber: '767588494857',
  secretName: 'ACCOUNT_DELETION_PEPPER',
  activeVersion: { versionId: '1', createTime: '2026-07-20', state: 'DESTROYED' },
  secretValueStoredInRepository: false,
}, "defineSecret('ACCOUNT_DELETION_PEPPER')\nsecrets: [ACCOUNT_DELETION_PEPPER]"), false);

const storageBoundary = {
  capturedAt: '2026-07-20T09:22:34.458Z',
  projectId: 'chegaja-ac88d',
  bucket: 'chegaja-ac88d.firebasestorage.app',
  audit: {
    passed: true,
    restrictedObjectsWithDownloadTokens: 0,
    nonPublicObjectsWithDownloadTokens: 0,
    suspiciousObjectsInPublicPaths: 0,
    disabledStoryObjects: 0,
    unknownObjects: 0,
  },
  quarantineLifecycle: {
    action: 'Delete',
    ageDays: 30,
    matchesPrefix: 'migration_quarantine/',
  },
  temporaryUploadLifecycle: {
    action: 'Delete',
    ageDays: 2,
    matchesPrefix: 'temp/',
  },
  privacySafeOutput: true,
  objectNamesIncluded: false,
};
assert.strictEqual(validateStorageBoundaryEvidence(storageBoundary), true);
assert.strictEqual(validateStorageBoundaryEvidence({
  ...storageBoundary,
  audit: { ...storageBoundary.audit, nonPublicObjectsWithDownloadTokens: 1 },
}), false);

const physicalRunReference = 'android-run-2026-07-20-001';
const physicalAudit = auditFixture({
  artifactPath: 'docs/pilot/evidence/audits/android-physical-2026-001.json',
  provider: 'android-test-run',
  logReference: 'android-test-runs/2026-07-20-001',
  eventType: 'android-physical-validation',
  occurredAt: '2026-07-20T08:30:00.000Z',
  capturedAt: '2026-07-20T08:31:00.000Z',
  operationReference: physicalRunReference,
  reviewReference: 'reviews/android-physical-2026-001',
});
const physical = {
  schemaVersion: 'p1-physical-android-evidence-v2',
  status: 'COMPLETED',
  projectId: 'chegaja-ac88d',
  projectNumber: '767588494857',
  sourceRevision,
  executedAt: '2026-07-20T08:00:00.000Z',
  apkSha256: digest,
  testRunReference: physicalRunReference,
  device: {
    physical: true,
    apiLevel: 34,
    androidVersion: '14',
    manufacturer: 'Samsung',
    model: 'Galaxy A14',
    network: 'Vodafone PT',
  },
  cases: requiredPhysicalCases.map((id) => ({
    id,
    result: 'passed',
    evidenceReference: `android-cases/${id}`,
  })),
  evidenceBundle: physicalAudit,
  logsRedacted: true,
  containsParticipantIdentifiers: false,
};
assert.strictEqual(validatePhysicalEvidence(physical, deployedHashes), true);
assert.strictEqual(validatePhysicalEvidence({
  ...physical,
  apkSha256: 'b'.repeat(64),
}, deployedHashes), false);
assert.strictEqual(validatePhysicalEvidence({
  ...physical,
  cases: physical.cases.slice(1),
}, deployedHashes), false);
assert.strictEqual(validatePhysicalEvidence({
  ...physical,
  cases: physical.cases.map((item, index) => (
    index === 1 ? { ...item, evidenceReference: physical.cases[0].evidenceReference } : item
  )),
}, deployedHashes), false);
assert.strictEqual(validatePhysicalEvidence({
  ...physical,
  deviceSerialNumber: 'sensitive-device-id',
}, deployedHashes), false);
assert.strictEqual(validatePhysicalEvidence({
  ...physical,
  evidenceBundle: { ...physicalAudit, artifactSha256: '0'.repeat(64) },
}, deployedHashes), false);
assert.strictEqual(validatePhysicalEvidence({
  ...physical,
  executedAt: 'not-a-timestamp',
}, deployedHashes), false);

const metricsSnapshotReference = 'pilot-metrics/cohort-2026-001';
const pilotClosureReference = 'pilot-closures/cohort-2026-001';
const pilotClosureAudit = auditFixture({
  artifactPath: 'docs/pilot/evidence/audits/pilot-closure-2026-001.json',
  provider: 'chegaja-pilot-audit',
  logReference: 'pilot-audit/cohort-2026-001/closure',
  eventType: 'pilot-closure',
  occurredAt: '2026-07-01T02:00:00.000Z',
  capturedAt: '2026-07-01T03:00:00.000Z',
  operationReference: pilotClosureReference,
  reviewReference: metricsSnapshotReference,
});
const pilot = {
  schemaVersion: 'p1-real-pilot-evidence-v2',
  status: 'COMPLETED',
  projectId: 'chegaja-ac88d',
  projectNumber: '767588494857',
  sourceRevision,
  startedAt: '2026-06-01T00:00:00.000Z',
  completedAt: '2026-07-01T00:00:00.000Z',
  capturedAt: '2026-07-01T01:00:00.000Z',
  apkSha256: digest,
  cohort: { providers: 10, clients: 12 },
  metrics: {
    providersReceivedFirstOpportunity: 8,
    providersCompletedFirstPaidJob: 6,
    percentFirstPaidJobWithin30Days: 60,
    requestsPublished: 20,
    requestsWithResponse: 17,
    requestsCompleted: 11,
    providerValueGeneratedMzn: 12000,
    returningClients: 3,
    disputesOpened: 1,
    disputesResolved: 1,
  },
  cohortReference: 'pilot-cohorts/cohort-2026-001',
  consentAuditReference: 'pilot-consent/cohort-2026-001',
  metricsSnapshotReference,
  closureReference: pilotClosureReference,
  participantConsentRecorded: true,
  aggregatedDataOnly: true,
  containsParticipantIdentifiers: false,
  closureApproved: true,
  closureAudit: pilotClosureAudit,
};
assert.strictEqual(validateRealPilotEvidence(pilot, deployedHashes), true);
assert.strictEqual(validateRealPilotEvidence({
  ...pilot,
  phone: '+258000000000',
}, deployedHashes), false);
assert.strictEqual(validateRealPilotEvidence({
  ...pilot,
  metrics: { ...pilot.metrics, providersCompletedFirstPaidJob: 0 },
}, deployedHashes), false);
assert.strictEqual(validateRealPilotEvidence({
  ...pilot,
  metrics: { ...pilot.metrics, requestsCompleted: 18 },
}, deployedHashes), false);
assert.strictEqual(validateRealPilotEvidence({
  ...pilot,
  metrics: { ...pilot.metrics, percentFirstPaidJobWithin30Days: 61 },
}, deployedHashes), false);
assert.strictEqual(validateRealPilotEvidence({
  ...pilot,
  startedAt: '2026-06-15T00:00:00.000Z',
}, deployedHashes), false);
assert.strictEqual(validateRealPilotEvidence({
  ...pilot,
  closureAudit: { ...pilotClosureAudit, artifactSha256: '0'.repeat(64) },
}, deployedHashes), false);
assert.strictEqual(validateRealPilotEvidence({
  ...pilot,
  completedAt: 'not-a-timestamp',
}, deployedHashes), false);
assert.strictEqual(containsPiiKeys({ aggregate: { email: 'hidden' } }), true);
assert.strictEqual(containsPiiKeys({ aggregate: { participant_phone: 'hidden' } }), true);
assert.strictEqual(containsPiiKeys({ aggregate: { providerUid: 'hidden' } }), true);
assert.strictEqual(containsPiiKeys({ aggregate: { providers: 10 } }), false);

console.log('p1_pilot_readiness validators: PASS');
