import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';

export '../theme/app_semantic_colors.dart' show AppStatusTone;

enum AppStatusPillSize { sm, md }

class AppStatusPill extends StatelessWidget {
  const AppStatusPill({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.size = AppStatusPillSize.md,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final AppStatusPillSize size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.chegaJaTheme.usesU1
        ? AppSemanticColors.status(theme, tone)
        : _legacyColorsFor(theme, tone);
    final verticalPadding = size == AppStatusPillSize.sm ? 5.0 : 7.0;
    final iconSize = size == AppStatusPillSize.sm ? 14.0 : 16.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: verticalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: colors.foreground),
              const SizedBox(width: AppSpacing.x1),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppToneColors _legacyColorsFor(ThemeData theme, AppStatusTone tone) {
    final scheme = theme.colorScheme;
    return switch (tone) {
      AppStatusTone.info => AppToneColors(
          background: AppPalette.accentBlue.withValues(alpha: 0.10),
          border: AppPalette.accentBlue.withValues(alpha: 0.28),
          foreground: AppPalette.accentBlue,
        ),
      AppStatusTone.success => AppToneColors(
          background: AppPalette.success.withValues(alpha: 0.12),
          border: AppPalette.success.withValues(alpha: 0.30),
          foreground: AppPalette.success,
        ),
      AppStatusTone.warning => AppToneColors(
          background: AppPalette.warning.withValues(alpha: 0.12),
          border: AppPalette.warning.withValues(alpha: 0.30),
          foreground: AppPalette.warning,
        ),
      AppStatusTone.danger => AppToneColors(
          background: AppPalette.error.withValues(alpha: 0.10),
          border: AppPalette.error.withValues(alpha: 0.28),
          foreground: AppPalette.error,
        ),
      AppStatusTone.neutral => AppToneColors(
          background: scheme.surfaceContainerHighest,
          border: scheme.outline,
          foreground: scheme.onSurfaceVariant,
        ),
    };
  }
}
