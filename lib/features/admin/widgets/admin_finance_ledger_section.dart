import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_metric_tile.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

class AdminFinanceLedgerSection extends StatelessWidget {
  const AdminFinanceLedgerSection({
    super.key,
    required this.cost,
    required this.ledgerAnomalies,
    this.error,
  });

  final Map<String, dynamic> cost;
  final List<Map<String, dynamic>> ledgerAnomalies;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final acquisition = _asMap(cost['acquisition']);
    final retention = _asMap(cost['retention']);
    final revenue = _asMap(cost['revenue']);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financeiro e ledger',
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
              label: 'Novos utilizadores (30d)',
              value: '${adminAsInt(acquisition['newUsers30'])}',
              icon: Icons.person_add_alt_1_outlined,
            ),
            AdminMetricTile(
              label: 'CAC',
              value: adminMoneyCents(acquisition['cacCents']),
              icon: Icons.trending_up_outlined,
            ),
            AdminMetricTile(
              label: 'LTV (estimado)',
              value: adminMoneyCents(revenue['ltvCents']),
              icon: Icons.query_stats_outlined,
            ),
            AdminMetricTile(
              label: 'Churn (30d)',
              value:
                  '${(adminAsDouble(retention['churnRate30']) * 100).toStringAsFixed(2)}%',
              icon: Icons.trending_down_outlined,
            ),
            const SizedBox(height: 12),
            Text(
              'Saude do ledger',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            if (ledgerAnomalies.isEmpty)
              const AdminSectionEmptyState(
                message: 'Tudo ok. Nenhuma anomalia detectada.',
                icon: Icons.check_circle_outline,
              )
            else
              for (final anomaly in ledgerAnomalies)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PI: ${anomaly['paymentIntentId'] ?? '-'}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text('Pedido: ${anomaly['pedidoId'] ?? '-'}'),
                      Text('Valor: ${anomaly['amount'] ?? 0} cents'),
                      Text('Data: ${adminFormatMs(anomaly['updatedAt'])}'),
                      Text(
                        'Aviso: pagamento sem entrada correspondente no ledger.',
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
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

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, v) => MapEntry(key.toString(), v));
  }
  return <String, dynamic>{};
}
