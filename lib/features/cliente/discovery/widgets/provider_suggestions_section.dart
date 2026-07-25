import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:chegaja_v2/features/cliente/discovery/widgets/provider_suggestion_compact_card.dart';
import 'package:chegaja_v2/features/common/utils/open_public_profile.dart';
import 'package:flutter/material.dart';

typedef ProviderSuggestionOpenCallback = void Function(
  BuildContext context,
  ProviderSearchProfile profile,
);

class ProviderSuggestionsSection extends StatelessWidget {
  const ProviderSuggestionsSection({
    super.key,
    required this.onOpenSearch,
    this.firestore,
    this.profilesStream,
    this.onOpenProfile,
    this.queryLimit = 16,
    this.visibleLimit = 6,
    this.margin = EdgeInsets.zero,
  });

  final VoidCallback onOpenSearch;
  final FirebaseFirestore? firestore;
  final Stream<List<ProviderSearchProfile>>? profilesStream;
  final ProviderSuggestionOpenCallback? onOpenProfile;
  final int queryLimit;
  final int visibleLimit;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProviderSearchProfile>>(
      stream: profilesStream ?? _buildFirestoreStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ProviderSuggestionsShell(
            margin: margin,
            child: const _ProviderSuggestionsErrorState(),
          );
        }

        if (!snapshot.hasData) {
          return _ProviderSuggestionsShell(
            margin: margin,
            child: const _ProviderSuggestionsLoadingState(),
          );
        }

        final suggestions = _selectSuggestions(snapshot.data ?? const []);
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return _ProviderSuggestionsShell(
          margin: margin,
          trailing: AppButton(
            key: const Key('provider_suggestions_search_button'),
            label: 'Pesquisar prestadores',
            onPressed: onOpenSearch,
            leadingIcon: Icons.search_rounded,
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
          ),
          child: SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.x3),
              itemBuilder: (context, index) {
                final profile = suggestions[index];
                return ProviderSuggestionCompactCard(
                  profile: profile,
                  onTap: () => _openProfile(context, profile),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Stream<List<ProviderSearchProfile>> _buildFirestoreStream() {
    final db = firestore ?? FirebaseFirestore.instance;
    return db
        .collection('provider_public')
        .where('marketId', isEqualTo: AppConfig.pilotMarket.id)
        .where('isSearchable', isEqualTo: true)
        .limit(queryLimit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ProviderSearchProfile.fromPrestadorDoc(
                  id: doc.id,
                  data: doc.data(),
                ),
              )
              .where((profile) => profile.isSearchableLocal)
              .toList(growable: false),
        );
  }

  List<ProviderSearchProfile> _selectSuggestions(
    List<ProviderSearchProfile> profiles,
  ) {
    final suggestions = profiles
        .where((profile) => profile.isSearchableLocal)
        .toList(growable: true);

    suggestions.sort((a, b) {
      final scoreCompare = _suggestionScore(b).compareTo(_suggestionScore(a));
      if (scoreCompare != 0) return scoreCompare;
      return a.displayName.compareTo(b.displayName);
    });

    return suggestions.take(visibleLimit).toList(growable: false);
  }

  int _suggestionScore(ProviderSearchProfile profile) {
    var score = 0;
    if (profile.photoUrl != null) score += 18;
    if (profile.portfolioPreviewUrls.isNotEmpty) score += 18;
    if (profile.services.isNotEmpty || profile.categories.isNotEmpty) {
      score += 16;
    }
    if (profile.city.trim().isNotEmpty || profile.country.trim().isNotEmpty) {
      score += 8;
    }
    if (profile.hasValidRating) {
      score += 8;
      score += ((profile.ratingAvg ?? 0) * 2).round();
      score += (profile.ratingCount ?? 0).clamp(0, 10);
    }
    return score;
  }

  void _openProfile(BuildContext context, ProviderSearchProfile profile) {
    final callback = onOpenProfile;
    if (callback != null) {
      callback(context, profile);
      return;
    }

    openPublicProfile<void>(
      context,
      userId: profile.id,
      role: 'prestador',
      initialName: profile.displayName,
      initialPhotoUrl: profile.photoUrl,
    );
  }
}

class _ProviderSuggestionsShell extends StatelessWidget {
  const _ProviderSuggestionsShell({
    required this.child,
    required this.margin,
    this.trailing,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Column(
        key: const Key('provider_suggestions_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Prestadores para conhecer',
            subtitle:
                'Explora perfis disponiveis e ve portfolio, servicos e avaliacoes.',
            trailing: trailing,
          ),
          child,
        ],
      ),
    );
  }
}

class _ProviderSuggestionsLoadingState extends StatelessWidget {
  const _ProviderSuggestionsLoadingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      variant: AppCardVariant.outlined,
      size: AppCardSize.compact,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Text(
            'A carregar sugestoes...',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ProviderSuggestionsErrorState extends StatelessWidget {
  const _ProviderSuggestionsErrorState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      variant: AppCardVariant.outlined,
      size: AppCardSize.compact,
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              'Sugestoes indisponiveis agora.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
