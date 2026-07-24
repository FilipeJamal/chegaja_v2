/* eslint-disable no-console */
const crypto = require('crypto');
const path = require('path');

const RECONCILIATION_VERSION = 'pedido-dispatch-reconciliation-v1';
const SERVER_TIMESTAMP = Object.freeze({ __operation: 'server_timestamp' });
const OPEN_STATUS = 'criado';
const TARGETED_STATUSES = new Set([
  'aguarda_resposta_prestador',
  'aguarda_resposta_cliente',
]);
const ALLOWED_DISPATCH_FIELDS = Object.freeze([
  'pedidoId',
  'servicoId',
  'servicoNome',
  'categoria',
  'modo',
  'agendadoPara',
  'tipoPreco',
  'estado',
  'status',
  'prestadorId',
  'targetProviderId',
  'valorMinEstimadoPrestador',
  'valorMaxEstimadoPrestador',
  'statusProposta',
  'propostaExpiresAt',
  'zoneLabel',
  'enderecoTexto',
  'latitude',
  'longitude',
  'categoryApprovalRequired',
  'categoryRequirementId',
  'categoryRequirementName',
  'categoryRiskLevel',
  'isCustomService',
  'createdAt',
  'updatedAt',
]);

function cleanString(value) {
  return (value || '').toString().trim();
}

function safeText(value, maxLength = 120) {
  const text = cleanString(value);
  if (text.length <= maxLength) return text;
  return `${text.slice(0, Math.max(0, maxLength - 3))}...`;
}

function normalizeSafetyText(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/0/g, 'o')
    .replace(/1/g, 'i')
    .replace(/3/g, 'e')
    .replace(/4/g, 'a')
    .replace(/5/g, 's')
    .replace(/7/g, 't')
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function sanitizeDispatchText(value, maxLength = 500) {
  return safeText(value, maxLength)
    .replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[contacto removido]')
    .replace(/(?:https?:\/\/|www\.)\S+/gi, '[link removido]')
    .replace(/(?:\+|00)?\d(?:[\s().-]*\d){6,}/g, '[contacto removido]')
    .replace(/\b-?\d{1,2}\.\d{4,}\s*[,;]\s*-?\d{1,3}\.\d{4,}\b/g, '[localizacao removida]')
    .trim();
}

function sanitizeDispatchZone(value) {
  const parts = String(value || '')
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean)
    .filter((part) => {
      const normalized = normalizeSafetyText(part);
      const digits = part.replace(/\D/g, '');
      const looksLikeContact = /[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/.test(part)
        || /(?:258)?8[2-7]\d{7}/.test(digits)
        || /(?:https?:\/\/|www\.)\S+/i.test(part);
      const looksLikeAddress = /\b(rua|avenida|av|travessa|estrada|alameda|casa|porta|apartamento|apt|bloco|lote|talhao|quarteirao|edificio|predio|andar|numero|referencia|perto|frente|lado)\b/.test(
        normalized,
      );
      return !looksLikeContact && !looksLikeAddress && !/\d{3,}/.test(part);
    });
  const candidates = parts.slice(-2)
    .map((part) => part.replace(/\b\d+[A-Za-z-]*\b/g, '').trim());
  const zone = candidates.filter(Boolean).join(', ');
  return sanitizeDispatchText(zone || 'Zona aproximada', 120);
}

function approximateCoordinate(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return null;
  return Math.round(number * 100) / 100;
}

function normalizedDispatchMode(value) {
  const mode = cleanString(value || 'IMEDIATO').toUpperCase();
  return ['IMEDIATO', 'AGENDADO', 'POR_PROPOSTA'].includes(mode) ? mode : 'IMEDIATO';
}

function normalizedDispatchPriceModel(value) {
  const model = cleanString(value || 'a_combinar').toLowerCase();
  return ['a_combinar', 'fixo', 'por_hora', 'por_orcamento', 'por_tarefa'].includes(model)
    ? model
    : 'a_combinar';
}

function getCanonicalPedidoStatus(pedido = {}) {
  const hasStatus = Object.prototype.hasOwnProperty.call(pedido, 'status');
  const hasEstado = Object.prototype.hasOwnProperty.call(pedido, 'estado');
  if (!hasStatus || typeof pedido.status !== 'string') return '';
  const status = pedido.status.trim();
  if (!status) return '';
  if (hasEstado
    && (typeof pedido.estado !== 'string' || pedido.estado.trim() !== status)) {
    return '';
  }
  return status;
}

