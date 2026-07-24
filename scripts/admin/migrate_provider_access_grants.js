/* eslint-disable no-console */
const crypto = require('crypto');
const path = require('path');

const MIGRATION_VERSION = 'provider-access-grants-v2';
const AUDIT_COLLECTION = 'provider_access_migration_audit';
const POST_ACCEPT_STATES = new Set([
  'aceito',
  'em_andamento',
  'aguarda_confirmacao_valor',
  'concluido',
]);
const PENDING_RELATION_STATES = new Set([
  'aguarda_resposta_prestador',
  'aguarda_resposta_cliente',
]);
const NON_POST_ACCEPT_STATES = new Set([
  'criado',
  ...PENDING_RELATION_STATES,
  'cancelado',
]);
const DERIVABLE_TIMESTAMP_FIELDS = Object.freeze([
  'acceptedAt',
  'aceitoEm',
  'serviceStartedAt',
  'finalValueProposedAt',
  'concluidoEm',
  'completedAt',
  'updatedAt',
]);
const QUOTE_PRICE_MODELS = new Set([
  'por_orcamento',
  'por_proposta',
  'orcamento',
]);
const QUOTE_SERVICE_MODES = new Set([
  'POR_PROPOSTA',
  'POR_ORCAMENTO',
  'ORCAMENTO',
]);
const GRANT_MARKER_FIELDS = Object.freeze([
  'providerAccessGranted',
  'providerAccessGrantedTo',
  'providerAccessGrantedAt',
]);
const INTERNAL_MIGRATION_FIELDS = Object.freeze([
  'providerAccessMigrationResult',
  'providerAccessMigrationReason',
]);

function cleanString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function normalizeState(value) {
  return cleanString(value).toLowerCase();
}

function positiveDate(value) {
  let milliseconds = Number.NaN;
  if (value instanceof Date) {
    milliseconds = value.getTime();
  } else if (typeof value === 'number') {
    milliseconds = value;
  } else if (typeof value === 'string' && value.trim()) {
    milliseconds = Date.parse(value);
  } else if (value && typeof value.toMillis === 'function') {
    milliseconds = Number(value.toMillis());
  } else if (value && typeof value.toDate === 'function') {
    const date = value.toDate();
    milliseconds = date instanceof Date ? date.getTime() : Number.NaN;
  } else if (value && Number.isFinite(Number(value.seconds))) {
    milliseconds = (Number(value.seconds) * 1000)
      + Math.floor(Number(value.nanoseconds || 0) / 1000000);
  }
  return Number.isFinite(milliseconds) && milliseconds > 0
    ? new Date(milliseconds)
    : null;
}

