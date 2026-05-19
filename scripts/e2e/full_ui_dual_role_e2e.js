const fs = require('fs');
const http = require('http');
const https = require('https');
const os = require('os');
const path = require('path');
const { chromium } = require('playwright');

let admin;
try {
  admin = require(path.join(process.cwd(), 'functions', 'node_modules', 'firebase-admin'));
} catch (error) {
  console.error('Missing firebase-admin at functions/node_modules/firebase-admin');
  console.error('Run: cd functions && npm install');
  process.exit(1);
}

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
}

const PROJECT_ID = process.env.PROJECT_ID || 'chegaja-ac88d';
const TARGET_URL = process.env.TARGET_URL || 'http://localhost:5173';
const RUN_ID = new Date().toISOString().replace(/[:.]/g, '-');
const SHOT_ROOT = process.env.SHOT_DIR || path.join(os.tmpdir(), 'chegaja-e2e-full-ui');
const SHOT_DIR = path.join(SHOT_ROOT, RUN_ID);
const PROVIDER_NAME = process.env.E2E_PROVIDER_NAME || `Prestador E2E ${RUN_ID.slice(-6)}`;
const SCENARIO = resolveScenario(process.argv.slice(2), process.env.E2E_SCENARIO || 'full');

let serviceCatalogCache = null;

if (admin.apps.length === 0) {
  admin.initializeApp({ projectId: PROJECT_ID });
}
const db = admin.firestore();
fs.mkdirSync(SHOT_DIR, { recursive: true });

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const now = () => new Date().toISOString().slice(11, 19);

function resolveScenario(args, fallback) {
  const allowed = new Set(['full', 'orcamento']);
  let scenario = fallback || 'full';

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === '--scenario' && args[index + 1]) {
      scenario = args[index + 1];
      index += 1;
    } else if (arg.startsWith('--scenario=')) {
      scenario = arg.slice('--scenario='.length);
    }
  }

  scenario = `${scenario}`.trim().toLowerCase();
  if (!allowed.has(scenario)) {
    throw new Error(`Unsupported E2E scenario "${scenario}". Use one of: ${[...allowed].join(', ')}`);
  }
  return scenario;
}

function probeUrl(urlString, timeoutMs = 2500) {
  return new Promise((resolve) => {
    let resolved = false;
    let url;

    try {
      url = new URL(urlString);
    } catch (_) {
      resolve(false);
      return;
    }

    const lib = url.protocol === 'https:' ? https : http;
    const req = lib.request(
      {
        protocol: url.protocol,
        hostname: url.hostname,
        port: url.port || (url.protocol === 'https:' ? 443 : 80),
        path: '/',
        method: 'GET',
      },
      (res) => {
        if (resolved) return;
        resolved = true;
        res.resume();
        resolve(true);
      },
    );

    req.on('error', () => {
      if (resolved) return;
      resolved = true;
      resolve(false);
    });

    req.setTimeout(timeoutMs, () => {
      if (resolved) return;
      resolved = true;
      req.destroy();
      resolve(false);
    });

    req.end();
  });
}

async function ensureTargetUrlReady() {
  const timeoutMs = Number(process.env.TARGET_WAIT_TIMEOUT_MS || 45000);
  const start = Date.now();

  while (Date.now() - start < timeoutMs) {
    const ok = await probeUrl(TARGET_URL);
    if (ok) return;
    await sleep(1000);
  }

  let flutterHint = 'flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173';
  try {
    const u = new URL(TARGET_URL);
    const port = u.port || (u.protocol === 'https:' ? '443' : '80');
    flutterHint = `flutter run -d web-server --web-hostname=127.0.0.1 --web-port=${port}`;
  } catch (_) {}

  throw new Error(
    [
      `Target app not reachable at ${TARGET_URL}.`,
      `Start your web app first and retry.`,
      `Example: ${flutterHint}`,
      `Or set TARGET_URL to the running app URL.`,
    ].join(' '),
  );
}

async function configureContext(context) {
  // Keep the browser network behavior close to real users.
  // Blocking Flutter web font fetches makes text rendering and semantics flaky.
}

function escapeRegExp(input) {
  return String(input).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function tsMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (value._seconds != null) return value._seconds * 1000;
  if (value.seconds != null) return value.seconds * 1000;
  return 0;
}

function asNumber(value) {
  if (value == null) return null;
  const number = Number(value);
  return Number.isFinite(number) ? number : null;
}

function near(value, expected, tolerance = 0.001) {
  const number = asNumber(value);
  return number != null && Math.abs(number - expected) <= tolerance;
}

function hasHistoryEvent(data, eventName) {
  return Array.isArray(data?.historico) && data.historico.some((item) => `${item?.evento || ''}` === eventName);
}

function isOrcamentoQuotePending(data, providerUid) {
  return (
    data &&
    (data.estado || data.status) === 'aguarda_resposta_cliente' &&
    data.prestadorId === providerUid &&
    data.tipoPreco === 'por_orcamento' &&
    data.statusProposta === 'pendente_cliente' &&
    near(data.valorMinEstimadoPrestador, 20) &&
    near(data.valorMaxEstimadoPrestador, 35) &&
    hasHistoryEvent(data, 'proposta_enviada')
  );
}

function isOrcamentoAccepted(data) {
  return (
    data &&
    (data.estado || data.status) === 'aceito' &&
    data.tipoPreco === 'por_orcamento' &&
    data.statusProposta === 'aceita_cliente' &&
    near(data.valorMinEstimadoPrestador, 20) &&
    near(data.valorMaxEstimadoPrestador, 35) &&
    hasHistoryEvent(data, 'proposta_aceita')
  );
}

function isOrcamentoFinalPending(data) {
  return (
    data &&
    (data.estado || data.status) === 'aguarda_confirmacao_valor' &&
    data.statusConfirmacaoValor === 'pendente_cliente' &&
    data.statusProposta === 'aceita_cliente' &&
    near(data.precoPropostoPrestador, 30) &&
    near(data.valorMinEstimadoPrestador, 20) &&
    near(data.valorMaxEstimadoPrestador, 35) &&
    hasHistoryEvent(data, 'valor_proposto')
  );
}

function isOrcamentoConcluido(data) {
  return (
    data &&
    (data.estado || data.status) === 'concluido' &&
    data.tipoPreco === 'por_orcamento' &&
    data.statusProposta === 'aceita_cliente' &&
    data.statusConfirmacaoValor === 'confirmado_cliente' &&
    near(data.valorMinEstimadoPrestador, 20) &&
    near(data.valorMaxEstimadoPrestador, 35) &&
    near(data.precoFinal, 30) &&
    near(data.preco, 30) &&
    near(data.commissionPlatform, 4.5) &&
    near(data.earningsProvider, 25.5) &&
    near(data.earningsTotal, 30) &&
    hasHistoryEvent(data, 'concluido')
  );
}

function uniqueNonEmpty(list) {
  return [...new Set((list || []).map((v) => `${v || ''}`.trim()).filter(Boolean))];
}

function normalizeRole(value) {
  return `${value || ''}`.trim().toLowerCase();
}

function readServiceName(data = {}) {
  const preferredLang = (process.env.E2E_LANG || 'pt').trim().toLowerCase();
  const nameI18n = data.name_i18n;
  if (nameI18n && typeof nameI18n === 'object') {
    const direct = nameI18n[preferredLang];
    if (typeof direct === 'string' && direct.trim()) return direct.trim();
    const fallbackLangs = ['pt', 'en', 'es', 'fr', 'de'];
    for (const lang of fallbackLangs) {
      const v = nameI18n[lang];
      if (typeof v === 'string' && v.trim()) return v.trim();
    }
    for (const v of Object.values(nameI18n)) {
      if (typeof v === 'string' && v.trim()) return v.trim();
    }
  }

  const raw = data.name ?? data.nome ?? data.title ?? data.label ?? data.servicoNome ?? null;
  if (typeof raw === 'string') return raw.trim();
  if (raw && typeof raw === 'object') {
    const candidates = [raw.pt, raw.en, raw.name, raw.label].filter((v) => typeof v === 'string' && v.trim());
    if (candidates.length) return candidates[0].trim();
    for (const value of Object.values(raw)) {
      if (typeof value === 'string' && value.trim()) return value.trim();
    }
  }
  return null;
}

function loadServiceCatalogFromJsonFile() {
  const candidates = [
    path.join(process.cwd(), 'scripts', 'servicos_seed.json'),
    path.join(process.cwd(), 'functions', 'servicos_seed.json'),
  ];

  for (const file of candidates) {
    try {
      if (!fs.existsSync(file)) continue;
      const raw = fs.readFileSync(file, 'utf8');
      const arr = JSON.parse(raw);
      if (!Array.isArray(arr)) continue;

      const ids = [];
      const names = [];
      for (const item of arr) {
        if (!item || typeof item !== 'object') continue;
        if (item.id != null) ids.push(String(item.id));
        const name = readServiceName(item);
        if (name) names.push(name);
      }

      return {
        ids: uniqueNonEmpty(ids),
        names: uniqueNonEmpty(names),
      };
    } catch (_) {}
  }

  return null;
}

