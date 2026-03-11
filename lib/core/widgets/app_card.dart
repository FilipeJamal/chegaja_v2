import 'package:flutter/material.dart';

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
  });

  final Widget child;
  final VoidCallback? onTap;
  final AppCardVariant variant;
  final AppCardSize size;
  final EdgeInsetsGeometry? margin;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardRadius = BorderRadius.circular(radius ?? AppRadius.lg);
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
      _ => theme.colorScheme.outline,
    };

    final shadow = switch (variant) {
      AppCardVariant.elevated => isDark ? AppShadows.level1 : AppShadows.level2,
      AppCardVariant.outlined => AppShadows.level1,
      AppCardVariant.flat => const <BoxShadow>[],
    };

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: margin,
      padding: cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: cardRadius,
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: cardRadius,
      onTap: onTap,
      child: card,
    );
  }
}
