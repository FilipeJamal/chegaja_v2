import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';

enum SettingsListTileTone { normal, danger }

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.tone = SettingsListTileTone.normal,
    this.iconColor,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final SettingsListTileTone tone;
  final Color? iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final danger = tone == SettingsListTileTone.danger;
    final accent =
        danger ? AppPalette.error : iconColor ?? theme.colorScheme.primary;
    final foreground = danger ? AppPalette.error : theme.colorScheme.onSurface;
    final resolvedTrailing = trailing ??
        (onTap == null
            ? null
            : Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ));

    final content = InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.listTileMin),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x3,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: danger ? 0.10 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (resolvedTrailing != null) ...[
                const SizedBox(width: AppSpacing.x3),
                resolvedTrailing,
              ],
            ],
          ),
        ),
      ),
    );

    if (!showDivider) return content;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        Divider(
          height: 1,
          indent: AppSpacing.x4 + 40 + AppSpacing.x4,
          color: theme.colorScheme.outline,
        ),
      ],
    );
  }
}
