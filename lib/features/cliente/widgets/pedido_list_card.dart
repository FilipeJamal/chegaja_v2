import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

class PedidoListCard extends StatelessWidget {
  final PedidoListCardData data;
  final VoidCallback? onTap;
  final List<String> metaLabels;
  final List<Widget> trailingActions;
  final Widget? footer;

  const PedidoListCard({
    super.key,
    required this.data,
    this.onTap,
    this.metaLabels = const [],
    this.trailingActions = const [],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toneColor = _toneColor(theme, data.tone);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: toneColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(data.icon, color: toneColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      data.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              AppStatusPill(
                label: data.statusLabel,
                tone: _statusTone(data.tone),
                size: AppStatusPillSize.sm,
                icon: data.icon,
              ),
              for (final label in metaLabels)
                AppStatusPill(
                  label: label,
                  tone: AppStatusTone.neutral,
                  size: AppStatusPillSize.sm,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            data.valueLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          AppCard(
            variant: AppCardVariant.flat,
            size: AppCardSize.compact,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  data.hasUserAction
                      ? Icons.priority_high_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: toneColor,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    data.actionLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: toneColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailingActions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              alignment: WrapAlignment.end,
              children: trailingActions,
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.x3),
            footer!,
          ],
        ],
      ),
    );
  }

  Color _toneColor(ThemeData theme, PedidoStatusTone tone) {
    return switch (tone) {
      PedidoStatusTone.success => AppPalette.success,
      PedidoStatusTone.warning => AppPalette.warning,
      PedidoStatusTone.danger => theme.colorScheme.error,
      PedidoStatusTone.neutral => theme.colorScheme.onSurfaceVariant,
      PedidoStatusTone.info => theme.colorScheme.primary,
    };
  }

  AppStatusTone _statusTone(PedidoStatusTone tone) {
    return switch (tone) {
      PedidoStatusTone.success => AppStatusTone.success,
      PedidoStatusTone.warning => AppStatusTone.warning,
      PedidoStatusTone.danger => AppStatusTone.danger,
      PedidoStatusTone.neutral => AppStatusTone.neutral,
      PedidoStatusTone.info => AppStatusTone.info,
    };
  }
}
