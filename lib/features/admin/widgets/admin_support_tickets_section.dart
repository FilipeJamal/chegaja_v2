import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_action_row.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_filter_bar.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_status_chip.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminQueueFilterBar(
          title: 'Suporte interno',
          description: 'Tickets recebidos pela equipa de operacao.',
          value: statusFilter,
          options: _ticketFilterOptions,
          onChanged: onFilterChanged,
        ),
        if (error != null && error!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          AdminSectionError(message: error!),
        ],
        const SizedBox(height: 8),
        if (tickets.isEmpty)
          const AdminSectionEmptyState(
            message: 'Sem tickets para este filtro.',
          )
        else
          for (final ticket in tickets)
            _SupportTicketCard(
              ticket: ticket,
              onChangeStatus: onChangeStatus,
            ),
      ],
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  const _SupportTicketCard({
    required this.ticket,
    required this.onChangeStatus,
  });

  final Map<String, dynamic> ticket;
  final Future<void> Function({
    required String ticketId,
    required String status,
  }) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final ticketId = '${ticket['id'] ?? ''}'.trim();

    return AdminQueueCard(
      title: ticketId.isEmpty ? '' : 'Ticket $ticketId',
      fallbackTitle: 'Ticket sem ID',
      subtitle: adminTextOrFallback(
        ticket['subject'],
        fallback: 'Assunto sem titulo',
      ),
      meta: [
        AdminQueueStatusChip(
          label: 'Status',
          value: '${ticket['status'] ?? 'open'}',
        ),
        AdminQueueStatusChip(
          label: 'Utilizador',
          value: '${ticket['userType'] ?? ''}',
        ),
        AdminQueueStatusChip(
          label: 'Criado',
          value: adminFormatMs(ticket['createdAt']),
        ),
      ],
      children: [
        Text(
          adminTextOrFallback(ticket['message']),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      actions: AdminQueueActionRow(
        actions: [
          for (final action in _ticketActions)
            AdminQueueAction(
              label: action.label,
              icon: action.icon,
              onPressed: ticketId.isEmpty
                  ? null
                  : () => onChangeStatus(
                        ticketId: ticketId,
                        status: action.status,
                      ),
            ),
        ],
      ),
    );
  }
}

class _TicketAction {
  const _TicketAction(this.status, this.label, this.icon);

  final String status;
  final String label;
  final IconData icon;
}

const List<AdminQueueFilterOption> _ticketFilterOptions = [
  AdminQueueFilterOption(value: 'all', label: 'Todos'),
  AdminQueueFilterOption(value: 'open', label: 'Abertos'),
  AdminQueueFilterOption(value: 'in_progress', label: 'Em andamento'),
  AdminQueueFilterOption(value: 'resolved', label: 'Resolvidos'),
  AdminQueueFilterOption(value: 'closed', label: 'Fechados'),
];

const List<_TicketAction> _ticketActions = [
  _TicketAction('open', 'Reabrir', Icons.undo_outlined),
  _TicketAction('in_progress', 'Em andamento', Icons.pending_actions_outlined),
  _TicketAction('resolved', 'Resolver', Icons.check_circle_outline),
  _TicketAction('closed', 'Fechar', Icons.lock_outline),
];
