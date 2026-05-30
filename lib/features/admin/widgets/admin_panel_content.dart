import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_finance_ledger_section.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_no_show_section.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_overview_section.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_reports_section.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_stories_section.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_support_tickets_section.dart';

class AdminPanelContent extends StatefulWidget {
  const AdminPanelContent({
    super.key,
    required this.dashboard,
    required this.ops,
    required this.cost,
    required this.tickets,
    required this.reports,
    required this.noShowCases,
    required this.stories,
    required this.ledgerAnomalies,
    required this.ticketFilter,
    required this.reportFilter,
    required this.noShowFilter,
    required this.sectionErrors,
    required this.onTicketFilterChanged,
    required this.onReportFilterChanged,
    required this.onNoShowFilterChanged,
    required this.onChangeTicketStatus,
    required this.onChangeReportStatus,
    required this.onDecideNoShow,
    required this.onDeleteStory,
    this.globalError,
  });

  final Map<String, dynamic> dashboard;
  final Map<String, dynamic> ops;
  final Map<String, dynamic> cost;
  final List<Map<String, dynamic>> tickets;
  final List<Map<String, dynamic>> reports;
  final List<Map<String, dynamic>> noShowCases;
  final List<Map<String, dynamic>> stories;
  final List<Map<String, dynamic>> ledgerAnomalies;
  final String ticketFilter;
  final String reportFilter;
  final String noShowFilter;
  final Map<String, String> sectionErrors;
  final ValueChanged<String> onTicketFilterChanged;
  final ValueChanged<String> onReportFilterChanged;
  final ValueChanged<String> onNoShowFilterChanged;
  final Future<void> Function({
    required String ticketId,
    required String status,
  }) onChangeTicketStatus;
  final Future<void> Function({
    required String reportId,
    required String status,
    String? decisionReason,
  }) onChangeReportStatus;
  final Future<void> Function({
    required String pedidoId,
    required String decision,
  }) onDecideNoShow;
  final Future<void> Function(String storyId) onDeleteStory;
  final String? globalError;

  @override
  State<AdminPanelContent> createState() => _AdminPanelContentState();
}

class _AdminPanelContentState extends State<AdminPanelContent> {
  _AdminPanelSection _selected = _AdminPanelSection.overview;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionSelector(
          selected: _selected,
          onSelected: (section) => setState(() => _selected = section),
        ),
        if (widget.globalError != null &&
            widget.globalError!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          AdminSectionError(message: widget.globalError!),
        ],
        const SizedBox(height: 12),
        _sectionBody(),
      ],
    );
  }

  Widget _sectionBody() {
    switch (_selected) {
      case _AdminPanelSection.overview:
        return AdminOverviewSection(
          dashboard: widget.dashboard,
          ops: widget.ops,
          cost: widget.cost,
          tickets: widget.tickets,
          reports: widget.reports,
          noShowCases: widget.noShowCases,
          ledgerAnomalies: widget.ledgerAnomalies,
          error: _firstError(['dashboard', 'ops']),
        );
      case _AdminPanelSection.moderation:
        return AdminReportsSection(
          reports: widget.reports,
          statusFilter: widget.reportFilter,
          error: widget.sectionErrors['reports'],
          onFilterChanged: widget.onReportFilterChanged,
          onUpdateStatus: widget.onChangeReportStatus,
        );
      case _AdminPanelSection.support:
        return AdminSupportTicketsSection(
          tickets: widget.tickets,
          statusFilter: widget.ticketFilter,
          error: widget.sectionErrors['tickets'],
          onFilterChanged: widget.onTicketFilterChanged,
          onChangeStatus: widget.onChangeTicketStatus,
        );
      case _AdminPanelSection.noShow:
        return AdminNoShowSection(
          cases: widget.noShowCases,
          decisionFilter: widget.noShowFilter,
          error: widget.sectionErrors['no_show'],
          onFilterChanged: widget.onNoShowFilterChanged,
          onDecide: widget.onDecideNoShow,
        );
      case _AdminPanelSection.content:
        return AdminStoriesSection(
          stories: widget.stories,
          error: widget.sectionErrors['stories'],
          onDeleteStory: widget.onDeleteStory,
        );
      case _AdminPanelSection.finance:
        return AdminFinanceLedgerSection(
          cost: widget.cost,
          ledgerAnomalies: widget.ledgerAnomalies,
          error: _firstError(['cost', 'ledger']),
        );
    }
  }

  String? _firstError(List<String> keys) {
    for (final key in keys) {
      final value = widget.sectionErrors[key];
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({
    required this.selected,
    required this.onSelected,
  });

  final _AdminPanelSection selected;
  final ValueChanged<_AdminPanelSection> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final section in _AdminPanelSection.values)
          ChoiceChip(
            label: Text(section.label),
            selected: selected == section,
            onSelected: (_) => onSelected(section),
          ),
      ],
    );
  }
}

enum _AdminPanelSection {
  overview('Visao geral'),
  moderation('Moderacao'),
  support('Suporte'),
  noShow('No-show'),
  content('Conteudo'),
  finance('Financeiro');

  const _AdminPanelSection(this.label);

  final String label;
}
