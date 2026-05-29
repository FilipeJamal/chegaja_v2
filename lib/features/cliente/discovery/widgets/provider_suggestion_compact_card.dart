import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:flutter/material.dart';

class ProviderSuggestionCompactCard extends StatelessWidget {
  const ProviderSuggestionCompactCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final ProviderSearchProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final services = _servicesLabel(profile);
    final location = _locationLabel(profile);

    return AppCard(
      key: Key('provider_suggestion_card_${profile.id}'),
      onTap: onTap,
      variant: AppCardVariant.outlined,
      size: AppCardSize.compact,
      child: SizedBox(
        width: 214,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProviderSuggestionAvatar(profile: profile),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (services.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          services,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (profile.hasValidRating) ...[
              const SizedBox(height: AppSpacing.x2),
              _ProviderSuggestionRating(profile: profile),
            ],
            if (profile.portfolioPreviewUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x2),
              Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 15,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Text(
                    'Portfolio',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProviderSuggestionAvatar extends StatelessWidget {
  const _ProviderSuggestionAvatar({required this.profile});

  final ProviderSearchProfile profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = profile.displayName.trim().isEmpty
        ? '?'
        : profile.displayName.trim()[0].toUpperCase();
    final photoUrl = profile.photoUrl;

    return ClipOval(
      child: Container(
        width: 44,
        height: 44,
        color: colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: photoUrl == null
            ? Text(
                initial,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Image.network(
                photoUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Text(
                  initial,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProviderSuggestionRating extends StatelessWidget {
  const _ProviderSuggestionRating({required this.profile});

  final ProviderSearchProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = profile.ratingCount ?? 0;
    final label = count == 1 ? '1 avaliacao' : '$count avaliacoes';

    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          size: 17,
          color: colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.x1),
        Text(
          _formatRating(profile.ratingAvg ?? 0),
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppSpacing.x2),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

String _servicesLabel(ProviderSearchProfile profile) {
  final values =
      profile.services.isNotEmpty ? profile.services : profile.categories;
  return values.take(2).join(', ');
}

String _locationLabel(ProviderSearchProfile profile) {
  return [
    profile.city,
    profile.country,
  ].where((value) => value.trim().isNotEmpty).join(', ');
}

String _formatRating(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