// Existing access markers must contain the type Firestore actually returns:
// a Date from the REST decoder or a Firestore Timestamp-like object. Keep this
// deliberately stricter than positiveDate(), which also accepts legacy values
// solely so an unambiguous historical timestamp can be derived for backfill.
function strictGrantTimestampDate(value) {
  if (value instanceof Date) {
    const milliseconds = value.getTime();
    return Number.isFinite(milliseconds) && milliseconds > 0
      ? new Date(milliseconds)
      : null;
  }
  if (!value || typeof value !== 'object') return null;

  if (typeof value.toMillis === 'function') {
    try {
      const milliseconds = value.toMillis();
      if (typeof milliseconds === 'number'
        && Number.isFinite(milliseconds)
        && milliseconds > 0) {
        return new Date(milliseconds);
      }
    } catch (_) {
      // Fall through to toDate(), matching Timestamp implementations that
      // expose both methods but cannot provide milliseconds directly.
    }
  }

  if (typeof value.toDate === 'function') {
    try {
      const date = value.toDate();
      if (date instanceof Date) {
        const milliseconds = date.getTime();
        if (Number.isFinite(milliseconds) && milliseconds > 0) {
          return new Date(milliseconds);
        }
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}

function deriveGrantTimestamp(data = {}) {
  for (const field of DERIVABLE_TIMESTAMP_FIELDS) {
    const date = positiveDate(data[field]);
    if (date) return { field, date };
  }
  return null;
}

function hasGrantMaterial(data = {}) {
  const flag = data.providerAccessGranted;
  const hasProviderAccessTarget = Object.prototype.hasOwnProperty.call(
    data,
    'providerAccessGrantedTo',
  ) && data.providerAccessGrantedTo !== null
    && data.providerAccessGrantedTo !== undefined;
  return flag === true
    || (flag !== undefined && flag !== null && flag !== false)
    || hasProviderAccessTarget
    || (data.providerAccessGrantedAt !== undefined
      && data.providerAccessGrantedAt !== null);
}

function hasAnyGrantMarkerField(data = {}) {
  return GRANT_MARKER_FIELDS.some((field) => (
    Object.prototype.hasOwnProperty.call(data, field)
  ));
}

function grantIsInternallyValid(data, providerId) {
  return data.providerAccessGranted === true
    && Boolean(providerId)
    && cleanString(data.providerAccessGrantedTo) === providerId
    && Boolean(strictGrantTimestampDate(data.providerAccessGrantedAt));
}

function isQuoteFlow(data = {}) {
  const priceModel = cleanString(data.tipoPreco).toLowerCase();
  const serviceMode = cleanString(data.modo || data.mode).toUpperCase();
  return QUOTE_PRICE_MODELS.has(priceModel)
    || QUOTE_SERVICE_MODES.has(serviceMode);
}

// Match the authoritative runtime predicate in functions/index.js. The
// persisted fields are the canonical valorMin/MaxEstimadoPrestador names;
// transient callable input aliases such as valorMin/valorMax are not evidence
// that a legacy pedido reached the accepted-quote state.
function acceptedQuoteRangeIsValid(data = {}) {
  const min = Number(data.valorMinEstimadoPrestador);
  const max = Number(data.valorMaxEstimadoPrestador);
  return cleanString(data.statusProposta) === 'aceita_cliente'
    && Number.isFinite(min)
    && min > 0
    && Number.isFinite(max)
    && max >= min;
}

function migrationPatch(action, reason, providerId = '', grantedAt = null) {
  if (!cleanString(reason)) {
    throw new Error('Migration classification reason is required.');
  }
  const patch = {
    providerAccessMigrationVersion: MIGRATION_VERSION,
  };
  if (action === 'backfill') {
    return {
      ...patch,
      providerAccessGranted: true,
      providerAccessGrantedTo: providerId,
      providerAccessGrantedAt: grantedAt,
    };
  }
  return {
    ...patch,
    providerAccessGranted: false,
    providerAccessGrantedTo: null,
    providerAccessGrantedAt: null,
  };
}

/**
 * Pure classification for a decoded pedidos document.
 *
 * A legacy order receives a grant only when its business state is
 * unambiguously post-acceptance, it has an explicit prestadorId, no pending
 * invitation/proposal contradiction, and a positive timestamp can be derived.
 */
function classifyProviderAccessGrant(data = {}) {
  const hasStatus = Object.prototype.hasOwnProperty.call(data, 'status');
  const hasEstado = Object.prototype.hasOwnProperty.call(data, 'estado');
  const status = normalizeState(data.status);
  const estado = normalizeState(data.estado);
  const state = status || estado;
  const providerId = cleanString(data.prestadorId);
  const clienteId = cleanString(data.clienteId);
  const clientIdAlias = cleanString(data.clientId);
  const canonicalClientId = clienteId || clientIdAlias;
  const targetProviderId = cleanString(data.targetProviderId);
  const proposalStatus = normalizeState(data.statusProposta);
  const moderationStatusPresent = Object.prototype.hasOwnProperty.call(
    data,
    'moderationStatus',
  );
  const moderationApproved = !moderationStatusPresent
    || data.moderationStatus === 'approved';
  const grantMaterial = hasGrantMaterial(data);
  const validGrant = grantIsInternallyValid(data, providerId);
  const malformedStateAlias = (hasStatus && (!status || typeof data.status !== 'string'))
    || (hasEstado && (!estado || typeof data.estado !== 'string'));
  const stateConflict = Boolean(
    hasStatus && hasEstado && !malformedStateAlias && status !== estado,
  );
  const missingCanonicalPostAcceptStatus = POST_ACCEPT_STATES.has(state) && !status;
  const providerConflict = Boolean(
    providerId && targetProviderId && providerId !== targetProviderId,
  );
  const clientAliasConflict = Boolean(
    clienteId && clientIdAlias && clienteId !== clientIdAlias,
  );
  const clientProviderSelfDealing = Boolean(
    providerId && (providerId === clienteId || providerId === clientIdAlias),
  );
  const pendingRelation = PENDING_RELATION_STATES.has(state)
    || proposalStatus === 'pendente_cliente';
  const eligibleState = POST_ACCEPT_STATES.has(state);
  const quoteFlow = isQuoteFlow(data);
  const inconsistentGrant = grantMaterial && !validGrant
    || validGrant && (
      !eligibleState
      || malformedStateAlias
      || stateConflict
      || missingCanonicalPostAcceptStatus
      || providerConflict
      || pendingRelation
    );

  if (malformedStateAlias) {
    return {
      action: 'quarantine',
      reason: 'invalid_status_estado_alias',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'invalid_status_estado_alias'),
    };
  }

  if (stateConflict) {
    return {
      action: 'quarantine',
      reason: 'status_estado_conflict',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'status_estado_conflict'),
    };
  }

  if (missingCanonicalPostAcceptStatus) {
    return {
      action: 'quarantine',
      reason: 'post_accept_without_canonical_status',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'post_accept_without_canonical_status'),
    };
  }

  if (providerConflict) {
    return {
      action: 'quarantine',
      reason: 'provider_target_conflict',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'provider_target_conflict'),
    };
  }

  if (clientProviderSelfDealing) {
    return {
      action: 'quarantine',
      reason: 'client_provider_self_dealing',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'client_provider_self_dealing'),
    };
  }

  if (clientAliasConflict) {
    return {
      action: 'quarantine',
      reason: 'client_alias_conflict',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'client_alias_conflict'),
    };
  }

  if (eligibleState && pendingRelation) {
    return {
      action: 'quarantine',
      reason: 'post_accept_state_with_pending_relation',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'post_accept_state_with_pending_relation'),
    };
  }

  if (!eligibleState) {
    if (!NON_POST_ACCEPT_STATES.has(state)) {
      return {
        action: 'quarantine',
        reason: state ? 'unknown_legacy_state' : 'missing_state',
        inconsistentGrant,
        patch: migrationPatch(
          'quarantine',
          state ? 'unknown_legacy_state' : 'missing_state',
        ),
      };
    }
    if (!grantMaterial) {
      return {
        action: 'unchanged',
        reason: pendingRelation ? 'pending_relation_without_grant' : 'non_post_accept_without_grant',
        inconsistentGrant: false,
        patch: null,
      };
    }
    return {
      action: 'revoke',
      reason: pendingRelation ? 'pending_relation_must_not_have_grant' : 'non_post_accept_grant',
      inconsistentGrant: true,
      patch: migrationPatch(
        'revoke',
        pendingRelation ? 'pending_relation_must_not_have_grant' : 'non_post_accept_grant',
      ),
    };
  }

  if (!providerId) {
    return {
      action: 'quarantine',
      reason: 'post_accept_without_provider',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'post_accept_without_provider'),
    };
  }

  if (!canonicalClientId) {
    return {
      action: 'quarantine',
      reason: 'post_accept_without_client',
      inconsistentGrant: true,
      patch: migrationPatch('quarantine', 'post_accept_without_client'),
    };
  }

  if (!moderationApproved) {
    return {
      action: 'quarantine',
      reason: 'post_accept_moderation_not_approved',
      inconsistentGrant: true,
      patch: migrationPatch(
        'quarantine',
        'post_accept_moderation_not_approved',
      ),
    };
  }

  if (quoteFlow && proposalStatus !== 'aceita_cliente') {
    return {
      action: 'quarantine',
      reason: 'quote_without_client_acceptance',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'quote_without_client_acceptance'),
    };
  }

  if (quoteFlow && !acceptedQuoteRangeIsValid(data)) {
    return {
      action: 'quarantine',
      reason: 'quote_without_valid_positive_range',
      inconsistentGrant,
      patch: migrationPatch('quarantine', 'quote_without_valid_positive_range'),
    };
  }

  if (validGrant) {
    return {
      action: 'keep',
      reason: 'valid_existing_grant',
      inconsistentGrant: false,
      patch: null,
    };
  }

  // Partial, malformed, or provider-mismatched grants are never repaired into
  // active grants. They require human review after access has been revoked.
  if (grantMaterial || hasAnyGrantMarkerField(data)) {
    const reason = 'inconsistent_existing_grant';
    return {
      action: 'quarantine',
      reason,
      inconsistentGrant: true,
      patch: migrationPatch('quarantine', reason),
    };
  }

  const derived = deriveGrantTimestamp(data);
  if (!derived) {
    return {
      action: 'quarantine',
      reason: 'post_accept_without_positive_timestamp',
      inconsistentGrant: false,
      patch: migrationPatch('quarantine', 'post_accept_without_positive_timestamp'),
    };
  }

  return {
    action: 'backfill',
    reason: `derived_from_${derived.field}`,
    inconsistentGrant: false,
    patch: migrationPatch('backfill', `derived_from_${derived.field}`, providerId, derived.date),
  };
}

