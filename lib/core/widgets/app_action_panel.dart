import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'app_card.dart';

class AppActionPanelAction {
  const AppActionPanelAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
}

class AppActionPanel extends StatelessWidget {
  const AppActionPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.tone = AppStatusTone.info,
    this.primaryAction,
    this.secondaryAction,
    this.trailing,
  });

  final String title;
  final String message;
  final IconData? icon;
  final AppStatusTone tone;
  final AppActionPanelAction? primaryAction;
  final AppActionPanelAction? secondaryAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usesU1 = context.chegaJaTheme.usesU1;
    final toneColors = AppSemanticColors.status(theme, tone);
    final visualTokens = context.chegaJaTheme;
    final legacyAccent = _legacyAccentFor(tone, theme);

    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: usesU1
                        ? toneColors.background
                        : legacyAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(visualTokens.radiusMd),
                    border:
                        usesU1 ? Border.all(color: toneColors.border) : null,
                  ),
                  child: Icon(
                    icon,
                    color: usesU1 ? toneColors.foreground : legacyAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.x3),
                trailing!,
              ],
            ],
          ),
          if (primaryAction != null || secondaryAction != null) ...[
            const SizedBox(height: AppSpacing.x4),
            _ActionPanelButtons(
              primaryAction: primaryAction,
              secondaryAction: secondaryAction,
            ),
          ],
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

class _ActionPanelButtons extends StatelessWidget {
  const _ActionPanelButtons({
    required this.primaryAction,
    required this.secondaryAction,
  });

  final AppActionPanelAction? primaryAction;
  final AppActionPanelAction? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (primaryAction != null)
        AppButton(
          label: primaryAction!.label,
          onPressed: primaryAction!.onPressed,
          leadingIcon: primaryAction!.icon,
          variant: primaryAction!.variant,
          expanded: true,
        ),
      if (secondaryAction != null)
        AppButton(
          label: secondaryAction!.label,
          onPressed: secondaryAction!.onPressed,
          leadingIcon: secondaryAction!.icon,
          variant: secondaryAction!.variant,
          expanded: true,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRow = constraints.maxWidth >= 520 && actions.length > 1;
        if (!useRow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < actions.length; index += 1) ...[
                if (index > 0) const SizedBox(height: AppSpacing.x2),
                actions[index],
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < actions.length; index += 1) ...[
              if (index > 0) const SizedBox(width: AppSpacing.x3),
              Expanded(child: actions[index]),
            ],
          ],
        );
      },
    );
  }
}
