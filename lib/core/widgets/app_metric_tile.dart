import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_status_pill.dart';

class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.supportingText,
    this.icon,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final String value;
  final String? supportingText;
  final IconData? icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(tone, theme);

    return AppCard(
      variant: AppCardVariant.outlined,
      size: AppCardSize.compact,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.x3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  label,
                  style: theme.textTheme.labelLarge,
                ),
                if (supportingText != null &&
                    supportingText!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    supportingText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentFor(AppStatusTone tone, ThemeData theme) {
    switch (tone) {
      case AppStatusTone.info:
        return AppPalette.accentBlue;
      case AppStatusTone.success:
        return AppPalette.success;
      case AppStatusTone.warning:
        return AppPalette.warning;
      case AppStatusTone.danger:
        return AppPalette.error;
      case AppStatusTone.neutral:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
