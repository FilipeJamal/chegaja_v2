import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';

enum AppButtonVariant { primary, brand, secondary, ghost }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.expanded = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool expanded;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final visualTokens = context.chegaJaTheme;
    final bool isDisabled = onPressed == null || loading;
    final buttonHeight = switch (size) {
      AppButtonSize.sm => visualTokens.buttonSm,
      AppButtonSize.md => visualTokens.buttonMd,
      AppButtonSize.lg => visualTokens.buttonLg,
    };

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.secondary ||
                      variant == AppButtonVariant.ghost
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
          )
        else if (leadingIcon != null)
          Icon(leadingIcon, size: 18),
        if (loading || leadingIcon != null)
          const SizedBox(width: AppSpacing.x2),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null && !loading) ...[
          const SizedBox(width: AppSpacing.x2),
          Icon(trailingIcon, size: 18),
        ],
      ],
    );

    final style = _style(context, buttonHeight);
    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: style,
          child: child,
        ),
      AppButtonVariant.brand => DecoratedBox(
          decoration: BoxDecoration(
            color: isDisabled
                ? visualTokens.primaryDisabled
                : visualTokens.brandGradientEnabled
                    ? null
                    : visualTokens.primary,
            gradient: isDisabled || !visualTokens.brandGradientEnabled
                ? null
                : visualTokens.actionGradient,
            borderRadius: BorderRadius.circular(visualTokens.radiusMd),
            boxShadow: isDisabled ? const [] : visualTokens.shadowLevel2,
          ),
          child: ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: style,
            child: child,
          ),
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: style,
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: style,
          child: child,
        ),
    };

    final semanticButton = Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: !isDisabled,
      label: loading ? '$label, a carregar' : label,
      onTap: isDisabled ? null : onPressed,
      child: button,
    );
    if (!expanded) return semanticButton;
    return SizedBox(width: double.infinity, child: semanticButton);
  }

  ButtonStyle _style(BuildContext context, double buttonHeight) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;
    final textStyle = theme.textTheme.labelLarge;

    switch (variant) {
      case AppButtonVariant.primary:
        return ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, buttonHeight)),
          textStyle: WidgetStatePropertyAll(textStyle),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(visualTokens.radiusSm),
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return visualTokens.primaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return visualTokens.primaryPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return visualTokens.primaryHover;
            }
            return visualTokens.primary;
          }),
        );
      case AppButtonVariant.brand:
        return ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, buttonHeight)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.x5,
              vertical: AppSpacing.x3,
            ),
          ),
          textStyle: WidgetStatePropertyAll(textStyle),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(visualTokens.radiusMd),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.16);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
        );
      case AppButtonVariant.secondary:
        final enabledColor =
            AppSemanticColors.secondaryActionForeground(Theme.of(context));
        final hoverColor =
            AppSemanticColors.secondaryActionHover(Theme.of(context));
        final pressedColor =
            AppSemanticColors.secondaryActionPressed(Theme.of(context));
        return ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, buttonHeight)),
          textStyle: WidgetStatePropertyAll(textStyle),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(visualTokens.radiusSm),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: visualTokens.secondaryDisabled);
            }
            if (states.contains(WidgetState.pressed)) {
              return BorderSide(color: pressedColor);
            }
            if (states.contains(WidgetState.hovered)) {
              return BorderSide(color: hoverColor);
            }
            return BorderSide(color: enabledColor);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return visualTokens.secondaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return pressedColor;
            }
            if (states.contains(WidgetState.hovered)) {
              return hoverColor;
            }
            return enabledColor;
          }),
        );
      case AppButtonVariant.ghost:
        final enabledColor =
            AppSemanticColors.ghostActionForeground(Theme.of(context));
        final pressedColor =
            AppSemanticColors.ghostActionPressed(Theme.of(context));
        return ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, buttonHeight)),
          textStyle: WidgetStatePropertyAll(textStyle),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(visualTokens.radiusSm),
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Theme.of(context).colorScheme.onSurfaceVariant;
            }
            if (states.contains(WidgetState.pressed)) {
              return pressedColor;
            }
            return enabledColor;
          }),
        );
    }
  }
}
