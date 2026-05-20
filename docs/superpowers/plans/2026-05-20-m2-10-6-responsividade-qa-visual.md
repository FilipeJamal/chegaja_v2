# M2.10.6 Responsividade QA Visual Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validar visualmente a experiencia Web/Windows/Android da M2.10, corrigir problemas pequenos/medios de responsividade e documentar evidencias antes de fechar a fase visual.

**Architecture:** A execucao separa captura/evidencia de correcao visual. Primeiro criar um harness local de screenshots com Playwright e um relatorio de QA, depois corrigir apenas problemas confirmados em widgets visuais, shell/layout ou `web/index.html`; backend, rules, Functions e services de negocio ficam intocados.

**Tech Stack:** Flutter/Dart, Material 3, Flutter Web build local, Firebase Emulator Suite local, Playwright, Node.js, `flutter_test`, `AppShellScaffold`, `AppContentShell`, `AppPageScaffold`, `AppResponsiveGrid`.

---

## Contexto

Spec aprovada:

```txt
docs/superpowers/specs/2026-05-20-m2-10-6-responsividade-qa-visual-design.md
```

Commit da spec:

```txt
3e2ea5d342ad6e0c254d287b7fc78584ef210006
Iniciar M2.10.6 responsividade QA visual
```

Estado visual anterior:

```txt
M2.10.2: design system foundation
M2.10.3: Home Cliente redesign
M2.10.4: Home Prestador redesign
M2.10.5: Pedido/listas/detalhe polish
```

Evidencia manual inicial:

```txt
Home Cliente desktop melhorou, mas ainda pode usar melhor largura/estados.
Home Cliente mobile esta mais organizada.
Home Prestador mobile melhorou, mas precisa validar scroll/conteudo completo.
Home Prestador desktop, listas e detalhe ainda precisam screenshots reais.
Banner vermelho de emulador tapa a bottom navigation no mobile.
```

## Fora do escopo

```txt
backend
Firestore Rules
Storage Rules
Cloud Functions
deploy
smoke real
cleanup real
health real
Android fisico real
pagamentos reais
Play Store
package id final
HTTPS App Links
fechar M2.6
novas funcionalidades grandes
mudancas de schema
mudancas de regra de negocio
```

Nao tocar:

```txt
functions/**
firestore.rules
storage.rules
lib/core/services/pedido_service.dart
lib/core/repositories/pedido_repo.dart
lib/core/services/location_service.dart
lib/core/services/chat_service.dart
android/key.properties
keystore
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
.superpowers/
```

## Estrutura de ficheiros esperada

Criar:

```txt
scripts/qa/capture_visual_matrix.js
scripts/test/capture_visual_matrix.test.js
docs/M2_10_VISUAL_QA_REPORT.md
```

Modificar, se as evidencias pedirem:

