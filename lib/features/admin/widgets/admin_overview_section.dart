import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_metric_tile.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

class AdminOverviewSection extends StatelessWidget {
  const AdminOverviewSection({
    super.key,
    required this.dashboard,
    required this.ops,
    this.error,
  });

  final Map<String, dynamic> dashboard;
  final Map<String, dynamic> ops;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final funnel = _asMap(ops['funnel']);
    final noShow = _asMap(ops['noShow']);
    final revenue = _asMap(ops['revenue']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo operacional',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (error != null && error!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              AdminSectionError(message: error!),
            ],
            const SizedBox(height: 12),
            AdminMetricTile(
              label: 'Tickets abertos',
              value: '${adminAsInt(dashboard['openTickets'])}',
              icon: Icons.support_agent,
            ),
            AdminMetricTile(
              label: 'No-show pendente',
              value: '${adminAsInt(dashboard['pendingNoShow'])}',
              icon: Icons.report_problem_outlined,
            ),
            AdminMetricTile(
              label: 'Pedidos (30d)',
              value: '${adminAsInt(funnel['created'])}',
              icon: Icons.shopping_bag_outlined,
            ),
            AdminMetricTile(
              label: 'Concluidos (30d)',
              value: '${adminAsInt(funnel['completed'])}',
              icon: Icons.task_alt_outlined,
            ),
            AdminMetricTile(
              label: 'Receita liquida (30d)',
              value: adminMoneyCents(revenue['netCents']),
              icon: Icons.euro_outlined,
            ),
            AdminMetricTile(
              label: 'No-show aprovados (30d)',
              value: '${adminAsInt(noShow['approved'])}',
              icon: Icons.gavel_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, v) => MapEntry(key.toString(), v));
  }
  return <String, dynamic>{};
}
