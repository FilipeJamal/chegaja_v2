import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/admin_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  Map<String, String> _sectionErrors = <String, String>{};

  String _ticketFilter = 'open';
  String _noShowFilter = 'pending';

  Map<String, dynamic> _dashboard = <String, dynamic>{};
  Map<String, dynamic> _ops = <String, dynamic>{};
  Map<String, dynamic> _cost = <String, dynamic>{};
  List<Map<String, dynamic>> _tickets = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _noShowCases = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _stories = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _ledgerAnomalies = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadAll(initial: true);
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('${value ?? ''}') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}') ?? 0;
  }

  String _moneyCents(int cents) {
    final euros = cents / 100.0;
    return '€ ${euros.toStringAsFixed(2)}';
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

  Future<void> _loadAll({bool initial = false}) async {
    if (initial) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }

    try {
      final sectionErrors = <String, String>{};

      Future<T?> guarded<T>(String key, Future<T> Function() loader) async {
        try {
          return await loader().timeout(const Duration(seconds: 8));
        } catch (e) {
          sectionErrors[key] = e.toString();
          return null;
        }
      }

      final results = await Future.wait<Object?>([
        guarded(
            'dashboard', () => AdminService.instance.getDashboardSnapshot()),
        guarded('ops', () => AdminService.instance.getOpsMetrics(days: 30)),
        guarded(
          'cost',
          () => AdminService.instance.getCostRetentionSnapshot(),
        ),
        guarded(
          'tickets',
          () => AdminService.instance.listSupportTickets(
            status: _ticketFilter,
            limit: 60,
          ),
        ),
        guarded(
          'no_show',
          () => AdminService.instance.listNoShowCases(
            decision: _noShowFilter,
            limit: 60,
          ),
        ),
        guarded('stories', () => AdminService.instance.listStories(limit: 60)),
        guarded(
          'ledger',
          () => AdminService.instance.getLedgerAnomalies(limit: 60),
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _dashboard =
            (results[0] as Map<String, dynamic>?) ?? <String, dynamic>{};
        _ops = (results[1] as Map<String, dynamic>?) ?? <String, dynamic>{};
        _cost = (results[2] as Map<String, dynamic>?) ?? <String, dynamic>{};
        _tickets = (results[3] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
        _noShowCases = (results[4] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
        _stories = (results[5] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
        _ledgerAnomalies = (results[6] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
        _sectionErrors = sectionErrors;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _refreshing = false;
      });
    }
  }

  Future<void> _changeTicketStatus({
    required String ticketId,
    required String status,
  }) async {
    try {
      await AdminService.instance.updateSupportTicketStatus(
        ticketId: ticketId,
        status: status,
      );
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status do ticket atualizado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar ticket: $e')),
      );
    }
  }

  Future<void> _decideNoShow({
    required String pedidoId,
    required String decision,
  }) async {
    try {
      await AdminService.instance.setNoShowDecision(
        pedidoId: pedidoId,
        decision: decision,
      );
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decisão de no-show registrada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao decidir no-show: $e')),
      );
    }
  }

  Future<void> _deleteStory(String storyId) async {
    try {
      await AdminService.instance.deleteStory(storyId: storyId);
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('História removida com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao remover história: $e')),
      );
    }
  }

  Widget _metricTile({
    required String label,
    required String value,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final funnel = (_ops['funnel'] is Map)
        ? Map<String, dynamic>.from(_ops['funnel'] as Map)
        : <String, dynamic>{};
    final noShow = (_ops['noShow'] is Map)
        ? Map<String, dynamic>.from(_ops['noShow'] as Map)
        : <String, dynamic>{};
    final revenue = (_ops['revenue'] is Map)
        ? Map<String, dynamic>.from(_ops['revenue'] as Map)
        : <String, dynamic>{};
    final retention = (_cost['retention'] is Map)
        ? Map<String, dynamic>.from(_cost['retention'] as Map)
        : <String, dynamic>{};
    final acquisition = (_cost['acquisition'] is Map)
        ? Map<String, dynamic>.from(_cost['acquisition'] as Map)
        : <String, dynamic>{};
    final revenueCost = (_cost['revenue'] is Map)
        ? Map<String, dynamic>.from(_cost['revenue'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backoffice Admin'),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : () => _loadAll(),
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text('Erro: $_error'),
                    ),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumo operacional (7d/30d)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _metricTile(
                            label: 'Tickets abertos',
                            value: '${_asInt(_dashboard['openTickets'])}',
                            icon: Icons.support_agent,
                          ),
                          _metricTile(
                            label: 'No-show pendente',
                            value: '${_asInt(_dashboard['pendingNoShow'])}',
                            icon: Icons.report_problem_outlined,
                          ),
                          _metricTile(
                            label: 'Pedidos (30d)',
                            value: '${_asInt(funnel['created'])}',
                            icon: Icons.shopping_bag_outlined,
                          ),
                          _metricTile(
                            label: 'Concluídos (30d)',
                            value: '${_asInt(funnel['completed'])}',
                            icon: Icons.task_alt_outlined,
                          ),
                          _metricTile(
                            label: 'Receita líquida (30d)',
                            value: _moneyCents(_asInt(revenue['netCents'])),
                            icon: Icons.euro_outlined,
                          ),
                          _metricTile(
                            label: 'No-show aprovados (30d)',
                            value: '${_asInt(noShow['approved'])}',
                            icon: Icons.gavel_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custos e retenção',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _metricTile(
                            label: 'Novos utilizadores (30d)',
                            value: '${_asInt(acquisition['newUsers30'])}',
                            icon: Icons.person_add_alt_1_outlined,
                          ),
                          _metricTile(
                            label: 'CAC',
                            value: _moneyCents(_asInt(acquisition['cacCents'])),
                            icon: Icons.trending_up_outlined,
                          ),
                          _metricTile(
                            label: 'LTV (estimado)',
                            value: _moneyCents(_asInt(revenueCost['ltvCents'])),
                            icon: Icons.query_stats_outlined,
                          ),
                          _metricTile(
                            label: 'Churn (30d)',
                            value:
                                '${(_asDouble(retention['churnRate30']) * 100).toStringAsFixed(2)}%',
                            icon: Icons.trending_down_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
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
                                value: _ticketFilter,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('Todos'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'open',
                                    child: Text('Open'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'in_progress',
                                    child: Text('In progress'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'resolved',
                                    child: Text('Resolved'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'closed',
                                    child: Text('Closed'),
                                  ),
                                ],
                                onChanged: (value) async {
                                  if (value == null) return;
                                  setState(() => _ticketFilter = value);
                                  await _loadAll();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_tickets.isEmpty)
                            const Text('Sem tickets para este filtro.')
                          else
                            for (final ticket in _tickets)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${ticket['subject'] ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
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
                                            'Status: ${ticket['status'] ?? 'open'}',
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            'User: ${ticket['userType'] ?? '-'}',
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            _formatMs(ticket['createdAt']),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        for (final status in const [
                                          'open',
                                          'in_progress',
                                          'resolved',
                                          'closed',
                                        ])
                                          OutlinedButton(
                                            onPressed: () =>
                                                _changeTicketStatus(
                                              ticketId: '${ticket['id'] ?? ''}'
                                                  .trim(),
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
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Moderação no-show',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DropdownButton<String>(
                                value: _noShowFilter,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'pending',
                                    child: Text('Pendentes'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'approved',
                                    child: Text('Aprovados'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'rejected',
                                    child: Text('Rejeitados'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('Todos'),
                                  ),
                                ],
                                onChanged: (value) async {
                                  if (value == null) return;
                                  setState(() => _noShowFilter = value);
                                  await _loadAll();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_noShowCases.isEmpty)
                            const Text('Sem casos para este filtro.')
                          else
                            for (final item in _noShowCases)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pedido ${item['pedidoId'] ?? ''}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Título: ${item['titulo'] ?? '-'}'),
                                    Text(
                                      'Reportado por: ${item['noShowReportedBy'] ?? '-'}',
                                    ),
                                    if ('${item['noShowReason'] ?? ''}'
                                        .trim()
                                        .isNotEmpty)
                                      Text('Motivo: ${item['noShowReason']}'),
                                    Text(
                                      'Status: ${item['noShowDecision'] ?? 'pending'}',
                                    ),
                                    Text(
                                      'Atualizado: ${_formatMs(item['updatedAt'])}',
                                    ),
                                    if ('${item['noShowDecision'] ?? 'pending'}' ==
                                        'pending') ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => _decideNoShow(
                                              pedidoId:
                                                  '${item['pedidoId'] ?? ''}',
                                              decision: 'approved',
                                            ),
                                            icon: const Icon(Icons.check),
                                            label: const Text('Aprovar'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => _decideNoShow(
                                              pedidoId:
                                                  '${item['pedidoId'] ?? ''}',
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
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Moderação de Histórias',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_stories.isEmpty)
                            const Text('Sem histórias ativas.')
                          else
                            for (final story in _stories)
                              ListTile(
                                leading: Image.network(
                                  '${story['mediaUrl']}',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                                title: Text('${story['prestadorNome']}'),
                                subtitle: Text(
                                  '${story['descricao'] ?? ''}\nExpira: ${_formatMs(story['expiresAt'])}',
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deleteStory('${story['id']}'),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saúde do Ledger (Anomalias)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_ledgerAnomalies.isEmpty)
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Tudo ok! Nenhuma anomalia detectada.'),
                              ],
                            )
                          else
                            for (final anom in _ledgerAnomalies)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  border: Border.all(color: Colors.orange),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PI: ${anom['paymentIntentId']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12),
                                    ),
                                    Text('Pedido: ${anom['pedidoId']}'),
                                    Text('Valor: ${anom['amount']} cents'),
                                    Text(
                                        'Data: ${_formatMs(anom['updatedAt'])}'),
                                    const Text(
                                      'Aviso: Pagamento sem entrada no Ledger!',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
