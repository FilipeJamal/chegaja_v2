import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppStatusTone { neutral, info, success, warning, danger }

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
    final colors = _colorsFor(theme, tone);
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

  _StatusPillColors _colorsFor(ThemeData theme, AppStatusTone tone) {
    final scheme = theme.colorScheme;
    switch (tone) {
      case AppStatusTone.info:
        return _StatusPillColors(
          background: AppPalette.accentBlue.withValues(alpha: 0.10),
          border: AppPalette.accentBlue.withValues(alpha: 0.28),
          foreground: AppPalette.accentBlue,
        );
      case AppStatusTone.success:
        return _StatusPillColors(
          background: AppPalette.success.withValues(alpha: 0.12),
          border: AppPalette.success.withValues(alpha: 0.30),
          foreground: AppPalette.success,
        );
      case AppStatusTone.warning:
        return _StatusPillColors(
          background: AppPalette.warning.withValues(alpha: 0.12),
          border: AppPalette.warning.withValues(alpha: 0.30),
          foreground: AppPalette.warning,
        );
      case AppStatusTone.danger:
        return _StatusPillColors(
          background: AppPalette.error.withValues(alpha: 0.10),
          border: AppPalette.error.withValues(alpha: 0.28),
          foreground: AppPalette.error,
        );
      case AppStatusTone.neutral:
        return _StatusPillColors(
          background: scheme.surfaceContainerHighest,
          border: scheme.outline,
          foreground: scheme.onSurfaceVariant,
        );
    }
  }
}

class _StatusPillColors {
  const _StatusPillColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