async function loadServiceCatalog() {
  if (serviceCatalogCache) return serviceCatalogCache;

  try {
    const snap = await db.collection('servicos').get();
    const ids = [];
    const names = [];

    for (const doc of snap.docs) {
      ids.push(doc.id);
      const name = readServiceName(doc.data());
      if (name) names.push(name);
    }

    const cleanIds = uniqueNonEmpty(ids);
    const cleanNames = uniqueNonEmpty(names);
    if (cleanIds.length || cleanNames.length) {
      serviceCatalogCache = {
        ids: cleanIds,
        names: cleanNames,
      };
      return serviceCatalogCache;
    }

    const fileCatalog = loadServiceCatalogFromJsonFile();
    if (fileCatalog) {
      serviceCatalogCache = fileCatalog;
      return serviceCatalogCache;
    }

    serviceCatalogCache = {
      ids: [],
      names: ['Assentamento de anexos', 'Bolos personalizados', 'Cake designer', 'Caricaturista'],
    };
    return serviceCatalogCache;
  } catch (_) {
    const fileCatalog = loadServiceCatalogFromJsonFile();
    if (fileCatalog) {
      serviceCatalogCache = fileCatalog;
      return serviceCatalogCache;
    }
    serviceCatalogCache = {
      ids: [],
      names: ['Assentamento de anexos', 'Bolos personalizados', 'Cake designer', 'Caricaturista'],
    };
    return serviceCatalogCache;
  }
}

function buildServiceNameRegex(names = []) {
  const fallbackNames = [
    'Assentamento de anexos',
    'Assentamento de anexos exterior',
    'Assentamento de anexos interior',
    'Bolos personalizados',
    'Cake designer',
    'Caricaturista',
  ];
  const candidates = uniqueNonEmpty([...names, ...fallbackNames]).slice(0, 24);

  return new RegExp(candidates.map((name) => escapeRegExp(name)).join('|'), 'i');
}

async function setProviderState(providerUid, patch) {
  await db
    .collection('prestadores')
    .doc(providerUid)
    .set(
      {
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        ...patch,
      },
      { merge: true },
    );
}

async function seedProviderBase(providerUid, { online = true, serviceId = null, serviceName = null } = {}) {
  const catalog = await loadServiceCatalog();
  const manualScenarioCategories = [
    'Assentamento de anexos',
    '_custom_Assentamento de anexos',
    'Assentamento de anexos interior',
    '_custom_Assentamento de anexos interior',
    'Assentamento de anexos exterior',
    '_custom_Assentamento de anexos exterior',
    'svc_assentamento de anexos_oqv4yo',
    'svc_assentamento de anexos interior_16p5oog',
    'svc_assentamento de anexos exterior_2t63lm',
  ];

  // Keep provider docs lean; overly large arrays make selector query unstable/flaky in emulator.
  const dynamicCategories = uniqueNonEmpty([
    serviceId,
    serviceName,
    serviceName ? serviceName.toLowerCase() : null,
    serviceName ? `_custom_${serviceName}` : null,
    ...manualScenarioCategories,
    ...catalog.ids.slice(0, 20),
  ]).slice(0, 60);

  const servicos = uniqueNonEmpty([serviceId, ...dynamicCategories, ...catalog.ids.slice(0, 20)]).slice(0, 80);
  const servicosNomes = uniqueNonEmpty([serviceName, ...catalog.names.slice(0, 40)]).slice(0, 80);

  await setProviderState(providerUid, {
    nome: PROVIDER_NAME,
    displayName: PROVIDER_NAME,
    isOnline: online,
    available: online,
    categories: dynamicCategories.slice(0, 6000),
    servicos: uniqueNonEmpty([...servicos, ...dynamicCategories]).slice(0, 6000),
    servicosNomes,
    radiusKm: 9999,
    lastLocation: { lat: 38.7223, lng: -9.1393 },
    city: 'Lisboa',
    state: 'Lisboa',
    country: 'Portugal',
    ratingAvg: 4.9,
    ratingCount: 99,
  });
}

async function waitPedidoWhere(pedidoId, label, predicate, timeoutMs = 60000) {
  const start = Date.now();
  let last = null;

  while (Date.now() - start < timeoutMs) {
    const data = await getPedido(pedidoId);
    last = data;
    const ok = data ? await Promise.resolve(predicate(data)) : false;
    if (ok) return data;
    await sleep(900);
  }

  throw new Error(`Timeout waiting ${label} for pedido=${pedidoId} lastEstado=${last?.estado || 'null'}`);
}

async function chatMessagesForPedido(pedidoId) {
  const qs = await db.collection('chats').doc(pedidoId).collection('messages').orderBy('createdAt', 'asc').get();
  return qs.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function shot(page, name) {
  const fullPath = path.join(SHOT_DIR, `${name}.png`);
  try {
    await page.screenshot({ path: fullPath, fullPage: true, timeout: 15000 });
    return;
  } catch (error) {
    try {
      await page.screenshot({ path: fullPath, fullPage: false, timeout: 5000, animations: 'disabled' });
      return;
    } catch (_) {
      try {
        const cdp = await page.context().newCDPSession(page);
        const { data } = await cdp.send('Page.captureScreenshot', {
          format: 'png',
          fromSurface: true,
          captureBeyondViewport: true,
        });
        fs.writeFileSync(fullPath, Buffer.from(data, 'base64'));
        await cdp.detach().catch(() => {});
        return;
      } catch (_) {}
      console.warn(`[${now()}] WARN screenshot failed (${name}): ${error.message || error}`);
    }
  }
}

function attachPageDiagnostics(page, label) {
  page.on('pageerror', (error) => {
    console.log(`[${now()}] ${label} pageerror: ${error?.message || error}`);
  });

  page.on('console', (msg) => {
    const type = msg.type();
    const text = msg.text();
    if (!text) return;

    if (
      /fonts\.gstatic\.com|Failed to load font|Flutter Web engine failed to complete HTTP request to fetch|Google Maps JavaScript API has been loaded directly/i.test(
        text,
      )
    ) {
      return;
    }

    const interesting =
      type === 'error' ||
      type === 'warning' ||
      /firestore|firebase|permission|denied|failed|exception|error/i.test(text);
    if (/^Failed to load resource: net::ERR_FAILED$/i.test(text)) return;
    if (!interesting) return;

    console.log(`[${now()}] ${label} console.${type}: ${text}`);
  });

  page.on('requestfailed', (request) => {
    const url = request.url();
    const failure = request.failure();
    if (
      /google\.firestore\.v1\.Firestore\/Write\/channel/i.test(url) &&
      /ERR_ABORTED/i.test(failure?.errorText || '')
    ) {
      return;
    }
    if (!/googleapis|firestore|identitytoolkit|securetoken|127\.0\.0\.1:8080|127\.0\.0\.1:9099/i.test(url)) {
      return;
    }
    console.log(
      `[${now()}] ${label} requestfailed: ${request.method()} ${url} ${failure?.errorText || 'unknown'}`,
    );
  });
}

async function waitForFlutterMounted(page, role, timeoutMs = Number(process.env.FLUTTER_MOUNT_TIMEOUT_MS || 120000)) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const hasFlutterDom = await page
      .locator('flt-glass-pane, flt-semantics-host, flutter-view')
      .first()
      .isVisible()
      .catch(() => false);
    if (hasFlutterDom) return true;

    await sleep(400);
  }

  const bodyText = await page.locator('body').innerText().catch(() => '');
  throw new Error(
    [
      `Flutter UI not mounted for role=${role} at ${page.url()}.`,
      `body=${bodyText.slice(0, 180).replace(/\s+/g, ' ')}`,
      `Tip: run Flutter web on a fixed port (e.g. flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173)`,
      `or set TARGET_URL to the exact running URL.`,
    ].join(' '),
  );
}

async function readUid(page) {
  return await page.evaluate(async () => {
    function tryParse(value) {
      if (typeof value !== 'string') return value;
      try {
        return JSON.parse(value);
      } catch (_) {
        return value;
      }
    }

    function extractUid(entry) {
      const parsed = tryParse(entry);
      if (!parsed || typeof parsed !== 'object') return null;
      return parsed?.uid || parsed?.value?.uid || null;
    }

    function readStorage(storage) {
      const entries = [];
      for (let i = 0; i < storage.length; i++) {
        const key = storage.key(i);
        if (!key) continue;
        entries.push({
          key,
          value: storage.getItem(key),
        });
      }
      return entries;
    }

    function readIndexedDbEntries() {
      return new Promise((resolve) => {
        const req = indexedDB.open('firebaseLocalStorageDb');
        req.onerror = () => resolve([]);
        req.onsuccess = () => {
          try {
            const idb = req.result;
            const tx = idb.transaction('firebaseLocalStorage', 'readonly');
            const store = tx.objectStore('firebaseLocalStorage');
            const all = store.getAll();
            all.onerror = () => resolve([]);
            all.onsuccess = () => resolve(all.result || []);
          } catch (_) {
            resolve([]);
          }
        };
      });
    }

    const storageEntries = [
      ...readStorage(localStorage),
      ...readStorage(sessionStorage),
    ];
    for (const item of storageEntries) {
      const uid = extractUid(item?.value);
      if (uid) return uid;
    }

    const indexedDbEntries = await readIndexedDbEntries();
    for (const item of indexedDbEntries) {
      const uid = extractUid(item);
      if (uid) return uid;
    }

    return null;
  });
}

async function waitStableUid(page, timeoutMs = 120000) {
  const start = Date.now();
  let last = null;
  let stable = 0;

  while (Date.now() - start < timeoutMs) {
    const uid = await readUid(page).catch(() => null);
    if (uid && uid === last) {
      stable += 1;
      if (stable >= 2) return uid;
    } else {
      last = uid;
      stable = uid ? 1 : 0;
    }
    await sleep(1200);
  }

  return last;
}

async function tryClick(root, rx, timeout = 900) {
  const candidates = [
    root.getByRole('button', { name: rx }).first(),
    root.locator('button', { hasText: rx }).first(),
    root.locator('[role="button"]', { hasText: rx }).first(),
    root.locator('flt-semantics[role="button"]', { hasText: rx }).first(),
    root.getByText(rx).first(),
    root.locator('flt-semantics', { hasText: rx }).first(),
  ];

  for (const candidate of candidates) {
    try {
      await candidate.click({ force: true, timeout });
      return true;
    } catch (_) {}
  }

  return false;
}

