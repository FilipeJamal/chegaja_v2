import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_formatters.dart';

class AdminQueueCard extends StatelessWidget {
  const AdminQueueCard({
    super.key,
    required this.title,
    required this.fallbackTitle,
    this.subtitle,
    this.meta = const <Widget>[],
    this.children = const <Widget>[],
    this.actions,
    this.leading,
  });

  final String title;
  final String fallbackTitle;
  final String? subtitle;
  final List<Widget> meta;
  final List<Widget> children;
  final Widget? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedTitle = adminTextOrFallback(
      title,
      fallback: fallbackTitle,
    );
    final resolvedSubtitle = adminTextOrFallback(subtitle);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resolvedSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meta,
            ),
          ],
          if (children.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...children,
          ],
          if (actions != null) ...[
            const SizedBox(height: 10),
            actions!,
          ],
        ],
      ),
    );
  }
}
