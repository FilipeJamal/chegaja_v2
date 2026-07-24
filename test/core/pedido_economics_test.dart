import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/utils/pedido_economics.dart';
import 'package:flutter_test/flutter_test.dart';

Pedido _pedido({
  double? total,
  double? commission,
  double? providerEarnings,
}) {
  return Pedido(
    id: 'economics',
    clienteId: 'cliente',
    prestadorId: 'prestador',
    servicoId: 'srv_limpeza',
    servicoNome: 'Limpeza',
    titulo: 'Limpeza semanal',
    descricao: 'Apartamento T2',
    modo: 'AGENDADO',
    status: 'concluido',
    tipoPreco: 'fixo',
    tipoPagamento: 'dinheiro',
    statusProposta: 'aceita_cliente',
    statusConfirmacaoValor: 'confirmado_cliente',
    precoFinal: total ?? 100,
    earningsTotal: total,
    commissionPlatform: commission,
    earningsProvider: providerEarnings,
    createdAt: DateTime(2026, 7, 20),
    updatedAt: DateTime(2026, 7, 20),
  );
}

void main() {
  test('aceita apenas o trio financeiro persistido e consistente', () {
    final economics = pedidoAuthoritativeEconomics(
      _pedido(total: 100, commission: 10, providerEarnings: 90),
    );

    expect(economics, isNotNull);
    expect(economics!.total, 100);
    expect(economics.commission, 10);
    expect(economics.providerEarnings, 90);
  });

  test('rejeita campos parciais ou matematicamente inconsistentes', () {
    expect(
      pedidoAuthoritativeEconomics(
        _pedido(total: null, commission: 10, providerEarnings: 90),
      ),
      isNull,
    );
    expect(
      pedidoAuthoritativeEconomics(
        _pedido(total: 100, commission: 10, providerEarnings: 70),
      ),
      isNull,
    );
  });

  test('total persistido nunca usa proposta ou intervalo estimado', () {
    final onlyEstimate = Pedido(
      id: 'estimated',
      clienteId: 'cliente',
      prestadorId: 'prestador',
      servicoId: 'srv_limpeza',
      servicoNome: 'Limpeza',
      titulo: 'Limpeza semanal',
      descricao: 'Apartamento T2',
      modo: 'AGENDADO',
      status: 'concluido',
      tipoPreco: 'por_orcamento',
      tipoPagamento: 'dinheiro',
      statusProposta: 'aceita_cliente',
      statusConfirmacaoValor: 'confirmado_cliente',
      precoPropostoPrestador: 100,
      valorMinEstimadoPrestador: 80,
      valorMaxEstimadoPrestador: 120,
      createdAt: DateTime(2026, 7, 20),
    );

    expect(pedidoPersistedGross(onlyEstimate), isNull);
    expect(
      pedidoPersistedGross(onlyEstimate.copyWith(precoFinal: 95)),
      95,
    );
  });
}
