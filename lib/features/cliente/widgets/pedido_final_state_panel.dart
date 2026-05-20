import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';

class PedidoFinalStatePanel extends StatelessWidget {
  final PedidoFinalStateData data;

  const PedidoFinalStatePanel({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppStatusPill(
                  label: data.title,
                  tone: data.title.toLowerCase().contains('cancel')
                      ? AppStatusTone.danger
                      : AppStatusTone.success,
                  icon: data.icon,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  data.message,
                  style: theme.textTheme.bodyMedium,
                ),
                if (data.detail != null) ...[
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    data.detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.x2),
                Text(
                  data.actionHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
