import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_unread_badge.dart';

class AppProductHeader extends StatelessWidget {
  const AppProductHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBrand = true,
    this.brandLabel = 'ChegaJa',
    this.onNotificationPressed,
    this.showNotificationDot = false,
    this.avatar,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final bool showBrand;
  final String brandLabel;
  final VoidCallback? onNotificationPressed;
  final bool showNotificationDot;
  final Widget? avatar;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.tabletMin;
        final hasTopRow = showBrand ||
            onNotificationPressed != null ||
            avatar != null ||
            actions.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasTopRow) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showBrand) _BrandLabel(label: brandLabel),
                  const Spacer(),
                  for (final action in actions) ...[
                    action,
                    const SizedBox(width: AppSpacing.x2),
                  ],
                  if (onNotificationPressed != null) ...[
                    _NotificationButton(
                      onPressed: onNotificationPressed,
                      showDot: showNotificationDot,
                    ),
                    const SizedBox(width: AppSpacing.x3),
                  ],
                  if (avatar != null) avatar!,
                ],
              ),
              SizedBox(height: compact ? AppSpacing.x6 : AppSpacing.x7),
            ],
            Text(
              title,
              style: (compact
                      ? theme.textTheme.displayMedium
                      : theme.textTheme.displayLarge)
                  ?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(
                subtitle!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BrandLabel extends StatelessWidget {
  const _BrandLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (label == 'ChegaJa') {
      return RichText(
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
      );
    }

    return Text(
      label,
      style: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.onPressed,
    required this.showDot,
  });

  final VoidCallback? onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notificacoes',
          onPressed: onPressed,
          icon: Icon(
            Icons.notifications_none_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (showDot)
          const Positioned(
            right: 9,
            top: 9,
            child: AppUnreadBadge.dot(color: AppPalette.success),
          ),
      ],
    );
  }
}
