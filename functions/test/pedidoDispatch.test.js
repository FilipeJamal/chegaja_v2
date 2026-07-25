const assert = require('assert');

const { __test__ } = require('../index');
const {
  buildPedidoDispatchProjection: buildReconcilerProjection,
} = require('../../scripts/admin/reconcile_pedido_dispatch');

const ACTIVE_MARKET_ID = 'mz-maputo';
const ACTIVE_CURRENCY = 'MZN';

describe('pedido dispatch sanitization', () => {
  let previousMarketId;
  let previousCurrency;

  beforeEach(() => {
    previousMarketId = process.env.PILOT_MARKET_ID;
    previousCurrency = process.env.DEFAULT_CURRENCY_CODE;
    process.env.PILOT_MARKET_ID = ACTIVE_MARKET_ID;
    process.env.DEFAULT_CURRENCY_CODE = ACTIVE_CURRENCY;
  });

  afterEach(() => {
    if (previousMarketId === undefined) delete process.env.PILOT_MARKET_ID;
    else process.env.PILOT_MARKET_ID = previousMarketId;
    if (previousCurrency === undefined) delete process.env.DEFAULT_CURRENCY_CODE;
    else process.env.DEFAULT_CURRENCY_CODE = previousCurrency;
  });

  function pedidoFixture(data = {}) {
    return {
      marketId: ACTIVE_MARKET_ID,
      currency: ACTIVE_CURRENCY,
      ...data,
    };
  }

  it('projects only structured fields, approximate location and no client-authored text', () => {
    const scheduledAt = { seconds: 1780000000, nanoseconds: 0 };
    const projection = __test__.pedidos.buildPedidoDispatchProjection('pedido1', pedidoFixture({
      clienteId: 'client-secret',
      clienteNome: 'Nome Completo',
      telefone: '+258 84 123 4567',
      enderecoTexto: 'Rua das Flores 123, Matola A, Matola',
      bairro: 'Matola A',
      city: 'Matola',
      latitude: -25.9654321,
      longitude: 32.5898765,
      servicoId: 'plumbing',
      servicoNome: 'Canalização',
      categoria: 'Casa e reparações',
      titulo: 'Cano partido na casa da Dona Maria',
      descricao: 'Liga +258 84 123 4567 ou teste@example.com. Porta azul.',
      customServiceDescription: 'Perto da escola, falar com a cliente.',
      anexos: ['pedidos/pedido1/anexos/foto-porta.jpg'],
      tipoPagamento: 'dinheiro',
      modo: 'AGENDADO',
      agendadoPara: scheduledAt,
      tipoPreco: 'por_orcamento',
      status: 'criado',
    }));

    const forbiddenFields = [
      'anexos',
      'clienteId',
      'clienteNome',
      'customServiceDescription',
      'customServiceName',
      'descricao',
      'telefone',
      'tipoPagamento',
      'titulo',
    ];
    forbiddenFields.forEach((field) => assert.strictEqual(projection[field], undefined));
    assert.deepStrictEqual(Object.keys(projection).sort(), [
      'agendadoPara',
      'categoria',
      'categoryApprovalRequired',
      'categoryRequirementId',
      'categoryRequirementName',
      'categoryRiskLevel',
      'createdAt',
      'currency',
      'enderecoTexto',
      'estado',
      'isCustomService',
      'latitude',
      'longitude',
      'marketId',
      'modo',
      'pedidoId',
      'prestadorId',
      'propostaExpiresAt',
      'servicoId',
      'servicoNome',
      'status',
      'statusProposta',
      'targetProviderId',
      'tipoPreco',
      'updatedAt',
      'valorMaxEstimadoPrestador',
      'valorMinEstimadoPrestador',
      'zoneLabel',
    ]);
    const market = __test__.pilot.configuredPilotMarket();
    assert.strictEqual(projection.marketId, market.id);
    assert.strictEqual(projection.currency, market.currency);
    assert.strictEqual(projection.latitude, -25.97);
    assert.strictEqual(projection.longitude, 32.59);
    assert.strictEqual(projection.zoneLabel, 'Matola A, Matola');
    assert.strictEqual(projection.enderecoTexto, 'Matola A, Matola');
    assert.strictEqual(projection.modo, 'AGENDADO');
    assert.strictEqual(projection.agendadoPara, scheduledAt);
    assert.strictEqual(projection.tipoPreco, 'por_orcamento');

    const serialized = JSON.stringify(projection);
    for (const leakedValue of [
      'client-secret',
      'Nome Completo',
      '+258 84 123 4567',
      'teste@example.com',
      'Rua das Flores',
      'Dona Maria',
      'Porta azul',
    ]) {
      assert(!serialized.includes(leakedValue), `dispatch leaked ${leakedValue}`);
    }
  });

  it('targets a quote without exposing its free-text message or private grant', () => {
    const expiresAt = { seconds: 1780000000, nanoseconds: 0 };
    const projection = __test__.pedidos.buildPedidoDispatchProjection('pedido_target', pedidoFixture({
      clienteId: 'client-secret',
      prestadorId: 'provider1',
      status: 'aguarda_resposta_cliente',
      tipoPreco: 'por_orcamento',
      valorMinEstimadoPrestador: 500,
      valorMaxEstimadoPrestador: 750,
      statusProposta: 'pendente_cliente',
      propostaExpiresAt: expiresAt,
      mensagemPropostaPrestador: 'Ligue-me no +258 84 123 4567.',
      providerAccessGranted: true,
      providerAccessGrantedTo: 'provider1',
      enderecoTexto: 'Rua privada 123',
      bairro: 'Zona Norte',
      city: 'Maputo',
    }));

    assert.strictEqual(projection.prestadorId, null);
    assert.strictEqual(projection.targetProviderId, 'provider1');
    assert.strictEqual(projection.valorMinEstimadoPrestador, 500);
    assert.strictEqual(projection.valorMaxEstimadoPrestador, 750);
    assert.strictEqual(projection.statusProposta, 'pendente_cliente');
    assert.strictEqual(projection.propostaExpiresAt, expiresAt);
    assert.strictEqual(projection.mensagemPropostaPrestador, undefined);
    assert.strictEqual(projection.providerAccessGranted, undefined);
    assert.strictEqual(projection.providerAccessGrantedTo, undefined);
    assert(!JSON.stringify(projection).includes('+258 84 123 4567'));
    assert(!JSON.stringify(projection).includes('Rua privada 123'));
  });

  it('never derives the public zone from a Portuguese free-text address', () => {
    const projection = __test__.pedidos.buildPedidoDispatchProjection('pedido2', pedidoFixture({
      enderecoTexto: 'Rua das Acácias, casa 15, perto da Escola Primária, Maputo',
      status: 'criado',
    }));
    assert.strictEqual(projection.zoneLabel, 'Zona aproximada');
    assert.strictEqual(projection.enderecoTexto, 'Zona aproximada');
    assert(!JSON.stringify(projection).includes('Escola Primária'));
  });

  it('removes Mozambique phone, email and address references from a structured zone', () => {
    const projection = __test__.pedidos.buildPedidoDispatchProjection('pedido3', pedidoFixture({
      dispatchZone: 'Rua da Igreja, contacto +258 86 987 6543, apoio@exemplo.co.mz, Matola',
      status: 'criado',
    }));
    assert.strictEqual(projection.zoneLabel, 'Matola');
    const serialized = JSON.stringify(projection);
    assert(!serialized.includes('Rua da Igreja'));
    assert(!serialized.includes('+258 86 987 6543'));
    assert(!serialized.includes('apoio@exemplo.co.mz'));
  });

  it('never publishes custom-service labels containing international contact or address data', () => {
    const projection = __test__.pedidos.buildPedidoDispatchProjection('pedido_custom', pedidoFixture({
      isCustomService: true,
      servicoNome: 'Costura na Rua das Flores 12, ligar +351 912 345 678',
      categoria: 'Costura na Rua das Flores 12, ligar +351 912 345 678',
      bairro: 'Santo António dos Olivais',
      city: 'Coimbra',
      status: 'criado',
    }));

    assert.strictEqual(projection.servicoNome, 'Serviço personalizado');
    assert.strictEqual(projection.categoria, 'Serviço personalizado');
    const serialized = JSON.stringify(projection);
    assert(!serialized.includes('Rua das Flores'));
    assert(!serialized.includes('+351 912 345 678'));
  });

  it('builds the pre-acceptance push only from structured dispatch data', () => {
    const notification = __test__.pedidos.buildPedidoOpportunityNotification('pedido4', pedidoFixture({
      servicoId: 'plumbing',
      servicoNome: 'Canalização',
      bairro: 'Matola A',
      city: 'Matola',
      modo: 'AGENDADO',
      titulo: 'URGENTE: liga para +258 84 123 4567',
      descricao: 'Rua da Liberdade 44, porta verde; cliente@exemplo.co.mz',
      enderecoTexto: 'Rua da Liberdade 44, Matola A, Matola',
      status: 'criado',
    }));

    assert.strictEqual(notification.title, 'ChegaJá - Novo pedido perto de ti');
    assert(notification.body.includes('Canalização'));
    assert(notification.body.includes('Matola A, Matola'));
    assert(notification.body.includes('Horário agendado'));
    assert.deepStrictEqual(notification.data, {
      type: 'novo_pedido',
      pedidoId: 'pedido4',
    });

    const serialized = JSON.stringify(notification);
    for (const leakedValue of [
      'URGENTE',
      '+258 84 123 4567',
      'Rua da Liberdade',
      'porta verde',
      'cliente@exemplo.co.mz',
    ]) {
      assert(!serialized.includes(leakedValue), `push leaked ${leakedValue}`);
    }
  });

  it('enforces service and sensitive-category eligibility', () => {
    assert.strictEqual(__test__.pedidos.providerMatchesPedido(
      { servicos: ['electricity'], approvedSensitiveCategoryIds: [] },
      { servicoId: 'electricity' },
    ), true);
    assert.strictEqual(__test__.pedidos.providerMatchesPedido(
      { servicos: ['electricity'], approvedSensitiveCategoryIds: [] },
      { servicoId: 'electricity', categoryApprovalRequired: true },
    ), false);
  });

  it('fails closed for missing or conflicting lifecycle aliases', () => {
    assert.strictEqual(__test__.pedidos.isOpenPedido({
      status: 'criado',
      estado: 'cancelado',
      moderationStatus: 'approved',
    }), false);
    assert.strictEqual(__test__.pedidos.isOpenPedido({
      estado: 'criado',
      moderationStatus: 'approved',
    }), false);
    assert.strictEqual(__test__.pedidos.isOpenPedido({
      status: 'criado',
      estado: 'criado',
      moderationStatus: 'approved',
    }), true);
  });

  it('keeps the runtime and legacy reconciler projection contracts identical', () => {
    const fixtures = [
      pedidoFixture({
        status: 'criado',
        estado: 'criado',
        moderationStatus: 'approved',
        servicoId: 'plumbing',
        servicoNome: 'Canalização +351 912 345 678',
        bairro: 'Rua 10, Coimbra',
        city: 'Coimbra',
        latitude: 40.20561,
        longitude: -8.41392,
        createdAt: new Date('2026-07-20T10:00:00.000Z'),
      }),
      pedidoFixture({
        status: 'aguarda_resposta_prestador',
        estado: 'aguarda_resposta_prestador',
        prestadorId: 'provider-contract',
        moderationStatus: 'approved',
        modo: 'POR_PROPOSTA',
        tipoPreco: 'por_orcamento',
        valorMinEstimadoPrestador: 100,
        valorMaxEstimadoPrestador: 200,
        statusProposta: 'pendente_prestador',
        createdAt: new Date('2026-07-20T10:00:00.000Z'),
      }),
      pedidoFixture({
        status: 'criado',
        estado: 'criado',
        moderationStatus: 'approved',
        isCustomService: true,
        servicoNome: 'Texto privado que não pode sair',
        createdAt: new Date('2026-07-20T10:00:00.000Z'),
      }),
    ];

    fixtures.forEach((fixture, index) => {
      const runtime = __test__.pedidos.buildPedidoDispatchProjection(
        `contract-${index}`,
        fixture,
      );
      const reconciler = buildReconcilerProjection(`contract-${index}`, fixture);
      delete runtime.updatedAt;
      delete reconciler.updatedAt;
      assert.deepStrictEqual(reconciler, runtime);
    });
  });
});