function dispatchZoneSource(pedido = {}) {
  const explicitZone = cleanString(pedido.dispatchZone || pedido.zone);
  if (explicitZone) return explicitZone;
  const district = cleanString(pedido.bairro);
  const city = cleanString(pedido.city);
  if (district && city && normalizeSafetyText(district) !== normalizeSafetyText(city)) {
    return `${district}, ${city}`;
  }
  return district || city;
}

// Keep this deterministic contract in lockstep with functions/index.js
// buildPedidoDispatchProjection. The two server timestamps are represented by
// a local sentinel and converted to Firestore REQUEST_TIME transforms at write.
function buildPedidoDispatchProjection(pedidoId, pedido = {}) {
  const latitude = approximateCoordinate(
    pedido.latitude ?? pedido.geo?.geopoint?.latitude,
  );
  const longitude = approximateCoordinate(
    pedido.longitude ?? pedido.geo?.geopoint?.longitude,
  );
  const zoneLabel = sanitizeDispatchZone(dispatchZoneSource(pedido));
  const mode = normalizedDispatchMode(pedido.modo);
  const status = getCanonicalPedidoStatus(pedido) || OPEN_STATUS;
  const serviceLabel = pedido.isCustomService === true
    ? 'Serviço personalizado'
    : sanitizeDispatchText(pedido.servicoNome || pedido.categoria, 160);
  const targetProviderId = TARGETED_STATUSES.has(status)
    ? cleanString(pedido.prestadorId)
    : '';
  return {
    pedidoId,
    servicoId: safeText(pedido.servicoId, 120),
    servicoNome: serviceLabel,
    categoria: serviceLabel,
    modo: mode,
    agendadoPara: mode === 'AGENDADO' ? (pedido.agendadoPara || null) : null,
    tipoPreco: normalizedDispatchPriceModel(pedido.tipoPreco),
    estado: status,
    status,
    prestadorId: null,
    targetProviderId: targetProviderId || null,
    valorMinEstimadoPrestador: targetProviderId
      && Number.isFinite(Number(pedido.valorMinEstimadoPrestador))
      ? Number(pedido.valorMinEstimadoPrestador)
      : null,
    valorMaxEstimadoPrestador: targetProviderId
      && Number.isFinite(Number(pedido.valorMaxEstimadoPrestador))
      ? Number(pedido.valorMaxEstimadoPrestador)
      : null,
    statusProposta: targetProviderId ? safeText(pedido.statusProposta, 40) : 'nenhuma',
    propostaExpiresAt: targetProviderId ? (pedido.propostaExpiresAt || null) : null,
    zoneLabel,
    enderecoTexto: zoneLabel,
    latitude,
    longitude,
    categoryApprovalRequired: pedido.categoryApprovalRequired === true,
    categoryRequirementId: safeText(pedido.categoryRequirementId, 120),
    categoryRequirementName: sanitizeDispatchText(pedido.categoryRequirementName, 160),
    categoryRiskLevel: safeText(pedido.categoryRiskLevel, 40),
    isCustomService: pedido.isCustomService === true,
    createdAt: pedido.createdAt || SERVER_TIMESTAMP,
    updatedAt: SERVER_TIMESTAMP,
  };
}

function isOpenPedido(pedido = {}) {
  return getCanonicalPedidoStatus(pedido) === OPEN_STATUS
    && !cleanString(pedido.prestadorId)
    && cleanString(pedido.moderationStatus || 'approved') === 'approved';
}

function isTargetedDispatchPedido(pedido = {}) {
  return TARGETED_STATUSES.has(getCanonicalPedidoStatus(pedido))
    && !!cleanString(pedido.prestadorId)
    && cleanString(pedido.moderationStatus || 'approved') === 'approved';
}

function timestampMilliseconds(value) {
  if (value instanceof Date) return value.getTime();
  if (value && typeof value.toMillis === 'function') {
    try {
      return Number(value.toMillis());
    } catch (_) {
      return Number.NaN;
    }
  }
  if (value && typeof value.toDate === 'function') {
    try {
      const date = value.toDate();
      return date instanceof Date ? date.getTime() : Number.NaN;
    } catch (_) {
      return Number.NaN;
    }
  }
  return Number.NaN;
}

