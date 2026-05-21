# M2.11.4 Refatorar Runner E2E Web da Beta Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tornar o runner E2E Web da beta interna confiavel, orientado por estado e capaz de concluir `e2e:ui:dual` e `e2e:ui:orcamento` sem confundir detalhe do pedido, perfil e chat.

**Architecture:** A refatoracao deve manter o runner atual como ponto de entrada, mas extrair helpers puros/testaveis para detectar telas, validar estados Firestore e decidir proximas acoes. A UI so deve receber keys minimas se forem indispensaveis para estabilizar seletores; nenhuma regra de negocio, service, repository, Rules ou Function deve mudar.

**Tech Stack:** Node.js, Playwright, Firebase Admin SDK, Firebase Emulator Suite, Flutter Web local, testes Node em `scripts/test`, testes Flutter existentes.

---

## File Structure

**Create**

- `scripts/e2e/full_ui_dual_role_e2e_helpers.js` - helpers puros do runner: deteccao de tela, resumo de estado do pedido, mensagens de erro e proxima acao esperada.

**Modify**

- `scripts/e2e/full_ui_dual_role_e2e.js` - usar os helpers novos, reduzir coordenadas, adicionar checkpoints de tela/Firestore e melhorar logs.
- `scripts/test/full_ui_dual_role_e2e.test.js` - expandir testes para tela errada, estados do pedido e proxima acao.
- `package.json` - manter `test:scripts` incluindo o teste do runner.
- `docs/M2_11_BETA_INTERNA_STATUS.md` - registar a execucao da M2.11.4.
- `docs/BETA_INTERNA_CHECKLIST_WEB_WINDOWS.md` - atualizar resultado do E2E Web.

**Modify only if needed**

- `lib/features/cliente/pedido_detalhe_screen.dart` - adicionar key/semantics estavel para detalhe do pedido, se o runner nao conseguir distinguir detalhe de chat por seletores existentes.
- `lib/features/common/mensagens/chat_thread_screen.dart` - adicionar key/semantics estavel para tela de chat, se necessario.
- `lib/features/prestador/widgets/prestador_pedido_acoes.dart` - adicionar key/semantics estavel em CTA de estimativa, se a key atual nao aparecer no Web.

**Do Not Touch**

- `functions/**`
- `firestore.rules`
- `storage.rules`
- `lib/core/services/pedido_service.dart`
- `lib/core/repositories/pedido_repo.dart`
- `lib/core/services/location_service.dart`
- `lib/core/services/chat_service.dart`
- `android/key.properties`
- qualquer keystore
- `.superpowers/`
- `artifacts/presentation_chegaja/~$*.pptx`

---

### Task 1: Criar helpers puros do runner

**Files:**
- Create: `scripts/e2e/full_ui_dual_role_e2e_helpers.js`
- Modify: `scripts/test/full_ui_dual_role_e2e.test.js`

- [ ] **Step 1: Adicionar testes para deteccao de tela**

Acrescentar a `scripts/test/full_ui_dual_role_e2e.test.js`:

```js
const helpers = require('../e2e/full_ui_dual_role_e2e_helpers');

assert.strictEqual(
  helpers.detectScreenKind('Voltar\nCliente C\nPesquisar\nVideochamada\nChamada\nAinda nao ha mensagens.'),
  'chat',
  'chat screen should be detected explicitly',
);

assert.strictEqual(
  helpers.detectScreenKind('Detalhe do pedido\nProxima acao\nEnviar estimativa ao cliente\nLinha do tempo'),
  'pedido_detail',
  'pedido detail screen should be detected explicitly',
);

assert.strictEqual(
  helpers.detectScreenKind('Meu perfil\nNome completo\nGuardar alteracoes'),
  'profile',
  'profile screen should not be treated as pedido detail',
);
```

- [ ] **Step 2: Rodar teste e confirmar falha**

Run:

```powershell
node scripts/test/full_ui_dual_role_e2e.test.js
```

Expected:

```text
Cannot find module '../e2e/full_ui_dual_role_e2e_helpers'
```

- [ ] **Step 3: Criar helper minimo**

