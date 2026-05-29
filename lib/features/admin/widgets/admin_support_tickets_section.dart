import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

class AdminSupportTicketsSection extends StatelessWidget {
  const AdminSupportTicketsSection({
    super.key,
    required this.tickets,
    required this.statusFilter,
    required this.onFilterChanged,
    required this.onChangeStatus,
    this.error,
  });

  final List<Map<String, dynamic>> tickets;
  final String statusFilter;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function({
    required String ticketId,
    required String status,
  }) onChangeStatus;
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
                    'Suporte interno',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _ticketFilters.contains(statusFilter)
                      ? statusFilter
                      : 'open',
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('all')),
                    DropdownMenuItem(value: 'open', child: Text('open')),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('in_progress'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('resolved'),
                    ),
                    DropdownMenuItem(value: 'closed', child: Text('closed')),
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
            if (tickets.isEmpty)
              const AdminSectionEmptyState(
                message: 'Sem tickets para este filtro.',
              )
            else
              for (final ticket in tickets)
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
                        '${ticket['subject'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ticket['message'] ?? ''}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                              label: Text(
                                  'Status: ${ticket['status'] ?? 'open'}')),
                          Chip(
                              label:
                                  Text('User: ${ticket['userType'] ?? '-'}')),
                          Chip(label: Text(adminFormatMs(ticket['createdAt']))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final status in _actionStatuses)
                            OutlinedButton(
                              onPressed: () => onChangeStatus(
                                ticketId: '${ticket['id'] ?? ''}'.trim(),
                                status: status,
                              ),
                              child: Text(status),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

const Set<String> _ticketFilters = {
  'all',
  'open',
  'in_progress',
  'resolved',
  'closed',
};

const List<String> _actionStatuses = [
  'open',
  'in_progress',
  'resolved',
  'closed',
];
