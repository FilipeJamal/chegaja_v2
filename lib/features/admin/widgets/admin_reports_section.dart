import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Moderacao e denuncias',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _allowedFilters.contains(statusFilter)
                      ? statusFilter
                      : 'pending_review',
                  items: const [
                    DropdownMenuItem(
                      value: 'pending_review',
                      child: Text('Pendentes'),
                    ),
                    DropdownMenuItem(
                      value: 'reviewed',
                      child: Text('Analisadas'),
                    ),
                    DropdownMenuItem(
                      value: 'dismissed',
                      child: Text('Descartadas'),
                    ),
                    DropdownMenuItem(
                      value: 'escalated',
                      child: Text('Escaladas'),
                    ),
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Todas'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onFilterChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Fila inicial de reports. Nenhuma acao aqui oculta conteudo ou bane utilizadores automaticamente.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (error != null && error!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Falha ao carregar denuncias: $error',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (reports.isEmpty)
              const Text('Sem denuncias para este filtro.')
            else
              for (final report in reports)
                _AdminReportCard(
                  report: report,
                  onUpdateStatus: onUpdateStatus,
                ),
          ],
        ),
      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reportId = '${report['id'] ?? ''}'.trim();
    final details = '${report['details'] ?? ''}'.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reportId.isEmpty ? 'Denuncia sem ID' : 'Denuncia $reportId',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.report_gmailerrorred_outlined,
                color: colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ReportChip(label: '${report['targetType'] ?? '-'}'),
              _ReportChip(label: '${report['reasonCode'] ?? '-'}'),
              _ReportChip(label: '${report['severity'] ?? '-'}'),
              _ReportChip(label: '${report['status'] ?? '-'}'),
              _ReportChip(label: _formatMs(report['createdAt'])),
            ],
          ),
          const SizedBox(height: 8),
          Text('Reporter: ${report['reporterId'] ?? '-'}'),
          Text('Target: ${report['targetId'] ?? '-'}'),
          if ('${report['targetOwnerId'] ?? ''}'.trim().isNotEmpty)
            Text('Owner: ${report['targetOwnerId']}'),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              details,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: reportId.isEmpty
                    ? null
                    : () => onUpdateStatus(
                          reportId: reportId,
                          status: 'reviewed',
                          decisionReason: 'Marcada como analisada no admin.',
                        ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Marcar analisada'),
              ),
              OutlinedButton.icon(
                onPressed: reportId.isEmpty
                    ? null
                    : () => onUpdateStatus(
                          reportId: reportId,
                          status: 'dismissed',
                          decisionReason: 'Descartada no admin.',
                        ),
                icon: const Icon(Icons.close),
                label: const Text('Descartar'),
              ),
              OutlinedButton.icon(
                onPressed: reportId.isEmpty
                    ? null
                    : () => onUpdateStatus(
                          reportId: reportId,
                          status: 'escalated',
                          decisionReason: 'Escalada para analise posterior.',
                        ),
                icon: const Icon(Icons.priority_high),
                label: const Text('Escalar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportChip extends StatelessWidget {
  const _ReportChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

String _formatMs(Object? value) {
  final ms = _asInt(value);
  if (ms <= 0) return '-';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}

const Set<String> _allowedFilters = {
  'pending_review',
  'reviewed',
  'dismissed',
  'escalated',
  'all',
};
