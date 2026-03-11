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

const admin = require('firebase-admin');
const { Timestamp, FieldValue } = require('firebase-admin/firestore');
const { logger } = require('firebase-functions');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const geofire = require('geofire-common');
const cors = require('cors')({ origin: true });
const dotenv = require('dotenv');

// Carrega .env local (apenas em emuladores/dev)
const useEmulators = process.env.FUNCTIONS_EMULATOR === 'true'
  || !!process.env.FIREBASE_EMULATOR_HUB;
if (useEmulators) {
  dotenv.config({ path: '.env.local' });
  dotenv.config();
}

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const REGION = process.env.FUNCTIONS_REGION || 'europe-west1';
const GOOGLE_PLACES_API_KEY = defineSecret('GOOGLE_PLACES_API_KEY');
const GOOGLE_MAPS_API_KEY = defineSecret('GOOGLE_MAPS_API_KEY');

// ------------------------------------------------------------
// Helpers
// ------------------------------------------------------------

function getEnv(key, fallback = '') {
  const v = process.env[key];
  return (v === undefined || v === null) ? fallback : String(v);
}

function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) {
    out.push(arr.slice(i, i + size));
  }
  return out;
}

async function getUserFcmTokens(userId) {
  const snap = await db.collection('users').doc(userId).collection('fcmTokens').get();
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
    const ref = db.collection('users').doc(userId).collection('fcmTokens').doc(t);
    batch.delete(ref);
  });
  await batch.commit();
  logger.info(`[FCM] Tokens inválidos removidos user=${userId} count=${invalid.length}`);
}

async function saveInAppNotification(userId, payload) {
  try {
    await db.collection('users').doc(userId).collection('notifications').add({
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


function moneyToCents(value) {
  const num = Number(value);
  if (!Number.isFinite(num)) return 0;
  return Math.round(num * 100);
}

function getClienteId(data) {
  if (!data) return '';
  return (data.clienteId || data.clientId || '').toString();
}

function ensureAdmin(auth) {
  if (useEmulators) {
    return;
  }
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

  const usersByCustomer = await db.collection('users')
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

  await db.collection('users').doc(uid).set(
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

    // Só pedidos abertos
    if (pedido.prestadorId) return;

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
      let q = db.collection('prestadores')
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
    const targetIds = matches.slice(0, TOP_N).map((m) => m.id);

    await Promise.all(targetIds.map((prestadorId) => {
      return sendPushToUser(prestadorId, {
        title: 'ChegaJá - Novo pedido perto de ti',
        body: safeText(titulo || 'Novo pedido', 120),
        data: {
          type: 'novo_pedido',
          pedidoId,
        },
      });
    }));

    logger.info(`[matching] push enviado para ${targetIds.length} prestadores pedido=${pedidoId}`);
  }
);

// ------------------------------------------------------------
// 4) Stripe Connect + Pagamentos
// ------------------------------------------------------------

function getStripe() {
  const secret = getEnv('STRIPE_SECRET_KEY');
  if (!secret) {
    throw new Error('STRIPE_SECRET_KEY não configurada.');
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

    const prestadorRef = db.collection('prestadores').doc(uid);
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

    // Valor a cobrar
    const valor = pedido.precoPropostoPrestador ?? pedido.precoFinal ?? pedido.preco;
    const amount = moneyToCents(valor);
    if (amount <= 0) {
      throw new Error('Valor inválido para pagamento');
    }

    const currency = String(pedido.currency || 'eur').toLowerCase();

    // conta do prestador
    const prestadorSnap = await db.collection('prestadores').doc(prestadorId).get();
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

    const commissionRate = Number(getEnv('DEFAULT_COMMISSION_RATE', '0.15')) || 0.15;
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

    const userRef = db.collection('users').doc(uid);
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
    const userSnap = await db.collection('users').doc(uid).get();
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
      if (sessiontoken) params.set('sessiontoken', sessiontoken);

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

      const apiKey = GOOGLE_PLACES_API_KEY.value() || getEnv('GOOGLE_PLACES_API_KEY');
      if (!apiKey) {
        res.status(500).json({
          status: 'REQUEST_DENIED',
          error_message: 'GOOGLE_PLACES_API_KEY missing',
        });
        return;
      }

      const placeId = String(req.query.place_id || '').trim();
      if (!placeId) {
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
      if (sessiontoken) params.set('sessiontoken', sessiontoken);

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
      if (!origin || !destination) {
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

          const qs = await db.collection('prestadores').where('stripeAccountId', '==', accountId).limit(5).get();
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

exports.admin_updateSupportTicketStatus = onCall(
  {
    region: REGION,
  },
  async (req) => {
    ensureAdmin(req.auth);
    const ticketId = String(req.data?.ticketId || '').trim();
    const status = String(req.data?.status || '').trim().toLowerCase();
    const allowed = new Set(['open', 'in_progress', 'resolved', 'closed']);
    if (!ticketId) throw new HttpsError('invalid-argument', 'ticketId obrigatório');
    if (!allowed.has(status)) throw new HttpsError('invalid-argument', 'status inválido');

    await db.collection('support_tickets').doc(ticketId).set(
      {
        status,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: req.auth.uid,
      },
      { merge: true }
    );
    return { ok: true };
  }
);

exports.admin_setNoShowDecision = onCall(
  {
    region: REGION,
  },
  async (req) => {
    ensureAdmin(req.auth);
    const pedidoId = String(req.data?.pedidoId || '').trim();
    const decision = String(req.data?.decision || '').trim().toLowerCase();
    if (!pedidoId) throw new HttpsError('invalid-argument', 'pedidoId obrigatório');
    if (!['approved', 'rejected'].includes(decision)) {
      throw new HttpsError('invalid-argument', 'decision inválido');
    }

    await db.collection('pedidos').doc(pedidoId).set(
      {
        noShowDecision: decision,
        noShowDecidedAt: FieldValue.serverTimestamp(),
        noShowDecidedBy: req.auth.uid,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { ok: true };
  }
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
      db.collection('users').where('createdAt', '>=', since30).limit(3000).get(),
      db.collection('users').where('createdAt', '>=', since90).limit(9000).get(),
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
  async (req) => {
    ensureAdmin(req.auth);
    const storyId = String(req.data?.storyId || '').trim();
    if (!storyId) throw new HttpsError('invalid-argument', 'storyId obrigatório');

    await db.collection('stories').doc(storyId).delete();
    return { ok: true };
  }
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