Criar `scripts/e2e/full_ui_dual_role_e2e_helpers.js`:

```js
function normalizeText(value) {
  return `${value || ''}`
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

function detectScreenKind(bodyText) {
  const text = normalizeText(bodyText);

  if (
    text.includes('videochamada') ||
    text.includes('chamada') ||
    text.includes('ainda nao ha mensagens') ||
    text.includes('digite uma mensagem')
  ) {
    return 'chat';
  }

  if (
    text.includes('detalhe do pedido') ||
    text.includes('proxima acao') ||
    text.includes('linha do tempo') ||
    text.includes('enviar estimativa ao cliente') ||
    text.includes('confirmar valor final')
  ) {
    return 'pedido_detail';
  }

  if (
    text.includes('meu perfil') ||
    text.includes('nome completo') ||
    text.includes('guardar alteracoes') ||
    text.includes('salvar alteracoes')
  ) {
    return 'profile';
  }

  return 'unknown';
}

function assertExpectedScreen({ bodyText, expected, pedidoId, title }) {
  const actual = detectScreenKind(bodyText);
  if (actual !== expected) {
    throw new Error(
      `Expected ${expected} for pedido ${pedidoId || 'unknown'} "${title || 'sem titulo'}", but current screen is ${actual}.`,
    );
  }
  return actual;
}

module.exports = {
  normalizeText,
  detectScreenKind,
  assertExpectedScreen,
};
```

- [ ] **Step 4: Rodar teste e confirmar passagem**

Run:

```powershell
node scripts/test/full_ui_dual_role_e2e.test.js
```

Expected:

```text
full_ui_dual_role_e2e order form detection ok
```

---

### Task 2: Adicionar helpers de estado Firestore e proxima acao

**Files:**
- Modify: `scripts/e2e/full_ui_dual_role_e2e_helpers.js`
- Modify: `scripts/test/full_ui_dual_role_e2e.test.js`

- [ ] **Step 1: Adicionar testes de estado**

Acrescentar a `scripts/test/full_ui_dual_role_e2e.test.js`:

```js
assert.deepStrictEqual(
  helpers.describePedidoState({
    estado: 'aceito',
    status: 'aceito',
    prestadorId: 'provider-1',
    statusProposta: 'nenhuma',
  }),
  {
    estado: 'aceito',
    status: 'aceito',
    prestadorId: 'provider-1',
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: '',
    tipoPreco: '',
  },
  'pedido state summary should be stable',
);

assert.strictEqual(
  helpers.nextProviderAction({
    estado: 'aceito',
    status: 'aceito',
    tipoPreco: 'por_orcamento',
    statusProposta: 'nenhuma',
  }),
  'send_quote',
  'provider should send quote after accepting orçamento pedido',
);

assert.strictEqual(
  helpers.nextProviderAction({
    estado: 'aceito',
    status: 'aceito',
    tipoPreco: 'por_orcamento',
    statusProposta: 'aceita_cliente',
  }),
  'start_service',
  'provider should start service after client accepts quote',
);
```

- [ ] **Step 2: Rodar teste e confirmar falha**

Run:

```powershell
node scripts/test/full_ui_dual_role_e2e.test.js
```

Expected:

```text
TypeError: helpers.describePedidoState is not a function
```

- [ ] **Step 3: Implementar helpers**

Adicionar a `scripts/e2e/full_ui_dual_role_e2e_helpers.js`:

```js
function describePedidoState(data) {
  return {
    estado: `${data?.estado || ''}`,
    status: `${data?.status || ''}`,
    prestadorId: `${data?.prestadorId || ''}`,
    statusProposta: `${data?.statusProposta || ''}`,
    statusConfirmacaoValor: `${data?.statusConfirmacaoValor || ''}`,
    tipoPreco: `${data?.tipoPreco || ''}`,
  };
}

function nextProviderAction(data) {
  const state = describePedidoState(data);

  if (state.tipoPreco === 'por_orcamento' && state.statusProposta !== 'aceita_cliente') {
    return 'send_quote';
  }

  if ((state.estado === 'aceito' || state.status === 'aceito') && state.statusProposta === 'aceita_cliente') {
    return 'start_service';
  }

  if (state.estado === 'em_andamento' || state.status === 'em_andamento') {
    return 'send_final_value';
  }

  return 'wait';
}
```

