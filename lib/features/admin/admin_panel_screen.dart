import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/admin_service.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_panel_content.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_sensitive_category_decision_sheet.dart';

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
  String _reportFilter = 'pending_review';
  String _noShowFilter = 'pending';
  String _sensitiveCategoryFilter = 'pending_review';

  Map<String, dynamic> _dashboard = <String, dynamic>{};
  Map<String, dynamic> _ops = <String, dynamic>{};
  Map<String, dynamic> _cost = <String, dynamic>{};
  List<Map<String, dynamic>> _tickets = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _reports = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _noShowCases = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _stories = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _ledgerAnomalies = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _auditLogs = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _sensitiveCategoryRequests =
      <Map<String, dynamic>>[];
  Map<String, dynamic> _pilotMetrics = <String, dynamic>{};
  List<Map<String, dynamic>> _pilotParticipants = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadAll(initial: true);
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
          'dashboard',
          () => AdminService.instance.getDashboardSnapshot(),
        ),
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
          'reports',
          () => AdminService.instance.listReports(
            status: _reportFilter,
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
        guarded(
          'audit',
          () => AdminService.instance.listAuditLogs(limit: 60),
        ),
        guarded(
          'sensitive_categories',
          () => AdminService.instance.listSensitiveCategoryRequests(
            status: _sensitiveCategoryFilter,
            limit: 60,
          ),
        ),
        guarded('pilot_metrics', AdminService.instance.getPilotMetrics),
        guarded(
          'pilot_participants',
          AdminService.instance.listPilotParticipants,
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
        _reports = (results[4] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
        _noShowCases = (results[5] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
        _stories = (results[6] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
        _ledgerAnomalies = (results[7] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
        _auditLogs = (results[8] as List<Map<String, dynamic>>?) ??
            <Map<String, dynamic>>[];
        _sensitiveCategoryRequests =
            (results[9] as List<Map<String, dynamic>>?) ??
                <Map<String, dynamic>>[];
        _pilotMetrics =
            (results[10] as Map<String, dynamic>?) ?? <String, dynamic>{};
        _pilotParticipants = (results[11] as List<Map<String, dynamic>>?) ??
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

  Future<void> _changeReportStatus({
    required String reportId,
    required String status,
    String? decisionReason,
  }) async {
    try {
      await AdminService.instance.updateReportStatus(
        reportId: reportId,
        status: status,
        decisionReason: decisionReason,
      );
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denuncia atualizada.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar denuncia: $e')),
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
        const SnackBar(content: Text('Decisao de no-show registrada.')),
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
        const SnackBar(content: Text('Historia removida com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao remover historia: $e')),
      );
    }
  }

  Future<void> _setPilotParticipant({
    required String uid,
    required String status,
    required List<String> roles,
    required String city,
    required String cohort,
    String? note,
  }) async {
    try {
      await AdminService.instance.setPilotParticipant(
        uid: uid,
        status: status,
        roles: roles,
        city: city,
        cohort: cohort,
        note: note,
      );
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participante do piloto atualizado.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar participante: $error')),
      );
    }
  }

  Future<void> _openSensitiveCategoryDecision({
    required Map<String, dynamic> request,
    required String decision,
  }) async {
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => AdminSensitiveCategoryDecisionSheet(
          request: request,
          decision: decision,
          onSubmit: (input) async {
            await AdminService.instance.reviewSensitiveCategoryRequest(
              requestId: input.requestId,
              decision: input.decision,
              decisionReason: input.decisionReason,
            );
            if (context.mounted) Navigator.of(context).pop();
            await _loadAll();
            if (!mounted) return;
            ScaffoldMessenger.of(this.context).showSnackBar(
              const SnackBar(
                content: Text('Decisao de comprovativo registrada.'),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao decidir comprovativo: $e')),
      );
    }
  }

  void _changeTicketFilter(String value) {
    setState(() => _ticketFilter = value);
    _loadAll();
  }

  void _changeReportFilter(String value) {
    setState(() => _reportFilter = value);
    _loadAll();
  }

  void _changeNoShowFilter(String value) {
    setState(() => _noShowFilter = value);
    _loadAll();
  }

  void _changeSensitiveCategoryFilter(String value) {
    setState(() => _sensitiveCategoryFilter = value);
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backoffice Admin'),
        actions: [
          IconButton(
            tooltip: 'Atualizar admin',
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
              child: AdminPanelContent(
                dashboard: _dashboard,
                ops: _ops,
                cost: _cost,
                tickets: _tickets,
                reports: _reports,
                noShowCases: _noShowCases,
                stories: _stories,
                ledgerAnomalies: _ledgerAnomalies,
                auditLogs: _auditLogs,
                sensitiveCategoryRequests: _sensitiveCategoryRequests,
                pilotMetrics: _pilotMetrics,
                pilotParticipants: _pilotParticipants,
                ticketFilter: _ticketFilter,
                reportFilter: _reportFilter,
                noShowFilter: _noShowFilter,
                sensitiveCategoryFilter: _sensitiveCategoryFilter,
                sectionErrors: _sectionErrors,
                globalError: _error,
                onTicketFilterChanged: _changeTicketFilter,
                onReportFilterChanged: _changeReportFilter,
                onNoShowFilterChanged: _changeNoShowFilter,
                onSensitiveCategoryFilterChanged:
                    _changeSensitiveCategoryFilter,
                onChangeTicketStatus: _changeTicketStatus,
                onChangeReportStatus: _changeReportStatus,
                onDecideNoShow: _decideNoShow,
                onReviewSensitiveCategoryRequest:
                    _openSensitiveCategoryDecision,
                onDeleteStory: _deleteStory,
                onSetPilotParticipant: _setPilotParticipant,
              ),
            ),
    );
  }
}
