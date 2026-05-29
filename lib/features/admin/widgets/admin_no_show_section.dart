import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

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
                    'Moderacao no-show',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _decisionFilters.contains(decisionFilter)
                      ? decisionFilter
                      : 'pending',
                  items: const [
                    DropdownMenuItem(
                        value: 'pending', child: Text('Pendentes')),
                    DropdownMenuItem(
                        value: 'approved', child: Text('Aprovados')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rejeitados')),
                    DropdownMenuItem(value: 'all', child: Text('Todos')),
                  ],
                  onChanged: (value) {
                    if (value != null) onFilterChanged(value);
                  },
                ),
              ],
            ),
            if (error != null && error!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              AdminSectionError(message: error!),
            ],
            const SizedBox(height: 8),
            if (cases.isEmpty)
              const AdminSectionEmptyState(
                message: 'Sem casos para este filtro.',
              )
            else
              for (final item in cases)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido ${item['pedidoId'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text('Titulo: ${item['titulo'] ?? '-'}'),
                      Text('Reportado por: ${item['noShowReportedBy'] ?? '-'}'),
                      if ('${item['noShowReason'] ?? ''}'.trim().isNotEmpty)
                        Text('Motivo: ${item['noShowReason']}'),
                      Text('Status: ${item['noShowDecision'] ?? 'pending'}'),
                      Text('Atualizado: ${adminFormatMs(item['updatedAt'])}'),
                      if ('${item['noShowDecision'] ?? 'pending'}' ==
                          'pending') ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => onDecide(
                                pedidoId: '${item['pedidoId'] ?? ''}',
                                decision: 'approved',
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text('Aprovar'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => onDecide(
                                pedidoId: '${item['pedidoId'] ?? ''}',
                                decision: 'rejected',
                              ),
                              icon: const Icon(Icons.close),
                              label: const Text('Rejeitar'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

const Set<String> _decisionFilters = {
  'pending',
  'approved',
  'rejected',
  'all',
};
