const path = require('path');

const DEFAULT_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'chegaja-ac88d';

const USER_PUBLIC_FIELDS = new Set([
  'uid', 'nome', 'displayName', 'photoUrl', 'fotoUrl', 'bio',
  'city', 'state', 'province', 'country', 'countryCode', 'stateCode',
  'createdAt', 'updatedAt',
]);

const PROVIDER_PUBLIC_FIELDS = new Set([
  'uid', 'userId', 'nome', 'displayName', 'photoUrl', 'fotoUrl', 'bio',
  'city', 'state', 'country', 'countryCode', 'stateCode', 'radiusKm',
  'servicos', 'servicosNomes', 'categories', 'customServices',
  'customServiceNames', 'customServiceSearchTerms', 'portfolioUrls',
  'portfolioImages', 'handle', 'handleDisplay', 'handleUpdatedAt',
  'ratingCount', 'ratingSum', 'ratingAvg', 'approvedSensitiveCategoryIds',
  'approvedSensitiveCategoryNames', 'categoryApprovalsUpdatedAt',
  'isSearchable', 'createdAt', 'updatedAt',
]);

const PROVIDER_DISPATCH_FIELDS = new Set([
  'isOnline', 'lastLocation', 'geo', 'geohash', 'radiusKm', 'workingHours',
  'blockedDates', 'servicos', 'servicosNomes', 'lastSeenAt', 'createdAt',
  'updatedAt',
]);

function pickFields(data, allowlist) {
  const result = {};
  for (const [key, value] of Object.entries(data || {})) {
    if (allowlist.has(key)) result[key] = value;
  }
  return result;
}

function omitFields(data, ...allowlists) {
  const excluded = new Set(allowlists.flatMap((set) => [...set]));
  return Object.fromEntries(
    Object.entries(data || {}).filter(([key]) => !excluded.has(key)),
  );
}

function partitionUser(uid, data = {}) {
  return {
    publicProfile: { ...pickFields(data, USER_PUBLIC_FIELDS), uid },
    privateUser: { ...omitFields(data, USER_PUBLIC_FIELDS), uid },
  };
}

function partitionProvider(uid, data = {}) {
  const publicProfile = pickFields(data, PROVIDER_PUBLIC_FIELDS);
  delete publicProfile.isOnline;
  delete publicProfile.lastLocation;
  delete publicProfile.geo;
  delete publicProfile.geohash;

  return {
    publicProvider: { ...publicProfile, uid },
    dispatchProvider: {
      ...pickFields(data, PROVIDER_DISPATCH_FIELDS),
      providerId: uid,
    },
    privateProvider: {
      ...omitFields(data, PROVIDER_PUBLIC_FIELDS, PROVIDER_DISPATCH_FIELDS),
      providerId: uid,
    },
  };
}

