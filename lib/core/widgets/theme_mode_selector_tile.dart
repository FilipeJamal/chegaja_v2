import 'package:flutter/material.dart';

import '../services/theme_mode_service.dart';
import '../theme/app_tokens.dart';
import 'app_bottom_sheet.dart';

class ThemeModeSelectorTile extends StatelessWidget {
  const ThemeModeSelectorTile({
    super.key,
    this.title = 'Theme',
    this.systemLabel = 'System',
    this.lightLabel = 'Light',
    this.darkLabel = 'Dark',
  });

  final String title;
  final String systemLabel;
  final String lightLabel;
  final String darkLabel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeModeService.instance,
      builder: (context, _) {
        final mode = ThemeModeService.instance.themeMode;
        return ListTile(
          leading: const Icon(Icons.contrast_outlined),
          title: Text(title),
          subtitle: Text(_labelFor(mode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openSelector(context, mode),
        );
      },
    );
  }

  String _labelFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return lightLabel;
      case ThemeMode.dark:
        return darkLabel;
      case ThemeMode.system:
        return systemLabel;
    }
  }

  Future<void> _openSelector(BuildContext context, ThemeMode current) async {
    final selected = await showAppBottomSheet<ThemeMode>(
      context: context,
      level: AppBottomSheetLevel.half,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final options = <(ThemeMode, String)>[
            (ThemeMode.system, systemLabel),
            (ThemeMode.light, lightLabel),
            (ThemeMode.dark, darkLabel),
          ];
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
                  ListTile(
                    minVerticalPadding: AppSpacing.x2,
                    leading: Icon(
                      _iconFor(option.$1),
                      color: option.$1 == current
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(option.$2),
                    trailing: option.$1 == current
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(option.$1),
                  ),
              ],
            ),
          );
        },
      ),
    );

    if (selected == null) return;
    await ThemeModeService.instance.setThemeMode(selected);
  }

  IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.settings_suggest_outlined;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }
}