function isPositiveTimestamp(value) {
  const milliseconds = timestampMilliseconds(value);
  return Number.isFinite(milliseconds) && milliseconds > 0;
}

function canonicalComparable(value) {
  if (value instanceof Date) return { __timestamp: value.toISOString() };
  if (value && typeof value.toMillis === 'function') {
    const milliseconds = timestampMilliseconds(value);
    return Number.isFinite(milliseconds)
      ? { __timestamp: new Date(milliseconds).toISOString() }
      : null;
  }
  if (Array.isArray(value)) return value.map(canonicalComparable);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).sort().map(
      (key) => [key, canonicalComparable(value[key])],
    ));
  }
  return value;
}

function dispatchMatchesProjection(dispatch, projection) {
  if (!dispatch || typeof dispatch !== 'object') return false;
  if (Object.keys(dispatch).length !== ALLOWED_DISPATCH_FIELDS.length) return false;
  if (Object.keys(dispatch).some((field) => !ALLOWED_DISPATCH_FIELDS.includes(field))) {
    return false;
  }
  for (const field of ALLOWED_DISPATCH_FIELDS) {
    if (!Object.prototype.hasOwnProperty.call(dispatch, field)) return false;
    const expected = projection[field];
    const actual = dispatch[field];
    if (field === 'updatedAt') {
      if (!isPositiveTimestamp(actual)) return false;
      continue;
    }
    if (expected === SERVER_TIMESTAMP) {
      if (!isPositiveTimestamp(actual)) return false;
      continue;
    }
    if (JSON.stringify(canonicalComparable(actual))
      !== JSON.stringify(canonicalComparable(expected))) {
      return false;
    }
  }
  return true;
}

function emptyPlanCounts() {
  return {
    pedidosScanned: 0,
    dispatchScanned: 0,
    eligibleOpen: 0,
    eligibleTargeted: 0,
    upserts: 0,
    deletesTerminalOrStale: 0,
    deletesOrphan: 0,
    unchanged: 0,
    inconsistencies: 0,
  };
}

function buildReconciliationPlan(pedidos = [], dispatchDocuments = []) {
  const counts = emptyPlanCounts();
  counts.pedidosScanned = pedidos.length;
  counts.dispatchScanned = dispatchDocuments.length;
  const pedidoById = new Map(pedidos.map((pedido) => [pedido.id, pedido]));
  const dispatchById = new Map(dispatchDocuments.map((dispatch) => [dispatch.id, dispatch]));
  const eligibleIds = new Set();
  const mutations = [];

  for (const pedido of pedidos) {
    const data = pedido.data || {};
    const open = isOpenPedido(data);
    const targeted = isTargetedDispatchPedido(data);
    if (!open && !targeted) continue;
    eligibleIds.add(pedido.id);
    if (open) counts.eligibleOpen += 1;
    if (targeted) counts.eligibleTargeted += 1;
    const projection = buildPedidoDispatchProjection(pedido.id, data);
    const currentDispatch = dispatchById.get(pedido.id);
    if (currentDispatch
      && dispatchMatchesProjection(currentDispatch.data || {}, projection)) {
      counts.unchanged += 1;
      continue;
    }
    counts.upserts += 1;
    mutations.push({
      action: 'upsert',
      reason: currentDispatch ? 'projection_mismatch' : 'projection_missing',
      pedidoId: pedido.id,
      sourceUpdateTime: pedido.updateTime,
      dispatchExists: !!currentDispatch,
      dispatchUpdateTime: currentDispatch?.updateTime || '',
      projection,
    });
  }

  for (const dispatch of dispatchDocuments) {
    if (eligibleIds.has(dispatch.id)) continue;
    const pedido = pedidoById.get(dispatch.id);
    const reason = pedido ? 'terminal_or_stale' : 'orphan';
    if (pedido) counts.deletesTerminalOrStale += 1;
    else counts.deletesOrphan += 1;
    mutations.push({
      action: 'delete',
      reason,
      pedidoId: dispatch.id,
      sourceExists: !!pedido,
      sourceUpdateTime: pedido?.updateTime || '',
      dispatchUpdateTime: dispatch.updateTime,
    });
  }

  counts.inconsistencies = counts.upserts
    + counts.deletesTerminalOrStale
    + counts.deletesOrphan;
  return { counts, mutations };
}