```txt
package.json
web/index.html
lib/core/widgets/app_shell_scaffold.dart
lib/core/widgets/app_content_shell.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
lib/features/cliente/widgets/pedido_list_card.dart
lib/features/cliente/pedido_detalhe_screen.dart
test/core/widgets/app_shell_scaffold_test.dart
test/core/widgets/app_content_shell_test.dart
test/features/cliente/cliente_home_redesign_test.dart
test/features/prestador/prestador_home_redesign_test.dart
test/features/cliente/widgets/pedido_detail_components_test.dart
docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Nao modificar ficheiros de negocio se o problema tiver solucao em shell, layout,
CSS local, padding, max-width, cards ou componentes visuais.

## Viewports da matriz

```js
const viewports = [
  { name: 'mobile', width: 390, height: 844 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1366, height: 768 },
  { name: 'wide', width: 1920, height: 1080 },
];
```

## Rotas/telas minimas

```js
const routes = [
  { name: 'home_cliente', url: '/?role=cliente' },
  { name: 'home_prestador', url: '/?role=prestador' },
];
```

Detalhe/lista com dados reais de emulador deve ser coberto por uma destas vias:

1. usar screenshots produzidos por `scripts/e2e/full_ui_dual_role_e2e.js`, se o fluxo conseguir chegar ao detalhe;
2. criar dados de emulador com Admin SDK e navegar diretamente para rotas existentes, se houver rota direta estavel;
3. documentar bloqueio ambiental com screenshot e motivo, sem fingir que foi validado.

---

### Task 1: Pre-check e baseline visual

**Files:**
- Read: `docs/superpowers/specs/2026-05-20-m2-10-6-responsividade-qa-visual-design.md`
- Read: `docs/M2_10_VISUAL_PRODUCT_STATUS.md`
- Read: `package.json`

- [ ] **Step 1: Confirmar branch e working tree**

Run:

```powershell
git branch --show-current
git status --short
git log -1 --oneline
```

Expected:

```txt
main
3e2ea5d Iniciar M2.10.6 responsividade QA visual
```

`git status --short` pode continuar a mostrar apenas:

```txt
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
?? .superpowers/
```

Nao restaurar, apagar, stagear ou commitar esses itens.

- [ ] **Step 2: Confirmar que nenhuma porta critica esta em estado parcial**

Run:

```powershell
@(8080,9099,9199,5173,63776) | ForEach-Object {
  $port=$_
  $r=Test-NetConnection 127.0.0.1 -Port $port -WarningAction SilentlyContinue
  "$port=$($r.TcpTestSucceeded)"
}
```

Expected:

```txt
8080=True|False
9099=True|False
9199=True|False
5173=True|False
63776=True|False
```

Se so algumas portas Firebase estiverem abertas, parar processos locais
relacionados ou escolher portas novas para a sessao. Nao matar processos sem
verificar que pertencem ao ambiente local desta app.

- [ ] **Step 3: Criar pasta local de screenshots fora do Git**

Run:

```powershell
$env:CHEGAJA_VISUAL_QA_DIR = Join-Path $env:TEMP "chegaja-m2106-visual-qa"
New-Item -ItemType Directory -Force -Path $env:CHEGAJA_VISUAL_QA_DIR
```

Expected: pasta criada em `%TEMP%`, nao dentro do repo.

---

### Task 2: Harness de screenshots read-only

**Files:**
- Create: `scripts/qa/capture_visual_matrix.js`
- Create: `scripts/test/capture_visual_matrix.test.js`
- Modify: `package.json`

- [ ] **Step 1: Criar teste do parser/plan do harness**

Criar `scripts/test/capture_visual_matrix.test.js`:

```js
const assert = require('assert');
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

testSanitizeName();
testBuildCapturePlan();
testParseArgs();

console.log('capture_visual_matrix planning ok');
```

- [ ] **Step 2: Rodar o teste e confirmar falha**

Run:

```powershell
node scripts/test/capture_visual_matrix.test.js
```

Expected: falha com `Cannot find module '../qa/capture_visual_matrix'`.

- [ ] **Step 3: Implementar harness minimo**

Criar `scripts/qa/capture_visual_matrix.js`:

```js
const fs = require('fs');
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
      process.env.SHOT_DIR ||
      path.join(require('os').tmpdir(), 'chegaja-m2106-visual-qa'),
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
```

- [ ] **Step 4: Adicionar scripts npm**

Modificar `package.json`:

```json
"qa:visual:m2-10-6": "node scripts/qa/capture_visual_matrix.js"
```

Modificar `test:scripts` para incluir o novo teste:

```json
"test:scripts": "node scripts/test/run_android_integration_test.test.js && node scripts/test/cleanup_smoke_data.test.js && node scripts/test/firebase_production_health.test.js && node scripts/test/capture_visual_matrix.test.js"
```

- [ ] **Step 5: Rodar teste do harness**

Run:

```powershell
node scripts/test/capture_visual_matrix.test.js
npm.cmd run test:scripts
```

Expected:

```txt
capture_visual_matrix planning ok
run_android_integration_test args ok
cleanup_smoke_data safeguards ok
firebase_production_health parsing ok
capture_visual_matrix planning ok
```

---

### Task 3: Ambiente local de QA visual

**Files:**
- Modify: `docs/M2_10_VISUAL_QA_REPORT.md`

- [ ] **Step 1: Criar relatorio inicial**

Criar `docs/M2_10_VISUAL_QA_REPORT.md`:

```md
# M2.10.6 Visual QA Report

Data: 2026-05-20

## Objetivo

Validar responsividade e qualidade visual da M2.10 antes de fechar a fase.

## Ambiente local

| Item | Valor |
| --- | --- |
| Build | Pendente |
| URL local | Pendente |
| Firebase Emulator Suite | Pendente |
| Screenshots | Pendente |

## Matriz de screenshots