async function waitAndClick(root, rx, timeoutMs = 30000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (await tryClick(root, rx, 1000)) return true;
    await sleep(350);
  }
  return false;
}

async function clickVisibleTextCenter(page, rx) {
  const best = await page.evaluate(
    ({ source, flags }) => {
      let re = null;
      try {
        re = new RegExp(source, flags.includes('i') ? 'i' : '');
      } catch (_) {
        return null;
      }

      const seen = new Set();
      const nodes = [];
      const selectors = [
        'flt-semantics[role="button"]',
        'button',
        '[role="button"]',
        'flt-semantics',
        'div',
        'span',
      ];

      for (const selector of selectors) {
        for (const element of document.querySelectorAll(selector)) {
          if (seen.has(element)) continue;
          seen.add(element);

          const text = ((element.innerText || element.textContent || '') + '').replace(/\s+/g, ' ').trim();
          if (!text || !re.test(text)) continue;

          const rect = element.getBoundingClientRect();
          const style = getComputedStyle(element);
          const visible =
            rect.width >= 24 &&
            rect.height >= 18 &&
            style.display !== 'none' &&
            style.visibility !== 'hidden' &&
            style.pointerEvents !== 'none' &&
            parseFloat(style.opacity || '1') > 0;
          if (!visible) continue;

          const x = rect.left + rect.width / 2;
          const y = rect.top + rect.height / 2;
          if (x < 2 || y < 2 || x > window.innerWidth - 2 || y > window.innerHeight - 2) continue;

          nodes.push({
            x: Math.round(x),
            y: Math.round(y),
            area: rect.width * rect.height,
            top: rect.top,
          });
        }
      }

      if (!nodes.length) return null;

      nodes.sort((a, b) => {
        if (b.area !== a.area) return b.area - a.area;
        return a.top - b.top;
      });

      const ctaLike = nodes.find(
        (n) => n.x > window.innerWidth * 0.2 && n.x < window.innerWidth * 0.8 && n.y > 120 && n.y < window.innerHeight * 0.75,
      );

      return ctaLike || nodes[0];
    },
    { source: rx.source, flags: rx.flags || '' },
  );

  if (!best) return false;
  await page.mouse.click(best.x, best.y);
  return true;
}

async function clickVisibleServiceCard(page, rx) {
  const domBest = await page.evaluate(
    ({ source, flags }) => {
      let re = null;
      try {
        re = new RegExp(source, flags.includes('i') ? 'i' : '');
      } catch (_) {
        return null;
      }

      const seen = new Set();
      const nodes = [];
      const selectors = ['flt-semantics[role="button"]', '[role="button"]', 'flt-semantics', 'div', 'span'];

      for (const selector of selectors) {
        for (const element of document.querySelectorAll(selector)) {
          if (seen.has(element)) continue;
          seen.add(element);

          const text = ((element.innerText || element.textContent || '') + '').replace(/\s+/g, ' ').trim();
          if (!text || !re.test(text)) continue;

          const rect = element.getBoundingClientRect();
          const style = getComputedStyle(element);
          const visible =
            rect.width >= 240 &&
            rect.height >= 48 &&
            rect.height <= 160 &&
            rect.top >= 160 &&
            rect.bottom <= window.innerHeight - 60 &&
            style.display !== 'none' &&
            style.visibility !== 'hidden' &&
            style.pointerEvents !== 'none' &&
            parseFloat(style.opacity || '1') > 0;
          if (!visible) continue;

          nodes.push({
            x: Math.round(rect.left + rect.width / 2),
            y: Math.round(rect.top + rect.height / 2),
            top: rect.top,
            width: rect.width,
            height: rect.height,
            role: element.getAttribute('role') || '',
          });
        }
      }

      if (!nodes.length) return null;

      nodes.sort((a, b) => {
        const aRoleScore = a.role === 'button' ? 0 : 1;
        const bRoleScore = b.role === 'button' ? 0 : 1;
        if (aRoleScore !== bRoleScore) return aRoleScore - bRoleScore;
        if (a.top !== b.top) return a.top - b.top;
        return b.width * b.height - a.width * a.height;
      });

      return nodes[0];
    },
    { source: rx.source, flags: rx.flags || '' },
  );

  if (domBest) {
    await page.mouse.click(domBest.x, domBest.y);
    return true;
  }

  const locatorGroups = [
    page.locator('flt-semantics[role="button"]', { hasText: rx }),
    page.getByRole('button', { name: rx }),
    page.locator('[role="button"]', { hasText: rx }),
  ];

  for (const group of locatorGroups) {
    const count = await group.count().catch(() => 0);
    for (let i = 0; i < Math.min(count, 8); i++) {
      const candidate = group.nth(i);
      try {
        const visible = await candidate.isVisible({ timeout: 700 }).catch(() => false);
        if (!visible) continue;

        const box = await candidate.boundingBox().catch(() => null);
        if (!box || box.width < 160 || box.height < 48) continue;
        if (box.y < 160 || box.y > 620) continue;

        await candidate.click({ force: true, timeout: 1500 });
        return true;
      } catch (_) {}
    }
  }

  const viewport = page.viewportSize() || { width: 1280, height: 720 };
  const fallbackPoints = [
    { x: Math.round(viewport.width / 2), y: 333 },
    { x: Math.round(viewport.width / 2), y: 427 },
    { x: Math.round(viewport.width / 2), y: 512 },
  ];

  for (const point of fallbackPoints) {
    await page.mouse.click(point.x, point.y).catch(() => {});
    await page.waitForTimeout(500);
    if (await isOnOrderForm(page)) return true;
  }

  return false;
}

async function tryConfirmDialogs(page) {
  await tryClick(page, /Confirmar|Confirm|Sim|Yes|Iniciar agora|Start now/i, 600);
  await tryClick(page, /OK|Entendido|Fechar|Close/i, 600);
}

async function scrollToBottom(page, steps = 8) {
  for (let i = 0; i < steps; i++) {
    await page.mouse.wheel(0, 500).catch(() => {});
    await sleep(180);
  }
}

async function fillAnyVisibleField(page, value) {
  const candidates = [
    page.locator('input:not([readonly]):visible').first(),
    page.locator('input:visible').first(),
    page.locator('textarea:not([readonly]):visible').first(),
    page.locator('[role="textbox"]').first(),
    page.locator('flt-semantics[role="textbox"]').first(),
  ];

  for (const candidate of candidates) {
    try {
      const visible = await candidate.isVisible({ timeout: 600 }).catch(() => false);
      if (!visible) continue;
      await candidate.click({ force: true, timeout: 800 });
      await page.keyboard.press('Control+A').catch(() => {});
      await page.keyboard.type(value);
      return true;
    } catch (_) {}
  }

  return false;
}

async function fillField(locator, page, value) {
  await locator.click({ force: true });
  await page.keyboard.press('Control+A');
  await page.keyboard.type(value);
}

async function fillFirstTextbox(page, value) {
  const candidates = [
    page.locator('textarea:visible').first(),
    page.locator('input[type="text"]:visible').first(),
    page.locator('input:visible').first(),
    page.locator('[role="textbox"]').first(),
    page.locator('flt-semantics[role="textbox"]').first(),
  ];

  for (const candidate of candidates) {
    try {
      const visible = await candidate.isVisible({ timeout: 700 }).catch(() => false);
      if (!visible) continue;
      await fillField(candidate, page, value);
      return true;
    } catch (_) {}
  }

  return false;
}

async function clickNearInputSend(page) {
  const textbox = page.locator('textarea:visible, input[type="text"]:visible, input:visible').first();
  const isVisible = await textbox.isVisible({ timeout: 900 }).catch(() => false);
  if (!isVisible) return false;

  const box = await textbox.boundingBox();
  if (!box) return false;

  const x = Math.round(Math.min(box.x + box.width + 34, 1260));
  const y = Math.round(box.y + box.height / 2);
  await page.mouse.click(x, y).catch(() => {});
  return true;
}

async function isQuoteDialogOpen(page) {
  const hasTitle = await page
    .getByText(/Enviar estimativa|Enviar or.amento|Propor servi.o/i)
    .first()
    .isVisible()
    .catch(() => false);
  const hasMin = await page.getByText(/Valor m[ií]nimo/i).first().isVisible().catch(() => false);
  return hasTitle && hasMin;
}

async function dismissQuoteDialog(page) {
  for (let i = 0; i < 6; i++) {
    const open = await isQuoteDialogOpen(page);
    if (!open) return true;

    let closed = await tryClick(page, /Cancelar|Close|Fechar/i, 900);
    if (!closed) {
      closed = await clickVisibleTextCenter(page, /Cancelar|Close|Fechar/i);
    }
    if (!closed) {
      await page.keyboard.press('Escape').catch(() => {});
      await sleep(250);
    }
    if (await isQuoteDialogOpen(page)) {
      const dialog = page.locator('[role="dialog"]:visible').first();
      const box = await dialog.boundingBox().catch(() => null);
      if (box) {
        const cancelX = Math.round(box.x + box.width * 0.48);
        const cancelY = Math.round(box.y + box.height * 0.9);
        await page.mouse.click(cancelX, cancelY).catch(() => {});
        await sleep(250);
      }
    }
    if (await isQuoteDialogOpen(page)) {
      await page.mouse.click(40, 40).catch(() => {});
      await sleep(250);
    }
    await sleep(350);
  }
  return !(await isQuoteDialogOpen(page));
}