Exportar os dois nomes em `module.exports`.

- [ ] **Step 4: Rodar teste e confirmar passagem**

Run:

```powershell
node scripts/test/full_ui_dual_role_e2e.test.js
```

Expected:

```text
full_ui_dual_role_e2e order form detection ok
```

---

### Task 3: Integrar protecao contra tela errada no runner

**Files:**
- Modify: `scripts/e2e/full_ui_dual_role_e2e.js`

- [ ] **Step 1: Importar helpers**

No topo de `scripts/e2e/full_ui_dual_role_e2e.js`, adicionar:

```js
const {
  assertExpectedScreen,
  detectScreenKind,
  describePedidoState,
  nextProviderAction,
} = require('./full_ui_dual_role_e2e_helpers');
```

- [ ] **Step 2: Criar helper de texto da pagina**

Adicionar perto dos helpers de pagina:

```js
async function currentBodyText(page) {
  return page.locator('body').innerText({ timeout: 2500 }).catch(() => '');
}

async function ensurePedidoDetailScreen(page, { pedidoId, title, role }) {
  const bodyText = await currentBodyText(page);
  const screen = detectScreenKind(bodyText);
  log(`${role} screen=${screen} expected=pedido_detail pedidoId=${pedidoId} title="${title}"`);
  assertExpectedScreen({ bodyText, expected: 'pedido_detail', pedidoId, title });
}
```

- [ ] **Step 3: Usar protecao antes de enviar orcamento**

Em `providerAcceptAndQuote`, depois de abrir o detalhe e antes de clicar no CTA
de estimativa, adicionar:

```js
await ensurePedidoDetailScreen(provider, {
  pedidoId,
  title: expectedTitle,
  role: 'provider',
});
```

- [ ] **Step 4: Rodar teste de scripts**

Run:

```powershell
npm.cmd run test:scripts
```

Expected:

```text
full_ui_dual_role_e2e order form detection ok
```

---

### Task 4: Reduzir coordenadas no fluxo do prestador

**Files:**
- Modify: `scripts/e2e/full_ui_dual_role_e2e.js`

- [ ] **Step 1: Criar helper para abrir detalhe por titulo**

Garantir que `openOrderDetailByTitle` e usado primeiro no fluxo do prestador.
Em `providerAcceptAndQuote`, substituir qualquer abertura generica por:

```js
const opened = expectedTitle
  ? await openOrderDetailByTitle(provider, expectedTitle, { provider: true })
  : await providerOpenDetail(provider);
```

- [ ] **Step 2: Remover fallback perigoso para chat**

Dentro de `providerOpenDetail`, antes de aceitar uma tela como aberta, validar:

```js
const bodyText = await currentBodyText(provider);
if (detectScreenKind(bodyText) === 'chat') {
  log('providerOpenDetail reached chat instead of pedido detail; going back');
  await provider.goBack().catch(() => {});
  await sleep(700);
  continue;
}
```

- [ ] **Step 3: Falhar com contexto se nao abrir detalhe**

Quando `providerAcceptAndQuote` nao conseguir abrir o detalhe, logar:

```js
log(
  `provider detail not opened pedidoId=${pedidoId} title="${expectedTitle || ''}" state=${JSON.stringify(describePedidoState(lastData))}`,
);
```

- [ ] **Step 4: Rodar teste de scripts**

Run:

```powershell
npm.cmd run test:scripts
```

Expected:

```text
Todos os scripts tests passam.
```

---

### Task 5: Validar E2E Web com seed de servicos

**Files:**
- Modify: `docs/M2_11_BETA_INTERNA_STATUS.md`
- Modify: `docs/BETA_INTERNA_CHECKLIST_WEB_WINDOWS.md`

- [ ] **Step 1: Preparar Web local**

Run:

```powershell
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173 --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```

Expected:

```text
Servidor disponivel em http://127.0.0.1:5173.
```

