import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_avatar.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/core/widgets/app_unread_badge.dart';

class ConversationListCard extends StatelessWidget {
  const ConversationListCard({
    super.key,
    required this.name,
    required this.message,
    required this.timeLabel,
    this.avatarUrl,
    this.serviceLabel,
    this.statusLabel,
    this.isOnline = false,
    this.unreadCount = 0,
    this.isFavorite = false,
    this.onTap,
    this.onLongPress,
  });

  final String name;
  final String message;
  final String timeLabel;
  final String? avatarUrl;
  final String? serviceLabel;
  final String? statusLabel;
  final bool isOnline;
  final int unreadCount;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = unreadCount > 0;
    final service = serviceLabel?.trim() ?? '';
    final status = statusLabel?.trim() ?? '';

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppCard(
        onTap: onTap,
        size: AppCardSize.large,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 420;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(
                  imageUrl: avatarUrl,
                  label: name,
                  isOnline: isOnline,
                  size: compact ? AppAvatarSize.md : AppAvatarSize.lg,
                ),
                const SizedBox(width: AppSpacing.x4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x2),
                          _ConversationMeta(
                            timeLabel: timeLabel,
                            isFavorite: isFavorite,
                            hasUnread: hasUnread,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        message,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hasUnread
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (service.isNotEmpty || status.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x3),
                        Wrap(
                          spacing: AppSpacing.x2,
                          runSpacing: AppSpacing.x2,
                          children: [
                            if (service.isNotEmpty)
                              AppStatusPill(
                                label: service,
                                tone: AppStatusTone.info,
                                size: AppStatusPillSize.sm,
                                icon: Icons.handyman_outlined,
                              ),
                            if (status.isNotEmpty)
                              AppStatusPill(
                                label: status,
                                tone: AppStatusTone.neutral,
                                size: AppStatusPillSize.sm,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(width: AppSpacing.x3),
                  AppUnreadBadge(count: unreadCount),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConversationMeta extends StatelessWidget {
  const _ConversationMeta({
    required this.timeLabel,
    required this.isFavorite,
    required this.hasUnread,
  });

  final String timeLabel;
  final bool isFavorite;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFavorite) ...[
          Icon(
            Icons.push_pin_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.x1),
        ],
        Text(
          timeLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: hasUnread
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
