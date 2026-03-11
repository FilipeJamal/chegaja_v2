const path = require('path');
const { chromium } = require('playwright');

process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.GCLOUD_PROJECT = 'chegaja-ac88d';
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: 'chegaja-ac88d' });

const admin = require(path.join(
  __dirname,
  '..',
  '..',
  'functions',
  'node_modules',
  'firebase-admin',
));
const { Timestamp } = admin.firestore;

if (!admin.apps.length) {
  admin.initializeApp({ projectId: 'chegaja-ac88d' });
}

const db = admin.firestore();
const auth = admin.auth();

const APP_URL = 'http://127.0.0.1:7360';
const OUT_DIR = __dirname;
const CLIENT_NAME = 'Ana Cliente';
const PROVIDER_NAME = 'Carlos Prestador';
const PEDIDO_ID = `ppt-chat-demo-${Date.now()}`;
const PEDIDO_TITULO = 'Reparação torneira cozinha';

async function listAllUsers() {
  const out = [];
  let nextPageToken;
  do {
    const page = await auth.listUsers(1000, nextPageToken);
    out.push(...page.users);
    nextPageToken = page.pageToken;
  } while (nextPageToken);
  return out;
}

async function deleteAllUsers() {
  const users = await listAllUsers();
  if (!users.length) return;
  const ids = users.map((u) => u.uid);
  for (let i = 0; i < ids.length; i += 100) {
    await auth.deleteUsers(ids.slice(i, i + 100));
  }
}

async function waitForUserCount(expectedCount, timeoutMs = 15000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const users = await listAllUsers();
    if (users.length >= expectedCount) return users;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`Timed out waiting for ${expectedCount} auth user(s).`);
}

async function clickButtonByText(page, text) {
  const buttons = page.locator('flt-semantics[role="button"]');
  const count = await buttons.count();
  for (let i = 0; i < count; i += 1) {
    const value = await buttons.nth(i).innerText().catch(() => '');
    if (value.includes(text)) {
      await buttons.nth(i).click({ force: true });
      return;
    }
  }
  throw new Error(`Button not found: ${text}`);
}

async function createRoleSession(page, roleText, homeNeedle) {
  await page.goto(APP_URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500);
  await clickButtonByText(page, roleText);
  await page.waitForFunction(
    (needle) => document.body && document.body.innerText.includes(needle),
    homeNeedle,
    { timeout: 30000 },
  );
  await page.waitForTimeout(3000);
}