function sameValue(left, right) {
  if (left instanceof Date || right instanceof Date) {
    const leftDate = positiveDate(left);
    const rightDate = positiveDate(right);
    return Boolean(leftDate && rightDate && leftDate.getTime() === rightDate.getTime());
  }
  return left === right;
}

function patchChangesData(data, patch) {
  if (!patch) return false;
  return Object.entries(patch).some(([key, value]) => !sameValue(data[key], value));
}

function auditDocumentId(pedidoId) {
  return `${pedidoId}__${MIGRATION_VERSION}`;
}

function buildMigrationPlan(records = []) {
  const counts = {
    scanned: records.length,
    keep: 0,
    backfill: 0,
    revoke: 0,
    quarantine: 0,
    unchanged: 0,
    inconsistentGrants: 0,
    writesPlanned: 0,
  };
  const reasons = {};
  const writes = [];
  for (const record of records) {
    const classification = classifyProviderAccessGrant(record.data || {});
    counts[classification.action] += 1;
    if (classification.inconsistentGrant) counts.inconsistentGrants += 1;
    reasons[classification.reason] = (reasons[classification.reason] || 0) + 1;
    const deleteFields = INTERNAL_MIGRATION_FIELDS.filter((field) => (
      Object.prototype.hasOwnProperty.call(record.data || {}, field)
    ));
    let patch = classification.patch;
    if (!patch && deleteFields.length > 0) {
      patch = { providerAccessMigrationVersion: MIGRATION_VERSION };
    }
    if (patchChangesData(record.data || {}, patch) || deleteFields.length > 0) {
      writes.push({
        id: record.id,
        updateTime: record.updateTime,
        patch,
        deleteFields,
        audit: {
          id: auditDocumentId(record.id),
          fields: {
            pedidoId: record.id,
            migrationVersion: MIGRATION_VERSION,
            action: classification.action,
            reason: classification.reason,
            sourceUpdateTime: cleanString(record.updateTime),
            internalMetadataRemoved: deleteFields.length > 0,
          },
        },
      });
    }
  }
  counts.writesPlanned = writes.length;
  return { counts, reasons, writes };
}

