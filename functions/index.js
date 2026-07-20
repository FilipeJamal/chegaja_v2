/* eslint-disable no-console */

/**
 * ChegaJá v2.5 - Cloud Functions (Firebase)
 *
 * Inclui:
 * - Push notifications (FCM) para chat e mudanças de estado do pedido
 * - Matching geográfico simples para novos pedidos (GeoFire / geohash)
 * - Stripe Connect (onboarding prestador) + PaymentIntent (pagamento do cliente)
 *
 * NOTA: Em produção, recomenda-se usar Firebase Secrets.
 */

const crypto = require('crypto');
const { initializeApp } = require('firebase-admin/app');
const { getAppCheck } = require('firebase-admin/app-check');
const { getAuth } = require('firebase-admin/auth');
const {
  getFirestore, Timestamp, FieldValue, GeoPoint,
} = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getStorage } = require('firebase-admin/storage');
const { logger } = require('firebase-functions');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall: firebaseOnCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const geofire = require('geofire-common');
const allowedWebOrigins = new Set((process.env.ALLOWED_WEB_ORIGINS
  || 'https://chegaja.com,https://www.chegaja.com,https://chegaja-ac88d.web.app,https://chegaja-ac88d.firebaseapp.com')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean));
const cors = require('cors')({
  origin(origin, callback) {
    if (!origin || allowedWebOrigins.has(origin)) return callback(null, true);
    return callback(new Error('Origin not allowed'));
  },
  methods: ['GET', 'OPTIONS'],
  allowedHeaders: ['Authorization', 'Content-Type', 'X-Firebase-AppCheck'],
  maxAge: 3600,
});
const dotenv = require('dotenv');

// Carrega .env local (apenas em emuladores/dev)
const useEmulators = process.env.FUNCTIONS_EMULATOR === 'true'
  || !!process.env.FIREBASE_EMULATOR_HUB;
if (useEmulators) {
  dotenv.config({ path: '.env.local' });
  dotenv.config();
}

function onCall(options, handler) {
  return firebaseOnCall(
    { ...(options || {}), enforceAppCheck: !useEmulators },
    async (request) => {
      await enforceCallableRateLimit(request);
      return handler(request);
    },
  );
}

initializeApp();

const db = getFirestore();
const messaging = getMessaging();
const firebaseAuth = getAuth();
const firebaseStorage = getStorage();
const firebaseAppCheck = getAppCheck();

const REGION = process.env.FUNCTIONS_REGION || 'europe-west1';
const GOOGLE_PLACES_API_KEY = defineSecret('GOOGLE_PLACES_API_KEY');
const GOOGLE_MAPS_API_KEY = defineSecret('GOOGLE_MAPS_API_KEY');
const ACCOUNT_DELETION_PEPPER = defineSecret('ACCOUNT_DELETION_PEPPER');

// ------------------------------------------------------------
// Helpers
// ------------------------------------------------------------

function getEnv(key, fallback = '') {
  const v = process.env[key];
  return (v === undefined || v === null) ? fallback : String(v);
}

function envFlagEnabled(key, fallback = false) {
  const fallbackValue = typeof fallback === 'boolean'
    ? (fallback ? 'true' : 'false')
    : String(fallback);
  const value = getEnv(key, fallbackValue).trim().toLowerCase();
  return ['true', '1', 'yes', 'on'].includes(value);
}

function paymentMethodEnabled(method) {
  switch (cleanString(method).toLowerCase()) {
    case 'dinheiro':
    case 'cash':
      return true;
    case 'mpesa':
      return envFlagEnabled('ENABLE_MPESA');
    case 'emola':
      return envFlagEnabled('ENABLE_EMOLA');
    case 'stripe':
      return envFlagEnabled('ENABLE_STRIPE') && envFlagEnabled('STRIPE_MZN_VALIDATED');
    default:
      return false;
  }
}

async function enforceHttpAppSecurity(req, res, { endpoint, limitPerMinute }) {
  if (useEmulators) return { uid: 'emulator', appId: 'emulator' };
  const appCheckToken = cleanString(req.get('X-Firebase-AppCheck'));
  const authorization = cleanString(req.get('Authorization'));
  const idToken = authorization.toLowerCase().startsWith('bearer ')
    ? authorization.slice(7).trim()
    : '';
  if (!appCheckToken || !idToken) {
    res.status(401).json({ error: 'UNAUTHENTICATED' });
    return null;
  }
  let appClaims;
  let authClaims;
  try {
    [appClaims, authClaims] = await Promise.all([
      firebaseAppCheck.verifyToken(appCheckToken),
      firebaseAuth.verifyIdToken(idToken, true),
    ]);
  } catch (error) {
    logger.warn('[http-security] Token invalido.', { endpoint });
    res.status(401).json({ error: 'UNAUTHENTICATED' });
    return null;
  }
  const uid = cleanString(authClaims.uid);
  if (!uid) {
    res.status(401).json({ error: 'UNAUTHENTICATED' });
    return null;
  }
  const windowStart = Math.floor(Date.now() / 60000) * 60000;
  const counterRef = db.collection('endpoint_rate_limits')
    .doc(`${uid}_${endpoint}_${windowStart}`);
  let allowed = true;
  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(counterRef);
    const count = snapshot.exists ? Number(snapshot.data().count || 0) : 0;
    if (count >= limitPerMinute) {
      allowed = false;
      return;
    }
    tx.set(counterRef, {
      uid,
      endpoint,
      windowStart: Timestamp.fromMillis(windowStart),
      count: count + 1,
      expiresAt: Timestamp.fromMillis(windowStart + 24 * 60 * 60 * 1000),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  if (!allowed) {
    res.set('Retry-After', '60');
    res.status(429).json({ error: 'RATE_LIMITED' });
    return null;
  }
  return { uid, appId: cleanString(appClaims.app_id || appClaims.sub) };
}

async function enforceCallableRateLimit(request) {
  if (useEmulators) return;
  const rawKey = cleanString(
    (request.auth && request.auth.uid)
      || (request.app && (request.app.appId || request.app.app_id))
      || 'unknown',
  );
  const key = rawKey.replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 120);
  const limit = Number(getEnv('RATE_LIMIT_CALLABLES_PER_MINUTE', '90')) || 90;
  const windowStart = Math.floor(Date.now() / 60000) * 60000;
  const ref = db.collection('endpoint_rate_limits').doc(`${key}_callables_${windowStart}`);
  let allowed = true;
  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const count = snapshot.exists ? Number(snapshot.data().count || 0) : 0;
    if (count >= limit) {
      allowed = false;
      return;
    }
    tx.set(ref, {
      key,
      endpoint: 'callables',
      windowStart: Timestamp.fromMillis(windowStart),
      count: count + 1,
      expiresAt: Timestamp.fromMillis(windowStart + 24 * 60 * 60 * 1000),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  if (!allowed) {
    throw new HttpsError('resource-exhausted', 'Demasiados pedidos. Tenta novamente dentro de um minuto.');
  }
}

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
}

async function getUserFcmTokens(userId) {
  const snap = await db.collection('users_private').doc(userId).collection('fcmTokens').get();
  return snap.docs.map((d) => d.id).filter((t) => typeof t === 'string' && t.trim().length > 0);
}

async function pruneInvalidTokens(userId, tokens, sendResponse) {
  // Remove tokens inválidos da subcoleção fcmTokens/{token}
  if (!sendResponse || !sendResponse.responses) return;

  const invalid = [];
  sendResponse.responses.forEach((r, idx) => {
    if (!r.success) {
      const code = r.error && r.error.code ? r.error.code : '';
      if (code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-registration-token') {
        invalid.push(tokens[idx]);
      }
    }
  });

  if (invalid.length === 0) return;

  const batch = db.batch();
  invalid.forEach((t) => {
    const ref = db.collection('users_private').doc(userId).collection('fcmTokens').doc(t);
    batch.delete(ref);
  });
  await batch.commit();
  logger.info(`[FCM] Tokens inválidos removidos user=${userId} count=${invalid.length}`);
}

async function saveInAppNotification(userId, payload) {
  try {
    await db.collection('users_private').doc(userId).collection('notifications').add({
      ...payload,
      createdAt: FieldValue.serverTimestamp(),
      readAt: null,
    });
  } catch (e) {
    logger.warn(`[notifications] Falha ao guardar notificação in-app para ${userId}: ${e}`);
  }
}

async function sendPushToUser(userId, { title, body, data }) {
  const tokens = await getUserFcmTokens(userId);
  if (tokens.length === 0) return;

  // FCM data precisa ser string
  const dataStrings = {};
  if (data && typeof data === 'object') {
    Object.entries(data).forEach(([k, v]) => {
      dataStrings[String(k)] = v === undefined || v === null ? '' : String(v);
    });
  }

  const messageBase = {
    notification: {
      title: title || 'ChegaJá',
      body: body || '',
    },
    data: dataStrings,
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance_channel',
        sound: 'default',
        defaultSound: true,
        defaultVibrateTimings: true,
        priority: 'high',
        visibility: 'public',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
    },
  };

  for (const group of chunk(tokens, 500)) {
    const resp = await messaging.sendEachForMulticast({ ...messageBase, tokens: group });
    await pruneInvalidTokens(userId, group, resp);
  }
}

function safeText(str, max = 120) {
  const s = (str || '').toString().trim();
  if (s.length <= max) return s;
  return `${s.slice(0, Math.max(0, max - 3))}...`;
}

const PROHIBITED_SERVICE_PHRASES = [
  'servico sexual', 'sexo pago', 'garota de programa', 'garoto de programa',
  'prostituicao', 'prostituta', 'prostituto', 'escort', 'pornografia',
  'comprar droga', 'vender droga', 'trafico de drogas', 'cocaina', 'heroina',
  'crack', 'metanfetamina', 'fabricar droga', 'venda de armas', 'arma ilegal',
  'bomba caseira', 'fabricar bomba', 'cartao clonado', 'clonar cartao',
  'phishing', 'roubar senha', 'hackear conta', 'invadir conta',
  'falsificacao de documentos', 'documento falso', 'passaporte falso',
  'bilhete falso', 'diploma falso', 'assassino de aluguel', 'matar alguem',
  'encomenda de morte', 'agressao encomendada', 'exploracao sexual infantil',
  'abuso infantil', 'pedofilia', 'venda de criancas', 'trafico humano',
  'trabalho forcado', 'recrutamento terrorista', 'cirurgia clandestina',
  'receita falsa', 'lavagem de dinheiro', 'mercadoria roubada',
  'roubo sob encomenda', 'furto sob encomenda', 'extorsao', 'chantagem',
  'sequestro', 'suborno', 'servico criminoso',
];

const REVIEW_SERVICE_PHRASES = [
  'companhia discreta', 'servico adulto', 'servico especial', 'trabalho secreto',
  'faco de tudo', 'qualquer coisa', 'servico privado', 'coisa discreta',
  'contactos especiais', 'ajuda confidencial',
];

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

function includesSafetyPhrase(normalized, phrase) {
  const needle = normalizeSafetyText(phrase);
  return needle && ` ${normalized} `.includes(` ${needle} `);
}

function classifyServerServiceText(fields) {
  const normalized = normalizeSafetyText((Array.isArray(fields) ? fields : [fields]).join(' '));
  const matchedBlocked = PROHIBITED_SERVICE_PHRASES
    .filter((phrase) => includesSafetyPhrase(normalized, phrase));
  const hasBlockedPrefix = normalized.split(' ').some((token) => (
    ['prostitu', 'pedofil', 'assassin', 'sicari', 'terror', 'falsific'].some((prefix) => token.startsWith(prefix))
  ));
  if (matchedBlocked.length > 0 || hasBlockedPrefix) {
    return { decision: 'block', normalized, matches: matchedBlocked.slice(0, 5) };
  }
  const matchedReview = REVIEW_SERVICE_PHRASES
    .filter((phrase) => includesSafetyPhrase(normalized, phrase));
  if (matchedReview.length > 0) {
    return { decision: 'pending_review', normalized, matches: matchedReview.slice(0, 5) };
  }
  return { decision: 'allow', normalized, matches: [] };
}

const RESERVED_HANDLES = new Set([
  'admin',
  'administrador',
  'administrator',
  'support',
  'suporte',
  'help',
  'ajuda',
  'chegaja',
  'chegajaoficial',
  'chegajaapp',
  'oficial',
  'official',
  'verified',
  'verificado',
  'certificado',
  'pagamento',
  'pagamentos',
  'payment',
  'seguranca',
  'security',
  'termos',
  'terms',
  'privacidade',
  'privacy',
  'login',
  'logout',
  'register',
  'signup',
  'api',
  'app',
  'root',
  'null',
  'undefined',
  'system',
  'moderator',
  'moderador',
  'moderacao',
  'moderation',
  'staff',
  'team',
]);

const PROHIBITED_HANDLE_PHRASES = [
  'prostituicao',
  'servico sexual',
  'servicos sexuais',
  'pornografia',
  'trafico humano',
  'drogas ilegais',
  'droga ilegal',
  'cocaina',
  'heroina',
  'crack',
  'armas ilegais',
  'arma ilegal',
  'fraude',
  'golpe',
  'burla',
  'falsificacao de documentos',
  'documento falso',
  'exploracao de menores',
  'abuso infantil',
  'servico criminoso',
  'extorsao',
];

function normalizePublicHandle(raw) {
  let value = String(raw || '').trim();
  if (value.startsWith('@')) {
    value = value.slice(1).trim();
  }
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();
}

function handleValidationMessage(code) {
  if (code === 'empty') return 'Escolhe um @handle.';
  if (code === 'too_short') return 'O @handle deve ter pelo menos 3 caracteres.';
  if (code === 'too_long') return 'O @handle deve ter no maximo 30 caracteres.';
  if (code === 'invalid_characters') {
    return 'Usa apenas letras, numeros, ponto, underline ou hifen.';
  }
  if (code === 'edge_separator') {
    return 'O @handle nao pode comecar ou terminar com separador.';
  }
  if (code === 'repeated_separator') {
    return 'O @handle nao pode ter separadores repetidos.';
  }
  if (code === 'reserved' || code === 'blocked') {
    return 'Este nome de perfil nao pode ser usado.';
  }
  if (code === 'taken') return 'Este @handle ja esta em uso.';
  return '';
}

function isBlockedPublicHandle(normalized) {
  const safetyText = normalized.replace(/[._-]+/g, ' ');
  const haystack = ` ${safetyText} `;
  return PROHIBITED_HANDLE_PHRASES.some((phrase) => {
    const safePhrase = normalizePublicHandle(phrase).replace(/[._-]+/g, ' ');
    return haystack.includes(` ${safePhrase} `);
  });
}

function validatePublicHandle(raw) {
  const normalizedHandle = normalizePublicHandle(raw);
  let reason = 'valid';

  if (!normalizedHandle) reason = 'empty';
  else if (normalizedHandle.length < 3) reason = 'too_short';
  else if (normalizedHandle.length > 30) reason = 'too_long';
  else if (!/^[a-z0-9._-]+$/.test(normalizedHandle)) reason = 'invalid_characters';
  else if (/^[._-]|[._-]$/.test(normalizedHandle)) reason = 'edge_separator';
  else if (/[._-]{2,}/.test(normalizedHandle)) reason = 'repeated_separator';
  else if (RESERVED_HANDLES.has(normalizedHandle)) reason = 'reserved';
  else if (isBlockedPublicHandle(normalizedHandle)) reason = 'blocked';

  return {
    normalizedHandle,
    ok: reason === 'valid',
    reason,
    message: handleValidationMessage(reason),
  };
}


function moneyToCents(value) {
  const num = Number(value);
  if (!Number.isFinite(num)) return 0;
  return Math.round(num * 100);
}

function getClienteId(data) {
  if (!data) return '';
  return (data.clienteId || data.clientId || '').toString();
}

function getPedidoEstado(data) {
  if (!data) return '';
  return String(data.status || data.estado || '').trim();
}

function sanitizeDispatchText(value, maxLength = 500) {
  return safeText(value, maxLength)
    .replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[contacto removido]')
    .replace(/(?:https?:\/\/|www\.)\S+/gi, '[link removido]')
    .replace(/(?:\+?258[\s.-]?)?(?:8[2-7])[\s.-]?\d{3}[\s.-]?\d{3}/g, '[contacto removido]')
    .replace(/\b-?\d{1,2}\.\d{4,}\s*[,;]\s*-?\d{1,3}\.\d{4,}\b/g, '[localizacao removida]')
    .trim();
}

function approximateCoordinate(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return null;
  return Math.round(number * 100) / 100;
}

function sanitizeDispatchZone(value) {
  const parts = String(value || '')
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean)
    .filter((part) => !/\d{3,}/.test(part));
  const candidates = parts.slice(-2).map((part) => part.replace(/\b\d+[A-Za-z-]*\b/g, '').trim());
  const zone = candidates.filter(Boolean).join(', ');
  return sanitizeDispatchText(zone || 'Zona aproximada', 120);
}

