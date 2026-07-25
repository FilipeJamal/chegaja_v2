const assert = require('assert');

process.env.FUNCTIONS_EMULATOR = 'true';
const { __test__ } = require('../index');

describe('server-side catalogue and Trust & Safety', () => {
  const originalMarketId = process.env.PILOT_MARKET_ID;
  const originalCurrency = process.env.DEFAULT_CURRENCY_CODE;

  beforeEach(() => {
    process.env.PILOT_MARKET_ID = 'mz-maputo';
    process.env.DEFAULT_CURRENCY_CODE = 'MZN';
  });

  after(() => {
    if (originalMarketId === undefined) delete process.env.PILOT_MARKET_ID;
    else process.env.PILOT_MARKET_ID = originalMarketId;
    if (originalCurrency === undefined) delete process.env.DEFAULT_CURRENCY_CODE;
    else process.env.DEFAULT_CURRENCY_CODE = originalCurrency;
  });

  it('blocks prohibited services even when client-side validation is bypassed', () => {
    const blocked = [
      'Quero comprar droga',
      'Preciso de documento falso',
      'Servico para hackear conta',
      'Garota de programa',
    ];
    blocked.forEach((text) => {
      assert.strictEqual(
        __test__.pedidos.classifyServerServiceText([text]).decision,
        'block',
      );
    });
  });

  it('routes ambiguous custom services to human review', () => {
    const result = __test__.pedidos.classifyServerServiceText([
      'Faço de tudo',
      'Ajuda confidencial',
    ]);
    assert.strictEqual(result.decision, 'pending_review');
  });

  it('trusts only an explicitly active server catalogue document', () => {
    assert.strictEqual(__test__.pedidos.catalogDocumentIsActive({ isActive: true }), true);
    assert.strictEqual(__test__.pedidos.catalogDocumentIsActive({ ativo: true }), true);
    assert.strictEqual(__test__.pedidos.catalogDocumentIsActive({ name: 'Limpeza' }), false);
    assert.strictEqual(__test__.pedidos.catalogDocumentIsActive({ isActive: false }), false);
  });

  it('builds category risk from server policy and not from client flags', () => {
    const payload = __test__.pedidos.buildSecurePedidoData({
      uid: 'client1',
      input: {
        titulo: 'Reparar quadro eletrico',
        descricao: 'Uma tomada deixou de funcionar.',
        modo: 'IMEDIATO',
        tipoPreco: 'a_combinar',
        tipoPagamento: 'dinheiro',
        latitude: -25.9692,
        longitude: 32.5732,
        zoneId: 'maputo',
        categoryApprovalRequired: false,
        categoryRiskLevel: 'normal',
      },
      policy: {
        id: 'electricity',
        name: 'Eletricidade',
        riskLevel: 'sensitive',
        approvalRequired: true,
        requirementId: 'electricity',
        requirementName: 'Eletricidade',
      },
      moderationStatus: 'approved',
    });
    assert.strictEqual(payload.clienteId, 'client1');
    assert.strictEqual(payload.categoryApprovalRequired, true);
    assert.strictEqual(payload.categoryRiskLevel, 'sensitive');
    assert.strictEqual(payload.status, 'criado');
  });

  it('does not dispatch requests pending moderation', () => {
    assert.strictEqual(__test__.pedidos.isOpenPedido({
      status: 'criado',
      moderationStatus: 'pending_review',
    }), false);
    assert.strictEqual(__test__.pedidos.isOpenPedido({
      status: 'criado',
      moderationStatus: 'approved',
    }), true);
  });

  it('reclassifies provider custom services on the server', () => {
    const service = __test__.providers.sanitizeProviderCustomService({
      id: 'trusted_by_client',
      title: 'Consultoria de imagem',
      description: 'Organização de guarda-roupa',
      trustSafetyDecision: 'approved',
    });
    assert.strictEqual(service.id, 'custom_consultoria_de_imagem');
    assert.strictEqual(service.trustSafetyDecision, 'allow');

    const blocked = __test__.providers.sanitizeProviderCustomService({
      title: 'Venda de armas',
    });
    assert.strictEqual(blocked.trustSafetyDecision, 'block');
  });
});
