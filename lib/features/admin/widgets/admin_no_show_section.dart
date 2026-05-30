import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_action_row.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_filter_bar.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_status_chip.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

class AdminNoShowSection extends StatelessWidget {
  const AdminNoShowSection({
    super.key,
    required this.cases,
    required this.decisionFilter,
    required this.onFilterChanged,
    required this.onDecide,
    this.error,
  });

  final List<Map<String, dynamic>> cases;
  final String decisionFilter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function({
    required String pedidoId,
    required String decision,
  }) onDecide;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminQueueFilterBar(
          title: 'Moderacao no-show',
          description: 'Casos reportados que precisam de decisao operacional.',
          value: decisionFilter,
          options: _decisionFilterOptions,
          onChanged: onFilterChanged,
        ),
        if (error != null && error!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          AdminSectionError(message: error!),
        ],
        const SizedBox(height: 8),
        if (cases.isEmpty)
          const AdminSectionEmptyState(
            message: 'Sem casos para este filtro.',
          )
        else
          for (final item in cases)
            _NoShowCaseCard(
              item: item,
              onDecide: onDecide,
            ),
      ],
    );
  }
}

class _NoShowCaseCard extends StatelessWidget {
  const _NoShowCaseCard({
    required this.item,
    required this.onDecide,
  });

  final Map<String, dynamic> item;
  final Future<void> Function({
    required String pedidoId,
    required String decision,
  }) onDecide;

  @override
  Widget build(BuildContext context) {
    final pedidoId = '${item['pedidoId'] ?? ''}'.trim();
    final decision = '${item['noShowDecision'] ?? 'pending'}'.trim();
    final isPending = decision.isEmpty || decision == 'pending';

    return AdminQueueCard(
      title: pedidoId.isEmpty ? '' : 'Pedido $pedidoId',
      fallbackTitle: 'Pedido sem ID',
      subtitle:
          'Titulo: ${adminTextOrFallback(item['titulo'], fallback: 'Sem dados')}',
      meta: [
        AdminQueueStatusChip(label: 'Decisao', value: decision),
        AdminQueueStatusChip(
          label: 'Atualizado',
          value: adminFormatMs(item['updatedAt']),
        ),
      ],
      children: [
        Text(
          'Reportado por: ${adminTextOrFallback(item['noShowReportedBy'], fallback: '-')}',
        ),
        if ('${item['noShowReason'] ?? ''}'.trim().isNotEmpty)
          Text('Motivo: ${item['noShowReason']}'),
      ],
      actions: isPending
          ? AdminQueueActionRow(
              actions: [
                AdminQueueAction(
                  label: 'Aprovar',
                  icon: Icons.check,
                  primary: true,
                  onPressed: pedidoId.isEmpty
                      ? null
                      : () => onDecide(
                            pedidoId: pedidoId,
                            decision: 'approved',
                          ),
                ),
                AdminQueueAction(
                  label: 'Rejeitar',
                  icon: Icons.close,
                  onPressed: pedidoId.isEmpty
                      ? null
                      : () => onDecide(
                            pedidoId: pedidoId,
                            decision: 'rejected',
                          ),
                ),
              ],
            )
          : null,
    );
  }
}

const List<AdminQueueFilterOption> _decisionFilterOptions = [
  AdminQueueFilterOption(value: 'pending', label: 'Pendentes'),
  AdminQueueFilterOption(value: 'approved', label: 'Aprovados'),
  AdminQueueFilterOption(value: 'rejected', label: 'Rejeitados'),
  AdminQueueFilterOption(value: 'all', label: 'Todos'),
];
