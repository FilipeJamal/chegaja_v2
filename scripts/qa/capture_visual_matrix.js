const fs = require('fs');
const os = require('os');
const path = require('path');
const { chromium } = require('playwright');

const DEFAULT_VIEWPORTS = [
  { name: 'mobile', width: 390, height: 844 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1366, height: 768 },
  { name: 'wide', width: 1920, height: 1080 },
];

const DEFAULT_ROUTES = [
  { name: 'home_cliente', url: '/?role=cliente' },
  { name: 'home_prestador', url: '/?role=prestador' },
];

function sanitizeName(value) {
  return `${value}`
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function parseArgs(argv = process.argv.slice(2)) {
  const result = {
    baseUrl: process.env.TARGET_URL || 'http://127.0.0.1:63776',
    outDir:
      process.env.SHOT_DIR || path.join(os.tmpdir(), 'chegaja-m2106-visual-qa'),
    waitMs: Number(process.env.CAPTURE_WAIT_MS || 10000),
  };

  for (const arg of argv) {
    if (arg.startsWith('--base-url=')) {
      result.baseUrl = arg.slice('--base-url='.length);
    } else if (arg.startsWith('--out-dir=')) {
      result.outDir = arg.slice('--out-dir='.length);
    } else if (arg.startsWith('--wait-ms=')) {
      result.waitMs = Number(arg.slice('--wait-ms='.length));
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!Number.isFinite(result.waitMs) || result.waitMs < 0) {
    throw new Error('--wait-ms must be a non-negative number');
  }

  return result;
}

function buildCapturePlan({
  baseUrl,
  outDir,
  routes = DEFAULT_ROUTES,
  viewports = DEFAULT_VIEWPORTS,
}) {
  const normalizedBase = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  const steps = [];

  for (const route of routes) {
    for (const viewport of viewports) {
      const routeName = sanitizeName(route.name);
      const viewportName = sanitizeName(viewport.name);
      const urlPath = route.url.startsWith('/') ? route.url : `/${route.url}`;
      steps.push({
        name: `${routeName}__${viewportName}`,
        url: `${normalizedBase}${urlPath}`,
        viewport,
        filePath: path.join(outDir, `${routeName}__${viewportName}.png`),
      });
    }
  }

  return steps;
}

async function captureMatrix(options) {
  const plan = buildCapturePlan(options);
  fs.mkdirSync(options.outDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const results = [];

  try {
    for (const step of plan) {
      const page = await browser.newPage({
        viewport: {
          width: step.viewport.width,
          height: step.viewport.height,
        },
      });
      const consoleErrors = [];
      page.on('console', (message) => {
        if (message.type() === 'error') {
          consoleErrors.push(message.text());
        }
      });
      page.on('pageerror', (error) => {
        consoleErrors.push(error.message);
      });

      await page.goto(step.url, {
        waitUntil: 'domcontentloaded',
        timeout: 45000,
      });
      await page.waitForTimeout(options.waitMs);
      await page.screenshot({ path: step.filePath, fullPage: false });

      results.push({
        name: step.name,
        url: step.url,
        viewport: step.viewport,
        filePath: step.filePath,
        consoleErrors,
      });
      await page.close();
    }
  } finally {
    await browser.close();
  }

  return results;
}

async function main() {
  const args = parseArgs();
  const results = await captureMatrix({
    baseUrl: args.baseUrl,
    outDir: args.outDir,
    waitMs: args.waitMs,
  });

  for (const result of results) {
    console.log(
      `${result.name} ${result.viewport.width}x${result.viewport.height} ${result.filePath}`,
    );
    if (result.consoleErrors.length > 0) {
      console.log(`  consoleErrors=${result.consoleErrors.length}`);
    }
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = {
  DEFAULT_ROUTES,
  DEFAULT_VIEWPORTS,
  buildCapturePlan,
  captureMatrix,
  parseArgs,
  sanitizeName,
};
