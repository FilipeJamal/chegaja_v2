import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:flutter/material.dart';

class ProviderSearchCard extends StatelessWidget {
  const ProviderSearchCard({
    super.key,
    required this.profile,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.favoriteLoading = false,
  });

  final ProviderSearchProfile profile;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final bool favoriteLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final services = _mainServices(profile);
    final location = _locationLabel(profile);

    return Semantics(
      button: true,
      label: 'Ver perfil de ${profile.displayName}',
      child: AppCard(
        key: Key('provider_search_card_${profile.id}'),
        onTap: onTap,
        variant: AppCardVariant.outlined,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProviderAvatar(profile: profile),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_handleLabel(profile).isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      _handleLabel(profile),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (services.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      services,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (profile.hasApprovedSensitiveCategories) ...[
                    const SizedBox(height: AppSpacing.x2),
                    _ApprovedCategorySummary(profile: profile),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x1),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 16,
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
                    _ProviderRating(profile: profile),
                  ],
                  if (profile.portfolioPreviewUrls.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x3),
                    _ProviderPortfolioPreview(
                      urls: profile.portfolioPreviewUrls,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onToggleFavorite != null)
                  Tooltip(
                    message: isFavorite
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    child: IconButton(
                      key: Key(
                        'provider_search_favorite_button_${profile.id}',
                      ),
                      onPressed: favoriteLoading ? null : onToggleFavorite,
                      icon: favoriteLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _mainServices(ProviderSearchProfile profile) {
    final values =
        profile.services.isNotEmpty ? profile.services : profile.categories;
    return values.take(3).join(', ');
  }

  String _locationLabel(ProviderSearchProfile profile) {
    return [
      profile.city,
      profile.country,
    ].where((value) => value.trim().isNotEmpty).join(', ');
  }

  String _handleLabel(ProviderSearchProfile profile) {
    final value = profile.handle?.trim();
    if (value == null || value.isEmpty) return '';
    return value.startsWith('@') ? value : '@$value';
  }
}

class _ApprovedCategorySummary extends StatelessWidget {
  const _ApprovedCategorySummary({required this.profile});

  final ProviderSearchProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final names = profile.approvedSensitiveCategoryNames.take(2).toList();

    return Wrap(
      spacing: AppSpacing.x1,
      runSpacing: AppSpacing.x1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            'Categoria aprovada',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (final name in names)
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar({required this.profile});

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
        width: 56,
        height: 56,
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
                width: 56,
                height: 56,
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

class _ProviderRating extends StatelessWidget {
  const _ProviderRating({required this.profile});

  final ProviderSearchProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = profile.ratingCount ?? 0;
    final label = count == 1 ? '1 avaliacao' : '$count avaliacoes';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          color: colorScheme.primary,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.x1),
        Text(
          _formatRating(profile.ratingAvg ?? 0),
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: AppSpacing.x2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProviderPortfolioPreview extends StatelessWidget {
  const _ProviderPortfolioPreview({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewUrls = urls.take(3).toList();

    return Row(
      children: [
        for (final url in previewUrls) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              width: 42,
              height: 42,
              color: colorScheme.surfaceContainerHighest,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
      ],
    );
  }
}

String _formatRating(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
