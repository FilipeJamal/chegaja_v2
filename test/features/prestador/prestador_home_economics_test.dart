import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/prestador/prestador_home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Pedido _pedido({
  required String id,
  required DateTime completedAt,
  double price = 100,
  double? total,
  double? commission,
  double? providerEarnings,
}) {
  return Pedido(
    id: id,
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
    precoFinal: price,
    earningsTotal: total,
    commissionPlatform: commission,
    earningsProvider: providerEarnings,
    createdAt: completedAt.subtract(const Duration(hours: 2)),
    updatedAt: completedAt,
  );
}

void main() {
  test(
      'agregado diário não inventa comissão quando um trabalho está incompleto',
      () {
    final now = DateTime(2026, 7, 20, 18);
    final summary = prestadorDailyEconomicsSummary([
      _pedido(
        id: 'complete',
        completedAt: DateTime(2026, 7, 20, 12),
        total: 100,
        commission: 0,
        providerEarnings: 100,
      ),
      _pedido(
        id: 'incomplete',
        completedAt: DateTime(2026, 7, 20, 13),
        price: 50,
      ),
    ], now);

    expect(summary.grossToday, 150);
    expect(summary.commissionToday, isNull);
    expect(summary.providerEarningsToday, isNull);
    expect(summary.servicesThisMonth, 2);
  });

  test('agregado diário soma apenas trios financeiros autoritativos', () {
    final now = DateTime(2026, 7, 20, 18);
    final summary = prestadorDailyEconomicsSummary([
      _pedido(
        id: 'complete',
        completedAt: DateTime(2026, 7, 20, 12),
        total: 100,
        commission: 10,
        providerEarnings: 90,
      ),
    ], now);

    expect(summary.grossToday, 100);
    expect(summary.commissionToday, 10);
    expect(summary.providerEarningsToday, 90);
    expect(summary.servicesThisMonth, 1);
  });
}
