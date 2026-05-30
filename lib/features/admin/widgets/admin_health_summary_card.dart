import 'package:flutter/material.dart';

class AdminHealthSummaryCard extends StatelessWidget {
  const AdminHealthSummaryCard({
    super.key,
    required this.pendingCount,
    required this.helper,
  });

  final int pendingCount;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPending = pendingCount > 0;
    final foreground = hasPending
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;
    final background =
        hasPending ? colorScheme.errorContainer : colorScheme.primaryContainer;
    final icon =
        hasPending ? Icons.priority_high_outlined : Icons.check_circle_outline;
    final title = hasPending
        ? 'Ha pendencias para rever'
        : 'Operacao sem pendencias criticas';
    final message = hasPending
        ? '$pendingCount item(ns) precisam de atencao.'
        : 'Nenhuma pendencia critica carregada agora.';
    final helperText = helper.trim() == message ? '' : helper.trim();

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: foreground),
                  ),
                  if (helperText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      helperText,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
