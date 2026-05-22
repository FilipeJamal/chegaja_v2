const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const helpers = require('../e2e/full_ui_dual_role_e2e_helpers');

function extractFunction(source, name) {
  const marker = `async function ${name}`;
  const start = source.indexOf(marker);
  assert.notStrictEqual(start, -1, `Function ${name} not found`);

  const openBrace = source.indexOf('{', start);
  let depth = 0;
  for (let index = openBrace; index < source.length; index += 1) {
    const char = source[index];
    if (char === '{') depth += 1;
    if (char === '}') depth -= 1;
    if (depth === 0) return source.slice(start, index + 1);
  }

  throw new Error(`Could not extract ${name}`);
}

function visibleLocator(value) {
  return {
    first() {
      return this;
    },
    async isVisible() {
      return value;
    },
  };
}

function fakePage({ inputVisible, textAreaVisible, orderSubmitVisible, profileSubmitVisible }) {
  return {
    locator(selector) {
      if (selector.startsWith('input')) return visibleLocator(inputVisible);
      if (selector.startsWith('textarea')) return visibleLocator(textAreaVisible);
      return visibleLocator(false);
    },
    getByText(pattern) {
      const source = pattern instanceof RegExp ? pattern.source : String(pattern);
      const matchesOrderSubmit = /Pedir|Request/.test(source) && orderSubmitVisible;
      const matchesProfileSubmit = /Guardar|Save/.test(source) && profileSubmitVisible;
      return visibleLocator(matchesOrderSubmit || matchesProfileSubmit);
    },
  };
}

const scriptPath = path.join(process.cwd(), 'scripts', 'e2e', 'full_ui_dual_role_e2e.js');
const scriptSource = fs.readFileSync(scriptPath, 'utf8');
const isOnOrderForm = vm.runInNewContext(`(${extractFunction(scriptSource, 'isOnOrderForm')})`);

(async () => {
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

  assert.notStrictEqual(
    helpers.detectScreenKind(
      'Pedidos\nEm aberto 1\nAbrir\nC Cliente E2E-HAPPY-123456\nEnviar estimativa ao cliente\nCancelar trabalho',
    ),
    'pedido_detail',
    'provider order lists must not be treated as pedido detail just because an action label is visible',
  );

  assert.strictEqual(
    helpers.detectScreenKind('Meu perfil\nNome completo\nGuardar alteracoes'),
    'profile',
    'profile screen should not be treated as pedido detail',
  );

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

  assert.deepStrictEqual(
    helpers.summarizeClientOrdersBody('Meus pedidos\nPendentes 0\nSem pedidos ativos'),
    {
      hasMyOrders: true,
      hasPendingZero: true,
      hasEmptyActive: true,
      screen: 'unknown',
    },
    'client order empty-state summary should detect the BUG-004 symptom',
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

  assert.strictEqual(
    await isOnOrderForm(
      fakePage({
        inputVisible: true,
        textAreaVisible: true,
        orderSubmitVisible: false,
        profileSubmitVisible: true,
      }),
    ),
    false,
    'profile edit forms must not be treated as order forms',
  );

  assert.strictEqual(
    await isOnOrderForm(
      fakePage({
        inputVisible: true,
        textAreaVisible: true,
        orderSubmitVisible: true,
        profileSubmitVisible: false,
      }),
    ),
    true,
    'order forms with the order submit CTA should be detected',
  );

  console.log('full_ui_dual_role_e2e order form detection ok');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