| Tela | Mobile 390x844 | Tablet 768x1024 | Desktop 1366x768 | Wide 1920x1080 |
| --- | --- | --- | --- | --- |
| Home Cliente | Pendente | Pendente | Pendente | Pendente |
| Home Prestador | Pendente | Pendente | Pendente | Pendente |
| Lista Cliente | Pendente | Pendente | Pendente | Pendente |
| Pedidos Prestador | Pendente | Pendente | Pendente | Pendente |
| Detalhe Cliente | Pendente | Pendente | Pendente | Pendente |
| Detalhe Prestador | Pendente | Pendente | Pendente | Pendente |

## Problemas encontrados

| Severidade | Tela | Viewport | Problema | Decisao |
| --- | --- | --- | --- | --- |
| Pendente | Pendente | Pendente | Pendente | Pendente |

## Correcoes aplicadas

| Ficheiro | Correcao | Evidencia |
| --- | --- | --- |
| Pendente | Pendente | Pendente |

## Validacoes finais

| Comando | Resultado |
| --- | --- |
| `flutter test` | Pendente |
| `npm.cmd run test:scripts` | Pendente |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | Pendente |
```

- [ ] **Step 2: Construir Web em modo emulador**

Run:

```powershell
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Expected:

```txt
Built build\web
```

Warnings de Wasm dry run vindos de dependencias podem ser documentados, mas nao
devem bloquear esta fase se o build Web standard passar.

- [ ] **Step 3: Servir `build/web` localmente sem Python**

Se nao houver servidor local ativo, criar um servidor temporario fora do repo:

```powershell
$serverJs = Join-Path $env:TEMP 'chegaja_static_server_m2106.js'
@'
const http = require('http');
const fs = require('fs');
const path = require('path');
const root = path.resolve('C:/Users/Jamal/Documents/ProjetosFlutter/chegaja_v2/build/web');
const port = Number(process.env.PORT || 63776);
const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.ico': 'image/x-icon',
};
http.createServer((req, res) => {
  const cleanUrl = decodeURIComponent(req.url.split('?')[0]);
  let filePath = path.resolve(root, cleanUrl === '/' ? 'index.html' : `.${cleanUrl}`);
  if (!filePath.startsWith(root)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }
  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) filePath = path.join(root, 'index.html');
    fs.readFile(filePath, (readErr, data) => {
      if (readErr) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      res.writeHead(200, {'Content-Type': types[path.extname(filePath)] || 'application/octet-stream'});
      res.end(data);
    });
  });
}).listen(port, '127.0.0.1', () => console.log(`serving ${root} on ${port}`));
'@ | Set-Content -Path $serverJs -Encoding UTF8
Start-Process -FilePath 'node' -ArgumentList @($serverJs) -WindowStyle Hidden
```

Confirmar:

```powershell
Invoke-WebRequest http://127.0.0.1:63776 -UseBasicParsing | Select-Object -ExpandProperty StatusCode
```

Expected:

```txt
200
```

- [ ] **Step 4: Garantir Firebase emulators locais**

Run:

```powershell
@(8080,9099,9199) | ForEach-Object {
  $port=$_
  $r=Test-NetConnection 127.0.0.1 -Port $port -WarningAction SilentlyContinue
  "$port=$($r.TcpTestSucceeded)"
}
```

Se todos forem `False`, iniciar:

```powershell
Start-Process -FilePath 'cmd.exe' `
  -ArgumentList @('/c','npx.cmd firebase emulators:start --only auth,firestore,storage --project chegaja-ac88d') `
  -WorkingDirectory 'C:\Users\Jamal\Documents\ProjetosFlutter\chegaja_v2' `
  -WindowStyle Hidden
```

Esperar `8080=True`, `9099=True`, `9199=True`.

- [ ] **Step 5: Capturar matriz basica**

Run:

```powershell
$env:SHOT_DIR = Join-Path $env:TEMP "chegaja-m2106-visual-qa"
$env:TARGET_URL = "http://127.0.0.1:63776"
npm.cmd run qa:visual:m2-10-6 -- --base-url=$env:TARGET_URL --out-dir=$env:SHOT_DIR --wait-ms=12000
```

Expected: screenshots `home_cliente__*.png` e `home_prestador__*.png` gerados
em `%TEMP%\chegaja-m2106-visual-qa`.

---

### Task 4: Corrigir banner de emulador sem esconder QA

**Files:**
- Modify: `web/index.html`
- Create or modify: `scripts/test/capture_visual_matrix.test.js`

- [ ] **Step 1: Adicionar teste textual para normalizador do banner**

Acrescentar ao fim de `scripts/test/capture_visual_matrix.test.js`:

```js
const fs = require('fs');
const path = require('path');

