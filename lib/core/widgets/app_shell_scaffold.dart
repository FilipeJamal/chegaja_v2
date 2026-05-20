import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_unread_badge.dart';

class AppShellDestination {
  const AppShellDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.child,
    this.showBadge = false,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Widget child;
  final bool showBadge;
}

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppShellDestination> destinations;

  @override
  Widget build(BuildContext context) {
    assert(destinations.isNotEmpty);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppBreakpoints.desktopMin;
        final content = IndexedStack(
          index: currentIndex,
          children: [
            for (var index = 0; index < destinations.length; index += 1)
              KeyedSubtree(
                key: ValueKey(
                  'app-shell-page-$index-${destinations[index].label}',
                ),
                child: destinations[index].child,
              ),
          ],
        );

        if (useRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  Container(
                    key: const Key('app_shell_desktop_sidebar'),
                    width: 112,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      boxShadow: AppShadows.level1,
                    ),
                    child: NavigationRail(
                      selectedIndex: currentIndex,
                      onDestinationSelected: onDestinationSelected,
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -1,
                      minWidth: 112,
                      leading: const Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.x2,
                          AppSpacing.x4,
                          AppSpacing.x2,
                          AppSpacing.x5,
                        ),
                        child: _ShellBrand(),
                      ),
                      destinations: [
                        for (var index = 0;
                            index < destinations.length;
                            index += 1)
                          NavigationRailDestination(
                            icon: _buildIcon(
                              destinations[index],
                              selected: false,
                            ),
                            selectedIcon: _buildIcon(
                              destinations[index],
                              selected: true,
                            ),
                            label: Text(
                              destinations[index].label,
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: content,
          ),
          bottomNavigationBar: Container(
            key: const Key('app_shell_mobile_navigation'),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: AppShadows.level3,
            ),
            child: SafeArea(
              top: false,
              child: NavigationBar(
                height: 76,
                selectedIndex: currentIndex,
                onDestinationSelected: onDestinationSelected,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (var index = 0; index < destinations.length; index += 1)
                    NavigationDestination(
                      icon: _buildIcon(destinations[index], selected: false),
                      selectedIcon:
                          _buildIcon(destinations[index], selected: true),
                      label: destinations[index].label,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(
    AppShellDestination destination, {
    required bool selected,
  }) {
    final icon = Icon(
      selected
          ? destination.selectedIcon ?? destination.icon
          : destination.icon,
    );
    if (!destination.showBadge) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        const Positioned(
          right: -3,
          top: -3,
          child: AppUnreadBadge.dot(),
        ),
      ],
    );
  }
}

class _ShellBrand extends StatelessWidget {
  const _ShellBrand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      key: const Key('app_shell_desktop_brand'),
      width: 88,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: theme.textTheme.labelLarge?.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
          ),
          children: const [
            TextSpan(
              text: 'Chega',
              style: TextStyle(color: AppPalette.accentBlue),
            ),
            TextSpan(
              text: 'Ja',
              style: TextStyle(color: AppPalette.success),
            ),
          ],
        ),
      ),
    );
  }
}
