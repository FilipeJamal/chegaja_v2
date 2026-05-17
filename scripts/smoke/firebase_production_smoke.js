const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'chegaja-ac88d';
const REGION = process.env.FIREBASE_FUNCTIONS_REGION || 'europe-west1';
const API_KEY =
  process.env.FIREBASE_WEB_API_KEY ||
  'AIzaSyAjjapiuGF_hb_Thj6hX5UbvEqOoQ8iYQE';
const STORAGE_BUCKET =
  process.env.FIREBASE_STORAGE_BUCKET ||
  'chegaja-ac88d.firebasestorage.app';

const runId = `m274_smoke_${Date.now()}`;
const serviceId = `${runId}_service`;
const serviceName = `Servico smoke M2.7.4 ${runId}`;
const pedidoId = `${runId}_pedido`;
const finalValue = 120;

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function near(actual, expected, tolerance = 0.01) {
  return typeof actual === 'number' && Math.abs(actual - expected) <= tolerance;
}

function encodeDocPath(path) {
  return path.split('/').map(encodeURIComponent).join('/');
}

function firestoreUrl(path, query = '') {
  const suffix = query ? `?${query}` : '';
  return `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${encodeDocPath(path)}${suffix}`;
}

function fieldPathQuery(fields) {
  return fields
    .map((field) => `updateMask.fieldPaths=${encodeURIComponent(field)}`)
    .join('&');
}

function toFirestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value)
      ? { integerValue: String(value) }
      : { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (typeof value === 'object') {
    return { mapValue: { fields: toFirestoreFields(value) } };
  }
  throw new Error(`Unsupported Firestore value: ${value}`);
}

function toFirestoreFields(data) {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, toFirestoreValue(value)]),
  );
}

