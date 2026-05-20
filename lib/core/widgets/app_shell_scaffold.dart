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
                  _DesktopSidebar(
                    key: const Key('app_shell_desktop_sidebar'),
                    currentIndex: currentIndex,
                    onDestinationSelected: onDestinationSelected,
                    destinations: destinations,
                    iconBuilder: _buildIcon,
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

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.iconBuilder,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppShellDestination> destinations;
  final Widget Function(AppShellDestination destination,
      {required bool selected}) iconBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        ),
        boxShadow: AppShadows.level1,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x5,
          AppSpacing.x5,
          AppSpacing.x5,
          AppSpacing.x4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ShellBrand(),
            const SizedBox(height: AppSpacing.x2),
            Text(
              'Servicos perto de ti',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.x7),
            for (var index = 0; index < destinations.length; index += 1) ...[
              _DesktopSidebarItem(
                destination: destinations[index],
                selected: index == currentIndex,
                iconBuilder: iconBuilder,
                onTap: () => onDestinationSelected(index),
              ),
              if (index < destinations.length - 1)
                const SizedBox(height: AppSpacing.x2),
            ],
            const Spacer(),
            const _DesktopSidebarSessionStatus(),
          ],
        ),
      ),
    );
  }
}

class _DesktopSidebarItem extends StatelessWidget {
  const _DesktopSidebarItem({
    required this.destination,
    required this.selected,
    required this.iconBuilder,
    required this.onTap,
  });

  final AppShellDestination destination;
  final bool selected;
  final Widget Function(AppShellDestination destination,
      {required bool selected}) iconBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedBackground = AppPalette.primary.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.22 : 0.14,
    );
    final foreground = selected ? AppPalette.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(
              minHeight: AppSizes.minTapTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4,
              vertical: AppSpacing.x3,
            ),
            decoration: BoxDecoration(
              color: selected ? selectedBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected
                    ? AppPalette.primary.withValues(alpha: 0.38)
                    : Colors.transparent,
              ),
            ),
            child: IconTheme(
              data: IconThemeData(color: foreground, size: 22),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: iconBuilder(destination, selected: selected),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected ? scheme.onSurface : foreground,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebarSessionStatus extends StatelessWidget {
  const _DesktopSidebarSessionStatus();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppPalette.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppPalette.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estado',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  'Sessao ativa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      child: RichText(
        textAlign: TextAlign.start,
        text: TextSpan(
          style: theme.textTheme.titleLarge?.copyWith(
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