function decodeFirestoreValue(value) {
  if (!value || typeof value !== 'object') return null;
  if (Object.prototype.hasOwnProperty.call(value, 'nullValue')) return null;
  if (Object.prototype.hasOwnProperty.call(value, 'booleanValue')) return value.booleanValue;
  if (Object.prototype.hasOwnProperty.call(value, 'stringValue')) return value.stringValue;
  if (Object.prototype.hasOwnProperty.call(value, 'integerValue')) {
    return Number(value.integerValue);
  }
  if (Object.prototype.hasOwnProperty.call(value, 'doubleValue')) return Number(value.doubleValue);
  if (Object.prototype.hasOwnProperty.call(value, 'timestampValue')) {
    return new Date(value.timestampValue);
  }
  if (Object.prototype.hasOwnProperty.call(value, 'geoPointValue')) {
    return {
      latitude: Number(value.geoPointValue.latitude),
      longitude: Number(value.geoPointValue.longitude),
    };
  }
  if (value.arrayValue) {
    return (value.arrayValue.values || []).map(decodeFirestoreValue);
  }
  if (value.mapValue) return decodeFirestoreFields(value.mapValue.fields || {});
  return null;
}

function decodeFirestoreFields(fields = {}) {
  return Object.fromEntries(
    Object.entries(fields).map(([field, value]) => [field, decodeFirestoreValue(value)]),
  );
}

function encodeFirestoreValue(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (value instanceof Date && isPositiveTimestamp(value)) {
    return { timestampValue: value.toISOString() };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(encodeFirestoreValue) } };
  }
  if (value && typeof value === 'object' && value !== SERVER_TIMESTAMP) {
    return {
      mapValue: {
        fields: Object.fromEntries(
          Object.entries(value).map(([field, item]) => [field, encodeFirestoreValue(item)]),
        ),
      },
    };
  }
  throw new Error(`Unsupported pedido_dispatch value: ${String(value)}`);
}

function documentId(document) {
  return decodeURIComponent(cleanString(document.name).split('/').pop());
}

async function readCollection(client, projectId, collectionId, { pageSize = 500 } = {}) {
  if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 1000) {
    throw new Error('pageSize must be an integer between 1 and 1000.');
  }
  const documents = [];
  const seenPageTokens = new Set();
  let pageToken = '';
  do {
    if (pageToken && seenPageTokens.has(pageToken)) {
      throw new Error(`Firestore repeated a page token while reading ${collectionId}.`);
    }
    if (pageToken) seenPageTokens.add(pageToken);
    const response = await client.get(
      `/projects/${projectId}/databases/(default)/documents/${collectionId}`,
      {
        queryParams: {
          pageSize,
          orderBy: '__name__',
          ...(pageToken ? { pageToken } : {}),
        },
      },
    );
    documents.push(...(response.body.documents || []));
    pageToken = response.body.nextPageToken || '';
  } while (pageToken);
  return documents.map((document) => ({
    id: documentId(document),
    updateTime: cleanString(document.updateTime),
    data: decodeFirestoreFields(document.fields || {}),
  }));
}

async function readReconciliationState(client, projectId, { pageSize = 500 } = {}) {
  const [pedidos, dispatchDocuments] = await Promise.all([
    readCollection(client, projectId, 'pedidos', { pageSize }),
    readCollection(client, projectId, 'pedido_dispatch', { pageSize }),
  ]);
  return { pedidos, dispatchDocuments };
}

function validUpdateTime(value) {
  const text = cleanString(value);
  return text && Number.isFinite(Date.parse(text));
}

function documentName(database, collection, id) {
  return `${database}/documents/${collection}/${encodeURIComponent(id)}`;
}

function buildProjectionWrite(database, mutation) {
  const fields = {};
  const updateTransforms = [];
  for (const [field, value] of Object.entries(mutation.projection)) {
    if (value === SERVER_TIMESTAMP) {
      updateTransforms.push({
        fieldPath: field,
        setToServerValue: 'REQUEST_TIME',
      });
    } else {
      fields[field] = encodeFirestoreValue(value);
    }
  }
  return {
    update: {
      name: documentName(database, 'pedido_dispatch', mutation.pedidoId),
      fields,
    },
    updateTransforms,
    currentDocument: mutation.dispatchExists
      ? { updateTime: mutation.dispatchUpdateTime }
      : { exists: false },
  };
}

