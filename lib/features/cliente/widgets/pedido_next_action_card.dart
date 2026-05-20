import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

class PedidoNextActionCard extends StatelessWidget {
  final PedidoNextActionData data;

  const PedidoNextActionCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return AppActionPanel(
      title: data.title,
      message: '${data.description}\n${data.nextStep}',
      icon: data.hasUserAction
          ? Icons.touch_app_rounded
          : Icons.hourglass_empty_rounded,
      tone: data.hasUserAction ? AppStatusTone.info : AppStatusTone.neutral,
    );
  }
}
