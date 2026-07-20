/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../..');
const DEFAULT_PROJECT_ID = 'chegaja-ac88d';
const suspiciousSegment = /^(?:kyc|passport|passaporte|bilhete|identidade|document|documento|comprovativo|certificate|certificado|license|licenca|licença|nuit|morada|address|invoice|fatura|payment|pagamento)(?:[._-]|$)/i;

function readJson(relativePath) {
  return JSON.parse(fs.readFileSync(path.join(root, relativePath), 'utf8'));
}

function defaultBucket() {
  return readJson('android/app/google-services.json').project_info.storage_bucket;
}

function resolveOptions(argv = process.argv.slice(2)) {
  const options = {
    projectId: DEFAULT_PROJECT_ID,
    bucket: defaultBucket(),
    json: false,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--help' || arg === '-h') options.help = true;
    else if (arg === '--json') options.json = true;
    else if (arg.startsWith('--project=')) options.projectId = arg.slice(10);
    else if (arg === '--project') options.projectId = argv[++index] || '';
    else if (arg.startsWith('--bucket=')) options.bucket = arg.slice(9);
    else if (arg === '--bucket') options.bucket = argv[++index] || '';
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!options.help) {
    if (!options.projectId) throw new Error('--project is required.');
    if (!options.bucket) throw new Error('--bucket is required.');
    if (options.projectId !== DEFAULT_PROJECT_ID) {
      throw new Error(`Refusing unexpected project: ${options.projectId}`);
    }
    if (!options.bucket.startsWith(`${options.projectId}.`)) {
      throw new Error('Bucket does not belong to the confirmed project.');
    }
  }
  return options;
}

function accessClass(objectName) {
  const segments = String(objectName || '').split('/').filter(Boolean);
  const top = segments[0] || '';
  if (top === 'kyc' || top === 'kyc_pending') return 'restricted';
  if (top === 'pedidos' || top === 'chats' || top === 'temp') return 'participant_private';
  if (top === 'users') return 'authenticated_shared';
  if (top === 'profile_public') return 'public_profile';
  if (top === 'portfolio') return 'public_portfolio';
  if (top === 'prestadores') return 'legacy_public_provider';
  if (top === 'stories') return 'disabled_public_story';
  if (top === 'migration_quarantine') return 'restricted_quarantine';
  return 'unknown';
}

function hasDownloadToken(item) {
  const value = item && item.metadata && item.metadata.firebaseStorageDownloadTokens;
  return typeof value === 'string' && value.trim().length > 0;
}

function hasSuspiciousPublicName(objectName) {
  const classification = accessClass(objectName);
  if (![
    'public_profile', 'public_portfolio', 'legacy_public_provider', 'disabled_public_story',
  ].includes(classification)) {
    return false;
  }
  return String(objectName || '').split('/').some((segment) => suspiciousSegment.test(segment));
}

