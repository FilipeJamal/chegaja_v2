import 'package:flutter/material.dart';

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
    final color =
        active ? theme.colorScheme.primary : theme.colorScheme.surface;
    final foreground =
        active ? Colors.white : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        elevation: active ? AppElevation.level2 : AppElevation.level1,
        shadowColor: Colors.black.withValues(alpha: 0.16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.inputLg,
              minHeight: AppSizes.inputLg,
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
