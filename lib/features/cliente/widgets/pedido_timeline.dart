// lib/features/cliente/widgets/pedido_timeline.dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/l10n/app_localizations.dart';

/// Visual stepper showing order progress: Criado → Aceito → Em Andamento → Concluído/Cancelado.
class PedidoTimeline extends StatelessWidget {
  final String estado;

  const PedidoTimeline({
    super.key,
    required this.estado,
  });

  int _stepIndex() {
    switch (estado) {
      case 'criado':
      case 'aguarda_resposta_prestador':
      case 'aguarda_resposta_cliente':
        return 0;
      case 'aceito':
        return 1;
      case 'em_andamento':
      case 'aguarda_confirmacao_valor':
        return 2;
      case 'concluido':
      case 'cancelado':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = _stepIndex();
    final primary = Theme.of(context).colorScheme.primary;

    Widget buildCircle(bool active) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? primary : Colors.grey.shade300,
        ),
      );
    }

    Widget buildConnector(bool active) {
      return Expanded(
        child: Container(
          height: 2,
          color: active ? primary : Colors.grey.shade300,
        ),
      );
    }

    Widget buildLabel(String text, bool active) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? Colors.black87 : Colors.black54,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            buildCircle(current >= 0),
            buildConnector(current >= 1),
            buildCircle(current >= 1),
            buildConnector(current >= 2),
            buildCircle(current >= 2),
            buildConnector(current >= 3),
            buildCircle(current >= 3),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 70,
              child: buildLabel(l10n.timelineCreated, current >= 0),
            ),
            SizedBox(
              width: 80,
              child: buildLabel(l10n.timelineAccepted, current >= 1),
            ),
            SizedBox(
              width: 90,
              child: buildLabel(l10n.timelineInProgress, current >= 2),
            ),
            SizedBox(
              width: 80,
              child: buildLabel(
                estado == 'cancelado'
                    ? l10n.timelineCancelled
                    : l10n.timelineCompleted,
                current >= 3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
