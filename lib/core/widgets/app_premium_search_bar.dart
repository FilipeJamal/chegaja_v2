import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';

class AppPremiumSearchBar extends StatelessWidget {
  const AppPremiumSearchBar({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.trailing,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualTokens = context.chegaJaTheme;

    return Container(
      height: visualTokens.inputLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(visualTokens.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: visualTokens.shadowLevel1,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.x4),
          Icon(
            Icons.search_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.x2),
            trailing!,
            const SizedBox(width: AppSpacing.x2),
          ] else
            const SizedBox(width: AppSpacing.x4),
        ],
      ),
    );
  }
}
