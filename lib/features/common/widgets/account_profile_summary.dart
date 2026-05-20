import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_avatar.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';

class AccountProfileMetric {
  const AccountProfileMetric({
    required this.label,
    required this.value,
    this.supportingText,
    this.icon,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final String value;
  final String? supportingText;
  final IconData? icon;
  final AppStatusTone tone;
}

class AccountProfileSummary extends StatelessWidget {
  const AccountProfileSummary({
    super.key,
    required this.name,
    required this.roleLabel,
    this.photoUrl,
    this.statusLabel,
    this.statusIcon,
    this.statusTone = AppStatusTone.info,
    this.isOnline = false,
    this.metrics = const [],
    this.onEditPressed,
    this.editLabel = 'Editar perfil',
  });

  final String name;
  final String roleLabel;
  final String? photoUrl;
  final String? statusLabel;
  final IconData? statusIcon;
  final AppStatusTone statusTone;
  final bool isOnline;
  final List<AccountProfileMetric> metrics;
  final VoidCallback? onEditPressed;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = name.trim().isEmpty ? 'Sem nome' : name.trim();
    final role = roleLabel.trim().isEmpty ? 'Perfil' : roleLabel.trim();

    return AppCard(
      size: AppCardSize.large,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < AppBreakpoints.tabletMin;

          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppAvatar(
                imageUrl: photoUrl,
                label: displayName,
                size: AppAvatarSize.lg,
                isOnline: isOnline,
              ),
              const SizedBox(width: AppSpacing.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppPalette.accentBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (statusLabel != null &&
                        statusLabel!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x3),
                      AppStatusPill(
                        label: statusLabel!,
                        icon: statusIcon,
                        tone: statusTone,
                        size: AppStatusPillSize.sm,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final editButton = onEditPressed == null
              ? null
              : AppButton(
                  label: editLabel,
                  onPressed: onEditPressed,
                  variant: AppButtonVariant.secondary,
                  leadingIcon: Icons.edit_outlined,
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                identity,
                if (editButton != null) ...[
                  const SizedBox(height: AppSpacing.x4),
                  SizedBox(width: double.infinity, child: editButton),
                ],
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: identity),
                    if (editButton != null) ...[
                      const SizedBox(width: AppSpacing.x4),
                      editButton,
                    ],
                  ],
                ),
              ],
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.x5),
                Divider(color: theme.colorScheme.outline),
                const SizedBox(height: AppSpacing.x4),
                _AccountMetricStrip(metrics: metrics),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AccountMetricStrip extends StatelessWidget {
  const _AccountMetricStrip({required this.metrics});

  final List<AccountProfileMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= AppBreakpoints.tabletMin ? 3 : 1;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (AppSpacing.x4 * (columns - 1))) /
                columns;

        return Wrap(
          spacing: AppSpacing.x4,
          runSpacing: AppSpacing.x3,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _AccountMetricItem(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _AccountMetricItem extends StatelessWidget {
  const _AccountMetricItem({required this.metric});

  final AccountProfileMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(theme, metric.tone);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (metric.icon != null) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(metric.icon, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.x3),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                metric.value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (metric.supportingText != null &&
                  metric.supportingText!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.x1),
                Text(
                  metric.supportingText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _accentFor(ThemeData theme, AppStatusTone tone) {
    return switch (tone) {
      AppStatusTone.info => AppPalette.accentBlue,
      AppStatusTone.success => AppPalette.success,
      AppStatusTone.warning => AppPalette.warning,
      AppStatusTone.danger => AppPalette.error,
      AppStatusTone.neutral => theme.colorScheme.onSurfaceVariant,
    };
  }
}
