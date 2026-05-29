import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/services/trust_safety_service.dart';

typedef ReportSubmitCallback = Future<void> Function({
  required ReportTargetType targetType,
  required String targetId,
  required ReportReasonCode reasonCode,
  required ReportSeverity severity,
  String? details,
  String? targetOwnerId,
  String? sourceContext,
  String? pedidoId,
  String? chatId,
  String? messageId,
  String? mediaUrl,
  String? mediaPath,
});

class ReportContentSheet extends StatefulWidget {
  const ReportContentSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetOwnerId,
    this.sourceContext,
    this.pedidoId,
    this.chatId,
    this.messageId,
    this.mediaUrl,
    this.mediaPath,
    this.onSubmit,
    this.title = 'Denunciar conteudo',
  });

  final ReportTargetType targetType;
  final String targetId;
  final String? targetOwnerId;
  final String? sourceContext;
  final String? pedidoId;
  final String? chatId;
  final String? messageId;
  final String? mediaUrl;
  final String? mediaPath;
  final ReportSubmitCallback? onSubmit;
  final String title;

  static Future<void> show(
    BuildContext context, {
    required ReportTargetType targetType,
    required String targetId,
    String? targetOwnerId,
    String? sourceContext,
    String? pedidoId,
    String? chatId,
    String? messageId,
    String? mediaUrl,
    String? mediaPath,
    ReportSubmitCallback? onSubmit,
    String title = 'Denunciar conteudo',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReportContentSheet(
        targetType: targetType,
        targetId: targetId,
        targetOwnerId: targetOwnerId,
        sourceContext: sourceContext,
        pedidoId: pedidoId,
        chatId: chatId,
        messageId: messageId,
        mediaUrl: mediaUrl,
        mediaPath: mediaPath,
        onSubmit: onSubmit,
        title: title,
      ),
    );
  }

  @override
  State<ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends State<ReportContentSheet> {
  static const int _detailsLimit = 1000;

  final TextEditingController _detailsCtrl = TextEditingController();
  ReportReasonCode? _selectedReason;
  bool _submitting = false;
  String? _errorText;

  bool get _detailsTooLong => _detailsCtrl.text.length > _detailsLimit;

  bool get _canSubmit =>
      _selectedReason != null && !_detailsTooLong && !_submitting;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null || !_canSubmit) return;

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final details = _detailsCtrl.text.trim();
      final onSubmit = widget.onSubmit;
      if (onSubmit != null) {
        await onSubmit(
          targetType: widget.targetType,
          targetId: widget.targetId,
          reasonCode: reason,
          severity: _severityForReason(reason),
          details: details.isEmpty ? null : details,
          targetOwnerId: widget.targetOwnerId,
          sourceContext: widget.sourceContext,
          pedidoId: widget.pedidoId,
          chatId: widget.chatId,
          messageId: widget.messageId,
          mediaUrl: widget.mediaUrl,
          mediaPath: widget.mediaPath,
        );
      } else {
        await TrustSafetyService.instance.createReport(
          targetType: widget.targetType,
          targetId: widget.targetId,
          reasonCode: reason,
          severity: _severityForReason(reason),
          details: details.isEmpty ? null : details,
          targetOwnerId: widget.targetOwnerId,
          sourceContext: widget.sourceContext,
          pedidoId: widget.pedidoId,
          chatId: widget.chatId,
          messageId: widget.messageId,
          mediaUrl: widget.mediaUrl,
          mediaPath: widget.mediaPath,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Denuncia enviada para analise.')),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        setState(() => _submitting = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Nao conseguimos enviar a denuncia.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final detailsLength = _detailsCtrl.text.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Escolhe o motivo. A equipa ira analisar a denuncia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in _reportReasonOptions)
              RadioListTile<ReportReasonCode>(
                value: option.code,
                groupValue: _selectedReason,
                contentPadding: EdgeInsets.zero,
                title: Text(option.label),
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _selectedReason = value),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsCtrl,
              enabled: !_submitting,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Detalhes opcionais',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                errorText: _detailsTooLong
                    ? 'Limite maximo de 1000 caracteres.'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$detailsLength/$_detailsLimit',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: _detailsTooLong
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar denuncia'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

ReportSeverity _severityForReason(ReportReasonCode reason) {
  return switch (reason) {
    ReportReasonCode.illegalService ||
    ReportReasonCode.sexualContent ||
    ReportReasonCode.drugs ||
    ReportReasonCode.violence ||
    ReportReasonCode.childSafety =>
      ReportSeverity.critical,
    ReportReasonCode.fraud ||
    ReportReasonCode.harassment ||
    ReportReasonCode.hateSpeech ||
    ReportReasonCode.scam ||
    ReportReasonCode.impersonation ||
    ReportReasonCode.unsafeService =>
      ReportSeverity.high,
    ReportReasonCode.personalData ||
    ReportReasonCode.spam ||
    ReportReasonCode.copyrightOrStolenMedia ||
    ReportReasonCode.offPlatformCircumvention =>
      ReportSeverity.medium,
    ReportReasonCode.other => ReportSeverity.low,
  };
}

const List<_ReportReasonOption> _reportReasonOptions = [
  _ReportReasonOption(
    label: 'Servico ilegal',
    code: ReportReasonCode.illegalService,
  ),
  _ReportReasonOption(
    label: 'Conteudo sexual/obsceno',
    code: ReportReasonCode.sexualContent,
  ),
  _ReportReasonOption(
    label: 'Drogas ou armas ilegais',
    code: ReportReasonCode.drugs,
  ),
  _ReportReasonOption(
    label: 'Fraude/golpe',
    code: ReportReasonCode.fraud,
  ),
  _ReportReasonOption(
    label: 'Assedio ou ameaca',
    code: ReportReasonCode.harassment,
  ),
  _ReportReasonOption(
    label: 'Discurso de odio',
    code: ReportReasonCode.hateSpeech,
  ),
  _ReportReasonOption(
    label: 'Dados pessoais expostos',
    code: ReportReasonCode.personalData,
  ),
  _ReportReasonOption(
    label: 'Spam',
    code: ReportReasonCode.spam,
  ),
  _ReportReasonOption(
    label: 'Finge ser outra pessoa',
    code: ReportReasonCode.impersonation,
  ),
  _ReportReasonOption(
    label: 'Outro',
    code: ReportReasonCode.other,
  ),
];

class _ReportReasonOption {
  const _ReportReasonOption({
    required this.label,
    required this.code,
  });

  final String label;
  final ReportReasonCode code;
}