function writesForMutation(database, mutation) {
  if (mutation.action === 'upsert'
    && mutation.dispatchExists
    && !validUpdateTime(mutation.dispatchUpdateTime)) {
    throw new Error('Missing or invalid existing pedido_dispatch updateTime precondition.');
  }
  if (mutation.action === 'delete' && !validUpdateTime(mutation.dispatchUpdateTime)) {
    throw new Error('Missing or invalid pedido_dispatch delete updateTime precondition.');
  }
  if (mutation.action === 'upsert') {
    return [buildProjectionWrite(database, mutation)];
  }
  if (mutation.action === 'delete') {
    return [
      {
        delete: documentName(database, 'pedido_dispatch', mutation.pedidoId),
        currentDocument: { updateTime: mutation.dispatchUpdateTime },
      },
    ];
  }
  throw new Error(`Unsupported reconciliation action: ${mutation.action}`);
}

function responseBody(response) {
  return response?.body || response || {};
}

function isNotFoundError(error) {
  return Number(error?.status) === 404
    || Number(error?.statusCode) === 404
    || Number(error?.context?.response?.statusCode) === 404
    || Number(error?.context?.response?.status) === 404;
}

async function beginReadWriteTransaction(client, database) {
  const response = await client.post(`/${database}/documents:beginTransaction`, {
    options: { readWrite: {} },
  });
  const transaction = cleanString(responseBody(response).transaction);
  if (!transaction) throw new Error('Firestore did not return a transaction token.');
  return transaction;
}

async function rollbackTransaction(client, database, transaction) {
  if (!cleanString(transaction)) return;
  await client.post(`/${database}/documents:rollback`, { transaction });
}

async function readDocumentInTransaction(
  client,
  database,
  collection,
  id,
  transaction,
) {
  try {
    const response = await client.get(
      `/${documentName(database, collection, id)}`,
      { queryParams: { transaction } },
    );
    const document = responseBody(response);
    return {
      id,
      updateTime: cleanString(document.updateTime),
      data: decodeFirestoreFields(document.fields || {}),
    };
  } catch (error) {
    if (isNotFoundError(error)) return null;
    throw error;
  }
}

function currentMutationForDocuments(pedidoId, pedido, dispatch) {
  const source = pedido?.data || null;
  if (source && (isOpenPedido(source) || isTargetedDispatchPedido(source))) {
    const projection = buildPedidoDispatchProjection(pedidoId, source);
    if (dispatch && dispatchMatchesProjection(dispatch.data || {}, projection)) return null;
    return {
      action: 'upsert',
      reason: dispatch ? 'projection_mismatch' : 'projection_missing',
      pedidoId,
      dispatchExists: !!dispatch,
      dispatchUpdateTime: dispatch?.updateTime || '',
      projection,
    };
  }
  if (!dispatch) return null;
  return {
    action: 'delete',
    reason: pedido ? 'terminal_or_stale' : 'orphan',
    pedidoId,
    dispatchUpdateTime: dispatch.updateTime,
  };
}

async function readMutationInTransaction(client, database, mutation, transaction) {
  const [pedido, dispatch] = await Promise.all([
    readDocumentInTransaction(
      client,
      database,
      'pedidos',
      mutation.pedidoId,
      transaction,
    ),
    readDocumentInTransaction(
      client,
      database,
      'pedido_dispatch',
      mutation.pedidoId,
      transaction,
    ),
  ]);
  return currentMutationForDocuments(mutation.pedidoId, pedido, dispatch);
}

