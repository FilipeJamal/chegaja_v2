import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_dashboard_explainer.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_health_summary_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_metric_group_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_metric_tile.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

class AdminOverviewSection extends StatelessWidget {
  const AdminOverviewSection({
    super.key,
    required this.dashboard,
    required this.ops,
    this.cost = const <String, dynamic>{},
    this.tickets = const <Map<String, dynamic>>[],
    this.reports = const <Map<String, dynamic>>[],
    this.noShowCases = const <Map<String, dynamic>>[],
    this.ledgerAnomalies = const <Map<String, dynamic>>[],
    this.error,
  });

  final Map<String, dynamic> dashboard;
  final Map<String, dynamic> ops;
  final Map<String, dynamic> cost;
  final List<Map<String, dynamic>> tickets;
  final List<Map<String, dynamic>> reports;
  final List<Map<String, dynamic>> noShowCases;
  final List<Map<String, dynamic>> ledgerAnomalies;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final funnel = _asMap(ops['funnel']);
    final noShow = _asMap(ops['noShow']);
    final revenue = _asMap(ops['revenue']);
    final acquisition = _asMap(cost['acquisition']);
    final retention = _asMap(cost['retention']);
    final costRevenue = _asMap(cost['revenue']);

    final openTickets = _countWithFallback(
      dashboard,
      'openTickets',
      tickets,
      statusKey: 'status',
      matchingStatus: 'open',
    );
    final pendingReports = _countStatus(
      reports,
      statusKey: 'status',
      matchingStatus: 'pending_review',
      fallbackToLength: true,
    );
    final pendingNoShow = _firstAvailableInt([
          noShow['pending'],
          dashboard['pendingNoShow'],
        ]) ??
        _countStatus(
          noShowCases,
          statusKey: 'noShowDecision',
          matchingStatus: 'pending',
          fallbackToLength: true,
        );
    final ledgerAnomalyCount = ledgerAnomalies.length;
    final pendingCount =
        openTickets + pendingReports + pendingNoShow + ledgerAnomalyCount;

