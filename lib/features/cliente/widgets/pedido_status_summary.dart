import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

class PedidoStatusSummary extends StatelessWidget {
  final PedidoStatusSummaryData data;

  const PedidoStatusSummary({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      title: data.title,
      message: '${data.description}\n${data.actor}',
      icon: data.icon,
      tone: _toneFor(data.tone),
    );
  }

  AppStatusTone _toneFor(PedidoStatusTone tone) {
    return switch (tone) {
      PedidoStatusTone.success => AppStatusTone.success,
      PedidoStatusTone.warning => AppStatusTone.warning,
      PedidoStatusTone.danger => AppStatusTone.danger,
      PedidoStatusTone.neutral => AppStatusTone.neutral,
      PedidoStatusTone.info => AppStatusTone.info,
    };
  }
}
