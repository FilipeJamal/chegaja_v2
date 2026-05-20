import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum AppAvatarSize { sm, md, lg }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.label,
    this.initials,
    this.size = AppAvatarSize.md,
    this.isOnline = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? imageUrl;
  final String? label;
  final String? initials;
  final AppAvatarSize size;
  final bool isOnline;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diameter = _diameter;
    final indicatorSize = _indicatorSize;
    final resolvedImageUrl = imageUrl?.trim() ?? '';
    final hasImage = resolvedImageUrl.startsWith('http');

    return Semantics(
      label: label,
      image: true,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CircleAvatar(
                backgroundColor: backgroundColor ??
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage:
                    hasImage ? NetworkImage(resolvedImageUrl) : null,
                child: hasImage
                    ? null
                    : Text(
                        _fallbackInitial,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foregroundColor ?? theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            if (isOnline)
              Positioned(
                key: const Key('app_avatar_online_indicator'),
                right: 0,
                bottom: 0,
                child: Container(
                  width: indicatorSize,
                  height: indicatorSize,
                  decoration: BoxDecoration(
                    color: AppPalette.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double get _diameter {
    return switch (size) {
      AppAvatarSize.sm => 32,
      AppAvatarSize.md => 48,
      AppAvatarSize.lg => 64,
    };
  }

  double get _indicatorSize {
    return switch (size) {
      AppAvatarSize.sm => 10,
      AppAvatarSize.md => 14,
      AppAvatarSize.lg => 18,
    };
  }

  String get _fallbackInitial {
    final explicit = initials?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit.characters.first.toUpperCase();
    }

    final source = label?.trim();
    if (source != null && source.isNotEmpty) {
      return source.characters.first.toUpperCase();
    }

    return '?';
  }
}
