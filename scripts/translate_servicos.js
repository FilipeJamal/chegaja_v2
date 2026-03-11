#!/usr/bin/env node
// scripts/translate_servicos.js
// Backfills name_i18n for servicos using Google Translate.
//
// Usage:
//   node scripts/translate_servicos.js --emulator-host=127.0.0.1
//   node scripts/translate_servicos.js --langs=es,fr --limit=200
//
// Flags:
//   --langs=auto (default) or comma list (ex: ar,de,es,fr,hi,ru,zh,en)
//   --source-lang=pt
//   --collection=servicos
//   --sleep-ms=100
//   --limit=0 (0 = no limit)
//   --start-after=DOC_ID
//   --retries=3
//   --retry-ms=500
//   --fail-threshold=20
//   --fail-pause-ms=30000
//   --overwrite
//   --dry-run
//   --emulator-host=127.0.0.1
//   --emulator-port=8080
//   --project-id=chegaja-ac88d
//   --service-account=path/to/serviceAccount.json
//   --provider=google|googlecloud|libretranslate
//   --help

const fs = require("fs");
const path = require("path");

// Reuse dependencies installed under functions/.
const admin = require("../functions/node_modules/firebase-admin");

function parseArgs(argv) {
  const args = {
    langs: "auto",
    sourceLang: "pt",
    collection: "servicos",
    sleepMs: 100,
    limit: 0,
    startAfter: "",
    retries: 3,
    retryMs: 500,
    failThreshold: 20,
    failPauseMs: 30000,
    overwrite: false,
    dryRun: false,
    emulatorHost: "",
    emulatorPort: 8080,
    projectId: "",
    serviceAccount: "",
    provider: "google",
    googleKey: "",
    libretranslateUrl: "",
    libretranslateKey: "",
    help: false,
  };

  for (const arg of argv) {
    if (arg === "--help" || arg === "-h") {
      args.help = true;
    } else if (arg === "--overwrite") {
      args.overwrite = true;
    } else if (arg === "--dry-run") {
      args.dryRun = true;
    } else if (arg.startsWith("--langs=")) {
      args.langs = arg.slice("--langs=".length);
    } else if (arg.startsWith("--source-lang=")) {
      args.sourceLang = arg.slice("--source-lang=".length);
    } else if (arg.startsWith("--collection=")) {
      args.collection = arg.slice("--collection=".length);
    } else if (arg.startsWith("--sleep-ms=")) {
      args.sleepMs = Number(arg.slice("--sleep-ms=".length)) || args.sleepMs;
    } else if (arg.startsWith("--limit=")) {
      args.limit = Number(arg.slice("--limit=".length)) || args.limit;
    } else if (arg.startsWith("--start-after=")) {
      args.startAfter = arg.slice("--start-after=".length);
    } else if (arg.startsWith("--retries=")) {
      args.retries = Number(arg.slice("--retries=".length)) || args.retries;
    } else if (arg.startsWith("--retry-ms=")) {
      args.retryMs = Number(arg.slice("--retry-ms=".length)) || args.retryMs;
    } else if (arg.startsWith("--fail-threshold=")) {
      args.failThreshold =
        Number(arg.slice("--fail-threshold=".length)) || args.failThreshold;
    } else if (arg.startsWith("--fail-pause-ms=")) {
      args.failPauseMs =
        Number(arg.slice("--fail-pause-ms=".length)) || args.failPauseMs;
    } else if (arg.startsWith("--emulator-host=")) {
      args.emulatorHost = arg.slice("--emulator-host=".length);
    } else if (arg.startsWith("--emulator-port=")) {
      args.emulatorPort = Number(arg.slice("--emulator-port=".length)) || args.emulatorPort;
    } else if (arg.startsWith("--project-id=")) {
      args.projectId = arg.slice("--project-id=".length);
    } else if (arg.startsWith("--service-account=")) {
      args.serviceAccount = arg.slice("--service-account=".length);
    } else if (arg.startsWith("--provider=")) {
      args.provider = arg.slice("--provider=".length);
    } else if (arg.startsWith("--google-key=")) {
      args.googleKey = arg.slice("--google-key=".length);
    } else if (arg.startsWith("--libretranslate-url=")) {
      args.libretranslateUrl = arg.slice("--libretranslate-url=".length);
    } else if (arg.startsWith("--libretranslate-key=")) {
      args.libretranslateKey = arg.slice("--libretranslate-key=".length);
    }
  }

  return args;
}

