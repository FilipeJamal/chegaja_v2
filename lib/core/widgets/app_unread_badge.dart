import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';

class AppUnreadBadge extends StatelessWidget {
  const AppUnreadBadge({
    super.key,
    this.count,
    this.dot = false,
    this.color,
  });

  const AppUnreadBadge.dot({
    super.key,
    this.color,
  })  : count = null,
        dot = true;

  final int? count;
  final bool dot;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final value = count ?? 0;
    final resolvedColor = color ??
        (context.chegaJaTheme.usesU1
            ? AppPalette.u1AccentBlue
            : AppPalette.accentBlue);
    if (!dot && value <= 0) return const SizedBox.shrink();

    if (dot || count == null) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: resolvedColor,
          shape: BoxShape.circle,
        ),
      );
    }

    final label = value > 99 ? '99+' : '$value';

    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2,
        vertical: AppSpacing.x1,
      ),
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: context.chegaJaTheme.shadowLevel1,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
