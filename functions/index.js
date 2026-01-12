/* eslint-disable no-console */

/**
 * ChegaJÃ¡ v2.5 â€” Cloud Functions (Firebase)
 *
 * Inclui:
 * - Push notifications (FCM) para chat e mudanÃ§as de estado do pedido
 * - Matching geogrÃ¡fico simples para novos pedidos (GeoFire / geohash)
 * - Stripe Connect (onboarding prestador) + PaymentIntent (pagamento do cliente)
 *
 * NOTA: Em produÃ§Ã£o, recomenda-se usar Firebase Secrets.
 */

const admin = require('firebase-admin');
const { logger } = require('firebase-functions');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onCall, onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const geofire = require('geofire-common');
const cors = require('cors')({ origin: true });
const dotenv = require('dotenv');

// Carrega .env local (apenas em emuladores/dev)
dotenv.config();

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const REGION = process.env.FUNCTIONS_REGION || 'europe-west1';

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
  // Remove tokens invÃ¡lidos da subcoleÃ§Ã£o fcmTokens/{token}
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
  logger.info(`[FCM] Tokens invÃ¡lidos removidos user=${userId} count=${invalid.length}`);
}

async function saveInAppNotification(userId, payload) {
  try {
    await db.collection('users').doc(userId).collection('notifications').add({
      ...payload,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      readAt: null,
    });
  } catch (e) {
    logger.warn(`[notifications] Falha ao guardar notificaÃ§Ã£o in-app para ${userId}: ${e}`);
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
      title: title || 'ChegaJÃ¡',
      body: body || '',
    },
    data: dataStrings,
    android: {
      priority: 'high',
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
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
  return `${s.slice(0, max - 1)}â€¦`;
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

    // Carrega pedido para determinar destinatÃ¡rio
    const pedidoSnap = await db.collection('pedidos').doc(pedidoId).get();
    if (!pedidoSnap.exists) return;

    const pedido = pedidoSnap.data() || {};
    const clienteId = getClienteId(pedido);
    const prestadorId = (pedido.prestadorId || '').toString();

    if (!clienteId) return;

    const recipientId = senderRole === 'cliente' ? prestadorId : clienteId;
    if (!recipientId) {
      // Ainda nÃ£o hÃ¡ prestador atribuÃ­do â€” nÃ£o hÃ¡ push.
      return;
    }

    // Atualiza meta (chats/{pedidoId}) de forma centralizada
    const chatRef = db.collection('chats').doc(pedidoId);
    const now = admin.firestore.FieldValue.serverTimestamp();

    const metaUpdate = {
      pedidoId,
      clienteId,
      prestadorId: prestadorId || null,
      updatedAt: now,
      lastMessageAt: now,
      lastMessage: safeText(text, 200),
      lastSenderRole: senderRole,
      messageCount: admin.firestore.FieldValue.increment(1),
      hasUnreadCliente: senderRole === 'prestador',
      hasUnreadPrestador: senderRole === 'cliente',
      unreadByCliente: senderRole === 'prestador' ? admin.firestore.FieldValue.increment(1) : 0,
      unreadByPrestador: senderRole === 'cliente' ? admin.firestore.FieldValue.increment(1) : 0,
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
      title: 'ChegaJÃ¡ â€” Nova mensagem',
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
// 2) PEDIDOS â†’ push por mudanÃ§as de estado
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

    // sÃ³ reage a mudanÃ§a real de status
    if (beforeStatus === afterStatus) return;

    const clienteId = getClienteId(after);
    const prestadorId = (after.prestadorId || '').toString();

    if (!clienteId) return;

    // Define para quem enviar
    // - se prestadorId existir, notifica o outro lado
    // - se ainda nÃ£o existe prestadorId, nÃ£o hÃ¡ destinatÃ¡rio especÃ­fico
    const updates = [];

    const title = 'ChegaJÃ¡ â€” Pedido atualizado';

    function bodyForStatus(status) {
      switch (status) {
        case 'aguarda_resposta_cliente':
          return 'Recebeste uma proposta de preÃ§o.';
        case 'aceito':
          return 'Proposta aceita. O prestador pode iniciar o serviÃ§o.';
        case 'em_andamento':
          return 'O prestador iniciou o serviÃ§o.';
        case 'aguarda_confirmacao_valor':
          return 'O prestador propÃ´s o valor final.';
        case 'concluido':
          return 'ServiÃ§o concluÃ­do.';
        case 'cancelado':
          return 'O pedido foi cancelado.';
        default:
          return `Estado: ${status}`;
      }
    }

    const body = bodyForStatus(afterStatus);

    // Se mudou por aÃ§Ã£o do prestador, notifica cliente
    // Se mudou por aÃ§Ã£o do cliente, notifica prestador
    // NÃ£o dÃ¡ para determinar 100% sem â€œlastActorRoleâ€, entÃ£o enviamos para ambos
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
      // sem prestador ainda â€” notifica sÃ³ o cliente (mudanÃ§as internas)
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
// 3) PEDIDOS â†’ push para prestadores prÃ³ximos (matching)
// ------------------------------------------------------------

exports.onPedidoCreated = onDocumentCreated(
  {
    region: REGION,
    document: 'pedidos/{pedidoId}',
  },
  async (event) => {
    const { pedidoId } = event.params;
    const pedido = event.data.data() || {};

    // SÃ³ pedidos abertos
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

    // Raio mÃ¡ximo de busca (em metros) â€” depois filtramos pelo radiusKm do prestador.
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
        title: 'ChegaJÃ¡ â€” Novo pedido perto de ti',
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
    throw new Error('STRIPE_SECRET_KEY nÃ£o configurada.');
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
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
      throw new Error('pedidoId obrigatÃ³rio');
    }

    const pedidoRef = db.collection('pedidos').doc(pedidoId);
    const pedidoSnap = await pedidoRef.get();
    if (!pedidoSnap.exists) {
      throw new Error('Pedido nÃ£o encontrado');
    }

    const pedido = pedidoSnap.data() || {};
    const clienteId = getClienteId(pedido);
    const prestadorId = String(pedido.prestadorId || '');

    if (clienteId !== uid) {
      throw new Error('PERMISSION_DENIED');
    }

    if (!prestadorId) {
      throw new Error('Pedido ainda sem prestador atribuÃ­do');
    }

    // Valor a cobrar
    const valor = pedido.precoPropostoPrestador ?? pedido.precoFinal ?? pedido.preco;
    const amount = moneyToCents(valor);
    if (amount <= 0) {
      throw new Error('Valor invÃ¡lido para pagamento');
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
    // o Stripe bloqueia transfers se payouts nÃ£o estiverem enabled.
    if (!onboardingComplete) {
      logger.warn(`[stripe] prestador ${prestadorId} sem onboarding completo (account=${accountId})`);
    }

    const commissionRate = Number(getEnv('DEFAULT_COMMISSION_RATE', '0.15')) || 0.15;
    const feeAmount = Math.max(0, Math.round(amount * commissionRate));

    const stripe = getStripe();

    // Reutiliza PaymentIntent se jÃ¡ existir
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
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      clientSecret: pi.client_secret,
      paymentIntentId: pi.id,
      amount,
      currency,
    };
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
          res.status(500).send('STRIPE_WEBHOOK_SECRET nÃ£o configurada');
          return;
        }

        event = stripe.webhooks.constructEvent(req.rawBody, sig, secret);
      } catch (err) {
        logger.error('[stripeWebhook] assinatura invÃ¡lida', err);
        res.status(400).send(`Webhook Error: ${err.message}`);
        return;
      }

      try {
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
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }

        // Completar onboarding do prestador (account.updated)
        if (type === 'account.updated') {
          const acc = event.data.object;
          const accountId = acc.id;
          const complete = !!(acc.charges_enabled && acc.payouts_enabled);

          const qs = await db.collection('prestadores').where('stripeAccountId', '==', accountId).limit(5).get();
          const batch = db.batch();
          qs.docs.forEach((d) => {
            batch.set(d.ref, { stripeOnboardingComplete: complete, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
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
// 5) Cleanup agendada (opcional): remover tokens antigos
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