function printHelp() {
  console.log(`translate_servicos.js
Backfills name_i18n on servicos using Google Translate.

Usage:
  node scripts/translate_servicos.js [options]

Options:
  --langs=auto or ar,de,es,fr,hi,ru,zh,en
  --source-lang=pt
  --collection=servicos
  --sleep-ms=100
  --limit=0
  --start-after=DOC_ID
  --retries=3
  --retry-ms=500
  --fail-threshold=20
  --fail-pause-ms=30000
  --overwrite
  --dry-run
  --emulator-host=127.0.0.1
  --emulator-port=8080
  --project-id=chegaja-ac88d
  --service-account=path/to/serviceAccount.json
  --provider=google|googlecloud|libretranslate
  --google-key=API_KEY (for googlecloud)
  --libretranslate-url=https://.../translate
  --libretranslate-key=API_KEY
  --help
`);
}

function readDefaultProjectId() {
  try {
    const rcPath = path.join(__dirname, "..", ".firebaserc");
    const data = JSON.parse(fs.readFileSync(rcPath, "utf8"));
    return data.projects && data.projects.default;
  } catch (err) {
    return "";
  }
}

function discoverLangs(sourceLang) {
  const l10nDir = path.join(__dirname, "..", "lib", "l10n");
  const langs = new Set();
  try {
    for (const file of fs.readdirSync(l10nDir)) {
      const match = /^app_(.+)\\.arb$/.exec(file);
      if (!match) continue;
      const code = match[1];
      if (code && code !== sourceLang) langs.add(code);
    }
  } catch (err) {
    // Ignore missing directory; user may pass --langs manually.
  }
  return Array.from(langs).sort();
}

async function translateGoogle(text, source, target) {
  const params = new URLSearchParams({
    client: "gtx",
    sl: source,
    tl: target,
    dt: "t",
    q: text,
  });
  const url = `https://translate.googleapis.com/translate_a/single?${params.toString()}`;
  const resp = await fetch(url);
  if (!resp.ok) {
    const err = new Error(`Translate failed (${resp.status})`);
    err.status = resp.status;
    throw err;
  }
  const data = await resp.json();
  const parts = Array.isArray(data?.[0]) ? data[0] : [];
  return parts
    .filter((part) => Array.isArray(part) && typeof part[0] === "string")
    .map((part) => part[0])
    .join("");
}

async function translateGoogleCloud(text, source, target, apiKey) {
  if (!apiKey) {
    throw new Error("GOOGLE_TRANSLATE_API_KEY missing");
  }
  const params = new URLSearchParams({
    q: text,
    source,
    target,
    format: "text",
    key: apiKey,
  });
  const url = "https://translation.googleapis.com/language/translate/v2";
  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params.toString(),
  });
  if (!resp.ok) {
    const err = new Error(`Translate failed (${resp.status})`);
    err.status = resp.status;
    throw err;
  }
  const data = await resp.json();
  const translated =
    data && data.data && data.data.translations && data.data.translations[0]
      ? data.data.translations[0].translatedText
      : "";
  return translated || "";
}

async function translateLibreTranslate(text, source, target, url, apiKey) {
  if (!url) {
    throw new Error("LIBRETRANSLATE_URL missing");
  }
  const params = new URLSearchParams({
    q: text,
    source,
    target,
    format: "text",
  });
  if (apiKey) params.set("api_key", apiKey);
  const resp = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params.toString(),
  });
  if (!resp.ok) {
    const err = new Error(`Translate failed (${resp.status})`);
    err.status = resp.status;
    throw err;
  }
  const data = await resp.json();
  return data && data.translatedText ? data.translatedText : "";
}

async function sleep(ms) {
  if (!ms) return;
  await new Promise((resolve) => setTimeout(resolve, ms));
}

function isRetryableError(err) {
  const status = err && typeof err.status === "number" ? err.status : 0;
  if (status === 429 || status === 500 || status === 502 || status === 503 || status === 504) {
    return true;
  }

  const message = String((err && err.message) || "").toLowerCase();
  if (message.includes("fetch failed")) return true;

  const retryableCodes = new Set([
    "ECONNRESET",
    "ECONNREFUSED",
    "ETIMEDOUT",
    "EAI_AGAIN",
    "ENOTFOUND",
    "ENETUNREACH",
  ]);
  const code = err && err.code;
  const causeCode = err && err.cause && err.cause.code;
  return retryableCodes.has(code) || retryableCodes.has(causeCode);
}

