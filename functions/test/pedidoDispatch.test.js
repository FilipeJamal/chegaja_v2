const assert = require('assert');

const { __test__ } = require('../index');

describe('pedido dispatch sanitization', () => {
  it('projects only approximate location and no client identity', () => {
    const projection = __test__.pedidos.buildPedidoDispatchProjection('pedido1', {
      clienteId: 'client-secret',
      clienteNome: 'Nome Completo',
      telefone: '+258 84 123 4567',
      enderecoTexto: 'Rua das Flores 123, Matola A, Matola',
      latitude: -25.9654321,
      longitude: 32.5898765,
      servicoId: 'plumbing',
      servicoNome: 'Canalizacao',
      titulo: 'Cano partido',
      descricao: 'Liga +258 84 123 4567 ou teste@example.com',
      status: 'criado',
    });

    assert.strictEqual(projection.clienteId, undefined);
    assert.strictEqual(projection.clienteNome, undefined);
    assert.strictEqual(projection.telefone, undefined);
    assert.strictEqual(projection.latitude, -25.97);
    assert.strictEqual(projection.longitude, 32.59);
    assert.strictEqual(projection.zoneLabel, 'Matola A, Matola');
    assert(!projection.descricao.includes('123 4567'));
    assert(!projection.descricao.includes('teste@example.com'));
  });

  it('does not leak a one-part address as a zone', () => {
    const projection = __test__.pedidos.buildPedidoDispatchProjection('pedido2', {
      enderecoTexto: 'Avenida 1234 casa 5',
      status: 'criado',
    });
    assert.strictEqual(projection.zoneLabel, 'Zona aproximada');
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
});
