import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost }

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
    final bool isDisabled = onPressed == null || loading;
    final buttonHeight = switch (size) {
      AppButtonSize.sm => AppSizes.buttonSm,
      AppButtonSize.md => AppSizes.buttonMd,
      AppButtonSize.lg => AppSizes.buttonLg,
    };

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
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

    if (!expanded) return button;
    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }

  ButtonStyle _style(BuildContext context, double buttonHeight) {
    final textStyle = Theme.of(context).textTheme.labelLarge;

    switch (variant) {
      case AppButtonVariant.primary:
        return ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, buttonHeight)),
          textStyle: WidgetStatePropertyAll(textStyle),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppPalette.primaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppPalette.primaryPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppPalette.primaryHover;
            }
            return AppPalette.primary;
          }),
        );
      case AppButtonVariant.secondary:
        return ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, buttonHeight)),
          textStyle: WidgetStatePropertyAll(textStyle),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppPalette.secondaryDisabled);
            }
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(color: AppPalette.secondaryPressed);
            }
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(color: AppPalette.secondaryHover);
            }
            return const BorderSide(color: AppPalette.secondary);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppPalette.secondaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppPalette.secondaryPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppPalette.secondaryHover;
            }
            return AppPalette.secondary;
          }),
        );
      case AppButtonVariant.ghost:
        return ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, buttonHeight)),
          textStyle: WidgetStatePropertyAll(textStyle),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Theme.of(context).colorScheme.onSurfaceVariant;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppPalette.primaryPressed;
            }
            return AppPalette.primary;
          }),
        );
    }
  }
}

