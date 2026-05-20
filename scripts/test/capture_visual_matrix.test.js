const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {
  buildCapturePlan,
  sanitizeName,
  parseArgs,
} = require('../qa/capture_visual_matrix');

function testSanitizeName() {
  assert.strictEqual(sanitizeName('Home Cliente'), 'home_cliente');
  assert.strictEqual(sanitizeName('pedido/detail:42'), 'pedido_detail_42');
}

function testBuildCapturePlan() {
  const plan = buildCapturePlan({
    baseUrl: 'http://127.0.0.1:63776',
    outDir: 'C:/tmp/screens',
    routes: [
      { name: 'home_cliente', url: '/?role=cliente' },
      { name: 'home_prestador', url: '/?role=prestador' },
    ],
    viewports: [
      { name: 'mobile', width: 390, height: 844 },
      { name: 'wide', width: 1920, height: 1080 },
    ],
  });

  assert.strictEqual(plan.length, 4);
  assert.deepStrictEqual(plan[0].viewport, {
    name: 'mobile',
    width: 390,
    height: 844,
  });
  assert.ok(plan[0].url.startsWith('http://127.0.0.1:63776/'));
  assert.ok(plan[0].filePath.endsWith('home_cliente__mobile.png'));
}

function testParseArgs() {
  const args = parseArgs([
    '--base-url=http://127.0.0.1:63776',
    '--out-dir=C:/tmp/screens',
    '--wait-ms=9000',
  ]);
  assert.strictEqual(args.baseUrl, 'http://127.0.0.1:63776');
  assert.strictEqual(args.outDir, 'C:/tmp/screens');
  assert.strictEqual(args.waitMs, 9000);
}

function testWebIndexHasEmulatorBannerNormalizer() {
  const indexPath = path.join(process.cwd(), 'web', 'index.html');
  const html = fs.readFileSync(indexPath, 'utf8');
  assert.ok(
    html.includes('normalizeFirebaseAuthEmulatorWarning'),
    'web/index.html should normalize Firebase Auth emulator warning banner',
  );
  assert.ok(
    html.includes(
      'Running in emulator mode. Do not use with production credentials.',
    ),
    'normalizer should target only the Firebase Auth emulator warning text',
  );
  assert.ok(
    html.includes('node.style.top'),
    'emulator warning should be positioned away from bottom navigation',
  );
  assert.ok(
    html.includes('node.style.right'),
    'emulator warning should sit in a compact corner placement',
  );
  assert.ok(
    html.includes('Emulador Firebase ativo'),
    'emulator warning should use compact local QA copy',
  );
}

testSanitizeName();
testBuildCapturePlan();
testParseArgs();
testWebIndexHasEmulatorBannerNormalizer();

console.log('capture_visual_matrix planning ok');
