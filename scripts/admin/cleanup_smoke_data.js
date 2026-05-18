const path = require('path');

const DEFAULT_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'chegaja-ac88d';
const DEFAULT_STORAGE_BUCKET =
  process.env.FIREBASE_STORAGE_BUCKET || 'chegaja-ac88d.firebasestorage.app';
const DEFAULT_PREFIX = 'm274_smoke_';
const PREFIX_END = '\uf8ff';

function resolveCleanupOptions(argv = process.argv.slice(2)) {
  const options = {
    prefix: '',
    projectId: DEFAULT_PROJECT_ID,
    storageBucket: DEFAULT_STORAGE_BUCKET,
    dryRun: true,
    confirm: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg === '--confirm') {
      options.confirm = true;
      options.dryRun = false;
    } else if (arg === '--prefix') {
      i += 1;
      options.prefix = argv[i] || '';
    } else if (arg.startsWith('--prefix=')) {
      options.prefix = arg.slice('--prefix='.length);
    } else if (arg === '--project') {
      i += 1;
      options.projectId = argv[i] || '';
    } else if (arg.startsWith('--project=')) {
      options.projectId = arg.slice('--project='.length);
    } else if (arg === '--bucket') {
      i += 1;
      options.storageBucket = argv[i] || '';
    } else if (arg.startsWith('--bucket=')) {
      options.storageBucket = arg.slice('--bucket='.length);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (options.help) return options;
  validateCleanupOptions(options);
  return options;
}

function validateCleanupOptions(options) {
  const prefix = String(options.prefix || '').trim();
  if (!prefix) {
    throw new Error('--prefix is required. Example: --prefix=m274_smoke_');
  }
  if (prefix.length < 8) {
    throw new Error('--prefix is too short for a destructive cleanup operation.');
  }
  if (/[\\/*?[\]]/.test(prefix)) {
    throw new Error('--prefix must be a plain smoke id prefix, not a path or pattern.');
  }
  if (!options.projectId) {
    throw new Error('--project is required.');
  }
  if (!options.storageBucket) {
    throw new Error('--bucket is required.');
  }
  options.prefix = prefix;
}

function unique(values) {
  return [...new Set(values.filter(Boolean))];
}

function buildCleanupPlan({
  pedidos = [],
  users = [],
  prestadores = [],
  storageFiles = [],
} = {}) {
  const firestorePaths = [];
  const authUids = [];

  for (const pedido of pedidos) {
    if (!pedido || !pedido.id) continue;
    firestorePaths.push(`pedidos/${pedido.id}`);
  }

  for (const user of users) {
    if (!user || !user.id) continue;
    firestorePaths.push(`users/${user.id}`);
    authUids.push(user.id);
  }

  for (const prestador of prestadores) {
    if (!prestador || !prestador.id) continue;
    firestorePaths.push(`prestadores/${prestador.id}`);
  }

  return {
    firestorePaths: unique(firestorePaths).sort(),
    authUids: unique(authUids).sort(),
    storageFiles: unique(storageFiles).sort(),
  };
}

async function applyCleanupPlan(plan, deps, { dryRun = true, confirm = false } = {}) {
  if (!dryRun && !confirm) {
    throw new Error('--confirm is required when dry-run is disabled.');
  }

  const summary = {
    firestoreDocs: plan.firestorePaths.length,
    storageFiles: plan.storageFiles.length,
    authUsers: plan.authUids.length,
    dryRun,
  };

  if (dryRun) return summary;

  for (const fileName of plan.storageFiles) {
    await deps.deleteStorageFile(fileName);
  }

  for (const docPath of plan.firestorePaths) {
    await deps.deleteFirestorePath(docPath);
  }

  if (plan.authUids.length > 0) {
    await deps.deleteAuthUsers(plan.authUids);
  }

  return summary;
}

function requireAdmin() {
  return require(path.resolve(__dirname, '..', '..', 'functions', 'node_modules', 'firebase-admin'));
}

function snapshotDocs(snapshot) {
  return snapshot.docs.map((doc) => ({ id: doc.id, data: doc.data() || {} }));
}

async function getDocsByIdPrefix(db, admin, collection, prefix) {
  const snapshot = await db.collection(collection)
    .orderBy(admin.firestore.FieldPath.documentId())
    .startAt(prefix)
    .endAt(`${prefix}${PREFIX_END}`)
    .get();
  return snapshotDocs(snapshot);
}

async function getDocsBySmokeRunPrefix(db, collection, prefix) {
  const snapshot = await db.collection(collection)
    .where('smokeRunId', '>=', prefix)
    .where('smokeRunId', '<=', `${prefix}${PREFIX_END}`)
    .get();
  return snapshotDocs(snapshot);
}

async function listFilesForPrefix(bucket, prefix) {
  const [files] = await bucket.getFiles({ prefix });
  return files.map((file) => file.name);
}

async function getStorageFilesForPlan(bucket, { prefix, pedidos, users }) {
  const names = [];

  for (const pedido of pedidos) {
    names.push(...await listFilesForPrefix(bucket, `pedidos/${pedido.id}/anexos/`));
  }

  for (const user of users) {
    const userFiles = await listFilesForPrefix(bucket, `temp/${user.id}/anexos/`);
    names.push(...userFiles.filter((name) => name.includes(prefix)));
  }

  return names;
}

async function buildCleanupPlanFromFirebase({ admin, db, bucket, prefix }) {
  const pedidos = await getDocsByIdPrefix(db, admin, 'pedidos', prefix);
  const usersByRunId = await getDocsBySmokeRunPrefix(db, 'users', prefix);
  const prestadoresByRunId = await getDocsBySmokeRunPrefix(db, 'prestadores', prefix);
  const storageFiles = await getStorageFilesForPlan(bucket, {
    prefix,
    pedidos,
    users: usersByRunId,
  });

  return buildCleanupPlan({
    pedidos,
    users: usersByRunId,
    prestadores: prestadoresByRunId,
    storageFiles,
  });
}

async function cleanupSmokeData(options) {
  validateCleanupOptions(options);
  const admin = requireAdmin();

  if (admin.apps.length === 0) {
    admin.initializeApp({
      projectId: options.projectId,
      storageBucket: options.storageBucket,
    });
  }

  const db = admin.firestore();
  const bucket = admin.storage().bucket(options.storageBucket);
  const plan = await buildCleanupPlanFromFirebase({
    admin,
    db,
    bucket,
    prefix: options.prefix,
  });

  return applyCleanupPlan(plan, {
    deleteFirestorePath: async (docPath) => db.doc(docPath).delete(),
    deleteStorageFile: async (fileName) => {
      try {
        await bucket.file(fileName).delete();
      } catch (error) {
        if (error && error.code === 404) return;
        throw error;
      }
    },
    deleteAuthUsers: async (uids) => {
      for (let i = 0; i < uids.length; i += 1000) {
        await admin.auth().deleteUsers(uids.slice(i, i + 1000));
      }
    },
  }, options);
}

function printHelp() {
  console.log(`Usage:
  node scripts/admin/cleanup_smoke_data.js --prefix=${DEFAULT_PREFIX} --dry-run
  node scripts/admin/cleanup_smoke_data.js --prefix=${DEFAULT_PREFIX} --confirm

Options:
  --prefix <value>   Required smoke prefix or exact smoke run id.
  --dry-run          Default. Print counts only; does not delete.
  --confirm          Required for deletion.
  --project <id>     Firebase project. Default: ${DEFAULT_PROJECT_ID}
  --bucket <name>    Storage bucket. Default: ${DEFAULT_STORAGE_BUCKET}
`);
}

async function main() {
  const options = resolveCleanupOptions();
  if (options.help) {
    printHelp();
    return;
  }

  console.log(`[cleanup_smoke_data] project=${options.projectId} bucket=${options.storageBucket}`);
  console.log(`[cleanup_smoke_data] prefix=${options.prefix} dryRun=${options.dryRun}`);
  const result = await cleanupSmokeData(options);
  console.log(`[cleanup_smoke_data] firestoreDocs=${result.firestoreDocs}`);
  console.log(`[cleanup_smoke_data] storageFiles=${result.storageFiles}`);
  console.log(`[cleanup_smoke_data] authUsers=${result.authUsers}`);
  console.log(`[cleanup_smoke_data] ${result.dryRun ? 'DRY_RUN_ONLY' : 'DELETED'}`);
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[cleanup_smoke_data] FAILED: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  DEFAULT_PREFIX,
  applyCleanupPlan,
  buildCleanupPlan,
  cleanupSmokeData,
  resolveCleanupOptions,
  validateCleanupOptions,
};