function buildPedidoDispatchProjection(pedidoId, pedido = {}) {
  const latitude = approximateCoordinate(pedido.latitude ?? pedido.geo?.geopoint?.latitude);
  const longitude = approximateCoordinate(pedido.longitude ?? pedido.geo?.geopoint?.longitude);
  const zoneLabel = sanitizeDispatchZone(
    pedido.dispatchZone || pedido.zone || pedido.bairro || pedido.city || pedido.enderecoTexto,
  );
  const status = getPedidoEstado(pedido) || 'criado';
  return {
    pedidoId,
    servicoId: safeText(pedido.servicoId, 120),
    servicoNome: sanitizeDispatchText(pedido.servicoNome || pedido.categoria, 160),
    categoria: sanitizeDispatchText(pedido.categoria || pedido.servicoNome, 160),
    titulo: sanitizeDispatchText(pedido.titulo, 180),
    descricao: sanitizeDispatchText(pedido.descricao, 500),
    modo: safeText(pedido.modo, 40),
    agendadoPara: pedido.agendadoPara || null,
    tipoPreco: safeText(pedido.tipoPreco, 60),
    tipoPagamento: safeText(pedido.tipoPagamento, 60),
    estado: status,
    status,
    prestadorId: null,
    zoneLabel,
    enderecoTexto: zoneLabel,
    latitude,
    longitude,
    categoryApprovalRequired: pedido.categoryApprovalRequired === true,
    categoryRequirementId: safeText(pedido.categoryRequirementId, 120),
    categoryRequirementName: sanitizeDispatchText(pedido.categoryRequirementName, 160),
    categoryRiskLevel: safeText(pedido.categoryRiskLevel, 40),
    isCustomService: pedido.isCustomService === true,
    customServiceName: sanitizeDispatchText(pedido.customServiceName, 160),
    createdAt: pedido.createdAt || FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function isOpenPedido(pedido) {
  return getPedidoEstado(pedido) === 'criado'
    && !cleanString(pedido?.prestadorId)
    && cleanString(pedido?.moderationStatus || 'approved') === 'approved';
}

async function syncPedidoDispatch(database, pedidoId, pedido) {
  const dispatchRef = database.collection('pedido_dispatch').doc(pedidoId);
  if (!isOpenPedido(pedido)) {
    await dispatchRef.delete();
    return { open: false };
  }
  await dispatchRef.set(buildPedidoDispatchProjection(pedidoId, pedido), { merge: false });
  return { open: true };
}

async function syncProviderActiveClients(database, providerId) {
  const cleanProviderId = cleanString(providerId);
  if (!cleanProviderId) return;
  const activeStates = [
    'aceito',
    'em_andamento',
    'aguarda_confirmacao_valor',
    'aguarda_resposta_cliente',
  ];
  const active = await database.collection('pedidos')
    .where('prestadorId', '==', cleanProviderId)
    .where('status', 'in', activeStates)
    .limit(500)
    .get();
  const activeClientIds = [...new Set(active.docs.map((doc) => getClienteId(doc.data())).filter(Boolean))];
  await database.collection('provider_dispatch_private').doc(cleanProviderId).set({
    providerId: cleanProviderId,
    activeClientIds,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

function providerMatchesPedido(provider = {}, pedido = {}) {
  const serviceIds = new Set((provider.servicos || provider.categories || []).map((value) => cleanString(value)));
  const serviceNames = new Set((provider.servicosNomes || []).map((value) => cleanString(value).toLowerCase()));
  const pedidoServiceId = cleanString(pedido.servicoId);
  const pedidoServiceName = cleanString(pedido.servicoNome || pedido.categoria).toLowerCase();
  const serviceMatch = (pedidoServiceId && serviceIds.has(pedidoServiceId))
    || (pedidoServiceName && serviceNames.has(pedidoServiceName));
  if (!serviceMatch) return false;
  if (pedido.categoryApprovalRequired !== true) return true;
  const required = cleanString(pedido.categoryRequirementId || pedido.servicoId);
  const approvals = new Set((provider.approvedSensitiveCategoryIds || []).map((value) => cleanString(value)));
  return !!required && approvals.has(required);
}

async function acceptPedidoDispatchCore({ database = db, auth, pedidoId }) {
  if (!auth || !auth.uid) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  if (!auth.token || !cleanString(auth.token.phone_number)) {
    throw new HttpsError('failed-precondition', 'Confirma o telefone antes de aceitar trabalhos.');
  }
  const providerId = cleanString(auth.uid);
  const cleanPedidoId = cleanString(pedidoId);
  if (!cleanPedidoId) throw new HttpsError('invalid-argument', 'pedidoId obrigatorio.');

  const providerSnap = await database.collection('provider_public').doc(providerId).get();
  if (!providerSnap.exists) throw new HttpsError('failed-precondition', 'Perfil de prestador inexistente.');
  const provider = providerSnap.data() || {};
  const [providerPrivateSnap, dispatchPrivateSnap] = await Promise.all([
    database.collection('provider_private').doc(providerId).get(),
    database.collection('provider_dispatch_private').doc(providerId).get(),
  ]);
  const providerPrivate = providerPrivateSnap.data() || {};
  const dispatchPrivate = dispatchPrivateSnap.data() || {};
  if (providerPrivate.financialStatus === 'suspended_new_jobs'
    || dispatchPrivate.acceptingNewJobs === false) {
    throw new HttpsError(
      'failed-precondition',
      'Regulariza ou contesta o saldo de comissao antes de aceitar novos pedidos.',
    );
  }

  const pedidoRef = database.collection('pedidos').doc(cleanPedidoId);
  await database.runTransaction(async (tx) => {
    const pedidoSnap = await tx.get(pedidoRef);
    if (!pedidoSnap.exists) throw new HttpsError('not-found', 'Pedido nao encontrado.');
    const pedido = pedidoSnap.data() || {};
    const invitedProvider = getPedidoEstado(pedido) === 'aguarda_resposta_prestador'
      && cleanString(pedido.prestadorId) === providerId
      && cleanString(pedido.moderationStatus || 'approved') === 'approved';
    if (!isOpenPedido(pedido) && !invitedProvider) {
      throw new HttpsError('failed-precondition', 'Pedido ja nao esta disponivel.');
    }
    if (!providerMatchesPedido(provider, pedido)) {
      throw new HttpsError('permission-denied', 'Prestador nao elegivel para este pedido.');
    }
    tx.update(pedidoRef, {
      prestadorId: providerId,
      status: 'aceito',
      estado: 'aceito',
      updatedAt: FieldValue.serverTimestamp(),
      historico: FieldValue.arrayUnion({
        evento: invitedProvider ? 'convite_aceite' : 'pedido_aceite',
        timestamp: Timestamp.now(),
        userId: providerId,
        descricao: invitedProvider
          ? 'Prestador aceitou o convite via backend seguro'
          : 'Prestador aceitou o pedido via dispatch seguro',
      }),
    });
  });
  await database.collection('pedido_dispatch').doc(cleanPedidoId).delete();
  await syncProviderActiveClients(database, providerId);
  return { ok: true, pedidoId: cleanPedidoId };
}

function mergePreferTarget(source = {}, target = {}) {
  const merged = { ...source, ...target };
  delete merged.mergedInto;
  delete merged.mergedAt;
  return merged;
}

async function syncPhoneIdentityCore({ database = db, auth }) {
  if (!auth || !auth.uid) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  const userRecord = await firebaseAuth.getUser(auth.uid);
  const phoneNumber = cleanString(userRecord.phoneNumber);
  if (!phoneNumber) throw new HttpsError('failed-precondition', 'Telefone ainda nao confirmado.');

  const now = FieldValue.serverTimestamp();
  const privateRef = database.collection('users_private').doc(auth.uid);
  const providerPublicRef = database.collection('provider_public').doc(auth.uid);
  const [providerSnap, activePilotProvider] = await Promise.all([
    providerPublicRef.get(),
    pilotParticipantIsActive({
      database,
      uid: auth.uid,
      role: 'prestador',
    }),
  ]);
  const batch = database.batch();
  batch.set(privateRef, {
    uid: auth.uid,
    isAnonymous: false,
    phoneE164: phoneNumber,
    phoneVerified: true,
    phoneVerifiedAt: now,
    updatedAt: now,
  }, { merge: true });
  if (providerSnap.exists) {
    batch.set(providerPublicRef, {
      isSearchable: activePilotProvider,
      trustSignals: { phoneConfirmed: true },
      updatedAt: now,
    }, { merge: true });
  }
  await batch.commit();
  return { ok: true, phoneVerified: true };
}

async function mergeAnonymousDataCore({ database = db, auth, sourceIdToken }) {
  if (!auth || !auth.uid) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  const targetUser = await firebaseAuth.getUser(auth.uid);
  if (!targetUser.phoneNumber) {
    throw new HttpsError('failed-precondition', 'A conta de destino precisa de telefone confirmado.');
  }
  const token = cleanString(sourceIdToken);
  if (!token) throw new HttpsError('invalid-argument', 'Token da sessao temporaria em falta.');
  const sourceAuth = await firebaseAuth.verifyIdToken(token, true);
  const sourceUid = cleanString(sourceAuth.uid);
  const provider = sourceAuth.firebase && sourceAuth.firebase.sign_in_provider;
  if (!sourceUid || sourceUid === auth.uid || provider !== 'anonymous') {
    throw new HttpsError('permission-denied', 'Sessao temporaria invalida.');
  }

  const sourcePrivateRef = database.collection('users_private').doc(sourceUid);
  const targetPrivateRef = database.collection('users_private').doc(auth.uid);
  const [sourcePrivateSnap, targetPrivateSnap] = await Promise.all([
    sourcePrivateRef.get(),
    targetPrivateRef.get(),
  ]);
  const sourcePrivate = sourcePrivateSnap.data() || {};
  if (sourcePrivate.mergedInto && sourcePrivate.mergedInto !== auth.uid) {
    throw new HttpsError('already-exists', 'Sessao temporaria ja foi migrada.');
  }
  if (sourcePrivate.mergedInto === auth.uid) {
    return { ok: true, sourceUid, targetUid: auth.uid, idempotent: true };
  }

  const docPairs = [
    ['public_profiles', sourceUid, auth.uid, 'uid'],
    ['provider_public', sourceUid, auth.uid, 'uid'],
    ['provider_private', sourceUid, auth.uid, 'providerId'],
    ['provider_dispatch_private', sourceUid, auth.uid, 'providerId'],
  ];
  const bulk = database.bulkWriter();
  const targetPrivate = targetPrivateSnap.data() || {};
  bulk.set(targetPrivateRef, {
    ...mergePreferTarget(sourcePrivate, targetPrivate),
    uid: auth.uid,
    isAnonymous: false,
    phoneE164: targetUser.phoneNumber,
    phoneVerified: true,
    phoneVerifiedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  for (const [collection, sourceId, targetId, identityField] of docPairs) {
    const [sourceSnap, targetSnap] = await Promise.all([
      database.collection(collection).doc(sourceId).get(),
      database.collection(collection).doc(targetId).get(),
    ]);
    if (!sourceSnap.exists) continue;
    bulk.set(database.collection(collection).doc(targetId), {
      ...mergePreferTarget(sourceSnap.data(), targetSnap.data()),
      [identityField]: targetId,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  const favorites = await sourcePrivateRef.collection('favorites').limit(500).get();
  favorites.docs.forEach((doc) => {
    bulk.set(targetPrivateRef.collection('favorites').doc(doc.id), doc.data(), { merge: true });
  });

  const ownershipQueries = await Promise.all([
    database.collection('pedidos').where('clienteId', '==', sourceUid).limit(500).get(),
    database.collection('pedidos').where('prestadorId', '==', sourceUid).limit(500).get(),
    database.collection('chats').where('clienteId', '==', sourceUid).limit(500).get(),
    database.collection('chats').where('prestadorId', '==', sourceUid).limit(500).get(),
  ]);
  ownershipQueries[0].docs.forEach((doc) => bulk.update(doc.ref, { clienteId: auth.uid }));
  ownershipQueries[1].docs.forEach((doc) => bulk.update(doc.ref, { prestadorId: auth.uid }));
  ownershipQueries[2].docs.forEach((doc) => bulk.update(doc.ref, { clienteId: auth.uid }));
  ownershipQueries[3].docs.forEach((doc) => bulk.update(doc.ref, { prestadorId: auth.uid }));

  bulk.set(sourcePrivateRef, {
    mergedInto: auth.uid,
    mergedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  bulk.create(database.collection('account_merge_audit').doc(), {
    sourceUid,
    targetUid: auth.uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  await bulk.close();
  await syncPhoneIdentityCore({ database, auth });
  return { ok: true, sourceUid, targetUid: auth.uid, idempotent: false };
}

const KYC_CONSENT_VERSION = 'kyc-consent-2026-07-20';
const KYC_UPLOAD_WINDOW_MINUTES = 30;
const KYC_RETENTION_DAYS = 90;
const LEGAL_DOCUMENT_VERSION = 'legal-2026-07-20-pilot-v2';
const ACCOUNT_DELETION_GRACE_DAYS = 7;

function requireVerifiedPhoneAuth(auth) {
  const uid = requireCallableUid(auth && auth.uid);
  if (!auth.token || !cleanString(auth.token.phone_number)) {
    throw new HttpsError('failed-precondition', 'Confirma o telefone antes de continuar.');
  }
  return uid;
}

async function requireCurrentLegalConsent({ database = db, uid }) {
  const snapshot = await database.collection('users_private').doc(uid).get();
  const consent = snapshot.exists ? snapshot.data().legalConsent : null;
  if (!consent
    || cleanString(consent.version) !== LEGAL_DOCUMENT_VERSION
    || consent.ageConfirmed !== true) {
    throw new HttpsError(
      'failed-precondition',
      'Aceita os Termos de Utilizacao e a Politica de Privacidade atuais.',
    );
  }
  return consent;
}

function pilotAllowlistRequired() {
  return envFlagEnabled('PILOT_REQUIRE_ALLOWLIST', !useEmulators);
}

function normalizedPilotRoles(value) {
  const roles = cleanStringArray(value, { maxItems: 2, maxLength: 20 })
    .map((role) => role.toLowerCase())
    .filter((role) => ['cliente', 'prestador'].includes(role));
  return [...new Set(roles)];
}

async function requirePilotParticipant({ database = db, uid, role }) {
  if (!pilotAllowlistRequired()) {
    return { active: true, bypassed: true, roles: ['cliente', 'prestador'] };
  }
  const snapshot = await database.collection('pilot_participants').doc(uid).get();
  const participant = snapshot.exists ? snapshot.data() : null;
  const roles = normalizedPilotRoles(participant && participant.roles);
  if (!participant || participant.status !== 'active' || !roles.includes(role)) {
    throw new HttpsError(
      'permission-denied',
      'Esta conta ainda nao faz parte do piloto controlado. Contacta o suporte.',
    );
  }
  const city = normalizeSafetyText(participant.city || '');
  if (!['maputo', 'matola'].includes(city)) {
    throw new HttpsError('failed-precondition', 'O piloto esta limitado a Maputo e Matola.');
  }
  return { ...participant, active: true, roles };
}

async function pilotParticipantIsActive({ database = db, uid, role }) {
  try {
    await requirePilotParticipant({ database, uid, role });
    return true;
  } catch (_) {
    return false;
  }
}

function enforcePilotOrderLocation(input = {}) {
  if (!envFlagEnabled('PILOT_MAPUTO_ONLY', !useEmulators)) return;
  const latitude = input.latitude === null || input.latitude === undefined
    ? null
    : Number(input.latitude);
  const longitude = input.longitude === null || input.longitude === undefined
    ? null
    : Number(input.longitude);
  if (Number.isFinite(latitude) && Number.isFinite(longitude)) {
    const minLat = Number(getEnv('PILOT_MIN_LAT', '-26.20'));
    const maxLat = Number(getEnv('PILOT_MAX_LAT', '-25.60'));
    const minLng = Number(getEnv('PILOT_MIN_LNG', '32.20'));
    const maxLng = Number(getEnv('PILOT_MAX_LNG', '33.00'));
    if (latitude >= minLat && latitude <= maxLat && longitude >= minLng && longitude <= maxLng) {
      return;
    }
    throw new HttpsError('failed-precondition', 'O pedido esta fora da area do piloto Maputo/Matola.');
  }
  const address = normalizeSafetyText(input.enderecoTexto || input.zone || input.city || '');
  const allowedZones = getEnv('PILOT_ALLOWED_ZONES', 'maputo,matola')
    .split(',')
    .map(normalizeSafetyText)
    .filter(Boolean);
  if (!address || !allowedZones.some((zone) => address.includes(zone))) {
    throw new HttpsError(
      'failed-precondition',
      'Confirma uma localizacao em Maputo ou Matola para publicar no piloto.',
    );
  }
}

async function acceptLegalDocumentsCore({ database = db, auth, data = {} }) {
  const uid = requireVerifiedPhoneAuth(auth);
  const version = cleanString(data.version);
  const locale = cleanString(data.locale || 'pt_MZ').slice(0, 20);
  if (version !== LEGAL_DOCUMENT_VERSION) {
    throw new HttpsError('failed-precondition', 'A versao dos documentos mudou. Le novamente.');
  }
  if (data.termsAccepted !== true
    || data.privacyAccepted !== true
    || data.ageConfirmed !== true) {
    throw new HttpsError(
      'invalid-argument',
      'Aceita os documentos e confirma que tens pelo menos 18 anos.',
    );
  }

  const acceptedAt = FieldValue.serverTimestamp();
  const batch = database.batch();
  batch.set(database.collection('users_private').doc(uid), {
    legalConsent: {
      version,
      locale,
      termsAccepted: true,
      privacyAccepted: true,
      ageConfirmed: true,
      acceptedAt,
    },
    updatedAt: acceptedAt,
  }, { merge: true });
  batch.create(database.collection('legal_consent_audit').doc(), {
    uid,
    version,
    locale,
    termsAccepted: true,
    privacyAccepted: true,
    ageConfirmed: true,
    acceptedAt,
  });
  await batch.commit();
  return { ok: true, version };
}

const SUPPORT_SUBJECTS = Object.freeze({
  general: 'Duvida geral',
  order: 'Problema com um pedido',
  technical: 'Erro na aplicacao',
  safety: 'Seguranca ou denuncia',
  account: 'Conta e acesso',
  payment: 'Pagamento ou comissao',
  privacy_deletion: 'Privacidade ou eliminacao',
  other: 'Outro assunto',
});

async function createSupportTicketCore({ database = db, auth, data = {} }) {
  const uid = requireCallableUid(auth && auth.uid);
  const category = cleanString(data.category).toLowerCase();
  const message = cleanString(data.message);
  const userType = cleanString(data.userType).toLowerCase();
  const pedidoId = cleanString(data.pedidoId);
  if (!Object.prototype.hasOwnProperty.call(SUPPORT_SUBJECTS, category)) {
    throw new HttpsError('invalid-argument', 'Categoria de suporte invalida.');
  }
  if (message.length < 10 || message.length > 2000) {
    throw new HttpsError('invalid-argument', 'A mensagem deve ter entre 10 e 2000 caracteres.');
  }
  if (!['cliente', 'prestador'].includes(userType)) {
    throw new HttpsError('invalid-argument', 'Tipo de utilizador invalido.');
  }
  if (pedidoId) {
    const pedido = await database.collection('pedidos').doc(pedidoId).get();
    const pedidoData = pedido.exists ? pedido.data() : null;
    if (!pedidoData || ![getClienteId(pedidoData), cleanString(pedidoData.prestadorId)].includes(uid)) {
      throw new HttpsError('permission-denied', 'Nao tens acesso a este pedido.');
    }
  }

  const ref = database.collection('support_tickets').doc();
  await ref.create({
    uid,
    userType,
    category,
    subject: SUPPORT_SUBJECTS[category],
    message,
    pedidoId: pedidoId || null,
    status: 'open',
    source: 'callable',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { ok: true, ticketId: ref.id };
}

async function adminSetPilotParticipantCore({
  database = db,
  auth,
  data = {},
  authAdmin = firebaseAuth,
}) {
  ensureAdmin(auth);
  const participantUid = cleanString(data.uid);
  const status = cleanString(data.status || 'active').toLowerCase();
  const roles = normalizedPilotRoles(data.roles);
  const city = cleanString(data.city || 'Maputo');
  const normalizedCity = normalizeSafetyText(city);
  const cohort = safeText(data.cohort || 'maputo-pilot-1', 80);
  const note = safeText(data.note, 500);
  if (!participantUid || participantUid.length > 128) {
    throw new HttpsError('invalid-argument', 'UID do participante invalido.');
  }
  if (!['active', 'inactive'].includes(status)) {
    throw new HttpsError('invalid-argument', 'Estado do participante invalido.');
  }
  if (status === 'active' && roles.length === 0) {
    throw new HttpsError('invalid-argument', 'Seleciona Cliente, Prestador ou ambos.');
  }
  if (!['maputo', 'matola'].includes(normalizedCity)) {
    throw new HttpsError('invalid-argument', 'O piloto aceita apenas Maputo ou Matola.');
  }
  if (status === 'active') {
    try {
      await authAdmin.getUser(participantUid);
    } catch (error) {
      if (error && error.code === 'auth/user-not-found') {
        throw new HttpsError('not-found', 'Conta Firebase inexistente.');
      }
      throw error;
    }
  }

  const ref = database.collection('pilot_participants').doc(participantUid);
  const [existing, provider, dispatch] = await Promise.all([
    ref.get(),
    database.collection('provider_public').doc(participantUid).get(),
    database.collection('provider_dispatch_private').doc(participantUid).get(),
  ]);
  const beforeStatus = existing.exists ? cleanString(existing.data().status) : '';
  const batch = database.batch();
  batch.set(ref, {
    uid: participantUid,
    status,
    roles,
    city: normalizedCity === 'matola' ? 'Matola' : 'Maputo',
    cohort,
    note: note || null,
    enrolledAt: existing.exists
      ? (existing.data().enrolledAt || FieldValue.serverTimestamp())
      : FieldValue.serverTimestamp(),
    enrolledBy: auth.uid,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.set(database.collection('users_private').doc(participantUid), {
    pilot: { status, roles, city, cohort },
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  if (provider.exists) {
    const hasServices = Array.isArray(provider.data().servicos)
      && provider.data().servicos.length > 0;
    batch.set(provider.ref, {
      isSearchable: status === 'active' && roles.includes('prestador') && hasServices,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (roles.includes('prestador') || provider.exists || dispatch.exists) {
    batch.set(database.collection('provider_dispatch_private').doc(participantUid), {
      acceptingRequests: status === 'active' && roles.includes('prestador'),
      ...(status === 'inactive' ? { isOnline: false } : {}),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  writeAdminAuditLog({
    database,
    batch,
    auth,
    action: `pilot_participant.${status}`,
    targetType: 'pilot_participant',
    targetId: participantUid,
    beforeStatus,
    afterStatus: status,
    reason: note,
    metadata: { roles, city, cohort },
  });
  await batch.commit();
  return { ok: true, uid: participantUid, status, roles, city, cohort };
}

async function adminListPilotParticipantsCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);
  const statusFilter = cleanString(data.status || 'all').toLowerCase();
  if (!['all', 'active', 'inactive'].includes(statusFilter)) {
    throw new HttpsError('invalid-argument', 'Filtro de participantes invalido.');
  }
  const snapshot = await database.collection('pilot_participants').limit(500).get();
  const participants = snapshot.docs
    .map((doc) => ({
      uid: doc.id,
      status: cleanString(doc.data().status),
      roles: normalizedPilotRoles(doc.data().roles),
      city: cleanString(doc.data().city),
      cohort: cleanString(doc.data().cohort),
      note: cleanString(doc.data().note),
      enrolledAt: toMillis(doc.data().enrolledAt),
      updatedAt: toMillis(doc.data().updatedAt),
    }))
    .filter((item) => statusFilter === 'all' || item.status === statusFilter)
    .sort((a, b) => (b.enrolledAt || 0) - (a.enrolledAt || 0));
  return { generatedAt: Date.now(), total: participants.length, participants };
}

function median(values) {
  if (!values.length) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0
    ? (sorted[middle - 1] + sorted[middle]) / 2
    : sorted[middle];
}

async function buildPilotMetricsCore({ database = db, now = Timestamp.now() } = {}) {
  const nowMs = toMillis(now) || Date.now();
  const since30 = nowMs - 30 * 24 * 60 * 60 * 1000;
  const since90 = nowMs - 90 * 24 * 60 * 60 * 1000;
  const [participantsSnap, opportunitiesSnap, pedidosSnap, commissionPaymentsSnap,
    reportsSnap, supportSnap] = await Promise.all([
    database.collection('pilot_participants').limit(2000).get(),
    database.collection('provider_opportunities').limit(5000).get(),
    database.collection('pedidos').limit(5000).get(),
    database.collection('commission_payments').limit(5000).get(),
    database.collection('reports').limit(5000).get(),
    database.collection('support_tickets').limit(5000).get(),
  ]);

  const participants = participantsSnap.docs
    .map((doc) => ({ uid: doc.id, ...doc.data() }))
    .filter((item) => item.status === 'active');
  const participantIds = new Set(participants.map((item) => item.uid));
  const providerParticipants = participants.filter((item) => (
    normalizedPilotRoles(item.roles).includes('prestador')
  ));
  const providerIds = new Set(providerParticipants.map((item) => item.uid));
  const enrolledAtByProvider = new Map(providerParticipants.map((item) => [
    item.uid,
    toMillis(item.enrolledAt || item.createdAt),
  ]));

  const providersWithOpportunity = new Set();
  opportunitiesSnap.docs.forEach((doc) => {
    const data = doc.data() || {};
    const providerId = cleanString(data.providerId);
    if (providerIds.has(providerId)) providersWithOpportunity.add(providerId);
  });

  let requestsCreated = 0;
  let requestsWithResponse = 0;
  let requestsCompleted = 0;
  let requestsCancelled = 0;
  let gmvMzn = 0;
  let providerEarningsMzn = 0;
  let commissionDueMzn = 0;
  const firstCompletedAtByProvider = new Map();
  const activeProviders30 = new Set();
  const activeProviders90 = new Set();
  const completedByClient = new Map();

  pedidosSnap.docs.forEach((doc) => {
    const data = doc.data() || {};
    const clientId = cleanString(getClienteId(data));
    const providerId = cleanString(data.prestadorId);
    if (!participantIds.has(clientId) && !providerIds.has(providerId)) return;
    requestsCreated += 1;
    const status = cleanString(data.status || data.estado).toLowerCase();
    if (providerId || ['aceito', 'em_andamento', 'concluido'].includes(status)) {
      requestsWithResponse += 1;
    }
    if (status === 'cancelado') requestsCancelled += 1;
    if (status !== 'concluido') return;
    requestsCompleted += 1;
    const finalValue = Number(data.precoFinal ?? data.preco ?? data.earningsTotal ?? 0);
    const providerEarnings = Number(data.earningsProvider ?? finalValue);
    const commission = Number(data.commissionPlatform ?? 0);
    if (Number.isFinite(finalValue) && finalValue > 0) gmvMzn += finalValue;
    if (Number.isFinite(providerEarnings) && providerEarnings > 0) {
      providerEarningsMzn += providerEarnings;
    }
    if (Number.isFinite(commission) && commission > 0) commissionDueMzn += commission;
    const completedAt = toMillis(data.completedAt || data.updatedAt || data.createdAt);
    if (providerIds.has(providerId) && completedAt) {
      const previous = firstCompletedAtByProvider.get(providerId);
      if (!previous || completedAt < previous) firstCompletedAtByProvider.set(providerId, completedAt);
      if (completedAt >= since30) activeProviders30.add(providerId);
      if (completedAt >= since90) activeProviders90.add(providerId);
    }
    if (participantIds.has(clientId)) {
      completedByClient.set(clientId, (completedByClient.get(clientId) || 0) + 1);
    }
  });

  let providersFirstPaid30Days = 0;
  const timeToFirstIncomeHours = [];
  providerParticipants.forEach((provider) => {
    const enrolledAt = enrolledAtByProvider.get(provider.uid);
    const firstCompletedAt = firstCompletedAtByProvider.get(provider.uid);
    if (!enrolledAt || !firstCompletedAt || firstCompletedAt < enrolledAt) return;
    const hours = (firstCompletedAt - enrolledAt) / (60 * 60 * 1000);
    timeToFirstIncomeHours.push(hours);
    if (hours <= 30 * 24) providersFirstPaid30Days += 1;
  });

  let commissionsCollectedMzn = 0;
  commissionPaymentsSnap.docs.forEach((doc) => {
    const data = doc.data() || {};
    if (!providerIds.has(cleanString(data.providerId))) return;
    const amount = Number(data.amount || 0);
    if (Number.isFinite(amount) && amount > 0) commissionsCollectedMzn += amount;
  });
  const relevantDisputeCategories = new Set(['order', 'payment', 'safety']);
  let disputesOpened = 0;
  let disputesResolved = 0;
  reportsSnap.docs.forEach((doc) => {
    const data = doc.data() || {};
    if (!participantIds.has(cleanString(data.reporterId))
      && !participantIds.has(cleanString(data.targetOwnerId))) return;
    disputesOpened += 1;
    if (['resolved', 'closed', 'actioned', 'dismissed'].includes(cleanString(data.status).toLowerCase())) {
      disputesResolved += 1;
    }
  });
  supportSnap.docs.forEach((doc) => {
    const data = doc.data() || {};
    if (!participantIds.has(cleanString(data.uid))
      || !relevantDisputeCategories.has(cleanString(data.category))) return;
    disputesOpened += 1;
    if (['resolved', 'closed'].includes(cleanString(data.status).toLowerCase())) disputesResolved += 1;
  });

  const totalProviders = providerParticipants.length;
  const returningClients = [...completedByClient.values()].filter((count) => count >= 2).length;
  const round2 = (value) => Math.round(value * 100) / 100;
  return {
    generatedAt: nowMs,
    currency: 'MZN',
    scope: 'Maputo/Matola controlled pilot',
    mission: {
      metric: 'providers_first_paid_work_within_30_days',
      numerator: providersFirstPaid30Days,
      denominator: totalProviders,
      rate: totalProviders > 0 ? providersFirstPaid30Days / totalProviders : null,
      medianTimeToFirstIncomeHours: timeToFirstIncomeHours.length
        ? round2(median(timeToFirstIncomeHours))
        : null,
    },
    providers: {
      enrolled: totalProviders,
      receivedFirstOpportunity: providersWithOpportunity.size,
      completedFirstPaidWork: firstCompletedAtByProvider.size,
      active30Days: activeProviders30.size,
      active90Days: activeProviders90.size,
    },
    requests: {
      created: requestsCreated,
      withResponse: requestsWithResponse,
      responseRate: requestsCreated > 0 ? requestsWithResponse / requestsCreated : null,
      completed: requestsCompleted,
      completionRate: requestsCreated > 0 ? requestsCompleted / requestsCreated : null,
      cancelled: requestsCancelled,
    },
    value: {
      gmvMzn: round2(gmvMzn),
      providerEarningsMzn: round2(providerEarningsMzn),
      commissionDueMzn: round2(commissionDueMzn),
      commissionsCollectedMzn: round2(commissionsCollectedMzn),
      commissionCollectionRate: commissionDueMzn > 0
        ? commissionsCollectedMzn / commissionDueMzn
        : null,
    },
    clients: { returning: returningClients },
    trustSafety: {
      disputesOpened,
      disputesResolved,
      resolutionRate: disputesOpened > 0 ? disputesResolved / disputesOpened : null,
    },
    sourceLimits: {
      participants: 2000,
      opportunities: 5000,
      pedidos: 5000,
      commissionPayments: 5000,
      reports: 5000,
      supportTickets: 5000,
    },
  };
}

const ACCOUNT_TERMINAL_ORDER_STATES = new Set([
  'concluido', 'cancelado', 'expirado', 'rejeitado', 'refunded', 'reembolsado',
]);

function isActiveAccountOrder(data = {}) {
  const status = cleanString(data.status || data.estado).toLowerCase();
  return !ACCOUNT_TERMINAL_ORDER_STATES.has(status);
}

async function findActiveAccountOrders({ database = db, uid }) {
  const snapshots = await Promise.all([
    database.collection('pedidos').where('clienteId', '==', uid).limit(200).get(),
    database.collection('pedidos').where('clientId', '==', uid).limit(200).get(),
    database.collection('pedidos').where('prestadorId', '==', uid).limit(200).get(),
  ]);
  const active = new Map();
  snapshots.forEach((snapshot) => snapshot.docs.forEach((doc) => {
    if (isActiveAccountOrder(doc.data())) active.set(doc.id, doc);
  }));
  return [...active.values()];
}

async function requestAccountDeletionCore({ database = db, auth, data = {} }) {
  const uid = requireVerifiedPhoneAuth(auth);
  await requireCurrentLegalConsent({ database, uid });
  if (cleanString(data.confirmation).toUpperCase() !== 'ELIMINAR') {
    throw new HttpsError('invalid-argument', 'Escreve ELIMINAR para confirmar.');
  }
  const activeOrders = await findActiveAccountOrders({ database, uid });
  if (activeOrders.length > 0) {
    throw new HttpsError(
      'failed-precondition',
      'Conclui ou cancela os trabalhos ativos antes de pedir a eliminacao da conta.',
    );
  }

  const requestRef = database.collection('account_deletion_requests').doc(uid);
  const existing = await requestRef.get();
  if (existing.exists && cleanString(existing.data().status) === 'pending') {
    const executeAt = existing.data().executeAt;
    return { ok: true, alreadyPending: true, executeAtMillis: toMillis(executeAt) };
  }
  const [providerPublic, dispatchPrivate, publicProfile] = await Promise.all([
    database.collection('provider_public').doc(uid).get(),
    database.collection('provider_dispatch_private').doc(uid).get(),
    database.collection('public_profiles').doc(uid).get(),
  ]);
  const executeAt = Timestamp.fromMillis(
    Date.now() + ACCOUNT_DELETION_GRACE_DAYS * 24 * 60 * 60 * 1000,
  );
  const batch = database.batch();
  batch.set(requestRef, {
    uid,
    status: 'pending',
    requestedAt: FieldValue.serverTimestamp(),
    executeAt,
    graceDays: ACCOUNT_DELETION_GRACE_DAYS,
    legalVersion: LEGAL_DOCUMENT_VERSION,
    hadProviderPublic: providerPublic.exists,
    hadDispatchPrivate: dispatchPrivate.exists,
    previousProviderSearchable: providerPublic.exists
      && providerPublic.data().isSearchable === true,
    previousAcceptingRequests: dispatchPrivate.exists
      && dispatchPrivate.data().acceptingRequests === true,
    publicProfileBackup: publicProfile.exists ? publicProfile.data() : null,
  });
  batch.set(database.collection('users_private').doc(uid), {
    accountStatus: 'deletion_pending',
    deletionRequestedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  if (providerPublic.exists) {
    batch.set(providerPublic.ref, {
      isSearchable: false,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (dispatchPrivate.exists) {
    batch.set(dispatchPrivate.ref, {
      acceptingRequests: false,
      isOnline: false,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (publicProfile.exists) batch.delete(publicProfile.ref);
  await batch.commit();
  return { ok: true, alreadyPending: false, executeAtMillis: executeAt.toMillis() };
}

async function cancelAccountDeletionCore({ database = db, auth }) {
  const uid = requireVerifiedPhoneAuth(auth);
  const requestRef = database.collection('account_deletion_requests').doc(uid);
  const snapshot = await requestRef.get();
  if (!snapshot.exists || cleanString(snapshot.data().status) !== 'pending') {
    throw new HttpsError('failed-precondition', 'Nao existe um pedido de eliminacao pendente.');
  }
  const data = snapshot.data();
  if (toMillis(data.executeAt) <= Date.now()) {
    throw new HttpsError('failed-precondition', 'O prazo para cancelar ja terminou. Contacta o suporte.');
  }
  const batch = database.batch();
  batch.set(requestRef, {
    status: 'cancelled',
    cancelledAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.set(database.collection('users_private').doc(uid), {
    accountStatus: 'active',
    deletionRequestedAt: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  if (data.hadProviderPublic === true) {
    batch.set(database.collection('provider_public').doc(uid), {
      isSearchable: data.previousProviderSearchable === true,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (data.hadDispatchPrivate === true) {
    batch.set(database.collection('provider_dispatch_private').doc(uid), {
      acceptingRequests: data.previousAcceptingRequests === true,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (data.publicProfileBackup && typeof data.publicProfileBackup === 'object') {
    batch.set(database.collection('public_profiles').doc(uid), {
      ...data.publicProfileBackup,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  return { ok: true };
}

function accountDeletionPseudonym(uid) {
  const configuredPepper = cleanString(getEnv('ACCOUNT_DELETION_PEPPER'));
  if (!configuredPepper && !useEmulators) {
    throw new Error('ACCOUNT_DELETION_PEPPER must be configured before account deletion runs.');
  }
  const pepper = configuredPepper || 'emulator-only-account-deletion-pepper';
  const digest = crypto.createHmac('sha256', pepper).update(uid).digest('hex').slice(0, 32);
  return `deleted:${digest}`;
}

async function updateMatchingDocuments({ database, collection, field, uid, update }) {
  const snapshot = await database.collection(collection).where(field, '==', uid).limit(500).get();
  if (snapshot.empty) return 0;
  const bulk = database.bulkWriter();
  snapshot.docs.forEach((doc) => bulk.update(doc.ref, update));
  await bulk.close();
  return snapshot.size;
}

async function deleteMatchingDocuments({ database, collection, field, uid }) {
  const snapshot = await database.collection(collection).where(field, '==', uid).limit(500).get();
  for (const doc of snapshot.docs) await database.recursiveDelete(doc.ref);
  return snapshot.size;
}

async function executeAccountDeletionCore({
  database = db,
  uid,
  bucket = firebaseStorage.bucket(),
  authAdmin = firebaseAuth,
  deleteStorage = true,
  deleteAuth = true,
}) {
  const requestRef = database.collection('account_deletion_requests').doc(uid);
  const request = await requestRef.get();
  if (!request.exists || !['pending', 'pending_active_work'].includes(cleanString(request.data().status))) {
    return { ok: false, skipped: true, reason: 'not_pending' };
  }
  const executeAtMillis = toMillis(request.data().executeAt);
  if (!executeAtMillis || executeAtMillis > Date.now()) {
    return { ok: false, skipped: true, reason: 'grace_period' };
  }
  const activeOrders = await findActiveAccountOrders({ database, uid });
  if (activeOrders.length > 0) {
    const retryAt = Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000);
    await requestRef.set({
      status: 'pending_active_work',
      executeAt: retryAt,
      blockedReason: 'active_work',
      checkedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { ok: false, skipped: true, reason: 'active_work', retryAtMillis: retryAt.toMillis() };
  }

  const pseudonym = accountDeletionPseudonym(uid);
  await requestRef.set({ status: 'executing', startedAt: FieldValue.serverTimestamp() }, { merge: true });
  const orderPrivateFields = {
    nomeCliente: FieldValue.delete(),
    clienteNome: FieldValue.delete(),
    clientName: FieldValue.delete(),
    clienteTelefone: FieldValue.delete(),
    telefoneCliente: FieldValue.delete(),
    morada: FieldValue.delete(),
    endereco: FieldValue.delete(),
    address: FieldValue.delete(),
    localizacaoExata: FieldValue.delete(),
    exactLocation: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  const providerPrivateFields = {
    nomePrestador: FieldValue.delete(),
    prestadorNome: FieldValue.delete(),
    providerName: FieldValue.delete(),
    prestadorTelefone: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  const counts = {};
  counts.pedidosCliente = await updateMatchingDocuments({
    database, collection: 'pedidos', field: 'clienteId', uid,
    update: { clienteId: pseudonym, ...orderPrivateFields },
  });
  counts.pedidosClientLegacy = await updateMatchingDocuments({
    database, collection: 'pedidos', field: 'clientId', uid,
    update: { clientId: pseudonym, ...orderPrivateFields },
  });
  counts.pedidosPrestador = await updateMatchingDocuments({
    database, collection: 'pedidos', field: 'prestadorId', uid,
    update: { prestadorId: pseudonym, ...providerPrivateFields },
  });
  for (const collection of ['payments', 'commission_payments', 'payment_ledger']) {
    for (const field of ['clienteId', 'prestadorId', 'uid']) {
      await updateMatchingDocuments({
        database, collection, field, uid,
        update: { [field]: pseudonym, updatedAt: FieldValue.serverTimestamp() },
      });
    }
  }
  for (const field of ['clienteId', 'prestadorId']) {
    await updateMatchingDocuments({
      database, collection: 'avaliacoes', field, uid,
      update: { [field]: pseudonym, comentario: FieldValue.delete() },
    });
  }
  counts.chatsCliente = await deleteMatchingDocuments({
    database, collection: 'chats', field: 'clienteId', uid,
  });
  counts.chatsPrestador = await deleteMatchingDocuments({
    database, collection: 'chats', field: 'prestadorId', uid,
  });
  counts.support = await deleteMatchingDocuments({
    database, collection: 'support_tickets', field: 'uid', uid,
  });

  const keyedDocuments = [
    ['users_private', uid],
    ['public_profiles', uid],
    ['provider_private', uid],
    ['provider_public', uid],
    ['provider_dispatch_private', uid],
    ['prestadores', uid],
    ['users', uid],
    ['kyc_submissions', uid],
    ['kyc_upload_grants', uid],
  ];
  for (const [collection, id] of keyedDocuments) {
    await database.recursiveDelete(database.collection(collection).doc(id));
  }
  for (const [collection, field] of [
    ['provider_custom_service_requests', 'providerId'],
    ['provider_sensitive_category_requests', 'providerId'],
    ['category_approval_requests', 'providerId'],
  ]) {
    await deleteMatchingDocuments({ database, collection, field, uid });
  }

  if (deleteStorage) {
    for (const prefix of [`users/${uid}/`, `prestadores/${uid}/`, `kyc_pending/${uid}/`]) {
      await bucket.deleteFiles({ prefix, force: true });
    }
  }
  if (deleteAuth) {
    try {
      await authAdmin.deleteUser(uid);
    } catch (error) {
      if (error && error.code !== 'auth/user-not-found') throw error;
    }
  }
  await database.collection('account_deletion_audit').doc(pseudonym.replace(':', '_')).set({
    pseudonym,
    completedAt: FieldValue.serverTimestamp(),
    retainedTransactionalRecords: true,
    legalVersion: LEGAL_DOCUMENT_VERSION,
  });
  await requestRef.delete();
  return { ok: true, pseudonym, counts };
}

function requireKycEnabled() {
  if (!envFlagEnabled('ENABLE_KYC')) {
    throw new HttpsError(
      'failed-precondition',
      'A verificacao de identidade esta temporariamente indisponivel.',
    );
  }
}

function normalizeKycDocumentPaths({ uid, submissionId, documentPaths }) {
  if (!Array.isArray(documentPaths) || documentPaths.length < 1 || documentPaths.length > 4) {
    throw new HttpsError('invalid-argument', 'Envia entre um e quatro documentos.');
  }
  const prefix = `kyc_pending/${uid}/${submissionId}/`;
  const paths = [...new Set(documentPaths.map((value) => cleanString(value)))];
  if (paths.length !== documentPaths.length || paths.some((path) => (
    !path.startsWith(prefix)
    || path.length > 500
    || path.includes('..')
  ))) {
    throw new HttpsError('invalid-argument', 'Caminho de documento invalido.');
  }
  return paths;
}

function normalizeKycDecision(value) {
  const decision = cleanString(value).toLowerCase();
  if (!['approved', 'rejected', 'needs_more_info'].includes(decision)) {
    throw new HttpsError('invalid-argument', 'Decisao KYC invalida.');
  }
  return decision;
}

async function setKycUploadClaim(uid, enabled) {
  const user = await firebaseAuth.getUser(uid);
  const claims = { ...(user.customClaims || {}) };
  if (enabled) claims.kyc_upload_enabled = true;
  else delete claims.kyc_upload_enabled;
  await firebaseAuth.setCustomUserClaims(uid, claims);
}

async function beginKycSubmissionCore({ database = db, auth }) {
  requireKycEnabled();
  const uid = requireVerifiedPhoneAuth(auth);
  const existing = await database.collection('kyc_submissions').doc(uid).get();
  const status = cleanString(existing.data() && existing.data().status);
  if (['pending_review', 'approved'].includes(status)) {
    throw new HttpsError('failed-precondition', 'Ja existe uma verificacao ativa.');
  }

  const submissionId = database.collection('kyc_upload_sessions').doc().id;
  const expiresAt = Timestamp.fromMillis(
    Date.now() + KYC_UPLOAD_WINDOW_MINUTES * 60 * 1000,
  );
  await Promise.all([
    database.collection('kyc_upload_grants').doc(uid).set({
      uid,
      submissionId,
      expiresAt,
      createdAt: FieldValue.serverTimestamp(),
    }),
    setKycUploadClaim(uid, true),
  ]);
  return {
    ok: true,
    submissionId,
    expiresAtMillis: expiresAt.toMillis(),
    consentVersion: KYC_CONSENT_VERSION,
  };
}

async function validateKycStorageObjects({ uid, paths }) {
  const bucket = firebaseStorage.bucket();
  await Promise.all(paths.map(async (path) => {
    let metadata;
    try {
      [metadata] = await bucket.file(path).getMetadata();
    } catch (error) {
      throw new HttpsError('failed-precondition', 'Um documento carregado nao foi encontrado.');
    }
    const contentType = cleanString(metadata.contentType).toLowerCase();
    const size = Number(metadata.size || 0);
    const ownerUid = cleanString(metadata.metadata && metadata.metadata.ownerUid);
    if (!contentType.startsWith('image/') || size <= 0 || size > 10 * 1024 * 1024 || ownerUid !== uid) {
      throw new HttpsError('failed-precondition', 'Documento carregado invalido.');
    }
  }));
}

async function deleteStoragePaths(paths) {
  const bucket = firebaseStorage.bucket();
  await Promise.all((Array.isArray(paths) ? paths : []).map(async (path) => {
    const cleanPath = cleanString(path);
    if (!cleanPath.startsWith('kyc_pending/')) return;
    try {
      await bucket.file(cleanPath).delete({ ignoreNotFound: true });
    } catch (error) {
      logger.warn('[kyc] Falha ao eliminar documento retido.', {
        path: cleanPath,
        error: String(error && error.message ? error.message : error),
      });
    }
  }));
}

async function submitKycCore({ database = db, auth, data = {} }) {
  requireKycEnabled();
  const uid = requireVerifiedPhoneAuth(auth);
  if (!auth.token || auth.token.kyc_upload_enabled !== true) {
    throw new HttpsError('permission-denied', 'A janela de envio KYC nao esta ativa.');
  }
  const consentVersion = cleanString(data.consentVersion);
  if (consentVersion !== KYC_CONSENT_VERSION) {
    throw new HttpsError('failed-precondition', 'E necessario aceitar o consentimento KYC atual.');
  }

  const grantRef = database.collection('kyc_upload_grants').doc(uid);
  const grantSnap = await grantRef.get();
  const grant = grantSnap.data() || {};
  const submissionId = cleanString(grant.submissionId);
  const expiresAtMs = grant.expiresAt && typeof grant.expiresAt.toMillis === 'function'
    ? grant.expiresAt.toMillis()
    : 0;
  if (!grantSnap.exists || !submissionId || expiresAtMs <= Date.now()) {
    throw new HttpsError('permission-denied', 'A janela de envio KYC expirou.');
  }
  const documentPaths = normalizeKycDocumentPaths({
    uid,
    submissionId,
    documentPaths: data.documentPaths,
  });
  await validateKycStorageObjects({ uid, paths: documentPaths });

  const submissionRef = database.collection('kyc_submissions').doc(uid);
  const previous = await submissionRef.get();
  const previousData = previous.data() || {};
  const previousStatus = cleanString(previousData.status);
  if (['pending_review', 'approved'].includes(previousStatus)) {
    throw new HttpsError('failed-precondition', 'Ja existe uma verificacao ativa.');
  }
  const retentionDeleteAt = Timestamp.fromMillis(
    Date.now() + KYC_RETENTION_DAYS * 24 * 60 * 60 * 1000,
  );
  const batch = database.batch();
  batch.set(submissionRef, {
    providerId: uid,
    submissionId,
    status: 'pending_review',
    documentPaths,
    consentVersion,
    consentAt: FieldValue.serverTimestamp(),
    submittedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    retentionDeleteAt,
    reviewedBy: FieldValue.delete(),
    reviewedAt: FieldValue.delete(),
    decisionReason: FieldValue.delete(),
  }, { merge: true });
  batch.delete(grantRef);
  batch.create(database.collection('security_event_logs').doc(), {
    actorUid: uid,
    action: 'kyc.submitted',
    targetType: 'kyc_submission',
    targetId: uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  await setKycUploadClaim(uid, false);
  const previousPaths = (previousData.documentPaths || [])
    .filter((path) => !documentPaths.includes(path));
  await deleteStoragePaths(previousPaths);
  return { ok: true, status: 'pending_review', retentionDeleteAtMillis: retentionDeleteAt.toMillis() };
}

async function deleteMyKycSubmissionCore({ database = db, auth }) {
  const uid = requireCallableUid(auth && auth.uid);
  const submissionRef = database.collection('kyc_submissions').doc(uid);
  const [submission, grant] = await Promise.all([
    submissionRef.get(),
    database.collection('kyc_upload_grants').doc(uid).get(),
  ]);
  const paths = submission.exists ? (submission.data().documentPaths || []) : [];
  const batch = database.batch();
  if (submission.exists) batch.delete(submissionRef);
  if (grant.exists) batch.delete(grant.ref);
  batch.set(database.collection('provider_public').doc(uid), {
    'trustSignals.identityConfirmed': false,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  batch.create(database.collection('security_event_logs').doc(), {
    actorUid: uid,
    action: 'kyc.deleted_by_owner',
    targetType: 'kyc_submission',
    targetId: uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  await Promise.all([deleteStoragePaths(paths), setKycUploadClaim(uid, false)]);
  return { ok: true };
}

async function getKycReviewDocumentsCore({ database = db, auth, providerId }) {
  ensureAdmin(auth);
  const cleanProviderId = cleanString(providerId);
  if (!cleanProviderId) throw new HttpsError('invalid-argument', 'providerId obrigatorio.');
  const submission = await database.collection('kyc_submissions').doc(cleanProviderId).get();
  if (!submission.exists) throw new HttpsError('not-found', 'Submissao KYC inexistente.');
  const data = submission.data() || {};
  const expires = Date.now() + 10 * 60 * 1000;
  const bucket = firebaseStorage.bucket();
  const documents = await Promise.all((data.documentPaths || []).map(async (path) => {
    const [url] = await bucket.file(path).getSignedUrl({ version: 'v4', action: 'read', expires });
    return { path, url, expiresAtMillis: expires };
  }));
  await writeAdminAuditLog({
    database,
    auth,
    action: 'kyc.view_documents',
    targetType: 'kyc_submission',
    targetId: cleanProviderId,
    beforeStatus: cleanString(data.status),
  });
  return { providerId: cleanProviderId, status: data.status || 'unknown', documents };
}

async function reviewKycSubmissionCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);
  const providerId = cleanString(data.providerId);
  if (!providerId) throw new HttpsError('invalid-argument', 'providerId obrigatorio.');
  const decision = normalizeKycDecision(data.decision);
  const reason = safeText(data.reason, 500);
  if (decision !== 'approved' && reason.length < 5) {
    throw new HttpsError('invalid-argument', 'Indica o motivo da decisao.');
  }
  const submissionRef = database.collection('kyc_submissions').doc(providerId);
  const submission = await submissionRef.get();
  if (!submission.exists) throw new HttpsError('not-found', 'Submissao KYC inexistente.');
  const beforeStatus = cleanString(submission.data().status);
  if (beforeStatus !== 'pending_review') {
    throw new HttpsError('failed-precondition', 'Esta submissao ja foi decidida.');
  }
  const batch = database.batch();
  batch.set(submissionRef, {
    status: decision,
    reviewedBy: auth.uid,
    reviewedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    decisionReason: reason || null,
  }, { merge: true });
  if (decision === 'approved') {
    batch.set(database.collection('provider_public').doc(providerId), {
      'trustSignals.identityConfirmed': true,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  await writeAdminAuditLog({
    database,
    batch,
    auth,
    action: `kyc.${decision}`,
    targetType: 'kyc_submission',
    targetId: providerId,
    beforeStatus,
    afterStatus: decision,
    reason,
  });
  await batch.commit();
  return { ok: true, providerId, status: decision };
}

const PRIVATE_STORAGE_SIGNED_URL_TTL_MS = 5 * 60 * 1000;

function normalizePrivateStoragePath(value) {
  const storagePath = cleanString(value);
  if (!storagePath || storagePath.length > 500
    || storagePath.startsWith('/') || storagePath.endsWith('/')
    || storagePath.includes('\\') || storagePath.includes('//')) {
    throw new HttpsError('invalid-argument', 'Caminho privado invalido.');
  }
  const segments = storagePath.split('/');
  if (segments.some((segment) => !segment || segment === '.' || segment === '..')) {
    throw new HttpsError('invalid-argument', 'Caminho privado invalido.');
  }
  const [scope, ownerOrPedidoId, folder] = segments;
  if (scope === 'temp' && segments.length >= 4 && folder === 'anexos') {
    return { storagePath, scope, ownerId: ownerOrPedidoId, pedidoId: '' };
  }
  if (scope === 'pedidos' && segments.length >= 4 && folder === 'anexos') {
    return { storagePath, scope, ownerId: '', pedidoId: ownerOrPedidoId };
  }
  if (scope === 'chats' && segments.length >= 4
    && ['images', 'files', 'audio'].includes(folder)) {
    return { storagePath, scope, ownerId: '', pedidoId: ownerOrPedidoId };
  }
  throw new HttpsError('invalid-argument', 'Caminho fora das areas privadas permitidas.');
}

function authIsAdmin(auth) {
  return !!(auth && auth.token && auth.token.admin === true);
}

async function authorizePrivateStoragePath({ database = db, auth, storagePath }) {
  if (!auth || !auth.uid) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  const parsed = normalizePrivateStoragePath(storagePath);
  if (authIsAdmin(auth)) return parsed;
  if (parsed.scope === 'temp') {
    if (parsed.ownerId !== auth.uid) {
      throw new HttpsError('permission-denied', 'Sem acesso a este anexo temporario.');
    }
    return parsed;
  }
  const pedido = await database.collection('pedidos').doc(parsed.pedidoId).get();
  const data = pedido.exists ? (pedido.data() || {}) : null;
  if (!data || (getClienteId(data) !== auth.uid && cleanString(data.prestadorId) !== auth.uid)) {
    throw new HttpsError('permission-denied', 'Sem acesso aos anexos deste pedido.');
  }
  return parsed;
}

function maxPrivateStorageBytes(parsed) {
  return parsed.scope === 'chats' && parsed.storagePath.split('/')[2] === 'images'
    ? 15 * 1024 * 1024
    : 20 * 1024 * 1024;
}

async function finalizePrivateStorageUploadCore({
  database = db,
  storage = firebaseStorage,
  auth,
  data = {},
}) {
  const parsed = await authorizePrivateStoragePath({
    database,
    auth,
    storagePath: data.path,
  });
  const file = storage.bucket().file(parsed.storagePath);
  let metadata;
  try {
    [metadata] = await file.getMetadata();
  } catch (_) {
    throw new HttpsError('not-found', 'Anexo privado nao encontrado.');
  }
  const size = Number(metadata.size || 0);
  if (!Number.isFinite(size) || size <= 0 || size > maxPrivateStorageBytes(parsed)) {
    throw new HttpsError('failed-precondition', 'Tamanho do anexo privado invalido.');
  }
  await file.setMetadata({
    cacheControl: 'private, no-store, max-age=0',
    metadata: {
      ...(metadata.metadata || {}),
      firebaseStorageDownloadTokens: null,
      chegajaPrivateAccess: 'authenticated',
    },
  });
  return { ok: true, path: parsed.storagePath, persistentDownloadTokenRemoved: true };
}

async function getPrivateStorageReadUrlCore({
  database = db,
  storage = firebaseStorage,
  auth,
  data = {},
}) {
  const parsed = await authorizePrivateStoragePath({
    database,
    auth,
    storagePath: data.path,
  });
  const expiresAtMillis = Date.now() + PRIVATE_STORAGE_SIGNED_URL_TTL_MS;
  const file = storage.bucket().file(parsed.storagePath);
  let url;
  try {
    [url] = await file.getSignedUrl({
      version: 'v4',
      action: 'read',
      expires: expiresAtMillis,
    });
  } catch (_) {
    throw new HttpsError('not-found', 'Anexo privado nao encontrado.');
  }
  return { path: parsed.storagePath, url, expiresAtMillis };
}

function cleanStringArray(value, { maxItems = 20, maxLength = 180 } = {}) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value
    .map((item) => cleanString(item))
    .filter((item) => item && item.length <= maxLength))]
    .slice(0, maxItems);
}

function catalogDocumentIsActive(data) {
  if (!data || typeof data !== 'object') return false;
  if (data.isActive === true || data.ativo === true) return true;
  return false;
}

async function resolveServicePolicy(database, serviceId) {
  const id = cleanString(serviceId);
  if (!id || id.length > 120) {
    throw new HttpsError('invalid-argument', 'Seleciona um servico valido.');
  }
  const policyRef = database.collection('service_catalog_policies').doc(id);
  const legacyRef = database.collection('servicos').doc(id);
  const [policySnap, legacySnap] = await Promise.all([policyRef.get(), legacyRef.get()]);
  const source = policySnap.exists ? policySnap.data() : (legacySnap.exists ? legacySnap.data() : null);
  if (!source || !catalogDocumentIsActive(source)) {
    throw new HttpsError('failed-precondition', 'Este servico nao esta ativo no catalogo.');
  }
  const requirementId = cleanString(
    source.sensitiveRequirementId || source.categoryRequirementId || id,
  );
  const requirementSnap = await database.collection('categoryRequirements').doc(requirementId).get();
  const requirement = requirementSnap.exists ? (requirementSnap.data() || {}) : {};
  const requirementActive = requirement.isActive === true;
  const riskLevel = cleanString(
    (requirementActive && requirement.riskLevel) || source.riskLevel || 'normal',
  ).toLowerCase();
  if (riskLevel === 'prohibited') {
    throw new HttpsError('permission-denied', 'Este tipo de servico nao e permitido no ChegaJa.');
  }
  return {
    id,
    name: safeText(source.name || source.nome || requirement.categoryName || id, 160),
    riskLevel,
    approvalRequired: requirementActive
      ? requirement.approvalRequired === true
      : source.approvalRequired === true,
    requirementId,
    requirementName: safeText(requirement.categoryName || source.name || source.nome || id, 160),
  };
}

function parsePedidoSchedule(value, mode) {
  if (mode !== 'AGENDADO') return null;
  let timestamp = value;
  if (value instanceof Date) timestamp = Timestamp.fromDate(value);
  if (!timestamp || typeof timestamp.toMillis !== 'function') {
    throw new HttpsError('invalid-argument', 'Data de agendamento obrigatoria.');
  }
  const millis = timestamp.toMillis();
  const min = Date.now() + 15 * 60 * 1000;
  const max = Date.now() + 366 * 24 * 60 * 60 * 1000;
  if (millis < min || millis > max) {
    throw new HttpsError('invalid-argument', 'Data de agendamento fora do intervalo permitido.');
  }
  return Timestamp.fromMillis(millis);
}

function buildSecurePedidoData({ uid, input, policy, moderationStatus, requestedProviderId = '' }) {
  const title = cleanString(input.titulo);
  const description = cleanString(input.descricao);
  if (title.length < 4 || title.length > 180 || description.length > 2000) {
    throw new HttpsError('invalid-argument', 'Titulo ou descricao invalido.');
  }
  const mode = cleanString(input.modo || 'IMEDIATO').toUpperCase();
  if (!['IMEDIATO', 'AGENDADO', 'POR_PROPOSTA'].includes(mode)) {
    throw new HttpsError('invalid-argument', 'Modelo de trabalho invalido.');
  }
  const scheduledAt = parsePedidoSchedule(input.agendadoPara, mode);
  const latitude = input.latitude === null || input.latitude === undefined
    ? null
    : Number(input.latitude);
  const longitude = input.longitude === null || input.longitude === undefined
    ? null
    : Number(input.longitude);
  if ((latitude === null) !== (longitude === null)
    || (latitude !== null && (!Number.isFinite(latitude) || latitude < -90 || latitude > 90))
    || (longitude !== null && (!Number.isFinite(longitude) || longitude < -180 || longitude > 180))) {
    throw new HttpsError('invalid-argument', 'Localizacao invalida.');
  }
  const tipoPreco = cleanString(input.tipoPreco || 'a_combinar').toLowerCase();
  if (!['a_combinar', 'fixo', 'por_hora', 'por_orcamento', 'por_tarefa'].includes(tipoPreco)) {
    throw new HttpsError('invalid-argument', 'Modelo de preco invalido.');
  }
  const paymentType = cleanString(input.tipoPagamento || 'dinheiro').toLowerCase();
  if (!['dinheiro', 'cash', 'mpesa', 'emola', 'stripe'].includes(paymentType)) {
    throw new HttpsError('invalid-argument', 'Meio de pagamento invalido.');
  }
  if (!paymentMethodEnabled(paymentType)) {
    throw new HttpsError(
      'failed-precondition',
      'Este meio de pagamento ainda nao esta validado para o piloto.',
    );
  }
  const attachments = cleanStringArray(input.anexos, { maxItems: 10, maxLength: 500 });
  const custom = input.isCustomService === true;
  const customName = custom ? safeText(input.customServiceName || policy.name, 160) : '';
  const customDescription = custom ? safeText(input.customServiceDescription, 1000) : '';
  const customSearchTerms = custom
    ? cleanStringArray(input.customServiceSearchTerms, { maxItems: 30, maxLength: 80 })
        .map(normalizeSafetyText)
        .filter(Boolean)
    : [];
  const geo = latitude === null ? null : {
    geohash: geofire.geohashForLocation([latitude, longitude]),
    geopoint: new GeoPoint(latitude, longitude),
  };
  const providerId = moderationStatus === 'pending_review' ? null : (requestedProviderId || null);
  const state = providerId ? 'aguarda_resposta_prestador' : 'criado';
  return {
    clienteId: uid,
    prestadorId: providerId,
    requestedProviderId: moderationStatus === 'pending_review' && requestedProviderId
      ? requestedProviderId
      : null,
    servicoId: policy.id,
    servicoNome: custom ? customName : policy.name,
    categoria: custom ? customName : policy.name,
    titulo: title,
    descricao: description || null,
    modo: mode,
    agendadoPara: scheduledAt,
    tipoPreco,
    tipoPagamento: paymentType === 'cash' ? 'dinheiro' : paymentType,
    currency: cleanString(getEnv('DEFAULT_CURRENCY_CODE', 'MZN')).toUpperCase() || 'MZN',
    estado: state,
    status: state,
    latitude,
    longitude,
    ...(geo ? { geo } : {}),
    enderecoTexto: safeText(input.enderecoTexto, 300) || null,
    anexos: attachments,
    categoryApprovalRequired: policy.approvalRequired === true,
    ...(policy.approvalRequired ? {
      categoryRequirementId: policy.requirementId,
      categoryRequirementName: policy.requirementName,
      categoryRiskLevel: policy.riskLevel,
    } : {}),
    isCustomService: custom,
    ...(custom ? {
      customServiceName: customName,
      customServiceDescription: customDescription || null,
      customServiceSearchTerms: [...new Set(customSearchTerms)].slice(0, 30),
    } : {}),
    moderationStatus,
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: 'nenhum',
    lastAuthoritativeFunction: 'pedidos_createSecure',
  };
}

async function promotePedidoAttachments({
  storage = firebaseStorage,
  uid,
  pedidoId,
  attachments,
}) {
  const values = cleanStringArray(attachments, { maxItems: 10, maxLength: 500 });
  if (values.length === 0) return [];
  const bucket = storage.bucket();
  const promoted = [];
  for (const value of values) {
    const parsed = normalizePrivateStoragePath(value);
    if (parsed.scope === 'pedidos' && parsed.pedidoId === pedidoId) {
      promoted.push(parsed.storagePath);
      continue;
    }
    if (parsed.scope !== 'temp' || parsed.ownerId !== uid) {
      throw new HttpsError('permission-denied', 'Anexo de pedido fora da area autorizada.');
    }
    const fileName = parsed.storagePath.split('/').pop();
    const destination = `pedidos/${pedidoId}/anexos/${fileName}`;
    const sourceFile = bucket.file(parsed.storagePath);
    const destinationFile = bucket.file(destination);
    let metadata;
    try {
      [metadata] = await sourceFile.getMetadata();
    } catch (_) {
      throw new HttpsError('not-found', 'Anexo temporario nao encontrado.');
    }
    const size = Number(metadata.size || 0);
    if (!Number.isFinite(size) || size <= 0 || size > 20 * 1024 * 1024) {
      throw new HttpsError('failed-precondition', 'Tamanho do anexo invalido.');
    }
    await sourceFile.copy(destinationFile);
    await destinationFile.setMetadata({
      cacheControl: 'private, no-store, max-age=0',
      metadata: {
        ...(metadata.metadata || {}),
        firebaseStorageDownloadTokens: null,
        chegajaPrivateAccess: 'authenticated',
      },
    });
    promoted.push(destination);
  }
  return promoted;
}

async function validateRequestedProvider(database, requestedProviderId, pedido) {
  const providerId = cleanString(requestedProviderId);
  if (!providerId) return '';
  const providerSnap = await database.collection('provider_public').doc(providerId).get();
  if (!providerSnap.exists || providerSnap.data().isSearchable !== true) {
    throw new HttpsError('failed-precondition', 'O prestador selecionado nao esta disponivel.');
  }
  if (!providerMatchesPedido(providerSnap.data() || {}, pedido)) {
    throw new HttpsError('failed-precondition', 'O prestador nao esta elegivel para este servico.');
  }
  return providerId;
}

async function createSecurePedidoCore({ database = db, auth, data = {} }) {
  const uid = requireVerifiedPhoneAuth(auth);
  const custom = data.isCustomService === true;
  const serviceId = cleanString(data.servicoId);
  let policy;
  let moderationStatus = 'approved';
  const safety = classifyServerServiceText([
    data.titulo,
    data.descricao,
    data.customServiceName,
    data.customServiceDescription,
    ...(Array.isArray(data.customServiceSearchTerms) ? data.customServiceSearchTerms : []),
  ]);
  if (safety.decision === 'block') {
    throw new HttpsError('permission-denied', 'Este tipo de servico nao e permitido no ChegaJa.');
  }
  if (custom) {
    const customName = cleanString(data.customServiceName || data.servicoNome);
    if (customName.length < 3 || customName.length > 160) {
      throw new HttpsError('invalid-argument', 'Descreve o servico personalizado.');
    }
    policy = {
      id: `custom_${normalizeSafetyText(customName).replace(/\s+/g, '_').slice(0, 80) || 'servico_personalizado'}`,
      name: customName,
      riskLevel: 'review',
      approvalRequired: false,
      requirementId: '',
      requirementName: '',
    };
    moderationStatus = 'pending_review';
  } else {
    policy = await resolveServicePolicy(database, serviceId);
    if (safety.decision === 'pending_review') moderationStatus = 'pending_review';
  }

  const validationPayload = buildSecurePedidoData({
    uid,
    input: { ...data, anexos: [] },
    policy,
    moderationStatus,
    requestedProviderId: cleanString(data.prestadorId),
  });
  const requestedProviderId = await validateRequestedProvider(
    database,
    data.prestadorId,
    validationPayload,
  );
  const ref = database.collection('pedidos').doc();
  const attachmentPaths = await promotePedidoAttachments({
    uid,
    pedidoId: ref.id,
    attachments: data.anexos,
  });
  const secureInput = { ...data, anexos: attachmentPaths };
  const payload = buildSecurePedidoData({
    uid,
    input: secureInput,
    policy,
    moderationStatus,
    requestedProviderId,
  });
  const batch = database.batch();
  batch.create(ref, {
    ...payload,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  if (moderationStatus === 'pending_review') {
    batch.set(database.collection('service_moderation_queue').doc(ref.id), {
      pedidoId: ref.id,
      requesterId: uid,
      serviceId: policy.id,
      title: payload.customServiceName || payload.servicoNome,
      description: payload.customServiceDescription || payload.descricao || '',
      status: 'pending_review',
      safetyMatches: safety.matches,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  try {
    await batch.commit();
  } catch (error) {
    await Promise.all(attachmentPaths.map((storagePath) => (
      firebaseStorage.bucket().file(storagePath).delete({ ignoreNotFound: true })
        .catch(() => undefined)
    )));
    throw error;
  }
  return { ok: true, pedidoId: ref.id, moderationStatus };
}

async function updateSecurePedidoCore({ database = db, auth, data = {} }) {
  const uid = requireVerifiedPhoneAuth(auth);
  const pedidoId = requirePedidoId(data);
  const currentRef = database.collection('pedidos').doc(pedidoId);
  const currentSnap = await currentRef.get();
  if (!currentSnap.exists) throw new HttpsError('not-found', 'Pedido nao encontrado.');
  const current = currentSnap.data() || {};
  if (getClienteId(current) !== uid || getPedidoEstado(current) !== 'criado' || current.prestadorId) {
    throw new HttpsError('failed-precondition', 'Este pedido ja nao pode ser editado.');
  }
  const requestedAttachments = Object.prototype.hasOwnProperty.call(data, 'anexos')
    ? data.anexos
    : current.anexos;
  const attachmentPaths = await promotePedidoAttachments({
    uid,
    pedidoId,
    attachments: requestedAttachments,
  });
  const merged = { ...current, ...data, anexos: attachmentPaths, prestadorId: null };
  const custom = merged.isCustomService === true;
  const safety = classifyServerServiceText([
    merged.titulo,
    merged.descricao,
    merged.customServiceName,
    merged.customServiceDescription,
  ]);
  if (safety.decision === 'block') {
    throw new HttpsError('permission-denied', 'Este tipo de servico nao e permitido no ChegaJa.');
  }
  const policy = custom
    ? {
      id: `custom_${normalizeSafetyText(merged.customServiceName || merged.servicoNome)
        .replace(/\s+/g, '_').slice(0, 80) || 'servico_personalizado'}`,
      name: cleanString(merged.customServiceName || merged.servicoNome),
      riskLevel: 'review',
      approvalRequired: false,
      requirementId: '',
      requirementName: '',
    }
    : await resolveServicePolicy(database, merged.servicoId);
  const moderationStatus = custom || safety.decision === 'pending_review'
    ? 'pending_review'
    : 'approved';
  const payload = buildSecurePedidoData({ uid, input: merged, policy, moderationStatus });
  const batch = database.batch();
  batch.update(currentRef, {
    ...payload,
    createdAt: current.createdAt,
    updatedAt: FieldValue.serverTimestamp(),
    lastAuthoritativeFunction: 'pedidos_updateSecure',
  });
  const queueRef = database.collection('service_moderation_queue').doc(pedidoId);
  if (moderationStatus === 'pending_review') {
    batch.set(queueRef, {
      pedidoId,
      requesterId: uid,
      serviceId: policy.id,
      title: payload.customServiceName || payload.servicoNome,
      description: payload.customServiceDescription || payload.descricao || '',
      status: 'pending_review',
      safetyMatches: safety.matches,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  } else {
    batch.delete(queueRef);
  }
  await batch.commit();
  return { ok: true, pedidoId, moderationStatus };
}

async function reviewPedidoServiceCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);
  const pedidoId = requirePedidoId(data);
  const decision = cleanString(data.decision).toLowerCase();
  if (!['approved', 'rejected'].includes(decision)) {
    throw new HttpsError('invalid-argument', 'Decisao invalida.');
  }
  const reason = safeText(data.reason, 500);
  if (decision === 'rejected' && reason.length < 5) {
    throw new HttpsError('invalid-argument', 'Indica o motivo da rejeicao.');
  }
  const pedidoRef = database.collection('pedidos').doc(pedidoId);
  const pedidoSnap = await pedidoRef.get();
  if (!pedidoSnap.exists) throw new HttpsError('not-found', 'Pedido nao encontrado.');
  const pedido = pedidoSnap.data() || {};
  if (pedido.moderationStatus !== 'pending_review') {
    throw new HttpsError('failed-precondition', 'Pedido nao esta pendente de moderacao.');
  }
  const requestedProviderId = cleanString(pedido.requestedProviderId);
  const nextStatus = decision === 'approved' && requestedProviderId
    ? 'aguarda_resposta_prestador'
    : (decision === 'approved' ? 'criado' : 'cancelado');
  const batch = database.batch();
  batch.update(pedidoRef, {
    moderationStatus: decision,
    moderationReviewedBy: auth.uid,
    moderationReviewedAt: FieldValue.serverTimestamp(),
    moderationDecisionReason: reason || null,
    prestadorId: decision === 'approved' && requestedProviderId ? requestedProviderId : null,
    estado: nextStatus,
    status: nextStatus,
    updatedAt: FieldValue.serverTimestamp(),
  });
  batch.set(database.collection('service_moderation_queue').doc(pedidoId), {
    status: decision,
    reviewedBy: auth.uid,
    reviewedAt: FieldValue.serverTimestamp(),
    decisionReason: reason || null,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  await writeAdminAuditLog({
    database,
    batch,
    auth,
    action: `service_request.${decision}`,
    targetType: 'pedido',
    targetId: pedidoId,
    beforeStatus: 'pending_review',
    afterStatus: decision,
    reason,
  });
  await batch.commit();
  return { ok: true, pedidoId, moderationStatus: decision };
}

function providerApprovalIsActive(data) {
  if (!data || data.status !== 'approved') return false;
  if (!data.expiresAt) return true;
  return typeof data.expiresAt.toMillis === 'function' && data.expiresAt.toMillis() > Date.now();
}

function sanitizeProviderCustomService(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const title = safeText(value.title || value.name, 80);
  if (title.length < 3) return null;
  const id = `custom_${normalizeSafetyText(title).replace(/\s+/g, '_').slice(0, 80) || 'servico_personalizado'}`;
  const description = safeText(value.description, 280);
  const aliases = cleanStringArray(value.aliases, { maxItems: 10, maxLength: 40 });
  const safety = classifyServerServiceText([title, description, ...aliases]);
  return {
    id,
    title,
    name: title,
    description,
    aliases,
    normalizedTitle: normalizeSafetyText(title),
    normalizedSearchTerms: [...new Set([title, description, ...aliases]
      .map(normalizeSafetyText).filter(Boolean))].slice(0, 30),
    parentCategoryId: 'other',
    taxonomySubcategoryId: 'other_service',
    trustSafetyDecision: safety.decision,
    trustSafetyReasonCodes: safety.matches,
    isActive: true,
  };
}

async function updateProviderServicesCore({ database = db, auth, data = {} }) {
  const uid = requireVerifiedPhoneAuth(auth);
  const requestedIds = cleanStringArray(data.serviceIds, { maxItems: 50, maxLength: 120 });
  const rawCustom = Array.isArray(data.customServices) ? data.customServices.slice(0, 10) : [];
  const customServices = rawCustom.map(sanitizeProviderCustomService).filter(Boolean);
  if (requestedIds.length === 0 && customServices.length === 0) {
    throw new HttpsError('invalid-argument', 'Seleciona pelo menos um servico.');
  }

  const acceptedPolicies = [];
  const pendingSensitiveIds = [];
  for (const serviceId of requestedIds.filter((id) => !id.startsWith('custom_'))) {
    const policy = await resolveServicePolicy(database, serviceId);
    if (!policy.approvalRequired) {
      acceptedPolicies.push(policy);
      continue;
    }
    const approval = await database.collection('provider_private').doc(uid)
      .collection('categoryApprovals').doc(policy.requirementId).get();
    if (approval.exists && providerApprovalIsActive(approval.data())) {
      acceptedPolicies.push(policy);
    } else {
      pendingSensitiveIds.push(policy.id);
    }
  }

  const approvedCustom = [];
  const pendingCustomIds = [];
  const customBatch = database.batch();
  for (const custom of customServices) {
    if (custom.trustSafetyDecision === 'block') continue;
    const requestRef = database.collection('provider_custom_service_requests').doc(`${uid}_${custom.id}`);
    const request = await requestRef.get();
    if (request.exists && request.data().status === 'approved') {
      approvedCustom.push({ ...custom, trustSafetyDecision: 'approved' });
    } else {
      pendingCustomIds.push(custom.id);
      customBatch.set(requestRef, {
        providerId: uid,
        serviceId: custom.id,
        service: custom,
        status: 'pending_review',
        createdAt: request.exists ? (request.data().createdAt || FieldValue.serverTimestamp()) : FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }
  await customBatch.commit();

  const serviceIds = [
    ...acceptedPolicies.map((policy) => policy.id),
    ...approvedCustom.map((service) => service.id),
  ];
  const serviceNames = [
    ...acceptedPolicies.map((policy) => policy.name),
    ...approvedCustom.map((service) => service.title),
  ];
  const customNames = approvedCustom.map((service) => service.title);
  const customTerms = [...new Set(approvedCustom.flatMap((service) => service.normalizedSearchTerms))];
  const now = FieldValue.serverTimestamp();
  const batch = database.batch();
  batch.set(database.collection('provider_public').doc(uid), {
    uid,
    servicos: serviceIds,
    servicosNomes: serviceNames,
    categories: serviceIds,
    customServices: approvedCustom,
    customServiceNames: customNames,
    customServiceSearchTerms: customTerms,
    customServiceUpdatedAt: now,
    updatedAt: now,
  }, { merge: true });
  batch.set(database.collection('provider_dispatch_private').doc(uid), {
    providerId: uid,
    servicos: serviceIds,
    servicosNomes: serviceNames,
    updatedAt: now,
  }, { merge: true });
  batch.set(database.collection('provider_private').doc(uid), {
    providerId: uid,
    selectedServiceIds: requestedIds,
    pendingSensitiveServiceIds: pendingSensitiveIds,
    selectedCustomServiceIds: customServices.map((service) => service.id),
    pendingCustomServiceIds: pendingCustomIds,
    serviceSelectionUpdatedAt: now,
  }, { merge: true });
  await batch.commit();
  return {
    ok: true,
    serviceIds,
    pendingSensitiveIds,
    pendingCustomIds,
    blockedCustomCount: customServices.filter((service) => service.trustSafetyDecision === 'block').length,
  };
}

const CATEGORY_EVIDENCE_TYPES = new Set([
  'certificate', 'license', 'work_experience', 'portfolio_reference',
  'external_profile', 'declaration', 'other',
]);

async function submitSensitiveCategoryRequestCore({ database = db, auth, data = {} }) {
  const uid = requireVerifiedPhoneAuth(auth);
  const categoryId = cleanString(data.categoryId);
  if (!categoryId) throw new HttpsError('invalid-argument', 'Categoria obrigatoria.');
  const requirement = await database.collection('categoryRequirements').doc(categoryId).get();
  const requirementData = requirement.data() || {};
  if (!requirement.exists || requirementData.isActive !== true
    || requirementData.approvalRequired !== true
    || requirementData.riskLevel === 'prohibited') {
    throw new HttpsError('failed-precondition', 'Categoria nao disponivel para aprovacao.');
  }
  const evidenceTypes = cleanStringArray(data.evidenceTypes, { maxItems: 10, maxLength: 60 })
    .filter((type) => CATEGORY_EVIDENCE_TYPES.has(type));
  const evidenceText = safeText(data.evidenceText, 2000);
  const documentRefs = cleanStringArray(data.documentRefs, { maxItems: 20, maxLength: 500 })
    .filter((ref) => !/^https?:/i.test(ref)
      && (ref.startsWith(`category_evidence/${uid}/`) || ref.startsWith(`portfolio/${uid}/`)));
  const publicProvider = await database.collection('provider_public').doc(uid).get();
  const ownedPortfolio = new Set([
    ...((publicProvider.data() && publicProvider.data().portfolioUrls) || []),
    ...((publicProvider.data() && publicProvider.data().portfolioImages) || []),
  ].map(cleanString));
  const portfolioUrls = cleanStringArray(data.portfolioUrls, { maxItems: 20, maxLength: 1000 })
    .filter((url) => ownedPortfolio.has(url));
  if (evidenceTypes.length === 0 && !evidenceText && portfolioUrls.length === 0 && documentRefs.length === 0) {
    throw new HttpsError('invalid-argument', 'Adiciona pelo menos uma evidencia.');
  }
  const requestId = `${uid}_${categoryId}`;
  const ref = database.collection('sensitiveCategoryRequests').doc(requestId);
  const existing = await ref.get();
  if (existing.exists && existing.data().status === 'approved') {
    throw new HttpsError('failed-precondition', 'Esta categoria ja esta aprovada.');
  }
  const now = FieldValue.serverTimestamp();
  await ref.set({
    providerId: uid,
    categoryId,
    categoryName: safeText(requirementData.categoryName || categoryId, 160),
    status: 'pending_review',
    evidenceTypes,
    evidenceText: evidenceText || null,
    portfolioUrls,
    documentRefs,
    createdAt: existing.exists ? (existing.data().createdAt || now) : now,
    updatedAt: now,
    submittedAt: now,
    reviewedBy: FieldValue.delete(),
    reviewedAt: FieldValue.delete(),
    decisionReason: FieldValue.delete(),
  }, { merge: true });
  return { ok: true, requestId, status: 'pending_review' };
}

async function reviewProviderCustomServiceCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);
  const requestId = cleanString(data.requestId);
  const decision = cleanString(data.decision).toLowerCase();
  const reason = safeText(data.reason, 500);
  if (!requestId || !['approved', 'rejected'].includes(decision)) {
    throw new HttpsError('invalid-argument', 'Pedido e decisao obrigatorios.');
  }
  if (decision === 'rejected' && reason.length < 5) {
    throw new HttpsError('invalid-argument', 'Indica o motivo da rejeicao.');
  }
  const ref = database.collection('provider_custom_service_requests').doc(requestId);
  const snapshot = await ref.get();
  if (!snapshot.exists) throw new HttpsError('not-found', 'Pedido de servico inexistente.');
  const request = snapshot.data() || {};
  if (request.status !== 'pending_review') {
    throw new HttpsError('failed-precondition', 'Pedido ja decidido.');
  }
  const providerId = cleanString(request.providerId);
  const service = sanitizeProviderCustomService(request.service);
  if (!providerId || !service || service.trustSafetyDecision === 'block') {
    throw new HttpsError('failed-precondition', 'Servico personalizado invalido.');
  }
  const privateState = await database.collection('provider_private').doc(providerId).get();
  const selected = new Set(cleanStringArray(privateState.data() && privateState.data().selectedCustomServiceIds));
  const batch = database.batch();
  batch.update(ref, {
    status: decision,
    reviewedBy: auth.uid,
    reviewedAt: FieldValue.serverTimestamp(),
    decisionReason: reason || null,
    updatedAt: FieldValue.serverTimestamp(),
  });
  if (decision === 'approved' && selected.has(service.id)) {
    const approvedService = { ...service, trustSafetyDecision: 'approved' };
    batch.set(database.collection('provider_public').doc(providerId), {
      servicos: FieldValue.arrayUnion(service.id),
      categories: FieldValue.arrayUnion(service.id),
      servicosNomes: FieldValue.arrayUnion(service.title),
      customServices: FieldValue.arrayUnion(approvedService),
      customServiceNames: FieldValue.arrayUnion(service.title),
      customServiceSearchTerms: FieldValue.arrayUnion(...service.normalizedSearchTerms),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    batch.set(database.collection('provider_dispatch_private').doc(providerId), {
      servicos: FieldValue.arrayUnion(service.id),
      servicosNomes: FieldValue.arrayUnion(service.title),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  await writeAdminAuditLog({
    database,
    batch,
    auth,
    action: `custom_service.${decision}`,
    targetType: 'provider_custom_service',
    targetId: requestId,
    beforeStatus: 'pending_review',
    afterStatus: decision,
    reason,
  });
  await batch.commit();
  return { ok: true, requestId, status: decision };
}

function normalizeAvaliacaoRating(value) {
  if (!Number.isInteger(value)) return null;
  if (value < 1 || value > 5) return null;
  return value;
}

function calculateAvaliacaoRatingAggregates(currentData, estrelas) {
  const currentCount = Number(currentData?.ratingCount || 0);
  const currentSum = Number(currentData?.ratingSum || 0);
  const safeCount = Number.isFinite(currentCount) && currentCount > 0
    ? Math.floor(currentCount)
    : 0;
  const safeSum = Number.isFinite(currentSum) && currentSum > 0 ? currentSum : 0;
  const rating = normalizeAvaliacaoRating(estrelas);
  if (rating === null) {
    return null;
  }
  const ratingCount = safeCount + 1;
  const ratingSum = safeSum + rating;
  const ratingAvg = ratingSum / ratingCount;
  return { ratingCount, ratingSum, ratingAvg };
}

async function onAvaliacaoCreatedCore({ database = db, avaliacaoId, avaliacao }) {
  const pedidoId = cleanString(avaliacao?.pedidoId);
  const clienteId = cleanString(avaliacao?.clienteId);
  const prestadorId = cleanString(avaliacao?.prestadorId);
  const estrelas = normalizeAvaliacaoRating(avaliacao?.estrelas);

  if (!pedidoId || !clienteId || !prestadorId || estrelas === null) {
    logger.warn('[onAvaliacaoCreated] Avaliacao ignorada por dados invalidos.', {
      avaliacaoId,
      pedidoId: maskIdentifier(pedidoId),
      clienteId: maskIdentifier(clienteId),
      prestadorId: maskIdentifier(prestadorId),
    });
    return { updated: false, reason: 'invalid-review-data' };
  }

  const expectedId = `${pedidoId}_${clienteId}`;
  if (avaliacaoId !== expectedId) {
    logger.warn('[onAvaliacaoCreated] Avaliacao ignorada por docId invalido.', {
      avaliacaoId,
      expectedId,
    });
    return { updated: false, reason: 'invalid-review-id' };
  }

  const pedidoRef = database.collection('pedidos').doc(pedidoId);
  const prestadorRef = database.collection('provider_public').doc(prestadorId);

  return database.runTransaction(async (tx) => {
    const pedidoSnap = await tx.get(pedidoRef);
    if (!pedidoSnap.exists) {
      logger.warn('[onAvaliacaoCreated] Avaliacao ignorada: pedido inexistente.', {
        avaliacaoId,
        pedidoId: maskIdentifier(pedidoId),
      });
      return { updated: false, reason: 'missing-order' };
    }

    const pedido = pedidoSnap.data() || {};
    if (
      getClienteId(pedido) !== clienteId ||
      cleanString(pedido.prestadorId) !== prestadorId ||
      getPedidoEstado(pedido) !== 'concluido'
    ) {
      logger.warn('[onAvaliacaoCreated] Avaliacao ignorada: pedido nao corresponde.', {
        avaliacaoId,
        pedidoId: maskIdentifier(pedidoId),
      });
      return { updated: false, reason: 'order-mismatch' };
    }

    const prestadorSnap = await tx.get(prestadorRef);
    if (!prestadorSnap.exists) {
      logger.warn('[onAvaliacaoCreated] Avaliacao ignorada: prestador inexistente.', {
        avaliacaoId,
        prestadorId: maskIdentifier(prestadorId),
      });
      return { updated: false, reason: 'missing-provider' };
    }

    const aggregates = calculateAvaliacaoRatingAggregates(
      prestadorSnap.data() || {},
      estrelas,
    );
    if (!aggregates) {
      return { updated: false, reason: 'invalid-rating' };
    }

    tx.set(
      prestadorRef,
      {
        ratingCount: aggregates.ratingCount,
        ratingSum: aggregates.ratingSum,
        ratingAvg: aggregates.ratingAvg,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { updated: true, ...aggregates };
  });
}

function cleanString(value) {
  return (value || '').toString().trim();
}

function maskIdentifier(value) {
  const text = cleanString(value);
  if (text.length <= 8) return text ? '***' : '';
  return `${text.slice(0, 4)}...${text.slice(-4)}`;
}

function roundMoney(value) {
  const num = Number(value);
  if (!Number.isFinite(num)) return null;
  return Math.round(num * 100) / 100;
}

function normalizedRate(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 && parsed <= 1 ? parsed : fallback;
}

function calculatePedidoEconomics(finalValue, {
  commissionRate = normalizedRate(getEnv('DEFAULT_DIGITAL_COMMISSION_RATE', '0.15'), 0.15),
  commissionCap = null,
} = {}) {
  const value = roundMoney(finalValue);
  if (value === null || value <= 0) {
    throw new HttpsError('invalid-argument', 'Valor final invalido.');
  }

  const rate = normalizedRate(commissionRate, 0);
  const rawCommission = roundMoney(value * rate);
  const parsedCap = commissionCap === null || commissionCap === undefined
    ? null
    : roundMoney(commissionCap);
  const commissionPlatform = parsedCap !== null && parsedCap >= 0
    ? Math.min(rawCommission, parsedCap)
    : rawCommission;
  const earningsProvider = roundMoney(value - commissionPlatform);

  return {
    precoFinal: value,
    preco: value,
    commissionRate: rate,
    commissionPlatform,
    earningsProvider,
    earningsTotal: value,
    currency: cleanString(getEnv('DEFAULT_CURRENCY_CODE', 'MZN')).toUpperCase() || 'MZN',
  };
}

function cashCommissionPolicy({ completedJobsCount = 0 } = {}) {
  const freeJobs = Math.max(0, Math.floor(Number(getEnv('COMMISSION_FREE_FIRST_JOBS', '2')) || 2));
  const completed = Math.max(0, Math.floor(Number(completedJobsCount) || 0));
  const configuredRate = normalizedRate(getEnv('DEFAULT_CASH_COMMISSION_RATE', '0.10'), 0.10);
  const rawCapValue = getEnv('CASH_COMMISSION_CAP_MZN', '').trim();
  const rawCap = rawCapValue ? Number(rawCapValue) : Number.NaN;
  return {
    commissionRate: completed < freeJobs ? 0 : configuredRate,
    commissionCap: Number.isFinite(rawCap) && rawCap >= 0 ? rawCap : null,
    freeCommissionJob: completed < freeJobs,
    completedJobsBefore: completed,
  };
}

function historyItem({ evento, userId, descricao }) {
  return {
    evento,
    userId,
    descricao: descricao || null,
    timestamp: Timestamp.now(),
    source: 'cloud_functions',
  };
}

function requireCallableUid(uid) {
  const cleanUid = cleanString(uid);
  if (!cleanUid) {
    throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  }
  return cleanUid;
}

function requirePedidoId(data) {
  const pedidoId = cleanString(data && data.pedidoId);
  if (!pedidoId) {
    throw new HttpsError('invalid-argument', 'pedidoId obrigatorio.');
  }
  return pedidoId;
}

function requirePositiveMoney(value, fieldName) {
  const money = roundMoney(value);
  if (money === null || money <= 0) {
    throw new HttpsError('invalid-argument', `${fieldName} invalido.`);
  }
  return money;
}

function ensureAdmin(auth) {
  if (!auth || !auth.token || auth.token.admin !== true) {
    throw new HttpsError('permission-denied', 'Apenas admin.');
  }
}

async function writeLedgerEntry({
  paymentIntentId,
  eventType,
  pedidoId = null,
  clienteId = null,
  prestadorId = null,
  status = null,
  amount = null,
  feeAmount = null,
  currency = null,
  source = 'system',
}) {
  if (!paymentIntentId || !eventType) return;
  const createdAt = FieldValue.serverTimestamp();
  const ledgerId = `${paymentIntentId}_${eventType}_${Date.now()}`;
  await db.collection('payment_ledger').doc(ledgerId).set({
    paymentIntentId,
    eventType,
    pedidoId,
    clienteId,
    prestadorId,
    status,
    amount,
    feeAmount,
    currency,
    source,
    createdAt,
  });
}

function toMillis(value) {
  if (!value) return null;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value === 'number') return value;
  if (value instanceof Date) return value.getTime();
  return null;
}

function toTimestampFromUnixSeconds(value) {
  const num = Number(value);
  if (!Number.isFinite(num) || num <= 0) return null;
  return Timestamp.fromMillis(Math.round(num * 1000));
}

function formatMonthKeyFromMillis(ms) {
  if (!Number.isFinite(ms)) return null;
  const d = new Date(ms);
  const y = d.getUTCFullYear();
  const m = `${d.getUTCMonth() + 1}`.padStart(2, '0');
  return `${y}-${m}`;
}

function getSubscriptionPlanInput(planIdRaw) {
  const planId = String(planIdRaw || 'pro').trim().toLowerCase();
  const basicPriceId = getEnv('STRIPE_SUB_PRICE_BASIC_ID', '').trim();
  const proPriceId = getEnv('STRIPE_SUB_PRICE_PRO_ID', '').trim();
  const basicAmount = Number(getEnv('STRIPE_SUB_BASIC_CENTS', '990')) || 990;
  const proAmount = Number(getEnv('STRIPE_SUB_PRO_CENTS', '1990')) || 1990;
  const currency = getEnv('STRIPE_SUB_CURRENCY', 'eur').trim().toLowerCase() || 'eur';

  if (planId === 'basic') {
    return {
      planId: 'basic',
      amountCents: basicAmount,
      currency,
      priceId: basicPriceId || null,
    };
  }
  return {
    planId: 'pro',
    amountCents: proAmount,
    currency,
    priceId: proPriceId || null,
  };
}

function inferPlanIdFromStripeSubscription(subscription) {
  const firstItem = subscription && subscription.items && subscription.items.data
    ? subscription.items.data[0]
    : null;
  const price = firstItem && firstItem.price ? firstItem.price : null;
  const priceId = price && price.id ? String(price.id) : '';
  const priceNickname = price && price.nickname ? String(price.nickname).toLowerCase() : '';
  const metaPlan = price && price.metadata && price.metadata.planId
    ? String(price.metadata.planId).toLowerCase()
    : '';
  const subMetaPlan = subscription && subscription.metadata && subscription.metadata.planId
    ? String(subscription.metadata.planId).toLowerCase()
    : '';

  const basicPriceId = getEnv('STRIPE_SUB_PRICE_BASIC_ID', '').trim();
  const proPriceId = getEnv('STRIPE_SUB_PRICE_PRO_ID', '').trim();

  if (metaPlan === 'basic' || subMetaPlan === 'basic') return 'basic';
  if (metaPlan === 'pro' || subMetaPlan === 'pro') return 'pro';
  if (priceId && basicPriceId && priceId === basicPriceId) return 'basic';
  if (priceId && proPriceId && priceId === proPriceId) return 'pro';
  if (priceNickname.includes('basic') || priceNickname.includes('starter')) return 'basic';
  if (priceNickname.includes('pro') || priceNickname.includes('premium')) return 'pro';
  return 'pro';
}

async function resolveUidByStripeCustomerId(customerId) {
  const cid = String(customerId || '').trim();
  if (!cid) return null;

  const usersByCustomer = await db.collection('users_private')
    .where('stripeCustomerId', '==', cid)
    .limit(1)
    .get();
  if (!usersByCustomer.empty) return usersByCustomer.docs[0].id;

  const subByCustomer = await db.collection('subscriptions')
    .where('stripeCustomerId', '==', cid)
    .limit(1)
    .get();
  if (!subByCustomer.empty) return subByCustomer.docs[0].id;

  return null;
}

async function upsertSubscriptionFromStripe(subscription, { source = 'webhook' } = {}) {
  if (!subscription || !subscription.id) return null;

  const stripeSubscriptionId = String(subscription.id);
  const stripeCustomerId = String(subscription.customer || '');
  const metadataUid = subscription.metadata && subscription.metadata.uid
    ? String(subscription.metadata.uid)
    : '';
  const uid = metadataUid || await resolveUidByStripeCustomerId(stripeCustomerId);

  if (!uid) {
    logger.warn(`[subscription] uid nao resolvido para subscription=${stripeSubscriptionId}`);
    return null;
  }

  const firstItem = subscription && subscription.items && subscription.items.data
    ? subscription.items.data[0]
    : null;
  const price = firstItem && firstItem.price ? firstItem.price : null;
  const planId = inferPlanIdFromStripeSubscription(subscription);
  const monthlyAmountCents = price && Number.isFinite(Number(price.unit_amount))
    ? Number(price.unit_amount)
    : null;
  const currency = price && price.currency ? String(price.currency).toLowerCase() : null;
  const status = String(subscription.status || 'incomplete');

  const currentPeriodStart = toTimestampFromUnixSeconds(subscription.current_period_start);
  const currentPeriodEnd = toTimestampFromUnixSeconds(subscription.current_period_end);
  const canceledAt = toTimestampFromUnixSeconds(subscription.canceled_at);
  const cancelAt = toTimestampFromUnixSeconds(subscription.cancel_at);

  const now = FieldValue.serverTimestamp();

  await db.collection('subscriptions').doc(uid).set(
    {
      uid,
      planId,
      status,
      stripeSubscriptionId,
      stripeCustomerId: stripeCustomerId || null,
      stripePriceId: price && price.id ? String(price.id) : null,
      monthlyAmountCents,
      currency,
      cancelAtPeriodEnd: subscription.cancel_at_period_end === true,
      currentPeriodStart: currentPeriodStart || null,
      currentPeriodEnd: currentPeriodEnd || null,
      cancelAt: cancelAt || null,
      canceledAt: canceledAt || null,
      source,
      updatedAt: now,
      createdAt: now,
    },
    { merge: true }
  );

  await db.collection('users_private').doc(uid).set(
    {
      stripeCustomerId: stripeCustomerId || null,
      subscriptionStatus: status,
      subscriptionPlanId: planId,
      subscriptionUpdatedAt: now,
      updatedAt: now,
    },
    { merge: true }
  );

  return {
    uid,
    planId,
    status,
    stripeSubscriptionId,
  };
}

// ------------------------------------------------------------
// 1) CHAT â†’ push + meta
// ------------------------------------------------------------

exports.onChatMessageCreated = onDocumentCreated(
  {
    region: REGION,
    document: 'chats/{pedidoId}/messages/{messageId}',
  },
  async (event) => {
    const { pedidoId, messageId } = event.params;
    const snap = event.data;
    if (!snap) return;

    const msg = snap.data() || {};
    const senderId = (msg.senderId || '').toString();
    const senderRole = (msg.senderRole || '').toString();
    const text = (msg.text || msg.message || msg.texto || msg.conteudo || '').toString();

    // Carrega pedido para determinar destinatário
    const pedidoSnap = await db.collection('pedidos').doc(pedidoId).get();
    if (!pedidoSnap.exists) return;

    const pedido = pedidoSnap.data() || {};
    const clienteId = getClienteId(pedido);
    const prestadorId = (pedido.prestadorId || '').toString();

    if (!clienteId) return;

    const recipientId = senderRole === 'cliente' ? prestadorId : clienteId;
    if (!recipientId) {
    // Ainda não há prestador atribuído - não há push.
      return;
    }

    // Atualiza meta (chats/{pedidoId}) de forma centralizada
    const chatRef = db.collection('chats').doc(pedidoId);
    const now = FieldValue.serverTimestamp();

    const metaUpdate = {
      pedidoId,
      clienteId,
      prestadorId: prestadorId || null,
      updatedAt: now,
      lastMessageAt: now,
      lastMessage: safeText(text, 200),
      lastSenderRole: senderRole,
      messageCount: FieldValue.increment(1),
      hasUnreadCliente: senderRole === 'prestador',
      hasUnreadPrestador: senderRole === 'cliente',
      unreadByCliente: senderRole === 'prestador' ? FieldValue.increment(1) : 0,
      unreadByPrestador: senderRole === 'cliente' ? FieldValue.increment(1) : 0,
    };

    await chatRef.set(metaUpdate, { merge: true });

    // in-app notification
    await saveInAppNotification(recipientId, {
      type: 'chat_message',
      pedidoId,
      messageId,
      title: senderRole === 'cliente' ? 'Nova mensagem do cliente' : 'Nova mensagem do prestador',
      body: safeText(text, 140),
      fromUserId: senderId,
    });

    // Push
    await sendPushToUser(recipientId, {
      title: 'ChegaJá - Nova mensagem',
      body: safeText(text, 120),
      data: {
        type: 'chat_message',
        pedidoId,
        openChat: 'true',
      },
    });

    logger.info(`[chat] push enviado pedido=${pedidoId} msg=${messageId} -> ${recipientId}`);
  }
);

// ------------------------------------------------------------
// 1.1) AVALIACOES -> agregados autoritativos do prestador
// ------------------------------------------------------------

exports.onAvaliacaoCreated = onDocumentCreated(
  {
    region: REGION,
    document: 'avaliacoes/{avaliacaoId}',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    await onAvaliacaoCreatedCore({
      database: db,
      avaliacaoId: event.params.avaliacaoId,
      avaliacao: snap.data() || {},
    });
  }
);

// ------------------------------------------------------------
// 2) PEDIDOS -> push por mudanças de estado
// ------------------------------------------------------------

exports.onPedidoUpdated = onDocumentUpdated(
  {
    region: REGION,
    document: 'pedidos/{pedidoId}',
  },
  async (event) => {
    const { pedidoId } = event.params;
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};

    await syncPedidoDispatch(db, pedidoId, after);
    const providerIdsToRefresh = new Set([
      cleanString(before.prestadorId),
      cleanString(after.prestadorId),
    ]);
    await Promise.all(
      [...providerIdsToRefresh]
        .filter(Boolean)
        .map((providerId) => syncProviderActiveClients(db, providerId)),
    );

    const beforeStatus = (before.status || '').toString();
    const afterStatus = (after.status || '').toString();

    // Só reage a mudança real de status
    if (beforeStatus === afterStatus) return;

    const clienteId = getClienteId(after);
    const prestadorId = (after.prestadorId || '').toString();

    if (!clienteId) return;

    // Define para quem enviar
    // - se prestadorId existir, notifica o outro lado
    // - se ainda não existe prestadorId, não há destinatário específico
    const updates = [];

    const title = 'ChegaJá - Pedido atualizado';

    function bodyForStatus(status) {
      switch (status) {
        case 'aguarda_resposta_cliente':
          return 'Recebeste uma proposta de preço.';
        case 'aceito':
          return 'Proposta aceita. O prestador pode iniciar o serviço.';
        case 'em_andamento':
          return 'O prestador iniciou o serviço.';
        case 'aguarda_confirmacao_valor':
          return 'O prestador propôs o valor final.';
        case 'concluido':
          return 'Serviço concluído.';
        case 'cancelado':
          const motivo = (after.motivoCancelamento || after.cancelReason || '').toString();
          if (motivo.includes('no_show')) {
            return 'Pedido cancelado por não comparência.';
          }
          return 'O pedido foi cancelado.';
        default:
          return `Estado: ${status}`;
      }
    }

    const body = bodyForStatus(afterStatus);

    // Se mudou por ação do prestador, notifica cliente
    // Se mudou por ação do cliente, notifica prestador
    // Não dá para determinar 100% sem "lastActorRole", então enviamos para ambos
    // quando ambos existem, com fallback.
    if (prestadorId) {
      updates.push(sendPushToUser(clienteId, {
        title,
        body,
        data: { type: 'pedido_status', pedidoId },
      }));
      updates.push(sendPushToUser(prestadorId, {
        title,
        body,
        data: { type: 'pedido_status', pedidoId },
      }));

      await saveInAppNotification(clienteId, {
        type: 'pedido_status',
        pedidoId,
        title,
        body,
        status: afterStatus,
      });
      await saveInAppNotification(prestadorId, {
        type: 'pedido_status',
        pedidoId,
        title,
        body,
        status: afterStatus,
      });
    } else {
      // sem prestador ainda - notifica só o cliente (mudanças internas)
      updates.push(sendPushToUser(clienteId, {
        title,
        body,
        data: { type: 'pedido_status', pedidoId },
      }));
      await saveInAppNotification(clienteId, {
        type: 'pedido_status',
        pedidoId,
        title,
        body,
        status: afterStatus,
      });
    }

    await Promise.all(updates);
  }
);

// ------------------------------------------------------------
// 3) PEDIDOS -> push para prestadores próximos (matching)
// ------------------------------------------------------------

exports.onPedidoCreated = onDocumentCreated(
  {
    region: REGION,
    document: 'pedidos/{pedidoId}',
  },
  async (event) => {
    const { pedidoId } = event.params;
    const pedido = event.data.data() || {};

    await syncPedidoDispatch(db, pedidoId, pedido);

    // Só pedidos abertos
    if (!isOpenPedido(pedido)) return;

    const servicoId = (pedido.servicoId || '').toString();
    const titulo = (pedido.titulo || '').toString();

    // Geo
    const geo = pedido.geo || null;
    const geopoint = geo && geo.geopoint ? geo.geopoint : null;

    if (!geopoint || typeof geopoint.latitude !== 'number' || typeof geopoint.longitude !== 'number') {
      logger.info(`[matching] pedido sem geo: ${pedidoId} (skip geo matching)`);
      return;
    }

    const center = [geopoint.latitude, geopoint.longitude];

    // Raio máximo de busca (em metros) - depois filtramos pelo radiusKm do prestador.
    const maxRadiusKm = 20;
    const radiusInM = maxRadiusKm * 1000;

    const bounds = geofire.geohashQueryBounds(center, radiusInM);

    const queries = bounds.map(([start, end]) => {
      let q = db.collection('provider_dispatch_private')
        .orderBy('geo.geohash')
        .startAt(start)
        .endAt(end)
        .where('isOnline', '==', true);

      if (servicoId) {
        q = q.where('servicos', 'array-contains', servicoId);
      }

      return q.get();
    });

    const snaps = await Promise.all(queries);

    const seen = new Set();
    const matches = [];

    for (const snap of snaps) {
      for (const doc of snap.docs) {
        if (seen.has(doc.id)) continue;
        seen.add(doc.id);

        const p = doc.data() || {};
        const pgeo = p.geo || null;
        const ppoint = pgeo && pgeo.geopoint ? pgeo.geopoint : null;
        if (!ppoint) continue;

        const distKm = geofire.distanceBetween([ppoint.latitude, ppoint.longitude], center);
        const radiusKm = Number(p.radiusKm || 0) || 0;
        const effectiveRadius = radiusKm > 0 ? radiusKm : 10;

        if (distKm <= effectiveRadius) {
          matches.push({ id: doc.id, distKm });
        }
      }
    }

    if (matches.length === 0) {
      logger.info(`[matching] nenhum prestador no raio para pedido ${pedidoId}`);
      return;
    }

    // Ordena por proximidade (opcional)
    matches.sort((a, b) => a.distKm - b.distKm);

    // Limit para evitar spam (ex.: top 30)
    const TOP_N = 30;
    const targets = matches.slice(0, TOP_N);
    const targetIds = targets.map((match) => match.id);

    await Promise.all(targets.map((match) => Promise.all([
      sendPushToUser(match.id, {
        title: 'ChegaJá - Novo pedido perto de ti',
        body: safeText(titulo || 'Novo pedido', 120),
        data: {
          type: 'novo_pedido',
          pedidoId,
        },
      }),
      db.collection('provider_opportunities').doc(`${pedidoId}_${match.id}`).set({
        pedidoId,
        providerId: match.id,
        serviceId: servicoId,
        approximateDistanceKm: Math.round(match.distKm * 10) / 10,
        channel: 'matching_push',
        deliveredAt: FieldValue.serverTimestamp(),
      }, { merge: false }),
    ])));

    logger.info(`[matching] push enviado para ${targetIds.length} prestadores pedido=${pedidoId}`);
  }
);

// ------------------------------------------------------------
// 4) Pedidos - valores finais autoritativos
// ------------------------------------------------------------

async function proporValorFinalPedidoCore({ db: firestore = db, uid, data }) {
  const actorUid = requireCallableUid(uid);
  const pedidoId = requirePedidoId(data);
  const valorFinal = requirePositiveMoney(
    data && (data.valorFinal ?? data.precoPropostoPrestador),
    'valorFinal'
  );
  const comentario = safeText(data && data.comentario, 500);

  const pedidoRef = firestore.collection('pedidos').doc(pedidoId);
  let previousStatus = '';

  await firestore.runTransaction(async (tx) => {
    const snap = await tx.get(pedidoRef);
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Pedido nao encontrado.');
    }

    const pedido = snap.data() || {};
    const prestadorId = cleanString(pedido.prestadorId);
    const estado = getPedidoEstado(pedido);
    previousStatus = estado;

    if (prestadorId !== actorUid) {
      throw new HttpsError('permission-denied', 'Apenas o prestador atribuido pode propor o valor final.');
    }

    if (estado !== 'em_andamento') {
      throw new HttpsError('failed-precondition', 'Pedido nao esta em andamento.');
    }

    tx.update(pedidoRef, {
      precoPropostoPrestador: valorFinal,
      statusConfirmacaoValor: 'pendente_cliente',
      estado: 'aguarda_confirmacao_valor',
      status: 'aguarda_confirmacao_valor',
      ...(comentario ? { mensagemPropostaPrestador: comentario } : {}),
      updatedAt: FieldValue.serverTimestamp(),
      historico: FieldValue.arrayUnion(historyItem({
        evento: 'valor_proposto',
        userId: actorUid,
        descricao: `Prestador propos valor final: ${valorFinal}`,
      })),
      lastAuthoritativeFunction: 'proporValorFinalPedido',
    });
  });

  logger.info('[pedidos] valor final proposto', {
    functionName: 'proporValorFinalPedido',
    pedidoId,
    prestadorId: maskIdentifier(actorUid),
    previousStatus,
    newStatus: 'aguarda_confirmacao_valor',
    valueCents: moneyToCents(valorFinal),
  });
  return { ok: true, pedidoId, valorFinal };
}

async function confirmarValorFinalPedidoCore({ db: firestore = db, uid, data }) {
  const actorUid = requireCallableUid(uid);
  const pedidoId = requirePedidoId(data);
  let economics;
  let previousStatus = '';
  let paymentMethod = 'dinheiro';

  await firestore.runTransaction(async (tx) => {
    const pedidoRef = firestore.collection('pedidos').doc(pedidoId);
    const snap = await tx.get(pedidoRef);
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Pedido nao encontrado.');
    }

    const pedido = snap.data() || {};
    const clienteId = cleanString(getClienteId(pedido));
    const providerId = cleanString(pedido.prestadorId);
    const estado = getPedidoEstado(pedido);
    const statusConfirmacaoValor = cleanString(pedido.statusConfirmacaoValor || 'nenhum');
    previousStatus = estado;
    const proposedValue = requirePositiveMoney(
      pedido.precoPropostoPrestador,
      'precoPropostoPrestador'
    );

    if (clienteId !== actorUid) {
      throw new HttpsError('permission-denied', 'Apenas o cliente do pedido pode confirmar o valor final.');
    }

    if (estado !== 'aguarda_confirmacao_valor' || statusConfirmacaoValor !== 'pendente_cliente') {
      throw new HttpsError('failed-precondition', 'Valor final nao esta pendente de confirmacao.');
    }

    if (!providerId) {
      throw new HttpsError('failed-precondition', 'Pedido sem prestador atribuido.');
    }

    paymentMethod = cleanString(pedido.tipoPagamento || 'dinheiro').toLowerCase();
    if (paymentMethod === 'cash') paymentMethod = 'dinheiro';
    const isCash = paymentMethod === 'dinheiro';
    if (!isCash) {
      if (!paymentMethodEnabled(paymentMethod)) {
        throw new HttpsError('failed-precondition', 'Meio de pagamento digital indisponivel no piloto.');
      }
      const paymentStatus = cleanString(pedido.paymentStatus).toLowerCase();
      if (!['paid', 'succeeded'].includes(paymentStatus)) {
        throw new HttpsError(
          'failed-precondition',
          'O pagamento digital deve estar confirmado antes de concluir o trabalho.',
        );
      }
      economics = calculatePedidoEconomics(proposedValue);
    } else {
      const providerRef = firestore.collection('provider_private').doc(providerId);
      const providerSnap = await tx.get(providerRef);
      const providerPrivate = providerSnap.exists ? (providerSnap.data() || {}) : {};
      const policy = cashCommissionPolicy({
        completedJobsCount: providerPrivate.completedJobsCount,
      });
      economics = calculatePedidoEconomics(proposedValue, policy);

      const previousBalance = Math.max(0, roundMoney(providerPrivate.commissionBalanceDue) || 0);
      const nextBalance = roundMoney(previousBalance + economics.commissionPlatform);
      const graceDays = Math.max(1, Math.floor(Number(getEnv('COMMISSION_GRACE_DAYS', '7')) || 7));
      const proposedDueAt = Timestamp.fromMillis(Date.now() + graceDays * 24 * 60 * 60 * 1000);
      const existingDueAt = providerPrivate.commissionDueAt;
      const dueAt = previousBalance > 0 && existingDueAt && typeof existingDueAt.toMillis === 'function'
        ? existingDueAt
        : (nextBalance > 0 ? proposedDueAt : null);
      const currentFinancialStatus = cleanString(providerPrivate.financialStatus);
      const nextFinancialStatus = currentFinancialStatus === 'suspended_new_jobs'
        ? currentFinancialStatus
        : (nextBalance > 0 ? 'payment_due' : 'active');
      const completedJobsCount = policy.completedJobsBefore + 1;
      const now = FieldValue.serverTimestamp();

      tx.set(providerRef, {
        providerId,
        completedJobsCount,
        commissionBalanceDue: nextBalance,
        financialBalance: roundMoney(-nextBalance),
        financialStatus: nextFinancialStatus,
        commissionDueAt: dueAt,
        commissionDebtUpdatedAt: now,
        updatedAt: now,
        ...(!providerSnap.exists ? { createdAt: now } : {}),
      }, { merge: true });

      const cashPaymentId = `cash_${pedidoId}`;
      tx.set(firestore.collection('payments').doc(cashPaymentId), {
        paymentId: cashPaymentId,
        pedidoId,
        clienteId,
        prestadorId: providerId,
        method: 'cash',
        currency: economics.currency,
        serviceAmount: economics.precoFinal,
        commissionAmount: economics.commissionPlatform,
        providerNetAmount: economics.earningsProvider,
        status: economics.commissionPlatform > 0 ? 'commission_due' : 'commission_waived',
        commissionDueAt: dueAt,
        freeCommissionJob: policy.freeCommissionJob,
        confirmedAt: now,
        updatedAt: now,
        createdAt: now,
      }, { merge: true });
      tx.set(providerRef.collection('financialTransactions').doc(cashPaymentId), {
        transactionId: cashPaymentId,
        pedidoId,
        type: economics.commissionPlatform > 0 ? 'commission_charge' : 'commission_waiver',
        currency: economics.currency,
        serviceAmount: economics.precoFinal,
        commissionAmount: economics.commissionPlatform,
        balanceAfter: nextBalance,
        dueAt,
        status: economics.commissionPlatform > 0 ? 'due' : 'waived',
        createdAt: now,
      }, { merge: false });
    }

    tx.update(pedidoRef, {
      ...economics,
      tipoPagamento: paymentMethod,
      paymentStatus: isCash ? 'cash_confirmed_by_client' : pedido.paymentStatus,
      statusConfirmacaoValor: 'confirmado_cliente',
      estado: 'concluido',
      status: 'concluido',
      concluidoEm: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      historico: FieldValue.arrayUnion(historyItem({
        evento: 'concluido',
        userId: actorUid,
        descricao: `Cliente confirmou valor final: ${economics.precoFinal}`,
      })),
      lastAuthoritativeFunction: 'confirmarValorFinalPedido',
    });
  });

  logger.info('[pedidos] valor final confirmado', {
    functionName: 'confirmarValorFinalPedido',
    pedidoId,
    clienteId: maskIdentifier(actorUid),
    previousStatus,
    newStatus: 'concluido',
    valueCents: moneyToCents(economics && economics.precoFinal),
    commissionCents: moneyToCents(economics && economics.commissionPlatform),
    providerEarningsCents: moneyToCents(economics && economics.earningsProvider),
    paymentMethod,
  });
  return { ok: true, pedidoId, ...economics };
}

async function recordCommissionPaymentCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);
  const providerId = cleanString(data.providerId);
  const amount = requirePositiveMoney(data.amount, 'amount');
  const reference = safeText(data.reference, 160);
  if (!providerId || reference.length < 3) {
    throw new HttpsError('invalid-argument', 'Prestador e referencia do pagamento sao obrigatorios.');
  }
  const receiptId = cleanString(data.receiptId)
    || `commission_${providerId}_${Date.now()}`;
  const actorId = cleanString(auth && auth.uid) || 'emulator_admin';

  let nextBalance = 0;
  await database.runTransaction(async (tx) => {
    const providerRef = database.collection('provider_private').doc(providerId);
    const providerSnap = await tx.get(providerRef);
    if (!providerSnap.exists) {
      throw new HttpsError('not-found', 'Prestador nao encontrado.');
    }
    const provider = providerSnap.data() || {};
    const currentBalance = Math.max(0, roundMoney(provider.commissionBalanceDue) || 0);
    if (currentBalance <= 0) {
      throw new HttpsError('failed-precondition', 'O prestador nao tem comissao pendente.');
    }
    if (amount > currentBalance) {
      throw new HttpsError('invalid-argument', 'O pagamento excede o saldo pendente.');
    }
    nextBalance = roundMoney(currentBalance - amount);
    const cleared = nextBalance <= 0;
    const now = FieldValue.serverTimestamp();
    tx.update(providerRef, {
      commissionBalanceDue: nextBalance,
      financialBalance: roundMoney(-nextBalance),
      financialStatus: cleared ? 'active' : 'payment_due',
      commissionDueAt: cleared ? null : provider.commissionDueAt,
      lastCommissionPaymentAt: now,
      updatedAt: now,
    });
    if (cleared) {
      tx.set(database.collection('provider_dispatch_private').doc(providerId), {
        providerId,
        acceptingNewJobs: true,
        financialRestrictionClearedAt: now,
        updatedAt: now,
      }, { merge: true });
    }
    tx.set(database.collection('commission_payments').doc(receiptId), {
      receiptId,
      providerId,
      amount,
      currency: cleanString(getEnv('DEFAULT_CURRENCY_CODE', 'MZN')).toUpperCase() || 'MZN',
      reference,
      recordedBy: actorId,
      balanceBefore: currentBalance,
      balanceAfter: nextBalance,
      createdAt: now,
    }, { merge: false });
    tx.set(providerRef.collection('financialTransactions').doc(receiptId), {
      transactionId: receiptId,
      type: 'commission_payment',
      amount,
      reference,
      balanceAfter: nextBalance,
      status: 'confirmed',
      createdAt: now,
    }, { merge: false });
  });
  return { ok: true, providerId, receiptId, balanceAfter: nextBalance };
}

async function enforceCommissionDebtCore({ database = db, now = Timestamp.now() } = {}) {
  const snapshot = await database.collection('provider_private')
    .where('financialStatus', '==', 'payment_due')
    .limit(500)
    .get();
  const maxDebt = Math.max(0, Number(getEnv('MAX_COMMISSION_DEBT_MZN', '100')) || 100);
  const nowMillis = now.toMillis();
  const batch = database.batch();
  let suspended = 0;
  for (const doc of snapshot.docs) {
    const provider = doc.data() || {};
    const balance = Math.max(0, roundMoney(provider.commissionBalanceDue) || 0);
    const dueAt = provider.commissionDueAt;
    const overdue = dueAt && typeof dueAt.toMillis === 'function' && dueAt.toMillis() <= nowMillis;
    if (balance <= 0 || (!overdue && balance < maxDebt)) continue;
    const updatedAt = FieldValue.serverTimestamp();
    batch.set(doc.ref, {
      financialStatus: 'suspended_new_jobs',
      financialRestrictionReason: overdue ? 'commission_overdue' : 'commission_limit_reached',
      financialRestrictedAt: updatedAt,
      updatedAt,
    }, { merge: true });
    batch.set(database.collection('provider_dispatch_private').doc(doc.id), {
      providerId: doc.id,
      acceptingNewJobs: false,
      financialRestrictionReason: overdue ? 'commission_overdue' : 'commission_limit_reached',
      updatedAt,
    }, { merge: true });
    suspended += 1;
  }
  if (suspended > 0) await batch.commit();
  return { checked: snapshot.size, suspended };
}

exports.proporValorFinalPedido = onCall(
  {
    region: REGION,
  },
  async (req) => {
    const uid = requireVerifiedPhoneAuth(req.auth);
    await requireCurrentLegalConsent({ uid });
    await requirePilotParticipant({ uid, role: 'prestador' });
    return proporValorFinalPedidoCore({ uid, data: req.data || {} });
  },
);

exports.confirmarValorFinalPedido = onCall(
  {
    region: REGION,
  },
  async (req) => {
    const uid = requireVerifiedPhoneAuth(req.auth);
    await requireCurrentLegalConsent({ uid });
    await requirePilotParticipant({ uid, role: 'cliente' });
    return confirmarValorFinalPedidoCore({ uid, data: req.data || {} });
  },
);

exports.admin_recordCommissionPayment = onCall(
  { region: REGION },
  async (req) => recordCommissionPaymentCore({
    auth: req.auth,
    data: req.data || {},
  }),
);

exports.pedidos_acceptDispatch = onCall(
  { region: REGION },
  async (req) => {
    const uid = requireVerifiedPhoneAuth(req.auth);
    await requireCurrentLegalConsent({ uid });
    await requirePilotParticipant({ uid, role: 'prestador' });
    return acceptPedidoDispatchCore({
      auth: req.auth,
      pedidoId: req.data && req.data.pedidoId,
    });
  },
);

exports.pedidos_createSecure = onCall(
  { region: REGION },
  async (req) => {
    const uid = requireVerifiedPhoneAuth(req.auth);
    await requireCurrentLegalConsent({ uid });
    await requirePilotParticipant({ uid, role: 'cliente' });
    enforcePilotOrderLocation(req.data || {});
    return createSecurePedidoCore({ auth: req.auth, data: req.data || {} });
  },
);

exports.pedidos_updateSecure = onCall(
  { region: REGION },
  async (req) => {
    const uid = requireVerifiedPhoneAuth(req.auth);
    await requireCurrentLegalConsent({ uid });
    await requirePilotParticipant({ uid, role: 'cliente' });
    enforcePilotOrderLocation(req.data || {});
    return updateSecurePedidoCore({ auth: req.auth, data: req.data || {} });
  },
);

exports.admin_reviewPedidoService = onCall(
  { region: REGION },
  async (req) => reviewPedidoServiceCore({ auth: req.auth, data: req.data || {} }),
);

exports.providers_updateServices = onCall(
  { region: REGION },
  async (req) => {
    const uid = requireVerifiedPhoneAuth(req.auth);
    await requireCurrentLegalConsent({ uid });
    await requirePilotParticipant({ uid, role: 'prestador' });
    const result = await updateProviderServicesCore({ auth: req.auth, data: req.data || {} });
    await db.collection('provider_public').doc(uid).set({
      isSearchable: result.serviceIds.length > 0,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return result;
  },
);

exports.categories_submitSensitiveRequest = onCall(
  { region: REGION },
  async (req) => {
    const uid = requireVerifiedPhoneAuth(req.auth);
    await requireCurrentLegalConsent({ uid });
    await requirePilotParticipant({ uid, role: 'prestador' });
    return submitSensitiveCategoryRequestCore({ auth: req.auth, data: req.data || {} });
  },
);

exports.admin_reviewProviderCustomService = onCall(
  { region: REGION },
  async (req) => reviewProviderCustomServiceCore({ auth: req.auth, data: req.data || {} }),
);

exports.auth_syncPhoneIdentity = onCall(
  { region: REGION },
  async (req) => syncPhoneIdentityCore({ auth: req.auth }),
);

exports.auth_mergeAnonymousData = onCall(
  { region: REGION },
  async (req) => mergeAnonymousDataCore({
    auth: req.auth,
    sourceIdToken: req.data && req.data.sourceIdToken,
  }),
);

exports.legal_acceptDocuments = onCall(
  { region: REGION },
  async (req) => acceptLegalDocumentsCore({ auth: req.auth, data: req.data || {} }),
);

exports.support_createTicket = onCall(
  { region: REGION },
  async (req) => createSupportTicketCore({ auth: req.auth, data: req.data || {} }),
);

exports.account_requestDeletion = onCall(
  { region: REGION },
  async (req) => requestAccountDeletionCore({ auth: req.auth, data: req.data || {} }),
);

exports.account_cancelDeletion = onCall(
  { region: REGION },
  async (req) => cancelAccountDeletionCore({ auth: req.auth }),
);

exports.kyc_beginSubmission = onCall(
  { region: REGION },
  async (req) => {
    const uid = requireVerifiedPhoneAuth(req.auth);
    await requireCurrentLegalConsent({ uid });
    await requirePilotParticipant({ uid, role: 'prestador' });
    return beginKycSubmissionCore({ auth: req.auth });
  },
);

exports.kyc_submit = onCall(
  { region: REGION },
  async (req) => {
    const uid = requireVerifiedPhoneAuth(req.auth);
    await requireCurrentLegalConsent({ uid });
    await requirePilotParticipant({ uid, role: 'prestador' });
    return submitKycCore({ auth: req.auth, data: req.data || {} });
  },
);

exports.kyc_deleteMySubmission = onCall(
  { region: REGION },
  async (req) => deleteMyKycSubmissionCore({ auth: req.auth }),
);

exports.admin_getKycReviewDocuments = onCall(
  { region: REGION },
  async (req) => getKycReviewDocumentsCore({
    auth: req.auth,
    providerId: req.data && req.data.providerId,
  }),
);

exports.admin_reviewKycSubmission = onCall(
  { region: REGION },
  async (req) => reviewKycSubmissionCore({ auth: req.auth, data: req.data || {} }),
);

exports.storage_finalizePrivateUpload = onCall(
  { region: REGION },
  async (req) => finalizePrivateStorageUploadCore({
    auth: req.auth,
    data: req.data || {},
  }),
);

exports.storage_getPrivateReadUrl = onCall(
  { region: REGION },
  async (req) => getPrivateStorageReadUrlCore({
    auth: req.auth,
    data: req.data || {},
  }),
);

// ------------------------------------------------------------
// 5) Stripe Connect + Pagamentos
// ------------------------------------------------------------

function getStripe() {
  if (!envFlagEnabled('ENABLE_STRIPE') || !envFlagEnabled('STRIPE_MZN_VALIDATED')) {
    throw new HttpsError(
      'failed-precondition',
      'Stripe esta desativado ate a integracao em MZN estar validada.',
    );
  }
  const secret = getEnv('STRIPE_SECRET_KEY');
  if (!secret) {
    throw new HttpsError('failed-precondition', 'STRIPE_SECRET_KEY nao configurada.');
  }
  // eslint-disable-next-line global-require
  const Stripe = require('stripe');
  return Stripe(secret);
}

exports.payments_createOnboardingLink = onCall(
  {
    region: REGION,
  },
  async (req) => {
    if (!req.auth) {
      throw new Error('UNAUTHENTICATED');
    }

    const uid = req.auth.uid;
    const stripe = getStripe();

    const baseUrl = getEnv('APP_BASE_URL', 'http://localhost:5000');

    const prestadorRef = db.collection('provider_private').doc(uid);
    const prestadorSnap = await prestadorRef.get();
    const prestador = prestadorSnap.exists ? (prestadorSnap.data() || {}) : {};

    let accountId = (prestador.stripeAccountId || '').toString();

    if (!accountId) {
      // cria conta Connect Express
      const account = await stripe.accounts.create({
        type: 'express',
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        metadata: {
          prestadorId: uid,
        },
      });

      accountId = account.id;

      await prestadorRef.set(
        {
          stripeAccountId: accountId,
          stripeOnboardingComplete: false,
          updatedAt: FieldValue.serverTimestamp(),
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    const refreshUrl = `${baseUrl.replace(/\/$/, '')}/stripe/refresh?prestadorId=${uid}`;
    const returnUrl = `${baseUrl.replace(/\/$/, '')}/stripe/return?prestadorId=${uid}`;

    const link = await stripe.accountLinks.create({
      account: accountId,
      refresh_url: refreshUrl,
      return_url: returnUrl,
      type: 'account_onboarding',
    });

    return { url: link.url, accountId };
  }
);

exports.payments_createPaymentIntent = onCall(
  {
    region: REGION,
  },
  async (req) => {
    if (!req.auth) {
      throw new Error('UNAUTHENTICATED');
    }

    const uid = req.auth.uid;
    const pedidoId = (req.data && req.data.pedidoId) ? String(req.data.pedidoId).trim() : '';

    if (!pedidoId) {
      throw new Error('pedidoId obrigatório');
    }

    const pedidoRef = db.collection('pedidos').doc(pedidoId);
    const pedidoSnap = await pedidoRef.get();
    if (!pedidoSnap.exists) {
      throw new Error('Pedido não encontrado');
    }

    const pedido = pedidoSnap.data() || {};
    const clienteId = getClienteId(pedido);
    const prestadorId = String(pedido.prestadorId || '');

    if (clienteId !== uid) {
      throw new Error('PERMISSION_DENIED');
    }

    if (!prestadorId) {
      throw new Error('Pedido ainda sem prestador atribuído');
    }
    if (cleanString(pedido.tipoPagamento).toLowerCase() !== 'stripe') {
      throw new HttpsError('failed-precondition', 'Este pedido nao usa Stripe.');
    }

    // Valor a cobrar
    const valor = pedido.precoPropostoPrestador ?? pedido.precoFinal ?? pedido.preco;
    const amount = moneyToCents(valor);
    if (amount <= 0) {
      throw new Error('Valor inválido para pagamento');
    }

    const currency = String(pedido.currency || getEnv('DEFAULT_CURRENCY_CODE', 'MZN')).toLowerCase();
    if (currency !== 'mzn') {
      throw new HttpsError('failed-precondition', 'Moeda do pedido invalida para o piloto.');
    }

    // conta do prestador
    const prestadorSnap = await db.collection('provider_private').doc(prestadorId).get();
    const prestador = prestadorSnap.exists ? (prestadorSnap.data() || {}) : {};

    const accountId = String(prestador.stripeAccountId || '');
    const onboardingComplete = prestador.stripeOnboardingComplete === true;

    if (!accountId) {
      throw new Error('Prestador sem Stripe Connect.');
    }

    // Podemos permitir pagamento mesmo sem onboarding completo, mas normalmente
    // o Stripe bloqueia transfers se payouts não estiverem enabled.
    if (!onboardingComplete) {
      logger.warn(`[stripe] prestador ${prestadorId} sem onboarding completo (account=${accountId})`);
    }

    const commissionRate = normalizedRate(getEnv('DEFAULT_DIGITAL_COMMISSION_RATE', '0.15'), 0.15);
    const feeAmount = Math.max(0, Math.round(amount * commissionRate));

    const stripe = getStripe();

    // Reutiliza PaymentIntent se já existir
    const existingId = String(pedido.paymentIntentId || '');
    if (existingId) {
      const existing = await stripe.paymentIntents.retrieve(existingId);
      if (existing && existing.status && existing.status !== 'canceled') {
        return {
          clientSecret: existing.client_secret,
          paymentIntentId: existing.id,
          amount,
          currency,
        };
      }
    }

    const pi = await stripe.paymentIntents.create({
      amount,
      currency,
      automatic_payment_methods: { enabled: true },
      application_fee_amount: feeAmount,
      transfer_data: { destination: accountId },
      metadata: {
        pedidoId,
        clienteId,
        prestadorId,
      },
    });

    // Guarda no Firestore
    await pedidoRef.set(
      {
        paymentIntentId: pi.id,
        paymentAmount: amount,
        paymentCurrency: currency,
        paymentFeeAmount: feeAmount,
        paymentStatus: pi.status,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await db.collection('payments').doc(pi.id).set(
      {
        pedidoId,
        clienteId,
        prestadorId,
        amount,
        currency,
        feeAmount,
        status: pi.status,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await writeLedgerEntry({
      paymentIntentId: pi.id,
      eventType: 'payment_intent_created',
      pedidoId,
      clienteId,
      prestadorId,
      status: pi.status,
      amount,
      feeAmount,
      currency,
      source: 'callable',
    });

    return {
      clientSecret: pi.client_secret,
      paymentIntentId: pi.id,
      amount,
      currency,
    };
  }
);

exports.payments_createSubscriptionCheckout = onCall(
  {
    region: REGION,
  },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'UNAUTHENTICATED');
    }

    const uid = req.auth.uid;
    const planInput = getSubscriptionPlanInput(req.data ? req.data.planId : 'pro');
    const stripe = getStripe();

    const userRef = db.collection('users_private').doc(uid);
    const userSnap = await userRef.get();
    const user = userSnap.exists ? (userSnap.data() || {}) : {};

    let stripeCustomerId = String(user.stripeCustomerId || '').trim();
    if (!stripeCustomerId) {
      const customer = await stripe.customers.create({
        metadata: { uid },
      });
      stripeCustomerId = customer.id;
      await userRef.set(
        {
          stripeCustomerId,
          updatedAt: FieldValue.serverTimestamp(),
          createdAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    const baseUrl = getEnv('APP_BASE_URL', 'http://localhost:5000').replace(/\/$/, '');
    const defaultSuccessUrl = `${baseUrl}/billing/success?session_id={CHECKOUT_SESSION_ID}`;
    const defaultCancelUrl = `${baseUrl}/billing/cancel`;

    const normalizeUrl = (raw, fallback) => {
      try {
        const candidate = String(raw || '').trim();
        if (!candidate) return fallback;
        const u = new URL(candidate);
        if (!['http:', 'https:'].includes(u.protocol)) return fallback;
        return u.toString();
      } catch (_) {
        return fallback;
      }
    };

    const successUrl = normalizeUrl(req.data ? req.data.successUrl : null, defaultSuccessUrl);
    const cancelUrl = normalizeUrl(req.data ? req.data.cancelUrl : null, defaultCancelUrl);

    const sessionPayload = {
      mode: 'subscription',
      customer: stripeCustomerId,
      success_url: successUrl,
      cancel_url: cancelUrl,
      allow_promotion_codes: true,
      client_reference_id: uid,
      metadata: {
        uid,
        planId: planInput.planId,
      },
      subscription_data: {
        metadata: {
          uid,
          planId: planInput.planId,
        },
      },
      line_items: planInput.priceId
        ? [{ price: planInput.priceId, quantity: 1 }]
        : [{
          quantity: 1,
          price_data: {
            currency: planInput.currency,
            unit_amount: planInput.amountCents,
            recurring: { interval: 'month' },
            product_data: {
        name: `ChegaJá ${planInput.planId.toUpperCase()} Plan`,
              metadata: {
                planId: planInput.planId,
              },
            },
          },
        }],
    };

    const session = await stripe.checkout.sessions.create(sessionPayload);
    if (!session || !session.id || !session.url) {
      throw new HttpsError('internal', 'Falha ao criar sessão de assinatura.');
    }

    await db.collection('subscriptions').doc(uid).set(
      {
        uid,
        planId: planInput.planId,
        status: 'checkout_pending',
        stripeCustomerId,
        checkoutSessionId: session.id,
        monthlyAmountCents: planInput.amountCents,
        currency: planInput.currency,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      url: session.url,
      sessionId: session.id,
      planId: planInput.planId,
      stripeCustomerId,
    };
  }
);

exports.payments_createBillingPortalLink = onCall(
  {
    region: REGION,
  },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'UNAUTHENTICATED');
    }

    const uid = req.auth.uid;
    const stripe = getStripe();
    const userSnap = await db.collection('users_private').doc(uid).get();
    const user = userSnap.exists ? (userSnap.data() || {}) : {};
    const stripeCustomerId = String(user.stripeCustomerId || '').trim();

    if (!stripeCustomerId) {
      throw new HttpsError('failed-precondition', 'Usuário sem cliente Stripe.');
    }

    const baseUrl = getEnv('APP_BASE_URL', 'http://localhost:5000').replace(/\/$/, '');
    const defaultReturnUrl = `${baseUrl}/billing`;
    let returnUrl = defaultReturnUrl;
    try {
      const maybe = String(req.data && req.data.returnUrl ? req.data.returnUrl : '').trim();
      if (maybe) {
        const parsed = new URL(maybe);
        if (['http:', 'https:'].includes(parsed.protocol)) {
          returnUrl = parsed.toString();
        }
      }
    } catch (_) {}

    const portal = await stripe.billingPortal.sessions.create({
      customer: stripeCustomerId,
      return_url: returnUrl,
    });

    return { url: portal.url };
  }
);

exports.payments_getMySubscription = onCall(
  {
    region: REGION,
  },
  async (req) => {
    if (!req.auth) {
      throw new HttpsError('unauthenticated', 'UNAUTHENTICATED');
    }
    const uid = req.auth.uid;
    const snap = await db.collection('subscriptions').doc(uid).get();
    if (!snap.exists) return { subscription: null };
    return { subscription: { id: snap.id, ...snap.data() } };
  }
);

// ------------------------------------------------------------
// Google Places proxy (Autocomplete)
// ------------------------------------------------------------

exports.places_autocomplete = onRequest(
  {
    region: REGION,
    secrets: [GOOGLE_PLACES_API_KEY],
  },
  (req, res) => {
    cors(req, res, async () => {
      if (req.method !== 'GET') {
        res.status(405).send('Method not allowed');
        return;
      }
      const security = await enforceHttpAppSecurity(req, res, {
        endpoint: 'places_autocomplete',
        limitPerMinute: Number(getEnv('RATE_LIMIT_PLACES_AUTOCOMPLETE', '30')) || 30,
      });
      if (!security) return;

      const apiKey = GOOGLE_PLACES_API_KEY.value() || getEnv('GOOGLE_PLACES_API_KEY');
      if (!apiKey) {
        res.status(500).json({
          status: 'REQUEST_DENIED',
          error_message: 'GOOGLE_PLACES_API_KEY missing',
        });
        return;
      }

      const input = String(req.query.input || '').trim();
      if (input.length < 2) {
        res.json({ status: 'ZERO_RESULTS', predictions: [] });
        return;
      }
      if (input.length > 200) {
        res.status(400).json({ status: 'INVALID_REQUEST' });
        return;
      }

      const rawTypes = String(req.query.types || '');
      const allowedTypes = new Set(['(cities)', '(regions)', 'address']);
      const types = allowedTypes.has(rawTypes) ? rawTypes : '(cities)';

      const languageRaw = String(req.query.language || 'en').trim();
      const language = /^[a-z-]{2,10}$/i.test(languageRaw) ? languageRaw : 'en';

      const params = new URLSearchParams({
        input,
        key: apiKey,
        types,
        language,
      });

      const components = String(req.query.components || '').trim();
      if (/^country:[a-z]{2}$/i.test(components)) {
        params.set('components', components);
      }

      const sessiontoken = String(req.query.sessiontoken || '').trim();
      if (sessiontoken && sessiontoken.length <= 120) params.set('sessiontoken', sessiontoken);

      const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?${params.toString()}`;
      try {
        const response = await fetch(url);
        const data = await response.json();
        res.status(response.status).json(data);
      } catch (e) {
        logger.error('[placesAutocomplete] error', e);
        res.status(500).json({
          status: 'UNKNOWN_ERROR',
          error_message: String(e),
        });
      }
    });
  }
);

exports.places_details = onRequest(
  {
    region: REGION,
    secrets: [GOOGLE_PLACES_API_KEY],
  },
  (req, res) => {
    cors(req, res, async () => {
      if (req.method !== 'GET') {
        res.status(405).send('Method not allowed');
        return;
      }
      const security = await enforceHttpAppSecurity(req, res, {
        endpoint: 'places_details',
        limitPerMinute: Number(getEnv('RATE_LIMIT_PLACES_DETAILS', '20')) || 20,
      });
      if (!security) return;

      const apiKey = GOOGLE_PLACES_API_KEY.value() || getEnv('GOOGLE_PLACES_API_KEY');
      if (!apiKey) {
        res.status(500).json({
          status: 'REQUEST_DENIED',
          error_message: 'GOOGLE_PLACES_API_KEY missing',
        });
        return;
      }

      const placeId = String(req.query.place_id || '').trim();
      if (!placeId || placeId.length > 300) {
        res.status(400).json({
          status: 'INVALID_REQUEST',
          error_message: 'place_id required',
        });
        return;
      }

      const fieldsRaw = String(req.query.fields || 'geometry,formatted_address,name');
      const fields = fieldsRaw
        .split(',')
        .map((f) => f.trim())
        .filter((f) => ['geometry', 'formatted_address', 'name'].includes(f));
      if (!fields.length) fields.push('geometry', 'formatted_address', 'name');

      const languageRaw = String(req.query.language || 'en').trim();
      const language = /^[a-z-]{2,10}$/i.test(languageRaw) ? languageRaw : 'en';

      const params = new URLSearchParams({
        place_id: placeId,
        key: apiKey,
        fields: fields.join(','),
        language,
      });

      const sessiontoken = String(req.query.sessiontoken || '').trim();
      if (sessiontoken && sessiontoken.length <= 120) params.set('sessiontoken', sessiontoken);

      const url = `https://maps.googleapis.com/maps/api/place/details/json?${params.toString()}`;
      try {
        const response = await fetch(url);
        const data = await response.json();
        res.status(response.status).json(data);
      } catch (e) {
        logger.error('[placesDetails] error', e);
        res.status(500).json({
          status: 'UNKNOWN_ERROR',
          error_message: String(e),
        });
      }
    });
  }
);

// ------------------------------------------------------------
// Google Directions proxy
// ------------------------------------------------------------

exports.directions_route = onRequest(
  {
    region: REGION,
    secrets: [GOOGLE_MAPS_API_KEY, GOOGLE_PLACES_API_KEY],
  },
  (req, res) => {
    cors(req, res, async () => {
      if (req.method !== 'GET') {
        res.status(405).send('Method not allowed');
        return;
      }
      const security = await enforceHttpAppSecurity(req, res, {
        endpoint: 'directions_route',
        limitPerMinute: Number(getEnv('RATE_LIMIT_DIRECTIONS', '20')) || 20,
      });
      if (!security) return;

      const apiKey = GOOGLE_MAPS_API_KEY.value()
        || getEnv('GOOGLE_MAPS_API_KEY')
        || GOOGLE_PLACES_API_KEY.value()
        || getEnv('GOOGLE_PLACES_API_KEY');
      if (!apiKey) {
        res.status(500).json({
          status: 'REQUEST_DENIED',
          error_message: 'GOOGLE_MAPS_API_KEY missing',
        });
        return;
      }

      const origin = String(req.query.origin || '').trim();
      const destination = String(req.query.destination || '').trim();
      if (!origin || !destination || origin.length > 100 || destination.length > 100) {
        res.status(400).json({
          status: 'INVALID_REQUEST',
          error_message: 'origin and destination required',
        });
        return;
      }

      const modeRaw = String(req.query.mode || 'driving').trim().toLowerCase();
      const allowedModes = new Set(['driving', 'walking', 'bicycling', 'transit']);
      const mode = allowedModes.has(modeRaw) ? modeRaw : 'driving';

      const languageRaw = String(req.query.language || 'en').trim();
      const language = /^[a-z-]{2,10}$/i.test(languageRaw) ? languageRaw : 'en';

      const params = new URLSearchParams({
        origin,
        destination,
        mode,
        language,
        key: apiKey,
      });

      const url = `https://maps.googleapis.com/maps/api/directions/json?${params.toString()}`;
      try {
        const response = await fetch(url);
        const data = await response.json();
        res.status(response.status).json(data);
      } catch (e) {
        logger.error('[directionsRoute] error', e);
        res.status(500).json({
          status: 'UNKNOWN_ERROR',
          error_message: String(e),
        });
      }
    });
  }
);

// Webhook Stripe (opcional). Precisa configurar endpoint no painel Stripe.
exports.payments_stripeWebhook = onRequest(
  {
    region: REGION,
  },
  (req, res) => {
    cors(req, res, async () => {
      let event;
      try {
        const stripe = getStripe();
        const sig = req.headers['stripe-signature'];
        const secret = getEnv('STRIPE_WEBHOOK_SECRET');
        if (!secret) {
          res.status(500).send('STRIPE_WEBHOOK_SECRET não configurada');
          return;
        }

        event = stripe.webhooks.constructEvent(req.rawBody, sig, secret);
      } catch (err) {
        logger.error('[stripeWebhook] assinatura inválida', err);
        res.status(400).send(`Webhook Error: ${err.message}`);
        return;
      }

      try {
        const stripe = getStripe();
        const type = event.type;

        if (type === 'payment_intent.succeeded' || type === 'payment_intent.payment_failed') {
          const pi = event.data.object;
          const pedidoId = pi.metadata ? pi.metadata.pedidoId : null;
          const clienteId = pi.metadata ? pi.metadata.clienteId : null;
          const prestadorId = pi.metadata ? pi.metadata.prestadorId : null;

          const status = pi.status;

          if (pedidoId) {
            await db.collection('pedidos').doc(pedidoId).set(
              {
                paymentIntentId: pi.id,
                paymentStatus: status,
                updatedAt: FieldValue.serverTimestamp(),
              },
              { merge: true }
            );
          }

          await db.collection('payments').doc(pi.id).set(
            {
              pedidoId: pedidoId || null,
              clienteId: clienteId || null,
              prestadorId: prestadorId || null,
              status,
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );

          await writeLedgerEntry({
            paymentIntentId: pi.id,
            eventType: type,
            pedidoId: pedidoId || null,
            clienteId: clienteId || null,
            prestadorId: prestadorId || null,
            status,
            amount: pi.amount_received || pi.amount || null,
            feeAmount: null,
            currency: pi.currency || null,
            source: 'webhook',
          });
        }

        if (type === 'checkout.session.completed') {
          const session = event.data.object;
          if (session && session.mode === 'subscription' && session.subscription) {
            const stripeSubscriptionId = String(session.subscription);
            const sub = await stripe.subscriptions.retrieve(stripeSubscriptionId);
            await upsertSubscriptionFromStripe(sub, { source: 'checkout.session.completed' });
          }
        }

        if (
          type === 'customer.subscription.created'
          || type === 'customer.subscription.updated'
          || type === 'customer.subscription.deleted'
        ) {
          const sub = event.data.object;
          await upsertSubscriptionFromStripe(sub, { source: type });
        }

        // Completar onboarding do prestador (account.updated)
        if (type === 'account.updated') {
          const acc = event.data.object;
          const accountId = acc.id;
          const complete = !!(acc.charges_enabled && acc.payouts_enabled);

          const qs = await db.collection('provider_private').where('stripeAccountId', '==', accountId).limit(5).get();
          const batch = db.batch();
          qs.docs.forEach((d) => {
            batch.set(d.ref, { stripeOnboardingComplete: complete, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
          });
          await batch.commit();
        }

        res.json({ received: true });
      } catch (e) {
        logger.error('[stripeWebhook] erro a processar', e);
        res.status(500).send('Erro a processar webhook');
      }
    });
  }
);

// ------------------------------------------------------------
// 5) Admin Backoffice (K1/K2/K3 + E3/E4)
// ------------------------------------------------------------

const ADMIN_REPORT_STATUS_FILTERS = new Set([
  'all',
  'pending_review',
  'reviewed',
  'resolved',
  'hidden',
  'rejected',
  'dismissed',
  'escalated',
]);

const ADMIN_REPORT_UPDATE_STATUSES = new Set([
  'pending_review',
  'reviewed',
  'resolved',
  'hidden',
  'rejected',
  'dismissed',
  'escalated',
]);

const ADMIN_AUDIT_ACTIONS = new Set([
  'report.update_status',
  'support_ticket.update_status',
  'no_show.set_decision',
  'story.delete',
  'sensitive_category_request.approve',
  'sensitive_category_request.reject',
  'sensitive_category_request.needs_more_info',
  'kyc.view_documents',
  'kyc.approved',
  'kyc.rejected',
  'kyc.needs_more_info',
  'service_request.approved',
  'service_request.rejected',
  'custom_service.approved',
  'custom_service.rejected',
  'pilot_participant.active',
  'pilot_participant.inactive',
]);

const ADMIN_AUDIT_TARGET_TYPES = new Set([
  'report',
  'support_ticket',
  'pedido',
  'no_show',
  'story',
  'sensitive_category_request',
  'kyc_submission',
  'provider_custom_service',
  'pilot_participant',
]);

const ADMIN_SENSITIVE_CATEGORY_REQUEST_STATUS_FILTERS = new Set([
  'all',
  'pending',
  'draft',
  'submitted',
  'pending_review',
  'approved',
  'rejected',
  'needs_more_info',
  'expired',
  'revoked',
]);

const ADMIN_SENSITIVE_CATEGORY_DECISIONS = new Set([
  'approved',
  'rejected',
  'needs_more_info',
]);

function normalizeAdminReportStatus(value, { allowAll = false } = {}) {
  const status = String(value || (allowAll ? 'all' : 'pending_review')).trim().toLowerCase();
  const allowed = allowAll ? ADMIN_REPORT_STATUS_FILTERS : ADMIN_REPORT_UPDATE_STATUSES;
  if (!allowed.has(status)) {
    throw new HttpsError('invalid-argument', 'status inválido');
  }
  return status;
}

function normalizeAdminAuditAction(value, { allowEmpty = false } = {}) {
  const action = String(value || '').trim();
  if (allowEmpty && !action) return '';
  if (!ADMIN_AUDIT_ACTIONS.has(action)) {
    throw new HttpsError('invalid-argument', 'action inválida');
  }
  return action;
}

function normalizeAdminAuditTargetType(value, { allowEmpty = false } = {}) {
  const targetType = String(value || '').trim();
  if (allowEmpty && !targetType) return '';
  if (!ADMIN_AUDIT_TARGET_TYPES.has(targetType)) {
    throw new HttpsError('invalid-argument', 'targetType inválido');
  }
  return targetType;
}

function normalizeSensitiveCategoryRequestStatus(value, { allowAll = false } = {}) {
  const fallback = allowAll ? 'pending' : 'pending_review';
  const status = String(value || fallback).trim().toLowerCase();
  const allowed = allowAll
    ? ADMIN_SENSITIVE_CATEGORY_REQUEST_STATUS_FILTERS
    : new Set([...ADMIN_SENSITIVE_CATEGORY_REQUEST_STATUS_FILTERS].filter((item) => !['all', 'pending'].includes(item)));
  if (!allowed.has(status)) {
    throw new HttpsError('invalid-argument', 'status inválido');
  }
  return status;
}

function normalizeSensitiveCategoryDecision(value) {
  const decision = String(value || '').trim().toLowerCase();
  if (!ADMIN_SENSITIVE_CATEGORY_DECISIONS.has(decision)) {
    throw new HttpsError('invalid-argument', 'decision inválida');
  }
  return decision;
}

function auditText(value, max = 160) {
  const text = String(value || '').trim();
  if (text.length <= max) return text;
  return text.slice(0, max);
}

function stringList(value, maxItems = 20, maxTextLength = 1000) {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => auditText(item, maxTextLength))
    .filter((item) => item.length > 0)
    .slice(0, maxItems);
}

function optionalTimestamp(value, fieldName = 'timestamp') {
  if (value === undefined || value === null || value === '') return null;
  if (value && typeof value.toMillis === 'function') {
    return Timestamp.fromMillis(value.toMillis());
  }
  if (value instanceof Date) {
    return Timestamp.fromDate(value);
  }
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Timestamp.fromMillis(Math.round(value));
  }
  if (typeof value === 'string') {
    const millis = Date.parse(value);
    if (Number.isFinite(millis)) return Timestamp.fromMillis(millis);
  }
  throw new HttpsError('invalid-argument', `${fieldName} inválido`);
}

function sanitizeAuditMetadata(metadata) {
  if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
    return null;
  }
  const out = {};
  Object.entries(metadata).slice(0, 10).forEach(([key, value]) => {
    if (value === undefined || value === null) return;
    if (!['string', 'number', 'boolean'].includes(typeof value)) return;
    out[String(key).slice(0, 60)] = auditText(value, 140);
  });
  return Object.keys(out).length > 0 ? out : null;
}

function adminAuditLogPayload({
  auth,
  action,
  targetType,
  targetId,
  beforeStatus = '',
  afterStatus = '',
  reason = '',
  metadata = null,
}) {
  const actorUid = cleanString(auth && auth.uid);
  if (!actorUid) {
    throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  }
  const payload = {
    actorUid,
    actorRole: auth && auth.token && auth.token.admin === true ? 'admin' : 'dev',
    action: normalizeAdminAuditAction(action),
    targetType: normalizeAdminAuditTargetType(targetType),
    targetId: auditText(targetId, 180),
    beforeStatus: auditText(beforeStatus, 80),
    afterStatus: auditText(afterStatus, 80),
    reason: auditText(reason, 500),
    source: 'admin_callable',
    createdAt: FieldValue.serverTimestamp(),
  };
  const safeMetadata = sanitizeAuditMetadata(metadata);
  if (safeMetadata) payload.metadata = safeMetadata;
  return payload;
}

function writeAdminAuditLog({
  database = db,
  batch = null,
  auth,
  action,
  targetType,
  targetId,
  beforeStatus = '',
  afterStatus = '',
  reason = '',
  metadata = null,
}) {
  const ref = database.collection('adminAuditLogs').doc();
  const payload = adminAuditLogPayload({
    auth,
    action,
    targetType,
    targetId,
    beforeStatus,
    afterStatus,
    reason,
    metadata,
  });
  if (batch) {
    batch.set(ref, payload);
    return Promise.resolve(ref.id);
  }
  return ref.set(payload).then(() => ref.id);
}

function serializeAdminReport(doc) {
  const data = doc.data() || {};
  return {
    id: doc.id,
    reporterId: String(data.reporterId || ''),
    targetType: String(data.targetType || ''),
    targetId: String(data.targetId || ''),
    targetOwnerId: String(data.targetOwnerId || ''),
    reasonCode: String(data.reasonCode || ''),
    severity: String(data.severity || ''),
    status: String(data.status || 'pending_review'),
    details: String(data.details || ''),
    sourceContext: String(data.sourceContext || ''),
    pedidoId: String(data.pedidoId || ''),
    chatId: String(data.chatId || ''),
    messageId: String(data.messageId || ''),
    mediaUrl: String(data.mediaUrl || ''),
    mediaPath: String(data.mediaPath || ''),
    reviewedBy: String(data.reviewedBy || ''),
    decisionReason: String(data.decisionReason || ''),
    createdAt: toMillis(data.createdAt),
    updatedAt: toMillis(data.updatedAt),
    reviewedAt: toMillis(data.reviewedAt),
  };
}

function serializeAdminAuditLog(doc) {
  const data = doc.data() || {};
  return {
    id: doc.id,
    actorUid: String(data.actorUid || ''),
    actorRole: String(data.actorRole || ''),
    action: String(data.action || ''),
    targetType: String(data.targetType || ''),
    targetId: String(data.targetId || ''),
    beforeStatus: String(data.beforeStatus || ''),
    afterStatus: String(data.afterStatus || ''),
    reason: String(data.reason || ''),
    source: String(data.source || ''),
    createdAt: toMillis(data.createdAt),
  };
}

function serializeSensitiveCategoryRequest(doc) {
  const data = doc.data() || {};
  return {
    id: doc.id,
    providerId: String(data.providerId || ''),
    categoryId: String(data.categoryId || ''),
    categoryName: String(data.categoryName || ''),
    status: String(data.status || 'pending_review'),
    evidenceTypes: stringList(data.evidenceTypes, 10, 120),
    evidenceText: auditText(data.evidenceText, 2000),
    portfolioUrls: stringList(data.portfolioUrls, 20, 1000),
    documentRefs: stringList(data.documentRefs, 20, 500),
    createdAt: toMillis(data.createdAt),
    updatedAt: toMillis(data.updatedAt),
    submittedAt: toMillis(data.submittedAt),
    reviewedBy: String(data.reviewedBy || ''),
    reviewedAt: toMillis(data.reviewedAt),
    decisionReason: String(data.decisionReason || ''),
    expiresAt: toMillis(data.expiresAt),
  };
}

async function handleCheckAvailabilityCore({ database = db, data = {} }) {
  const validation = validatePublicHandle(data.handle);
  if (!validation.ok) {
    return {
      normalizedHandle: validation.normalizedHandle,
      available: false,
      reason: validation.reason,
      message: validation.message,
    };
  }

  const snap = await database.collection('handles')
    .doc(validation.normalizedHandle)
    .get();

  if (snap.exists) {
    return {
      normalizedHandle: validation.normalizedHandle,
      available: false,
      reason: 'taken',
      message: handleValidationMessage('taken'),
    };
  }

  return {
    normalizedHandle: validation.normalizedHandle,
    available: true,
    reason: 'available',
    message: '',
  };
}

async function handleReserveProviderHandleCore({ database = db, auth, data = {} }) {
  const uid = requireCallableUid(auth && auth.uid);
  const validation = validatePublicHandle(data.handle);

  if (!validation.ok) {
    throw new HttpsError('invalid-argument', validation.message || 'Handle invalido.', {
      reason: validation.reason,
      normalizedHandle: validation.normalizedHandle,
    });
  }

  const handle = validation.normalizedHandle;
  const handleDisplay = `@${handle}`;
  const prestadorRef = database.collection('provider_public').doc(uid);
  const handleRef = database.collection('handles').doc(handle);

  await database.runTransaction(async (tx) => {
    const prestadorSnap = await tx.get(prestadorRef);
    if (!prestadorSnap.exists) {
      throw new HttpsError('failed-precondition', 'Perfil de prestador obrigatorio.');
    }

    const prestadorData = prestadorSnap.data() || {};
    const oldHandle = normalizePublicHandle(prestadorData.handle || '');
    const handleSnap = await tx.get(handleRef);

    if (handleSnap.exists) {
      const handleData = handleSnap.data() || {};
      const ownerUid = String(handleData.uid || '');
      const status = String(handleData.status || 'active');
      if (ownerUid !== uid || status === 'blocked') {
        throw new HttpsError('already-exists', 'Este @handle ja esta em uso.');
      }
    }

    if (oldHandle && oldHandle !== handle) {
      const oldHandleRef = database.collection('handles').doc(oldHandle);
      tx.set(
        oldHandleRef,
        {
          handle: oldHandle,
          uid,
          role: 'prestador',
          status: 'released',
          previousOwnerUid: uid,
          releasedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          source: 'prestador_profile',
        },
        { merge: true },
      );
    }

    tx.set(
      handleRef,
      {
        handle,
        uid,
        role: 'prestador',
        status: 'active',
        handleDisplay,
        source: 'prestador_profile',
        updatedAt: FieldValue.serverTimestamp(),
        ...(handleSnap.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );

    tx.set(
      prestadorRef,
      {
        handle,
        handleDisplay,
        handleUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  return {
    handle,
    handleDisplay,
    uid,
    status: 'active',
  };
}

async function adminListReportsCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);

  const statusFilter = normalizeAdminReportStatus(data.status || 'pending_review', { allowAll: true });
  const limitRaw = Number(data.limit || 50);
  const limit = Math.min(200, Math.max(1, Number.isFinite(limitRaw) ? Math.round(limitRaw) : 50));

  const rawLimit = Math.max(limit * 4, 200);
  const snap = await database.collection('reports')
    .orderBy('createdAt', 'desc')
    .limit(rawLimit)
    .get();

  const counts = {};
  const reports = [];

  for (const doc of snap.docs) {
    const item = serializeAdminReport(doc);
    const status = item.status || 'pending_review';
    counts[status] = (counts[status] || 0) + 1;
    if (statusFilter !== 'all' && status !== statusFilter) continue;
    reports.push(item);
    if (reports.length >= limit) break;
  }

  return {
    generatedAt: Date.now(),
    total: reports.length,
    status: statusFilter,
    counts,
    reports,
  };
}

async function adminListAuditLogsCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);

  const limitRaw = Number(data.limit || 50);
  const limit = Math.min(100, Math.max(1, Number.isFinite(limitRaw) ? Math.round(limitRaw) : 50));
  const targetTypeFilter = normalizeAdminAuditTargetType(data.targetType, { allowEmpty: true });
  const actionFilter = normalizeAdminAuditAction(data.action, { allowEmpty: true });

  const rawLimit = Math.max(limit * 4, 100);
  const snap = await database.collection('adminAuditLogs')
    .orderBy('createdAt', 'desc')
    .limit(rawLimit)
    .get();

  const logs = [];
  for (const doc of snap.docs) {
    const item = serializeAdminAuditLog(doc);
    if (targetTypeFilter && item.targetType !== targetTypeFilter) continue;
    if (actionFilter && item.action !== actionFilter) continue;
    logs.push(item);
    if (logs.length >= limit) break;
  }

  return {
    generatedAt: Date.now(),
    total: logs.length,
    logs,
  };
}

async function adminListSensitiveCategoryRequestsCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);

  const statusFilter = normalizeSensitiveCategoryRequestStatus(data.status || 'pending', { allowAll: true });
  const limitRaw = Number(data.limit || 50);
  const limit = Math.min(100, Math.max(1, Number.isFinite(limitRaw) ? Math.round(limitRaw) : 50));
  const providerIdFilter = String(data.providerId || '').trim();
  const categoryIdFilter = String(data.categoryId || '').trim();

  const rawLimit = Math.max(limit * 4, 200);
  const snap = await database.collection('sensitiveCategoryRequests')
    .orderBy('updatedAt', 'desc')
    .limit(rawLimit)
    .get();

  const counts = {};
  const requests = [];

  for (const doc of snap.docs) {
    const item = serializeSensitiveCategoryRequest(doc);
    const status = item.status || 'pending_review';
    counts[status] = (counts[status] || 0) + 1;

    const matchesPending = status === 'submitted' || status === 'pending_review';
    if (statusFilter === 'pending' && !matchesPending) continue;
    if (statusFilter !== 'all' && statusFilter !== 'pending' && status !== statusFilter) continue;
    if (providerIdFilter && item.providerId !== providerIdFilter) continue;
    if (categoryIdFilter && item.categoryId !== categoryIdFilter) continue;

    requests.push(item);
    if (requests.length >= limit) break;
  }

  return {
    generatedAt: Date.now(),
    total: requests.length,
    status: statusFilter,
    counts,
    requests,
  };
}

async function adminReviewSensitiveCategoryRequestCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);

  const requestId = String(data.requestId || '').trim();
  const decision = normalizeSensitiveCategoryDecision(data.decision);
  const decisionReasonRaw = String(data.decisionReason || '').trim();
  const decisionReason = auditText(decisionReasonRaw, 500);
  const expiresAt = optionalTimestamp(data.expiresAt, 'expiresAt');

  if (!requestId) {
    throw new HttpsError('invalid-argument', 'requestId obrigatorio');
  }
  if ((decision === 'rejected' || decision === 'needs_more_info') && !decisionReason) {
    throw new HttpsError('invalid-argument', 'Motivo obrigatorio para esta decisao.');
  }

  const requestRef = database.collection('sensitiveCategoryRequests').doc(requestId);
  const requestSnap = await requestRef.get();
  if (!requestSnap.exists) {
    throw new HttpsError('not-found', 'Pedido de comprovativo nao encontrado.');
  }

  const request = requestSnap.data() || {};
  const beforeStatus = String(request.status || 'pending_review').toLowerCase();
  if (['expired', 'revoked'].includes(beforeStatus)) {
    throw new HttpsError('failed-precondition', 'Pedido nao pode ser decidido neste estado.');
  }

  const providerId = String(request.providerId || '').trim();
  const categoryId = String(request.categoryId || '').trim();
  const categoryName = String(request.categoryName || '').trim();
  if (!providerId || !categoryId) {
    throw new HttpsError('failed-precondition', 'Pedido sem providerId ou categoryId.');
  }

  const batch = database.batch();
  const reviewFields = {
    status: decision,
    reviewedBy: auth && auth.uid ? String(auth.uid) : '',
    reviewedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    decisionReason,
  };
  batch.set(requestRef, reviewFields, { merge: true });

  if (decision === 'approved') {
    const providerRef = database.collection('provider_public').doc(providerId);
    const approvalRef = database
      .collection('provider_private')
      .doc(providerId)
      .collection('categoryApprovals')
      .doc(categoryId);
    const approvalSnap = await approvalRef.get();
    batch.set(
      approvalRef,
      {
        providerId,
        categoryId,
        categoryName,
        status: 'approved',
        sourceRequestId: requestId,
        approvedBy: auth && auth.uid ? String(auth.uid) : '',
        approvedAt: FieldValue.serverTimestamp(),
        ...(expiresAt ? { expiresAt } : {}),
        decisionReason,
        updatedAt: FieldValue.serverTimestamp(),
        ...(approvalSnap.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );

    batch.set(
      providerRef,
      {
        approvedSensitiveCategoryIds: FieldValue.arrayUnion(categoryId),
        ...(categoryName
          ? { approvedSensitiveCategoryNames: FieldValue.arrayUnion(categoryName) }
          : {}),
        categoryApprovalsUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }

  writeAdminAuditLog({
    database,
    batch,
    auth,
    action: `sensitive_category_request.${decision === 'approved' ? 'approve' : decision === 'rejected' ? 'reject' : 'needs_more_info'}`,
    targetType: 'sensitive_category_request',
    targetId: requestId,
    beforeStatus,
    afterStatus: decision,
    reason: decisionReason,
    metadata: {
      providerId,
      categoryId,
      categoryName,
    },
  });

  await batch.commit();

  return {
    ok: true,
    requestId,
    status: decision,
  };
}

async function adminUpdateReportStatusCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);

  const reportId = String(data.reportId || '').trim();
  const status = normalizeAdminReportStatus(data.status || 'reviewed');
  const decisionReasonRaw = String(data.decisionReason || '').trim();
  const decisionReason = decisionReasonRaw.length > 500
    ? decisionReasonRaw.slice(0, 500)
    : decisionReasonRaw;

  if (!reportId) {
    throw new HttpsError('invalid-argument', 'reportId obrigatório');
  }

  const ref = database.collection('reports').doc(reportId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'Denúncia não encontrada.');
  }
  const beforeStatus = String((snap.data() || {}).status || 'pending_review');

  const update = {
    status,
    updatedAt: FieldValue.serverTimestamp(),
    reviewedAt: FieldValue.serverTimestamp(),
    reviewedBy: auth.uid,
  };
  if (decisionReason) {
    update.decisionReason = decisionReason;
  }

  const batch = database.batch();
  batch.set(ref, update, { merge: true });
  writeAdminAuditLog({
    database,
    batch,
    auth,
    action: 'report.update_status',
    targetType: 'report',
    targetId: reportId,
    beforeStatus,
    afterStatus: status,
    reason: decisionReason,
  });
  await batch.commit();

  return {
    ok: true,
    reportId,
    status,
  };
}

async function adminUpdateSupportTicketStatusCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);
  const ticketId = String(data.ticketId || '').trim();
  const status = String(data.status || '').trim().toLowerCase();
  const allowed = new Set(['open', 'in_progress', 'resolved', 'closed']);
  if (!ticketId) throw new HttpsError('invalid-argument', 'ticketId obrigatório');
  if (!allowed.has(status)) throw new HttpsError('invalid-argument', 'status inválido');

  const ref = database.collection('support_tickets').doc(ticketId);
  const snap = await ref.get();
  const beforeStatus = snap.exists
    ? String((snap.data() || {}).status || 'open').toLowerCase()
    : '';

  const batch = database.batch();
  batch.set(
    ref,
    {
      status,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: auth.uid,
    },
    { merge: true }
  );
  writeAdminAuditLog({
    database,
    batch,
    auth,
    action: 'support_ticket.update_status',
    targetType: 'support_ticket',
    targetId: ticketId,
    beforeStatus,
    afterStatus: status,
  });
  await batch.commit();
  return { ok: true };
}

async function adminSetNoShowDecisionCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);
  const pedidoId = String(data.pedidoId || '').trim();
  const decision = String(data.decision || '').trim().toLowerCase();
  if (!pedidoId) throw new HttpsError('invalid-argument', 'pedidoId obrigatório');
  if (!['approved', 'rejected'].includes(decision)) {
    throw new HttpsError('invalid-argument', 'decision inválido');
  }

  const ref = database.collection('pedidos').doc(pedidoId);
  const snap = await ref.get();
  const beforeDecision = snap.exists
    ? String((snap.data() || {}).noShowDecision || 'pending').toLowerCase()
    : '';

  const batch = database.batch();
  batch.set(
    ref,
    {
      noShowDecision: decision,
      noShowDecidedAt: FieldValue.serverTimestamp(),
      noShowDecidedBy: auth.uid,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  writeAdminAuditLog({
    database,
    batch,
    auth,
    action: 'no_show.set_decision',
    targetType: 'no_show',
    targetId: pedidoId,
    beforeStatus: beforeDecision,
    afterStatus: decision,
  });
  await batch.commit();

  return { ok: true };
}

async function adminDeleteStoryCore({ database = db, auth, data = {} }) {
  ensureAdmin(auth);
  const storyId = String(data.storyId || '').trim();
  if (!storyId) throw new HttpsError('invalid-argument', 'storyId obrigatório');

  const ref = database.collection('stories').doc(storyId);
  const snap = await ref.get();
  const beforeStatus = snap.exists ? 'active' : 'missing';
  const story = snap.exists ? snap.data() || {} : {};

  const batch = database.batch();
  batch.delete(ref);
  writeAdminAuditLog({
    database,
    batch,
    auth,
    action: 'story.delete',
    targetType: 'story',
    targetId: storyId,
    beforeStatus,
    afterStatus: 'deleted',
    metadata: {
      ownerId: story.prestadorId || story.ownerId || '',
    },
  });
  await batch.commit();
  return { ok: true };
}

exports.admin_getDashboardSnapshot = onCall(
  {
    region: REGION,
  },
  async (req) => {
    ensureAdmin(req.auth);

    const now = Timestamp.now();
    const since7d = new Timestamp(now.seconds - 7 * 24 * 60 * 60, now.nanoseconds);

    const [
      openTicketsSnap,
      pendingNoShowSnap,
      paymentsSnap,
      pedidosSnap,
      completedSnap,
    ] = await Promise.all([
      db.collection('support_tickets').where('status', '==', 'open').limit(200).get(),
      db.collection('pedidos').where('noShowAt', '!=', null).limit(200).get(),
      db.collection('payments').where('updatedAt', '>=', since7d).limit(500).get(),
      db.collection('pedidos').where('createdAt', '>=', since7d).limit(500).get(),
      db.collection('pedidos').where('status', '==', 'concluido').where('updatedAt', '>=', since7d).limit(500).get(),
    ]);

    let grossCents = 0;
    paymentsSnap.docs.forEach((d) => {
      const v = Number(d.data().amount || 0);
      if (Number.isFinite(v)) grossCents += Math.round(v);
    });

    return {
      generatedAt: Date.now(),
      openTickets: openTicketsSnap.size,
      pendingNoShow: pendingNoShowSnap.size,
      paymentsLast7d: paymentsSnap.size,
      grossLast7dCents: grossCents,
      pedidosLast7d: pedidosSnap.size,
      completedLast7d: completedSnap.size,
    };
  }
);

exports.admin_listReports = onCall(
  {
    region: REGION,
  },
  async (req) => adminListReportsCore({
    database: db,
    auth: req.auth,
    data: req.data || {},
  })
);

exports.handle_checkAvailability = onCall(
  {
    region: REGION,
  },
  async (req) => handleCheckAvailabilityCore({
    database: db,
    data: req.data || {},
  })
);

exports.handle_reserveProviderHandle = onCall(
  {
    region: REGION,
  },
  async (req) => handleReserveProviderHandleCore({
    database: db,
    auth: req.auth,
    data: req.data || {},
  })
);

exports.admin_updateReportStatus = onCall(
  {
    region: REGION,
  },
  async (req) => adminUpdateReportStatusCore({
    database: db,
    auth: req.auth,
    data: req.data || {},
  })
);

exports.admin_updateSupportTicketStatus = onCall(
  {
    region: REGION,
  },
  async (req) => adminUpdateSupportTicketStatusCore({
    database: db,
    auth: req.auth,
    data: req.data || {},
  })
);

exports.admin_setPilotParticipant = onCall(
  { region: REGION },
  async (req) => adminSetPilotParticipantCore({
    auth: req.auth,
    data: req.data || {},
  }),
);

exports.admin_listPilotParticipants = onCall(
  { region: REGION },
  async (req) => adminListPilotParticipantsCore({
    auth: req.auth,
    data: req.data || {},
  }),
);

exports.admin_getPilotMetrics = onCall(
  { region: REGION },
  async (req) => {
    ensureAdmin(req.auth);
    return buildPilotMetricsCore();
  },
);

exports.admin_setNoShowDecision = onCall(
  {
    region: REGION,
  },
  async (req) => adminSetNoShowDecisionCore({
    database: db,
    auth: req.auth,
    data: req.data || {},
  })
);

exports.admin_listSupportTickets = onCall(
  {
    region: REGION,
  },
  async (req) => {
    ensureAdmin(req.auth);

    const statusFilter = String(req.data?.status || 'all').trim().toLowerCase();
    const limitRaw = Number(req.data?.limit || 50);
    const limit = Math.min(200, Math.max(1, Number.isFinite(limitRaw) ? Math.round(limitRaw) : 50));
    const allowedStatuses = new Set(['all', 'open', 'in_progress', 'resolved', 'closed']);
    if (!allowedStatuses.has(statusFilter)) {
      throw new HttpsError('invalid-argument', 'status inválido');
    }

    const rawLimit = Math.max(limit * 3, 150);
    const snap = await db.collection('support_tickets')
      .orderBy('createdAt', 'desc')
      .limit(rawLimit)
      .get();

    const tickets = [];
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const status = String(data.status || 'open').toLowerCase();
      if (statusFilter !== 'all' && status !== statusFilter) continue;
      tickets.push({
        id: doc.id,
        uid: String(data.uid || ''),
        userType: String(data.userType || ''),
        subject: String(data.subject || ''),
        message: String(data.message || ''),
        status,
        createdAt: toMillis(data.createdAt),
        updatedAt: toMillis(data.updatedAt),
        updatedBy: String(data.updatedBy || ''),
      });
      if (tickets.length >= limit) break;
    }

    return {
      generatedAt: Date.now(),
      total: tickets.length,
      tickets,
    };
  }
);

exports.admin_listNoShowCases = onCall(
  {
    region: REGION,
  },
  async (req) => {
    ensureAdmin(req.auth);

    const decisionFilter = String(req.data?.decision || 'pending').trim().toLowerCase();
    const limitRaw = Number(req.data?.limit || 50);
    const limit = Math.min(200, Math.max(1, Number.isFinite(limitRaw) ? Math.round(limitRaw) : 50));
    const allowedDecisionFilters = new Set(['all', 'pending', 'approved', 'rejected']);
    if (!allowedDecisionFilters.has(decisionFilter)) {
      throw new HttpsError('invalid-argument', 'decision inválido');
    }

    const rawLimit = Math.max(limit * 4, 250);
    const snap = await db.collection('pedidos')
      .orderBy('updatedAt', 'desc')
      .limit(rawLimit)
      .get();

    const rows = [];
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const reporter = String(data.noShowReportedBy || '').toLowerCase();
      if (!reporter) continue;
      const decision = String(data.noShowDecision || 'pending').toLowerCase();
      if (decisionFilter !== 'all' && decision !== decisionFilter) continue;

      rows.push({
        pedidoId: doc.id,
        titulo: String(data.titulo || ''),
        status: String(data.status || data.estado || ''),
        clienteId: String(getClienteId(data) || ''),
        prestadorId: String(data.prestadorId || ''),
        noShowReportedBy: reporter,
        noShowReason: String(data.noShowReason || ''),
        noShowAt: toMillis(data.noShowAt || data.noShowReportedAt),
        noShowDecision: decision,
        noShowDecidedAt: toMillis(data.noShowDecidedAt),
        noShowDecidedBy: String(data.noShowDecidedBy || ''),
        updatedAt: toMillis(data.updatedAt),
      });

      if (rows.length >= limit) break;
    }

    return {
      generatedAt: Date.now(),
      total: rows.length,
      cases: rows,
    };
  }
);

exports.admin_getOpsMetrics = onCall(
  {
    region: REGION,
  },
  async (req) => {
    ensureAdmin(req.auth);

    const now = Timestamp.now();
    const daysRaw = Number(req.data?.days || 30);
    const days = Math.min(90, Math.max(7, Number.isFinite(daysRaw) ? Math.round(daysRaw) : 30));
    const since = new Timestamp(
      now.seconds - days * 24 * 60 * 60,
      now.nanoseconds
    );

    const [pedidosSnap, paymentsSnap, subscriptionsSnap] = await Promise.all([
      db.collection('pedidos').where('createdAt', '>=', since).limit(2000).get(),
      db.collection('payments').where('updatedAt', '>=', since).limit(2000).get(),
      db.collection('subscriptions').limit(2000).get(),
    ]);

    let created = 0;
    let accepted = 0;
    let inProgress = 0;
    let completed = 0;
    let cancelled = 0;
    let noShowReported = 0;
    let noShowPending = 0;
    let noShowApproved = 0;
    let noShowRejected = 0;

    pedidosSnap.docs.forEach((doc) => {
      const data = doc.data() || {};
      const status = String(data.status || data.estado || '').toLowerCase();
      created += 1;
      if (['aceito', 'em_andamento', 'concluido'].includes(status)) accepted += 1;
      if (status === 'em_andamento') inProgress += 1;
      if (status === 'concluido') completed += 1;
      if (status === 'cancelado') cancelled += 1;

      const hasNoShow = String(data.noShowReportedBy || '').trim().length > 0;
      if (hasNoShow) {
        noShowReported += 1;
        const decision = String(data.noShowDecision || 'pending').toLowerCase();
        if (decision === 'approved') noShowApproved += 1;
        else if (decision === 'rejected') noShowRejected += 1;
        else noShowPending += 1;
      }
    });

    let grossCents = 0;
    let feeCents = 0;
    let netCents = 0;
    let succeededPayments = 0;
    let failedPayments = 0;
    let pendingPayments = 0;

    paymentsSnap.docs.forEach((doc) => {
      const data = doc.data() || {};
      const status = String(data.status || '').toLowerCase();
      const amount = Number(data.amount || 0);
      const fee = Number(data.feeAmount || 0);
      if (status === 'succeeded') {
        succeededPayments += 1;
        if (Number.isFinite(amount)) grossCents += Math.round(amount);
        if (Number.isFinite(fee)) feeCents += Math.round(fee);
      } else if (status.includes('fail') || status === 'canceled') {
        failedPayments += 1;
      } else {
        pendingPayments += 1;
      }
    });
    netCents = Math.max(0, grossCents - feeCents);

    let subscriptionsActive = 0;
    let subscriptionsPastDue = 0;
    let subscriptionsCanceled = 0;
    subscriptionsSnap.docs.forEach((doc) => {
      const data = doc.data() || {};
      const status = String(data.status || '').toLowerCase();
      if (['active', 'trialing'].includes(status)) subscriptionsActive += 1;
      else if (status === 'past_due') subscriptionsPastDue += 1;
      else if (['canceled', 'unpaid', 'incomplete_expired'].includes(status)) subscriptionsCanceled += 1;
    });

    return {
      generatedAt: Date.now(),
      windowDays: days,
      funnel: {
        created,
        accepted,
        inProgress,
        completed,
        cancelled,
      },
      noShow: {
        reported: noShowReported,
        pending: noShowPending,
        approved: noShowApproved,
        rejected: noShowRejected,
      },
      revenue: {
        grossCents,
        feeCents,
        netCents,
        succeededPayments,
        failedPayments,
        pendingPayments,
      },
      subscriptions: {
        active: subscriptionsActive,
        pastDue: subscriptionsPastDue,
        canceled: subscriptionsCanceled,
      },
    };
  }
);

exports.admin_getCostRetentionSnapshot = onCall(
  {
    region: REGION,
  },
  async (req) => {
    ensureAdmin(req.auth);

    const now = Timestamp.now();
    const since30 = new Timestamp(now.seconds - 30 * 24 * 60 * 60, now.nanoseconds);
    const since90 = new Timestamp(now.seconds - 90 * 24 * 60 * 60, now.nanoseconds);

    const [
      usersLast30Snap,
      usersLast90Snap,
      pedidosLast30Snap,
      paymentsLast30Snap,
      paymentsAllSnap,
      subscriptionsSnap,
    ] = await Promise.all([
      db.collection('users_private').where('createdAt', '>=', since30).limit(3000).get(),
      db.collection('users_private').where('createdAt', '>=', since90).limit(9000).get(),
      db.collection('pedidos').where('updatedAt', '>=', since30).limit(5000).get(),
      db.collection('payments').where('updatedAt', '>=', since30).limit(5000).get(),
      db.collection('payments').limit(9000).get(),
      db.collection('subscriptions').limit(3000).get(),
    ]);

    const activeUserIds = new Set();
    pedidosLast30Snap.docs.forEach((doc) => {
      const data = doc.data() || {};
      const clienteId = String(getClienteId(data) || '');
      const prestadorId = String(data.prestadorId || '');
      if (clienteId) activeUserIds.add(clienteId);
      if (prestadorId) activeUserIds.add(prestadorId);
    });

    let gross30Cents = 0;
    let fee30Cents = 0;
    paymentsLast30Snap.docs.forEach((doc) => {
      const data = doc.data() || {};
      const status = String(data.status || '').toLowerCase();
      if (status !== 'succeeded') return;
      const amount = Number(data.amount || 0);
      const fee = Number(data.feeAmount || 0);
      if (Number.isFinite(amount)) gross30Cents += Math.round(amount);
      if (Number.isFinite(fee)) fee30Cents += Math.round(fee);
      const clienteId = String(data.clienteId || '');
      const prestadorId = String(data.prestadorId || '');
      if (clienteId) activeUserIds.add(clienteId);
      if (prestadorId) activeUserIds.add(prestadorId);
    });

    let grossAllCents = 0;
    const payingUserIds = new Set();
    paymentsAllSnap.docs.forEach((doc) => {
      const data = doc.data() || {};
      const status = String(data.status || '').toLowerCase();
      if (status !== 'succeeded') return;
      const amount = Number(data.amount || 0);
      if (Number.isFinite(amount)) grossAllCents += Math.round(amount);
      const clienteId = String(data.clienteId || '');
      const prestadorId = String(data.prestadorId || '');
      if (clienteId) payingUserIds.add(clienteId);
      if (prestadorId) payingUserIds.add(prestadorId);
    });

    let activeSubs = 0;
    let canceledIn30 = 0;
    subscriptionsSnap.docs.forEach((doc) => {
      const data = doc.data() || {};
      const status = String(data.status || '').toLowerCase();
      if (['active', 'trialing', 'past_due'].includes(status)) {
        activeSubs += 1;
        if (doc.id) activeUserIds.add(doc.id);
        if (doc.id) payingUserIds.add(doc.id);
      }
      const canceledAtMs = toMillis(data.canceledAt);
      if (canceledAtMs && canceledAtMs >= toMillis(since30)) {
        canceledIn30 += 1;
      }
    });

    const newUsers30 = usersLast30Snap.size;
    const activeUsers30 = activeUserIds.size;

    const marketingSpend30Cents = Number(getEnv('MARKETING_SPEND_30D_CENTS', '0')) || 0;
    const ltvMonths = Number(getEnv('LTV_MONTHS_ASSUMPTION', '6')) || 6;

    const cacCents = newUsers30 > 0
      ? Math.round(marketingSpend30Cents / newUsers30)
      : 0;
    const arppuCents = payingUserIds.size > 0
      ? Math.round(grossAllCents / payingUserIds.size)
      : 0;
    const ltvCents = Math.round(arppuCents * ltvMonths);
    const churnRate30 = subscriptionsSnap.size > 0
      ? Number((canceledIn30 / subscriptionsSnap.size).toFixed(4))
      : 0;

    const cohortsMap = new Map();
    usersLast90Snap.docs.forEach((doc) => {
      const data = doc.data() || {};
      const createdAtMs = toMillis(data.createdAt);
      const monthKey = formatMonthKeyFromMillis(createdAtMs);
      if (!monthKey) return;
      if (!cohortsMap.has(monthKey)) {
        cohortsMap.set(monthKey, { users: 0, retainedUsers: 0 });
      }
      const item = cohortsMap.get(monthKey);
      item.users += 1;
      if (activeUserIds.has(doc.id)) item.retainedUsers += 1;
    });

    const cohorts = Array.from(cohortsMap.entries())
      .sort((a, b) => b[0].localeCompare(a[0]))
      .slice(0, 6)
      .map(([month, item]) => ({
        month,
        users: item.users,
        retainedUsers: item.retainedUsers,
        retentionRate: item.users > 0
          ? Number((item.retainedUsers / item.users).toFixed(4))
          : 0,
      }));

    return {
      generatedAt: Date.now(),
      acquisition: {
        newUsers30,
        marketingSpend30Cents,
        cacCents,
      },
      revenue: {
        gross30Cents,
        fee30Cents,
        net30Cents: Math.max(0, gross30Cents - fee30Cents),
        grossAllCents,
        payingUsers: payingUserIds.size,
        arppuCents,
        ltvCents,
        ltvMonthsAssumption: ltvMonths,
      },
      retention: {
        activeUsers30,
        activeSubscriptions: activeSubs,
        canceledSubscriptions30: canceledIn30,
        churnRate30,
      },
      cohorts,
    };
  }
);

exports.admin_listStories = onCall(
  {
    region: REGION,
  },
  async (req) => {
    ensureAdmin(req.auth);
    const limitRaw = Number(req.data?.limit || 50);
    const limit = Math.min(200, Math.max(1, Number.isFinite(limitRaw) ? Math.round(limitRaw) : 50));

    const snap = await db.collection('stories')
      .orderBy('expiresAt', 'desc')
      .limit(limit)
      .get();

    const stories = snap.docs.map((doc) => {
      const data = doc.data() || {};
      return {
        id: doc.id,
        ...data,
        createdAt: toMillis(data.createdAt),
        expiresAt: toMillis(data.expiresAt),
      };
    });

    return { stories };
  }
);

exports.admin_deleteStory = onCall(
  {
    region: REGION,
  },
  async (req) => adminDeleteStoryCore({
    database: db,
    auth: req.auth,
    data: req.data || {},
  })
);

exports.admin_listAuditLogs = onCall(
  {
    region: REGION,
  },
  async (req) => adminListAuditLogsCore({
    database: db,
    auth: req.auth,
    data: req.data || {},
  })
);

exports.admin_listSensitiveCategoryRequests = onCall(
  {
    region: REGION,
  },
  async (req) => adminListSensitiveCategoryRequestsCore({
    database: db,
    auth: req.auth,
    data: req.data || {},
  })
);

exports.admin_reviewSensitiveCategoryRequest = onCall(
  {
    region: REGION,
  },
  async (req) => adminReviewSensitiveCategoryRequestCore({
    database: db,
    auth: req.auth,
    data: req.data || {},
  })
);

exports.admin_getLedgerAnomalies = onCall(
  {
    region: REGION,
  },
  async (req) => {
    ensureAdmin(req.auth);
    const limitRaw = Number(req.data?.limit || 50);
    const limit = Math.min(200, Math.max(1, Number.isFinite(limitRaw) ? Math.round(limitRaw) : 50));

    // Procura pagamentos bem-sucedidos recentemente
    const paymentsSnap = await db.collection('payments')
      .where('status', '==', 'succeeded')
      .orderBy('updatedAt', 'desc')
      .limit(limit)
      .get();

    const anomalies = [];
    for (const pDoc of paymentsSnap.docs) {
      const pData = pDoc.data();
      const piId = pDoc.id;

      // Verifica se existe entrada correspondente no ledger
      const ledgerSnap = await db.collection('payment_ledger')
        .where('paymentIntentId', '==', piId)
        .where('eventType', 'in', ['payment_intent.succeeded', 'charge.succeeded'])
        .limit(1)
        .get();

      if (ledgerSnap.empty) {
        anomalies.push({
          paymentIntentId: piId,
          pedidoId: pData.pedidoId,
          clienteId: pData.clienteId,
          prestadorId: pData.prestadorId,
          amount: pData.amount,
          updatedAt: toMillis(pData.updatedAt),
        });
      }
    }

    return { anomalies };
  }
);

// ------------------------------------------------------------
// 6) Cleanup agendada (opcional): remover tokens antigos
// ------------------------------------------------------------


exports.scheduled_cleanupFcmTokens = onSchedule(
  {
    region: REGION,
    schedule: 'every day 03:00',
    timeZone: 'Europe/Lisbon',
  },
  async () => {
    // NOTA: Para TTL real, usa a funcionalidade TTL do Firestore.
    // Aqui fazemos uma limpeza simples baseada em lastSeenAt (se implementares no app).
    logger.info('[cleanupFcmTokens] executado');
  }
);

async function cleanupKycRetentionCore({
  database = db,
  bucket = firebaseStorage.bucket(),
  now = Timestamp.now(),
}) {
  const expired = await database.collection('kyc_submissions')
    .where('retentionDeleteAt', '<=', now)
    .limit(100)
    .get();
  let deletedDocuments = 0;
  for (const doc of expired.docs) {
    const data = doc.data() || {};
    const paths = Array.isArray(data.documentPaths) ? data.documentPaths : [];
    await Promise.all(paths.map(async (path) => {
      try {
        await bucket.file(path).delete({ ignoreNotFound: true });
        deletedDocuments += 1;
      } catch (error) {
        logger.warn('[kyc-retention] Falha ao apagar ficheiro.', { path, error: String(error) });
      }
    }));
    await doc.ref.set({
      status: data.status === 'approved' ? 'approved' : 'documents_deleted',
      documentsDeletedAt: FieldValue.serverTimestamp(),
      documentPaths: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  const expiredGrants = await database.collection('kyc_upload_grants')
    .where('expiresAt', '<=', now)
    .limit(100)
    .get();
  for (const grant of expiredGrants.docs) {
    await grant.ref.delete();
    try {
      await setKycUploadClaim(grant.id, false);
    } catch (error) {
      logger.warn('[kyc-retention] Falha ao revogar claim.', { uid: maskIdentifier(grant.id) });
    }
  }

  const activePathSet = new Set();
  const activeSubmissions = await database.collection('kyc_submissions').limit(2000).get();
  activeSubmissions.docs.forEach((doc) => {
    const paths = doc.data().documentPaths;
    if (Array.isArray(paths)) paths.forEach((path) => activePathSet.add(cleanString(path)));
  });
  const abandonedBefore = now.toMillis() - 24 * 60 * 60 * 1000;
  let pageToken;
  let deletedAbandoned = 0;
  do {
    const [files, nextQuery] = await bucket.getFiles({
      prefix: 'kyc_pending/',
      maxResults: 250,
      autoPaginate: false,
      pageToken,
    });
    for (const file of files) {
      const [metadata] = await file.getMetadata();
      const createdAt = Date.parse(metadata.timeCreated || '');
      if (!activePathSet.has(file.name) && Number.isFinite(createdAt) && createdAt <= abandonedBefore) {
        await file.delete({ ignoreNotFound: true });
        deletedAbandoned += 1;
      }
    }
    pageToken = nextQuery && nextQuery.pageToken;
  } while (pageToken);

  return {
    expiredSubmissions: expired.size,
    deletedDocuments,
    expiredGrants: expiredGrants.size,
    deletedAbandoned,
  };
}

exports.scheduled_cleanupKycRetention = onSchedule(
  {
    region: REGION,
    schedule: 'every day 03:30',
    timeZone: 'Africa/Maputo',
  },
  async () => {
    const result = await cleanupKycRetentionCore({});
    logger.info('[kyc-retention] Limpeza concluida.', result);
  },
);

exports.scheduled_executeAccountDeletions = onSchedule(
  {
    region: REGION,
    schedule: 'every day 04:00',
    timeZone: 'Africa/Maputo',
    secrets: [ACCOUNT_DELETION_PEPPER],
  },
  async () => {
    const due = await db.collection('account_deletion_requests')
      .where('executeAt', '<=', Timestamp.now())
      .limit(25)
      .get();
    const results = [];
    for (const doc of due.docs) {
      if (!['pending', 'pending_active_work'].includes(cleanString(doc.data().status))) continue;
      try {
        results.push(await executeAccountDeletionCore({ uid: doc.id }));
      } catch (error) {
        logger.error('[account-deletion] Falha ao eliminar conta.', {
          uid: maskIdentifier(doc.id),
          error: String(error),
        });
      }
    }
    logger.info('[account-deletion] Ciclo concluido.', { due: due.size, processed: results.length });
  },
);

exports.scheduled_buildPilotMetrics = onSchedule(
  {
    region: REGION,
    schedule: 'every day 05:00',
    timeZone: 'Africa/Maputo',
  },
  async () => {
    const metrics = await buildPilotMetricsCore();
    const maputoDate = new Date(metrics.generatedAt + 2 * 60 * 60 * 1000)
      .toISOString()
      .slice(0, 10);
    const batch = db.batch();
    batch.set(db.collection('pilot_metrics_daily').doc(maputoDate), {
      ...metrics,
      collectedAt: FieldValue.serverTimestamp(),
    });
    batch.set(db.collection('pilot_metrics_daily').doc('latest'), {
      ...metrics,
      metricDate: maputoDate,
      collectedAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
    logger.info('[pilot-metrics] Snapshot diario criado.', { maputoDate });
  },
);

// ------------------------------------------------------------
// 7) Lembretes agendados (G3)
// ------------------------------------------------------------

exports.scheduled_orderReminders = onSchedule(
  {
    region: REGION,
    schedule: 'every 10 minutes',
    timeZone: 'Europe/Lisbon',
  },
  async () => {
    const nowMs = Date.now();
    const activeStates = ['criado', 'aguarda_resposta_prestador', 'aceito', 'em_andamento'];

    const windows = [
      { key: 'r60', fromMin: 55, toMin: 65, title: 'Lembrete: serviço em 1h' },
      { key: 'r15', fromMin: 12, toMin: 18, title: 'Lembrete: serviço em 15 min' },
    ];

    for (const w of windows) {
      const from = Timestamp.fromMillis(nowMs + w.fromMin * 60 * 1000);
      const to = Timestamp.fromMillis(nowMs + w.toMin * 60 * 1000);

      const snap = await db.collection('pedidos')
        .where('modo', '==', 'AGENDADO')
        .where('status', 'in', activeStates)
        .where('agendadoPara', '>=', from)
        .where('agendadoPara', '<=', to)
        .limit(200)
        .get();

      for (const doc of snap.docs) {
        const pedidoId = doc.id;
        const data = doc.data() || {};
        const clienteId = getClienteId(data);
        const prestadorId = String(data.prestadorId || '');

        if (!clienteId && !prestadorId) continue;

        const markerRef = db.collection('scheduled_reminder_logs').doc(`${pedidoId}_${w.key}`);
        let shouldSend = false;
        await db.runTransaction(async (tx) => {
          const marker = await tx.get(markerRef);
          if (!marker.exists) {
            shouldSend = true;
            tx.set(markerRef, {
              pedidoId,
              key: w.key,
              createdAt: FieldValue.serverTimestamp(),
            });
          }
        });
        if (!shouldSend) continue;

        const body = 'Confirma os detalhes do pedido e o deslocamento.';
        if (clienteId) {
          await sendPushToUser(clienteId, {
            title: w.title,
            body,
            data: { type: 'scheduled_reminder', pedidoId, window: w.key },
          });
          await saveInAppNotification(clienteId, {
            type: 'scheduled_reminder',
            pedidoId,
            title: w.title,
            body,
            window: w.key,
          });
        }
        if (prestadorId) {
          await sendPushToUser(prestadorId, {
            title: w.title,
            body,
            data: { type: 'scheduled_reminder', pedidoId, window: w.key },
          });
          await saveInAppNotification(prestadorId, {
            type: 'scheduled_reminder',
            pedidoId,
            title: w.title,
            body,
            window: w.key,
          });
        }
      }
    }
  }
);

exports.scheduled_enforceCommissionDebt = onSchedule(
  {
    region: REGION,
    schedule: 'every 6 hours',
    timeZone: 'Africa/Maputo',
  },
  async () => {
    const result = await enforceCommissionDebtCore();
    logger.info('[finance] verificacao de comissoes concluida', result);
  },
);

// ------------------------------------------------------------
// 8) Timeout de pedidos (A6)
// ------------------------------------------------------------

exports.scheduled_expireRequests = onSchedule(
  {
    region: REGION,
    schedule: 'every 15 minutes', // Executa frequentemente para limpar pendentes
    timeZone: 'Europe/Lisbon',
  },
  async () => {
    const now = Timestamp.now();
    // 30 minutos atrás
    const cutoff = new Timestamp(now.seconds - 30 * 60, now.nanoseconds);

    // Estados pendentes sujeitos a timeout
    const states = ['criado', 'aguarda_resposta_prestador'];

    const snapshot = await db.collection('pedidos')
      .where('status', 'in', states)
      .where('updatedAt', '<', cutoff)
      .limit(100)
      .get();

    if (snapshot.empty) {
      return;
    }

    const batch = db.batch();
    let count = 0;

    snapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'cancelado',
        cancelReason: 'timeout_sistema',
        updatedAt: now,
      });
      count++;
    });

    await batch.commit();
    logger.info(`[expireRequests] Cancelados ${count} pedidos expirados.`);
  }
);

exports.__test__ = {
  // Keep the Firestore client behind a function. The Firebase Functions loader
  // recursively walks every exported object while discovering endpoints; a
  // raw Firestore instance contains cycles and makes discovery overflow.
  getDb: () => db,
  avaliacoes: {
    calculateAvaliacaoRatingAggregates,
    onAvaliacaoCreatedCore,
  },
  pedidos: {
    acceptPedidoDispatchCore,
    buildPedidoDispatchProjection,
    buildSecurePedidoData,
    cashCommissionPolicy,
    calculatePedidoEconomics,
    catalogDocumentIsActive,
    classifyServerServiceText,
    confirmarValorFinalPedidoCore,
    createSecurePedidoCore,
    isOpenPedido,
    providerMatchesPedido,
    promotePedidoAttachments,
    proporValorFinalPedidoCore,
    sanitizeDispatchText,
    sanitizeDispatchZone,
    syncPedidoDispatch,
    updateSecurePedidoCore,
  },
  payments: {
    enforceCommissionDebtCore,
    paymentMethodEnabled,
    recordCommissionPaymentCore,
  },
  providers: {
    sanitizeProviderCustomService,
    updateProviderServicesCore,
  },
  auth: {
    mergeAnonymousDataCore,
    mergePreferTarget,
    syncPhoneIdentityCore,
  },
  legal: {
    LEGAL_DOCUMENT_VERSION,
    acceptLegalDocumentsCore,
    requireCurrentLegalConsent,
  },
  support: {
    SUPPORT_SUBJECTS,
    createSupportTicketCore,
  },
  pilot: {
    adminListPilotParticipantsCore,
    adminSetPilotParticipantCore,
    buildPilotMetricsCore,
    enforcePilotOrderLocation,
    normalizedPilotRoles,
    pilotAllowlistRequired,
    pilotParticipantIsActive,
    requirePilotParticipant,
  },
  accounts: {
    ACCOUNT_DELETION_GRACE_DAYS,
    accountDeletionPseudonym,
    cancelAccountDeletionCore,
    executeAccountDeletionCore,
    findActiveAccountOrders,
    isActiveAccountOrder,
    requestAccountDeletionCore,
  },
  kyc: {
    KYC_CONSENT_VERSION,
    beginKycSubmissionCore,
    cleanupKycRetentionCore,
    deleteMyKycSubmissionCore,
    normalizeKycDecision,
    normalizeKycDocumentPaths,
    reviewKycSubmissionCore,
    submitKycCore,
  },
  privateStorage: {
    PRIVATE_STORAGE_SIGNED_URL_TTL_MS,
    authorizePrivateStoragePath,
    finalizePrivateStorageUploadCore,
    getPrivateStorageReadUrlCore,
    normalizePrivateStoragePath,
  },
  handles: {
    normalizePublicHandle,
    validatePublicHandle,
    handleCheckAvailabilityCore,
    handleReserveProviderHandleCore,
  },
  admin: {
    adminListReportsCore,
    adminUpdateReportStatusCore,
    adminUpdateSupportTicketStatusCore,
    adminSetNoShowDecisionCore,
    adminDeleteStoryCore,
    adminListAuditLogsCore,
    adminListSensitiveCategoryRequestsCore,
    adminReviewSensitiveCategoryRequestCore,
    writeAdminAuditLog,
  },
};
