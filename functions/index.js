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
  getFirestore, Timestamp, FieldValue, FieldPath, GeoPoint,
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

function getCanonicalPedidoStatus(data) {
  if (!data || typeof data !== 'object') return '';
  const hasStatus = Object.prototype.hasOwnProperty.call(data, 'status');
  const hasEstado = Object.prototype.hasOwnProperty.call(data, 'estado');
  if (!hasStatus || typeof data.status !== 'string') return '';
  const status = data.status.trim();
  if (!status) return '';
  if (hasEstado) {
    if (typeof data.estado !== 'string' || data.estado.trim() !== status) return '';
  }
  return status;
}

function sanitizeDispatchText(value, maxLength = 500) {
  return safeText(value, maxLength)
    .replace(/[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}/g, '[contacto removido]')
    .replace(/(?:https?:\/\/|www\.)\S+/gi, '[link removido]')
    .replace(/(?:\+|00)?\d(?:[\s().-]*\d){6,}/g, '[contacto removido]')
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
  const candidates = parts.slice(-2).map((part) => part.replace(/\b\d+[A-Za-z-]*\b/g, '').trim());
  const zone = candidates.filter(Boolean).join(', ');
  return sanitizeDispatchText(zone || 'Zona aproximada', 120);
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

function buildPedidoDispatchProjection(pedidoId, pedido = {}) {
  const latitude = approximateCoordinate(pedido.latitude ?? pedido.geo?.geopoint?.latitude);
  const longitude = approximateCoordinate(pedido.longitude ?? pedido.geo?.geopoint?.longitude);
  // enderecoTexto is deliberately excluded: it is client-authored and can
  // contain a door, landmark, phone number or other identifying detail.
  const zoneLabel = sanitizeDispatchZone(dispatchZoneSource(pedido));
  const mode = normalizedDispatchMode(pedido.modo);
  const status = getCanonicalPedidoStatus(pedido) || 'criado';
  const serviceLabel = pedido.isCustomService === true
    ? 'Serviço personalizado'
    : sanitizeDispatchText(pedido.servicoNome || pedido.categoria, 160);
  const targetProviderId = ['aguarda_resposta_prestador', 'aguarda_resposta_cliente'].includes(status)
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
    createdAt: pedido.createdAt || FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function buildPedidoOpportunityNotification(pedidoId, pedido = {}) {
  const projection = buildPedidoDispatchProjection(pedidoId, pedido);
  const service = projection.servicoNome || projection.categoria || 'Serviço local';
  const modeLabel = {
    AGENDADO: 'Horário agendado',
    POR_PROPOSTA: 'Orçamento/projeto',
    IMEDIATO: 'Disponível agora',
  }[projection.modo];
  return {
    title: 'ChegaJá - Novo pedido perto de ti',
    body: safeText([service, projection.zoneLabel, modeLabel].filter(Boolean).join(' | '), 120),
    data: {
      type: 'novo_pedido',
      pedidoId,
    },
  };
}

function isOpenPedido(pedido) {
  return getCanonicalPedidoStatus(pedido) === 'criado'
    && !cleanString(pedido?.prestadorId)
    && cleanString(pedido?.moderationStatus || 'approved') === 'approved';
}

function isTargetedDispatchPedido(pedido) {
  return ['aguarda_resposta_prestador', 'aguarda_resposta_cliente'].includes(
    getCanonicalPedidoStatus(pedido),
  )
    && !!cleanString(pedido?.prestadorId)
    && cleanString(pedido?.moderationStatus || 'approved') === 'approved';
}

async function syncPedidoDispatch(database, pedidoId) {
  const cleanPedidoId = cleanString(pedidoId);
  if (!cleanPedidoId) throw new HttpsError('invalid-argument', 'pedidoId obrigatorio.');
  const pedidoRef = database.collection('pedidos').doc(cleanPedidoId);
  const dispatchRef = database.collection('pedido_dispatch').doc(cleanPedidoId);
  return database.runTransaction(async (transaction) => {
    const pedidoSnap = await transaction.get(pedidoRef);
    const pedido = pedidoSnap.exists ? (pedidoSnap.data() || {}) : null;
    const open = !!pedido && isOpenPedido(pedido);
    const targeted = !!pedido && isTargetedDispatchPedido(pedido);
    if (!open && !targeted) {
      transaction.delete(dispatchRef);
      return { open: false, targeted: false, pedido };
    }
    transaction.set(
      dispatchRef,
      buildPedidoDispatchProjection(cleanPedidoId, pedido),
      { merge: false },
    );
    return { open, targeted, pedido };
  });
}

async function syncProviderActiveClients(database, providerId, { pageSize = 500 } = {}) {
  const cleanProviderId = cleanString(providerId);
  if (!cleanProviderId) return;
  if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 500) {
    throw new Error('pageSize must be an integer between 1 and 500');
  }
  const activeStates = [
    'aceito',
    'em_andamento',
    'aguarda_confirmacao_valor',
  ];
  const activeClientIds = new Set();
  let cursor = null;
  while (true) {
    let query = database.collection('pedidos')
      .where('prestadorId', '==', cleanProviderId)
      .where('status', 'in', activeStates)
      .orderBy(FieldPath.documentId())
      .limit(pageSize);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    snapshot.docs
      .map((doc) => doc.data() || {})
      .filter((pedido) => providerHasFullPedidoAccess(pedido, cleanProviderId))
      .map(getClienteId)
      .filter(Boolean)
      .forEach((clientId) => activeClientIds.add(clientId));
    if (snapshot.size < pageSize) break;
    cursor = snapshot.docs[snapshot.docs.length - 1];
  }
  await database.collection('provider_dispatch_private').doc(cleanProviderId).set({
    providerId: cleanProviderId,
    activeClientIds: [...activeClientIds],
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

const PROVIDER_LOCATION_MAX_AGE_MINUTES_DEFAULT = 30;

function deterministicCompositeDocumentId(prefix, components) {
  const normalized = components.map((component) => cleanString(component));
  if (normalized.some((component) => !component)) {
    throw new HttpsError('invalid-argument', 'Identificador composto invalido.');
  }
  const payload = normalized
    .map((component) => `${Buffer.byteLength(component, 'utf8')}:${component}`)
    .join('|');
  const digest = crypto.createHash('sha256').update(payload).digest('hex');
  return `${prefix}_${digest}`;
}

function opportunityDocumentId(pedidoId, providerId) {
  return deterministicCompositeDocumentId('opp', [pedidoId, providerId]);
}

function acceptanceQuotaDocumentId(providerId, acceptanceWindow) {
  return deterministicCompositeDocumentId('quota', [providerId, String(acceptanceWindow)]);
}

function safeLegacyCompositeDocumentId(components) {
  const legacy = components.map((component) => cleanString(component)).join('_');
  return legacy
    && !legacy.includes('/')
    && Buffer.byteLength(legacy, 'utf8') <= 1500
    ? legacy
    : null;
}

function numericCoordinate(value, minimum, maximum) {
  const coordinate = Number(value);
  return Number.isFinite(coordinate) && coordinate >= minimum && coordinate <= maximum
    ? coordinate
    : null;
}

function pedidoCoordinates(pedido = {}) {
  const geopoint = pedido.geo && pedido.geo.geopoint;
  const latitude = numericCoordinate(
    geopoint && geopoint.latitude !== undefined ? geopoint.latitude : pedido.latitude,
    -90,
    90,
  );
  const longitude = numericCoordinate(
    geopoint && geopoint.longitude !== undefined ? geopoint.longitude : pedido.longitude,
    -180,
    180,
  );
  return latitude === null || longitude === null ? null : { latitude, longitude };
}

function providerDispatchLocation(dispatchState = {}, nowMillis = Date.now()) {
  const maxAgeMinutes = Math.max(
    5,
    Math.min(
      Number(getEnv(
        'PROVIDER_LOCATION_MAX_AGE_MINUTES',
        String(PROVIDER_LOCATION_MAX_AGE_MINUTES_DEFAULT),
      )) || PROVIDER_LOCATION_MAX_AGE_MINUTES_DEFAULT,
      60,
    ),
  );
  const location = dispatchState.lastLocation;
  const geo = dispatchState.geo;
  const geopoint = geo && geo.geopoint;
  const latitude = numericCoordinate(location && location.lat, -90, 90);
  const longitude = numericCoordinate(location && location.lng, -180, 180);
  const geoLatitude = numericCoordinate(geopoint && geopoint.latitude, -90, 90);
  const geoLongitude = numericCoordinate(geopoint && geopoint.longitude, -180, 180);
  const radiusKm = Number(dispatchState.radiusKm);
  const lastLocationAtMillis = toMillis(dispatchState.lastLocationAt);
  const geohash = cleanString(geo && geo.geohash);
  const coordinatesAgree = latitude !== null
    && longitude !== null
    && geoLatitude !== null
    && geoLongitude !== null
    && Math.abs(latitude - geoLatitude) <= 1e-9
    && Math.abs(longitude - geoLongitude) <= 1e-9;
  const fresh = !!lastLocationAtMillis
    && lastLocationAtMillis <= nowMillis + 60 * 1000
    && lastLocationAtMillis >= nowMillis - maxAgeMinutes * 60 * 1000;
  if (!coordinatesAgree
    || !fresh
    || geohash.length < 5
    || geohash.length > 12
    || !Number.isFinite(radiusKm)
    || radiusKm < 1
    || radiusKm > 50) {
    return null;
  }
  return { latitude, longitude, radiusKm, lastLocationAtMillis };
}

async function acceptPedidoDispatchCore({ database = db, auth, pedidoId }) {
  if (!auth || !auth.uid) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  if (!auth.token || !cleanString(auth.token.phone_number)) {
    throw new HttpsError('failed-precondition', 'Confirma o telefone antes de aceitar trabalhos.');
  }
  const providerId = cleanString(auth.uid);
  const cleanPedidoId = cleanString(pedidoId);
  if (!cleanPedidoId) throw new HttpsError('invalid-argument', 'pedidoId obrigatorio.');
  const nowMillis = Date.now();

  const pedidoRef = database.collection('pedidos').doc(cleanPedidoId);
  const dispatchRef = database.collection('pedido_dispatch').doc(cleanPedidoId);
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
    if (pedidoIsSelfDealing(pedido, providerId)) {
      throw new HttpsError('permission-denied', 'Nao podes aceitar um pedido da tua propria conta.');
    }
    if (pedidoRequiresAcceptedQuote(pedido)) {
      throw new HttpsError(
        'failed-precondition',
        'Este pedido exige uma estimativa aceite antes de revelar os dados privados.',
      );
    }
    const opportunityCollection = database.collection('provider_opportunities');
    const opportunityRefV2 = opportunityCollection
      .doc(opportunityDocumentId(cleanPedidoId, providerId));
    const legacyOpportunityId = safeLegacyCompositeDocumentId([cleanPedidoId, providerId]);
    const legacyOpportunityRef = legacyOpportunityId
      ? opportunityCollection.doc(legacyOpportunityId)
      : null;
    let opportunityRef = opportunityRefV2;
    let opportunity = null;
    if (!invitedProvider) {
      let opportunitySnap = await tx.get(opportunityRefV2);
      if (!opportunitySnap.exists
        && legacyOpportunityRef
        && legacyOpportunityRef.path !== opportunityRefV2.path) {
        const legacyOpportunitySnap = await tx.get(legacyOpportunityRef);
        if (legacyOpportunitySnap.exists) {
          opportunitySnap = legacyOpportunitySnap;
          opportunityRef = legacyOpportunityRef;
        }
      }
      opportunity = opportunitySnap.exists ? (opportunitySnap.data() || {}) : null;
      const expiresAtMillis = toMillis(opportunity && opportunity.expiresAt);
      if (!opportunity
        || cleanString(opportunity.pedidoId) !== cleanPedidoId
        || cleanString(opportunity.providerId) !== providerId
        || cleanString(opportunity.status) !== 'active'
        || !expiresAtMillis
        || expiresAtMillis <= nowMillis) {
        throw new HttpsError(
          'permission-denied',
          'Esta oportunidade nao esta ativa para a tua conta.',
        );
      }
    }
    const eligibleProvider = await readEligibleProviderForPedido({
      transaction: tx,
      database,
      providerId,
      pedido,
      requireAvailableForNewWork: true,
      requireOnlineForNewWork: !invitedProvider,
      nowMillis,
    });
    if (!invitedProvider) {
      const currentProviderLocation = providerDispatchLocation(
        eligibleProvider.dispatchState,
        nowMillis,
      );
      const currentPedidoLocation = pedidoCoordinates(pedido);
      if (!currentProviderLocation || !currentPedidoLocation) {
        throw new HttpsError(
          'failed-precondition',
          'Atualiza a tua localizacao antes de aceitar esta oportunidade.',
        );
      }
      const currentDistanceKm = geofire.distanceBetween(
        [currentProviderLocation.latitude, currentProviderLocation.longitude],
        [currentPedidoLocation.latitude, currentPedidoLocation.longitude],
      );
      if (!Number.isFinite(currentDistanceKm)
        || currentDistanceKm > currentProviderLocation.radiusKm) {
        throw new HttpsError(
          'failed-precondition',
          'A oportunidade ja esta fora da tua area atual de atendimento.',
        );
      }
    }
    const acceptanceWindow = Math.floor(nowMillis / (60 * 60 * 1000)) * 60 * 60 * 1000;
    const acceptanceLimit = Math.max(
      1,
      Math.min(Number(getEnv('PROVIDER_ACCEPTANCES_PER_HOUR', '5')) || 5, 20),
    );
    const acceptanceLimitCollection = database.collection('provider_acceptance_limits');
    const acceptanceLimitRef = acceptanceLimitCollection
      .doc(acceptanceQuotaDocumentId(providerId, acceptanceWindow));
    const acceptanceLimitSnap = await tx.get(acceptanceLimitRef);
    let acceptanceCount = acceptanceLimitSnap.exists
      ? Number(acceptanceLimitSnap.data().count || 0)
      : 0;
    if (!acceptanceLimitSnap.exists) {
      const legacyAcceptanceLimitId = safeLegacyCompositeDocumentId([
        providerId,
        acceptanceWindow,
      ]);
      if (legacyAcceptanceLimitId) {
        const legacyAcceptanceLimitSnap = await tx.get(
          acceptanceLimitCollection.doc(legacyAcceptanceLimitId),
        );
        const legacyData = legacyAcceptanceLimitSnap.exists
          ? (legacyAcceptanceLimitSnap.data() || {})
          : {};
        if (cleanString(legacyData.providerId) === providerId
          && toMillis(legacyData.windowStartedAt) === acceptanceWindow) {
          acceptanceCount = Number(legacyData.count || 0);
        }
      }
    }
    if (!Number.isFinite(acceptanceCount) || acceptanceCount < 0 || acceptanceCount >= acceptanceLimit) {
      throw new HttpsError(
        'resource-exhausted',
        'Limite temporario de aceitacoes atingido. Tenta novamente mais tarde.',
      );
    }
    tx.set(acceptanceLimitRef, {
      providerId,
      idVersion: 'sha256-v1',
      windowStartedAt: Timestamp.fromMillis(acceptanceWindow),
      count: acceptanceCount + 1,
      expiresAt: Timestamp.fromMillis(acceptanceWindow + 24 * 60 * 60 * 1000),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    if (!invitedProvider) {
      tx.update(opportunityRef, {
        status: 'accepted',
        acceptedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    tx.update(pedidoRef, {
      prestadorId: providerId,
      providerAccessGranted: true,
      providerAccessGrantedTo: providerId,
      providerAccessGrantedAt: FieldValue.serverTimestamp(),
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
    tx.delete(dispatchRef);
  });
  await syncProviderActiveClients(database, providerId);
  return { ok: true, pedidoId: cleanPedidoId };
}

function mergePreferTarget(source = {}, target = {}) {
  const merged = { ...source, ...target };
  delete merged.mergedInto;
  delete merged.mergedAt;
  return merged;
}

async function syncPhoneIdentityCore({ database = db, auth, authAdmin = firebaseAuth }) {
  if (!auth || !auth.uid) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  const userRecord = await authAdmin.getUser(auth.uid);
  const phoneNumber = cleanString(userRecord.phoneNumber);
  if (!phoneNumber) throw new HttpsError('failed-precondition', 'Telefone ainda nao confirmado.');
  await requireAccountAllowsNewActivity({
    database,
    uid: auth.uid,
    message: 'Cancela primeiro o pedido de eliminacao para voltar a publicar o perfil.',
  });

  const now = FieldValue.serverTimestamp();
  const privateRef = database.collection('users_private').doc(auth.uid);
  const providerPublicRef = database.collection('provider_public').doc(auth.uid);
  const activePilotProvider = await pilotParticipantIsActive({
    database,
    uid: auth.uid,
    role: 'prestador',
  });
  await database.runTransaction(async (transaction) => {
    const [privateSnap, providerSnap] = await Promise.all([
      transaction.get(privateRef),
      transaction.get(providerPublicRef),
    ]);
    if (!accountAllowsNewWork(privateSnap.exists ? privateSnap.data() : {})) {
      throw new HttpsError(
        'failed-precondition',
        'Cancela primeiro o pedido de eliminacao para voltar a publicar o perfil.',
      );
    }
    transaction.set(privateRef, {
      uid: auth.uid,
      isAnonymous: false,
      phoneE164: phoneNumber,
      phoneVerified: true,
      phoneVerifiedAt: now,
      updatedAt: now,
    }, { merge: true });
    if (providerSnap.exists) {
      transaction.set(providerPublicRef, {
        isSearchable: activePilotProvider,
        trustSignals: { phoneConfirmed: true },
        updatedAt: now,
      }, { merge: true });
    }
  });
  return { ok: true, phoneVerified: true };
}

async function mergeAnonymousDataCore({
  database = db,
  auth,
  sourceIdToken,
  authAdmin = firebaseAuth,
}) {
  if (!auth || !auth.uid) throw new HttpsError('unauthenticated', 'Autenticacao obrigatoria.');
  const targetUser = await authAdmin.getUser(auth.uid);
  if (!targetUser.phoneNumber) {
    throw new HttpsError('failed-precondition', 'A conta de destino precisa de telefone confirmado.');
  }
  const token = cleanString(sourceIdToken);
  if (!token) throw new HttpsError('invalid-argument', 'Token da sessao temporaria em falta.');
  let sourceAuth;
  let completedTombstoneRetry = false;
  try {
    sourceAuth = await authAdmin.verifyIdToken(token, true);
  } catch (revokedOrDisabledError) {
    // `updateUser(disabled: true)` is the final side effect. If its response is
    // lost, the next call's revocation check can fail even though all durable
    // data work completed. A signature-validated token may resume only when a
    // completed tombstone already binds this exact source to this target.
    let decoded;
    try {
      decoded = await authAdmin.verifyIdToken(token, false);
    } catch (_) {
      throw revokedOrDisabledError;
    }
    const retrySourceUid = cleanString(decoded && decoded.uid);
    const retryTombstone = retrySourceUid
      ? await database.collection('account_merge_sources').doc(retrySourceUid).get()
      : null;
    const retryData = retryTombstone && retryTombstone.exists
      ? (retryTombstone.data() || {})
      : {};
    if (!retrySourceUid
      || !retryTombstone
      || !retryTombstone.exists
      || cleanString(retryData.targetUid) !== auth.uid
      || retryData.rekeyCompleted !== true
      || cleanString(retryData.status) !== 'complete') {
      throw revokedOrDisabledError;
    }
    sourceAuth = decoded;
    completedTombstoneRetry = true;
  }
  const sourceUid = cleanString(sourceAuth.uid);
  const provider = sourceAuth.firebase && sourceAuth.firebase.sign_in_provider;
  if (!sourceUid || sourceUid === auth.uid || provider !== 'anonymous') {
    throw new HttpsError('permission-denied', 'Sessao temporaria invalida.');
  }

  const targetUid = auth.uid;
  await requireAccountAllowsNewActivity({
    database,
    uid: targetUid,
    message: 'A conta de destino esta em processo de eliminacao.',
  });
  const sourcePrivateRef = database.collection('users_private').doc(sourceUid);
  const targetPrivateRef = database.collection('users_private').doc(targetUid);
  const tombstoneRef = database.collection('account_merge_sources').doc(sourceUid);
  const [sourcePrivateSnap, targetPrivateSnap] = await Promise.all([
    sourcePrivateRef.get(),
    targetPrivateRef.get(),
  ]);
  const sourcePrivate = sourcePrivateSnap.data() || {};
  if (sourcePrivate.mergedInto && sourcePrivate.mergedInto !== targetUid) {
    throw new HttpsError('already-exists', 'Sessao temporaria ja foi migrada.');
  }
  // Acquire the deterministic source lock before any copy/re-key operation.
  // A different phone account can therefore never race this merge and move
  // the same anonymous records to two destinations. The same target may
  // resume an interrupted in-progress merge idempotently.
  const tombstoneState = await database.runTransaction(async (transaction) => {
    const existing = await transaction.get(tombstoneRef);
    if (existing.exists) {
      const data = existing.data() || {};
      if (cleanString(data.targetUid) !== targetUid) {
        throw new HttpsError('already-exists', 'Sessao temporaria ja foi migrada.');
      }
      return data;
    }
    const pending = {
      sourceUid,
      targetUid,
      mergeVersion: 'anonymous-data-v3',
      status: 'in_progress',
      rekeyCompleted: false,
      startedAt: FieldValue.serverTimestamp(),
    };
    transaction.set(tombstoneRef, pending, { merge: false });
    return pending;
  });
  const alreadyRekeyed = tombstoneState.rekeyCompleted === true;
  if (completedTombstoneRetry && !alreadyRekeyed) {
    throw new HttpsError('failed-precondition', 'Migracao da sessao temporaria incompleta.');
  }
  const docPairs = [
    ['public_profiles', sourceUid, targetUid, 'uid'],
    ['provider_public', sourceUid, targetUid, 'uid'],
    ['provider_private', sourceUid, targetUid, 'providerId'],
    ['provider_dispatch_private', sourceUid, targetUid, 'providerId'],
    ['users', sourceUid, targetUid, 'uid'],
    ['prestadores', sourceUid, targetUid, 'uid'],
  ];

  if (!alreadyRekeyed) {
    const bulk = database.bulkWriter();
    const targetPrivate = targetPrivateSnap.data() || {};
    bulk.set(targetPrivateRef, {
      ...mergePreferTarget(sourcePrivate, targetPrivate),
      uid: targetUid,
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

    await bulk.close();

    // Copy and re-key in bounded pages. No completion marker is written until
    // every ownership record has moved successfully.
    await copySubcollectionDocuments({
      sourceCollection: sourcePrivateRef.collection('favorites'),
      targetCollection: targetPrivateRef.collection('favorites'),
    });
    await updateMatchingDocuments({
      database,
      collection: 'pedidos',
      field: 'clienteId',
      uid: sourceUid,
      update: (pedido) => {
        const legacyClientId = cleanString(pedido.clientId);
        const aliasesConflict = Boolean(
          legacyClientId && legacyClientId !== sourceUid,
        );
        const createsSelfDealing = cleanString(pedido.prestadorId) === targetUid;
        const mustRevokeGrant = aliasesConflict || createsSelfDealing;
        return {
          clienteId: targetUid,
          ...(legacyClientId === sourceUid ? { clientId: targetUid } : {}),
          ...(mustRevokeGrant ? {
            providerAccessGranted: false,
            providerAccessGrantedTo: null,
            providerAccessGrantedAt: null,
          } : {}),
        };
      },
    });
    await updateMatchingDocuments({
      database,
      collection: 'pedidos',
      field: 'clientId',
      uid: sourceUid,
      update: (pedido) => {
        const primaryClientId = cleanString(pedido.clienteId);
        const aliasesConflict = Boolean(
          primaryClientId && primaryClientId !== sourceUid,
        );
        const createsSelfDealing = cleanString(pedido.prestadorId) === targetUid;
        const mustRevokeGrant = aliasesConflict || createsSelfDealing;
        return {
          clientId: targetUid,
          ...(primaryClientId === sourceUid ? { clienteId: targetUid } : {}),
          ...(mustRevokeGrant ? {
            providerAccessGranted: false,
            providerAccessGrantedTo: null,
            providerAccessGrantedAt: null,
          } : {}),
        };
      },
    });
    await updateMatchingDocuments({
      database,
      collection: 'pedidos',
      field: 'prestadorId',
      uid: sourceUid,
      update: (pedido) => {
        const primaryClientId = cleanString(pedido.clienteId);
        const legacyClientId = cleanString(pedido.clientId);
        const aliasesConflict = Boolean(
          primaryClientId && legacyClientId && primaryClientId !== legacyClientId,
        );
        const clientId = aliasesConflict
          ? ''
          : (primaryClientId || legacyClientId);
        const lifecycle = getCanonicalPedidoStatus(pedido);
        const transfersAcceptedGrant = providerHasFullPedidoAccess(pedido, sourceUid)
          && ['aceito', 'em_andamento', 'aguarda_confirmacao_valor', 'concluido']
            .includes(lifecycle)
          && Boolean(clientId)
          && clientId !== sourceUid
          && clientId !== targetUid;
        return {
          prestadorId: targetUid,
          providerAccessGranted: transfersAcceptedGrant,
          providerAccessGrantedTo: transfersAcceptedGrant ? targetUid : null,
          providerAccessGrantedAt: transfersAcceptedGrant
            ? pedido.providerAccessGrantedAt
            : null,
        };
      },
    });
    await updateMatchingDocuments({
      database,
      collection: 'chats',
      field: 'clienteId',
      uid: sourceUid,
      update: { clienteId: targetUid },
    });
    await updateMatchingDocuments({
      database,
      collection: 'chats',
      field: 'prestadorId',
      uid: sourceUid,
      update: { prestadorId: targetUid },
    });

    // Mark the deterministic source lock complete only after every copy and
    // re-key operation has completed.
    await database.runTransaction(async (transaction) => {
      const existing = await transaction.get(tombstoneRef);
      if (!existing.exists || cleanString(existing.data().targetUid) !== targetUid) {
        throw new HttpsError('aborted', 'Bloqueio da migracao de conta foi alterado.');
      }
      transaction.update(tombstoneRef, {
        mergeVersion: 'anonymous-data-v3',
        status: 'complete',
        rekeyCompleted: true,
        completedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  const mergeAuditId = crypto
    .createHash('sha256')
    .update(`${sourceUid}\u0000${targetUid}`)
    .digest('hex');
  await database.collection('account_merge_audit').doc(mergeAuditId).set({
    sourceUid,
    targetUid,
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: false });

  // Once the durable tombstone exists, remove every copied source document.
  // recursiveDelete also removes favorites and any other nested private data.
  for (const sourceRef of [
    sourcePrivateRef,
    ...docPairs.map(([collection, sourceId]) => (
      database.collection(collection).doc(sourceId)
    )),
  ]) {
    await database.recursiveDelete(sourceRef);
  }

  await syncPhoneIdentityCore({ database, auth, authAdmin });
  await syncProviderActiveClients(database, targetUid);
  try {
    await authAdmin.updateUser(sourceUid, { disabled: true });
  } catch (error) {
    if (!error || error.code !== 'auth/user-not-found') throw error;
  }
  return { ok: true, sourceUid, targetUid, idempotent: alreadyRekeyed };
}

const KYC_CONSENT_VERSION = 'kyc-consent-2026-07-20';
const KYC_UPLOAD_WINDOW_MINUTES = 30;
const KYC_RETENTION_DAYS = 90;
const LEGAL_DOCUMENT_VERSION = 'legal-2026-07-20-pilot-v3';
const ACCOUNT_DELETION_GRACE_DAYS = 7;
const ACCOUNT_DELETION_LEASE_MS = 15 * 60 * 1000;
const ACCOUNT_DELETION_STORAGE_ROOTS = Object.freeze([
  'users',
  'prestadores',
  'kyc_pending',
  'profile_public',
  'portfolio',
  'stories',
  'temp',
  'kyc',
  'category_evidence',
]);

function requireVerifiedPhoneAuth(auth) {
  const uid = requireCallableUid(auth && auth.uid);
  if (!auth.token || !cleanString(auth.token.phone_number)) {
    throw new HttpsError('failed-precondition', 'Confirma o telefone antes de continuar.');
  }
  return uid;
}

function assertCurrentLegalConsent(consent) {
  if (!consent
    || cleanString(consent.version) !== LEGAL_DOCUMENT_VERSION
    || consent.termsAccepted !== true
    || consent.privacyAccepted !== true
    || consent.ageConfirmed !== true) {
    throw new HttpsError(
      'failed-precondition',
      'Aceita os Termos de Utilizacao e a Politica de Privacidade atuais.',
    );
  }
  return consent;
}

async function requireCurrentLegalConsent({ database = db, uid }) {
  const snapshot = await database.collection('users_private').doc(uid).get();
  const consent = snapshot.exists ? snapshot.data().legalConsent : null;
  return assertCurrentLegalConsent(consent);
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

function pilotParticipantIsActiveForRole(participant, role) {
  const roles = normalizedPilotRoles(participant && participant.roles);
  const city = normalizeSafetyText(participant && participant.city);
  return !!participant
    && participant.status === 'active'
    && roles.includes(role)
    && ['maputo', 'matola'].includes(city);
}

async function requirePilotParticipant({
  database = db,
  uid,
  role,
  allowEmulatorBypass = true,
}) {
  if (allowEmulatorBypass && !pilotAllowlistRequired()) {
    return { active: true, bypassed: true, roles: ['cliente', 'prestador'] };
  }
  const snapshot = await database.collection('pilot_participants').doc(uid).get();
  const participant = snapshot.exists ? snapshot.data() : null;
  const roles = normalizedPilotRoles(participant && participant.roles);
  if (!pilotParticipantIsActiveForRole(participant, role)) {
    throw new HttpsError(
      'permission-denied',
      'Esta conta ainda nao faz parte do piloto controlado. Contacta o suporte.',
    );
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
  const privateRef = database.collection('users_private').doc(uid);
  const auditRef = database.collection('legal_consent_audit').doc();
  await database.runTransaction(async (transaction) => {
    const userPrivate = await transaction.get(privateRef);
    if (!accountAllowsNewWork(userPrivate.exists ? userPrivate.data() : {})) {
      throw new HttpsError(
        'failed-precondition',
        'Cancela primeiro o pedido de eliminacao para atualizar os consentimentos.',
      );
    }
    transaction.set(privateRef, {
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
    transaction.create(auditRef, {
      uid,
      version,
      locale,
      termsAccepted: true,
      privacyAccepted: true,
      ageConfirmed: true,
      acceptedAt,
    });
  });
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
    const hasPedidoAccess = pedidoData
      && (cleanString(getClienteId(pedidoData)) === uid
        || providerHasFullPedidoAccess(pedidoData, uid));
    if (!hasPedidoAccess) {
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
  let financialRecordsComplete = 0;
  let financialRecordsIncomplete = 0;
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
    const finalValue = Number(data.earningsTotal ?? data.precoFinal ?? data.preco ?? 0);
    const hasProviderEarnings = data.earningsProvider !== null
      && data.earningsProvider !== undefined;
    const hasCommission = data.commissionPlatform !== null
      && data.commissionPlatform !== undefined;
    const providerEarnings = Number(data.earningsProvider);
    const commission = Number(data.commissionPlatform);
    if (Number.isFinite(finalValue) && finalValue > 0) gmvMzn += finalValue;
    const economicsTolerance = Math.max(0.01, Math.abs(finalValue) * 0.001);
    const hasAuthoritativeEconomics = Number.isFinite(finalValue)
      && finalValue > 0
      && hasProviderEarnings
      && hasCommission
      && Number.isFinite(providerEarnings)
      && providerEarnings >= 0
      && Number.isFinite(commission)
      && commission >= 0
      && Math.abs((providerEarnings + commission) - finalValue) <= economicsTolerance;
    if (hasAuthoritativeEconomics) {
      financialRecordsComplete += 1;
      providerEarningsMzn += providerEarnings;
      commissionDueMzn += commission;
    } else {
      financialRecordsIncomplete += 1;
    }
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
      financialRecordsComplete,
      financialRecordsIncomplete,
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
  const hasStatus = Object.prototype.hasOwnProperty.call(data, 'status');
  const hasEstado = Object.prototype.hasOwnProperty.call(data, 'estado');
  const status = hasStatus ? cleanString(data.status).toLowerCase() : '';
  const estado = hasEstado ? cleanString(data.estado).toLowerCase() : '';

  // A lifecycle conflict is never safe evidence that work has finished. This
  // intentionally fails closed so deletion cannot erase an account while one
  // of the authoritative aliases still says that the order is active.
  if (hasStatus && hasEstado && status !== estado) return true;
  const lifecycle = hasStatus ? status : estado;
  return !lifecycle || !ACCOUNT_TERMINAL_ORDER_STATES.has(lifecycle);
}

async function findActiveAccountOrders({ database = db, uid, pageSize = 200 }) {
  if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 500) {
    throw new Error('pageSize must be an integer between 1 and 500');
  }
  const active = new Map();
  for (const field of ['clienteId', 'clientId', 'prestadorId']) {
    let cursor = null;
    while (true) {
      let query = database.collection('pedidos')
        .where(field, '==', uid)
        .orderBy(FieldPath.documentId())
        .limit(pageSize);
      if (cursor) query = query.startAfter(cursor);
      const snapshot = await query.get();
      snapshot.docs.forEach((doc) => {
        if (isActiveAccountOrder(doc.data())) active.set(doc.id, doc);
      });
      if (snapshot.size < pageSize) break;
      cursor = snapshot.docs[snapshot.docs.length - 1];
    }
  }
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
  if (existing.exists && ['pending', 'pending_active_work', 'executing']
    .includes(cleanString(existing.data().status))) {
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

function accountDeletionStoragePrefixes(uid) {
  const ownerUid = cleanString(uid);
  if (!ownerUid) throw new Error('uid is required for storage cleanup');
  return ACCOUNT_DELETION_STORAGE_ROOTS.map((root) => `${root}/${ownerUid}/`);
}

function accountDeletionRequestCanExecute(request = {}, nowMillis = Date.now()) {
  const status = cleanString(request.status);
  if (!['pending', 'pending_active_work', 'executing'].includes(status)) return false;
  const executeAtMillis = toMillis(request.executeAt);
  if (!executeAtMillis || executeAtMillis > nowMillis) return false;
  return status !== 'executing' || toMillis(request.leaseUntil) <= nowMillis;
}

function pseudonymizeUidInValue(value, uid, pseudonym) {
  if (typeof value === 'string') {
    const replaced = value.split(uid).join(pseudonym);
    return { value: replaced, changed: replaced !== value };
  }
  if (Array.isArray(value)) {
    let changed = false;
    const next = value.map((item) => {
      const transformed = pseudonymizeUidInValue(item, uid, pseudonym);
      changed = changed || transformed.changed;
      return transformed.value;
    });
    return { value: changed ? next : value, changed };
  }
  if (!value || typeof value !== 'object' || typeof value.toMillis === 'function') {
    return { value, changed: false };
  }
  const prototype = Object.getPrototypeOf(value);
  if (prototype !== Object.prototype && prototype !== null) {
    return { value, changed: false };
  }
  let changed = false;
  const next = {};
  for (const [key, item] of Object.entries(value)) {
    const transformed = pseudonymizeUidInValue(item, uid, pseudonym);
    changed = changed || transformed.changed;
    next[key] = transformed.value;
  }
  return { value: changed ? next : value, changed };
}

async function pseudonymizeUidInAuditCollection({
  database,
  collection,
  uid,
  pseudonym,
  pageSize = 400,
}) {
  let cursor = null;
  let updated = 0;
  while (true) {
    let query = database.collection(collection)
      .orderBy(FieldPath.documentId())
      .limit(pageSize);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    if (snapshot.empty) break;
    const bulk = database.bulkWriter();
    for (const doc of snapshot.docs) {
      const transformed = pseudonymizeUidInValue(doc.data() || {}, uid, pseudonym);
      if (transformed.changed) {
        bulk.set(doc.ref, transformed.value, { merge: false });
        updated += 1;
      }
    }
    await bulk.close();
    cursor = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < pageSize) break;
  }
  return updated;
}

async function collectMergeSourceUidsForTarget({
  database,
  targetUid,
  pageSize = 400,
}) {
  const sourceUids = new Set();
  let cursor = null;
  while (true) {
    let query = database.collection('account_merge_sources')
      .where('targetUid', '==', targetUid)
      .orderBy(FieldPath.documentId())
      .limit(pageSize);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    if (snapshot.empty) break;
    snapshot.docs.forEach((doc) => {
      const sourceUid = cleanString((doc.data() || {}).sourceUid || doc.id);
      if (sourceUid && sourceUid !== targetUid) sourceUids.add(sourceUid);
    });
    cursor = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < pageSize) break;
  }
  return [...sourceUids];
}

async function copySubcollectionDocuments({
  sourceCollection,
  targetCollection,
  pageSize = 400,
}) {
  let cursor = null;
  let copied = 0;
  while (true) {
    let query = sourceCollection.orderBy(FieldPath.documentId()).limit(pageSize);
    if (cursor) query = query.startAfter(cursor);
    const snapshot = await query.get();
    if (snapshot.empty) break;
    const bulk = sourceCollection.firestore.bulkWriter();
    snapshot.docs.forEach((doc) => {
      bulk.set(targetCollection.doc(doc.id), doc.data(), { merge: true });
    });
    await bulk.close();
    copied += snapshot.size;
    cursor = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < pageSize) break;
  }
  return copied;
}

async function updateMatchingDocuments({
  database,
  collection,
  field,
  uid,
  update,
  pageSize = 400,
}) {
  let updated = 0;
  while (true) {
    const snapshot = await database.collection(collection)
      .where(field, '==', uid)
      .limit(pageSize)
      .get();
    if (snapshot.empty) break;
    const bulk = database.bulkWriter();
    for (const doc of snapshot.docs) {
      const patch = typeof update === 'function' ? update(doc.data() || {}, doc) : update;
      if (!patch || !Object.prototype.hasOwnProperty.call(patch, field) || patch[field] === uid) {
        throw new Error(`Paginated update must move ${collection}.${field} away from its source value.`);
      }
      bulk.update(doc.ref, patch);
    }
    await bulk.close();
    updated += snapshot.size;
    if (snapshot.size < pageSize) break;
  }
  return updated;
}

async function deleteMatchingDocuments({
  database,
  collection,
  field,
  uid,
  pageSize = 400,
}) {
  let deleted = 0;
  while (true) {
    const snapshot = await database.collection(collection)
      .where(field, '==', uid)
      .limit(pageSize)
      .get();
    if (snapshot.empty) break;
    for (let index = 0; index < snapshot.docs.length; index += 20) {
      const chunk = snapshot.docs.slice(index, index + 20);
      await Promise.all(chunk.map((doc) => database.recursiveDelete(doc.ref)));
    }
    deleted += snapshot.size;
    if (snapshot.size < pageSize) break;
  }
  return deleted;
}

async function removeUidFromArrayDocuments({
  database,
  collection,
  field,
  uid,
  pageSize = 400,
}) {
  let updated = 0;
  while (true) {
    const snapshot = await database.collection(collection)
      .where(field, 'array-contains', uid)
      .limit(pageSize)
      .get();
    if (snapshot.empty) break;
    const bulk = database.bulkWriter();
    snapshot.docs.forEach((doc) => {
      bulk.update(doc.ref, {
        [field]: FieldValue.arrayRemove(uid),
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
    await bulk.close();
    updated += snapshot.size;
    if (snapshot.size < pageSize) break;
  }
  return updated;
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
  const attemptStartedAtMillis = Date.now();
  const acquisition = await database.runTransaction(async (transaction) => {
    const request = await transaction.get(requestRef);
    if (!request.exists) return { acquired: false, reason: 'not_pending' };
    const requestData = request.data() || {};
    const status = cleanString(requestData.status);
    if (!['pending', 'pending_active_work', 'executing'].includes(status)) {
      return { acquired: false, reason: 'not_pending' };
    }
    const executeAtMillis = toMillis(requestData.executeAt);
    if (!executeAtMillis || executeAtMillis > attemptStartedAtMillis) {
      return { acquired: false, reason: 'grace_period' };
    }
    if (!accountDeletionRequestCanExecute(requestData, attemptStartedAtMillis)) {
      return { acquired: false, reason: 'already_executing' };
    }
    const previousAttempt = Number(requestData.attempt || 0);
    const attempt = (Number.isSafeInteger(previousAttempt) && previousAttempt >= 0
      ? previousAttempt
      : 0) + 1;
    transaction.set(requestRef, {
      status: 'executing',
      attempt,
      lastAttemptAt: FieldValue.serverTimestamp(),
      leaseUntil: Timestamp.fromMillis(attemptStartedAtMillis + ACCOUNT_DELETION_LEASE_MS),
      blockedReason: FieldValue.delete(),
      lastError: FieldValue.delete(),
      lastErrorAt: FieldValue.delete(),
      ...(requestData.startedAt ? {} : { startedAt: FieldValue.serverTimestamp() }),
    }, { merge: true });
    return {
      acquired: true,
      attempt,
      linkedSourceUidsCaptured: requestData.linkedSourceUidsCaptured === true,
      linkedSourceUids: Array.isArray(requestData.linkedSourceUids)
        ? requestData.linkedSourceUids.map(cleanString).filter(Boolean)
        : [],
    };
  });
  if (!acquisition.acquired) {
    return { ok: false, skipped: true, reason: acquisition.reason };
  }
  const pseudonym = accountDeletionPseudonym(uid);
  try {
    let linkedSourceUids = acquisition.linkedSourceUids;
    if (!acquisition.linkedSourceUidsCaptured) {
      linkedSourceUids = await collectMergeSourceUidsForTarget({ database, targetUid: uid });
      await requestRef.set({
        linkedSourceUids,
        linkedSourceUidsCaptured: true,
        linkedSourceUidsCapturedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    const identityUids = [...new Set([uid, ...linkedSourceUids])];
    const activeOrders = await findActiveAccountOrders({ database, uid });
    if (activeOrders.length > 0) {
      const retryAt = Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000);
      await requestRef.set({
        status: 'pending_active_work',
        executeAt: retryAt,
        leaseUntil: FieldValue.delete(),
        blockedReason: 'active_work',
        checkedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return { ok: false, skipped: true, reason: 'active_work', retryAtMillis: retryAt.toMillis() };
    }
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
    update: {
      prestadorId: pseudonym,
      providerAccessGranted: false,
      providerAccessGrantedTo: FieldValue.delete(),
      providerAccessGrantedAt: FieldValue.delete(),
      ...providerPrivateFields,
    },
  });
  counts.pedidosProviderGrant = await updateMatchingDocuments({
    database, collection: 'pedidos', field: 'providerAccessGrantedTo', uid,
    update: {
      providerAccessGranted: false,
      providerAccessGrantedTo: FieldValue.delete(),
      providerAccessGrantedAt: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    },
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

  // Anonymous sessions merged into this account are part of the same data
  // subject. The merge normally re-keys them, but deletion also removes any
  // legacy or interrupted residue defensively.
  for (const sourceUid of linkedSourceUids) {
    await updateMatchingDocuments({
      database, collection: 'pedidos', field: 'clienteId', uid: sourceUid,
      update: { clienteId: pseudonym, ...orderPrivateFields },
    });
    await updateMatchingDocuments({
      database, collection: 'pedidos', field: 'clientId', uid: sourceUid,
      update: { clientId: pseudonym, ...orderPrivateFields },
    });
    await updateMatchingDocuments({
      database, collection: 'pedidos', field: 'prestadorId', uid: sourceUid,
      update: {
        prestadorId: pseudonym,
        providerAccessGranted: false,
        providerAccessGrantedTo: FieldValue.delete(),
        providerAccessGrantedAt: FieldValue.delete(),
        ...providerPrivateFields,
      },
    });
    await updateMatchingDocuments({
      database, collection: 'pedidos', field: 'providerAccessGrantedTo', uid: sourceUid,
      update: {
        providerAccessGranted: false,
        providerAccessGrantedTo: FieldValue.delete(),
        providerAccessGrantedAt: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      },
    });
    for (const collection of ['payments', 'commission_payments', 'payment_ledger']) {
      for (const field of ['clienteId', 'prestadorId', 'uid']) {
        await updateMatchingDocuments({
          database, collection, field, uid: sourceUid,
          update: { [field]: pseudonym, updatedAt: FieldValue.serverTimestamp() },
        });
      }
    }
    for (const field of ['clienteId', 'prestadorId']) {
      await updateMatchingDocuments({
        database, collection: 'avaliacoes', field, uid: sourceUid,
        update: { [field]: pseudonym, comentario: FieldValue.delete() },
      });
    }
    await deleteMatchingDocuments({
      database, collection: 'chats', field: 'clienteId', uid: sourceUid,
    });
    await deleteMatchingDocuments({
      database, collection: 'chats', field: 'prestadorId', uid: sourceUid,
    });
    await deleteMatchingDocuments({
      database, collection: 'support_tickets', field: 'uid', uid: sourceUid,
    });
  }

  const keyedCollections = [
    'users_private',
    'public_profiles',
    'provider_private',
    'provider_public',
    'provider_dispatch_private',
    'prestadores',
    'users',
    'kyc_submissions',
    'kyc_upload_grants',
    'pilot_participants',
    'account_merge_sources',
  ];
  for (const identityUid of identityUids) {
    for (const collection of keyedCollections) {
      await database.recursiveDelete(database.collection(collection).doc(identityUid));
    }
  }
  counts.activeClientReferences = 0;
  counts.providerOpportunities = 0;
  counts.providerAcceptanceLimits = 0;
  counts.mergeSourcesBySource = 0;
  counts.mergeSourcesByTarget = 0;
  for (const identityUid of identityUids) {
    for (const [collection, field] of [
      ['provider_custom_service_requests', 'providerId'],
      ['provider_sensitive_category_requests', 'providerId'],
      ['category_approval_requests', 'providerId'],
      ['sensitiveCategoryRequests', 'providerId'],
      ['service_moderation_queue', 'requesterId'],
      ['stories', 'prestadorId'],
      ['stories', 'ownerId'],
      ['pedido_dispatch', 'targetPrestadorId'],
      ['handles', 'uid'],
      ['handles', 'previousOwnerUid'],
    ]) {
      await deleteMatchingDocuments({
        database, collection, field, uid: identityUid,
      });
    }
    counts.activeClientReferences += await removeUidFromArrayDocuments({
      database,
      collection: 'provider_dispatch_private',
      field: 'activeClientIds',
      uid: identityUid,
    });
    counts.providerOpportunities += await deleteMatchingDocuments({
      database,
      collection: 'provider_opportunities',
      field: 'providerId',
      uid: identityUid,
    });
    counts.providerAcceptanceLimits += await deleteMatchingDocuments({
      database,
      collection: 'provider_acceptance_limits',
      field: 'providerId',
      uid: identityUid,
    });
    counts.mergeSourcesBySource += await deleteMatchingDocuments({
      database,
      collection: 'account_merge_sources',
      field: 'sourceUid',
      uid: identityUid,
    });
    counts.mergeSourcesByTarget += await deleteMatchingDocuments({
      database,
      collection: 'account_merge_sources',
      field: 'targetUid',
      uid: identityUid,
    });
  }
  if (deleteStorage) {
    for (const identityUid of identityUids) {
      for (const prefix of accountDeletionStoragePrefixes(identityUid)) {
        await bucket.deleteFiles({ prefix, force: true });
      }
    }
  }
  for (const identityUid of identityUids) {
    counts.support += await deleteMatchingDocuments({
      database, collection: 'support_tickets', field: 'uid', uid: identityUid,
    });
  }
  counts.auditDocumentsPseudonymized = 0;
  for (const collection of [
    'legal_consent_audit',
    'account_merge_audit',
    'adminAuditLogs',
    'security_event_logs',
    'reports',
  ]) {
    for (const identityUid of identityUids) {
      counts.auditDocumentsPseudonymized += await pseudonymizeUidInAuditCollection({
        database,
        collection,
        uid: identityUid,
        pseudonym,
      });
    }
  }
  if (deleteAuth) {
    for (const identityUid of identityUids) {
      try {
        await authAdmin.deleteUser(identityUid);
      } catch (error) {
        if (error && error.code !== 'auth/user-not-found') throw error;
      }
    }
  }
  await database.collection('account_deletion_audit').doc(pseudonym.replace(':', '_')).set({
    pseudonym,
    completedAt: FieldValue.serverTimestamp(),
    attemptCount: acquisition.attempt,
    mergedSourceCount: linkedSourceUids.length,
    retainedTransactionalRecords: true,
    legalVersion: LEGAL_DOCUMENT_VERSION,
  });
  await requestRef.delete();
  return { ok: true, pseudonym, counts };
  } catch (error) {
    const lastError = safeText(
      error && error.message ? error.message : String(error),
      500,
    ) || 'account_deletion_failed';
    try {
      await requestRef.set({
        status: 'executing',
        attempt: acquisition.attempt,
        lastAttemptAt: FieldValue.serverTimestamp(),
        lastError,
        lastErrorAt: FieldValue.serverTimestamp(),
        leaseUntil: Timestamp.fromMillis(Date.now() - 1),
      }, { merge: true });
    } catch (stateError) {
      logger.error('[account-deletion] Falha ao guardar estado de retry.', {
        uid: maskIdentifier(uid),
        error: String(stateError && stateError.message ? stateError.message : stateError),
      });
    }
    throw error;
  }
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
  await requireAccountAllowsNewActivity({
    database,
    uid,
    message: 'A conta em eliminacao nao pode iniciar uma verificacao de identidade.',
  });
  const existing = await database.collection('kyc_submissions').doc(uid).get();
  const status = cleanString(existing.data() && existing.data().status);
  if (['pending_review', 'approved'].includes(status)) {
    throw new HttpsError('failed-precondition', 'Ja existe uma verificacao ativa.');
  }

  const submissionId = database.collection('kyc_upload_sessions').doc().id;
  const expiresAt = Timestamp.fromMillis(
    Date.now() + KYC_UPLOAD_WINDOW_MINUTES * 60 * 1000,
  );
  await database.runTransaction(async (transaction) => {
    const userPrivate = await transaction.get(database.collection('users_private').doc(uid));
    if (!accountAllowsNewWork(userPrivate.exists ? userPrivate.data() : {})) {
      throw new HttpsError(
        'failed-precondition',
        'A conta em eliminacao nao pode iniciar uma verificacao de identidade.',
      );
    }
    transaction.set(database.collection('kyc_upload_grants').doc(uid), {
      uid,
      submissionId,
      expiresAt,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  await setKycUploadClaim(uid, true);
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
  await requireAccountAllowsNewActivity({
    database,
    uid,
    message: 'A conta em eliminacao nao pode enviar documentos de identidade.',
  });
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
  await database.runTransaction(async (transaction) => {
    const [userPrivate, freshGrant, freshSubmission] = await Promise.all([
      transaction.get(database.collection('users_private').doc(uid)),
      transaction.get(grantRef),
      transaction.get(submissionRef),
    ]);
    if (!accountAllowsNewWork(userPrivate.exists ? userPrivate.data() : {})) {
      throw new HttpsError(
        'failed-precondition',
        'A conta em eliminacao nao pode enviar documentos de identidade.',
      );
    }
    const freshGrantData = freshGrant.exists ? (freshGrant.data() || {}) : {};
    if (!freshGrant.exists
      || cleanString(freshGrantData.submissionId) !== submissionId
      || toMillis(freshGrantData.expiresAt) <= Date.now()) {
      throw new HttpsError('permission-denied', 'A janela de envio KYC expirou.');
    }
    const freshStatus = cleanString(freshSubmission.data() && freshSubmission.data().status);
    if (['pending_review', 'approved'].includes(freshStatus)) {
      throw new HttpsError('failed-precondition', 'Ja existe uma verificacao ativa.');
    }
    transaction.set(submissionRef, {
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
    transaction.delete(grantRef);
    transaction.create(database.collection('security_event_logs').doc(), {
      actorUid: uid,
      action: 'kyc.submitted',
      targetType: 'kyc_submission',
      targetId: uid,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
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
  await database.runTransaction(async (transaction) => {
    const [userPrivate, freshSubmission] = await Promise.all([
      transaction.get(database.collection('users_private').doc(providerId)),
      transaction.get(submissionRef),
    ]);
    if (!accountAllowsNewWork(userPrivate.exists ? userPrivate.data() : {})) {
      throw new HttpsError('failed-precondition', 'A conta do prestador esta em processo de eliminacao.');
    }
    if (!freshSubmission.exists
      || cleanString(freshSubmission.data().status) !== 'pending_review') {
      throw new HttpsError('failed-precondition', 'Esta submissao ja foi decidida.');
    }
    transaction.set(submissionRef, {
      status: decision,
      reviewedBy: auth.uid,
      reviewedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      decisionReason: reason || null,
    }, { merge: true });
    if (decision === 'approved') {
      transaction.set(database.collection('provider_public').doc(providerId), {
        'trustSignals.identityConfirmed': true,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    await writeAdminAuditLog({
      database,
      batch: transaction,
      auth,
      action: `kyc.${decision}`,
      targetType: 'kyc_submission',
      targetId: providerId,
      beforeStatus,
      afterStatus: decision,
      reason,
    });
  });
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
  const uid = requireVerifiedPhoneAuth(auth);
  if (parsed.scope === 'temp') {
    if (parsed.ownerId !== uid) {
      throw new HttpsError('permission-denied', 'Sem acesso a este anexo temporario.');
    }
    await requirePilotParticipant({
      database,
      uid,
      role: 'cliente',
      allowEmulatorBypass: false,
    });
    return parsed;
  }
  const pedido = await database.collection('pedidos').doc(parsed.pedidoId).get();
  const data = pedido.exists ? (pedido.data() || {}) : null;
  const role = data && getClienteId(data) === uid
    ? 'cliente'
    : (data && providerHasFullPedidoAccess(data, uid) ? 'prestador' : '');
  if (!data || !role) {
    throw new HttpsError('permission-denied', 'Sem acesso aos anexos deste pedido.');
  }
  await requirePilotParticipant({
    database,
    uid,
    role,
    allowEmulatorBypass: false,
  });
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
  if (!authIsAdmin(auth)) {
    const uid = requireVerifiedPhoneAuth(auth);
    await requireAccountAllowsNewActivity({
      database,
      uid,
      message: 'A conta em eliminacao nao pode concluir novos carregamentos.',
    });
  }
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
    providerAccessGranted: false,
    providerAccessGrantedTo: null,
    providerAccessGrantedAt: null,
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

function normalizedPedidoContentRevision(value) {
  const revision = Number(value);
  return Number.isSafeInteger(revision) && revision >= 1 ? revision : 1;
}

function pedidoIsSecurelyEditableByClient(pedido, uid) {
  return getClienteId(pedido) === uid
    && getPedidoEstado(pedido) === 'criado'
    && !cleanString(pedido && pedido.prestadorId)
    && !(pedido && pedido.providerAccessGranted === true)
    && !cleanString(pedido && pedido.providerAccessGrantedTo)
    && !(pedido && pedido.providerAccessGrantedAt);
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

async function createSecurePedidoCore({ database = db, auth, data = {} }) {
  const uid = requireVerifiedPhoneAuth(auth);
  await requireAccountAllowsNewActivity({
    database,
    uid,
    message: 'Cancela primeiro o pedido de eliminacao para publicar um pedido.',
  });
  const requestedProviderId = cleanString(data.prestadorId);
  if (requestedProviderId === uid) {
    throw new HttpsError('invalid-argument', 'Nao podes convidar a tua propria conta.');
  }
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
    requestedProviderId,
  });
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
  try {
    await database.runTransaction(async (transaction) => {
      const clientPrivateSnap = await transaction.get(
        database.collection('users_private').doc(uid),
      );
      if (!accountAllowsNewWork(clientPrivateSnap.exists ? clientPrivateSnap.data() : {})) {
        throw new HttpsError(
          'failed-precondition',
          'Cancela primeiro o pedido de eliminacao para publicar um pedido.',
        );
      }
      if (requestedProviderId) {
        await readEligibleProviderForPedido({
          transaction,
          database,
          providerId: requestedProviderId,
          pedido: validationPayload,
          requireAvailableForNewWork: true,
          requireVerifiedPhoneProfile: true,
          nowMillis: Date.now(),
        });
      }
      transaction.create(ref, {
        ...payload,
        contentRevision: 1,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      if (moderationStatus === 'pending_review') {
        transaction.set(database.collection('service_moderation_queue').doc(ref.id), {
          pedidoId: ref.id,
          requesterId: uid,
          serviceId: policy.id,
          title: payload.customServiceName || payload.servicoNome,
          description: payload.customServiceDescription || payload.descricao || '',
          status: 'pending_review',
          contentRevision: 1,
          safetyMatches: safety.matches,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    });
  } catch (error) {
    await Promise.all(attachmentPaths.map((storagePath) => (
      firebaseStorage.bucket().file(storagePath).delete({ ignoreNotFound: true })
        .catch(() => undefined)
    )));
    throw error;
  }
  return { ok: true, pedidoId: ref.id, moderationStatus, contentRevision: 1 };
}

async function updateSecurePedidoCore({ database = db, auth, data = {} }) {
  const uid = requireVerifiedPhoneAuth(auth);
  await requireAccountAllowsNewActivity({
    database,
    uid,
    message: 'A conta em eliminacao nao pode alterar pedidos.',
  });
  const pedidoId = requirePedidoId(data);
  const currentRef = database.collection('pedidos').doc(pedidoId);
  const currentSnap = await currentRef.get();
  if (!currentSnap.exists) throw new HttpsError('not-found', 'Pedido nao encontrado.');
  const current = currentSnap.data() || {};
  if (!pedidoIsSecurelyEditableByClient(current, uid)) {
    throw new HttpsError('failed-precondition', 'Este pedido ja nao pode ser editado.');
  }
  const expectedContentRevision = normalizedPedidoContentRevision(current.contentRevision);
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
  const queueRef = database.collection('service_moderation_queue').doc(pedidoId);
  const contentRevision = await database.runTransaction(async (transaction) => {
    const [freshSnap, clientPrivateSnap] = await Promise.all([
      transaction.get(currentRef),
      transaction.get(database.collection('users_private').doc(uid)),
    ]);
    if (!accountAllowsNewWork(clientPrivateSnap.exists ? clientPrivateSnap.data() : {})) {
      throw new HttpsError('failed-precondition', 'A conta em eliminacao nao pode alterar pedidos.');
    }
    if (!freshSnap.exists) throw new HttpsError('not-found', 'Pedido nao encontrado.');
    const fresh = freshSnap.data() || {};
    if (!pedidoIsSecurelyEditableByClient(fresh, uid)) {
      throw new HttpsError('failed-precondition', 'Este pedido ja nao pode ser editado.');
    }
    const freshContentRevision = normalizedPedidoContentRevision(fresh.contentRevision);
    if (freshContentRevision !== expectedContentRevision) {
      throw new HttpsError(
        'failed-precondition',
        'O pedido foi alterado entretanto. Atualiza os dados antes de tentar novamente.',
      );
    }
    const nextContentRevision = freshContentRevision + 1;
    transaction.update(currentRef, {
      ...payload,
      contentRevision: nextContentRevision,
      updatedAt: FieldValue.serverTimestamp(),
      lastAuthoritativeFunction: 'pedidos_updateSecure',
    });
    if (moderationStatus === 'pending_review') {
      transaction.set(queueRef, {
        pedidoId,
        requesterId: uid,
        serviceId: policy.id,
        title: payload.customServiceName || payload.servicoNome,
        description: payload.customServiceDescription || payload.descricao || '',
        status: 'pending_review',
        contentRevision: nextContentRevision,
        safetyMatches: safety.matches,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    } else {
      transaction.delete(queueRef);
    }
    return nextContentRevision;
  });
  return { ok: true, pedidoId, moderationStatus, contentRevision };
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
  const queueRef = database.collection('service_moderation_queue').doc(pedidoId);
  const initialQueueSnap = await queueRef.get();
  if (!initialQueueSnap.exists) {
    throw new HttpsError('failed-precondition', 'Fila de moderacao inexistente para este pedido.');
  }
  const requestedRevision = data.contentRevision === undefined || data.contentRevision === null
    ? null
    : Number(data.contentRevision);
  if (requestedRevision !== null
    && (!Number.isSafeInteger(requestedRevision) || requestedRevision < 1)) {
    throw new HttpsError('invalid-argument', 'contentRevision invalida.');
  }
  const expectedContentRevision = requestedRevision
    || normalizedPedidoContentRevision((initialQueueSnap.data() || {}).contentRevision);
  await database.runTransaction(async (transaction) => {
    const pedidoSnap = await transaction.get(pedidoRef);
    const queueSnap = await transaction.get(queueRef);
    if (!pedidoSnap.exists) throw new HttpsError('not-found', 'Pedido nao encontrado.');
    if (!queueSnap.exists) {
      throw new HttpsError('failed-precondition', 'Fila de moderacao inexistente para este pedido.');
    }
    const pedido = pedidoSnap.data() || {};
    const queue = queueSnap.data() || {};
    if (pedido.moderationStatus !== 'pending_review' || queue.status !== 'pending_review') {
      throw new HttpsError('failed-precondition', 'Pedido nao esta pendente de moderacao.');
    }
    const pedidoRevision = normalizedPedidoContentRevision(pedido.contentRevision);
    const queueRevision = normalizedPedidoContentRevision(queue.contentRevision);
    if (pedidoRevision !== queueRevision || pedidoRevision !== expectedContentRevision) {
      throw new HttpsError(
        'failed-precondition',
        'O conteudo do pedido mudou. Reabre a revisao antes de decidir.',
      );
    }
    const requestedProviderId = cleanString(pedido.requestedProviderId);
    const nextStatus = decision === 'approved' && requestedProviderId
      ? 'aguarda_resposta_prestador'
      : (decision === 'approved' ? 'criado' : 'cancelado');
    if (decision === 'approved' && requestedProviderId) {
      if (pedidoIsSelfDealing(pedido, requestedProviderId)) {
        throw new HttpsError('permission-denied', 'Cliente e prestador devem ser contas diferentes.');
      }
      await readEligibleProviderForPedido({
        transaction,
        database,
        providerId: requestedProviderId,
        pedido: { ...pedido, moderationStatus: 'approved' },
        requireAvailableForNewWork: true,
        requireVerifiedPhoneProfile: true,
        nowMillis: Date.now(),
      });
    }
    transaction.update(pedidoRef, {
      moderationStatus: decision,
      moderationReviewedBy: auth.uid,
      moderationReviewedAt: FieldValue.serverTimestamp(),
      moderationDecisionReason: reason || null,
      prestadorId: decision === 'approved' && requestedProviderId ? requestedProviderId : null,
      providerAccessGranted: false,
      providerAccessGrantedTo: null,
      providerAccessGrantedAt: null,
      estado: nextStatus,
      status: nextStatus,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(queueRef, {
      status: decision,
      contentRevision: pedidoRevision,
      reviewedBy: auth.uid,
      reviewedAt: FieldValue.serverTimestamp(),
      decisionReason: reason || null,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    await writeAdminAuditLog({
      database,
      batch: transaction,
      auth,
      action: `service_request.${decision}`,
      targetType: 'pedido',
      targetId: pedidoId,
      beforeStatus: 'pending_review',
      afterStatus: decision,
      reason,
      metadata: { contentRevision: pedidoRevision },
    });
  });
  return {
    ok: true,
    pedidoId,
    moderationStatus: decision,
    contentRevision: expectedContentRevision,
  };
}

function providerApprovalIsActive(data, nowMillis = Date.now()) {
  if (!data || data.status !== 'approved') return false;
  if (!data.expiresAt) return true;
  return typeof data.expiresAt.toMillis === 'function' && data.expiresAt.toMillis() > nowMillis;
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
  await requireAccountAllowsNewActivity({
    database,
    uid,
    message: 'Cancela primeiro o pedido de eliminacao para publicar servicos.',
  });
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
  const pendingCustomWrites = [];
  for (const custom of customServices) {
    if (custom.trustSafetyDecision === 'block') continue;
    const requestRef = database.collection('provider_custom_service_requests').doc(`${uid}_${custom.id}`);
    const request = await requestRef.get();
    if (request.exists && request.data().status === 'approved') {
      approvedCustom.push({ ...custom, trustSafetyDecision: 'approved' });
    } else {
      pendingCustomIds.push(custom.id);
      pendingCustomWrites.push([requestRef, {
        providerId: uid,
        serviceId: custom.id,
        service: custom,
        status: 'pending_review',
        createdAt: request.exists ? (request.data().createdAt || FieldValue.serverTimestamp()) : FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }]);
    }
  }

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
  await database.runTransaction(async (transaction) => {
    const userPrivate = await transaction.get(database.collection('users_private').doc(uid));
    if (!accountAllowsNewWork(userPrivate.exists ? userPrivate.data() : {})) {
      throw new HttpsError(
        'failed-precondition',
        'Cancela primeiro o pedido de eliminacao para publicar servicos.',
      );
    }
    pendingCustomWrites.forEach(([ref, payload]) => {
      transaction.set(ref, payload, { merge: true });
    });
    transaction.set(database.collection('provider_public').doc(uid), {
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
    transaction.set(database.collection('provider_dispatch_private').doc(uid), {
      providerId: uid,
      servicos: serviceIds,
      servicosNomes: serviceNames,
      updatedAt: now,
    }, { merge: true });
    transaction.set(database.collection('provider_private').doc(uid), {
      providerId: uid,
      selectedServiceIds: requestedIds,
      pendingSensitiveServiceIds: pendingSensitiveIds,
      selectedCustomServiceIds: customServices.map((service) => service.id),
      pendingCustomServiceIds: pendingCustomIds,
      serviceSelectionUpdatedAt: now,
    }, { merge: true });
  });
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
  await requireAccountAllowsNewActivity({
    database,
    uid,
    message: 'A conta em eliminacao nao pode submeter novas aprovacoes.',
  });
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
  await database.runTransaction(async (transaction) => {
    const [userPrivate, freshRequest] = await Promise.all([
      transaction.get(database.collection('users_private').doc(uid)),
      transaction.get(ref),
    ]);
    if (!accountAllowsNewWork(userPrivate.exists ? userPrivate.data() : {})) {
      throw new HttpsError(
        'failed-precondition',
        'A conta em eliminacao nao pode submeter novas aprovacoes.',
      );
    }
    if (freshRequest.exists && freshRequest.data().status === 'approved') {
      throw new HttpsError('failed-precondition', 'Esta categoria ja esta aprovada.');
    }
    transaction.set(ref, {
      providerId: uid,
      categoryId,
      categoryName: safeText(requirementData.categoryName || categoryId, 160),
      status: 'pending_review',
      evidenceTypes,
      evidenceText: evidenceText || null,
      portfolioUrls,
      documentRefs,
      createdAt: freshRequest.exists ? (freshRequest.data().createdAt || now) : now,
      updatedAt: now,
      submittedAt: now,
      reviewedBy: FieldValue.delete(),
      reviewedAt: FieldValue.delete(),
      decisionReason: FieldValue.delete(),
    }, { merge: true });
  });
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
  await database.runTransaction(async (transaction) => {
    const [userPrivate, freshRequest] = await Promise.all([
      transaction.get(database.collection('users_private').doc(providerId)),
      transaction.get(ref),
    ]);
    if (!accountAllowsNewWork(userPrivate.exists ? userPrivate.data() : {})) {
      throw new HttpsError('failed-precondition', 'A conta do prestador esta em processo de eliminacao.');
    }
    if (!freshRequest.exists || cleanString(freshRequest.data().status) !== 'pending_review') {
      throw new HttpsError('failed-precondition', 'Pedido ja decidido.');
    }
    transaction.update(ref, {
      status: decision,
      reviewedBy: auth.uid,
      reviewedAt: FieldValue.serverTimestamp(),
      decisionReason: reason || null,
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (decision === 'approved' && selected.has(service.id)) {
      const approvedService = { ...service, trustSafetyDecision: 'approved' };
      transaction.set(database.collection('provider_public').doc(providerId), {
        servicos: FieldValue.arrayUnion(service.id),
        categories: FieldValue.arrayUnion(service.id),
        servicosNomes: FieldValue.arrayUnion(service.title),
        customServices: FieldValue.arrayUnion(approvedService),
        customServiceNames: FieldValue.arrayUnion(service.title),
        customServiceSearchTerms: FieldValue.arrayUnion(...service.normalizedSearchTerms),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      transaction.set(database.collection('provider_dispatch_private').doc(providerId), {
        servicos: FieldValue.arrayUnion(service.id),
        servicosNomes: FieldValue.arrayUnion(service.title),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    await writeAdminAuditLog({
      database,
      batch: transaction,
      auth,
      action: `custom_service.${decision}`,
      targetType: 'provider_custom_service',
      targetId: requestId,
      beforeStatus: 'pending_review',
      afterStatus: decision,
      reason,
    });
  });
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

function requiredCommissionRate(name) {
  const raw = cleanString(getEnv(name));
  const rate = raw ? normalizedRate(raw, null) : null;
  if (rate === null) {
    throw new HttpsError(
      'failed-precondition',
      `${name} deve ser configurada explicitamente antes de cobrar comissao.`,
    );
  }
  return rate;
}

function authoritativeDigitalPaymentMatches(payment, {
  pedidoId,
  clienteId,
  prestadorId,
  amount,
  currency,
}) {
  if (!payment) return false;
  const paymentAmount = Number(payment.amount);
  const feeAmount = Number(payment.feeAmount);
  return cleanString(payment.status).toLowerCase() === 'succeeded'
    && cleanString(payment.pedidoId) === pedidoId
    && cleanString(payment.clienteId) === clienteId
    && cleanString(payment.prestadorId) === prestadorId
    && Number.isInteger(paymentAmount)
    && paymentAmount === amount
    && Number.isInteger(feeAmount)
    && feeAmount >= 0
    && feeAmount <= paymentAmount
    && cleanString(payment.currency).toLowerCase() === cleanString(currency).toLowerCase();
}

function calculatePedidoEconomics(finalValue, {
  commissionRate = requiredCommissionRate('DEFAULT_DIGITAL_COMMISSION_RATE'),
  commissionCap = null,
  currency = cleanString(getEnv('DEFAULT_CURRENCY_CODE', 'MZN')).toUpperCase(),
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
  const normalizedCurrency = cleanString(currency).toUpperCase();
  if (!/^[A-Z]{3}$/.test(normalizedCurrency)) {
    throw new HttpsError('failed-precondition', 'Moeda autoritativa invalida.');
  }

  return {
    precoFinal: value,
    preco: value,
    commissionRate: rate,
    commissionPlatform,
    earningsProvider,
    earningsTotal: value,
    currency: normalizedCurrency,
  };
}

function cashCommissionPolicy({ completedJobsCount = 0 } = {}) {
  const freeJobs = Math.max(0, Math.floor(Number(getEnv('COMMISSION_FREE_FIRST_JOBS', '2')) || 2));
  const completed = Math.max(0, Math.floor(Number(completedJobsCount) || 0));
  const configuredRate = requiredCommissionRate('DEFAULT_CASH_COMMISSION_RATE');
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

const PEDIDO_ACTION_SPECS = Object.freeze({
  provider_submit_quote: Object.freeze({
    role: 'prestador',
    fields: Object.freeze(['valorMin', 'valorMax', 'mensagem', 'validadeMinutos']),
  }),
  client_accept_quote: Object.freeze({ role: 'cliente', fields: Object.freeze([]) }),
  client_reject_quote: Object.freeze({ role: 'cliente', fields: Object.freeze([]) }),
  client_invite_provider: Object.freeze({
    role: 'cliente',
    fields: Object.freeze(['prestadorId']),
  }),
  client_replace_invited_provider: Object.freeze({
    role: 'cliente',
    fields: Object.freeze(['prestadorId']),
  }),
  provider_decline_invite: Object.freeze({ role: 'prestador', fields: Object.freeze([]) }),
  provider_start_service: Object.freeze({ role: 'prestador', fields: Object.freeze([]) }),
  client_reject_final_value: Object.freeze({
    role: 'cliente',
    fields: Object.freeze(['motivo']),
  }),
  client_cancel: Object.freeze({
    role: 'cliente',
    fields: Object.freeze(['motivo', 'motivoDetalhe']),
  }),
  provider_cancel: Object.freeze({
    role: 'prestador',
    fields: Object.freeze(['motivo', 'motivoDetalhe']),
  }),
  client_report_no_show: Object.freeze({
    role: 'cliente',
    fields: Object.freeze(['motivo']),
  }),
  provider_report_no_show: Object.freeze({
    role: 'prestador',
    fields: Object.freeze(['motivo']),
  }),
});

const VALID_PEDIDO_ACTION_STATES = new Set([
  'criado',
  'aguarda_resposta_prestador',
  'aguarda_resposta_cliente',
  'aceito',
  'em_andamento',
  'aguarda_confirmacao_valor',
  'concluido',
  'cancelado',
]);

function strictPedidoActionText(value, {
  field,
  maxLength,
  required = false,
} = {}) {
  if (value === undefined || value === null) {
    if (required) throw new HttpsError('invalid-argument', `${field} obrigatorio.`);
    return '';
  }
  if (typeof value !== 'string' || /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/.test(value)) {
    throw new HttpsError('invalid-argument', `${field} invalido.`);
  }
  const text = value.replace(/\s+/g, ' ').trim();
  if ((required && !text) || text.length > maxLength) {
    throw new HttpsError('invalid-argument', `${field} invalido.`);
  }
  return text;
}

function strictPedidoDocumentId(value, field = 'pedidoId') {
  const documentId = strictPedidoActionText(value, {
    field,
    maxLength: 128,
    required: true,
  });
  if (documentId === '.' || documentId === '..' || documentId.includes('/')) {
    throw new HttpsError('invalid-argument', `${field} invalido.`);
  }
  return documentId;
}

function strictPedidoActionMoney(value, field) {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new HttpsError('invalid-argument', `${field} invalido.`);
  }
  const rounded = Math.round(value * 100) / 100;
  if (rounded <= 0 || rounded > 100000000 || Math.abs(value - rounded) > 0.000001) {
    throw new HttpsError('invalid-argument', `${field} invalido.`);
  }
  return rounded;
}

function parsePedidoActionInput(data = {}) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    throw new HttpsError('invalid-argument', 'Pedido de acao invalido.');
  }
  const action = strictPedidoActionText(data.action, {
    field: 'action',
    maxLength: 80,
    required: true,
  });
  const spec = PEDIDO_ACTION_SPECS[action];
  if (!spec) throw new HttpsError('invalid-argument', 'action invalida.');

  const allowedFields = new Set(['action', 'pedidoId', ...spec.fields]);
  const forgedFields = Object.keys(data).filter((field) => !allowedFields.has(field));
  if (forgedFields.length > 0) {
    throw new HttpsError(
      'invalid-argument',
      `Campos nao permitidos para ${action}: ${forgedFields.sort().join(', ')}.`,
    );
  }

  const input = {
    action,
    role: spec.role,
    pedidoId: strictPedidoDocumentId(data.pedidoId),
  };
  if (action === 'provider_submit_quote') {
    input.valorMin = strictPedidoActionMoney(data.valorMin, 'valorMin');
    input.valorMax = strictPedidoActionMoney(data.valorMax, 'valorMax');
    if (input.valorMax < input.valorMin) {
      throw new HttpsError('invalid-argument', 'valorMax deve ser maior ou igual a valorMin.');
    }
    input.mensagem = strictPedidoActionText(data.mensagem, {
      field: 'mensagem',
      maxLength: 500,
    });
    const validadeMinutos = data.validadeMinutos === undefined
      ? 1440
      : data.validadeMinutos;
    if (!Number.isInteger(validadeMinutos)
      || validadeMinutos < 15
      || validadeMinutos > 10080) {
      throw new HttpsError('invalid-argument', 'validadeMinutos invalido.');
    }
    input.validadeMinutos = validadeMinutos;
  }
  if (['client_invite_provider', 'client_replace_invited_provider'].includes(action)) {
    input.prestadorId = strictPedidoDocumentId(data.prestadorId, 'prestadorId');
  }
  if (['client_reject_final_value', 'client_report_no_show', 'provider_report_no_show'].includes(action)) {
    input.motivo = strictPedidoActionText(data.motivo, {
      field: 'motivo',
      maxLength: 500,
    });
  }
  if (['client_cancel', 'provider_cancel'].includes(action)) {
    input.motivo = strictPedidoActionText(data.motivo, {
      field: 'motivo',
      maxLength: 160,
      required: true,
    });
    input.motivoDetalhe = strictPedidoActionText(data.motivoDetalhe, {
      field: 'motivoDetalhe',
      maxLength: 500,
    });
  }
  return input;
}

function authoritativePedidoActionState(pedido) {
  const status = cleanString(pedido && pedido.status).toLowerCase();
  const estado = cleanString(pedido && pedido.estado).toLowerCase();
  if (status && estado && status !== estado) {
    throw new HttpsError('failed-precondition', 'Estado inconsistente; contacta o suporte.');
  }
  const state = status || estado;
  if (!VALID_PEDIDO_ACTION_STATES.has(state)) {
    throw new HttpsError('failed-precondition', 'Estado do pedido invalido.');
  }
  return state;
}

function assertPedidoActionState(action, state, allowedStates) {
  if (!allowedStates.includes(state)) {
    throw new HttpsError(
      'failed-precondition',
      `A acao ${action} nao e permitida no estado ${state}.`,
    );
  }
}

function assertPedidoActionOwner({ pedido, uid, role }) {
  const ownsPedido = role === 'cliente'
    ? cleanString(getClienteId(pedido)) === uid
    : cleanString(pedido && pedido.prestadorId) === uid;
  if (!ownsPedido) {
    throw new HttpsError('permission-denied', 'Sem permissao para executar esta acao no pedido.');
  }
}

function pedidoActionResetPatch() {
  return {
    prestadorId: null,
    providerAccessGranted: false,
    providerAccessGrantedTo: null,
    providerAccessGrantedAt: null,
    valorMinEstimadoPrestador: null,
    valorMaxEstimadoPrestador: null,
    mensagemPropostaPrestador: null,
    statusProposta: 'nenhuma',
    propostaExpiresAt: null,
    statusConfirmacaoValor: 'nenhum',
    precoPropostoPrestador: null,
    precoFinal: null,
    preco: null,
    commissionRate: null,
    commissionPlatform: null,
    earningsProvider: null,
    earningsTotal: null,
    concluidoEm: null,
    completedAt: null,
    completedBy: null,
    canceladoPor: null,
    motivoCancelamento: null,
    motivoCancelamentoDetalhe: null,
    tipoReembolso: null,
  };
}

function pedidoHasSettledDigitalPayment(pedido) {
  const method = cleanString(pedido && pedido.tipoPagamento).toLowerCase();
  const status = cleanString(pedido && pedido.paymentStatus).toLowerCase();
  return !['', 'dinheiro', 'cash'].includes(method) && ['paid', 'succeeded'].includes(status);
}

function accountAllowsNewWork(userPrivate) {
  const status = cleanString(userPrivate && userPrivate.accountStatus).toLowerCase();
  return ![
    'deletion_pending',
    'disabled',
    'deleted',
    'suspended',
    'inactive',
    'blocked',
  ].includes(status);
}

async function requireAccountAllowsNewActivity({
  database = db,
  uid,
  message = 'Esta conta nao pode iniciar novas operacoes.',
}) {
  const snapshot = await database.collection('users_private').doc(uid).get();
  const userPrivate = snapshot.exists ? (snapshot.data() || {}) : {};
  if (!accountAllowsNewWork(userPrivate)) {
    throw new HttpsError('failed-precondition', message);
  }
  return userPrivate;
}

async function readEligibleProviderForPedido({
  transaction,
  database,
  providerId,
  pedido,
  requireAvailableForNewWork,
  requireOnlineForNewWork = false,
  requireVerifiedPhoneProfile = false,
  nowMillis = Date.now(),
}) {
  const publicSnap = await transaction.get(database.collection('provider_public').doc(providerId));
  if (!publicSnap.exists) {
    throw new HttpsError('failed-precondition', 'Perfil de prestador inexistente.');
  }
  const provider = publicSnap.data() || {};
  if (provider.isSearchable !== true || !providerMatchesPedido(provider, pedido)) {
    throw new HttpsError('failed-precondition', 'Prestador nao elegivel para este pedido.');
  }

  const participantSnap = await transaction.get(
    database.collection('pilot_participants').doc(providerId),
  );
  if (!participantSnap.exists
    || !pilotParticipantIsActiveForRole(participantSnap.data(), 'prestador')) {
    throw new HttpsError('permission-denied', 'Prestador fora da coorte ativa do piloto.');
  }

  const userPrivateSnap = await transaction.get(
    database.collection('users_private').doc(providerId),
  );
  const userPrivate = userPrivateSnap.exists ? (userPrivateSnap.data() || {}) : {};
  if (requireVerifiedPhoneProfile && userPrivate.phoneVerified !== true) {
    throw new HttpsError('failed-precondition', 'O prestador precisa de telefone confirmado.');
  }
  assertCurrentLegalConsent(userPrivate.legalConsent);
  if (!accountAllowsNewWork(userPrivate)) {
    throw new HttpsError('failed-precondition', 'A conta do prestador nao aceita novos trabalhos.');
  }

  if (pedido.categoryApprovalRequired === true) {
    const requirementId = cleanString(pedido.categoryRequirementId || pedido.servicoId);
    if (!requirementId) {
      throw new HttpsError('failed-precondition', 'Categoria sensivel sem requisito autoritativo.');
    }
    const approvalSnap = await transaction.get(
      database.collection('provider_private').doc(providerId)
        .collection('categoryApprovals').doc(requirementId),
    );
    if (!approvalSnap.exists || !providerApprovalIsActive(approvalSnap.data(), nowMillis)) {
      throw new HttpsError('failed-precondition', 'A aprovacao desta categoria nao esta ativa.');
    }
  }

  let privateState = {};
  let dispatchState = {};
  if (requireAvailableForNewWork) {
    const privateSnap = await transaction.get(
      database.collection('provider_private').doc(providerId),
    );
    const dispatchSnap = await transaction.get(
      database.collection('provider_dispatch_private').doc(providerId),
    );
    privateState = privateSnap.exists ? (privateSnap.data() || {}) : {};
    dispatchState = dispatchSnap.exists ? (dispatchSnap.data() || {}) : {};
    if (cleanString(privateState.financialStatus) === 'suspended_new_jobs'
      || dispatchState.acceptingNewJobs === false
      || dispatchState.acceptingRequests === false) {
      throw new HttpsError(
        'failed-precondition',
        'O prestador nao pode receber novos pedidos neste momento.',
      );
    }
    if (requireOnlineForNewWork && dispatchState.isOnline !== true) {
      throw new HttpsError(
        'failed-precondition',
        'Fica online para aceitar esta oportunidade.',
      );
    }
  }
  return {
    provider,
    participant: participantSnap.data() || {},
    userPrivate,
    privateState,
    dispatchState,
  };
}

function pedidoIsApprovedForWork(pedido) {
  return cleanString(pedido && (pedido.moderationStatus || 'approved')) === 'approved';
}

function pedidoIsSelfDealing(pedido, providerId = null) {
  const clientId = cleanString(getClienteId(pedido));
  const assignedProviderId = cleanString(providerId || (pedido && pedido.prestadorId));
  return !!clientId && !!assignedProviderId && clientId === assignedProviderId;
}

function providerHasFullPedidoAccess(pedido, providerId) {
  const uid = cleanString(providerId);
  return !!uid
    && cleanString(pedido && pedido.prestadorId) === uid
    && pedido && pedido.providerAccessGranted === true
    && cleanString(pedido && pedido.providerAccessGrantedTo) === uid
    && !!(pedido && pedido.providerAccessGrantedAt)
    && typeof pedido.providerAccessGrantedAt.toMillis === 'function'
    && pedido.providerAccessGrantedAt.toMillis() > 0;
}

function pedidoRequiresAcceptedQuote(pedido) {
  return cleanString(pedido && pedido.tipoPreco).toLowerCase() === 'por_orcamento'
    || cleanString(pedido && pedido.modo).toUpperCase() === 'POR_PROPOSTA';
}

function pedidoHasAcceptedQuote(pedido) {
  const min = Number(pedido && pedido.valorMinEstimadoPrestador);
  const max = Number(pedido && pedido.valorMaxEstimadoPrestador);
  return cleanString(pedido && pedido.statusProposta) === 'aceita_cliente'
    && Number.isFinite(min)
    && min > 0
    && Number.isFinite(max)
    && max >= min;
}

async function assertNoActiveDigitalPayment({ transaction, database, pedido }) {
  const method = cleanString(pedido && pedido.tipoPagamento).toLowerCase();
  if (['', 'dinheiro', 'cash'].includes(method)) return;
  const paymentIntentId = cleanString(pedido && pedido.paymentIntentId);
  const pedidoStatus = cleanString(pedido && pedido.paymentStatus).toLowerCase();
  if (!paymentIntentId) {
    if (['', 'canceled', 'cancelled'].includes(pedidoStatus)) return;
    throw new HttpsError(
      'failed-precondition',
      'O estado do pagamento digital precisa de revisao pelo suporte.',
    );
  }
  const paymentSnap = await transaction.get(database.collection('payments').doc(paymentIntentId));
  const paymentStatus = paymentSnap.exists
    ? cleanString(paymentSnap.data().status).toLowerCase()
    : '';
  if (['canceled', 'cancelled'].includes(pedidoStatus)
    && ['canceled', 'cancelled'].includes(paymentStatus)) return;
  throw new HttpsError(
    'failed-precondition',
    'Existe um pagamento digital ativo; contacta o suporte antes de alterar o pedido.',
  );
}

async function applyPedidoActionSecureCore({
  database = db,
  auth,
  data = {},
  now = Timestamp.now(),
}) {
  const uid = requireVerifiedPhoneAuth(auth);
  const input = parsePedidoActionInput(data);
  await requireCurrentLegalConsent({ database, uid });
  await requirePilotParticipant({
    database,
    uid,
    role: input.role,
    allowEmulatorBypass: false,
  });
  if (['client_invite_provider', 'client_replace_invited_provider'].includes(input.action)) {
    if (input.prestadorId === uid) {
      throw new HttpsError('invalid-argument', 'Nao podes convidar a tua propria conta.');
    }
    await requirePilotParticipant({
      database,
      uid: input.prestadorId,
      role: 'prestador',
      allowEmulatorBypass: false,
    });
  }

  const pedidoRef = database.collection('pedidos').doc(input.pedidoId);
  let previousStatus = '';
  let nextStatus = '';
  await database.runTransaction(async (transaction) => {
    const pedidoSnap = await transaction.get(pedidoRef);
    if (!pedidoSnap.exists) throw new HttpsError('not-found', 'Pedido nao encontrado.');
    const pedido = pedidoSnap.data() || {};
    const state = authoritativePedidoActionState(pedido);
    previousStatus = state;
    const nowMillis = now && typeof now.toMillis === 'function' ? now.toMillis() : Date.now();
    const actorUserSnap = await transaction.get(database.collection('users_private').doc(uid));
    const actorUser = actorUserSnap.exists ? (actorUserSnap.data() || {}) : {};
    assertCurrentLegalConsent(actorUser.legalConsent);
    const actorParticipantSnap = await transaction.get(
      database.collection('pilot_participants').doc(uid),
    );
    if (!actorParticipantSnap.exists
      || !pilotParticipantIsActiveForRole(actorParticipantSnap.data(), input.role)) {
      throw new HttpsError('permission-denied', 'A conta deixou de pertencer a esta coorte do piloto.');
    }
    const newRelationshipActions = [
      'provider_submit_quote',
      'client_accept_quote',
      'client_invite_provider',
      'client_replace_invited_provider',
    ];
    if (newRelationshipActions.includes(input.action) && !accountAllowsNewWork(actorUser)) {
      throw new HttpsError('failed-precondition', 'A conta nao pode iniciar uma nova relacao de trabalho.');
    }
    const workProgressActions = [
      ...newRelationshipActions,
      'provider_start_service',
    ];
    if (workProgressActions.includes(input.action) && !pedidoIsApprovedForWork(pedido)) {
      throw new HttpsError('failed-precondition', 'O pedido ainda nao foi aprovado por Trust & Safety.');
    }
    const selfDealingSensitiveActions = [
      'provider_submit_quote',
      'client_accept_quote',
      'provider_start_service',
      'client_reject_final_value',
      'client_report_no_show',
      'provider_report_no_show',
    ];
    if (selfDealingSensitiveActions.includes(input.action) && pedidoIsSelfDealing(pedido)) {
      throw new HttpsError('permission-denied', 'Cliente e prestador devem ser contas diferentes.');
    }
    if (['client_report_no_show', 'provider_report_no_show'].includes(input.action)
      && !envFlagEnabled('ENABLE_NO_SHOW_REPORTING', false)) {
      throw new HttpsError('failed-precondition', 'O reporte de no-show ainda nao esta ativo no piloto.');
    }
    if ([
      'provider_submit_quote',
      'client_reject_quote',
      'client_reject_final_value',
      'client_cancel',
      'provider_cancel',
    ].includes(input.action)) {
      await assertNoActiveDigitalPayment({ transaction, database, pedido });
    }
    const commonPatch = {
      updatedAt: FieldValue.serverTimestamp(),
      lastAuthoritativeFunction: 'pedidos_applyActionSecure',
    };
    let patch;
    let event;
    let description;

    switch (input.action) {
      case 'provider_submit_quote': {
        assertPedidoActionState(input.action, state, [
          'criado',
          'aguarda_resposta_prestador',
        ]);
        if (!pedidoRequiresAcceptedQuote(pedido)) {
          throw new HttpsError(
            'failed-precondition',
            'Este pedido nao usa o fluxo de orcamento.',
          );
        }
        if (cleanString(getClienteId(pedido)) === uid) {
          throw new HttpsError('permission-denied', 'Nao podes apresentar proposta ao teu proprio pedido.');
        }
        const assignedProviderId = cleanString(pedido.prestadorId);
        if ((state === 'criado' && assignedProviderId)
          || (state !== 'criado' && assignedProviderId !== uid)) {
          throw new HttpsError('permission-denied', 'Pedido atribuido a outro prestador.');
        }
        await readEligibleProviderForPedido({
          transaction,
          database,
          providerId: uid,
          pedido,
          requireAvailableForNewWork: true,
          nowMillis,
        });
        nextStatus = 'aguarda_resposta_cliente';
        patch = {
          ...pedidoActionResetPatch(),
          prestadorId: uid,
          valorMinEstimadoPrestador: input.valorMin,
          valorMaxEstimadoPrestador: input.valorMax,
          mensagemPropostaPrestador: input.mensagem || null,
          statusProposta: 'pendente_cliente',
          propostaExpiresAt: Timestamp.fromMillis(
            nowMillis + input.validadeMinutos * 60 * 1000,
          ),
          status: nextStatus,
          estado: nextStatus,
        };
        event = 'proposta_enviada';
        description = `Prestador enviou proposta: ${input.valorMin} - ${input.valorMax}`;
        break;
      }
      case 'client_accept_quote': {
        assertPedidoActionOwner({ pedido, uid, role: 'cliente' });
        assertPedidoActionState(input.action, state, ['aguarda_resposta_cliente']);
        if (!pedidoRequiresAcceptedQuote(pedido)) {
          throw new HttpsError('failed-precondition', 'Este pedido nao exige aprovacao de orcamento.');
        }
        const expiresAt = pedido.propostaExpiresAt;
        const quoteMin = Number(pedido.valorMinEstimadoPrestador);
        const quoteMax = Number(pedido.valorMaxEstimadoPrestador);
        if (cleanString(pedido.statusProposta) !== 'pendente_cliente'
          || !cleanString(pedido.prestadorId)
          || !expiresAt
          || typeof expiresAt.toMillis !== 'function'
          || expiresAt.toMillis() <= nowMillis
          || !Number.isFinite(quoteMin)
          || quoteMin <= 0
          || !Number.isFinite(quoteMax)
          || quoteMax < quoteMin) {
          throw new HttpsError('failed-precondition', 'A proposta ja nao esta valida.');
        }
        await readEligibleProviderForPedido({
          transaction,
          database,
          providerId: cleanString(pedido.prestadorId),
          pedido,
          requireAvailableForNewWork: true,
          nowMillis,
        });
        nextStatus = 'aceito';
        patch = {
          statusProposta: 'aceita_cliente',
          status: nextStatus,
          estado: nextStatus,
          providerAccessGranted: true,
          providerAccessGrantedTo: cleanString(pedido.prestadorId),
          providerAccessGrantedAt: FieldValue.serverTimestamp(),
        };
        event = 'proposta_aceita';
        description = 'Cliente aceitou a proposta do prestador';
        break;
      }
      case 'client_reject_quote': {
        assertPedidoActionOwner({ pedido, uid, role: 'cliente' });
        assertPedidoActionState(input.action, state, ['aguarda_resposta_cliente']);
        if (cleanString(pedido.statusProposta) !== 'pendente_cliente') {
          throw new HttpsError('failed-precondition', 'Nao existe proposta pendente.');
        }
        nextStatus = 'criado';
        patch = {
          ...pedidoActionResetPatch(),
          statusProposta: 'rejeitada_cliente',
          status: nextStatus,
          estado: nextStatus,
        };
        event = 'proposta_rejeitada';
        description = 'Cliente rejeitou a proposta';
        break;
      }
      case 'client_invite_provider': {
        assertPedidoActionOwner({ pedido, uid, role: 'cliente' });
        assertPedidoActionState(input.action, state, ['criado']);
        if (cleanString(pedido.prestadorId)) {
          throw new HttpsError('failed-precondition', 'Pedido ja tem prestador atribuido.');
        }
        await readEligibleProviderForPedido({
          transaction,
          database,
          providerId: input.prestadorId,
          pedido,
          requireAvailableForNewWork: true,
          nowMillis,
        });
        nextStatus = 'aguarda_resposta_prestador';
        patch = {
          ...pedidoActionResetPatch(),
          prestadorId: input.prestadorId,
          status: nextStatus,
          estado: nextStatus,
        };
        event = 'convite_enviado';
        description = 'Cliente convidou prestador manualmente';
        break;
      }
      case 'client_replace_invited_provider': {
        assertPedidoActionOwner({ pedido, uid, role: 'cliente' });
        assertPedidoActionState(input.action, state, ['aguarda_resposta_prestador']);
        const invitedProviderId = cleanString(pedido.prestadorId);
        if (!invitedProviderId) {
          throw new HttpsError('failed-precondition', 'Pedido sem convite pendente.');
        }
        if (invitedProviderId === input.prestadorId) {
          throw new HttpsError('failed-precondition', 'Seleciona um prestador diferente.');
        }
        await readEligibleProviderForPedido({
          transaction,
          database,
          providerId: input.prestadorId,
          pedido,
          requireAvailableForNewWork: true,
          nowMillis,
        });
        nextStatus = 'aguarda_resposta_prestador';
        patch = {
          ...pedidoActionResetPatch(),
          prestadorId: input.prestadorId,
          status: nextStatus,
          estado: nextStatus,
        };
        event = 'convite_substituido';
        description = 'Cliente substituiu o prestador convidado';
        break;
      }
      case 'provider_decline_invite': {
        assertPedidoActionOwner({ pedido, uid, role: 'prestador' });
        assertPedidoActionState(input.action, state, ['aguarda_resposta_prestador']);
        nextStatus = 'criado';
        patch = {
          ...pedidoActionResetPatch(),
          status: nextStatus,
          estado: nextStatus,
          ultimoCancelamentoPrestadorId: uid,
          ultimoCancelamentoPrestadorMotivo: 'convite_recusado',
          ultimoCancelamentoPrestadorMotivoDetalhe: null,
          ultimoCancelamentoPrestadorEm: FieldValue.serverTimestamp(),
        };
        event = 'convite_recusado';
        description = 'Prestador recusou o convite';
        break;
      }
      case 'provider_start_service': {
        assertPedidoActionOwner({ pedido, uid, role: 'prestador' });
        assertPedidoActionState(input.action, state, ['aceito']);
        if (!providerHasFullPedidoAccess(pedido, uid)) {
          throw new HttpsError('permission-denied', 'O acesso privado ao pedido nao esta ativo.');
        }
        if (pedidoRequiresAcceptedQuote(pedido) && !pedidoHasAcceptedQuote(pedido)) {
          throw new HttpsError(
            'failed-precondition',
            'O cliente precisa de aceitar a estimativa antes do inicio do servico.',
          );
        }
        nextStatus = 'em_andamento';
        patch = {
          status: nextStatus,
          estado: nextStatus,
          serviceStartedAt: FieldValue.serverTimestamp(),
        };
        event = 'servico_iniciado';
        description = 'Prestador iniciou o servico';
        break;
      }
      case 'client_reject_final_value': {
        assertPedidoActionOwner({ pedido, uid, role: 'cliente' });
        assertPedidoActionState(input.action, state, ['aguarda_confirmacao_valor']);
        if (!providerHasFullPedidoAccess(pedido, cleanString(pedido.prestadorId))) {
          throw new HttpsError('failed-precondition', 'A relacao com o prestador nao esta ativa.');
        }
        if (cleanString(pedido.statusConfirmacaoValor) !== 'pendente_cliente'
          || !(Number(pedido.precoPropostoPrestador) > 0)) {
          throw new HttpsError('failed-precondition', 'Valor final nao esta pendente.');
        }
        nextStatus = 'em_andamento';
        patch = {
          statusConfirmacaoValor: 'rejeitado_cliente',
          status: nextStatus,
          estado: nextStatus,
        };
        event = 'valor_final_rejeitado';
        description = input.motivo
          ? `Cliente rejeitou o valor final: ${input.motivo}`
          : 'Cliente rejeitou o valor final';
        break;
      }
      case 'client_cancel': {
        assertPedidoActionOwner({ pedido, uid, role: 'cliente' });
        assertPedidoActionState(input.action, state, [
          'criado',
          'aguarda_resposta_prestador',
          'aguarda_resposta_cliente',
          'aceito',
          'em_andamento',
          'aguarda_confirmacao_valor',
        ]);
        if (pedidoHasSettledDigitalPayment(pedido)) {
          throw new HttpsError(
            'failed-precondition',
            'O pagamento digital ja foi confirmado; contacta o suporte para cancelar.',
          );
        }
        nextStatus = 'cancelado';
        patch = {
          status: nextStatus,
          estado: nextStatus,
          providerAccessGranted: false,
          providerAccessGrantedTo: null,
          providerAccessGrantedAt: null,
          canceladoPor: 'cliente',
          motivoCancelamento: input.motivo,
          motivoCancelamentoDetalhe: input.motivoDetalhe || null,
        };
        event = 'cancelado';
        description = input.motivoDetalhe
          ? `${input.motivo}: ${input.motivoDetalhe}`
          : input.motivo;
        break;
      }
      case 'provider_cancel': {
        assertPedidoActionOwner({ pedido, uid, role: 'prestador' });
        assertPedidoActionState(input.action, state, [
          'aguarda_resposta_prestador',
          'aguarda_resposta_cliente',
          'aceito',
          'em_andamento',
          'aguarda_confirmacao_valor',
        ]);
        if (['aceito', 'em_andamento', 'aguarda_confirmacao_valor'].includes(state)
          && !providerHasFullPedidoAccess(pedido, uid)) {
          throw new HttpsError('permission-denied', 'O acesso privado ao pedido nao esta ativo.');
        }
        if (pedidoHasSettledDigitalPayment(pedido)) {
          throw new HttpsError(
            'failed-precondition',
            'O pagamento digital ja foi confirmado; contacta o suporte para cancelar.',
          );
        }
        const withdrawal = [
          'aguarda_resposta_prestador',
          'aguarda_resposta_cliente',
          'aceito',
        ].includes(state);
        nextStatus = withdrawal ? 'criado' : 'cancelado';
        patch = withdrawal
          ? {
            ...pedidoActionResetPatch(),
            status: nextStatus,
            estado: nextStatus,
            ultimoCancelamentoPrestadorId: uid,
            ultimoCancelamentoPrestadorMotivo: input.motivo,
            ultimoCancelamentoPrestadorMotivoDetalhe: input.motivoDetalhe || null,
            ultimoCancelamentoPrestadorEm: FieldValue.serverTimestamp(),
          }
          : {
            status: nextStatus,
            estado: nextStatus,
            providerAccessGranted: false,
            providerAccessGrantedTo: null,
            providerAccessGrantedAt: null,
            canceladoPor: 'prestador',
            motivoCancelamento: input.motivo,
            motivoCancelamentoDetalhe: input.motivoDetalhe || null,
          };
        event = withdrawal ? 'desistencia_prestador' : 'cancelado';
        description = input.motivoDetalhe
          ? `${input.motivo}: ${input.motivoDetalhe}`
          : input.motivo;
        break;
      }
      case 'client_report_no_show':
      case 'provider_report_no_show': {
        assertPedidoActionOwner({ pedido, uid, role: input.role });
        assertPedidoActionState(input.action, state, ['aceito', 'em_andamento']);
        if (!cleanString(pedido.prestadorId)) {
          throw new HttpsError('failed-precondition', 'Pedido sem prestador atribuido.');
        }
        if (cleanString(pedido.noShowReportedBy)) {
          throw new HttpsError('already-exists', 'Ja existe um no-show reportado neste pedido.');
        }
        if (!providerHasFullPedidoAccess(pedido, cleanString(pedido.prestadorId))) {
          throw new HttpsError('failed-precondition', 'A relacao com o prestador nao esta ativa.');
        }
        nextStatus = state;
        patch = {
          noShowReportedBy: input.role,
          noShowReason: input.motivo || null,
          noShowAt: FieldValue.serverTimestamp(),
        };
        event = 'noshow';
        description = input.motivo
          ? `${input.role} reportou no-show: ${input.motivo}`
          : `${input.role} reportou no-show`;
        break;
      }
      default:
        throw new HttpsError('invalid-argument', 'action invalida.');
    }

    transaction.update(pedidoRef, {
      ...patch,
      ...commonPatch,
      historico: FieldValue.arrayUnion(historyItem({
        evento: event,
        userId: uid,
        descricao: description,
      })),
    });
  });

  logger.info('[pedidos] acao autoritativa aplicada', {
    functionName: 'pedidos_applyActionSecure',
    pedidoId: input.pedidoId,
    action: input.action,
    actorId: maskIdentifier(uid),
    actorRole: input.role,
    previousStatus,
    nextStatus,
  });
  return {
    ok: true,
    pedidoId: input.pedidoId,
    action: input.action,
    previousStatus,
    status: nextStatus,
  };
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
    if (!providerHasFullPedidoAccess(pedido, prestadorId)) {
      logger.warn('[chat] mensagem ignorada sem grant de relacao aceite', { pedidoId });
      return;
    }

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
      body: 'Recebeste uma nova mensagem.',
      fromUserId: senderId,
    });

    // Push
    await sendPushToUser(recipientId, {
      title: 'ChegaJá - Nova mensagem',
      body: 'Abre a aplicação para consultar a mensagem.',
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

    await syncPedidoDispatch(db, pedidoId);
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

async function loadDocumentsById(database, collectionName, documentIds) {
  const documents = new Map();
  const uniqueIds = [...new Set(documentIds.map(cleanString).filter(Boolean))];
  for (let offset = 0; offset < uniqueIds.length; offset += 100) {
    const ids = uniqueIds.slice(offset, offset + 100);
    const snapshots = await database.getAll(
      ...ids.map((id) => database.collection(collectionName).doc(id)),
    );
    snapshots.forEach((snapshot) => {
      documents.set(snapshot.id, snapshot.exists ? (snapshot.data() || {}) : null);
    });
  }
  return documents;
}

function providerIsEligibleForInitialMatching({
  pedido,
  dispatchState,
  providerPublic,
  providerPrivate,
  userPrivate,
  participant,
  nowMillis,
}) {
  if (!providerPublic
    || providerPublic.isSearchable !== true
    || !providerMatchesPedido(providerPublic, pedido)
    || !pilotParticipantIsActiveForRole(participant, 'prestador')
    || !accountAllowsNewWork(userPrivate)
    || cleanString(providerPrivate && providerPrivate.financialStatus) === 'suspended_new_jobs'
    || !dispatchState
    || dispatchState.acceptingRequests !== true
    || dispatchState.acceptingNewJobs === false
    || dispatchState.isOnline !== true
    || !providerDispatchLocation(dispatchState, nowMillis)) {
    return false;
  }
  try {
    assertCurrentLegalConsent(userPrivate && userPrivate.legalConsent);
    return true;
  } catch (_) {
    return false;
  }
}

async function matchPedidoToProvidersCore({
  database = db,
  pedidoId,
  now = Timestamp.now(),
  notifyProvider = sendPushToUser,
}) {
  const cleanPedidoId = cleanString(pedidoId);
  if (!cleanPedidoId) throw new HttpsError('invalid-argument', 'pedidoId obrigatorio.');
  const dispatchSync = await syncPedidoDispatch(database, cleanPedidoId);
  const currentPedido = dispatchSync.pedido || {};
  if (!dispatchSync.open) return { providerIds: [], reason: 'pedido_not_open' };

  const pedidoLocation = pedidoCoordinates(currentPedido);
  if (!pedidoLocation) {
    logger.info(`[matching] pedido sem geo: ${cleanPedidoId} (skip geo matching)`);
    return { providerIds: [], reason: 'pedido_without_location' };
  }
  const nowMillis = toMillis(now) || Date.now();
  const nowTimestamp = Timestamp.fromMillis(nowMillis);
  const servicoId = cleanString(currentPedido.servicoId);
  const center = [pedidoLocation.latitude, pedidoLocation.longitude];
  const maxRadiusKm = 20;
  const bounds = geofire.geohashQueryBounds(center, maxRadiusKm * 1000);
  const queries = bounds.map(([start, end]) => {
    let query = database.collection('provider_dispatch_private')
      .where('isOnline', '==', true)
      .where('acceptingRequests', '==', true);
    if (servicoId) query = query.where('servicos', 'array-contains', servicoId);
    query = query
      .orderBy('geo.geohash')
      .startAt(start)
      .endAt(end)
      .limit(100);
    return query.get();
  });
  const snapshots = await Promise.all(queries);
  const dispatchByProvider = new Map();
  snapshots.forEach((snapshot) => snapshot.docs.forEach((document) => {
    if (!dispatchByProvider.has(document.id)) {
      dispatchByProvider.set(document.id, document.data() || {});
    }
  }));

  const distanceCandidates = [];
  dispatchByProvider.forEach((dispatchState, providerId) => {
    const location = providerDispatchLocation(dispatchState, nowMillis);
    if (!location) return;
    const distanceKm = geofire.distanceBetween(
      [location.latitude, location.longitude],
      center,
    );
    if (Number.isFinite(distanceKm) && distanceKm <= location.radiusKm) {
      distanceCandidates.push({
        id: providerId,
        dispatchState,
        distanceKm,
        radiusKm: location.radiusKm,
      });
    }
  });
  if (distanceCandidates.length === 0) {
    logger.info(`[matching] nenhum prestador no raio para pedido ${cleanPedidoId}`);
    return { providerIds: [], reason: 'no_in_radius_provider' };
  }

  const candidateIds = distanceCandidates.map((candidate) => candidate.id);
  const [publicByProvider, privateByProvider, userByProvider, participantByProvider] =
    await Promise.all([
      loadDocumentsById(database, 'provider_public', candidateIds),
      loadDocumentsById(database, 'provider_private', candidateIds),
      loadDocumentsById(database, 'users_private', candidateIds),
      loadDocumentsById(database, 'pilot_participants', candidateIds),
    ]);
  const targets = distanceCandidates
    .filter((candidate) => providerIsEligibleForInitialMatching({
      pedido: currentPedido,
      dispatchState: candidate.dispatchState,
      providerPublic: publicByProvider.get(candidate.id),
      providerPrivate: privateByProvider.get(candidate.id),
      userPrivate: userByProvider.get(candidate.id),
      participant: participantByProvider.get(candidate.id),
      nowMillis,
    }))
    .sort((left, right) => left.distanceKm - right.distanceKm)
    .slice(0, 30);
  if (targets.length === 0) {
    logger.info(`[matching] nenhum prestador elegivel para pedido ${cleanPedidoId}`);
    return { providerIds: [], reason: 'no_eligible_provider' };
  }

  const opportunityTtlMinutes = Math.max(
    5,
    Math.min(Number(getEnv('PROVIDER_OPPORTUNITY_TTL_MINUTES', '15')) || 15, 30),
  );
  const opportunityExpiresAt = Timestamp.fromMillis(
    nowMillis + opportunityTtlMinutes * 60 * 1000,
  );
  const pedidoRef = database.collection('pedidos').doc(cleanPedidoId);
  const publishedProviderIds = await Promise.all(targets.map(async (match) => {
    const opportunityRef = database.collection('provider_opportunities')
      .doc(opportunityDocumentId(cleanPedidoId, match.id));
    const publishedPedido = await database.runTransaction(async (transaction) => {
      const pedidoSnap = await transaction.get(pedidoRef);
      const opportunitySnap = await transaction.get(opportunityRef);
      if (!pedidoSnap.exists) return null;

      const livePedido = pedidoSnap.data() || {};
      if (!isOpenPedido(livePedido)
        || livePedido.providerAccessGranted === true
        || !!cleanString(livePedido.providerAccessGrantedTo)) {
        return null;
      }

      if (opportunitySnap.exists) {
        const existingOpportunity = opportunitySnap.data() || {};
        if (cleanString(existingOpportunity.pedidoId) !== cleanPedidoId
          || cleanString(existingOpportunity.providerId) !== match.id
          || cleanString(existingOpportunity.status) !== 'active') {
          return null;
        }
      }

      const livePedidoLocation = pedidoCoordinates(livePedido);
      const liveProviderLocation = providerDispatchLocation(match.dispatchState, nowMillis);
      const liveProviderPublic = publicByProvider.get(match.id);
      if (!livePedidoLocation
        || !liveProviderLocation
        || !providerMatchesPedido(liveProviderPublic, livePedido)) {
        return null;
      }
      const liveDistanceKm = geofire.distanceBetween(
        [liveProviderLocation.latitude, liveProviderLocation.longitude],
        [livePedidoLocation.latitude, livePedidoLocation.longitude],
      );
      if (!Number.isFinite(liveDistanceKm) || liveDistanceKm > liveProviderLocation.radiusKm) {
        return null;
      }

      transaction.set(opportunityRef, {
        pedidoId: cleanPedidoId,
        providerId: match.id,
        serviceId: cleanString(livePedido.servicoId),
        approximateDistanceKm: Math.round(liveDistanceKm * 10) / 10,
        matchedRadiusKm: liveProviderLocation.radiusKm,
        channel: 'matching_push',
        idVersion: 'sha256-v1',
        status: 'active',
        expiresAt: opportunityExpiresAt,
        deliveredAt: nowTimestamp,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: false });
      return livePedido;
    });
    if (!publishedPedido) return null;
    await notifyProvider(
      match.id,
      buildPedidoOpportunityNotification(cleanPedidoId, publishedPedido),
    );
    return match.id;
  }));
  const providerIds = publishedProviderIds.filter(Boolean);
  logger.info(`[matching] push enviado para ${providerIds.length} prestadores pedido=${cleanPedidoId}`);
  return { providerIds, expiresAt: opportunityExpiresAt };
}

exports.onPedidoCreated = onDocumentCreated(
  {
    region: REGION,
    document: 'pedidos/{pedidoId}',
  },
  async (event) => {
    const { pedidoId } = event.params;
    const pedido = event.data.data() || {};
    await matchPedidoToProvidersCore({ database: db, pedidoId, pedido });
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

    if (pedidoIsSelfDealing(pedido)) {
      throw new HttpsError('permission-denied', 'Cliente e prestador devem ser contas diferentes.');
    }

    if (pedido.providerAccessGranted !== true
      || cleanString(pedido.providerAccessGrantedTo) !== actorUid
      || !pedido.providerAccessGrantedAt
      || typeof pedido.providerAccessGrantedAt.toMillis !== 'function'
      || pedido.providerAccessGrantedAt.toMillis() <= 0) {
      throw new HttpsError('failed-precondition', 'A relacao com o prestador ainda nao foi aceite.');
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

    if (pedidoIsSelfDealing(pedido)) {
      throw new HttpsError('permission-denied', 'Cliente e prestador devem ser contas diferentes.');
    }

    if (pedido.providerAccessGranted !== true
      || cleanString(pedido.providerAccessGrantedTo) !== providerId
      || !pedido.providerAccessGrantedAt
      || typeof pedido.providerAccessGrantedAt.toMillis !== 'function'
      || pedido.providerAccessGrantedAt.toMillis() <= 0) {
      throw new HttpsError('failed-precondition', 'A relacao com o prestador ainda nao foi aceite.');
    }

    paymentMethod = cleanString(pedido.tipoPagamento || 'dinheiro').toLowerCase();
    if (paymentMethod === 'cash') paymentMethod = 'dinheiro';
    const isCash = paymentMethod === 'dinheiro';
    if (!isCash) {
      if (!paymentMethodEnabled(paymentMethod)) {
        throw new HttpsError('failed-precondition', 'Meio de pagamento digital indisponivel no piloto.');
      }
      const paymentIntentId = cleanString(pedido.paymentIntentId);
      if (!paymentIntentId) {
        throw new HttpsError(
          'failed-precondition',
          'O pedido nao tem um pagamento digital autoritativo.',
        );
      }
      const paymentSnap = await tx.get(
        firestore.collection('payments').doc(paymentIntentId),
      );
      const payment = paymentSnap.exists ? (paymentSnap.data() || {}) : null;
      const expectedAmount = moneyToCents(proposedValue);
      const paymentAmount = Number(payment && payment.amount);
      const feeAmount = Number(payment && payment.feeAmount);
      const expectedCurrency = cleanString(
        pedido.currency || getEnv('DEFAULT_CURRENCY_CODE', 'MZN'),
      ).toLowerCase();
      const paymentValid = authoritativeDigitalPaymentMatches(payment, {
        pedidoId,
        clienteId: actorUid,
        prestadorId: providerId,
        amount: expectedAmount,
        currency: expectedCurrency,
      });
      if (!paymentValid) {
        throw new HttpsError(
          'failed-precondition',
          'O registo autoritativo do pagamento ainda nao confirma este trabalho.',
        );
      }
      economics = calculatePedidoEconomics(proposedValue, {
        commissionRate: paymentAmount === 0 ? 0 : feeAmount / paymentAmount,
        currency: expectedCurrency,
      });
    } else {
      const pedidoCurrency = cleanString(
        pedido.currency || getEnv('DEFAULT_CURRENCY_CODE', 'MZN'),
      ).toUpperCase();
      const configuredCurrency = cleanString(
        getEnv('DEFAULT_CURRENCY_CODE', 'MZN'),
      ).toUpperCase();
      if (pedidoCurrency !== configuredCurrency || configuredCurrency !== 'MZN') {
        throw new HttpsError(
          'failed-precondition',
          'A politica de comissao em dinheiro ainda nao suporta esta moeda.',
        );
      }
      const providerRef = firestore.collection('provider_private').doc(providerId);
      const providerSnap = await tx.get(providerRef);
      const providerPrivate = providerSnap.exists ? (providerSnap.data() || {}) : {};
      const policy = cashCommissionPolicy({
        completedJobsCount: providerPrivate.completedJobsCount,
      });
      economics = calculatePedidoEconomics(proposedValue, {
        ...policy,
        currency: pedidoCurrency,
      });

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
      paymentStatus: isCash ? 'cash_confirmed_by_client' : 'succeeded',
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

exports.pedidos_applyActionSecure = onCall(
  {
    region: REGION,
  },
  async (req) => applyPedidoActionSecureCore({
    auth: req.auth,
    data: req.data || {},
  }),
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
  async (req) => {
    if (!authIsAdmin(req.auth)) {
      const uid = requireVerifiedPhoneAuth(req.auth);
      await requireCurrentLegalConsent({ uid });
    }
    return finalizePrivateStorageUploadCore({
      auth: req.auth,
      data: req.data || {},
    });
  },
);

exports.storage_getPrivateReadUrl = onCall(
  { region: REGION },
  async (req) => {
    if (!authIsAdmin(req.auth)) {
      const uid = requireVerifiedPhoneAuth(req.auth);
      await requireCurrentLegalConsent({ uid });
    }
    return getPrivateStorageReadUrlCore({
      auth: req.auth,
      data: req.data || {},
    });
  },
);

// ------------------------------------------------------------
// 5) Stripe Connect + Pagamentos
// ------------------------------------------------------------

function getStripe() {
  if (!paymentMethodEnabled('stripe')) {
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

function subscriptionsEnabled() {
  return paymentMethodEnabled('stripe') && envFlagEnabled('ENABLE_SUBSCRIPTIONS');
}

function requireStripePaymentsEnabled() {
  if (!paymentMethodEnabled('stripe')) {
    throw new HttpsError(
      'failed-precondition',
      'Stripe esta desativado ate a integracao em MZN estar validada.',
    );
  }
}

function requireSubscriptionsEnabled() {
  requireStripePaymentsEnabled();
  if (!subscriptionsEnabled()) {
    throw new HttpsError(
      'failed-precondition',
      'As subscricoes estao desativadas para o piloto.',
    );
  }
}

async function requirePaymentActor({ auth, role, database = db }) {
  const uid = requireVerifiedPhoneAuth(auth);
  const userSnapshot = await database.collection('users_private').doc(uid).get();
  const userPrivate = userSnapshot.exists ? (userSnapshot.data() || {}) : {};
  assertCurrentLegalConsent(userPrivate.legalConsent);
  if (!accountAllowsNewWork(userPrivate)) {
    throw new HttpsError(
      'failed-precondition',
      'Esta conta nao pode iniciar operacoes de pagamento.',
    );
  }
  await requirePilotParticipant({
    database,
    uid,
    role,
    allowEmulatorBypass: false,
  });
  return uid;
}

function paymentIntentSpecFromPedido(pedidoId, pedido) {
  const clienteId = cleanString(getClienteId(pedido));
  const prestadorId = cleanString(pedido && pedido.prestadorId);
  const state = getPedidoEstado(pedido);
  const confirmationStatus = cleanString(pedido && pedido.statusConfirmacaoValor);
  if (state !== 'aguarda_confirmacao_valor' || confirmationStatus !== 'pendente_cliente') {
    throw new HttpsError(
      'failed-precondition',
      'O valor final nao esta pendente de confirmacao pelo cliente.',
    );
  }
  if (!clienteId || !prestadorId) {
    throw new HttpsError('failed-precondition', 'Pedido sem cliente ou prestador atribuido.');
  }
  if (pedidoIsSelfDealing(pedido, prestadorId)) {
    throw new HttpsError('permission-denied', 'Cliente e prestador devem ser contas diferentes.');
  }
  if (!providerHasFullPedidoAccess(pedido, prestadorId)) {
    throw new HttpsError('failed-precondition', 'A relacao com o prestador ainda nao foi aceite.');
  }
  if (!pedidoIsApprovedForWork(pedido)) {
    throw new HttpsError('failed-precondition', 'O pedido ainda nao foi aprovado para pagamento.');
  }
  if (cleanString(pedido.tipoPagamento).toLowerCase() !== 'stripe') {
    throw new HttpsError('failed-precondition', 'Este pedido nao usa Stripe.');
  }

  const amount = moneyToCents(requirePositiveMoney(
    pedido.precoPropostoPrestador,
    'precoPropostoPrestador',
  ));
  if (!Number.isSafeInteger(amount) || amount <= 0) {
    throw new HttpsError('invalid-argument', 'Valor invalido para pagamento.');
  }
  const currency = cleanString(
    pedido.currency || getEnv('DEFAULT_CURRENCY_CODE', 'MZN'),
  ).toLowerCase();
  const configuredCurrency = cleanString(getEnv('DEFAULT_CURRENCY_CODE', 'MZN')).toLowerCase();
  if (currency !== 'mzn' || configuredCurrency !== 'mzn') {
    throw new HttpsError('failed-precondition', 'Moeda do pedido invalida para o piloto.');
  }
  const commissionRate = requiredCommissionRate('DEFAULT_DIGITAL_COMMISSION_RATE');
  const feeAmount = Math.max(0, Math.round(amount * commissionRate));
  const material = `${pedidoId}\n${clienteId}\n${prestadorId}\n${amount}\n${currency}\n${feeAmount}`;
  const paymentSpecHash = crypto.createHash('sha256').update(material).digest('hex');
  return {
    pedidoId,
    clienteId,
    prestadorId,
    amount,
    currency,
    feeAmount,
    paymentSpecHash,
    idempotencyKey: `chegaja:pedido:${paymentSpecHash}`,
  };
}

function paymentRecordMatchesSpec(payment, spec) {
  if (!payment) return false;
  const status = cleanString(payment.status).toLowerCase();
  return !['canceled', 'cancelled'].includes(status)
    && cleanString(payment.pedidoId) === spec.pedidoId
    && cleanString(payment.clienteId) === spec.clienteId
    && cleanString(payment.prestadorId) === spec.prestadorId
    && Number(payment.amount) === spec.amount
    && Number(payment.feeAmount) === spec.feeAmount
    && cleanString(payment.currency).toLowerCase() === spec.currency
    && (!payment.paymentSpecHash || cleanString(payment.paymentSpecHash) === spec.paymentSpecHash);
}

function stripeIntentMatchesSpec(intent, spec) {
  if (!intent || cleanString(intent.id) === '') return false;
  const metadata = intent.metadata || {};
  const destination = intent.transfer_data && intent.transfer_data.destination
    ? cleanString(intent.transfer_data.destination)
    : '';
  const applicationFee = intent.application_fee_amount;
  return !['canceled', 'cancelled'].includes(cleanString(intent.status).toLowerCase())
    && Number(intent.amount) === spec.amount
    && cleanString(intent.currency).toLowerCase() === spec.currency
    && cleanString(metadata.pedidoId) === spec.pedidoId
    && cleanString(metadata.clienteId) === spec.clienteId
    && cleanString(metadata.prestadorId) === spec.prestadorId
    && cleanString(metadata.paymentSpecHash) === spec.paymentSpecHash
    && (applicationFee === null || applicationFee === undefined
      || Number(applicationFee) === spec.feeAmount)
    && (!destination || destination === spec.stripeAccountId);
}

function paymentLedgerDocumentId(paymentIntentId, eventType, eventId) {
  const digest = crypto.createHash('sha256')
    .update(`${cleanString(paymentIntentId)}\n${cleanString(eventType)}\n${cleanString(eventId)}`)
    .digest('hex');
  return `evt_${digest}`;
}

async function readPaymentIntentContextInTransaction({
  transaction,
  database,
  pedidoRef,
  pedidoId,
  clienteId,
  reserve = false,
}) {
  const pedidoSnapshot = await transaction.get(pedidoRef);
  if (!pedidoSnapshot.exists) {
    throw new HttpsError('not-found', 'Pedido nao encontrado.');
  }
  const pedido = pedidoSnapshot.data() || {};
  const spec = paymentIntentSpecFromPedido(pedidoId, pedido);
  if (spec.clienteId !== clienteId) {
    throw new HttpsError('permission-denied', 'Apenas o cliente do pedido pode pagar.');
  }

  const clientUserSnapshot = await transaction.get(
    database.collection('users_private').doc(spec.clienteId),
  );
  const clientPrivate = clientUserSnapshot.exists ? (clientUserSnapshot.data() || {}) : {};
  assertCurrentLegalConsent(clientPrivate.legalConsent);
  if (!accountAllowsNewWork(clientPrivate)) {
    throw new HttpsError('failed-precondition', 'A conta do cliente nao permite pagamentos.');
  }
  const clientParticipantSnapshot = await transaction.get(
    database.collection('pilot_participants').doc(spec.clienteId),
  );
  if (!clientParticipantSnapshot.exists
    || !pilotParticipantIsActiveForRole(clientParticipantSnapshot.data(), 'cliente')) {
    throw new HttpsError('permission-denied', 'Cliente fora da coorte ativa do piloto.');
  }

  await readEligibleProviderForPedido({
    transaction,
    database,
    providerId: spec.prestadorId,
    pedido,
    requireAvailableForNewWork: true,
  });
  const providerPrivateSnapshot = await transaction.get(
    database.collection('provider_private').doc(spec.prestadorId),
  );
  const providerPrivate = providerPrivateSnapshot.exists
    ? (providerPrivateSnapshot.data() || {})
    : {};
  const stripeAccountId = cleanString(providerPrivate.stripeAccountId);
  if (!stripeAccountId) {
    throw new HttpsError('failed-precondition', 'Prestador sem Stripe Connect.');
  }
  spec.stripeAccountId = stripeAccountId;

  const existingPaymentIntentId = cleanString(pedido.paymentIntentId);
  if (existingPaymentIntentId) {
    const paymentSnapshot = await transaction.get(
      database.collection('payments').doc(existingPaymentIntentId),
    );
    if (!paymentSnapshot.exists || !paymentRecordMatchesSpec(paymentSnapshot.data(), spec)) {
      throw new HttpsError(
        'failed-precondition',
        'O pagamento existente precisa de revisao pelo suporte.',
      );
    }
    return { pedido, spec, existingPaymentIntentId };
  }

  const paymentsForPedido = await transaction.get(
    database.collection('payments').where('pedidoId', '==', pedidoId).limit(2),
  );
  if (!paymentsForPedido.empty) {
    throw new HttpsError(
      'failed-precondition',
      'Existe um pagamento nao associado que precisa de revisao pelo suporte.',
    );
  }

  const reservationKey = cleanString(pedido.paymentIntentReservationKey);
  if (reservationKey && reservationKey !== spec.idempotencyKey) {
    throw new HttpsError(
      'failed-precondition',
      'Existe uma tentativa de pagamento incompatível que precisa de revisao.',
    );
  }
  if (reserve) {
    transaction.update(pedidoRef, {
      paymentIntentReservationKey: spec.idempotencyKey,
      paymentSpecHash: spec.paymentSpecHash,
      paymentAmount: spec.amount,
      paymentCurrency: spec.currency,
      paymentFeeAmount: spec.feeAmount,
      paymentStatus: 'creating',
      paymentIntentReservationAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  return { pedido, spec, existingPaymentIntentId: '' };
}

async function createPaymentIntentCore({ database = db, stripe, uid, pedidoId }) {
  requireStripePaymentsEnabled();
  const clienteId = requireCallableUid(uid);
  const cleanPedidoId = strictPedidoDocumentId(pedidoId);
  const pedidoRef = database.collection('pedidos').doc(cleanPedidoId);
  const initial = await database.runTransaction((transaction) => (
    readPaymentIntentContextInTransaction({
      transaction,
      database,
      pedidoRef,
      pedidoId: cleanPedidoId,
      clienteId,
      reserve: true,
    })
  ));
  const spec = initial.spec;

  let stripeAccount;
  try {
    stripeAccount = await stripe.accounts.retrieve(spec.stripeAccountId);
  } catch (_) {
    throw new HttpsError('failed-precondition', 'Nao foi possivel validar a conta Stripe do prestador.');
  }
  if (!stripeAccount
    || stripeAccount.deleted === true
    || stripeAccount.charges_enabled !== true
    || stripeAccount.payouts_enabled !== true) {
    throw new HttpsError(
      'failed-precondition',
      'A conta Stripe do prestador ainda nao pode receber pagamentos.',
    );
  }

  let paymentIntent;
  let createdNow = false;
  if (initial.existingPaymentIntentId) {
    try {
      paymentIntent = await stripe.paymentIntents.retrieve(initial.existingPaymentIntentId);
    } catch (_) {
      throw new HttpsError('failed-precondition', 'Nao foi possivel validar o pagamento existente.');
    }
    if (!stripeIntentMatchesSpec(paymentIntent, spec) || !cleanString(paymentIntent.client_secret)) {
      throw new HttpsError(
        'failed-precondition',
        'O pagamento existente e incompatível e precisa de revisao pelo suporte.',
      );
    }
  } else {
    paymentIntent = await stripe.paymentIntents.create({
      amount: spec.amount,
      currency: spec.currency,
      automatic_payment_methods: { enabled: true },
      application_fee_amount: spec.feeAmount,
      transfer_data: { destination: spec.stripeAccountId },
      metadata: {
        pedidoId: spec.pedidoId,
        clienteId: spec.clienteId,
        prestadorId: spec.prestadorId,
        paymentSpecHash: spec.paymentSpecHash,
      },
    }, { idempotencyKey: spec.idempotencyKey });
    createdNow = true;
    if (!stripeIntentMatchesSpec(paymentIntent, spec) || !cleanString(paymentIntent.client_secret)) {
      throw new HttpsError('internal', 'Stripe devolveu um pagamento incompatível.');
    }
  }

  try {
    await database.runTransaction(async (transaction) => {
      const current = await readPaymentIntentContextInTransaction({
        transaction,
        database,
        pedidoRef,
        pedidoId: cleanPedidoId,
        clienteId,
        reserve: false,
      });
      if (current.spec.paymentSpecHash !== spec.paymentSpecHash
        || current.spec.stripeAccountId !== spec.stripeAccountId
        || (current.existingPaymentIntentId
          && current.existingPaymentIntentId !== cleanString(paymentIntent.id))) {
        throw new HttpsError(
          'failed-precondition',
          'O pedido mudou durante a criacao do pagamento.',
        );
      }
      const now = FieldValue.serverTimestamp();
      transaction.update(pedidoRef, {
        paymentIntentId: paymentIntent.id,
        paymentIntentReservationKey: spec.idempotencyKey,
        paymentSpecHash: spec.paymentSpecHash,
        paymentAmount: spec.amount,
        paymentCurrency: spec.currency,
        paymentFeeAmount: spec.feeAmount,
        paymentStatus: paymentIntent.status,
        updatedAt: now,
      });
      transaction.set(database.collection('payments').doc(paymentIntent.id), {
        paymentIntentId: paymentIntent.id,
        pedidoId: spec.pedidoId,
        clienteId: spec.clienteId,
        prestadorId: spec.prestadorId,
        stripeAccountId: spec.stripeAccountId,
        paymentSpecHash: spec.paymentSpecHash,
        amount: spec.amount,
        currency: spec.currency,
        feeAmount: spec.feeAmount,
        status: paymentIntent.status,
        createdAt: now,
        updatedAt: now,
      }, { merge: true });
      const ledgerId = paymentLedgerDocumentId(
        paymentIntent.id,
        'payment_intent_created',
        spec.idempotencyKey,
      );
      transaction.set(database.collection('payment_ledger').doc(ledgerId), {
        paymentIntentId: paymentIntent.id,
        eventType: 'payment_intent_created',
        eventId: spec.idempotencyKey,
        pedidoId: spec.pedidoId,
        clienteId: spec.clienteId,
        prestadorId: spec.prestadorId,
        status: paymentIntent.status,
        amount: spec.amount,
        feeAmount: spec.feeAmount,
        currency: spec.currency,
        source: 'callable',
        createdAt: now,
      }, { merge: false });
    });
  } catch (error) {
    if (createdNow && stripe.paymentIntents && typeof stripe.paymentIntents.cancel === 'function') {
      try {
        await stripe.paymentIntents.cancel(
          paymentIntent.id,
          {},
          { idempotencyKey: `${spec.idempotencyKey}:cancel` },
        );
      } catch (cancelError) {
        logger.error('[stripe] falha ao cancelar PaymentIntent orfao', {
          pedidoId: cleanPedidoId,
          paymentIntentId: paymentIntent.id,
          error: String(cancelError),
        });
      }
    }
    throw error;
  }

  return {
    clientSecret: paymentIntent.client_secret,
    paymentIntentId: paymentIntent.id,
    amount: spec.amount,
    currency: spec.currency,
  };
}

exports.payments_createOnboardingLink = onCall(
  {
    region: REGION,
  },
  async (req) => {
    requireStripePaymentsEnabled();
    const uid = await requirePaymentActor({
      auth: req.auth,
      role: 'prestador',
    });
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
    requireStripePaymentsEnabled();
    const uid = await requirePaymentActor({
      auth: req.auth,
      role: 'cliente',
    });
    const stripe = getStripe();
    return createPaymentIntentCore({
      database: db,
      stripe,
      uid,
      pedidoId: req.data && req.data.pedidoId,
    });
  }
);

exports.payments_createSubscriptionCheckout = onCall(
  {
    region: REGION,
  },
  async (req) => {
    requireSubscriptionsEnabled();
    const uid = await requirePaymentActor({
      auth: req.auth,
      role: 'prestador',
    });
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
    requireSubscriptionsEnabled();
    const uid = await requirePaymentActor({
      auth: req.auth,
      role: 'prestador',
    });
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
    requireSubscriptionsEnabled();
    const uid = await requirePaymentActor({
      auth: req.auth,
      role: 'prestador',
    });
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

function safeStripeEventDocumentId(value) {
  const id = cleanString(value);
  if (!id || id.length > 200 || id.includes('/')) {
    throw new HttpsError('invalid-argument', 'Evento Stripe sem identificador valido.');
  }
  return id;
}

async function processStripePaymentEventCore({ database = db, event }) {
  const eventId = safeStripeEventDocumentId(event && event.id);
  const eventType = cleanString(event && event.type);
  if (!['payment_intent.succeeded', 'payment_intent.payment_failed'].includes(eventType)) {
    return { status: 'ignored', eventId, eventType };
  }
  const paymentIntent = event && event.data ? event.data.object : null;
  const paymentIntentId = cleanString(paymentIntent && paymentIntent.id);
  if (!paymentIntentId || paymentIntentId.includes('/')) {
    throw new HttpsError('invalid-argument', 'PaymentIntent invalido no webhook.');
  }
  const metadata = paymentIntent.metadata || {};
  const pedidoId = cleanString(metadata.pedidoId);
  const clienteId = cleanString(metadata.clienteId);
  const prestadorId = cleanString(metadata.prestadorId);
  const paymentSpecHash = cleanString(metadata.paymentSpecHash);
  const eventCreated = Number(event.created);
  const receiptRef = database.collection('stripe_webhook_events').doc(eventId);

  return database.runTransaction(async (transaction) => {
    const receiptSnapshot = await transaction.get(receiptRef);
    if (receiptSnapshot.exists) {
      const receipt = receiptSnapshot.data() || {};
      return {
        status: cleanString(receipt.status) || 'processed',
        eventId,
        idempotent: true,
      };
    }

    const reasons = [];
    if (!pedidoId || pedidoId.includes('/')) reasons.push('metadata_pedido_invalid');
    if (!clienteId) reasons.push('metadata_cliente_invalid');
    if (!prestadorId) reasons.push('metadata_prestador_invalid');
    if (!paymentSpecHash) reasons.push('metadata_spec_hash_missing');
    if (!Number.isFinite(eventCreated) || eventCreated <= 0) reasons.push('event_created_invalid');

    const pedidoRef = pedidoId && !pedidoId.includes('/')
      ? database.collection('pedidos').doc(pedidoId)
      : null;
    const paymentRef = database.collection('payments').doc(paymentIntentId);
    const pedidoSnapshot = pedidoRef ? await transaction.get(pedidoRef) : null;
    const paymentSnapshot = await transaction.get(paymentRef);
    const pedido = pedidoSnapshot && pedidoSnapshot.exists ? (pedidoSnapshot.data() || {}) : null;
    const payment = paymentSnapshot.exists ? (paymentSnapshot.data() || {}) : null;
    if (!pedido) reasons.push('pedido_missing');
    if (!payment) reasons.push('payment_record_missing');

    let spec = null;
    if (pedido) {
      try {
        spec = paymentIntentSpecFromPedido(pedidoId, pedido);
      } catch (_) {
        reasons.push('pedido_state_or_spec_invalid');
      }
    }
    if (spec) {
      if (spec.clienteId !== clienteId) reasons.push('cliente_mismatch');
      if (spec.prestadorId !== prestadorId) reasons.push('prestador_mismatch');
      if (spec.paymentSpecHash !== paymentSpecHash) reasons.push('spec_hash_mismatch');
      if (cleanString(pedido.paymentIntentId) !== paymentIntentId) {
        reasons.push('current_intent_mismatch');
      }
      if (Number(pedido.paymentAmount) !== spec.amount) reasons.push('pedido_amount_mismatch');
      if (Number(pedido.paymentFeeAmount) !== spec.feeAmount) reasons.push('pedido_fee_mismatch');
      if (cleanString(pedido.paymentCurrency).toLowerCase() !== spec.currency) {
        reasons.push('pedido_currency_mismatch');
      }
      if (Number(paymentIntent.amount) !== spec.amount) reasons.push('event_amount_mismatch');
      if (cleanString(paymentIntent.currency).toLowerCase() !== spec.currency) {
        reasons.push('event_currency_mismatch');
      }
      if (paymentIntent.application_fee_amount !== null
        && paymentIntent.application_fee_amount !== undefined
        && Number(paymentIntent.application_fee_amount) !== spec.feeAmount) {
        reasons.push('event_fee_mismatch');
      }
      if (eventType === 'payment_intent.succeeded') {
        if (cleanString(paymentIntent.status).toLowerCase() !== 'succeeded') {
          reasons.push('event_status_mismatch');
        }
        if (Number(paymentIntent.amount_received) !== spec.amount) {
          reasons.push('amount_received_mismatch');
        }
      } else if (cleanString(paymentIntent.status).toLowerCase() === 'succeeded') {
        reasons.push('event_status_mismatch');
      }
      if (!paymentRecordMatchesSpec(payment, spec)
        || cleanString(payment && payment.paymentSpecHash) !== spec.paymentSpecHash
        || cleanString(payment && payment.paymentIntentId) !== paymentIntentId) {
        reasons.push('payment_record_mismatch');
      }
      const previousStripeEventCreated = Number(payment && payment.lastStripeEventCreated);
      if (Number.isFinite(previousStripeEventCreated)
        && Number.isFinite(eventCreated)
        && eventCreated < previousStripeEventCreated) {
        reasons.push('stale_event');
      }
      if (eventType === 'payment_intent.payment_failed'
        && cleanString(payment && payment.status).toLowerCase() === 'succeeded') {
        reasons.push('succeeded_payment_cannot_regress');
      }
    }

    const now = FieldValue.serverTimestamp();
    if (reasons.length > 0) {
      const uniqueReasons = [...new Set(reasons)].sort();
      transaction.set(database.collection('payment_webhook_quarantine').doc(eventId), {
        eventId,
        eventType,
        paymentIntentId,
        pedidoId: pedidoId || null,
        clienteId: clienteId || null,
        prestadorId: prestadorId || null,
        reasonCodes: uniqueReasons,
        receivedAt: now,
      }, { merge: false });
      transaction.set(receiptRef, {
        eventId,
        eventType,
        paymentIntentId,
        status: 'quarantined',
        reasonCodes: uniqueReasons,
        processedAt: now,
      }, { merge: false });
      return { status: 'quarantined', eventId, reasons: uniqueReasons };
    }

    const status = cleanString(paymentIntent.status).toLowerCase();
    transaction.update(pedidoRef, {
      paymentStatus: status,
      lastStripeEventId: eventId,
      lastStripeEventCreated: eventCreated,
      updatedAt: now,
    });
    transaction.update(paymentRef, {
      status,
      lastStripeEventId: eventId,
      lastStripeEventCreated: eventCreated,
      updatedAt: now,
    });
    const ledgerId = paymentLedgerDocumentId(paymentIntentId, eventType, eventId);
    transaction.set(database.collection('payment_ledger').doc(ledgerId), {
      paymentIntentId,
      eventType,
      eventId,
      pedidoId,
      clienteId,
      prestadorId,
      status,
      amount: Number(paymentIntent.amount),
      feeAmount: spec.feeAmount,
      currency: spec.currency,
      source: 'webhook',
      createdAt: now,
    }, { merge: false });
    transaction.set(receiptRef, {
      eventId,
      eventType,
      paymentIntentId,
      status: 'processed',
      processedAt: now,
    }, { merge: false });
    return { status: 'processed', eventId, paymentIntentId };
  });
}

// Webhook Stripe (opcional). Precisa configurar endpoint no painel Stripe.
exports.payments_stripeWebhook = onRequest(
  {
    region: REGION,
  },
  (req, res) => {
    cors(req, res, async () => {
      if (!paymentMethodEnabled('stripe')) {
        res.status(200).json({ received: false, ignored: 'stripe_disabled' });
        return;
      }
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
          await processStripePaymentEventCore({ database: db, event });
        }

        if (subscriptionsEnabled() && type === 'checkout.session.completed') {
          const session = event.data.object;
          if (session && session.mode === 'subscription' && session.subscription) {
            const stripeSubscriptionId = String(session.subscription);
            const sub = await stripe.subscriptions.retrieve(stripeSubscriptionId);
            await upsertSubscriptionFromStripe(sub, { source: 'checkout.session.completed' });
          }
        }

        if (
          subscriptionsEnabled()
          && (
          type === 'customer.subscription.created'
          || type === 'customer.subscription.updated'
          || type === 'customer.subscription.deleted'
          )
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
    const [prestadorSnap, userPrivateSnap] = await Promise.all([
      tx.get(prestadorRef),
      tx.get(database.collection('users_private').doc(uid)),
    ]);
    if (!accountAllowsNewWork(userPrivateSnap.exists ? userPrivateSnap.data() : {})) {
      throw new HttpsError(
        'failed-precondition',
        'Cancela primeiro o pedido de eliminacao para reservar um identificador publico.',
      );
    }
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
  const providerRef = database.collection('provider_public').doc(providerId);
  const approvalRef = database
    .collection('provider_private')
    .doc(providerId)
    .collection('categoryApprovals')
    .doc(categoryId);
  await database.runTransaction(async (transaction) => {
    const reads = [
      transaction.get(database.collection('users_private').doc(providerId)),
      transaction.get(requestRef),
    ];
    if (decision === 'approved') reads.push(transaction.get(approvalRef));
    const [userPrivate, freshRequest, approvalSnap] = await Promise.all(reads);
    if (!accountAllowsNewWork(userPrivate.exists ? userPrivate.data() : {})) {
      throw new HttpsError('failed-precondition', 'A conta do prestador esta em processo de eliminacao.');
    }
    if (!freshRequest.exists) {
      throw new HttpsError('not-found', 'Pedido de comprovativo nao encontrado.');
    }
    const freshBeforeStatus = cleanString(freshRequest.data().status || 'pending_review');
    if (['expired', 'revoked'].includes(freshBeforeStatus)) {
      throw new HttpsError('failed-precondition', 'Pedido nao pode ser decidido neste estado.');
    }
    transaction.set(requestRef, {
      status: decision,
      reviewedBy: auth && auth.uid ? String(auth.uid) : '',
      reviewedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      decisionReason,
    }, { merge: true });

    if (decision === 'approved') {
      transaction.set(approvalRef, {
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
      }, { merge: true });
      transaction.set(providerRef, {
        approvedSensitiveCategoryIds: FieldValue.arrayUnion(categoryId),
        ...(categoryName
          ? { approvedSensitiveCategoryNames: FieldValue.arrayUnion(categoryName) }
          : {}),
        categoryApprovalsUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    writeAdminAuditLog({
      database,
      batch: transaction,
      auth,
      action: `sensitive_category_request.${decision === 'approved' ? 'approve' : decision === 'rejected' ? 'reject' : 'needs_more_info'}`,
      targetType: 'sensitive_category_request',
      targetId: requestId,
      beforeStatus: freshBeforeStatus,
      afterStatus: decision,
      reason: decisionReason,
      metadata: { providerId, categoryId, categoryName },
    });
  });

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
      if (!['pending', 'pending_active_work', 'executing'].includes(cleanString(doc.data().status))) continue;
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

async function expireRequestsCore({
  database = db,
  now = Timestamp.now(),
  pageSize = 100,
} = {}) {
  const boundedPageSize = Math.max(1, Math.min(Number(pageSize) || 100, 400));
  const cutoff = new Timestamp(now.seconds - 30 * 60, now.nanoseconds);
  const states = ['criado', 'aguarda_resposta_prestador'];
  let expired = 0;

  while (true) {
    const snapshot = await database.collection('pedidos')
      .where('status', 'in', states)
      .where('updatedAt', '<', cutoff)
      .limit(boundedPageSize)
      .get();
    if (snapshot.empty) break;

    const batch = database.batch();
    snapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: 'cancelado',
        estado: 'cancelado',
        providerAccessGranted: false,
        providerAccessGrantedTo: null,
        providerAccessGrantedAt: null,
        cancelReason: 'timeout_sistema',
        updatedAt: now,
      });
    });
    await batch.commit();
    expired += snapshot.size;
    if (snapshot.size < boundedPageSize) break;
  }
  return { expired };
}

exports.scheduled_expireRequests = onSchedule(
  {
    region: REGION,
    schedule: 'every 15 minutes', // Executa frequentemente para limpar pendentes
    timeZone: 'Europe/Lisbon',
  },
  async () => {
    const result = await expireRequestsCore();
    logger.info(`[expireRequests] Cancelados ${result.expired} pedidos expirados.`);
  },
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
    applyPedidoActionSecureCore,
    buildPedidoDispatchProjection,
    buildPedidoOpportunityNotification,
    buildSecurePedidoData,
    cashCommissionPolicy,
    calculatePedidoEconomics,
    catalogDocumentIsActive,
    classifyServerServiceText,
    confirmarValorFinalPedidoCore,
    createSecurePedidoCore,
    expireRequestsCore,
    isOpenPedido,
    matchPedidoToProvidersCore,
    opportunityDocumentId,
    providerMatchesPedido,
    providerDispatchLocation,
    promotePedidoAttachments,
    proporValorFinalPedidoCore,
    parsePedidoActionInput,
    PEDIDO_ACTION_SPECS,
    reviewPedidoServiceCore,
    sanitizeDispatchText,
    sanitizeDispatchZone,
    syncPedidoDispatch,
    syncProviderActiveClients,
    updateSecurePedidoCore,
  },
  payments: {
    authoritativeDigitalPaymentMatches,
    createPaymentIntentCore,
    enforceCommissionDebtCore,
    paymentIntentSpecFromPedido,
    paymentLedgerDocumentId,
    paymentMethodEnabled,
    processStripePaymentEventCore,
    recordCommissionPaymentCore,
    requirePaymentActor,
    stripeIntentMatchesSpec,
    subscriptionsEnabled,
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
    accountAllowsNewWork,
    accountDeletionPseudonym,
    accountDeletionRequestCanExecute,
    accountDeletionStoragePrefixes,
    cancelAccountDeletionCore,
    deleteMatchingDocuments,
    executeAccountDeletionCore,
    findActiveAccountOrders,
    isActiveAccountOrder,
    pseudonymizeUidInValue,
    requestAccountDeletionCore,
    requireAccountAllowsNewActivity,
    updateMatchingDocuments,
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
