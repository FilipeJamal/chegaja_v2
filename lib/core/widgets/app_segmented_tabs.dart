import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class AppSegmentedTab {
  const AppSegmentedTab({
    required this.label,
    this.count,
    this.icon,
  });

  final String label;
  final int? count;
  final IconData? icon;
}

class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<AppSegmentedTab> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (MediaQuery.sizeOf(context).width - AppSpacing.x4 * 2)
                .clamp(0.0, double.infinity)
                .toDouble();
        final compact = viewportWidth < 520;

        if (compact) {
          return SizedBox(
            width: viewportWidth,
            child: _TabsContainer(
              child: Row(
                children: [
                  for (var index = 0; index < items.length; index += 1)
                    Expanded(
                      child: _SegmentButton(
                        item: items[index],
                        selected: selectedIndex == index,
                        onTap: () => onChanged(index),
                        compact: true,
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return ClipRect(
          child: SizedBox(
            width: viewportWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _TabsContainer(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < items.length; index += 1)
                      _SegmentButton(
                        item: items[index],
                        selected: selectedIndex == index,
                        onTap: () => onChanged(index),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabsContainer extends StatelessWidget {
  const _TabsContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppShadows.level1,
      ),
      child: child,
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.item,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final AppSegmentedTab item;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final foreground =
        selected ? Colors.white : theme.colorScheme.onSurfaceVariant;
    final background = selected ? selectedColor : Colors.transparent;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 1 : 2),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.buttonMd),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.x1 : AppSpacing.x4,
                vertical: AppSpacing.x2,
              ),
              child: Row(
                mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!compact && item.icon != null) ...[
                    Icon(item.icon, size: 18, color: foreground),
                    const SizedBox(width: AppSpacing.x2),
                  ],
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontSize: compact ? 13 : null,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.count != null) ...[
                    SizedBox(width: compact ? AppSpacing.x1 : AppSpacing.x2),
                    _SegmentCount(
                      count: item.count!,
                      selected: selected,
                      compact: compact,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentCount extends StatelessWidget {
  const _SegmentCount({
    required this.count,
    required this.selected,
    this.compact = false,
  });

  final int count;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 20 : 22,
        minHeight: compact ? 20 : 22,
      ),
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : AppSpacing.x2),
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.20)
            : theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: selected ? Colors.white : theme.colorScheme.primary,
          fontSize: compact ? 11 : null,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
