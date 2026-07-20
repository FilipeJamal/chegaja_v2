/* eslint-disable no-console */
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const {
  collectReleaseInputs,
  releaseSourceFingerprint,
} = require('./release_source_fingerprint');

const root = path.resolve(__dirname, '../..');
const expectedAndroidPackage = 'com.chegaja.app';
const expectedAndroidFirebaseAppId = '1:767588494857:android:4198384a2a6387055252d8';
const expectedSigningCertificate =
  '1336ff14c1ddf09440387bbdf9f48d5a09602a87d1062ae6fce2a5072bac1f81';
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
  if (!evidence || !validIsoDate(evidence.capturedAt)) return false;
  if (!expected || !expected.apkSha256) return false;
  const services = evidence.services || {};
  const artifacts = evidence.deployedArtifacts || {};
  const enforced = (key) => String(services[key] || '').toUpperCase() === 'ENFORCED';
  const realReference = typeof evidence.deploymentReference === 'string'
    && evidence.deploymentReference.trim().length > 0
    && !/^(todo|tbd|placeholder|example)(?:\b|[-_])/i.test(evidence.deploymentReference.trim());
  return evidence.projectId === 'chegaja-ac88d'
    && enforced('firestore')
    && enforced('storage')
    && enforced('authentication')
    && evidence.functionsCallablesEnforceAppCheck === true
    && realReference
    && evidence.apkSha256 === expected.apkSha256
    && validIsoDate(evidence.migrationRerunAt)
    && artifacts.firestoreRulesSha256 === expected.firestoreRulesSha256
    && artifacts.storageRulesSha256 === expected.storageRulesSha256
    && artifacts.functionsIndexSha256 === expected.functionsIndexSha256;
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

function validateReleaseProvenance(evidence, apkDigest) {
  if (!evidence || !validIsoDate(evidence.generatedAt) || !apkDigest) return false;
  const inputs = collectReleaseInputs();
  return evidence.apkSha256 === apkDigest
    && evidence.releaseSourceFingerprint === releaseSourceFingerprint(inputs)
    && Number(evidence.releaseInputFiles) === inputs.length
    && evidence.generatedRegistrantExcluded === true;
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

function validatePhysicalEvidence(evidence, apkDigest) {
  if (!evidence || String(evidence.status).toUpperCase() !== 'COMPLETED') return false;
  const device = evidence.device || {};
  const results = Array.isArray(evidence.cases) ? evidence.cases : [];
  const passedCases = new Set(
    results
      .filter((item) => item && item.result === 'passed')
      .map((item) => item.id),
  );
  return evidence.apkSha256 === apkDigest
    && validIsoDate(evidence.executedAt)
    && device.physical === true
    && Number(device.apiLevel) >= 33
    && Boolean(device.manufacturer)
    && Boolean(device.model)
    && requiredPhysicalCases.every((id) => passedCases.has(id))
    && evidence.logsRedacted === true;
}

function containsPiiKeys(value) {
  const forbidden = /^(name|fullName|email|phone|telephone|address|street|house|document|documentNumber|token|uid|userId|participantId)$/i;
  if (Array.isArray(value)) return value.some(containsPiiKeys);
  if (!value || typeof value !== 'object') return false;
  return Object.entries(value).some(([key, child]) => forbidden.test(key) || containsPiiKeys(child));
}

function validateRealPilotEvidence(evidence, apkDigest) {
  if (!evidence || String(evidence.status).toUpperCase() !== 'COMPLETED') return false;
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
  return evidence.apkSha256 === apkDigest
    && validIsoDate(evidence.startedAt)
    && validIsoDate(evidence.completedAt)
    && Number(cohort.providers) > 0
    && Number(cohort.clients) > 0
    && requiredMetrics.every((key) => Number.isFinite(metrics[key]) && metrics[key] >= 0)
    && evidence.participantConsentRecorded === true
    && evidence.aggregatedDataOnly === true
    && evidence.closureApproved === true
    && !containsPiiKeys(evidence);
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
  const releaseProvenance = readJson('build/p1_release_provenance.json');
  const uiEvidence = read('build/p1_8_ui.xml');
  const emulatorEvidence = readJson('docs/android/p1-8-emulator-validation.json');

  const checks = [];
  function check(id, passed, severity, detail) {
    checks.push({ id, passed: Boolean(passed), severity, detail });
  }

  check('signed_apk', apk.passed && validateReleaseProvenance(releaseProvenance, apk.digest),
    'blocker',
    `APK v2 assinada e ligada aos fontes release atuais; SHA-256: ${apk.digest || 'indisponível'}`);
  check('android_runtime_evidence', exists('build/p1_8_launch.png')
    && uiEvidence.includes('Sou cliente')
    && uiEvidence.includes('Sou prestador')
    && emulatorEvidence
    && emulatorEvidence.status === 'COMPLETED'
    && emulatorEvidence.apkSha256 === apk.digest
    && emulatorEvidence.device?.physical === false
    && emulatorEvidence.startupPermissionPrompt === false
    && Array.isArray(emulatorEvidence.fatalPatternsMatched)
    && emulatorEvidence.fatalPatternsMatched.length === 0,
  'blocker', 'captura e hierarquia comprovam o seletor Android em português');
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
      apkSha256: apk.digest,
      firestoreRulesSha256: sha256File('firestore.rules'),
      storageRulesSha256: sha256File('storage.rules'),
      functionsIndexSha256: sha256File('functions/index.js'),
    },
  ), 'blocker', 'Firestore, Storage, Authentication e callables comprovadamente protegidos');
  check('physical_android', validatePhysicalEvidence(
    readJson('docs/pilot/evidence/android-physical-validation.json'), apk.digest,
  ), 'blocker', 'matriz de 12 casos aprovada em Android físico API 33+ para esta APK');
  check('real_pilot_execution', validateRealPilotEvidence(
    readJson('docs/pilot/evidence/real-pilot-execution.json'), apk.digest,
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
  containsPiiKeys,
  requiredPhysicalCases,
  validateAndroidProductionIdentity,
  validateAppCheckEvidence,
  validateDeletionSecretEvidence,
  validateLegalApproval,
  validateLegalIdentity,
  validatePhysicalEvidence,
  validateRealPilotEvidence,
  validateReleaseProvenance,
  validateStorageBoundaryEvidence,
};
