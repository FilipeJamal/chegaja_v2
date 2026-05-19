import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

class PedidoNextActionCard extends StatelessWidget {
  final PedidoNextActionData data;

  const PedidoNextActionCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = data.hasUserAction ? colors.primary : Colors.grey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                data.hasUserAction
                    ? Icons.touch_app_rounded
                    : Icons.hourglass_empty_rounded,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            data.nextStep,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