async function translateWithRetry(fn, text, source, target, retries, retryMs) {
  let attempt = 0;
  while (true) {
    try {
      return await fn(text, source, target);
    } catch (err) {
      attempt += 1;
      if (attempt > retries || !isRetryableError(err)) {
        throw err;
      }
      const delay = retryMs * Math.pow(2, attempt - 1);
      await sleep(delay);
    }
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }

  if (!args.googleKey) {
    args.googleKey = process.env.GOOGLE_TRANSLATE_API_KEY || "";
  }
  if (!args.libretranslateUrl) {
    args.libretranslateUrl = process.env.LIBRETRANSLATE_URL || "";
  }
  if (!args.libretranslateKey) {
    args.libretranslateKey = process.env.LIBRETRANSLATE_API_KEY || "";
  }

  let translateFn = translateGoogle;
  if (args.provider === "googlecloud") {
    translateFn = (text, source, target) =>
      translateGoogleCloud(text, source, target, args.googleKey);
  } else if (args.provider === "libretranslate") {
    translateFn = (text, source, target) =>
      translateLibreTranslate(
        text,
        source,
        target,
        args.libretranslateUrl,
        args.libretranslateKey
      );
  }

  if (args.emulatorHost) {
    process.env.FIRESTORE_EMULATOR_HOST = `${args.emulatorHost}:${args.emulatorPort}`;
  }

  const projectId =
    args.projectId ||
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    readDefaultProjectId();

  const appOptions = {};
  if (args.serviceAccount) {
    const raw = fs.readFileSync(path.resolve(args.serviceAccount), "utf8");
    const serviceAccount = JSON.parse(raw);
    appOptions.credential = admin.credential.cert(serviceAccount);
    appOptions.projectId = appOptions.projectId || serviceAccount.project_id;
  } else if (projectId) {
    appOptions.projectId = projectId;
  }

  admin.initializeApp(appOptions);
  const db = admin.firestore();

  const langs =
    args.langs === "auto"
      ? discoverLangs(args.sourceLang)
      : args.langs.split(",").map((l) => l.trim()).filter(Boolean);

  if (!langs.length) {
    console.error("No target languages found. Use --langs or add app_*.arb files.");
    process.exitCode = 1;
    return;
  }

  const langMap = { zh: "zh-CN" };
  const cache = new Map();

  let processed = 0;
  let updated = 0;

  let batch = db.batch();
  let batchOps = 0;

  let query = db.collection(args.collection).orderBy(admin.firestore.FieldPath.documentId());
  if (args.startAfter) {
    query = query.startAfter(args.startAfter);
  }
  if (args.limit > 0) {
    query = query.limit(args.limit);
  }
  const snapshot = await query.get();
  let lastDocId = "";
  let consecutiveFailures = 0;
  for (const doc of snapshot.docs) {
    if (args.limit > 0 && processed >= args.limit) break;
    lastDocId = doc.id;

    const data = doc.data() || {};
    const rawName = data.name || data.nome || "";
    const name = String(rawName).trim();
    if (!name) {
      processed += 1;
      continue;
    }

    const nameI18n = {};
    if (data.name_i18n && typeof data.name_i18n === "object") {
      for (const [key, value] of Object.entries(data.name_i18n)) {
        if (value) nameI18n[key] = String(value);
      }
    }

    let changed = false;
    for (const lang of langs) {
      if (lang === args.sourceLang) continue;
      if (!args.overwrite && nameI18n[lang]) continue;

      const target = langMap[lang] || lang;
      const cacheKey = `${target}|${name}`;
      let translated = cache.get(cacheKey);
      if (!translated) {
        try {
          translated = await translateWithRetry(
            translateFn,
            name,
            args.sourceLang,
            target,
            args.retries,
            args.retryMs
          );
          consecutiveFailures = 0;
        } catch (err) {
          console.error(`Translate error (${target}):`, err.message || err);
          translated = "";
          consecutiveFailures += 1;
          if (consecutiveFailures >= args.failThreshold) {
            console.log(
              `Too many failures (${consecutiveFailures}). Pausing for ${args.failPauseMs}ms...`
            );
            await sleep(args.failPauseMs);
            consecutiveFailures = 0;
          }
        }
        cache.set(cacheKey, translated);
      }

      if (translated) {
        nameI18n[lang] = translated;
        changed = true;
      }
      await sleep(args.sleepMs);
    }

    if (changed) {
      updated += 1;
      if (!args.dryRun) {
        batch.update(doc.ref, { name_i18n: nameI18n });
        batchOps += 1;
        if (batchOps >= 450) {
          await batch.commit();
          batch = db.batch();
          batchOps = 0;
        }
      }
    }

    processed += 1;
    if (processed % 100 === 0) {
      console.log(`Processed ${processed}, updated ${updated}`);
    }
  }

  if (!args.dryRun && batchOps > 0) {
    await batch.commit();
  }

  let suffix = "";
  if (lastDocId) {
    const quoted = JSON.stringify(lastDocId);
    suffix = ` Last doc: ${lastDocId}. Resume: --start-after=${quoted}`;
  }
  console.log(`Done. Processed ${processed}, updated ${updated}.${suffix}`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
