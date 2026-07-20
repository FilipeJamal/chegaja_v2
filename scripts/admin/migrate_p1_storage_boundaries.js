/* eslint-disable no-console */
const crypto = require('crypto');
const path = require('path');

const root = path.resolve(__dirname, '../..');
const DEFAULT_PROJECT_ID = 'chegaja-ac88d';
const DEFAULT_BUCKET = 'chegaja-ac88d.firebasestorage.app';
const QUARANTINE_PREFIX = 'migration_quarantine/2026-07-20';

function resolveOptions(argv = process.argv.slice(2)) {
  const options = {
    projectId: DEFAULT_PROJECT_ID,
    bucket: DEFAULT_BUCKET,
    confirm: false,
    confirmProject: '',
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--help' || arg === '-h') options.help = true;
    else if (arg === '--dry-run') options.confirm = false;
    else if (arg === '--confirm') options.confirm = true;
    else if (arg.startsWith('--project=')) options.projectId = arg.slice(10);
    else if (arg === '--project') options.projectId = argv[++index] || '';
    else if (arg.startsWith('--confirm-project=')) options.confirmProject = arg.slice(18);
    else if (arg === '--confirm-project') options.confirmProject = argv[++index] || '';
    else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!options.help) {
    if (options.projectId !== DEFAULT_PROJECT_ID) {
      throw new Error(`Refusing unexpected project: ${options.projectId}`);
    }
    if (options.bucket !== DEFAULT_BUCKET) throw new Error('Unexpected production bucket.');
    if (options.confirm && options.confirmProject !== options.projectId) {
      throw new Error('--confirm-project must match --project exactly.');
    }
  }
  return options;
}

function decodeFirestoreValue(value) {
  if (!value) return null;
  if (Object.prototype.hasOwnProperty.call(value, 'stringValue')) return value.stringValue;
  if (value.arrayValue) return (value.arrayValue.values || []).map(decodeFirestoreValue);
  return null;
}

