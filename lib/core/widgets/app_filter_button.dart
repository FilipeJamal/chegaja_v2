import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';

class AppFilterButton extends StatelessWidget {
  const AppFilterButton({
    super.key,
    required this.onPressed,
    this.active = false,
    this.tooltip = 'Filtrar',
    this.icon = Icons.tune_rounded,
  });

  final VoidCallback? onPressed;
  final bool active;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;
    final color =
        active ? theme.colorScheme.primary : theme.colorScheme.surface;
    final foreground =
        active ? Colors.white : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(visualTokens.radiusLg),
        elevation: active ? AppElevation.level2 : AppElevation.level1,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        child: InkWell(
          borderRadius: BorderRadius.circular(visualTokens.radiusLg),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: visualTokens.inputLg,
              minHeight: visualTokens.inputLg,
            ),
            child: Icon(
              icon,
              color: foreground,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