async function commitReconciliationPlan(client, projectId, plan, { batchSize = 50 } = {}) {
  if (!Number.isInteger(batchSize) || batchSize < 1 || batchSize > 250) {
    throw new Error('batchSize must be an integer between 1 and 250.');
  }
  const database = `projects/${projectId}/databases/(default)`;
  let batchesCommitted = 0;
  let mutationsCommitted = 0;
  let upsertsCommitted = 0;
  let deletesCommitted = 0;
  let deletesTerminalOrStaleCommitted = 0;
  let deletesOrphanCommitted = 0;
  for (let start = 0; start < plan.mutations.length; start += batchSize) {
    const batch = plan.mutations.slice(start, start + batchSize);
    const transaction = await beginReadWriteTransaction(client, database);
    let transactionFinished = false;
    try {
      // Every source pedido and target projection is re-read inside the same
      // read-write transaction. Firestore aborts commit if any read document
      // changes, closing the race between the global scan and this batch.
      const currentMutations = (await Promise.all(batch.map(
        (mutation) => readMutationInTransaction(
          client,
          database,
          mutation,
          transaction,
        ),
      ))).filter(Boolean);
      const writes = currentMutations.flatMap(
        (mutation) => writesForMutation(database, mutation),
      );
      if (writes.length === 0) {
        await rollbackTransaction(client, database, transaction);
        transactionFinished = true;
        continue;
      }
      await client.post(`/${database}/documents:commit`, { writes, transaction });
      transactionFinished = true;
      batchesCommitted += 1;
      mutationsCommitted += currentMutations.length;
      upsertsCommitted += currentMutations.filter(({ action }) => action === 'upsert').length;
      deletesCommitted += currentMutations.filter(({ action }) => action === 'delete').length;
      deletesTerminalOrStaleCommitted += currentMutations.filter(
        ({ action, reason }) => action === 'delete' && reason === 'terminal_or_stale',
      ).length;
      deletesOrphanCommitted += currentMutations.filter(
        ({ action, reason }) => action === 'delete' && reason === 'orphan',
      ).length;
    } catch (error) {
      if (!transactionFinished) {
        try {
          await rollbackTransaction(client, database, transaction);
        } catch (_) {
          // The original transaction/commit error is the actionable failure.
        }
      }
      throw error;
    }
  }
  return {
    batchesCommitted,
    mutationsCommitted,
    upsertsCommitted,
    deletesCommitted,
    deletesTerminalOrStaleCommitted,
    deletesOrphanCommitted,
  };
}