async function closeAllOverlays(page) {
  // Best effort: dismiss known modal dialogs that can steal focus and hide chat controls.
  for (let i = 0; i < 10; i++) {
    let changed = false;
    const hadQuoteDialog = await isQuoteDialogOpen(page);
    if (hadQuoteDialog) {
      await dismissQuoteDialog(page);
      changed = true;
    }

    const hasDialog = await page.locator('[role="dialog"]:visible').first().isVisible().catch(() => false);
    if (hasDialog) {
      const clickedClose =
        (await tryClick(page, /Cancelar|Fechar|Close|OK|Entendido|Voltar/i, 800)) ||
        (await clickVisibleTextCenter(page, /Cancelar|Fechar|Close|OK|Entendido|Voltar/i));
      if (!clickedClose) {
        await page.keyboard.press('Escape').catch(() => {});
      }
      changed = true;
    }

    if (!changed) break;
    await sleep(220);
  }
}

async function chatComposerVisible(page) {
  if (await isQuoteDialogOpen(page)) return false;

  const byPlaceholder = await page
    .getByPlaceholder(/mensagem|message|escreve|write/i)
    .first()
    .isVisible()
    .catch(() => false);
  if (byPlaceholder) return true;

  const genericTextarea = await page.locator('textarea:visible').first().isVisible().catch(() => false);
  if (genericTextarea) return true;

  return false;
}

async function fillChatComposer(page, value) {
  if (await isQuoteDialogOpen(page)) {
    const closed = await dismissQuoteDialog(page);
    if (!closed) return false;
  }

  const candidates = [
    page.getByPlaceholder(/mensagem|message|escreve|write/i).first(),
    page.locator('textarea[placeholder]:visible').first(),
    page.locator('input[placeholder]:visible').first(),
    page.locator('textarea:visible').first(),
  ];

  for (const candidate of candidates) {
    try {
      const visible = await candidate.isVisible({ timeout: 700 }).catch(() => false);
      if (!visible) continue;
      await fillField(candidate, page, value);
      return true;
    } catch (_) {}
  }
  return false;
}

async function isManualProviderMode(page) {
  const manualCta = await page
    .getByText(/Pesquisar prestadores|Trocar prestador|Nenhum prestador selecionado/i)
    .first()
    .isVisible()
    .catch(() => false);
  if (manualCta) return true;
  return false;
}

async function clickManualSegmentDom(page) {
  return await page.evaluate(() => {
    const textOf = (el) => ((el.innerText || el.textContent || '') + '').replace(/\s+/g, ' ').trim();
    const candidates = [];
    const selectors = ['button', '[role="button"]', 'flt-semantics', 'div', 'span'];
    for (const selector of selectors) {
      for (const el of document.querySelectorAll(selector)) {
        const text = textOf(el);
        if (text !== 'Manual') continue;
        const rect = el.getBoundingClientRect();
        if (rect.width < 24 || rect.height < 18) continue;
        if (rect.top < 0 || rect.top > window.innerHeight - 20) continue;
        candidates.push({ el, top: rect.top, area: rect.width * rect.height });
      }
    }
    if (!candidates.length) return false;
    candidates.sort((a, b) => {
      if (a.top !== b.top) return a.top - b.top;
      return b.area - a.area;
    });
    const target = candidates[0].el;
    target.click();
    return true;
  });
}

async function switchToManualProviderMode(page) {
  if (await isManualProviderMode(page)) return true;

  for (let i = 0; i < 8; i++) {
    await waitAndClick(page, /Manual/i, 1800);
    if (await isManualProviderMode(page)) return true;

    await clickVisibleTextCenter(page, /Manual/i);
    if (await isManualProviderMode(page)) return true;

    await clickManualSegmentDom(page).catch(() => false);
    await sleep(350);
    if (await isManualProviderMode(page)) return true;

    // Coordinate fallback for top "Encontrar prestador" segmented control.
    await page.mouse.click(950, 370).catch(() => {});
    await sleep(450);
    if (await isManualProviderMode(page)) return true;
  }

  return false;
}

async function isOnProviderSelector(page) {
  return await page.getByText(/Selecionar prestador/i).first().isVisible().catch(() => false);
}

async function waitForProviderSelector(page, timeoutMs = 30000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (await isOnProviderSelector(page)) return true;

    const searchInputVisible = await page
      .locator('input[placeholder*="Pesquisar prestador"], input:visible')
      .first()
      .isVisible()
      .catch(() => false);
    if (searchInputVisible) return true;

    await sleep(500);
  }
  return false;
}

async function isOnOrderForm(page) {
  const inputVisible = await page.locator('input:not([readonly]):visible').first().isVisible().catch(() => false);
  const textAreaVisible = await page.locator('textarea:not([readonly]):visible').first().isVisible().catch(() => false);
  if (inputVisible && textAreaVisible) return true;

  const submitVisible = await page
    .getByText(/Pedir servi.o|Request service|Guardar altera..es|Save changes/i)
    .first()
    .isVisible()
    .catch(() => false);
  if (!submitVisible) return false;

  return inputVisible || textAreaVisible;
}

async function clickManualProviderSelectButton(page) {
  const candidates = [
    page.getByRole('button', { name: /^Selecionar$/i }).first(),
    page.locator('button:has-text("Selecionar")').first(),
    page.locator('flt-semantics[role="button"]', { hasText: /^Selecionar$/i }).first(),
  ];

  for (const candidate of candidates) {
    try {
      const visible = await candidate.isVisible({ timeout: 700 }).catch(() => false);
      if (!visible) continue;
      await candidate.click({ force: true, timeout: 1200 });
      return true;
    } catch (_) {}
  }
  return false;
}

async function hasSelectedManualProvider(page, providerSearch) {
  if (!(await isManualProviderMode(page))) return false;
  if (!providerSearch) return true;

  const providerRx = new RegExp(escapeRegExp(providerSearch), 'i');
  return await page.getByText(providerRx).first().isVisible().catch(() => false);
}

async function selectManualProvider(page, providerSearch) {
  if (await hasSelectedManualProvider(page, providerSearch)) return true;
  if (!(await isOnProviderSelector(page))) return false;

  const searchInput = page.locator('input[placeholder*="Pesquisar prestador"], input:visible').first();
  const searchVisible = await searchInput.isVisible().catch(() => false);
  const useSearch = Boolean(providerSearch && searchVisible);
  if (useSearch) {
    await fillField(searchInput, page, providerSearch);
    await sleep(700);
  }

  let selected = false;
  const start = Date.now();
  let searchRelaxed = false;
  while (Date.now() - start < 90000) {
    const emptyList = await page.getByText(/Sem prestadores/i).first().isVisible().catch(() => false);
    if (emptyList) {
      if (!searchRelaxed && useSearch) {
        await fillField(searchInput, page, '');
        searchRelaxed = true;
      }
      await sleep(900);
      continue;
    }

    if (!searchRelaxed && useSearch && Date.now() - start > 22000) {
      await fillField(searchInput, page, '');
      searchRelaxed = true;
      await sleep(900);
    }

    selected = await clickManualProviderSelectButton(page);
    if (selected) break;
    if (await hasSelectedManualProvider(page, providerSearch)) return true;

    // Fallback: open first visible provider card then try select again.
    await page.mouse.click(250, 250).catch(() => {});
    await sleep(250);
    selected = await clickManualProviderSelectButton(page);
    if (selected) break;
    if (await hasSelectedManualProvider(page, providerSearch)) return true;

    await sleep(450);
  }

  if (!selected && !(await hasSelectedManualProvider(page, providerSearch))) return false;

  const waitBackStart = Date.now();
  while (Date.now() - waitBackStart < 30000) {
    if (await hasSelectedManualProvider(page, providerSearch)) return true;

    const onOrderScreen = await isOnOrderForm(page);
    const onManualOrderBlock = await isManualProviderMode(page);
    if (onOrderScreen || onManualOrderBlock) return true;

    const stillSelector = await isOnProviderSelector(page);
    if (!stillSelector) return true;
    await sleep(350);
  }

  return await hasSelectedManualProvider(page, providerSearch);
}

async function gotoRole(page, role) {
  await page.goto(`${TARGET_URL}/?role=${role}`, { waitUntil: 'domcontentloaded' });
  await waitForFlutterMounted(page, role);
  await page.waitForTimeout(800);
}

async function ensureProviderSetupDone(provider) {
  const start = Date.now();
  while (Date.now() - start < 90000) {
    const onHome = await provider
      .getByText(/Ol[aá], prestador|Est[aá]s ONLINE|Est[aá]s OFFLINE|Pedidos perto de ti/i)
      .first()
      .isVisible()
      .catch(() => false);
    if (onHome) return true;

    const onCoverage = await provider.getByText(/.rea de atua..o|Guardar altera..es/i).first().isVisible().catch(() => false);
    if (onCoverage) {
      const saved = (await waitAndClick(provider, /Guardar altera..es|Guardar/i, 5000)) || (await clickVisibleTextCenter(provider, /Guardar altera..es|Guardar/i));
      if (!saved) {
        await provider.mouse.click(640, 686).catch(() => {});
      }
      await sleep(1200);
      continue;
    }

    const onRoleSelector = await provider
      .getByText(/Cliente|Prestador|Escolhe o teu papel|Seleciona o perfil/i)
      .first()
      .isVisible()
      .catch(() => false);
    if (onRoleSelector) {
      await waitAndClick(provider, /Prestador/i, 5000);
      await sleep(1200);
      continue;
    }

    await tryConfirmDialogs(provider);
    await provider.keyboard.press('Escape').catch(() => {});
    await sleep(600);
  }
  return false;
}

async function ensureProviderOnline(provider) {
  const start = Date.now();
  while (Date.now() - start < 20000) {
    const isOnline = await provider.getByText(/Est[aá]s ONLINE/i).first().isVisible().catch(() => false);
    if (isOnline) return true;

    const isOffline = await provider.getByText(/Est[aá]s OFFLINE/i).first().isVisible().catch(() => false);
    if (!isOffline) {
      await sleep(500);
      continue;
    }

    await provider.mouse.click(1210, 124).catch(() => {});
    await sleep(700);
    await tryClick(provider, /Est[aá]s OFFLINE/i, 900);
    await sleep(500);
  }
  return false;
}

