import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppListTileVariant { defaultTile, withLeading, withTrailingAction }

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.variant = AppListTileVariant.defaultTile,
    this.enabled = true,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final AppListTileVariant variant;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.listTileMin),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ListTile(
        enabled: enabled,
        onTap: onTap,
        title: title,
        subtitle: subtitle,
        leading: variant == AppListTileVariant.defaultTile ? leading : leading,
        trailing: trailing,
      ),
    );
  }
}