function fromFirestoreValue(value) {
  if (value == null) return undefined;
  if ('nullValue' in value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return Number(value.doubleValue);
  if ('timestampValue' in value) return value.timestampValue;
  if ('arrayValue' in value) {
    return (value.arrayValue.values || []).map(fromFirestoreValue);
  }
  if ('mapValue' in value) {
    return fromFirestoreFields(value.mapValue.fields || {});
  }
  return undefined;
}

function fromFirestoreFields(fields = {}) {
  return Object.fromEntries(
    Object.entries(fields).map(([key, value]) => [key, fromFirestoreValue(value)]),
  );
}

async function httpJson(url, {
  method = 'GET',
  idToken,
  body,
  headers = {},
  expectStatus,
} = {}) {
  const response = await fetch(url, {
    method,
    headers: {
      ...(idToken ? { Authorization: `Bearer ${idToken}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await response.text();
  let parsed = null;
  if (text) {
    try {
      parsed = JSON.parse(text);
    } catch (_) {
      parsed = { raw: text };
    }
  }
  if (expectStatus != null) {
    assert(
      response.status === expectStatus,
      `Expected HTTP ${expectStatus}, got ${response.status}: ${text}`,
    );
  } else if (!response.ok) {
    throw new Error(`HTTP ${response.status} ${method} ${url}: ${text}`);
  }
  return { response, data: parsed };
}

async function signInAnonymously(label) {
  const { data } = await httpJson(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    {
      method: 'POST',
      body: { returnSecureToken: true },
    },
  );
  assert(data?.idToken && data?.localId, `Auth anonymous sign-up failed for ${label}`);
  return { uid: data.localId, idToken: data.idToken };
}

async function setDoc(idToken, path, data) {
  await httpJson(firestoreUrl(path), {
    method: 'PATCH',
    idToken,
    body: { fields: toFirestoreFields(data) },
  });
}

async function patchDoc(idToken, path, data) {
  await httpJson(firestoreUrl(path, fieldPathQuery(Object.keys(data))), {
    method: 'PATCH',
    idToken,
    body: { fields: toFirestoreFields(data) },
  });
}

async function getDoc(idToken, path) {
  const { data } = await httpJson(firestoreUrl(path), { idToken });
  return fromFirestoreFields(data.fields || {});
}

async function expectFirestoreDenied(idToken, path, data) {
  const { response } = await httpJson(firestoreUrl(path, fieldPathQuery(Object.keys(data))), {
    method: 'PATCH',
    idToken,
    body: { fields: toFirestoreFields(data) },
    expectStatus: 403,
  });
  return response.status;
}

async function callCallable(idToken, name, payload) {
  const { data } = await httpJson(
    `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/${name}`,
    {
      method: 'POST',
      idToken,
      body: { data: payload },
    },
  );
  if (data?.error) {
    throw new Error(`${name} returned callable error: ${JSON.stringify(data.error)}`);
  }
  return data?.result;
}

async function uploadObject({
  idToken,
  objectPath,
  content,
  contentType = 'text/plain',
  expectStatus,
}) {
  const url =
    `https://firebasestorage.googleapis.com/v0/b/${encodeURIComponent(STORAGE_BUCKET)}/o` +
    `?uploadType=media&name=${encodeURIComponent(objectPath)}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${idToken}`,
      'Content-Type': contentType,
    },
    body: content,
  });
  const text = await response.text();
  if (expectStatus != null) {
    assert(
      response.status === expectStatus,
      `Expected Storage HTTP ${expectStatus}, got ${response.status}: ${text}`,
    );
  } else if (!response.ok) {
    throw new Error(`Storage upload failed ${response.status}: ${text}`);
  }
  return { response, text };
}

async function main() {
  console.log(`[M2.7.4 smoke] project=${PROJECT_ID} runId=${runId}`);

  const client = await signInAnonymously('client');
  const provider = await signInAnonymously('provider');
  const outsider = await signInAnonymously('outsider');
  console.log(`[M2.7.4 smoke] users client=${client.uid} provider=${provider.uid}`);

  await setDoc(client.idToken, `users/${client.uid}`, {
    uid: client.uid,
    isAnonymous: true,
    activeRole: 'cliente',
    roles: { cliente: true },
    region: 'PT',
    updatedAt: new Date(),
  });

  await setDoc(provider.idToken, `users/${provider.uid}`, {
    uid: provider.uid,
    isAnonymous: true,
    activeRole: 'prestador',
    roles: { prestador: true },
    region: 'PT',
    updatedAt: new Date(),
  });

  await setDoc(provider.idToken, `prestadores/${provider.uid}`, {
    nome: `Prestador smoke ${runId}`,
    isOnline: true,
    servicos: [serviceId],
    servicosNomes: [serviceName],
    radiusKm: 50,
    lastLocation: { lat: 38.7223, lng: -9.1393 },
    updatedAt: new Date(),
  });

  await setDoc(client.idToken, `pedidos/${pedidoId}`, {
    clienteId: client.uid,
    prestadorId: null,
    servicoId: serviceId,
    servicoNome: serviceName,
    categoria: serviceName,
    titulo: `Smoke M2.7.4 ${runId}`,
    descricao: 'Pedido smoke M2.7.4 criado por REST apos deploy controlado.',
    modo: 'IMEDIATO',
    tipoPreco: 'a_combinar',
    tipoPagamento: 'dinheiro',
    estado: 'criado',
    status: 'criado',
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: 'nenhum',
    createdAt: new Date(),
    updatedAt: new Date(),
    latitude: null,
    longitude: null,
    enderecoTexto: 'Smoke M2.7.4',
  });

  await getDoc(provider.idToken, `pedidos/${pedidoId}`);
  console.log('[M2.7.4 smoke] provider can read open pedido');

  await patchDoc(provider.idToken, `pedidos/${pedidoId}`, {
    prestadorId: provider.uid,
    estado: 'aceito',
    status: 'aceito',
    updatedAt: new Date(),
  });

  await patchDoc(provider.idToken, `pedidos/${pedidoId}`, {
    estado: 'em_andamento',
    status: 'em_andamento',
    updatedAt: new Date(),
  });

  const proposed = await callCallable(provider.idToken, 'proporValorFinalPedido', {
    pedidoId,
    valorFinal: finalValue,
    comentario: 'Smoke M2.7.4',
  });
  assert(proposed?.ok === true, 'proporValorFinalPedido did not return ok=true');

  let pedido = await getDoc(client.idToken, `pedidos/${pedidoId}`);
  assert(pedido.estado === 'aguarda_confirmacao_valor', 'pedido not pending final confirmation');
  assert(pedido.lastAuthoritativeFunction === 'proporValorFinalPedido', 'missing proposal marker');

  const confirmed = await callCallable(client.idToken, 'confirmarValorFinalPedido', {
    pedidoId,
  });
  assert(confirmed?.ok === true, 'confirmarValorFinalPedido did not return ok=true');

  pedido = await getDoc(client.idToken, `pedidos/${pedidoId}`);
  assert(pedido.estado === 'concluido', 'pedido not concluded');
  assert(pedido.status === 'concluido', 'pedido status not concluded');
  assert(pedido.statusConfirmacaoValor === 'confirmado_cliente', 'final value not confirmed');
  assert(pedido.lastAuthoritativeFunction === 'confirmarValorFinalPedido', 'missing confirmation marker');
  assert(near(pedido.precoFinal, finalValue), 'precoFinal mismatch');
  assert(near(pedido.commissionPlatform, finalValue * 0.15), 'commissionPlatform mismatch');
  assert(near(pedido.earningsProvider, finalValue * 0.85), 'earningsProvider mismatch');
  assert(near(pedido.earningsTotal, finalValue), 'earningsTotal mismatch');
  console.log('[M2.7.4 smoke] authoritative pedido flow concluded with 15/85 split');

  const deniedStatus = await expectFirestoreDenied(client.idToken, `pedidos/${pedidoId}`, {
    commissionPlatform: 0,
  });
  console.log(`[M2.7.4 smoke] malicious direct economic update denied (${deniedStatus})`);

  const pngPixel = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
    'base64',
  );

  await uploadObject({
    idToken: client.idToken,
    objectPath: `temp/${client.uid}/anexos/${runId}.png`,
    content: pngPixel,
    contentType: 'image/png',
  });
  console.log('[M2.7.4 smoke] allowed temp attachment upload succeeded');

  await uploadObject({
    idToken: client.idToken,
    objectPath: `pedidos/${pedidoId}/anexos/${runId}.png`,
    content: pngPixel,
    contentType: 'image/png',
  });
  console.log('[M2.7.4 smoke] allowed pedido attachment upload succeeded');

  const { response: deniedUpload } = await uploadObject({
    idToken: outsider.idToken,
    objectPath: `pedidos/${pedidoId}/anexos/${runId}-blocked.png`,
    content: pngPixel,
    contentType: 'image/png',
    expectStatus: 403,
  });
  console.log(`[M2.7.4 smoke] outsider attachment upload denied (${deniedUpload.status})`);

  console.log('[M2.7.4 smoke] OK');
}

main().catch((error) => {
  console.error(`[M2.7.4 smoke] FAILED: ${error.message}`);
  process.exitCode = 1;
});