async function latestPedidoMeta() {
  const snap = await db.collection('pedidos').orderBy('createdAt', 'desc').limit(1).get();
  if (snap.empty) return { id: null, createdAtMs: 0 };
  const doc = snap.docs[0];
  return { id: doc.id, createdAtMs: tsMillis(doc.data().createdAt) };
}

async function waitNewPedidoAfter(baseMs, timeoutMs = 50000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const curr = await latestPedidoMeta();
    if (curr.createdAtMs > baseMs + 250) return curr.id;
    await sleep(1200);
  }
  return null;
}

async function getPedido(id) {
  const doc = await db.collection('pedidos').doc(id).get();
  return doc.data() || null;
}

async function ensureOrderForm(client) {
  const catalog = await loadServiceCatalog();
  const serviceNameRegex = buildServiceNameRegex(catalog.names);
  const start = Date.now();
  while (Date.now() - start < 30000) {
    if (await isOnOrderForm(client)) return true;

    const inputVisible = await client.locator('input:not([readonly])').first().isVisible().catch(() => false);
    const textAreaVisible = await client.locator('textarea:not([readonly])').first().isVisible().catch(() => false);
    if (inputVisible && textAreaVisible) return true;

    await clickVisibleServiceCard(client, serviceNameRegex);
    await client.mouse.click(210, 278).catch(() => {});
    await client.waitForTimeout(450);

    const stillList = await client
      .getByText(serviceNameRegex)
      .first()
      .isVisible()
      .catch(() => false);
    if (stillList) {
      await client.keyboard.press('Escape').catch(() => {});
      await client.mouse.click(28, 28).catch(() => {});
    }

    await sleep(500);
  }
  return false;
}

async function createOrder(
  client,
  { titlePrefix = 'E2E', manualProvider = false, providerSearch = PROVIDER_NAME, description = null } = {},
) {
  const catalog = await loadServiceCatalog();
  const serviceNameRegex = buildServiceNameRegex(catalog.names);
  await waitAndClick(client, /In[iI].cio|Home/i, 9000);
  await tryConfirmDialogs(client);
  let openedService = false;
  const openDeadline = Date.now() + 30000;
  while (Date.now() < openDeadline) {
    if (await isOnOrderForm(client)) {
      openedService = true;
      break;
    }

    if (await clickVisibleServiceCard(client, serviceNameRegex)) {
      await client.waitForTimeout(650);
      if (await isOnOrderForm(client)) {
        openedService = true;
        break;
      }
    }

    await waitAndClick(client, /In[iI].cio|Home/i, 1200);
    await tryConfirmDialogs(client);
    await client.keyboard.press('Escape').catch(() => {});
    await sleep(400);
  }

  const formReady = await ensureOrderForm(client);
  if (!openedService && !formReady) {
    const visibleButtons = await client.locator('flt-semantics[role="button"]', { hasText: serviceNameRegex }).count().catch(() => 0);
    const body = await client.locator('body').innerText().catch(() => '');
    const matches = await client
      .evaluate(
        ({ source, flags }) => {
          let re = null;
          try {
            re = new RegExp(source, flags.includes('i') ? 'i' : '');
          } catch (_) {
            return [];
          }

          const seen = new Set();
          const rows = [];
          for (const selector of ['flt-semantics', '[role="button"]', 'div', 'span']) {
            for (const element of document.querySelectorAll(selector)) {
              if (seen.has(element)) continue;
              seen.add(element);
              const text = ((element.innerText || element.textContent || '') + '').replace(/\s+/g, ' ').trim();
              if (!text || !re.test(text)) continue;
              const rect = element.getBoundingClientRect();
              rows.push({
                tag: element.tagName,
                role: element.getAttribute('role') || '',
                pe: getComputedStyle(element).pointerEvents,
                x: Math.round(rect.x),
                y: Math.round(rect.y),
                w: Math.round(rect.width),
                h: Math.round(rect.height),
                text: text.slice(0, 90),
              });
            }
          }
          return rows.slice(0, 8);
        },
        { source: serviceNameRegex.source, flags: serviceNameRegex.flags || '' },
      )
      .catch(() => []);
    throw new Error(
      `Service card not opened buttons=${visibleButtons} matches=${JSON.stringify(matches).slice(0, 700)} body=${body.slice(0, 350)}`,
    );
  }
  if (!formReady) throw new Error('Order form not ready');

  if (manualProvider) {
    const switched = await switchToManualProviderMode(client);
    if (!switched) throw new Error('Could not switch provider mode to manual');
    await sleep(500);

    const openSelector = await waitAndClick(client, /Pesquisar prestadores|Trocar prestador/i, 12000);
    const selectorVisible = await waitForProviderSelector(client, 30000);
    if (!openSelector && !selectorVisible) throw new Error('Could not open manual provider selector');
    if (!selectorVisible) throw new Error('Manual provider selector not visible');

    const selected = await selectManualProvider(client, providerSearch);
    if (!selected) throw new Error('Could not select manual provider');
    await sleep(700);
  }

  if ((await isOnProviderSelector(client)) && !(await isOnOrderForm(client)) && !(await isManualProviderMode(client))) {
    throw new Error('Still on manual provider selector after selection attempt');
  }

  const title = `${titlePrefix}-${Date.now().toString().slice(-6)}`;
  const titleInput = client.locator('input:not([readonly]):visible').first();
  await fillField(titleInput, client, title);

  const desc = client.locator('textarea:not([readonly]):visible').first();
  await fillField(desc, client, description || `Fluxo ${title}`);

  for (let i = 0; i < 5; i++) {
    await client.mouse.wheel(0, 450).catch(() => {});
    await sleep(220);
  }

  const clicked = await waitAndClick(client, /Pedir servi.o|Request service/i, 14000);
  if (!clicked) await client.mouse.click(640, 650).catch(() => {});
  return title;
}

async function providerOpenDetail(provider) {
  for (let i = 0; i < 14; i++) {
    await tryClick(provider, /Tens um trabalho para gerir|Tap here to open the next job|trabalho para gerir/i, 900);
    await provider.mouse.click(240, 390).catch(() => {});
    await sleep(650);

    const detail = await provider.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
    if (detail) return true;

    await tryClick(provider, /Meus trabalhos|My jobs|Meus Trabalhos/i, 1000);
    await provider.mouse.click(480, 684).catch(() => {});
    await sleep(900);
    await provider.mouse.click(250, 250).catch(() => {});
    await sleep(700);

    const detail2 = await provider.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
    if (detail2) return true;
  }
  return false;
}

async function openOrderDetailByTitle(page, title, { provider = false } = {}) {
  const titleRx = new RegExp(escapeRegExp(title), 'i');
  const tabRx = provider ? /Meus trabalhos|My jobs/i : /Meus pedidos|My orders/i;

  for (let i = 0; i < 18; i++) {
    await closeAllOverlays(page);

    const onDetail = await page.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
    if (onDetail) {
      const hasTitle = await page.getByText(titleRx).first().isVisible().catch(() => false);
      if (hasTitle) return true;
      await page.mouse.click(28, 28).catch(() => {});
      await sleep(700);
    }

    await tryClick(page, /Tens um trabalho para gerir|Tap here to open the next job|trabalho para gerir/i, 900);
    await sleep(500);

    const onDetailAfterBanner = await page.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
    if (onDetailAfterBanner) {
      const hasTitle = await page.getByText(titleRx).first().isVisible().catch(() => false);
      if (hasTitle) return true;
      await page.mouse.click(28, 28).catch(() => {});
      await sleep(700);
    }

    await waitAndClick(page, tabRx, 1400);
    await page.mouse.click(provider ? 480 : 480, 684).catch(() => {});
    await sleep(700);

    const clickedTitle = await waitAndClick(page, titleRx, 2500);
    if (clickedTitle) {
      await sleep(700);
      const isDetail = await page.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
      if (isDetail) {
        const hasTitle = await page.getByText(titleRx).first().isVisible().catch(() => false);
        if (hasTitle) return true;
        await page.mouse.click(28, 28).catch(() => {});
        await sleep(500);
      }
    } else {
      const isDetailBeforeFallback = await page.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
      if (isDetailBeforeFallback) {
        await page.mouse.click(28, 28).catch(() => {});
        await sleep(500);
        continue;
      }
      await page.mouse.wheel(0, 320).catch(() => {});
      await sleep(600);
      await closeAllOverlays(page);
      const isDetail = await page.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
      if (isDetail) {
        const hasTitle = await page.getByText(titleRx).first().isVisible().catch(() => false);
        if (hasTitle) return true;
        await page.mouse.click(28, 28).catch(() => {});
        await sleep(500);
      }
    }
  }
  return false;
}

async function clientOpenDetail(client) {
  for (let i = 0; i < 12; i++) {
    const isDetail = await client.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
    if (isDetail) return true;

    await tryClick(client, /A encontrar um prestador|Pedido criado|Tens um trabalho para gerir/i, 900);
    await tryClick(client, /Meus pedidos|My orders/i, 1000);
    await client.mouse.click(480, 684).catch(() => {});
    await sleep(700);
    await client.mouse.click(250, 250).catch(() => {});
    await sleep(800);
  }
  return false;
}