function testWebIndexHasEmulatorBannerNormalizer() {
  const indexPath = path.join(process.cwd(), 'web', 'index.html');
  const html = fs.readFileSync(indexPath, 'utf8');
  assert.ok(
    html.includes('normalizeFirebaseAuthEmulatorWarning'),
    'web/index.html should normalize Firebase Auth emulator warning banner',
  );
  assert.ok(
    html.includes('Running in emulator mode. Do not use with production credentials.'),
    'normalizer should target only the Firebase Auth emulator warning text',
  );
}

testWebIndexHasEmulatorBannerNormalizer();
```

Run:

```powershell
node scripts/test/capture_visual_matrix.test.js
```

Expected: falha ate o normalizador existir.

- [ ] **Step 2: Implementar normalizador local-only em `web/index.html`**

Adicionar antes de `</body>` e antes de `flutter_bootstrap.js` se possivel:

```html
  <script>
    // Local-only: keep the Firebase Auth emulator warning visible without
    // covering bottom navigation or primary actions during visual QA.
    (function normalizeFirebaseAuthEmulatorWarning() {
      var warningText = 'Running in emulator mode. Do not use with production credentials.';
      var isLocalHost =
        window.location.hostname === 'localhost' ||
        window.location.hostname === '127.0.0.1';
      if (!isLocalHost) return;

      function normalize() {
        var nodes = Array.prototype.slice.call(document.body.children);
        nodes.forEach(function (node) {
          if (!node || !node.textContent) return;
          if (node.textContent.indexOf(warningText) === -1) return;
          if (node.id === 'splash' || node.id === 'splash-branding') return;

          node.setAttribute('data-chegaja-emulator-warning', 'true');
          node.style.position = 'fixed';
          node.style.left = '8px';
          node.style.right = '8px';
          node.style.bottom = 'calc(env(safe-area-inset-bottom, 0px) + 84px)';
          node.style.zIndex = '2147483647';
          node.style.padding = '2px 8px';
          node.style.borderRadius = '999px';
          node.style.border = '1px solid rgba(239, 68, 68, 0.25)';
          node.style.background = 'rgba(255, 255, 255, 0.92)';
          node.style.color = '#991B1B';
          node.style.font = '11px/16px system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif';
          node.style.textAlign = 'center';
          node.style.pointerEvents = 'none';
          node.style.boxShadow = '0 6px 18px rgba(17, 20, 24, 0.12)';
        });
      }

      normalize();
      new MutationObserver(normalize).observe(document.body, {
        childList: true,
        subtree: false,
      });
    })();
  </script>
