import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppChipVariant { filter, choice, status }

enum AppChipSize { sm, md }

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.variant = AppChipVariant.filter,
    this.size = AppChipSize.md,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final AppChipVariant variant;
  final AppChipSize size;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipHeight = switch (size) {
      AppChipSize.sm => 28.0,
      AppChipSize.md => 32.0,
    };

    final style = _resolveStyle(theme);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        constraints: BoxConstraints(minHeight: chipHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: style.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              IconTheme(
                data: IconThemeData(size: 14, color: style.foreground),
                child: leading!,
              ),
              const SizedBox(width: AppSpacing.x1),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: style.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ChipStyle _resolveStyle(ThemeData theme) {
    if (!enabled) {
      return _ChipStyle(
        background: theme.disabledColor.withValues(alpha: 0.12),
        border: theme.disabledColor.withValues(alpha: 0.24),
        foreground: theme.disabledColor,
      );
    }

    switch (variant) {
      case AppChipVariant.filter:
        if (selected) {
          return _ChipStyle(
            background: AppPalette.primary.withValues(alpha: 0.15),
            border: AppPalette.primary.withValues(alpha: 0.45),
            foreground: AppPalette.primaryPressed,
          );
        }
        return _ChipStyle(
          background: theme.colorScheme.surface,
          border: theme.colorScheme.outline,
          foreground: theme.colorScheme.onSurfaceVariant,
        );
      case AppChipVariant.choice:
        return _ChipStyle(
          background: selected
              ? AppPalette.secondary.withValues(alpha: 0.20)
              : theme.colorScheme.surfaceContainerHighest,
          border: selected ? AppPalette.secondary : theme.colorScheme.outline,
          foreground: selected
              ? AppPalette.secondaryPressed
              : theme.colorScheme.onSurfaceVariant,
        );
      case AppChipVariant.status:
        return _ChipStyle(
          background: AppPalette.success.withValues(alpha: 0.12),
          border: AppPalette.success.withValues(alpha: 0.4),
          foreground: AppPalette.success,
        );
    }
  }
}

class _ChipStyle {
  const _ChipStyle({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