function resolveOptions(argv = process.argv.slice(2)) {
  const options = {
    projectId: DEFAULT_PROJECT_ID,
    dryRun: true,
    confirm: false,
    confirmProject: '',
    limit: null,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--help' || arg === '-h') options.help = true;
    else if (arg === '--dry-run') options.dryRun = true;
    else if (arg === '--confirm') {
      options.confirm = true;
      options.dryRun = false;
    } else if (arg.startsWith('--project=')) {
      options.projectId = arg.slice('--project='.length);
    } else if (arg === '--project') {
      options.projectId = argv[++index] || '';
    } else if (arg.startsWith('--confirm-project=')) {
      options.confirmProject = arg.slice('--confirm-project='.length);
    } else if (arg === '--confirm-project') {
      options.confirmProject = argv[++index] || '';
    } else if (arg.startsWith('--limit=')) {
      options.limit = Number(arg.slice('--limit='.length));
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  if (!options.help) validateOptions(options);
  return options;
}

function validateOptions(options) {
  if (!String(options.projectId || '').trim()) throw new Error('--project is required.');
  if (options.limit !== null && (!Number.isInteger(options.limit) || options.limit < 1)) {
    throw new Error('--limit must be a positive integer.');
  }
  if (options.confirm && options.confirmProject !== options.projectId) {
    throw new Error('--confirm-project must match --project exactly.');
  }
}

async function firestoreRestClient(projectId) {
  const root = path.resolve(__dirname, '..', '..');
  const auth = require(path.join(root, 'node_modules', 'firebase-tools', 'lib', 'auth'));
  const { requireAuth } = require(
    path.join(root, 'node_modules', 'firebase-tools', 'lib', 'requireAuth'),
  );
  const { Client } = require(
    path.join(root, 'node_modules', 'firebase-tools', 'lib', 'apiv2'),
  );
  const account = auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Run firebase login before the migration.');
  await requireAuth({ project: projectId, nonInteractive: true, ...account });
  return new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
}

async function readLegacyCollection(client, projectId, name, limit) {
  const documents = [];
  let pageToken = '';
  do {
    const remaining = limit ? limit - documents.length : 1000;
    if (remaining <= 0) break;
    const response = await client.get(
      `/projects/${projectId}/databases/(default)/documents/${name}`,
      {
        queryParams: {
          pageSize: Math.min(1000, remaining),
          orderBy: '__name__',
          ...(pageToken ? { pageToken } : {}),
        },
      },
    );
    documents.push(...(response.body.documents || []));
    pageToken = response.body.nextPageToken || '';
  } while (pageToken && (!limit || documents.length < limit));
  return documents;
}

function pickRawFields(fields, allowlist) {
  return Object.fromEntries(
    Object.entries(fields || {}).filter(([key]) => allowlist.has(key)),
  );
}

function omitRawFields(fields, ...allowlists) {
  const excluded = new Set(allowlists.flatMap((set) => [...set]));
  return Object.fromEntries(
    Object.entries(fields || {}).filter(([key]) => !excluded.has(key)),
  );
}

function partitionRawUser(uid, fields = {}) {
  const uidValue = { stringValue: uid };
  return {
    publicProfile: { ...pickRawFields(fields, USER_PUBLIC_FIELDS), uid: uidValue },
    privateUser: { ...omitRawFields(fields, USER_PUBLIC_FIELDS), uid: uidValue },
  };
}

function partitionRawProvider(uid, fields = {}) {
  const uidValue = { stringValue: uid };
  const publicProvider = pickRawFields(fields, PROVIDER_PUBLIC_FIELDS);
  delete publicProvider.isOnline;
  delete publicProvider.lastLocation;
  delete publicProvider.geo;
  delete publicProvider.geohash;
  return {
    publicProvider: { ...publicProvider, uid: uidValue },
    dispatchProvider: {
      ...pickRawFields(fields, PROVIDER_DISPATCH_FIELDS),
      providerId: uidValue,
    },
    privateProvider: {
      ...omitRawFields(fields, PROVIDER_PUBLIC_FIELDS, PROVIDER_DISPATCH_FIELDS),
      providerId: uidValue,
    },
  };
}

function documentId(document) {
  return decodeURIComponent(document.name.split('/').pop());
}

async function commitWrites(client, projectId, writes) {
  const database = `projects/${projectId}/databases/(default)`;
  for (let start = 0; start < writes.length; start += 400) {
    const batch = writes.slice(start, start + 400).map(([collection, id, fields]) => ({
      update: {
        name: `${database}/documents/${collection}/${id}`,
        fields,
      },
      updateMask: { fieldPaths: Object.keys(fields) },
    }));
    await client.post(`/${database}/documents:commit`, { writes: batch });
  }
}

async function migrate(options) {
  const client = await firestoreRestClient(options.projectId);
  const [users, providers] = await Promise.all([
    readLegacyCollection(client, options.projectId, 'users', options.limit),
    readLegacyCollection(client, options.projectId, 'prestadores', options.limit),
  ]);
  const summary = {
    projectId: options.projectId,
    dryRun: options.dryRun,
    legacyUsers: users.length,
    legacyProviders: providers.length,
    writesPlanned: (users.length * 2) + (providers.length * 3),
  };
  if (options.dryRun) return summary;

  const writes = [];
  for (const document of users) {
    const id = documentId(document);
    const split = partitionRawUser(id, document.fields);
    writes.push(['public_profiles', id, split.publicProfile]);
    writes.push(['users_private', id, split.privateUser]);
  }
  for (const document of providers) {
    const id = documentId(document);
    const split = partitionRawProvider(id, document.fields);
    writes.push(['provider_public', id, split.publicProvider]);
    writes.push(['provider_private', id, split.privateProvider]);
    writes.push(['provider_dispatch_private', id, split.dispatchProvider]);
  }
  await commitWrites(client, options.projectId, writes);
  return summary;
}

function printHelp() {
  console.log(`Usage:
  node scripts/admin/migrate_p1_data_boundaries.js --project=${DEFAULT_PROJECT_ID} --dry-run
  node scripts/admin/migrate_p1_data_boundaries.js --project=${DEFAULT_PROJECT_ID} --confirm --confirm-project=${DEFAULT_PROJECT_ID}

The migration is additive and idempotent. It never deletes legacy documents.
Unknown fields default to private storage.`);
}

async function main() {
  const options = resolveOptions();
  if (options.help) return printHelp();
  const summary = await migrate(options);
  console.log(JSON.stringify(summary, null, 2));
  console.log(options.dryRun ? 'DRY_RUN_ONLY' : 'MIGRATION_WRITTEN');
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[migrate_p1_data_boundaries] FAILED: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  partitionProvider,
  partitionUser,
  resolveOptions,
  validateOptions,
};
