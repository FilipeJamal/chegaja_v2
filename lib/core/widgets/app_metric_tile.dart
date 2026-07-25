import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';

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
    final usesU1 = context.chegaJaTheme.usesU1;
    final toneColors = AppSemanticColors.status(theme, tone);
    final visualTokens = context.chegaJaTheme;
    final legacyAccent = _legacyAccentFor(tone, theme);

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
                color: usesU1
                    ? toneColors.background
                    : legacyAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(visualTokens.radiusMd),
                border: usesU1 ? Border.all(color: toneColors.border) : null,
              ),
              child: Icon(
                icon,
                color: usesU1 ? toneColors.foreground : legacyAccent,
                size: 20,
              ),
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

  Color _legacyAccentFor(AppStatusTone tone, ThemeData theme) {
    return switch (tone) {
      AppStatusTone.info => AppPalette.accentBlue,
      AppStatusTone.success => AppPalette.success,
      AppStatusTone.warning => AppPalette.warning,
      AppStatusTone.danger => AppPalette.error,
      AppStatusTone.neutral => theme.colorScheme.onSurfaceVariant,
    };
  }
}
