import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppTopBarVariant { standard, search, contextual }

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.variant = AppTopBarVariant.standard,
    this.searchHint = 'Search',
    this.onSearchChanged,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final AppTopBarVariant variant;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;

  @override
  Size get preferredSize => Size.fromHeight(
        variant == AppTopBarVariant.search ? 112 : AppSizes.topBarHeight,
      );

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
    );

    if (variant != AppTopBarVariant.search) return appBar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        appBar,
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x4,
            AppSpacing.x1,
            AppSpacing.x4,
            AppSpacing.x3,
          ),
          child: TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      ],
    );
  }
}
