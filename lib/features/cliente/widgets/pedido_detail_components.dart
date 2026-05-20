import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/utils/currency_utils.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_metric_tile.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_next_action_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_summary.dart';

class PedidoDetailLayout extends StatelessWidget {
  const PedidoDetailLayout({
    super.key,
    required this.mainColumn,
    required this.sidePanel,
  });

  final Widget mainColumn;
  final Widget sidePanel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const Key('pedido_detail_layout'),
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 980;

        if (!useTwoColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KeyedSubtree(
                key: const Key('pedido_detail_side_panel_slot'),
                child: sidePanel,
              ),
              const SizedBox(height: AppSpacing.x4),
              KeyedSubtree(
                key: const Key('pedido_detail_main_column'),
                child: mainColumn,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: KeyedSubtree(
                key: const Key('pedido_detail_main_column'),
                child: mainColumn,
              ),
            ),
            const SizedBox(width: AppSpacing.x5),
            SizedBox(
              width: 360,
              child: KeyedSubtree(
                key: const Key('pedido_detail_side_panel_slot'),
                child: sidePanel,
              ),
            ),
          ],
        );
      },
    );
  }
}

class PedidoDetailSidePanel extends StatelessWidget {
  const PedidoDetailSidePanel({
    super.key,
    required this.pedido,
    required this.summary,
    required this.nextAction,
    this.actions,
  });

  final Pedido pedido;
  final PedidoStatusSummaryData summary;
  final PedidoNextActionData nextAction;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('pedido_detail_side_panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PedidoStatusSummary(data: summary),
        const SizedBox(height: AppSpacing.x3),
        PedidoNextActionCard(data: nextAction),
        const SizedBox(height: AppSpacing.x3),
        PedidoValueSummary(pedido: pedido),
        if (actions != null) ...[
          const SizedBox(height: AppSpacing.x3),
          actions!,
        ],
      ],
    );
  }
}

class PedidoValueSummary extends StatelessWidget {
  const PedidoValueSummary({
    super.key,
    required this.pedido,
  });

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final data = _PedidoValueSummaryData.fromPedido(pedido);

    return AppMetricTile(
      key: const Key('pedido_value_summary'),
      label: data.title,
      value: data.value,
      supportingText: data.supportingText,
      icon: data.icon,
      tone: data.tone,
    );
  }
}

class PedidoActionPanelSection extends StatelessWidget {
  const PedidoActionPanelSection({
    super.key,
    required this.title,
    required this.message,
    required this.child,
    this.icon = Icons.touch_app_rounded,
    this.tone = AppStatusTone.info,
  });

  final String title;
  final String message;
  final Widget child;
  final IconData icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('pedido_action_panel_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppActionPanel(
          title: title,
          message: message,
          icon: icon,
          tone: tone,
        ),
        const SizedBox(height: AppSpacing.x3),
        child,
      ],
    );
  }
}

class _PedidoValueSummaryData {
  const _PedidoValueSummaryData({
    required this.title,
    required this.value,
    required this.supportingText,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String value;
  final String supportingText;
  final IconData icon;
  final AppStatusTone tone;

  static _PedidoValueSummaryData fromPedido(Pedido pedido) {
    String money(double value) => CurrencyUtils.format(value);

    if (pedido.precoFinal != null &&
        pedido.statusConfirmacaoValor == 'confirmado_cliente') {
      return _PedidoValueSummaryData(
        title: 'Valor confirmado',
        value: money(pedido.precoFinal!),
        supportingText: 'Backend calcula comissao e ganhos do prestador.',
        icon: Icons.verified_rounded,
        tone: AppStatusTone.success,
      );
    }

    if (pedido.precoPropostoPrestador != null &&
        (pedido.statusConfirmacaoValor == 'pendente_cliente' ||
            pedido.estado == 'aguarda_confirmacao_valor')) {
      return _PedidoValueSummaryData(
        title: 'Valor final pendente',
        value: money(pedido.precoPropostoPrestador!),
        supportingText: 'O cliente precisa confirmar antes de concluir.',
        icon: Icons.price_check_rounded,
        tone: AppStatusTone.warning,
      );
    }

    final min = pedido.valorMinEstimadoPrestador;
    final max = pedido.valorMaxEstimadoPrestador;
    if (min != null && max != null) {
      return _PedidoValueSummaryData(
        title: 'Faixa estimada',
        value: '${money(min)} - ${money(max)}',
        supportingText: 'Nao e o valor final. O valor final vem depois.',
        icon: Icons.request_quote_rounded,
        tone: AppStatusTone.info,
      );
    }

    if (min != null || max != null) {
      final value = min != null ? 'Desde ${money(min)}' : 'Ate ${money(max!)}';
      return _PedidoValueSummaryData(
        title: 'Faixa estimada',
        value: value,
        supportingText: 'Nao e o valor final. O valor final vem depois.',
        icon: Icons.request_quote_rounded,
        tone: AppStatusTone.info,
      );
    }

    if (pedido.precoFinal != null) {
      return _PedidoValueSummaryData(
        title: 'Valor final',
        value: money(pedido.precoFinal!),
        supportingText: 'Consulta o estado para saber se ja foi confirmado.',
        icon: Icons.euro_rounded,
        tone: AppStatusTone.info,
      );
    }

    return const _PedidoValueSummaryData(
      title: 'Valor a combinar',
      value: 'A combinar',
      supportingText: 'O valor final sera definido no fluxo do pedido.',
      icon: Icons.euro_rounded,
      tone: AppStatusTone.neutral,
    );
  }
}
