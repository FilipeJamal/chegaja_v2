import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_status_chip.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

class AdminAuditLogsSection extends StatelessWidget {
  const AdminAuditLogsSection({
    super.key,
    required this.logs,
    this.error,
  });

  final List<Map<String, dynamic>> logs;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auditoria recente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Historico leve das acoes admin principais.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (error != null && error!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          AdminSectionError(message: error!),
        ],
        if (logs.isEmpty) ...[
          const SizedBox(height: 10),
          const AdminSectionEmptyState(message: 'Sem logs recentes.'),
        ],
        const SizedBox(height: 10),
        for (final log in logs) _AdminAuditLogCard(log: log),
      ],
    );
  }
}

class _AdminAuditLogCard extends StatelessWidget {
  const _AdminAuditLogCard({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final actorUid = adminTextOrFallback(log['actorUid']);
    final action = adminTextOrFallback(
      log['action'],
      fallback: 'Acao sem nome',
    );
    final targetType = adminTextOrFallback(log['targetType']);
    final targetId = adminTextOrFallback(log['targetId']);
    final beforeStatus = '${log['beforeStatus'] ?? ''}'.trim();
    final afterStatus = '${log['afterStatus'] ?? ''}'.trim();
    final reason = '${log['reason'] ?? ''}'.trim();

    return AdminQueueCard(
      title: adminTextOrFallback(log['id'], fallback: 'Log sem ID'),
      fallbackTitle: 'Log sem ID',
      subtitle: action,
      meta: [
        AdminQueueStatusChip(label: 'Alvo', value: targetType),
        if (afterStatus.isNotEmpty)
          AdminQueueStatusChip(label: 'Estado', value: afterStatus),
      ],
      children: [
        Text('$targetType $targetId'),
        Text(actorUid),
        if (beforeStatus.isNotEmpty || afterStatus.isNotEmpty)
          Text(_statusTransition(beforeStatus, afterStatus)),
        Text('Criado: ${adminFormatMs(log['createdAt'])}'),
        if (reason.isNotEmpty) Text('Motivo: $reason'),
      ],
    );
  }

  String _statusTransition(String before, String after) {
    final beforeLabel = adminQueueDisplayValue(before);
    final afterLabel = adminQueueDisplayValue(after);
    return '$beforeLabel -> $afterLabel';
  }
}
