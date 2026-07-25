import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';

enum AppCardVariant { elevated, outlined, flat }

enum AppCardSize { compact, regular, large }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.variant = AppCardVariant.elevated,
    this.size = AppCardSize.regular,
    this.margin,
    this.radius,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final AppCardSize size;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final String? semanticLabel;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardRadius = BorderRadius.circular(
      radius ?? visualTokens.radiusLg,
    );
    final cardPadding = switch (size) {
      AppCardSize.compact => const EdgeInsets.all(AppSpacing.x3),
      AppCardSize.regular => const EdgeInsets.all(AppSpacing.x4),
      AppCardSize.large => const EdgeInsets.all(AppSpacing.x5),
    };

    final backgroundColor = switch (variant) {
      AppCardVariant.flat => theme.colorScheme.surfaceContainerHighest,
      _ => theme.colorScheme.surface,
    };

    final borderColor = switch (variant) {
      AppCardVariant.flat => Colors.transparent,
      _ => visualTokens.usesU1
          ? theme.colorScheme.outlineVariant
          : theme.colorScheme.outline,
    };

    final shadow = switch (variant) {
      AppCardVariant.elevated =>
        isDark ? visualTokens.shadowLevel1 : visualTokens.shadowLevel2,
      AppCardVariant.outlined => visualTokens.shadowLevel1,
      AppCardVariant.flat => const <BoxShadow>[],
    };

    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: cardRadius,
      border: Border.all(color: borderColor),
      boxShadow: shadow,
    );

    if (onTap == null) {
      return Container(
        margin: margin,
        padding: cardPadding,
        decoration: decoration,
        child: child,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      selected: selected,
      child: Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: cardRadius),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: decoration,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.minTapTarget,
                ),
                child: Padding(
                  padding: cardPadding,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