function summarize(items, projectId, bucket) {
  const byAccessClass = {};
  const objectShapes = {
    userProfileImage: 0,
    userOther: 0,
    pedidoAttachment: 0,
    chatImage: 0,
    chatFile: 0,
    chatAudio: 0,
    tempAttachment: 0,
    publicProfileImage: 0,
    quarantinedObject: 0,
  };
  let bytes = 0;
  let objectsWithDownloadTokens = 0;
  let nonPublicObjectsWithDownloadTokens = 0;
  let restrictedObjectsWithDownloadTokens = 0;
  let suspiciousObjectsInPublicPaths = 0;
  let disabledStoryObjects = 0;
  let unknownObjects = 0;

  for (const item of items) {
    const classification = accessClass(item.name);
    const segments = String(item.name || '').split('/').filter(Boolean);
    const fileName = segments[segments.length - 1] || '';
    if (segments[0] === 'users') {
      if (segments.length === 3
        && /^(?:perfil|profile|avatar)(?:[._-]|$)/i.test(fileName)
        && String(item.contentType || '').startsWith('image/')) {
        objectShapes.userProfileImage += 1;
      } else objectShapes.userOther += 1;
    } else if (segments[0] === 'pedidos' && segments[2] === 'anexos') {
      objectShapes.pedidoAttachment += 1;
    } else if (segments[0] === 'chats' && segments[2] === 'images') {
      objectShapes.chatImage += 1;
    } else if (segments[0] === 'chats' && segments[2] === 'files') {
      objectShapes.chatFile += 1;
    } else if (segments[0] === 'chats' && segments[2] === 'audio') {
      objectShapes.chatAudio += 1;
    } else if (segments[0] === 'temp' && segments[2] === 'anexos') {
      objectShapes.tempAttachment += 1;
    } else if (segments[0] === 'profile_public') {
      objectShapes.publicProfileImage += 1;
    } else if (segments[0] === 'migration_quarantine') {
      objectShapes.quarantinedObject += 1;
    }
    byAccessClass[classification] = (byAccessClass[classification] || 0) + 1;
    bytes += Number(item.size || 0);
    const token = hasDownloadToken(item);
    if (token) objectsWithDownloadTokens += 1;
    if (token && ![
      'public_profile', 'public_portfolio', 'legacy_public_provider',
    ].includes(classification)) {
      nonPublicObjectsWithDownloadTokens += 1;
    }
    if (token && classification === 'restricted') restrictedObjectsWithDownloadTokens += 1;
    if (hasSuspiciousPublicName(item.name)) suspiciousObjectsInPublicPaths += 1;
    if (classification === 'disabled_public_story') disabledStoryObjects += 1;
    if (classification === 'unknown') unknownObjects += 1;
  }

  const blockers = {
    restrictedObjectsWithDownloadTokens,
    nonPublicObjectsWithDownloadTokens,
    suspiciousObjectsInPublicPaths,
    disabledStoryObjects,
    unknownObjects,
  };
  return {
    capturedAt: new Date().toISOString(),
    projectId,
    bucket,
    privacySafeOutput: true,
    objectNamesIncluded: false,
    totalObjects: items.length,
    totalBytes: bytes,
    byAccessClass,
    objectShapes,
    objectsWithDownloadTokens,
    blockers,
    passed: Object.values(blockers).every((value) => value === 0),
  };
}

async function storageClient(projectId) {
  const auth = require(path.join(root, 'node_modules', 'firebase-tools', 'lib', 'auth'));
  const { requireAuth } = require(
    path.join(root, 'node_modules', 'firebase-tools', 'lib', 'requireAuth'),
  );
  const { Client } = require(
    path.join(root, 'node_modules', 'firebase-tools', 'lib', 'apiv2'),
  );
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Execute firebase login antes da auditoria.');
  await requireAuth({ project: projectId, nonInteractive: true, ...account });
  return new Client({ urlPrefix: 'https://storage.googleapis.com', apiVersion: 'storage/v1' });
}

async function listObjects(client, bucket) {
  const items = [];
  let pageToken = '';
  do {
    const response = await client.get(`/b/${encodeURIComponent(bucket)}/o`, {
      queryParams: {
        maxResults: 1000,
        projection: 'full',
        fields: 'items(name,size,contentType,timeCreated,updated,metadata),nextPageToken',
        ...(pageToken ? { pageToken } : {}),
      },
    });
    items.push(...(response.body.items || []));
    pageToken = response.body.nextPageToken || '';
  } while (pageToken);
  return items;
}

function printHelp() {
  console.log(`Usage:
  node scripts/qa/firebase_storage_boundary_audit.js --json

Read-only production audit. Output contains aggregate counts only and never
prints object names, download tokens, UIDs or file metadata values.`);
}

async function main() {
  const options = resolveOptions();
  if (options.help) return printHelp();
  const client = await storageClient(options.projectId);
  const items = await listObjects(client, options.bucket);
  const result = summarize(items, options.projectId, options.bucket);
  console.log(JSON.stringify(result, null, 2));
  if (!result.passed) process.exitCode = 2;
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[firebase_storage_boundary_audit] FAILED: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  accessClass,
  hasDownloadToken,
  hasSuspiciousPublicName,
  resolveOptions,
  summarize,
};
