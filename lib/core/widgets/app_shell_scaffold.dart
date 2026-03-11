import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

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
        final compactLabels = constraints.maxWidth < 420;
        final content = KeyedSubtree(
          key: ValueKey(
            'app-shell-page-$currentIndex-${destinations[currentIndex].label}',
          ),
          child: destinations[currentIndex].child,
        );

        if (useRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.x3),
                    child: NavigationRail(
                      selectedIndex: currentIndex,
                      onDestinationSelected: onDestinationSelected,
                      labelType: NavigationRailLabelType.selected,
                      groupAlignment: -1,
                      minWidth: 84,
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
                  const VerticalDivider(width: 1),
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
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelBehavior: compactLabels
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (var index = 0; index < destinations.length; index += 1)
                NavigationDestination(
                  icon: _buildIcon(destinations[index], selected: false),
                  selectedIcon: _buildIcon(destinations[index], selected: true),
                  label: destinations[index].label,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon(
    AppShellDestination destination, {
    required bool selected,
  }) {
    final icon = Icon(selected
        ? destination.selectedIcon ?? destination.icon
        : destination.icon);
    if (!destination.showBadge) return icon;
    return Badge(
      backgroundColor: Colors.redAccent,
      smallSize: 10,
      child: icon,
    );
  }
}
