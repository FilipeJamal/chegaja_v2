#!/usr/bin/env node
// scripts/seed_servicos.js
// Seeds Firestore with servicos from a JSON file.
//
// Usage:
//   node scripts/seed_servicos.js --emulator-host=127.0.0.1
//
// Flags:
//   --file=scripts/servicos_seed.json
//   --collection=servicos
//   --limit=0 (0 = no limit)
//   --overwrite
//   --dry-run
//   --emulator-host=127.0.0.1
//   --emulator-port=8080
//   --project-id=chegaja-ac88d
//   --service-account=path/to/serviceAccount.json
//   --help

const fs = require("fs");
const path = require("path");

const admin = require("../functions/node_modules/firebase-admin");

function parseArgs(argv) {
  const args = {
    file: "scripts/servicos_seed.json",
    collection: "servicos",
    limit: 0,
    overwrite: false,
    dryRun: false,
    emulatorHost: "",
    emulatorPort: 8080,
    projectId: "",
    serviceAccount: "",
    help: false,
  };

  for (const arg of argv) {
    if (arg === "--help" || arg === "-h") {
      args.help = true;
    } else if (arg === "--overwrite") {
      args.overwrite = true;
    } else if (arg === "--dry-run") {
      args.dryRun = true;
    } else if (arg.startsWith("--file=")) {
      args.file = arg.slice("--file=".length);
    } else if (arg.startsWith("--collection=")) {
      args.collection = arg.slice("--collection=".length);
    } else if (arg.startsWith("--limit=")) {
      args.limit = Number(arg.slice("--limit=".length)) || args.limit;
    } else if (arg.startsWith("--emulator-host=")) {
      args.emulatorHost = arg.slice("--emulator-host=".length);
    } else if (arg.startsWith("--emulator-port=")) {
      args.emulatorPort = Number(arg.slice("--emulator-port=".length)) || args.emulatorPort;
    } else if (arg.startsWith("--project-id=")) {
      args.projectId = arg.slice("--project-id=".length);
    } else if (arg.startsWith("--service-account=")) {
      args.serviceAccount = arg.slice("--service-account=".length);
    }
  }

  return args;
}

function printHelp() {
  console.log(`seed_servicos.js
Seeds Firestore with servicos from a JSON file.

Usage:
  node scripts/seed_servicos.js [options]

Options:
  --file=scripts/servicos_seed.json
  --collection=servicos
  --limit=0
  --overwrite
  --dry-run
  --emulator-host=127.0.0.1
  --emulator-port=8080
  --project-id=chegaja-ac88d
  --service-account=path/to/serviceAccount.json
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

function toBool(value, fallback = true) {
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value !== 0;
  if (typeof value === "string") {
    const v = value.toLowerCase().trim();
    if (v === "true" || v === "1" || v === "sim" || v === "yes") return true;
    if (v === "false" || v === "0" || v === "nao" || v === "não" || v === "no")
      return false;
  }
  return fallback;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
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
  const col = db.collection(args.collection);

  const raw = fs.readFileSync(path.resolve(args.file), "utf8");
  const items = JSON.parse(raw);
  if (!Array.isArray(items)) {
    throw new Error("Seed file must be a JSON array.");
  }

  const limit = args.limit > 0 ? args.limit : items.length;
  let processed = 0;
  let written = 0;

  let batch = db.batch();
  let batchOps = 0;

  for (const item of items.slice(0, limit)) {
    const id = String(item.id || item.ID || item._id || "").trim();
    if (!id) {
      processed += 1;
      continue;
    }

    const name = String(item.name || item.nome || "").trim();
    const mode = String(item.mode || item.modo || "IMEDIATO");
    const isActive = toBool(item.isActive ?? item.ativo, true);
    const keywords = Array.isArray(item.keywords) ? item.keywords.map(String) : [];

    const data = {
      name,
      mode,
      isActive,
      nome: name,
      modo: mode,
      ativo: isActive,
      keywords,
      iconKey: item.iconKey || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (!args.dryRun) {
      const ref = col.doc(id);
      batch.set(ref, data, { merge: !args.overwrite });
      batchOps += 1;
      if (batchOps >= 450) {
        await batch.commit();
        batch = db.batch();
        batchOps = 0;
      }
    }

    written += 1;
    processed += 1;
    if (processed % 100 === 0) {
      console.log(`Processed ${processed}, written ${written}`);
    }
  }

  if (!args.dryRun && batchOps > 0) {
    await batch.commit();
  }

  console.log(`Done. Processed ${processed}, written ${written}.`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
