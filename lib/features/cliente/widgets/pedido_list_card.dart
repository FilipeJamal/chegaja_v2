import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/common/widgets/order_operational_card.dart';
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
    final modeLabel = metaLabels.isEmpty ? null : metaLabels.first;
    final extraMetaLabels = metaLabels.length <= 1
        ? const <String>[]
        : metaLabels.skip(1).toList(growable: false);
    final statusTone = _statusTone(data.tone);
    final mergedFooter = _PedidoListCardFooter(
      metaLabels: extraMetaLabels,
      trailingActions: trailingActions,
      footer: footer,
    );

    return OrderOperationalCard(
      onTap: onTap,
      title: data.title,
      subtitle: data.category,
      leadingIcon: data.icon,
      statusLabel: data.statusLabel,
      statusTone: statusTone,
      statusIcon: data.icon,
      modeLabel: modeLabel,
      modeTone: AppStatusTone.neutral,
      valueLabel: data.valueLabel,
      actionHintLabel: data.actionLabel,
      actionHintTone: statusTone,
      primaryActionLabel:
          onTap != null && trailingActions.isEmpty ? 'Abrir' : null,
      primaryActionIcon: Icons.arrow_forward_rounded,
      onPrimaryPressed: onTap,
      footer: mergedFooter.isEmpty ? null : mergedFooter,
    );
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

class _PedidoListCardFooter extends StatelessWidget {
  const _PedidoListCardFooter({
    required this.metaLabels,
    required this.trailingActions,
    this.footer,
  });

  final List<String> metaLabels;
  final List<Widget> trailingActions;
  final Widget? footer;

  bool get isEmpty =>
      metaLabels.isEmpty && trailingActions.isEmpty && footer == null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (metaLabels.isNotEmpty)
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final label in metaLabels)
                AppStatusPill(
                  label: label,
                  tone: AppStatusTone.neutral,
                  size: AppStatusPillSize.sm,
                ),
            ],
          ),
        if (trailingActions.isNotEmpty) ...[
          if (metaLabels.isNotEmpty) const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            alignment: WrapAlignment.end,
            children: trailingActions,
          ),
        ],
        if (footer != null) ...[
          if (metaLabels.isNotEmpty || trailingActions.isNotEmpty)
            const SizedBox(height: AppSpacing.x3),
          footer!,
        ],
      ],
    );
  }
}