async function providerAcceptAndQuote(provider, pedidoId, providerUid) {
  const start = Date.now();
  let lastData = null;
  while (Date.now() - start < 170000) {
    const data = await getPedido(pedidoId);
    lastData = data || lastData;
    if (!data) {
      await sleep(800);
      continue;
    }

    const state = `${data.estado || data.status || ''}`.trim();
    const statusProp = `${data.statusProposta || ''}`.trim();
    const pedidoProvider = `${data.prestadorId || ''}`.trim();
    const hasQuotedValues = data.valorMinEstimadoPrestador != null || data.valorMaxEstimadoPrestador != null;
    const hasQuoteHistory = Array.isArray(data.historico)
      ? data.historico.some((h) => `${h?.evento || ''}`.trim() === 'proposta_enviada')
      : false;

    if (
      statusProp === 'pendente_cliente' ||
      statusProp === 'proposta_enviada' ||
      statusProp === 'enviada' ||
      state === 'aguarda_resposta_cliente' ||
      state === 'tens_orcamento_para_decidir' ||
      state === 'aguarda_decisao_cliente' ||
      state === 'proposta_enviada' ||
      ((pedidoProvider === providerUid || !providerUid) && hasQuotedValues && hasQuoteHistory)
    ) {
      return;
    }

    if (providerUid && pedidoProvider !== providerUid) {
      await waitAndClick(provider, /Aceitar|Accept/i, 1200);
      await tryClick(provider, /Enviar agora|Send now/i, 1200);
      await sleep(600);
      continue;
    }

    const opened = await providerOpenDetail(provider);
    if (!opened) {
      await sleep(700);
      continue;
    }

    const uiAlreadyQuoted =
      (await provider.getByText(/Tens um or.amento para decidir|Aguardando resposta do cliente/i).first().isVisible().catch(() => false)) ||
      (await provider.getByText(/Proposta enviada/i).first().isVisible().catch(() => false));
    if (uiAlreadyQuoted) return;

    const quoteClicked = await tryClick(
      provider,
      /Enviar estimativa(?: ao cliente)?|Enviar or.amento.*faixa|min\/max|request_quote|orcamento|quote|propor servi.o/i,
      1700,
    );
    if (!quoteClicked) {
      await provider.mouse.click(640, 246).catch(() => {});
    }

    await sleep(700);

    const min = provider.locator('input[placeholder*="20"], input[aria-label*="20"], input:visible').first();
    const max = provider.locator('input[placeholder*="35"], input[aria-label*="35"], input:visible').nth(1);
    const hasMin = await min.isVisible().catch(() => false);
    const hasMax = await max.isVisible().catch(() => false);

    if (hasMin && hasMax) {
      await fillField(min, provider, '20');
      await fillField(max, provider, '35');

      const msg = provider.locator('textarea:visible').first();
      if (await msg.isVisible().catch(() => false)) {
        await fillField(msg, provider, 'e2e quote');
      }

      await waitAndClick(provider, /Enviar agora|Enviar|Send now|Send/i, 12000);
      await sleep(900);
    }
  }

  const body = await provider.locator('body').innerText().catch(() => '');
  throw new Error(
    `Provider could not send quote estado=${lastData?.estado || lastData?.status || ''} statusProp=${lastData?.statusProposta || ''} providerId=${lastData?.prestadorId || ''} body=${body.slice(0, 500)}`,
  );
}

async function providerAcceptManualInvite(provider, pedidoId, expectedTitle) {
  const start = Date.now();
  while (Date.now() - start < 120000) {
    const data = await getPedido(pedidoId);
    if (data && (data.estado || data.status) === 'aceito') return;

    const opened = expectedTitle
      ? await openOrderDetailByTitle(provider, expectedTitle, { provider: true })
      : await providerOpenDetail(provider);
    if (!opened) {
      await sleep(700);
      continue;
    }

    const accepted = (await tryClick(provider, /Aceitar|Accept/i, 1500)) || (await clickVisibleTextCenter(provider, /Aceitar|Accept/i));
    if (accepted) {
      await sleep(700);
      await tryConfirmDialogs(provider);
      await sleep(800);
    }
  }
  throw new Error(`Provider could not accept manual invite for pedido=${pedidoId}`);
}

async function clientAcceptProvider(client, pedidoId) {
  const start = Date.now();
  while (Date.now() - start < 160000) {
    const data = await getPedido(pedidoId);
    if (data && (data.estado || data.status) === 'aceito' && data.statusProposta === 'aceita_cliente') return;

    if (await tryClick(client, /Aceitar este prestador|Accept this provider/i, 1200)) {
      await sleep(700);
      continue;
    }

    await tryClick(client, /A procurar um prestador|Pedido criado|Tens um trabalho para gerir/i, 900);
    await tryClick(client, /Meus pedidos|My orders/i, 900);
    await client.mouse.click(480, 684).catch(() => {});
    await sleep(900);
    await client.mouse.click(250, 250).catch(() => {});
    await sleep(700);
    await tryClick(client, /Aceitar este prestador|Accept this provider/i, 1200);
    await sleep(600);
  }
  throw new Error('Client could not accept provider');
}

async function providerStart(provider, pedidoId) {
  const start = Date.now();
  while (Date.now() - start < 170000) {
    const data = await getPedido(pedidoId);
    if (data && (data.estado || data.status) === 'em_andamento') return;

    const isDetail = await provider.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
    if (!isDetail) {
      await providerOpenDetail(provider);
    }

    let clicked = false;
    clicked = clicked || (await tryClick(provider, /Iniciar servi.o|Start service/i, 1200));
    if (!clicked) clicked = await clickVisibleTextCenter(provider, /Iniciar servi.o|Start service/i);
    if (!clicked) {
      await provider.mouse.click(640, 334).catch(() => {});
      clicked = true;
    }

    if (clicked) {
      await sleep(500);
      await tryConfirmDialogs(provider);
      await sleep(900);

      const updated = await getPedido(pedidoId);
      if (updated && (updated.estado || updated.status) === 'em_andamento') return;
    }

    await provider.keyboard.press('F5').catch(() => {});
    await sleep(1200);
    await providerOpenDetail(provider);
    await sleep(500);
  }

  throw new Error('Provider could not start service');
}

async function providerSendFinal(provider, pedidoId) {
  const start = Date.now();
  while (Date.now() - start < 180000) {
    const data = await getPedido(pedidoId);
    if (data && (data.estado || data.status) === 'aguarda_confirmacao_valor' && data.statusConfirmacaoValor === 'pendente_cliente') return;

    const isDetail = await provider.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
    if (!isDetail) {
      await providerOpenDetail(provider);
    }

    const finishRx = /Terminar servi.o.*valor final|lancar valor final|lan.ar valor final|Finish service|final value/i;

    let openedModal = false;
    if (await tryClick(provider, finishRx, 1200)) openedModal = true;
    if (!openedModal && (await clickVisibleTextCenter(provider, finishRx))) openedModal = true;
    if (!openedModal) {
      await provider.mouse.click(640, 354).catch(() => {});
      openedModal = true;
    }

    if (openedModal) {
      await sleep(600);
      await tryConfirmDialogs(provider);

      let filled = await fillAnyVisibleField(provider, '30');
      if (!filled) {
        await sleep(500);
        filled = await fillAnyVisibleField(provider, '30');
      }

      if (filled) {
        await tryClick(provider, /Enviar ao cliente|Send to customer|Enviar agora|Enviar|Send/i, 1500);
        await sleep(1000);

        const after = await getPedido(pedidoId);
        if (after && (after.estado || after.status) === 'aguarda_confirmacao_valor' && after.statusConfirmacaoValor === 'pendente_cliente') return;
      }
    }

    await provider.keyboard.press('Escape').catch(() => {});
    await sleep(400);
    await provider.keyboard.press('F5').catch(() => {});
    await sleep(1200);
    await providerOpenDetail(provider);
    await sleep(500);
  }

  throw new Error('Provider could not send final value');
}

async function clientConfirmFinal(client, pedidoId) {
  const start = Date.now();
  while (Date.now() - start < 190000) {
    const data = await getPedido(pedidoId);
    if (data && (data.estado || data.status) === 'concluido' && data.statusConfirmacaoValor === 'confirmado_cliente') return;

    const isDetail = await client.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
    if (!isDetail) {
      await clientOpenDetail(client);
    }

    await scrollToBottom(client, 9);

    let clicked = false;
    clicked = clicked || (await tryClick(client, /Confirmar valor|Confirm value|Aceitar valor|Confirmar|Concluir pagamento/i, 1400));
    if (!clicked) clicked = await clickVisibleTextCenter(client, /Confirmar valor|Confirm value|Aceitar valor|Confirmar|Concluir pagamento/i);
    if (!clicked) {
      await client.mouse.click(640, 640).catch(() => {});
      clicked = true;
    }

    if (clicked) {
      await sleep(500);
      await tryConfirmDialogs(client);
      await sleep(1000);

      const after = await getPedido(pedidoId);
      if (after && (after.estado || after.status) === 'concluido' && after.statusConfirmacaoValor === 'confirmado_cliente') return;
    }

    await client.keyboard.press('Escape').catch(() => {});
    await sleep(300);
    await client.keyboard.press('F5').catch(() => {});
    await sleep(1400);
  }

  throw new Error('Client could not confirm final value');
}