function canonicalJson(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(',')}]`;
  if (value && typeof value === 'object') {
    return `{${Object.keys(value).sort().map(
      (key) => `${JSON.stringify(key)}:${canonicalJson(value[key])}`,
    ).join(',')}}`;
  }
  return JSON.stringify(value);
}

function buildReconciliationEvidence(plan, {
  executed,
  dryRun,
  afterPlan = plan,
  execution = null,
} = {}) {
  const evidence = {
    schemaVersion: RECONCILIATION_VERSION,
    hashAlgorithm: 'sha256-canonical-json-v1',
    executed: executed === true,
    dryRun: dryRun !== false,
    documentIdsIncluded: false,
    scanned: Number(plan.counts.pedidosScanned || 0),
    collectionTotalObserved: Number(plan.counts.pedidosScanned || 0),
    dispatchScanned: Number(plan.counts.dispatchScanned || 0),
    eligibleOpen: Number(plan.counts.eligibleOpen || 0),
    eligibleTargeted: Number(plan.counts.eligibleTargeted || 0),
    upserted: executed === true
      ? Number(execution?.upsertsCommitted ?? plan.counts.upserts ?? 0)
      : 0,
    deletedTerminalOrStale: executed === true
      ? Number(
        execution?.deletesTerminalOrStaleCommitted
        ?? plan.counts.deletesTerminalOrStale
        ?? 0,
      )
      : 0,
    deletedOrphan: executed === true
      ? Number(execution?.deletesOrphanCommitted ?? plan.counts.deletesOrphan ?? 0)
      : 0,
    unchanged: Number(plan.counts.unchanged || 0),
    inconsistentBefore: Number(plan.counts.inconsistencies || 0),
    inconsistentAfter: Number(afterPlan.counts.inconsistencies || 0),
  };
  const redactedExecutionOutput = {
    reconciliationVersion: RECONCILIATION_VERSION,
    beforeCounts: plan.counts,
    afterCounts: afterPlan.counts,
    execution,
    evidence,
  };
  return {
    ...evidence,
    executionOutputSha256: crypto
      .createHash('sha256')
      .update(canonicalJson(redactedExecutionOutput))
      .digest('hex'),
  };
}

function resolveOptions(argv = process.argv.slice(2)) {
  const options = {
    projectId: '',
    confirmProject: '',
    confirm: false,
    dryRun: true,
    pageSize: 500,
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
    } else if (arg.startsWith('--page-size=')) {
      options.pageSize = Number(arg.slice('--page-size='.length));
    } else if (arg === '--page-size') {
      options.pageSize = Number(argv[++index]);
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
  if (!Number.isInteger(options.pageSize) || options.pageSize < 1 || options.pageSize > 1000) {
    throw new Error('--page-size must be an integer between 1 and 1000.');
  }
  if (options.confirm && options.confirmProject !== options.projectId) {
    throw new Error('--confirm-project must match --project exactly.');
  }
  if (!options.confirm && cleanString(options.confirmProject)) {
    throw new Error('--confirm-project is only valid together with --confirm.');
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
  if (!account) throw new Error('Run firebase login before the reconciliation.');
  await requireAuth({ project: projectId, nonInteractive: true, ...account });
  return new Client({ urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1' });
}

async function reconcileWithClient(client, options, dependencies = {}) {
  validateOptions(options);
  const readState = dependencies.readState || readReconciliationState;
  const buildPlan = dependencies.buildPlan || buildReconciliationPlan;
  const commitPlan = dependencies.commitPlan || commitReconciliationPlan;
  const beforeState = await readState(client, options.projectId, {
    pageSize: options.pageSize,
  });
  const plan = buildPlan(beforeState.pedidos, beforeState.dispatchDocuments);
  let afterPlan = plan;
  let execution = null;

  if (options.confirm) {
    if (plan.counts.pedidosScanned < 1) {
      throw new Error('Refusing confirmed reconciliation with zero pedidos scanned.');
    }
    execution = await commitPlan(client, options.projectId, plan);
    // A full second scan is mandatory. It proves idempotence and catches any
    // concurrent write that happened after an earlier atomic batch committed.
    const afterState = await readState(client, options.projectId, {
      pageSize: options.pageSize,
    });
    afterPlan = buildPlan(afterState.pedidos, afterState.dispatchDocuments);
    if (afterPlan.counts.inconsistencies !== 0) {
      throw new Error(
        `Post-write verification failed: ${afterPlan.counts.inconsistencies} inconsistencies remain.`,
      );
    }
  }

  return {
    projectId: options.projectId,
    dryRun: options.dryRun,
    collections: ['pedidos', 'pedido_dispatch'],
    reconciliationVersion: RECONCILIATION_VERSION,
    documentIdsIncluded: false,
    planned: { ...plan.counts },
    ...(execution ? { executed: execution } : {}),
    pedidoDispatchReconciliation: buildReconciliationEvidence(plan, {
      executed: options.confirm,
      dryRun: options.dryRun,
      afterPlan,
      execution,
    }),
  };
}

async function reconcile(options, dependencies = {}) {
  const createClient = dependencies.createClient || firestoreRestClient;
  const client = await createClient(options.projectId);
  return reconcileWithClient(client, options, dependencies);
}

function printHelp() {
  console.log(`Usage:
  node scripts/admin/reconcile_pedido_dispatch.js --project=PROJECT_ID --dry-run
  node scripts/admin/reconcile_pedido_dispatch.js --project=PROJECT_ID --confirm --confirm-project=PROJECT_ID

Dry-run is the default and never writes. Confirm mode scans every page of both
collections, upserts only the sanitized projection for open/valid targeted
pedidos, and deletes terminal, stale or orphan dispatch documents. Every
mutation verifies the source pedido and existing dispatch updateTime (or
non-existence) atomically. A full mandatory rerun must report
inconsistentAfter=0. Output/evidence contains aggregate counts and a SHA-256,
never pedido IDs or participant data. This command does not deploy anything.`);
}

async function main() {
  const options = resolveOptions();
  if (options.help) return printHelp();
  const summary = await reconcile(options);
  console.log(JSON.stringify(summary, null, 2));
  console.log(options.confirm ? 'PEDIDO_DISPATCH_RECONCILIATION_WRITTEN' : 'DRY_RUN_ONLY');
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`[reconcile_pedido_dispatch] FAILED: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  ALLOWED_DISPATCH_FIELDS,
  RECONCILIATION_VERSION,
  SERVER_TIMESTAMP,
  buildPedidoDispatchProjection,
  buildReconciliationEvidence,
  buildReconciliationPlan,
  canonicalJson,
  commitReconciliationPlan,
  decodeFirestoreFields,
  dispatchMatchesProjection,
  encodeFirestoreValue,
  isOpenPedido,
  isTargetedDispatchPedido,
  readCollection,
  readReconciliationState,
  reconcile,
  reconcileWithClient,
  resolveOptions,
  sanitizeDispatchText,
  sanitizeDispatchZone,
  validateOptions,
  writesForMutation,
};