async function seedChatData(clientUid, providerUid) {
  const now = Timestamp.now();
  const t1 = Timestamp.fromMillis(Date.now() - 60000);
  const t2 = Timestamp.fromMillis(Date.now() - 30000);

  const batch = db.batch();

  batch.set(
    db.collection('users').doc(clientUid),
    {
      uid: clientUid,
      nome: CLIENT_NAME,
      displayName: CLIENT_NAME,
      name: CLIENT_NAME,
      region: 'PT',
      isAnonymous: true,
      createdAt: now,
      lastLoginAt: now,
      updatedAt: now,
    },
    { merge: true },
  );

  batch.set(
    db.collection('users').doc(providerUid),
    {
      uid: providerUid,
      nome: PROVIDER_NAME,
      displayName: PROVIDER_NAME,
      name: PROVIDER_NAME,
      region: 'PT',
      isAnonymous: true,
      createdAt: now,
      lastLoginAt: now,
      updatedAt: now,
    },
    { merge: true },
  );

  batch.set(
    db.collection('prestadores').doc(providerUid),
    {
      uid: providerUid,
      nome: PROVIDER_NAME,
      displayName: PROVIDER_NAME,
      name: PROVIDER_NAME,
      profissao: 'Canalizador',
      categoria: 'Canalização',
      isOnline: true,
      createdAt: now,
      updatedAt: now,
    },
    { merge: true },
  );

  batch.set(
    db.collection('pedidos').doc(PEDIDO_ID),
    {
      id: PEDIDO_ID,
      titulo: PEDIDO_TITULO,
      pedidoTitulo: PEDIDO_TITULO,
      clienteId: clientUid,
      prestadorId: providerUid,
      status: 'aceite',
      estado: 'aceite',
      categoria: 'Canalização',
      descricao: 'Troca de torneira e verificação de fuga.',
      createdAt: t1,
      updatedAt: now,
    },
    { merge: true },
  );

  batch.set(
    db.collection('chats').doc(PEDIDO_ID),
    {
      pedidoId: PEDIDO_ID,
      pedidoTitulo: PEDIDO_TITULO,
      clienteId: clientUid,
      prestadorId: providerUid,
      clienteNome: CLIENT_NAME,
      prestadorNome: PROVIDER_NAME,
      lastMessage: 'Tudo e você?',
      lastMessageAt: t2,
      lastSenderRole: 'prestador',
      createdAt: t1,
      updatedAt: now,
      hasUnreadCliente: true,
      hasUnreadPrestador: false,
      unreadByCliente: 1,
      unreadByPrestador: 0,
      messageCount: 2,
      favoritedBy: [],
    },
    { merge: true },
  );

  batch.set(
    db.collection('chats').doc(PEDIDO_ID).collection('messages').doc('msg_cliente'),
    {
      pedidoId: PEDIDO_ID,
      text: 'Olá, tudo bem?',
      type: 'text',
      senderRole: 'cliente',
      senderId: clientUid,
      createdAt: t1,
      deliveredToCliente: true,
      deliveredToPrestador: true,
      seenByCliente: true,
      seenByPrestador: true,
    },
    { merge: true },
  );

  batch.set(
    db.collection('chats').doc(PEDIDO_ID).collection('messages').doc('msg_prestador'),
    {
      pedidoId: PEDIDO_ID,
      text: 'Tudo e você?',
      type: 'text',
      senderRole: 'prestador',
      senderId: providerUid,
      createdAt: t2,
      deliveredToCliente: true,
      deliveredToPrestador: true,
      seenByCliente: true,
      seenByPrestador: true,
    },
    { merge: true },
  );

  await batch.commit();
}

async function openMessagesThread(page, otherUserName) {
  await clickButtonByText(page, 'Mensagens');
  await page.waitForFunction(
    (needle) => document.body && document.body.innerText.includes(needle),
    otherUserName,
    { timeout: 30000 },
  );
  await page.waitForTimeout(1500);
  await clickButtonByText(page, otherUserName);
  await page.waitForFunction(
    () =>
      document.body &&
      document.body.innerText.includes('Olá, tudo bem?') &&
      document.body.innerText.includes('Tudo e você?'),
    { timeout: 30000 },
  );
  await page.waitForTimeout(1500);
}

async function main() {
  await deleteAllUsers();

  const browser = await chromium.launch({ headless: true });
  const clientContext = await browser.newContext({ viewport: { width: 1440, height: 1080 } });
  const providerContext = await browser.newContext({ viewport: { width: 1440, height: 1080 } });
  const clientPage = await clientContext.newPage();
  const providerPage = await providerContext.newPage();

  await createRoleSession(clientPage, 'Sou cliente', 'Do que precisas hoje?');
  let users = await waitForUserCount(1);
  const clientUid = users[0].uid;

  await createRoleSession(providerPage, 'Sou prestador', 'Mensagens Guia 3 de 4');
  users = await waitForUserCount(2);
  const providerUid = users.find((u) => u.uid !== clientUid).uid;

  await seedChatData(clientUid, providerUid);
  await clientPage.waitForTimeout(5000);
  await providerPage.waitForTimeout(5000);

  await openMessagesThread(clientPage, PROVIDER_NAME);
  await openMessagesThread(providerPage, CLIENT_NAME);

  await clientPage.screenshot({
    path: path.join(OUT_DIR, 'client_chat_thread.png'),
  });
  await providerPage.screenshot({
    path: path.join(OUT_DIR, 'provider_chat_thread.png'),
  });

  await browser.close();
  console.log(JSON.stringify({
    clientUid,
    providerUid,
    pedidoId: PEDIDO_ID,
    clientShot: path.join(OUT_DIR, 'client_chat_thread.png'),
    providerShot: path.join(OUT_DIR, 'provider_chat_thread.png'),
  }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