async function clientCancelPedido(client, pedidoId, expectedTitle = null) {
  const start = Date.now();
  let lastData = null;
  const isCanceledByClient = (data) => (data.estado || data.status) === 'cancelado' && data.canceladoPor === 'cliente';
  while (Date.now() - start < 90000) {
    const data = await getPedido(pedidoId);
    lastData = data || lastData;
    if (data && isCanceledByClient(data)) return;

    let cancelClicked = await tryClick(client, /Cancelar pedido|Cancelar trabalho|Cancel order|Cancel/i, 1600);
    if (!cancelClicked) {
      cancelClicked = await clickVisibleTextCenter(client, /Cancelar pedido|Cancelar trabalho|Cancel order|Cancel/i);
    }
    if (!cancelClicked) {
      await client.mouse.click(640, 606).catch(() => {});
      cancelClicked = true;
    }
    await sleep(350);

    let hadDialog =
      (await tryClick(client, /Sim, cancelar|Sim cancelar|Yes, cancel|Sim/i, 1400)) ||
      (await clickVisibleTextCenter(client, /Sim, cancelar|Sim cancelar|Yes, cancel|Sim/i)) ||
      (await tryClick(client, /Confirmar|Confirm/i, 1000));
    if (!hadDialog) {
      await client.mouse.click(812, 474).catch(() => {});
      hadDialog = true;
    }
    if (hadDialog) {
      await sleep(850);
    }

    try {
      await waitPedidoWhere(
        pedidoId,
        'cancelamento cliente apos confirmar',
        isCanceledByClient,
        6000,
      );
      return;
    } catch (_) {
      const after = await getPedido(pedidoId);
      lastData = after || lastData;
      if (after && isCanceledByClient(after)) return;
    }

    if (expectedTitle) {
      await openOrderDetailByTitle(client, expectedTitle, { provider: false });
    } else {
      await clientOpenDetail(client);
    }

    const afterRecovery = await getPedido(pedidoId);
    lastData = afterRecovery || lastData;
    if (afterRecovery && isCanceledByClient(afterRecovery)) return;

    await sleep(600);
  }

  const finalData = await getPedido(pedidoId);
  lastData = finalData || lastData;
  if (finalData && isCanceledByClient(finalData)) return;

  const body = await client.locator('body').innerText().catch(() => '');
  throw new Error(
    `Client could not cancel pedido=${pedidoId} estado=${lastData?.estado || lastData?.status || ''} statusProp=${lastData?.statusProposta || ''} body=${body.slice(0, 500)}`,
  );
}

async function openChatPanel(page) {
  for (let i = 0; i < 12; i++) {
    await closeAllOverlays(page);
    if (await isQuoteDialogOpen(page)) {
      await dismissQuoteDialog(page);
      await sleep(300);
    }
    if (await chatComposerVisible(page)) return true;

    await scrollToBottom(page, 2);
    const opened =
      (await waitAndClick(page, /Chat sobre este pedido|Chat about this order|Order chat/i, 1400)) ||
      (await waitAndClick(page, /Abrir chat completo|Open full chat/i, 1400));

    if (opened) {
      await sleep(400);
      if (await chatComposerVisible(page)) return true;
    }
  }

  return await chatComposerVisible(page);
}

async function sendChatMessage(page, pedidoId, senderRole, text) {
  await closeAllOverlays(page);
  if (await isQuoteDialogOpen(page)) {
    const closed = await dismissQuoteDialog(page);
    if (!closed) throw new Error(`Quote dialog still open before chat (${senderRole})`);
  }
  const isChatOpen = await openChatPanel(page);
  if (!isChatOpen) throw new Error(`Could not open chat panel (${senderRole})`);

  await scrollToBottom(page, 4);
  const filled = await fillChatComposer(page, text);
  if (!filled) throw new Error(`Could not fill chat textbox (${senderRole})`);

  let sent = await clickNearInputSend(page);
  if (!sent) {
    await page.keyboard.press('Enter').catch(() => {});
    sent = true;
  }
  if (!sent) throw new Error(`Could not click send (${senderRole})`);

  await waitPedidoWhere(
    pedidoId,
    `chat message from ${senderRole}`,
    async () => {
      const messages = await chatMessagesForPedido(pedidoId);
      return messages.some((m) => {
        const body = `${m.text ?? m.texto ?? m.message ?? m.conteudo ?? ''}`;
        if (!body.includes(text)) return false;

        const expectedRole = normalizeRole(senderRole);
        const seenRole = normalizeRole(m.senderRole);
        if (!seenRole) return true;
        if (seenRole === expectedRole) return true;
        if (expectedRole === 'prestador' && seenRole === 'provider') return true;
        if (expectedRole === 'cliente' && seenRole === 'customer') return true;
        return false;
      });
    },
    25000,
  );
}

async function waitBidirectionalChat(pedidoId) {
  const pedido = await getPedido(pedidoId);
  const clienteId = `${pedido?.clienteId || ''}`;
  const prestadorId = `${pedido?.prestadorId || ''}`;

  const start = Date.now();
  while (Date.now() - start < 40000) {
    const messages = await chatMessagesForPedido(pedidoId);
    const hasClient = messages.some((m) => {
      const role = normalizeRole(m.senderRole);
      const sid = `${m.senderId || ''}`;
      return role === 'cliente' || role === 'customer' || (clienteId && sid === clienteId);
    });
    const hasProvider = messages.some((m) => {
      const role = normalizeRole(m.senderRole);
      const sid = `${m.senderId || ''}`;
      return role === 'prestador' || role === 'provider' || (prestadorId && sid === prestadorId);
    });
    if (hasClient && hasProvider) return messages.length;
    await sleep(800);
  }
  throw new Error(`Bidirectional chat not observed for pedido=${pedidoId}`);
}

async function providerReportNoShow(provider, pedidoId) {
  const start = Date.now();
  while (Date.now() - start < 100000) {
    const data = await getPedido(pedidoId);
    if (data?.noShowReportedBy === 'prestador') return;

    const isDetail = await provider.getByText(/Detalhe do pedido|Order detail/i).first().isVisible().catch(() => false);
    if (!isDetail) {
      await providerOpenDetail(provider);
    }

    await scrollToBottom(provider, 6);
    let clicked = await tryClick(provider, /Reportar no-show|No-show/i, 1500);
    if (!clicked) clicked = await clickVisibleTextCenter(provider, /Reportar no-show|No-show/i);
    if (!clicked) {
      await provider.keyboard.press('F5').catch(() => {});
      await sleep(1000);
      continue;
    }

    await sleep(400);
    await fillFirstTextbox(provider, 'No-show e2e');
    await tryClick(provider, /Reportar|Report|Enviar/i, 1600);
    await sleep(900);
  }
  throw new Error(`Provider could not report no-show for pedido=${pedidoId}`);
}

async function runHappyPathScenario(client, provider, providerUid) {
  console.log(`[${now()}] Scenario 1/3 happy-path`);
  const baseline = await latestPedidoMeta();
  const title = await createOrder(client, { titlePrefix: 'E2E-HAPPY', description: 'Fluxo completo happy path' });
  const pedidoId = await waitNewPedidoAfter(baseline.createdAtMs);
  if (!pedidoId) throw new Error('Pedido not created (happy-path)');
  await shot(client, '02_happy_client_order_created');

  const created = await getPedido(pedidoId);
  await seedProviderBase(providerUid, {
    online: true,
    serviceId: created?.servicoId || null,
    serviceName: created?.servicoNome || created?.categoria || null,
  });
  await ensureProviderSetupDone(provider);
  await ensureProviderOnline(provider);

  await providerAcceptAndQuote(provider, pedidoId, providerUid);
  await shot(provider, '03_happy_provider_quote_sent');

  await clientAcceptProvider(client, pedidoId);
  await shot(client, '04_happy_client_accept_provider');

  await providerStart(provider, pedidoId);
  await shot(provider, '05_happy_provider_started');

  await providerSendFinal(provider, pedidoId);
  await shot(provider, '06_happy_provider_final_sent');

  await clientConfirmFinal(client, pedidoId);
  await shot(client, '07_happy_client_confirmed');

  const finalData = await waitPedidoWhere(
    pedidoId,
    'happy-path concluido',
    (data) =>
      (data.estado || data.status) === 'concluido' &&
      data.statusProposta === 'aceita_cliente' &&
      data.statusConfirmacaoValor === 'confirmado_cliente',
    45000,
  );

  console.log(
    `[${now()}] happy-path ok pedido=${pedidoId} estado=${finalData?.estado} statusProp=${finalData?.statusProposta} statusConf=${finalData?.statusConfirmacaoValor}`,
  );
  return pedidoId;
}

async function runOrcamentoScenario(client, provider, providerUid) {
  console.log(`[${now()}] Scenario L2 orçamento min-max`);
  await gotoRole(client, 'cliente');
  await seedProviderBase(providerUid, { online: true });
  await ensureProviderSetupDone(provider);
  await ensureProviderOnline(provider);

  const baseline = await latestPedidoMeta();
  const title = await createOrder(client, {
    titlePrefix: 'E2E-ORCAMENTO',
    description: 'Fluxo orçamento min-max',
  });
  const pedidoId = await waitNewPedidoAfter(baseline.createdAtMs);
  if (!pedidoId) throw new Error('Pedido not created (orcamento scenario)');
  await shot(client, '10_orcamento_client_order_created');

  const created = await getPedido(pedidoId);
  if (created?.tipoPreco !== 'por_orcamento') {
    throw new Error(`Orçamento pedido expected tipoPreco=por_orcamento, got ${created?.tipoPreco || 'null'}`);
  }

  await seedProviderBase(providerUid, {
    online: true,
    serviceId: created?.servicoId || null,
    serviceName: created?.servicoNome || created?.categoria || null,
  });
  await ensureProviderSetupDone(provider);
  await ensureProviderOnline(provider);

  await providerAcceptAndQuote(provider, pedidoId, providerUid);
  await shot(provider, '11_orcamento_provider_quote_sent');
  const quoted = await waitPedidoWhere(
    pedidoId,
    'orcamento proposta min-max pendente',
    (data) => isOrcamentoQuotePending(data, providerUid),
    45000,
  );
  console.log(
    `[${now()}] orcamento quote ok pedido=${pedidoId} min=${quoted?.valorMinEstimadoPrestador} max=${quoted?.valorMaxEstimadoPrestador}`,
  );

  await clientAcceptProvider(client, pedidoId);
  await shot(client, '12_orcamento_client_accept_provider');
  await waitPedidoWhere(
    pedidoId,
    'orcamento proposta aceita',
    isOrcamentoAccepted,
    45000,
  );

  await providerStart(provider, pedidoId);
  await shot(provider, '13_orcamento_provider_started');

  await providerSendFinal(provider, pedidoId);
  await shot(provider, '14_orcamento_provider_final_sent');
  await waitPedidoWhere(
    pedidoId,
    'orcamento valor final pendente',
    isOrcamentoFinalPending,
    45000,
  );

  await clientConfirmFinal(client, pedidoId);
  await shot(client, '15_orcamento_client_confirmed');
  const finalData = await waitPedidoWhere(
    pedidoId,
    'orcamento concluido',
    isOrcamentoConcluido,
    45000,
  );

  console.log(
    `[${now()}] orcamento ok pedido=${pedidoId} estado=${finalData?.estado} min=${finalData?.valorMinEstimadoPrestador} max=${finalData?.valorMaxEstimadoPrestador} final=${finalData?.precoFinal} commission=${finalData?.commissionPlatform}`,
  );
  return pedidoId;
}

