import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_action_row.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_filter_bar.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_status_chip.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

typedef AdminReportStatusUpdateCallback = Future<void> Function({
  required String reportId,
  required String status,
  String? decisionReason,
});

class AdminReportsSection extends StatelessWidget {
  const AdminReportsSection({
    super.key,
    required this.reports,
    required this.statusFilter,
    required this.onFilterChanged,
    required this.onUpdateStatus,
    this.error,
  });

  final List<Map<String, dynamic>> reports;
  final String statusFilter;
  final ValueChanged<String> onFilterChanged;
  final AdminReportStatusUpdateCallback onUpdateStatus;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminQueueFilterBar(
          title: 'Moderacao e denuncias',
          description:
              'Fila inicial de reports. Nenhuma acao aqui oculta conteudo ou bane utilizadores automaticamente.',
          value: statusFilter,
          options: _reportFilterOptions,
          onChanged: onFilterChanged,
        ),
        if (error != null && error!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          AdminSectionError(message: error!),
        ],
        const SizedBox(height: 8),
        if (reports.isEmpty)
          const AdminSectionEmptyState(
            message: 'Sem denuncias para este filtro.',
          )
        else
          for (final report in reports)
            _AdminReportCard(
              report: report,
              onUpdateStatus: onUpdateStatus,
            ),
      ],
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  const _AdminReportCard({
    required this.report,
    required this.onUpdateStatus,
  });

  final Map<String, dynamic> report;
  final AdminReportStatusUpdateCallback onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final reportId = '${report['id'] ?? ''}'.trim();
    final details = '${report['details'] ?? ''}'.trim();

    return AdminQueueCard(
      title: reportId.isEmpty ? '' : 'Denuncia $reportId',
      fallbackTitle: 'Denuncia sem ID',
      subtitle:
          'Reporter: ${adminTextOrFallback(report['reporterId'], fallback: '-')}',
      meta: [
        AdminQueueStatusChip(
          label: 'Tipo',
          value: '${report['targetType'] ?? ''}',
        ),
        AdminQueueStatusChip(
          label: 'Motivo',
          value: '${report['reasonCode'] ?? ''}',
        ),
        AdminQueueStatusChip(
          label: 'Severidade',
          value: '${report['severity'] ?? ''}',
        ),
        AdminQueueStatusChip(
          label: 'Status',
          value: '${report['status'] ?? ''}',
        ),
        AdminQueueStatusChip(
          label: 'Criada',
          value: adminFormatMs(report['createdAt']),
        ),
      ],
      children: [
        Text(
            'Target: ${adminTextOrFallback(report['targetId'], fallback: '-')}'),
        if ('${report['targetOwnerId'] ?? ''}'.trim().isNotEmpty)
          Text('Owner: ${report['targetOwnerId']}'),
        if (details.isNotEmpty)
          Text(
            details,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
      ],
      actions: AdminQueueActionRow(
        actions: [
          AdminQueueAction(
            label: 'Marcar analisada',
            icon: Icons.check_circle_outline,
            primary: true,
            onPressed: reportId.isEmpty
                ? null
                : () => onUpdateStatus(
                      reportId: reportId,
                      status: 'reviewed',
                      decisionReason: 'Marcada como analisada no admin.',
                    ),
          ),
          AdminQueueAction(
            label: 'Descartar',
            icon: Icons.close,
            onPressed: reportId.isEmpty
                ? null
                : () => onUpdateStatus(
                      reportId: reportId,
                      status: 'dismissed',
                      decisionReason: 'Descartada no admin.',
                    ),
          ),
          AdminQueueAction(
            label: 'Escalar',
            icon: Icons.priority_high,
            onPressed: reportId.isEmpty
                ? null
                : () => onUpdateStatus(
                      reportId: reportId,
                      status: 'escalated',
                      decisionReason: 'Escalada para analise posterior.',
                    ),
          ),
        ],
      ),
    );
  }
}

const List<AdminQueueFilterOption> _reportFilterOptions = [
  AdminQueueFilterOption(value: 'pending_review', label: 'Pendentes'),
  AdminQueueFilterOption(value: 'reviewed', label: 'Analisadas'),
  AdminQueueFilterOption(value: 'dismissed', label: 'Descartadas'),
  AdminQueueFilterOption(value: 'escalated', label: 'Escaladas'),
  AdminQueueFilterOption(value: 'all', label: 'Todas'),
];
