import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppBottomSheetLevel { collapsed, half, full }

class AppBottomSheetFrame extends StatelessWidget {
  const AppBottomSheetFrame({
    super.key,
    required this.child,
    this.level = AppBottomSheetLevel.half,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.showHandle = true,
  });

  final Widget child;
  final AppBottomSheetLevel level;
  final EdgeInsetsGeometry padding;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = switch (level) {
      AppBottomSheetLevel.collapsed => 0.25,
      AppBottomSheetLevel.half => 0.55,
      AppBottomSheetLevel.full => 0.9,
    };

    return FractionallySizedBox(
      heightFactor: ratio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheetTop),
          ),
          boxShadow: AppShadows.level3,
        ),
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              if (showHandle)
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.x4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.colorScheme.outline,
                  ),
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  AppBottomSheetLevel level = AppBottomSheetLevel.half,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    builder: (_) => AppBottomSheetFrame(
      level: level,
      child: child,
    ),
  );
}
