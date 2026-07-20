const assert = require('assert');

const {
  containsPiiKeys,
  requiredPhysicalCases,
  validateAndroidProductionIdentity,
  validateAppCheckEvidence,
  validateDeletionSecretEvidence,
  validateLegalApproval,
  validatePhysicalEvidence,
  validateRealPilotEvidence,
  validateReleaseProvenance,
  validateStorageBoundaryEvidence,
} = require('../qa/p1_pilot_readiness');

const digest = 'a'.repeat(64);
const deployedHashes = {
  apkSha256: digest,
  firestoreRulesSha256: 'b'.repeat(64),
  storageRulesSha256: 'c'.repeat(64),
  functionsIndexSha256: 'd'.repeat(64),
};

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
assert.strictEqual(validateReleaseProvenance({
  generatedAt: '2026-07-20T09:00:00.000Z',
  apkSha256: digest,
  releaseSourceFingerprint: 'wrong',
  releaseInputFiles: 1,
  generatedRegistrantExcluded: true,
}, digest), false);

assert.strictEqual(validateLegalApproval(`
status: APPROVED
legal_entity: ChegaJá Sociedade, Lda.
reviewer: Revisora Legal
reviewed_at: 2026-07-20
document_version: legal-2026-07-20-pilot-v2
approval_reference: parecer-2026-001
`), true);
assert.strictEqual(validateLegalApproval(`
status: APPROVED
legal_entity: TODO
reviewer: TODO
reviewed_at: 2026-07-20
document_version: legal-2026-07-20-pilot-v2
approval_reference: TODO
`), false);

assert.strictEqual(validateAppCheckEvidence({
  projectId: 'chegaja-ac88d',
  capturedAt: '2026-07-20T08:00:00.000Z',
  migrationRerunAt: '2026-07-20T07:30:00.000Z',
  apkSha256: digest,
  services: {
    firestore: 'ENFORCED',
    storage: 'ENFORCED',
    authentication: 'ENFORCED',
  },
  functionsCallablesEnforceAppCheck: true,
  deploymentReference: 'deployment-id',
  deployedArtifacts: {
    firestoreRulesSha256: 'b'.repeat(64),
    storageRulesSha256: 'c'.repeat(64),
    functionsIndexSha256: 'd'.repeat(64),
  },
}, deployedHashes), true);
assert.strictEqual(validateAppCheckEvidence({
  projectId: 'chegaja-ac88d',
  capturedAt: '2026-07-20T08:00:00.000Z',
  migrationRerunAt: '2026-07-20T07:30:00.000Z',
  apkSha256: digest,
  services: { firestore: 'UNENFORCED', storage: 'ENFORCED', authentication: 'ENFORCED' },
  functionsCallablesEnforceAppCheck: true,
  deploymentReference: 'deployment-id',
  deployedArtifacts: {
    firestoreRulesSha256: 'b'.repeat(64),
    storageRulesSha256: 'c'.repeat(64),
    functionsIndexSha256: 'd'.repeat(64),
  },
}, deployedHashes), false);
assert.strictEqual(validateAppCheckEvidence({
  projectId: 'chegaja-ac88d',
  capturedAt: '2026-07-20T08:00:00.000Z',
  migrationRerunAt: '2026-07-20T07:30:00.000Z',
  apkSha256: digest,
  services: { firestore: 'ENFORCED', storage: 'ENFORCED', authentication: 'ENFORCED' },
  functionsCallablesEnforceAppCheck: true,
  deploymentReference: 'TODO',
  deployedArtifacts: {
    firestoreRulesSha256: 'b'.repeat(64),
    storageRulesSha256: 'c'.repeat(64),
    functionsIndexSha256: 'd'.repeat(64),
  },
}, deployedHashes), false);
assert.strictEqual(validateAppCheckEvidence({
  projectId: 'chegaja-ac88d',
  capturedAt: '2026-07-20T08:00:00.000Z',
  migrationRerunAt: '2026-07-20T07:30:00.000Z',
  apkSha256: digest,
  services: { firestore: 'ENFORCED', storage: 'ENFORCED', authentication: 'ENFORCED' },
  functionsCallablesEnforceAppCheck: true,
  deploymentReference: 'deployment-id',
  deployedArtifacts: {
    firestoreRulesSha256: '0'.repeat(64),
    storageRulesSha256: 'c'.repeat(64),
    functionsIndexSha256: 'd'.repeat(64),
  },
}, deployedHashes), false);

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

const physical = {
  status: 'COMPLETED',
  executedAt: '2026-07-20T08:00:00.000Z',
  apkSha256: digest,
  device: {
    physical: true,
    apiLevel: 34,
    manufacturer: 'Manufacturer',
    model: 'Model',
  },
  cases: requiredPhysicalCases.map((id) => ({ id, result: 'passed' })),
  logsRedacted: true,
};
assert.strictEqual(validatePhysicalEvidence(physical, digest), true);
assert.strictEqual(validatePhysicalEvidence({ ...physical, apkSha256: 'b'.repeat(64) }, digest), false);
assert.strictEqual(validatePhysicalEvidence({
  ...physical,
  cases: physical.cases.slice(1),
}, digest), false);

const pilot = {
  status: 'COMPLETED',
  startedAt: '2026-07-01',
  completedAt: '2026-07-20',
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
  participantConsentRecorded: true,
  aggregatedDataOnly: true,
  closureApproved: true,
};
assert.strictEqual(validateRealPilotEvidence(pilot, digest), true);
assert.strictEqual(validateRealPilotEvidence({ ...pilot, phone: '+258000000000' }, digest), false);
assert.strictEqual(containsPiiKeys({ aggregate: { email: 'hidden' } }), true);
assert.strictEqual(containsPiiKeys({ aggregate: { providers: 10 } }), false);

console.log('p1_pilot_readiness validators: PASS');