async function runCancelScenario(client, providerUid) {
  console.log(`[${now()}] Scenario 2/3 cancelamento cliente`);
  await gotoRole(client, 'cliente');
  await seedProviderBase(providerUid, { online: false });

  const baseline = await latestPedidoMeta();
  const title = await createOrder(client, { titlePrefix: 'E2E-CANCEL', description: 'Fluxo cancelamento cliente' });
  const pedidoId = await waitNewPedidoAfter(baseline.createdAtMs);
  if (!pedidoId) throw new Error('Pedido not created (cancel scenario)');

  await shot(client, '20_cancel_client_order_created');
  await clientCancelPedido(client, pedidoId, title);
  await shot(client, '21_cancel_client_done');

  const canceled = await waitPedidoWhere(
    pedidoId,
    'cancelamento cliente',
    (data) => (data.estado || data.status) === 'cancelado' && data.canceladoPor === 'cliente',
    30000,
  );
  console.log(`[${now()}] cancelamento ok pedido=${pedidoId} estado=${canceled?.estado} canceladoPor=${canceled?.canceladoPor}`);
  return pedidoId;
}

async function runManualChatNoShowScenario(
  client,
  provider,
  providerUid,
  { serviceId = null, serviceName = null } = {},
) {
  console.log(`[${now()}] Scenario 3/3 manual-provider + chat + no-show`);
  await gotoRole(client, 'cliente');
  await seedProviderBase(providerUid, { online: true, serviceId, serviceName });
  await ensureProviderSetupDone(provider);
  await ensureProviderOnline(provider);

  const baseline = await latestPedidoMeta();
  const manualTitle = await createOrder(client, {
    titlePrefix: 'E2E-MANUAL',
    manualProvider: true,
    providerSearch: PROVIDER_NAME,
    description: 'Fluxo manual, chat e no-show',
  });
  const pedidoId = await waitNewPedidoAfter(baseline.createdAtMs);
  if (!pedidoId) throw new Error('Pedido not created (manual scenario)');

  await waitPedidoWhere(
    pedidoId,
    'manual convite enviado',
    (data) => data.prestadorId === providerUid && (data.estado || data.status) === 'aguarda_resposta_prestador',
    35000,
  );
  await shot(client, '30_manual_client_detail');

  await ensureProviderSetupDone(provider);
  await ensureProviderOnline(provider);
  await providerAcceptManualInvite(provider, pedidoId, manualTitle);
  await waitPedidoWhere(pedidoId, 'manual convite aceito', (data) => (data.estado || data.status) === 'aceito', 45000);
  await shot(provider, '31_manual_provider_accepted');

  await openOrderDetailByTitle(client, manualTitle, { provider: false });
  await sendChatMessage(client, pedidoId, 'cliente', `msg cliente ${Date.now().toString().slice(-5)}`);
  await shot(client, '32_chat_client_sent');

  await openOrderDetailByTitle(provider, manualTitle, { provider: true });
  await sendChatMessage(provider, pedidoId, 'prestador', `msg prestador ${Date.now().toString().slice(-5)}`);
  await shot(provider, '33_chat_provider_sent');

  const totalMsgs = await waitBidirectionalChat(pedidoId);
  console.log(`[${now()}] bidirectional chat ok pedido=${pedidoId} totalMsgs=${totalMsgs}`);

  await providerReportNoShow(provider, pedidoId);
  await shot(provider, '34_noshow_provider_reported');

  const noShow = await waitPedidoWhere(
    pedidoId,
    'no-show reportado',
    (data) => data.noShowReportedBy === 'prestador',
    30000,
  );
  console.log(`[${now()}] no-show ok pedido=${pedidoId} noShowBy=${noShow?.noShowReportedBy}`);
  return pedidoId;
}

async function smokeTabs(client, provider) {
  await tryClick(client, /In[iI].cio|Home/i, 900);
  await shot(client, '40_client_home');
  await tryClick(client, /Meus pedidos|My orders/i, 900);
  await shot(client, '41_client_orders');
  await tryClick(client, /Mensagens|Messages/i, 900);
  await shot(client, '42_client_messages');
  await tryClick(client, /Perfil|Profile/i, 900);
  await shot(client, '43_client_profile');

  await tryClick(provider, /In[iI].cio|Home/i, 900);
  await shot(provider, '44_provider_home');
  await tryClick(provider, /Meus trabalhos|My jobs/i, 900);
  await shot(provider, '45_provider_jobs');
  await tryClick(provider, /Mensagens|Messages/i, 900);
  await shot(provider, '46_provider_messages');
  await tryClick(provider, /Perfil|Profile/i, 900);
  await shot(provider, '47_provider_profile');
}

(async () => {
  await ensureTargetUrlReady();

  const browser = await chromium.launch({ headless: false, slowMo: 22 });
  const clientCtx = await browser.newContext({ viewport: { width: 1280, height: 720 } });
  const providerCtx = await browser.newContext({ viewport: { width: 1280, height: 720 } });
  await configureContext(clientCtx);
  await configureContext(providerCtx);
  const client = await clientCtx.newPage();
  const provider = await providerCtx.newPage();
  attachPageDiagnostics(client, 'client');
  attachPageDiagnostics(provider, 'provider');

  try {
    console.log(`[${now()}] Open client+provider`);
    // In Flutter web debug (DDC), loading two roles in parallel can starve CPU and delay mount.
    await gotoRole(client, 'cliente');
    await gotoRole(provider, 'prestador');
    await Promise.all([shot(client, '01_client_home'), shot(provider, '01_provider_home')]);

    const [clientUid, providerUid] = await Promise.all([waitStableUid(client), waitStableUid(provider)]);
    if (!clientUid || !providerUid) {
      const clientText = await client.locator('body').innerText().catch(() => '');
      const providerText = await provider.locator('body').innerText().catch(() => '');
      throw new Error(
        `UID invalid client=${clientUid} provider=${providerUid} clientUrl=${client.url()} providerUrl=${provider.url()} clientBody=${clientText.slice(0, 120)} providerBody=${providerText.slice(0, 120)}`,
      );
    }
    console.log(`[${now()}] UIDs client=${clientUid} provider=${providerUid} providerName=${PROVIDER_NAME} scenario=${SCENARIO}`);

    await seedProviderBase(providerUid, { online: true });
    await ensureProviderSetupDone(provider);
    await ensureProviderOnline(provider);

    if (SCENARIO === 'orcamento') {
      const orcamentoPedidoId = await runOrcamentoScenario(client, provider, providerUid);
      const doneOrcamento = await getPedido(orcamentoPedidoId);
      console.log(
        `[${now()}] summary orcamento=${orcamentoPedidoId}:${doneOrcamento?.estado}/${doneOrcamento?.statusProposta}/${doneOrcamento?.statusConfirmacaoValor} final=${doneOrcamento?.precoFinal}`,
      );
      console.log(`[${now()}] ORCAMENTO MIN-MAX FLOW OK`);
      console.log(`[${now()}] screenshots: ${SHOT_DIR}`);
      return;
    }

    const fullFlowPedidoId = await runHappyPathScenario(client, provider, providerUid);
    const cancelPedidoId = await runCancelScenario(client, providerUid);
    const happyAfter = await getPedido(fullFlowPedidoId);
    const manualPedidoId = await runManualChatNoShowScenario(client, provider, providerUid, {
      serviceId: happyAfter?.servicoId || null,
      serviceName: happyAfter?.servicoNome || happyAfter?.categoria || null,
    });

    await smokeTabs(client, provider);

    const doneHappy = await getPedido(fullFlowPedidoId);
    const doneCancel = await getPedido(cancelPedidoId);
    const doneManual = await getPedido(manualPedidoId);
    console.log(
      `[${now()}] summary happy=${fullFlowPedidoId}:${doneHappy?.estado} cancel=${cancelPedidoId}:${doneCancel?.estado}/${doneCancel?.canceladoPor} manual=${manualPedidoId}:${doneManual?.estado}/noShow=${doneManual?.noShowReportedBy}`,
    );
    console.log(`[${now()}] FULL MULTI-SCENARIO FLOW OK`);
    console.log(`[${now()}] screenshots: ${SHOT_DIR}`);
  } catch (error) {
    console.error(`[${now()}] FAIL:`, error.message || error);
    try {
      await shot(client, 'zz_client_fail');
    } catch (_) {}
    try {
      await shot(provider, 'zz_provider_fail');
    } catch (_) {}
    const cu = await readUid(client).catch(() => null);
    const pu = await readUid(provider).catch(() => null);
    console.error(`[${now()}] Debug UIDs client=${cu} provider=${pu}`);
    console.error(`[${now()}] screenshots: ${SHOT_DIR}`);
    process.exitCode = 1;
  } finally {
    await clientCtx.close();
    await providerCtx.close();
    await browser.close();
  }
})();