    final created = adminMaybeInt(funnel['created']);
    final completed = adminMaybeInt(funnel['completed']);
    final cancelled = adminMaybeInt(funnel['cancelled']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Resumo operacional',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (error != null && error!.trim().isNotEmpty) ...[
          AdminSectionError(message: error!),
          const SizedBox(height: 8),
        ],
        AdminHealthSummaryCard(
          pendingCount: pendingCount,
          helper: pendingCount > 0
              ? 'Baseado nas filas carregadas.'
              : 'Nenhuma pendencia critica carregada agora.',
        ),
        AdminMetricGroupCard(
          title: 'Pendencias operacionais',
          subtitle: 'Itens que podem precisar de triagem hoje.',
          children: [
            AdminMetricTile(
              label: 'Tickets abertos',
              value: '$openTickets',
              helper: 'Tickets ainda sem resolucao.',
              icon: Icons.support_agent,
            ),
            AdminMetricTile(
              label: 'Denuncias pendentes',
              value: '$pendingReports',
              helper: 'Denuncias pendentes de triagem.',
              icon: Icons.flag_outlined,
            ),
            AdminMetricTile(
              label: 'No-show pendente',
              value: '$pendingNoShow',
              helper: 'Casos no-show ainda sem decisao.',
              icon: Icons.report_problem_outlined,
            ),
            AdminMetricTile(
              label: 'Anomalias de ledger',
              value: '$ledgerAnomalyCount',
              helper: 'Pagamentos que precisam de revisao operacional.',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        AdminMetricGroupCard(
          title: 'Pedidos',
          subtitle: 'Movimento operacional dos ultimos 30 dias.',
          children: [
            AdminMetricTile(
              label: 'Pedidos criados (30d)',
              value: _valueOrDash(created),
              helper: 'Pedidos criados nos ultimos 30 dias.',
              icon: Icons.shopping_bag_outlined,
            ),
            AdminMetricTile(
              label: 'Pedidos concluidos (30d)',
              value: _valueOrDash(completed),
              helper: 'Pedidos concluidos nos ultimos 30 dias.',
              icon: Icons.task_alt_outlined,
            ),
            AdminMetricTile(
              label: 'Taxa simples de conclusao',
              value: created == null || completed == null
                  ? '-'
                  : adminPercentFromParts(
                      numerator: completed,
                      denominator: created,
                    ),
              helper: 'Concluidos dividido por criados no periodo.',
              icon: Icons.insights_outlined,
            ),
            AdminMetricTile(
              label: 'Cancelamentos (30d)',
              value: _valueOrDash(cancelled),
              helper: 'Pedidos cancelados no periodo, quando informado.',
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
        AdminMetricGroupCard(
          title: 'Financeiro operacional',
          subtitle: 'Valores nao substituem faturacao real.',
          children: [
            AdminMetricTile(
              label: 'Receita liquida (30d)',
              value: adminMoneyCentsOrDash(revenue['netCents']),
              helper: _fallbackHelper(revenue['netCents']),
              icon: Icons.euro_outlined,
            ),
            AdminMetricTile(
              label: 'Receita bruta (30d)',
              value: adminMoneyCentsOrDash(revenue['grossCents']),
              helper: _fallbackHelper(revenue['grossCents']),
              icon: Icons.payments_outlined,
            ),
            AdminMetricTile(
              label: 'Comissao/plataforma (30d)',
              value: adminMoneyCentsOrDash(revenue['feeCents']),
              helper: _fallbackHelper(revenue['feeCents']),
              icon: Icons.percent_outlined,
            ),
          ],
        ),
        AdminMetricGroupCard(
          title: 'Crescimento e retencao',
          subtitle: 'Indicadores simples para leitura operacional.',
          children: [
            AdminMetricTile(
              label: 'Novos utilizadores (30d)',
              value: _valueOrDash(adminMaybeInt(acquisition['newUsers30'])),
              helper: _fallbackHelper(acquisition['newUsers30']),
              icon: Icons.person_add_alt_1_outlined,
            ),
            AdminMetricTile(
              label: 'Utilizadores ativos (30d)',
              value: _valueOrDash(adminMaybeInt(retention['activeUsers30'])),
              helper: _fallbackHelper(retention['activeUsers30']),
              icon: Icons.groups_outlined,
            ),
            AdminMetricTile(
              label: 'Churn estimado (30d)',
              value: adminPercentRatio(retention['churnRate30']),
              helper: _fallbackHelper(retention['churnRate30']),
              icon: Icons.trending_down_outlined,
            ),
            AdminMetricTile(
              label: 'LTV estimado',
              value: adminMoneyCentsOrDash(costRevenue['ltvCents']),
              helper: _fallbackHelper(costRevenue['ltvCents']),
              icon: Icons.timeline_outlined,
            ),
          ],
        ),
        const AdminDashboardExplainer(),
      ],
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

int _countWithFallback(
  Map<String, dynamic> source,
  String key,
  List<Map<String, dynamic>> fallbackList, {
  required String statusKey,
  required String matchingStatus,
}) {
  if (source.containsKey(key)) return adminAsInt(source[key]);
  return _countStatus(
    fallbackList,
    statusKey: statusKey,
    matchingStatus: matchingStatus,
    fallbackToLength: true,
  );
}

int _countStatus(
  List<Map<String, dynamic>> rows, {
  required String statusKey,
  required String matchingStatus,
  bool fallbackToLength = false,
}) {
  if (rows.isEmpty) return 0;
  var foundStatus = false;
  var count = 0;
  for (final row in rows) {
    if (!row.containsKey(statusKey)) continue;
    foundStatus = true;
    final status = '${row[statusKey]}'.trim().toLowerCase();
    if (status == matchingStatus) count += 1;
  }
  if (!foundStatus && fallbackToLength) return rows.length;
  return count;
}

int? _firstAvailableInt(List<Object?> values) {
  for (final value in values) {
    final parsed = adminMaybeInt(value);
    if (parsed != null) return parsed;
  }
  return null;
}

String _valueOrDash(int? value) => value == null ? '-' : '$value';

String? _fallbackHelper(Object? value) {
  if (value == null) return 'Sem dados suficientes para esta metrica.';
  return null;
}
