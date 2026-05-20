// lib/features/cliente/widgets/pedido_timeline.dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

/// Visual stepper showing order progress: Criado → Aceito → Em Andamento → Concluído/Cancelado.
class PedidoTimeline extends StatelessWidget {
  final String estado;

  const PedidoTimeline({
    super.key,
    required this.estado,
  });

  int _stepIndex() => PedidoStatusPresenter.timelineStepFor(estado);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = _stepIndex();
    final steps = [
      _TimelineStep(l10n.timelineCreated, current >= 0),
      _TimelineStep(l10n.timelineAccepted, current >= 1),
      _TimelineStep(l10n.timelineInProgress, current >= 2),
      _TimelineStep(
        estado == 'cancelado' ? l10n.timelineCancelled : l10n.timelineCompleted,
        current >= 3,
      ),
    ];

    return AppCard(
      variant: AppCardVariant.outlined,
      size: AppCardSize.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Progresso do pedido',
            subtitle: 'Acompanha as etapas principais.',
          ),
          const SizedBox(height: AppSpacing.x3),
          LayoutBuilder(
            builder: (context, constraints) {
              final mobile = constraints.maxWidth < 520;
              if (mobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < steps.length; i += 1)
                      _TimelineStepRow(
                        label: steps[i].label,
                        active: steps[i].active,
                        isLast: i == steps.length - 1,
                      ),
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < steps.length; i += 1) ...[
                    Expanded(
                      child: AppStatusPill(
                        label: steps[i].label,
                        tone: steps[i].active
                            ? AppStatusTone.success
                            : AppStatusTone.neutral,
                        size: AppStatusPillSize.sm,
                        icon: steps[i].active
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                      ),
                    ),
                    if (i < steps.length - 1)
                      const SizedBox(width: AppSpacing.x2),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep(this.label, this.active);

  final String label;
  final bool active;
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({
    required this.label,
    required this.active,
    required this.isLast,
  });

  final String label;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.x2),
      child: AppStatusPill(
        label: label,
        tone: active ? AppStatusTone.success : AppStatusTone.neutral,
        size: AppStatusPillSize.sm,
        icon:
            active ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
      ),
    );
  }
}
