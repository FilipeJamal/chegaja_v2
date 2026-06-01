import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_action_row.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_filter_bar.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_status_chip.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

typedef AdminSensitiveCategoryReviewCallback = Future<void> Function({
  required Map<String, dynamic> request,
  required String decision,
});

class AdminSensitiveCategoryRequestsSection extends StatelessWidget {
  const AdminSensitiveCategoryRequestsSection({
    super.key,
    required this.requests,
    required this.statusFilter,
    required this.onFilterChanged,
    required this.onReviewRequested,
    this.error,
  });

  final List<Map<String, dynamic>> requests;
  final String statusFilter;
  final ValueChanged<String> onFilterChanged;
  final AdminSensitiveCategoryReviewCallback onReviewRequested;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminQueueFilterBar(
          title: 'Comprovativos profissionais',
          description:
              'Fila leve para analisar pedidos de categorias sensiveis sem upload privado nesta fase.',
          value: statusFilter,
          options: _filterOptions,
          onChanged: onFilterChanged,
        ),
        if (error != null && error!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          AdminSectionError(message: error!),
        ],
        const SizedBox(height: 8),
        if (requests.isEmpty)
          const AdminSectionEmptyState(
            message: 'Sem pedidos de comprovativo para este filtro.',
            icon: Icons.fact_check_outlined,
          )
        else
          for (final request in requests)
            _SensitiveCategoryRequestCard(
              request: request,
              onReviewRequested: onReviewRequested,
            ),
      ],
    );
  }
}

class _SensitiveCategoryRequestCard extends StatelessWidget {
  const _SensitiveCategoryRequestCard({
    required this.request,
    required this.onReviewRequested,
  });

  final Map<String, dynamic> request;
  final AdminSensitiveCategoryReviewCallback onReviewRequested;

  @override
  Widget build(BuildContext context) {
    final requestId = '${request['id'] ?? ''}'.trim();
    final providerId =
        adminTextOrFallback(request['providerId'], fallback: '-');
    final categoryId =
        adminTextOrFallback(request['categoryId'], fallback: '-');
    final categoryName = '${request['categoryName'] ?? ''}'.trim();
    final evidenceText = '${request['evidenceText'] ?? ''}'.trim();
    final evidenceTypes = _asStringList(request['evidenceTypes']);
    final portfolioUrls = _asStringList(request['portfolioUrls']);

    return AdminQueueCard(
      title: categoryName,
      fallbackTitle: 'Pedido sem categoria',
      subtitle:
          'Provider: $providerId | Request: ${requestId.isEmpty ? '-' : requestId}',
      meta: [
        AdminQueueStatusChip(
          label: 'Status',
          value: '${request['status'] ?? ''}',
        ),
        AdminQueueStatusChip(
          label: 'Categoria',
          value: categoryId,
        ),
        AdminQueueStatusChip(
          label: 'Submetido',
          value: adminFormatMs(request['submittedAt']),
        ),
      ],
      children: [
        Text(
          'Tipos: ${_evidenceTypeLabels(evidenceTypes)}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Evidencia: ${evidenceText.isEmpty ? 'Sem descricao enviada.' : evidenceText}',
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
        if (portfolioUrls.isNotEmpty)
          Text(
            'Portfolio: ${portfolioUrls.join(', ')}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        if ('${request['decisionReason'] ?? ''}'.trim().isNotEmpty)
          Text(
            'Motivo anterior: ${request['decisionReason']}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
      ],
      actions: AdminQueueActionRow(
        actions: [
          AdminQueueAction(
            label: 'Aprovar',
            icon: Icons.check_circle_outline,
            primary: true,
            onPressed: requestId.isEmpty
                ? null
                : () => onReviewRequested(
                      request: request,
                      decision: 'approved',
                    ),
          ),
          AdminQueueAction(
            label: 'Rejeitar',
            icon: Icons.close,
            destructive: true,
            onPressed: requestId.isEmpty
                ? null
                : () => onReviewRequested(
                      request: request,
                      decision: 'rejected',
                    ),
          ),
          AdminQueueAction(
            label: 'Pedir mais informacao',
            icon: Icons.info_outline,
            onPressed: requestId.isEmpty
                ? null
                : () => onReviewRequested(
                      request: request,
                      decision: 'needs_more_info',
                    ),
          ),
        ],
      ),
    );
  }
}

List<String> _asStringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => '$item'.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _evidenceTypeLabels(List<String> values) {
  if (values.isEmpty) return 'Sem tipo indicado';
  return values
      .map((value) => _evidenceTypeLabelsMap[value] ?? value)
      .join(', ');
}

const Map<String, String> _evidenceTypeLabelsMap = {
  'certificate': 'Comprovativo profissional',
  'license': 'Licenca profissional',
  'work_experience': 'Experiencia de trabalho',
  'portfolio_reference': 'Portfolio publico',
  'external_profile': 'Perfil profissional externo',
  'declaration': 'Declaracao profissional',
  'other': 'Outro',
};

const List<AdminQueueFilterOption> _filterOptions = [
  AdminQueueFilterOption(value: 'pending_review', label: 'Pendentes'),
  AdminQueueFilterOption(value: 'submitted', label: 'Submetidos'),
  AdminQueueFilterOption(value: 'needs_more_info', label: 'Mais info'),
  AdminQueueFilterOption(value: 'approved', label: 'Aprovados'),
  AdminQueueFilterOption(value: 'rejected', label: 'Rejeitados'),
  AdminQueueFilterOption(value: 'all', label: 'Todos'),
];