function buildReconciliationEvidence(plan, {
  executed,
  dryRun,
  afterPlan = plan,
  execution = null,
} = {}) {
  const evidence = {
    schemaVersion: 'pedido-grant-reconciliation-v1',
    executed: executed === true,
    dryRun: dryRun !== false,
    scanned: plan.counts.scanned,
    collectionTotalObserved: plan.counts.scanned,
    backfilled: plan.counts.backfill,
    revoked: plan.counts.revoke,
    unchanged: plan.counts.keep + plan.counts.unchanged,
    manualReview: plan.counts.quarantine,
    inconsistentAfter: Number(afterPlan.counts.inconsistentGrants || 0)
      + Number(afterPlan.counts.writesPlanned || 0),
    deletesPerformed: 0,
  };
  // The digest binds the readiness evidence to the redacted, deterministic
  // execution summary without exposing pedido IDs or participant data.
  const redactedExecutionOutput = {
    migrationVersion: MIGRATION_VERSION,
    auditCollection: AUDIT_COLLECTION,
    beforeCounts: plan.counts,
    afterCounts: afterPlan.counts,
    execution,
    reconciliation: evidence,
  };
  return {
    ...evidence,
    executionOutputSha256: crypto
      .createHash('sha256')
      .update(JSON.stringify(redactedExecutionOutput))
      .digest('hex'),
  };
}

