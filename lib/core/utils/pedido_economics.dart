import 'package:chegaja_v2/core/models/pedido.dart';

class PedidoAuthoritativeEconomics {
  const PedidoAuthoritativeEconomics({
    required this.total,
    required this.commission,
    required this.providerEarnings,
  });

  final double total;
  final double commission;
  final double providerEarnings;
}

/// Retorna apenas um total persistido para um trabalho concluído.
///
/// Propostas e intervalos estimados não são prova de faturação e, por isso,
/// nunca entram neste fallback.
double? pedidoPersistedGross(Pedido pedido) {
  for (final value in <double?>[
    pedido.earningsTotal,
    pedido.precoFinal,
  ]) {
    if (value != null && value.isFinite && value > 0) {
      return value;
    }
  }
  return null;
}

PedidoAuthoritativeEconomics? pedidoAuthoritativeEconomics(Pedido pedido) {
  final total = pedido.earningsTotal;
  final commission = pedido.commissionPlatform;
  final providerEarnings = pedido.earningsProvider;
  if (total == null || commission == null || providerEarnings == null) {
    return null;
  }
  if (!total.isFinite ||
      !commission.isFinite ||
      !providerEarnings.isFinite ||
      total <= 0 ||
      commission < 0 ||
      providerEarnings < 0) {
    return null;
  }

  final tolerance = total.abs() * 0.001 < 0.01 ? 0.01 : total.abs() * 0.001;
  if ((commission + providerEarnings - total).abs() > tolerance) {
    return null;
  }

  return PedidoAuthoritativeEconomics(
    total: total,
    commission: commission,
    providerEarnings: providerEarnings,
  );
}
