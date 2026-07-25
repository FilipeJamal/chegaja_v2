import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/utils/currency_utils.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_metric_group_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_metric_tile.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';

typedef PilotParticipantUpdateCallback = Future<void> Function({
  required String uid,
  required String status,
  required List<String> roles,
  required String city,
  required String cohort,
  String? note,
});

class AdminPilotSection extends StatefulWidget {
  const AdminPilotSection({
    super.key,
    required this.metrics,
    required this.participants,
    required this.onSetParticipant,
    this.error,
  });

  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> participants;
  final PilotParticipantUpdateCallback onSetParticipant;
  final String? error;

  @override
  State<AdminPilotSection> createState() => _AdminPilotSectionState();
}

class _AdminPilotSectionState extends State<AdminPilotSection> {
  final _uidController = TextEditingController();
  final _cohortController = TextEditingController(
    text: '${AppConfig.pilotMarket.id}-pilot-1',
  );
  final _noteController = TextEditingController();
  bool _cliente = true;
  bool _prestador = false;
  bool _saving = false;
  String _city = AppConfig.pilotMarket.city;

  @override
  void dispose() {
    _uidController.dispose();
    _cohortController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final uid = _uidController.text.trim();
    final roles = [
      if (_cliente) 'cliente',
      if (_prestador) 'prestador',
    ];
    if (uid.isEmpty || roles.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSetParticipant(
        uid: uid,
        status: 'active',
        roles: roles,
        city: _city,
        cohort: _cohortController.text.trim(),
        note: _noteController.text.trim(),
      );
      _uidController.clear();
      _noteController.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = _map(widget.metrics['mission']);
    final providers = _map(widget.metrics['providers']);
    final requests = _map(widget.metrics['requests']);
    final value = _map(widget.metrics['value']);
    final trustSafety = _map(widget.metrics['trustSafety']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.error != null && widget.error!.trim().isNotEmpty) ...[
          AdminSectionError(message: widget.error!),
          const SizedBox(height: 8),
        ],
        AdminMetricGroupCard(
          title: 'Métrica central da missão',
          subtitle:
              'Prestadores que fizeram o primeiro trabalho remunerado nos primeiros 30 dias.',
          children: [
            AdminMetricTile(
              label: 'Primeiro rendimento em 30 dias',
              value: adminPercentRatio(mission['rate']),
              helper:
                  '${adminAsInt(mission['numerator'])} de ${adminAsInt(mission['denominator'])} prestadores',
              icon: Icons.trending_up,
            ),
            AdminMetricTile(
              label: 'Tempo mediano até primeiro rendimento',
              value: _hours(mission['medianTimeToFirstIncomeHours']),
              icon: Icons.schedule,
            ),
            AdminMetricTile(
              label: 'Receberam primeira oportunidade',
              value: '${adminAsInt(providers['receivedFirstOpportunity'])}',
              icon: Icons.notifications_active_outlined,
            ),
            AdminMetricTile(
              label: 'Concluíram primeiro trabalho pago',
              value: '${adminAsInt(providers['completedFirstPaidWork'])}',
              icon: Icons.task_alt,
            ),
          ],
        ),
        AdminMetricGroupCard(
          title: 'Liquidez e valor',
          subtitle:
              'Agregados do piloto em ${AppConfig.currencyCode}, sem dados pessoais.',
          children: [
            AdminMetricTile(
              label: 'Pedidos com resposta',
              value: adminPercentRatio(requests['responseRate']),
              helper:
                  '${adminAsInt(requests['withResponse'])} de ${adminAsInt(requests['created'])}',
              icon: Icons.forum_outlined,
            ),
            AdminMetricTile(
              label: 'Pedidos concluídos',
              value: adminPercentRatio(requests['completionRate']),
              helper: '${adminAsInt(requests['completed'])} concluídos',
              icon: Icons.done_all,
            ),
            AdminMetricTile(
              label: 'Valor gerado aos Prestadores',
              value: _money(
                value['providerEarnings'] ?? value['providerEarningsMzn'],
              ),
              icon: Icons.payments_outlined,
            ),
            AdminMetricTile(
              label: 'Comissões cobradas',
              value: _money(
                value['commissionsCollected'] ??
                    value['commissionsCollectedMzn'],
              ),
              helper: adminPercentRatio(value['commissionCollectionRate']),
              icon: Icons.account_balance_wallet_outlined,
            ),
            AdminMetricTile(
              label: 'Disputas resolvidas',
              value: adminPercentRatio(trustSafety['resolutionRate']),
              helper:
                  '${adminAsInt(trustSafety['disputesResolved'])} de ${adminAsInt(trustSafety['disputesOpened'])}',
              icon: Icons.shield_outlined,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionar participante controlado',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'A conta Firebase e o telefone devem existir. Usa o UID do backoffice; não coloques telefone ou documentos nas notas.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _uidController,
                  decoration: const InputDecoration(
                    labelText: 'Firebase UID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Cliente'),
                      selected: _cliente,
                      onSelected: (value) => setState(() => _cliente = value),
                    ),
                    FilterChip(
                      label: const Text('Prestador'),
                      selected: _prestador,
                      onSelected: (value) => setState(() => _prestador = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _city,
                  decoration: const InputDecoration(
                    labelText: 'Área',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final city in AppConfig.pilotMarket.supportedCities)
                      DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _city = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cohortController,
                  decoration: const InputDecoration(
                    labelText: 'Coorte',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Nota operacional sem dados sensíveis',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _add,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Ativar no piloto'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Participantes (${widget.participants.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (widget.participants.isEmpty)
          const AdminSectionEmptyState(
            message: 'Nenhum participante registado.',
          )
        else
          ...widget.participants.map(_participantCard),
      ],
    );
  }

  Widget _participantCard(Map<String, dynamic> participant) {
    final roles = (participant['roles'] as List?)
            ?.map((value) => value.toString())
            .toList() ??
        const <String>[];
    final active = participant['status'] == 'active';
    return Card(
      child: ListTile(
        title: Text(participant['uid']?.toString() ?? ''),
        subtitle: Text(
          '${roles.join(' + ')} • ${participant['city'] ?? ''} • ${participant['cohort'] ?? ''}',
        ),
        trailing: TextButton(
          onPressed: _saving
              ? null
              : () => widget.onSetParticipant(
                    uid: participant['uid']?.toString() ?? '',
                    status: active ? 'inactive' : 'active',
                    roles: roles,
                    city: participant['city']?.toString() ??
                        AppConfig.pilotMarket.city,
                    cohort: participant['cohort']?.toString() ??
                        '${AppConfig.pilotMarket.id}-pilot-1',
                    note: active
                        ? 'Desativado no backoffice'
                        : 'Reativado no backoffice',
                  ),
          child: Text(active ? 'Desativar' : 'Reativar'),
        ),
      ),
    );
  }

  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? value.map((key, item) => MapEntry(key.toString(), item))
      : <String, dynamic>{};

  static String _money(dynamic value) {
    final amount = adminAsDouble(value);
    return CurrencyUtils.format(amount);
  }

  static String _hours(dynamic value) {
    final hours = adminMaybeDouble(value);
    if (hours == null) return '-';
    if (hours >= 24) return '${(hours / 24).toStringAsFixed(1)} dias';
    return '${hours.toStringAsFixed(1)} h';
  }
}