function storagePathFromReference(value, bucket = DEFAULT_BUCKET) {
  if (typeof value !== 'string' || !value.trim()) return '';
  const normalized = value.trim();
  if (!/^https?:\/\//i.test(normalized)) return normalized;
  try {
    const url = new URL(normalized);
    const firebaseMatch = url.pathname.match(/\/o\/(.+)$/);
    if (firebaseMatch) return decodeURIComponent(firebaseMatch[1]);
    const gcsPrefix = `/${bucket}/`;
    if (url.hostname === 'storage.googleapis.com' && url.pathname.startsWith(gcsPrefix)) {
      return decodeURIComponent(url.pathname.slice(gcsPrefix.length));
    }
  } catch (_) {
    return '';
  }
  return '';
}

function firebaseDownloadUrl(bucket, objectName, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(objectName)}`
    + `?alt=media&token=${encodeURIComponent(token)}`;
}

function quarantinePath(objectName) {
  const hash = crypto.createHash('sha256').update(objectName).digest('hex').slice(0, 20);
  const fileName = objectName.split('/').pop().replace(/[^A-Za-z0-9._-]/g, '_') || 'object';
  return `${QUARANTINE_PREFIX}/${hash}/${fileName}`;
}

function accessClass(objectName) {
  const top = String(objectName || '').split('/')[0];
  if (top === 'users') return 'legacy_user_profile';
  if (['pedidos', 'chats', 'temp'].includes(top)) return 'participant_private';
  return 'unchanged';
}

async function clients(projectId) {
  const auth = require(path.join(root, 'node_modules', 'firebase-tools', 'lib', 'auth'));
  const { requireAuth } = require(
    path.join(root, 'node_modules', 'firebase-tools', 'lib', 'requireAuth'),
  );
  const { Client } = require(
    path.join(root, 'node_modules', 'firebase-tools', 'lib', 'apiv2'),
  );
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Execute firebase login antes da migracao.');
  await requireAuth({ project: projectId, nonInteractive: true, ...account });
  return {
    firestore: new Client({
      urlPrefix: 'https://firestore.googleapis.com',
      apiVersion: 'v1',
    }),
    storage: new Client({
      urlPrefix: 'https://storage.googleapis.com',
      apiVersion: 'storage/v1',
    }),
    identity: new Client({
      urlPrefix: 'https://identitytoolkit.googleapis.com',
      apiVersion: 'v1',
    }),
  };
}

async function listFirestoreCollection(client, projectId, collection) {
  const documents = [];
  let pageToken = '';
  do {
    const response = await client.get(
      `/projects/${projectId}/databases/(default)/documents/${collection}`,
      { queryParams: { pageSize: 1000, ...(pageToken ? { pageToken } : {}) } },
    );
    documents.push(...(response.body.documents || []));
    pageToken = response.body.nextPageToken || '';
  } while (pageToken);
  return documents;
}

async function listAuthUsers(client, projectId) {
  const users = [];
  let nextPageToken = '';
  do {
    const response = await client.get(`/projects/${projectId}/accounts:batchGet`, {
      queryParams: {
        maxResults: 1000,
        ...(nextPageToken ? { nextPageToken } : {}),
      },
    });
    users.push(...(response.body.users || []));
    nextPageToken = response.body.nextPageToken || '';
  } while (nextPageToken);
  return users;
}

async function listStorageObjects(client, bucket) {
  const items = [];
  let pageToken = '';
  do {
    const response = await client.get(`/b/${encodeURIComponent(bucket)}/o`, {
      queryParams: {
        maxResults: 1000,
        projection: 'full',
        ...(pageToken ? { pageToken } : {}),
      },
    });
    items.push(...(response.body.items || []));
    pageToken = response.body.nextPageToken || '';
  } while (pageToken);
  return items;
}

async function listChatMessages(client, projectId) {
  const response = await client.post(
    `/projects/${projectId}/databases/(default)/documents:runQuery`,
    {
      structuredQuery: {
        from: [{ collectionId: 'messages', allDescendants: true }],
        limit: 5000,
      },
    },
  );
  return (Array.isArray(response.body) ? response.body : [])
    .map((row) => row.document)
    .filter(Boolean);
}

function collectReferences({ firestoreDocuments, authUsers, bucket }) {
  const references = new Map();
  const add = (storagePath, reference) => {
    if (!storagePath) return;
    if (!references.has(storagePath)) references.set(storagePath, []);
    references.get(storagePath).push(reference);
  };
  for (const document of firestoreDocuments) {
    for (const field of ['photoUrl', 'fotoUrl']) {
      const value = decodeFirestoreValue((document.fields || {})[field]);
      add(storagePathFromReference(value, bucket), {
        kind: 'firestore_string',
        documentName: document.name,
        field,
      });
    }
    const attachments = decodeFirestoreValue((document.fields || {}).anexos);
    if (Array.isArray(attachments)) {
      attachments.forEach((value, index) => add(storagePathFromReference(value, bucket), {
        kind: 'pedido_attachment',
        documentName: document.name,
        field: 'anexos',
        index,
      }));
    }
    for (const field of ['mediaUrl', 'fileUrl', 'url', 'mediaPath']) {
      const value = decodeFirestoreValue((document.fields || {})[field]);
      add(storagePathFromReference(value, bucket), {
        kind: 'chat_media',
        documentName: document.name,
        field,
      });
    }
  }
  for (const user of authUsers) {
    add(storagePathFromReference(user.photoUrl, bucket), {
      kind: 'auth_photo',
      localId: user.localId,
    });
  }
  return references;
}

function buildPlan({ objects, references }) {
  const operations = [];
  let referencedPrivateObjects = 0;
  for (const object of objects) {
    const classification = accessClass(object.name);
    const refs = references.get(object.name) || [];
    if (classification === 'legacy_user_profile') {
      const segments = object.name.split('/');
      const destination = refs.length > 0
        ? `profile_public/${segments[1]}/${segments.slice(2).join('/')}`
        : quarantinePath(object.name);
      operations.push({
        action: refs.length > 0 ? 'migrate_public_profile' : 'quarantine_unreferenced',
        source: object.name,
        destination,
        references: refs,
        token: (object.metadata || {}).firebaseStorageDownloadTokens || '',
      });
    } else if (classification === 'participant_private') {
      if (refs.length > 0) {
        referencedPrivateObjects += 1;
      } else {
        operations.push({
          action: 'quarantine_unreferenced',
          source: object.name,
          destination: quarantinePath(object.name),
          references: [],
          token: '',
        });
      }
    }
  }
  const counts = operations.reduce((result, item) => {
    result[item.action] = (result[item.action] || 0) + 1;
    return result;
  }, {});
  return { operations, referencedPrivateObjects, counts };
}

async function copyObject(client, bucket, operation) {
  const source = encodeURIComponent(operation.source);
  const destination = encodeURIComponent(operation.destination);
  const isPublic = operation.action === 'migrate_public_profile';
  const token = isPublic ? (operation.token.split(',')[0] || crypto.randomUUID()) : '';
  const metadata = isPublic
    ? { firebaseStorageDownloadTokens: token, chegajaPublicPurpose: 'profile_photo' }
    : { chegajaPrivateAccess: 'migration_quarantine' };
  await client.post(
    `/b/${encodeURIComponent(bucket)}/o/${source}/rewriteTo/b/${encodeURIComponent(bucket)}/o/${destination}`,
    {
      cacheControl: isPublic ? 'public, max-age=3600' : 'private, no-store, max-age=0',
      metadata,
    },
  );
  return token;
}

async function updateFirestoreString(client, reference, value) {
  await client.patch(`/${reference.documentName}`, {
    fields: { [reference.field]: { stringValue: value } },
  }, {
    queryParams: { 'updateMask.fieldPaths': reference.field },
  });
}

async function executePlan({ api, options, plan }) {
  let copied = 0;
  let firestoreReferencesUpdated = 0;
  let authReferencesUpdated = 0;
  let sourcesRemoved = 0;
  for (const operation of plan.operations) {
    const token = await copyObject(api.storage, options.bucket, operation);
    copied += 1;
    if (operation.action === 'migrate_public_profile') {
      const url = firebaseDownloadUrl(options.bucket, operation.destination, token);
      for (const reference of operation.references) {
        if (reference.kind === 'firestore_string') {
          await updateFirestoreString(api.firestore, reference, url);
          firestoreReferencesUpdated += 1;
        } else if (reference.kind === 'auth_photo') {
          await api.identity.post(`/projects/${options.projectId}/accounts:update`, {
            localId: reference.localId,
            photoUrl: url,
          });
          authReferencesUpdated += 1;
        }
      }
    }
    await api.storage.delete(
      `/b/${encodeURIComponent(options.bucket)}/o/${encodeURIComponent(operation.source)}`,
    );
    sourcesRemoved += 1;
  }
  return {
    copied,
    firestoreReferencesUpdated,
    authReferencesUpdated,
    sourcesRemoved,
  };
}

async function migrate(options) {
  const api = await clients(options.projectId);
  const [users, publicProfiles, providers, pedidos, chatMessages, authUsers, objects] =
    await Promise.all([
      listFirestoreCollection(api.firestore, options.projectId, 'users'),
      listFirestoreCollection(api.firestore, options.projectId, 'public_profiles'),
      listFirestoreCollection(api.firestore, options.projectId, 'provider_public'),
      listFirestoreCollection(api.firestore, options.projectId, 'pedidos'),
      listChatMessages(api.firestore, options.projectId),
      listAuthUsers(api.identity, options.projectId),
      listStorageObjects(api.storage, options.bucket),
    ]);
  const references = collectReferences({
    firestoreDocuments: [...users, ...publicProfiles, ...providers, ...pedidos, ...chatMessages],
    authUsers,
    bucket: options.bucket,
  });
  const plan = buildPlan({ objects, references });
  const summary = {
    projectId: options.projectId,
    bucket: options.bucket,
    dryRun: !options.confirm,
    privacySafeOutput: true,
    objectNamesIncluded: false,
    totalObjects: objects.length,
    planned: plan.counts,
    referencedPrivateObjects: plan.referencedPrivateObjects,
  };
  if (options.confirm && plan.referencedPrivateObjects > 0) {
    throw new Error(
      'Referenced private objects exist. Convert Firestore references during the controlled cutover first.',
    );
  }
  if (options.confirm) summary.executed = await executePlan({ api, options, plan });
  return summary;
}

function printHelp() {
  console.log(`Usage:
  node scripts/admin/migrate_p1_storage_boundaries.js --dry-run
  node scripts/admin/migrate_p1_storage_boundaries.js --confirm --confirm-project=${DEFAULT_PROJECT_ID}

Referenced public profile photos are copied to profile_public and all known
Firestore/Auth references are updated before the source is removed. Unreferenced
legacy/private objects are moved into a token-free, default-deny quarantine.
The script refuses execution if any private object is still referenced.`);
}

async function main() {
  const options = resolveOptions();
  if (options.help) return printHelp();
  const result = await migrate(options);
  console.log(JSON.stringify(result, null, 2));
  console.log(options.confirm ? 'STORAGE_BOUNDARIES_MIGRATED' : 'DRY_RUN_ONLY');
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[migrate_p1_storage_boundaries] FAILED: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  accessClass,
  buildPlan,
  collectReferences,
  decodeFirestoreValue,
  firebaseDownloadUrl,
  quarantinePath,
  resolveOptions,
  storagePathFromReference,
};