- [ ] **Step 2: Rodar E2E dual com seed**

Run:

```powershell
npx.cmd firebase emulators:exec --only auth,firestore,storage "node scripts/seed_servicos.js --emulator-host=127.0.0.1 && npm.cmd run e2e:ui:dual"
```

Expected:

```text
E2E dual passa ou falha com mensagem explicita contendo pedidoId, title, tela esperada e tela atual.
```

- [ ] **Step 3: Rodar E2E orcamento com seed**

Run:

```powershell
npx.cmd firebase emulators:exec --only auth,firestore,storage "node scripts/seed_servicos.js --emulator-host=127.0.0.1 && npm.cmd run e2e:ui:orcamento"
```

Expected:

```text
E2E orcamento passa ou falha com mensagem explicita contendo pedidoId, title, tela esperada e tela atual.
```

- [ ] **Step 4: Atualizar status**

Adicionar a `docs/M2_11_BETA_INTERNA_STATUS.md`:

~~~markdown
## M2.11.4 - Refatoracao runner E2E Web beta

```text
runner orientado por estado e tela esperada
detalhe/chat/perfil distinguiveis por helper
dual: registar "passou" ou "bloqueado" com a mensagem final do runner
orcamento: registar "passou" ou "bloqueado" com a mensagem final do runner
decisao beta Web: aprovada apenas se dual e orcamento passarem
```
~~~

- [ ] **Step 5: Atualizar checklist**

Adicionar a `docs/BETA_INTERNA_CHECKLIST_WEB_WINDOWS.md`:

~~~markdown
## Execucao M2.11.4 - Runner E2E Web

```text
e2e:ui:dual: registar passou ou bloqueado com pedidoId/title quando falhar
e2e:ui:orcamento: registar passou ou bloqueado com pedidoId/title quando falhar
bloqueios restantes: listar os bloqueios objetivos ou escrever "nenhum"
```
~~~

---

### Task 6: Validacoes finais

**Files:**
- All changed files

- [ ] **Step 1: Rodar Flutter tests**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed.
```

- [ ] **Step 2: Rodar scripts tests**

Run:

```powershell
npm.cmd run test:scripts
```

Expected:

```text
Todos os scripts tests passam, incluindo full_ui_dual_role_e2e.test.js.
```

- [ ] **Step 3: Rodar Firebase emulator tests**

Run:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Expected:

```text
37 passing
Script exited successfully
```

- [ ] **Step 4: Confirmar arquivos fora do escopo**

Run:

```powershell
git status --short
```

Expected:

```text
.superpowers/ e artifacts/presentation_chegaja/~$*.pptx continuam fora do commit.
Nao ha mudancas em functions, rules, services ou repositories.
```

---

### Task 7: Commit

**Files:**
- Commit only M2.11.4 files

- [ ] **Step 1: Stage seletivo**

Run:

```powershell
git add -- scripts/e2e/full_ui_dual_role_e2e.js scripts/e2e/full_ui_dual_role_e2e_helpers.js scripts/test/full_ui_dual_role_e2e.test.js docs/M2_11_BETA_INTERNA_STATUS.md docs/BETA_INTERNA_CHECKLIST_WEB_WINDOWS.md
```

If UI keys were added, include only the specific UI files touched.

- [ ] **Step 2: Commit**

Run:

```powershell
git commit -m "Avancar M2.11.4 refatorar runner E2E Web beta"
```

- [ ] **Step 3: Push**

Run:

```powershell
git push origin main
```

---

## Self-Review

Spec coverage:

```text
Auditoria do runner: Task 1-4.
Helpers claros: Task 1-2.
Checkpoints Firestore/tela: Task 2-4.
Evitar chat/detalhe errado: Task 1 e Task 3.
Logs melhores: Task 3-4.
E2E dual/orcamento: Task 5.
Docs/status: Task 5.
Validacoes finais: Task 6.
```

Scope check:

```text
O plano nao altera backend, Rules, Functions, deploy, pagamentos, Play Store,
Android fisico ou M2.6. UI so entra se for necessario adicionar keys estaveis
sem mudar UX.
```
