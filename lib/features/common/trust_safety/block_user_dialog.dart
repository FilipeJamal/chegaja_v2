import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/trust_safety_service.dart';

typedef BlockUserCallback = Future<void> Function(String blockedUid);

class BlockUserDialog extends StatefulWidget {
  const BlockUserDialog({
    super.key,
    required this.blockedUid,
    this.userLabel,
    this.onConfirm,
  });

  final String blockedUid;
  final String? userLabel;
  final BlockUserCallback? onConfirm;

  static Future<void> show(
    BuildContext context, {
    required String blockedUid,
    String? userLabel,
    BlockUserCallback? onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlockUserDialog(
        blockedUid: blockedUid,
        userLabel: userLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<BlockUserDialog> {
  bool _submitting = false;
  String? _errorText;

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final onConfirm = widget.onConfirm;
      if (onConfirm != null) {
        await onConfirm(widget.blockedUid);
      } else {
        await TrustSafetyService.instance.blockUser(
          blockedUid: widget.blockedUid,
          source: 'user_action',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilizador bloqueado.')),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        setState(() => _submitting = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = 'Nao conseguimos bloquear este utilizador.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = (widget.userLabel ?? '').trim();

    return AlertDialog(
      title: const Text('Bloquear utilizador?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.isEmpty
                ? 'Esta pessoa ficara marcada como bloqueada na tua conta.'
                : '$label ficara marcado como bloqueado na tua conta.',
          ),
          const SizedBox(height: 8),
          Text(
            'A equipa podera usar este sinal em regras futuras de contacto e moderacao.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _confirm,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_submitting) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              const Text('Bloquear'),
            ],
          ),
        ),
      ],
    );
  }
}