function resolveOptions(argv = process.argv.slice(2)) {
  const options = {
    projectId: '',
    confirmProject: '',
    confirm: false,
    dryRun: true,
    limit: null,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--help' || arg === '-h') options.help = true;
    else if (arg === '--dry-run') {
      options.confirm = false;
      options.dryRun = true;
    } else if (arg === '--confirm') {
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
    } else if (arg === '--limit') {
      options.limit = Number(argv[++index]);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  if (!options.help) validateOptions(options);
  return options;
}

function validateOptions(options) {
  if (!cleanString(options.projectId)) {
    throw new Error('--project is required, including for dry-run.');
  }
  if (options.limit !== null
    && (!Number.isInteger(options.limit) || options.limit < 1)) {
    throw new Error('--limit must be a positive integer.');
  }
  if (options.confirm && options.confirmProject !== options.projectId) {
    throw new Error('--confirm-project must match --project exactly.');
  }
  if (options.confirm && options.limit !== null) {
    throw new Error('--limit is forbidden with --confirm; cutover reconciliation must scan all pedidos.');
  }
  if (!options.confirm && options.confirmProject) {
    throw new Error('--confirm-project is only valid together with --confirm.');
  }
}

function decodeFirestoreValue(value) {
  if (!value || typeof value !== 'object') return null;
  if (Object.prototype.hasOwnProperty.call(value, 'nullValue')) return null;
  if (Object.prototype.hasOwnProperty.call(value, 'booleanValue')) return value.booleanValue;
  if (Object.prototype.hasOwnProperty.call(value, 'stringValue')) return value.stringValue;
  if (Object.prototype.hasOwnProperty.call(value, 'integerValue')) {
    return Number(value.integerValue);
  }
  if (Object.prototype.hasOwnProperty.call(value, 'doubleValue')) return value.doubleValue;
  if (Object.prototype.hasOwnProperty.call(value, 'timestampValue')) {
    return new Date(value.timestampValue);
  }
  if (value.arrayValue) {
    return (value.arrayValue.values || []).map(decodeFirestoreValue);
  }
  if (value.mapValue) return decodeFirestoreFields(value.mapValue.fields || {});
  return null;
}

function decodeFirestoreFields(fields = {}) {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, decodeFirestoreValue(value)]),
  );
}

function encodePatchValue(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'string') return { stringValue: value };
  if (value instanceof Date && positiveDate(value)) {
    return { timestampValue: value.toISOString() };
  }
  throw new Error(`Unsupported migration patch value: ${String(value)}`);
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

function documentId(document) {
  return decodeURIComponent(document.name.split('/').pop());
}

