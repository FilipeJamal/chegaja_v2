import 'package:flutter/material.dart';

import '../feature_flags/feature_flag.dart';
import '../feature_flags/feature_flag_service.dart';
import '../theme/app_theme_extension.dart';
import '../theme/app_tokens.dart';
import 'app_brand_wordmark.dart';
import 'app_unread_badge.dart';

class AppShellDestination {
  const AppShellDestination({
    this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.child,
    this.builder,
    this.showBadge = false,
  }) : assert(
          (child == null) != (builder == null),
          'Provide exactly one of child or builder.',
        );

  /// Stable identifier used to preserve the destination state.
  ///
  /// Existing callers may omit it while they migrate. New shell definitions
  /// should always provide a role-scoped value such as `cliente.saved`.
  final String? id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Widget? child;
  final WidgetBuilder? builder;
  final bool showBadge;

  String resolvedId(int index) {
    final normalized = id?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
    return 'legacy-$index-$label';
  }

  Widget buildPage(BuildContext context) {
    return builder?.call(context) ?? child!;
  }
}

class AppShellScaffold extends StatefulWidget {
  const AppShellScaffold({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.experienceV2Override,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppShellDestination> destinations;
  final bool? experienceV2Override;

  @override
  State<AppShellScaffold> createState() => _AppShellScaffoldState();
}

class _AppShellScaffoldState extends State<AppShellScaffold> {
  final Set<String> _visitedDestinationIds = <String>{};
  final List<String> _stablePageOrderIds = <String>[];

  @override
  void initState() {
    super.initState();
    _syncStablePageOrder();
    _rememberCurrentDestination();
  }

  @override
  void didUpdateWidget(covariant AppShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncStablePageOrder();
    _rememberCurrentDestination();
    final currentIds = <String>{
      for (var index = 0; index < widget.destinations.length; index += 1)
        widget.destinations[index].resolvedId(index),
    };
    _visitedDestinationIds.removeWhere(
      (destinationId) => !currentIds.contains(destinationId),
    );
  }

  void _syncStablePageOrder() {
    final currentIds = <String>[
      for (var index = 0; index < widget.destinations.length; index += 1)
        widget.destinations[index].resolvedId(index),
    ];
    final currentIdSet = currentIds.toSet();
    _stablePageOrderIds.removeWhere(
      (destinationId) => !currentIdSet.contains(destinationId),
    );
    for (final destinationId in currentIds) {
      if (!_stablePageOrderIds.contains(destinationId)) {
        _stablePageOrderIds.add(destinationId);
      }
    }
  }

  void _rememberCurrentDestination() {
    if (widget.destinations.isEmpty) return;
    final safeIndex =
        widget.currentIndex.clamp(0, widget.destinations.length - 1);
    _visitedDestinationIds.add(
      widget.destinations[safeIndex].resolvedId(safeIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.destinations.isNotEmpty);
    assert(
      widget.currentIndex >= 0 &&
          widget.currentIndex < widget.destinations.length,
      'currentIndex must reference an existing destination.',
    );
    assert(
      _hasUniqueDestinationIds(widget.destinations),
      'AppShellDestination ids must be unique.',
    );

    if (widget.destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeCurrentIndex =
        widget.currentIndex.clamp(0, widget.destinations.length - 1);
    final experienceV2 = widget.experienceV2Override ??
        FeatureFlagService.instance.isEnabled(
          FeatureFlag.u1NavigationV2,
        );

    if (!experienceV2) {
      return _buildLegacyShell(context, safeCurrentIndex);
    }

    final currentDestinationId =
        widget.destinations[safeCurrentIndex].resolvedId(safeCurrentIndex);
    _visitedDestinationIds.add(currentDestinationId);
    final destinationById = <String, AppShellDestination>{
      for (var index = 0; index < widget.destinations.length; index += 1)
        widget.destinations[index].resolvedId(index):
            widget.destinations[index],
    };
    final currentPageIndex = _stablePageOrderIds.indexOf(currentDestinationId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopSidebar =
            constraints.maxWidth >= AppBreakpoints.desktopMin;
        final useTabletRail =
            constraints.maxWidth >= AppBreakpoints.tabletMin &&
                constraints.maxWidth < AppBreakpoints.desktopMin;
        final content = IndexedStack(
          index: currentPageIndex,
          children: [
            for (final destinationId in _stablePageOrderIds)
              _buildDestinationPage(
                context,
                destinationId,
                destinationById[destinationId]!,
              ),
          ],
        );

        if (useDesktopSidebar) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _DesktopSidebar(
                    key: const Key('app_shell_desktop_sidebar'),
                    experienceV2: true,
                    currentIndex: safeCurrentIndex,
                    onDestinationSelected: widget.onDestinationSelected,
                    destinations: widget.destinations,
                    iconBuilder: _buildIcon,
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          );
        }

        if (useTabletRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _TabletNavigationRail(
                    key: const Key('app_shell_tablet_navigation'),
                    currentIndex: safeCurrentIndex,
                    onDestinationSelected: widget.onDestinationSelected,
                    destinations: widget.destinations,
                    iconBuilder: _buildIcon,
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          );
        }

        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final showAllLabels = constraints.maxWidth >= 360 && textScale <= 1.3;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: content,
          ),
          bottomNavigationBar: Container(
            key: const Key('app_shell_mobile_navigation'),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: context.chegaJaTheme.shadowLevel3,
            ),
            child: SafeArea(
              top: false,
              child: NavigationBar(
                height: AppSizes.compactNavigationHeight,
                selectedIndex: safeCurrentIndex,
                onDestinationSelected: widget.onDestinationSelected,
                labelBehavior: showAllLabels
                    ? NavigationDestinationLabelBehavior.alwaysShow
                    : NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: [
                  for (var index = 0;
                      index < widget.destinations.length;
                      index += 1)
                    NavigationDestination(
                      icon: _buildIcon(
                        widget.destinations[index],
                        selected: false,
                      ),
                      selectedIcon: _buildIcon(
                        widget.destinations[index],
                        selected: true,
                      ),
                      label: widget.destinations[index].label,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegacyShell(BuildContext context, int safeCurrentIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= AppBreakpoints.desktopMin;
        final content = IndexedStack(
          index: safeCurrentIndex,
          children: [
            for (var index = 0; index < widget.destinations.length; index += 1)
              KeyedSubtree(
                key: ValueKey(
                  'app-shell-page-$index-'
                  '${widget.destinations[index].label}',
                ),
                child: widget.destinations[index].buildPage(context),
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
                    experienceV2: false,
                    currentIndex: safeCurrentIndex,
                    onDestinationSelected: widget.onDestinationSelected,
                    destinations: widget.destinations,
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
                selectedIndex: safeCurrentIndex,
                onDestinationSelected: widget.onDestinationSelected,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (var index = 0;
                      index < widget.destinations.length;
                      index += 1)
                    NavigationDestination(
                      icon: _buildIcon(
                        widget.destinations[index],
                        selected: false,
                      ),
                      selectedIcon: _buildIcon(
                        widget.destinations[index],
                        selected: true,
                      ),
                      label: widget.destinations[index].label,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDestinationPage(
    BuildContext context,
    String destinationId,
    AppShellDestination destination,
  ) {
    final pageKey = ValueKey('app-shell-page-$destinationId');

    if (!_visitedDestinationIds.contains(destinationId)) {
      return KeyedSubtree(
        key: pageKey,
        child: const SizedBox.shrink(),
      );
    }

    return KeyedSubtree(
      key: pageKey,
      child: destination.buildPage(context),
    );
  }

  bool _hasUniqueDestinationIds(List<AppShellDestination> destinations) {
    final ids = <String>{};
    for (var index = 0; index < destinations.length; index += 1) {
      if (!ids.add(destinations[index].resolvedId(index))) return false;
    }
    return true;
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

class _TabletNavigationRail extends StatelessWidget {
  const _TabletNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.iconBuilder,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppShellDestination> destinations;
  final Widget Function(
    AppShellDestination destination, {
    required bool selected,
  }) iconBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visualTokens = context.chegaJaTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(color: scheme.outlineVariant),
        ),
        boxShadow: visualTokens.shadowLevel1,
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        labelType: NavigationRailLabelType.all,
        groupAlignment: -0.75,
        destinations: [
          for (final destination in destinations)
            NavigationRailDestination(
              icon: iconBuilder(destination, selected: false),
              selectedIcon: iconBuilder(destination, selected: true),
              label: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    super.key,
    required this.experienceV2,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.iconBuilder,
  });

  final bool experienceV2;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppShellDestination> destinations;
  final Widget Function(
    AppShellDestination destination, {
    required bool selected,
  }) iconBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visualTokens = context.chegaJaTheme;

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          right: BorderSide(
            color: experienceV2
                ? scheme.outlineVariant
                : scheme.outline.withValues(alpha: 0.45),
          ),
        ),
        boxShadow: experienceV2 ? visualTokens.shadowLevel1 : AppShadows.level1,
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
            _ShellBrand(experienceV2: experienceV2),
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
            _DesktopSidebarSessionStatus(experienceV2: experienceV2),
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
  final Widget Function(
    AppShellDestination destination, {
    required bool selected,
  }) iconBuilder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visualTokens = context.chegaJaTheme;
    final selectedBackground = visualTokens.primary.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.22 : 0.14,
    );
    final foreground =
        selected ? visualTokens.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(visualTokens.radiusLg),
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
              borderRadius: BorderRadius.circular(visualTokens.radiusLg),
              border: Border.all(
                color: selected
                    ? visualTokens.primary.withValues(alpha: 0.38)
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
  const _DesktopSidebarSessionStatus({
    required this.experienceV2,
  });

  final bool experienceV2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visualTokens = context.chegaJaTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(visualTokens.radiusLg),
        border: Border.all(
          color: experienceV2
              ? scheme.outlineVariant
              : scheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppPalette.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(visualTokens.radiusMd),
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
  const _ShellBrand({
    required this.experienceV2,
  });

  final bool experienceV2;

  @override
  Widget build(BuildContext context) {
    if (!experienceV2) {
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

    return const SizedBox(
      key: Key('app_shell_desktop_brand'),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AppBrandWordmark(
            size: AppBrandSize.regular,
          ),
        ),
      ),
    );
  }
}
