import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_avatar.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';

class OrderOperationalAction {
  const OrderOperationalAction({
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.secondary,
    this.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final Key? key;
}

class OrderOperationalCard extends StatelessWidget {
  const OrderOperationalCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    this.statusTone = AppStatusTone.neutral,
    this.statusIcon,
    this.avatarUrl,
    this.avatarLabel,
    this.leadingIcon,
    this.locationLabel,
    this.timeLabel,
    this.valueLabel,
    this.modeLabel,
    this.modeTone = AppStatusTone.neutral,
    this.modeIcon,
    this.actionHintLabel,
    this.actionHintTone = AppStatusTone.info,
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryPressed,
    this.secondaryActions = const <OrderOperationalAction>[],
    this.footer,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final AppStatusTone statusTone;
  final IconData? statusIcon;
  final String? avatarUrl;
  final String? avatarLabel;
  final IconData? leadingIcon;
  final String? locationLabel;
  final String? timeLabel;
  final String? valueLabel;
  final String? modeLabel;
  final AppStatusTone modeTone;
  final IconData? modeIcon;
  final String? actionHintLabel;
  final AppStatusTone actionHintTone;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryPressed;
  final List<OrderOperationalAction> secondaryActions;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      size: AppCardSize.large,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  title: title,
                  subtitle: subtitle,
                  avatarUrl: avatarUrl,
                  avatarLabel: avatarLabel ?? title,
                  leadingIcon: leadingIcon,
                  statusLabel: statusLabel,
                  statusTone: statusTone,
                  statusIcon: statusIcon,
                  modeLabel: modeLabel,
                  modeTone: modeTone,
                  modeIcon: modeIcon,
                  compact: true,
                ),
                _Body(
                  locationLabel: locationLabel,
                  timeLabel: timeLabel,
                  valueLabel: valueLabel,
                  actionHintLabel: actionHintLabel,
                  actionHintTone: actionHintTone,
                  compact: true,
                ),
                _Actions(
                  primaryActionLabel: primaryActionLabel,
                  primaryActionIcon: primaryActionIcon,
                  onPrimaryPressed: onPrimaryPressed,
                  secondaryActions: secondaryActions,
                  compact: true,
                ),
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.x4),
                  footer!,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      title: title,
                      subtitle: subtitle,
                      avatarUrl: avatarUrl,
                      avatarLabel: avatarLabel ?? title,
                      leadingIcon: leadingIcon,
                      statusLabel: statusLabel,
                      statusTone: statusTone,
                      statusIcon: statusIcon,
                      modeLabel: modeLabel,
                      modeTone: modeTone,
                      modeIcon: modeIcon,
                    ),
                    _Body(
                      locationLabel: locationLabel,
                      timeLabel: timeLabel,
                      valueLabel: null,
                      actionHintLabel: actionHintLabel,
                      actionHintTone: actionHintTone,
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: AppSpacing.x4),
                      footer!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x5),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasText(valueLabel)) _ValueBlock(value: valueLabel!),
                    _Actions(
                      primaryActionLabel: primaryActionLabel,
                      primaryActionIcon: primaryActionIcon,
                      onPrimaryPressed: onPrimaryPressed,
                      secondaryActions: secondaryActions,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusTone,
    required this.avatarLabel,
    this.avatarUrl,
    this.leadingIcon,
    this.statusIcon,
    this.modeLabel,
    this.modeTone = AppStatusTone.neutral,
    this.modeIcon,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final AppStatusTone statusTone;
  final String avatarLabel;
  final String? avatarUrl;
  final IconData? leadingIcon;
  final IconData? statusIcon;
  final String? modeLabel;
  final AppStatusTone modeTone;
  final IconData? modeIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LeadingVisual(
          avatarUrl: avatarUrl,
          avatarLabel: avatarLabel,
          icon: leadingIcon,
          compact: compact,
        ),
        const SizedBox(width: AppSpacing.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x2,
                children: [
                  AppStatusPill(
                    label: statusLabel,
                    tone: statusTone,
                    size: AppStatusPillSize.sm,
                    icon: statusIcon,
                  ),
                  if (OrderOperationalCard._hasText(modeLabel))
                    AppStatusPill(
                      label: modeLabel!.trim(),
                      tone: modeTone,
                      size: AppStatusPillSize.sm,
                      icon: modeIcon,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeadingVisual extends StatelessWidget {
  const _LeadingVisual({
    required this.avatarLabel,
    this.avatarUrl,
    this.icon,
    this.compact = false,
  });

  final String avatarLabel;
  final String? avatarUrl;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = compact ? AppAvatarSize.md : AppAvatarSize.lg;

    if (OrderOperationalCard._hasText(avatarUrl)) {
      return AppAvatar(
        imageUrl: avatarUrl,
        label: avatarLabel,
        size: size,
      );
    }

    return Container(
      width: compact ? 48 : 56,
      height: compact ? 48 : 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Icon(
        icon ?? Icons.assignment_outlined,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    this.locationLabel,
    this.timeLabel,
    this.valueLabel,
    this.actionHintLabel,
    this.actionHintTone = AppStatusTone.info,
    this.compact = false,
  });

  final String? locationLabel;
  final String? timeLabel;
  final String? valueLabel;
  final String? actionHintLabel;
  final AppStatusTone actionHintTone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (OrderOperationalCard._hasText(locationLabel))
        _MetaLine(icon: Icons.location_on_outlined, label: locationLabel!),
      if (OrderOperationalCard._hasText(timeLabel))
        _MetaLine(icon: Icons.schedule_rounded, label: timeLabel!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x4),
          Wrap(
            spacing: AppSpacing.x4,
            runSpacing: AppSpacing.x2,
            children: items,
          ),
        ],
        if (compact && OrderOperationalCard._hasText(valueLabel)) ...[
          const SizedBox(height: AppSpacing.x4),
          _ValueBlock(value: valueLabel!),
        ],
        if (OrderOperationalCard._hasText(actionHintLabel)) ...[
          const SizedBox(height: AppSpacing.x4),
          _ActionHint(label: actionHintLabel!, tone: actionHintTone),
        ],
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.x1),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x2,
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ActionHint extends StatelessWidget {
  const _ActionHint({
    required this.label,
    required this.tone,
  });

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (tone) {
      AppStatusTone.success => AppPalette.success,
      AppStatusTone.warning => AppPalette.warning,
      AppStatusTone.danger => AppPalette.error,
      AppStatusTone.neutral => theme.colorScheme.onSurfaceVariant,
      AppStatusTone.info => theme.colorScheme.primary,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Row(
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: color),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryPressed,
    this.secondaryActions = const <OrderOperationalAction>[],
    this.compact = false,
  });

  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryPressed;
  final List<OrderOperationalAction> secondaryActions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!OrderOperationalCard._hasText(primaryActionLabel) &&
        secondaryActions.isEmpty) {
      return const SizedBox.shrink();
    }

    final actions = <Widget>[
      for (final action in secondaryActions)
        AppButton(
          key: action.key,
          label: action.label,
          onPressed: action.onPressed,
          leadingIcon: action.icon,
          variant: action.variant,
          size: AppButtonSize.sm,
          expanded: compact,
        ),
      if (OrderOperationalCard._hasText(primaryActionLabel))
        AppButton(
          label: primaryActionLabel!.trim(),
          onPressed: onPrimaryPressed,
          leadingIcon: primaryActionIcon,
          size: AppButtonSize.sm,
          expanded: compact,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x4),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.x2),
                  actions[i],
                ],
              ],
            )
          : Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              alignment: WrapAlignment.end,
              children: actions,
            ),
    );
  }
}