```

Nota: se a captura mostrar que `bottom: 84px` ainda tapa conteudo em mobile,
ajustar para `top: calc(env(safe-area-inset-top, 0px) + 8px)` e documentar a
decisao no relatorio. A regra principal e: banner visivel, mas nunca sobre a
bottom navigation.

- [ ] **Step 3: Rodar teste do normalizador**

Run:

```powershell
node scripts/test/capture_visual_matrix.test.js
npm.cmd run test:scripts
```

Expected: ambos passam.

- [ ] **Step 4: Rebuild e recaptura mobile**

Run:

```powershell
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
$env:SHOT_DIR = Join-Path $env:TEMP "chegaja-m2106-visual-qa-after-banner"
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:63776 --out-dir=$env:SHOT_DIR --wait-ms=12000
```

Expected: screenshots mobile mostram bottom navigation livre do banner.

---

### Task 5: Classificacao visual e fixes pequenos/medios

**Files:**
- Modify as needed: `docs/M2_10_VISUAL_QA_REPORT.md`
- Modify as needed: visual widgets listed in "Estrutura de ficheiros esperada"

- [ ] **Step 1: Preencher matriz no relatorio**

Atualizar `docs/M2_10_VISUAL_QA_REPORT.md` com caminhos locais dos screenshots:

```md
| Home Cliente | `%TEMP%/chegaja-m2106-visual-qa/home_cliente__mobile.png` | `%TEMP%/chegaja-m2106-visual-qa/home_cliente__tablet.png` | `%TEMP%/chegaja-m2106-visual-qa/home_cliente__desktop.png` | `%TEMP%/chegaja-m2106-visual-qa/home_cliente__wide.png` |
| Home Prestador | `%TEMP%/chegaja-m2106-visual-qa/home_prestador__mobile.png` | `%TEMP%/chegaja-m2106-visual-qa/home_prestador__tablet.png` | `%TEMP%/chegaja-m2106-visual-qa/home_prestador__desktop.png` | `%TEMP%/chegaja-m2106-visual-qa/home_prestador__wide.png` |
```

- [ ] **Step 2: Classificar problemas visualmente**

Preencher tabela com exemplos concretos:

```md
| Bloqueador visual | Mobile shell | 390x844 | Banner de emulador tapa bottom navigation | Corrigir em `web/index.html` |
| Ajuste medio | Home Cliente | 1920x1080 | Conteudo principal fica estreito quando lateral esta vazia | Ajustar `AppContentWidth` ou painel lateral |
| Ajuste medio | Home Prestador | 1366x768 | Loading prolongado sem contexto visual suficiente | Melhorar empty/loading se confirmado |
| Aceitavel futuro | Detalhe pedido | desktop | Validacao depende de dados de E2E completo | Documentar se bloqueado |
```

- [ ] **Step 3: Aplicar apenas fixes confirmados**

Regras de decisao:

```txt
Se for banner de emulador: corrigir `web/index.html`.
Se for bottom nav tapada por conteudo Flutter: corrigir `AppShellScaffold` ou `AppPageScaffold`.
Se for max-width estreito: ajustar `AppContentWidth` usado pela tela, nao tokens globais sem necessidade.
Se for card desalinhado em uma tela: corrigir componente local.
Se for problema de dados/emulador: documentar bloqueio, nao inventar feature.
```

Exemplo de ajuste permitido em `AppShellScaffold` se conteudo mobile ficar
por baixo da navigation bar:

```dart
return Scaffold(
  body: SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.topBarHeight),
      child: content,
    ),
  ),
  bottomNavigationBar: NavigationBar(
    selectedIndex: currentIndex,
    onDestinationSelected: onDestinationSelected,
    labelBehavior: compactLabels
        ? NavigationDestinationLabelBehavior.onlyShowSelected
        : NavigationDestinationLabelBehavior.alwaysShow,
    destinations: [
      for (var index = 0; index < destinations.length; index += 1)
        NavigationDestination(
          icon: _buildIcon(destinations[index], selected: false),
          selectedIcon: _buildIcon(destinations[index], selected: true),
          label: destinations[index].label,
        ),
    ],
  ),
);
```

Usar este exemplo so se o teste/screenshot confirmar conteudo tapado pela
bottom nav. Nao aplicar por antecipacao.

- [ ] **Step 4: Criar/ajustar testes para cada fix**

Exemplos:

Para shell mobile:

```dart
testWidgets('mobile shell keeps content above bottom navigation', (tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: AppShellScaffold(
        currentIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          AppShellDestination(
            label: 'Home',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text('Bottom content'),
            ),
          ),
          AppShellDestination(
            label: 'Messages',
            icon: Icons.chat_bubble_outline,
            selectedIcon: Icons.chat_bubble,
            child: SizedBox(),
          ),
        ],
      ),
    ),
  );

  expect(find.text('Bottom content'), findsOneWidget);
  expect(find.byType(NavigationBar), findsOneWidget);
});
```

Para widths, preferir testes existentes de Home Cliente/Prestador e detalhe.

- [ ] **Step 5: Rodar testes Flutter focados**

Run conforme ficheiros tocados:

```powershell
flutter test test/core/widgets/app_shell_scaffold_test.dart
flutter test test/features/cliente/cliente_home_redesign_test.dart
flutter test test/features/prestador/prestador_home_redesign_test.dart
flutter test test/features/cliente/widgets/pedido_detail_components_test.dart
```

Expected: todos passam.

---

### Task 6: Screenshots finais e documentacao

**Files:**
- Modify: `docs/M2_10_VISUAL_QA_REPORT.md`
- Modify: `docs/M2_10_VISUAL_PRODUCT_STATUS.md`

- [ ] **Step 1: Capturar matriz final**

Run:

```powershell
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
$env:SHOT_DIR = Join-Path $env:TEMP "chegaja-m2106-visual-qa-final"
npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:63776 --out-dir=$env:SHOT_DIR --wait-ms=12000
```

Expected: screenshots finais gerados.

- [ ] **Step 2: Atualizar relatorio final**

Atualizar `docs/M2_10_VISUAL_QA_REPORT.md`:

```md
## Ambiente local

