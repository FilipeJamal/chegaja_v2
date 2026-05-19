import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

class PedidoStatusSummary extends StatelessWidget {
  final PedidoStatusSummaryData data;

  const PedidoStatusSummary({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final toneColor = switch (data.tone) {
      PedidoStatusTone.success => Colors.green,
      PedidoStatusTone.warning => Colors.orange,
      PedidoStatusTone.danger => colors.error,
      PedidoStatusTone.neutral => Colors.grey,
      PedidoStatusTone.info => colors.primary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: toneColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: toneColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.description,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  data.actor,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: toneColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
