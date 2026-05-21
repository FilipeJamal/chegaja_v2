function normalizeText(value) {
  return `${value || ''}`
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

function detectScreenKind(bodyText) {
  const text = normalizeText(bodyText);

  if (
    text.includes('ainda nao ha mensagens') ||
    text.includes('digite uma mensagem') ||
    (text.includes('videochamada') && text.includes('mostrar menu')) ||
    (text.includes('chamada') && text.includes('mostrar menu'))
  ) {
    return 'chat';
  }

  if (
    text.includes('detalhe do pedido') ||
    text.includes('proxima acao') ||
    text.includes('linha do tempo') ||
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

module.exports = {
  normalizeText,
  detectScreenKind,
  assertExpectedScreen,
  describePedidoState,
  nextProviderAction,
};