| Item | Valor |
| --- | --- |
| Build | `flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true` |
| URL local | `http://127.0.0.1:63776` |
| Firebase Emulator Suite | Auth/Firestore/Storage local |
| Screenshots | `%TEMP%/chegaja-m2106-visual-qa-final` |

## Correcoes aplicadas

| Ficheiro | Correcao | Evidencia |
| --- | --- | --- |
| `web/index.html` | Banner de emulador reposicionado para nao tapar bottom navigation | Screenshot mobile final |
```

Se alguma tela continuar bloqueada, documentar assim:

```md
| Detalhe Prestador | Bloqueado | E2E/local nao chegou a estado de detalhe com dados carregados nesta rodada; manter para QA visual com fixture ou fluxo E2E seguinte. |
```

- [ ] **Step 3: Atualizar status M2.10**

Adicionar em `docs/M2_10_VISUAL_PRODUCT_STATUS.md`:

```md
## M2.10.6

Escopo:

```text
QA visual e responsividade Web/Windows/Android
matriz mobile/tablet/desktop/wide
Home Cliente e Home Prestador
listas e detalhe quando ambiente/dados permitirem
banner de emulador sem tapar navegacao
correcoes visuais pequenas/medias
```

## Evidencia M2.10.6

| Comando | Resultado |
| --- | --- |
| `flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true` | pendente ate validacao final |
| `npm.cmd run qa:visual:m2-10-6 -- --base-url=http://127.0.0.1:63776 --out-dir=%TEMP%\\chegaja-m2106-visual-qa-final --wait-ms=12000` | pendente ate validacao final |
| `flutter test` | pendente ate validacao final |
| `npm.cmd run test:scripts` | pendente ate validacao final |
| `npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"` | pendente ate validacao final |
```

Na execucao final, trocar `pendente` pelos resultados reais.

---

### Task 7: Validacoes finais e guardrails

**Files:**
- No code unless fixing failures.

- [ ] **Step 1: Rodar bateria obrigatoria**

Run:

```powershell
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```txt
flutter test: passou
npm.cmd run test:scripts: passou
Firebase emulator tests: 37/37 passou
```

- [ ] **Step 2: Confirmar que ficheiros proibidos nao mudaram**

Run:

```powershell
git diff -- firestore.rules storage.rules functions android/key.properties lib/core/services/pedido_service.dart lib/core/repositories/pedido_repo.dart lib/core/services/location_service.dart lib/core/services/chat_service.dart
```

Expected: sem output.

- [ ] **Step 3: Confirmar status antes do commit**

Run:

```powershell
git status --short
```

Expected: apenas ficheiros da M2.10.6 modificados/adicionados mais os itens
antigos nao stageados:

```txt
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_CHAT_COMPLETA_COMPAT.pptx
 D artifacts/presentation_chegaja/~$ChegaJa_Apresentacao_App_FINAL_COMPAT.pptx
?? .superpowers/
```

- [ ] **Step 4: Stage seletivo**

Stage apenas ficheiros da M2.10.6. Exemplo:

```powershell
git add -- package.json web/index.html scripts/qa/capture_visual_matrix.js scripts/test/capture_visual_matrix.test.js docs/M2_10_VISUAL_QA_REPORT.md docs/M2_10_VISUAL_PRODUCT_STATUS.md
```

Adicionar ficheiros Flutter/testes apenas se foram realmente modificados.

- [ ] **Step 5: Commit e push**

Run:

```powershell
git commit -m "Avancar M2.10.6 responsividade QA visual"
git push origin main
```

Expected: commit no `main`.

---

## Criterios de conclusao

M2.10.6 pode ser considerada avancada quando:

```txt
screenshots Home Cliente desktop/mobile existem
screenshots Home Prestador desktop/mobile existem
banner de emulador nao tapa bottom navigation mobile
problemas visuais encontrados foram classificados
fixes pequenos/medios foram aplicados ou adiados com justificativa
docs/M2_10_VISUAL_QA_REPORT.md foi preenchido
docs/M2_10_VISUAL_PRODUCT_STATUS.md foi atualizado
flutter test passou
npm.cmd run test:scripts passou
Firebase emulator tests passaram
backend/rules/functions/deploy nao foram tocados
M2.6 continua pendente de Android fisico
```

Nao fechar M2.10 automaticamente neste commit. Depois da M2.10.6 avancada, a
decisao de fecho deve ser tomada com base no relatorio visual final.