async function readPedidos(client, projectId, limit) {
  const documents = [];
  let pageToken = '';
  do {
    const remaining = limit ? limit - documents.length : 1000;
    if (remaining <= 0) break;
    const response = await client.get(
      `/projects/${projectId}/databases/(default)/documents/pedidos`,
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
  return documents.map((document) => ({
    id: documentId(document),
    updateTime: document.updateTime,
    data: decodeFirestoreFields(document.fields || {}),
  }));
}

async function commitWrites(client, projectId, writes) {
  const database = `projects/${projectId}/databases/(default)`;
  for (const write of writes) {
    const updateTime = cleanString(write.updateTime);
    if (!updateTime || !Number.isFinite(Date.parse(updateTime))) {
      throw new Error(
        `Missing or invalid Firestore updateTime precondition for pedido ${write.id}.`,
      );
    }
    if (!write.audit || !cleanString(write.audit.id) || !write.audit.fields) {
      throw new Error(`Missing deterministic audit record for pedido ${write.id}.`);
    }
  }
  let batchesCommitted = 0;
  // Each logical migration produces two atomic Firestore writes: the pedido
  // patch plus an immutable audit record. Keep commits below the 500-write
  // Firestore limit while preserving the pedido/audit pair in one commit.
  for (let start = 0; start < writes.length; start += 200) {
    const batch = writes.slice(start, start + 200).flatMap(({
      id,
      updateTime,
      patch,
      deleteFields = [],
      audit,
    }) => ([
      {
        update: {
          name: `${database}/documents/pedidos/${encodeURIComponent(id)}`,
          fields: Object.fromEntries(
            Object.entries(patch).map(([key, value]) => [key, encodePatchValue(value)]),
          ),
        },
        // A field path present in the mask but absent from fields is deleted.
        // This removes internal reasons written by the superseded v1 script.
        updateMask: {
          fieldPaths: [...new Set([...Object.keys(patch), ...deleteFields])],
        },
        currentDocument: { updateTime },
      },
      {
        update: {
          name: `${database}/documents/${AUDIT_COLLECTION}/${encodeURIComponent(audit.id)}`,
          fields: Object.fromEntries(
            Object.entries(audit.fields).map(([key, value]) => [key, encodePatchValue(value)]),
          ),
        },
        updateMask: { fieldPaths: Object.keys(audit.fields) },
        // Deterministic pedido/version audit records are immutable. A rerun
        // must fail closed rather than overwrite an earlier security decision.
        currentDocument: { exists: false },
      },
    ]));
    await client.post(`/${database}/documents:commit`, { writes: batch });
    batchesCommitted += 1;
  }
  return {
    writesCommitted: writes.length,
    auditWritesCommitted: writes.length,
    batchesCommitted,
  };
}

async function migrate(options) {
  const client = await firestoreRestClient(options.projectId);
  const records = await readPedidos(client, options.projectId, options.limit);
  const plan = buildMigrationPlan(records);
  let afterPlan = plan;
  let execution = null;
  if (options.confirm) {
    execution = await commitWrites(client, options.projectId, plan.writes);
    const afterRecords = await readPedidos(client, options.projectId, options.limit);
    afterPlan = buildMigrationPlan(afterRecords);
  }
  const summary = {
    projectId: options.projectId,
    dryRun: options.dryRun,
    collection: 'pedidos',
    auditCollection: AUDIT_COLLECTION,
    migrationVersion: MIGRATION_VERSION,
    documentIdsIncluded: false,
    ...plan.counts,
    reasons: plan.reasons,
    pedidoGrantReconciliation: buildReconciliationEvidence(plan, {
      executed: options.confirm,
      dryRun: options.dryRun,
      afterPlan,
      execution,
    }),
  };
  if (execution) summary.executed = execution;
  return summary;
}

function printHelp() {
  console.log(`Usage:
  node scripts/admin/migrate_provider_access_grants.js --project=PROJECT_ID --dry-run
  node scripts/admin/migrate_provider_access_grants.js --project=PROJECT_ID --confirm --confirm-project=PROJECT_ID

Dry-run is the default. Only unambiguous post-acceptance pedidos can receive a
grant. Pending invitations/proposals and inconsistent records are revoked or
quarantined. Confirm writes grant patches in batches, removes superseded
internal reason fields from pedidos, and creates immutable admin-only audit
records. It never deletes documents.`);
}

async function main() {
  const options = resolveOptions();
  if (options.help) return printHelp();
  const summary = await migrate(options);
  console.log(JSON.stringify(summary, null, 2));
  console.log(options.confirm ? 'PROVIDER_ACCESS_MIGRATION_WRITTEN' : 'DRY_RUN_ONLY');
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[migrate_provider_access_grants] FAILED: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  AUDIT_COLLECTION,
  DERIVABLE_TIMESTAMP_FIELDS,
  MIGRATION_VERSION,
  NON_POST_ACCEPT_STATES,
  POST_ACCEPT_STATES,
  acceptedQuoteRangeIsValid,
  auditDocumentId,
  buildReconciliationEvidence,
  buildMigrationPlan,
  classifyProviderAccessGrant,
  commitWrites,
  decodeFirestoreFields,
  deriveGrantTimestamp,
  isQuoteFlow,
  positiveDate,
  readPedidos,
  resolveOptions,
  strictGrantTimestampDate,
  validateOptions,
};
