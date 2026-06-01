import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_status_chip.dart';

class SensitiveCategoryDecisionInput {
  const SensitiveCategoryDecisionInput({
    required this.requestId,
    required this.decision,
    required this.decisionReason,
  });

  final String requestId;
  final String decision;
  final String decisionReason;
}

class AdminSensitiveCategoryDecisionSheet extends StatefulWidget {
  const AdminSensitiveCategoryDecisionSheet({
    super.key,
    required this.request,
    required this.decision,
    required this.onSubmit,
  });

  final Map<String, dynamic> request;
  final String decision;
  final Future<void> Function(SensitiveCategoryDecisionInput input) onSubmit;

  @override
  State<AdminSensitiveCategoryDecisionSheet> createState() =>
      _AdminSensitiveCategoryDecisionSheetState();
}

class _AdminSensitiveCategoryDecisionSheetState
    extends State<AdminSensitiveCategoryDecisionSheet> {
  final _reasonController = TextEditingController();
  bool _saving = false;
  String? _reasonError;
  String? _submitError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final requestId = _requestId;
    final categoryName = adminTextOrFallback(
      widget.request['categoryName'],
      fallback: 'Categoria sem nome',
    );
    final providerId = adminTextOrFallback(
      widget.request['providerId'],
      fallback: '-',
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              _titleForDecision(widget.decision),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analisa apenas a evidencia textual e referencias publicas do portfolio.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AdminQueueStatusChip(label: 'Categoria', value: categoryName),
                AdminQueueStatusChip(
                  label: 'Status',
                  value: '${widget.request['status'] ?? ''}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Pedido: ${requestId.isEmpty ? '-' : requestId}'),
            Text('Provider: $providerId'),
            const SizedBox(height: 12),
            TextField(
              key: const Key('admin_sensitive_category_decision_reason'),
              controller: _reasonController,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              enabled: !_saving,
              decoration: InputDecoration(
                labelText: 'Motivo',
                helperText: widget.decision == 'approved'
                    ? 'Opcional para aprovacao, recomendado para rastreabilidade.'
                    : 'Obrigatorio para rejeitar ou pedir mais informacao.',
                errorText: _reasonError,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 8),
              Text(
                _submitError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_saving ? 'A guardar...' : 'Confirmar decisao'),
            ),
          ],
        ),
      ),
    );
  }

  String get _requestId => '${widget.request['id'] ?? ''}'.trim();

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    final requiresReason =
        widget.decision == 'rejected' || widget.decision == 'needs_more_info';
    if (requiresReason && reason.isEmpty) {
      setState(() {
        _reasonError = 'Escreve um motivo para esta decisao.';
        _submitError = null;
      });
      return;
    }

    setState(() {
      _saving = true;
      _reasonError = null;
      _submitError = null;
    });

    try {
      await widget.onSubmit(
        SensitiveCategoryDecisionInput(
          requestId: _requestId,
          decision: widget.decision,
          decisionReason: reason,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitError = 'Nao foi possivel gravar esta decisao.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

String _titleForDecision(String decision) {
  switch (decision) {
    case 'approved':
      return 'Aprovar categoria';
    case 'rejected':
      return 'Rejeitar pedido';
    case 'needs_more_info':
      return 'Pedir mais informacao';
    default:
      return 'Decidir pedido';
  }
}
