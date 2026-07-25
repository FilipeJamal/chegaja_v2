import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/feature_flags/feature_flag.dart';
import '../../core/feature_flags/feature_flag_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_product_header.dart';
import '../../core/widgets/app_state_views.dart';
import 'discovery/provider_search_profile.dart';
import 'discovery/provider_search_screen.dart';
import 'discovery/widgets/provider_search_card.dart';
import '../common/utils/open_public_profile.dart';

typedef CustomerUidResolver = Future<String?> Function();
typedef SavedProviderProfileLoader = Future<ProviderSearchProfile?> Function(
  String providerId,
);
typedef SavedProviderToggle = Future<bool> Function(String providerId);
typedef SavedProviderOpenCallback = void Function(
  BuildContext context,
  ProviderSearchProfile profile,
);

/// Standalone route retained for existing profile links.
///
/// Use [embedded] when this screen is placed inside [AppShellScaffold].
class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({
    super.key,
    this.embedded = false,
    this.firestore,
    this.favoriteIdsStream,
    this.uidResolver,
    this.profileLoader,
    this.onToggleFavorite,
    this.onOpenProfile,
    this.onBrowseProviders,
    this.experienceV2Override,
  });

  final bool embedded;
  final FirebaseFirestore? firestore;
  final Stream<List<String>>? favoriteIdsStream;
  final CustomerUidResolver? uidResolver;
  final SavedProviderProfileLoader? profileLoader;
  final SavedProviderToggle? onToggleFavorite;
  final SavedProviderOpenCallback? onOpenProfile;
  final VoidCallback? onBrowseProviders;
  final bool? experienceV2Override;

  @override
  Widget build(BuildContext context) {
    final experienceV2 = experienceV2Override ??
        FeatureFlagService.instance.isEnabled(
          FeatureFlag.u1NavigationV2,
        );
    return FavoritosContent(
      embedded: embedded,
      experienceV2: experienceV2,
      firestore: firestore,
      favoriteIdsStream: favoriteIdsStream,
      uidResolver: uidResolver,
      profileLoader: profileLoader,
      onToggleFavorite: onToggleFavorite,
      onOpenProfile: onOpenProfile,
      onBrowseProviders: onBrowseProviders,
    );
  }
}

class FavoritosContent extends StatefulWidget {
  const FavoritosContent({
    super.key,
    this.embedded = true,
    this.firestore,
    this.favoriteIdsStream,
    this.uidResolver,
    this.profileLoader,
    this.onToggleFavorite,
    this.onOpenProfile,
    this.onBrowseProviders,
    this.experienceV2 = true,
  });

  final bool embedded;
  final bool experienceV2;
  final FirebaseFirestore? firestore;
  final Stream<List<String>>? favoriteIdsStream;
  final CustomerUidResolver? uidResolver;
  final SavedProviderProfileLoader? profileLoader;
  final SavedProviderToggle? onToggleFavorite;
  final SavedProviderOpenCallback? onOpenProfile;
  final VoidCallback? onBrowseProviders;

  @override
  State<FavoritosContent> createState() => _FavoritosContentState();
}

class _FavoritosContentState extends State<FavoritosContent> {
  late final CustomerUidResolver _uidResolver;
  late final SavedProviderProfileLoader _profileLoader;
  late Future<void> _initialization;
  Stream<List<String>>? _favoriteIdsStream;
  String _profileCacheKey = '';
  Future<_SavedProfilesLoadResult>? _profilesFuture;
  final Set<String> _toggleInProgress = <String>{};

  @override
  void initState() {
    super.initState();
    _uidResolver = widget.uidResolver ?? _resolveCurrentCustomerUid;
    _profileLoader = widget.profileLoader ?? _loadPublicProvider;
    _initialization = _initialize();
  }

  @override
  void didUpdateWidget(covariant FavoritosContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.experienceV2 != widget.experienceV2) {
      _profileCacheKey = '';
      _profilesFuture = null;
    }
  }

  Future<void> _initialize() async {
    final uid = (await _uidResolver())?.trim();
    if (uid == null || uid.isEmpty) {
      throw StateError('Customer session is unavailable.');
    }

    _favoriteIdsStream = widget.favoriteIdsStream ??
        FavoritesService.instance.getFavoritesStream();
  }

  void _retryInitialization() {
    setState(() {
      _favoriteIdsStream = null;
      _profileCacheKey = '';
      _profilesFuture = null;
      _initialization = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.experienceV2
              ? const AppLoadingView(label: 'A carregar guardados...')
              : const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || _favoriteIdsStream == null) {
          if (!widget.experienceV2) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Erro ao carregar favoritos.'),
              ),
            );
          }
          return AppErrorView(
            message:
                'Não conseguimos preparar os guardados. Verifica a ligação e tenta novamente.',
            retryLabel: 'Tentar novamente',
            onRetry: _retryInitialization,
          );
        }
        return _buildFavoritesStream();
      },
    );

    if (!widget.embedded) {
      return Scaffold(
        key: Key(
          widget.experienceV2
              ? 'favoritos_standalone_v2'
              : 'favoritos_standalone_legacy',
        ),
        appBar: AppBar(
          title: Text(
            widget.experienceV2 ? 'Prestadores guardados' : 'Meus Favoritos',
          ),
        ),
        body: SafeArea(child: body),
      );
    }

    if (!widget.experienceV2) {
      return ColoredBox(
        key: const Key('favoritos_embedded_legacy'),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(child: body),
      );
    }

    return ColoredBox(
      key: const Key('favoritos_embedded'),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.contentMaxTwoColumn,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x4,
                    AppSpacing.x5,
                    AppSpacing.x4,
                    AppSpacing.x4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppProductHeader(
                        title: 'Prestadores guardados',
                        subtitle:
                            'Volta rapidamente aos profissionais que queres acompanhar.',
                        showBrand: false,
                      ),
                      const SizedBox(height: AppSpacing.x4),
                      Expanded(child: body),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFavoritesStream() {
    return StreamBuilder<List<String>>(
      stream: _favoriteIdsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return widget.experienceV2
              ? const AppLoadingView(label: 'A carregar guardados...')
              : const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (!widget.experienceV2) {
            return const Center(
              child: Text('Erro ao carregar favoritos.'),
            );
          }
          return AppErrorView(
            message:
                'Não conseguimos atualizar os guardados. Verifica a ligação e tenta novamente.',
            retryLabel: 'Tentar novamente',
            onRetry: _retryInitialization,
          );
        }

        final ids = _normalizeIds(snapshot.data ?? const <String>[]);
        if (ids.isEmpty) {
          if (!widget.experienceV2) {
            return const _LegacyFavoritesEmpty();
          }
          return AppEmptyView(
            title: 'Ainda não guardaste prestadores.',
            message:
                'Pesquisa profissionais e guarda os perfis a que queres voltar.',
            actionLabel: 'Pesquisar prestadores',
            onAction: _browseProviders,
          );
        }

        return FutureBuilder<_SavedProfilesLoadResult>(
          future: _loadProfiles(ids),
          builder: (context, profilesSnapshot) {
            if (profilesSnapshot.connectionState != ConnectionState.done) {
              return widget.experienceV2
                  ? const AppLoadingView(
                      label: 'A preparar perfis guardados...',
                    )
                  : const Center(child: CircularProgressIndicator());
            }
            if (profilesSnapshot.hasError) {
              if (!widget.experienceV2) {
                return const Center(
                  child: Text('Erro ao carregar favoritos.'),
                );
              }
              return AppErrorView(
                message:
                    'Não conseguimos abrir os perfis guardados. Tenta novamente.',
                retryLabel: 'Tentar novamente',
                onRetry: _retryProfiles,
              );
            }

            final result = profilesSnapshot.data;
            if (result == null || result.profiles.isEmpty) {
              if (!widget.experienceV2) {
                return const _LegacyFavoritesEmpty();
              }
              return AppErrorView(
                message: result?.failedCount == ids.length
                    ? 'Os perfis guardados estão temporariamente indisponíveis.'
                    : 'Os perfis guardados já não estão disponíveis.',
                retryLabel: 'Tentar novamente',
                onRetry: _retryProfiles,
              );
            }

            if (!widget.experienceV2) {
              return _LegacySavedProvidersList(
                profiles: result.profiles,
                toggleInProgress: _toggleInProgress,
                onOpen: _openProfile,
                onToggle: _toggleFavorite,
              );
            }

            return _SavedProvidersList(
              profiles: result.profiles,
              unavailableCount: result.failedCount,
              toggleInProgress: _toggleInProgress,
              onOpen: _openProfile,
              onToggle: _toggleFavorite,
            );
          },
        );
      },
    );
  }

  Future<_SavedProfilesLoadResult> _loadProfiles(List<String> ids) {
    final nextCacheKey = ids.join('\u0000');
    if (_profilesFuture != null && nextCacheKey == _profileCacheKey) {
      return _profilesFuture!;
    }

    _profileCacheKey = nextCacheKey;
    _profilesFuture = _loadProfilesIsolated(ids);
    return _profilesFuture!;
  }

  Future<_SavedProfilesLoadResult> _loadProfilesIsolated(
    List<String> ids,
  ) async {
    final outcomes = await Future.wait(
      ids.map((id) async {
        try {
          final profile = await _profileLoader(id);
          return _SavedProfileOutcome(profile: profile, failed: false);
        } catch (_) {
          return const _SavedProfileOutcome(profile: null, failed: true);
        }
      }),
    );

    final profiles = outcomes
        .map((outcome) => outcome.profile)
        .whereType<ProviderSearchProfile>();
    return _SavedProfilesLoadResult(
      profiles: (widget.experienceV2
              ? profiles.where((profile) => profile.isSearchableLocal)
              : profiles)
          .toList(growable: false),
      failedCount: outcomes.where((outcome) => outcome.failed).length,
    );
  }

  Future<ProviderSearchProfile?> _loadPublicProvider(String providerId) async {
    final firestore = widget.firestore ?? FirebaseFirestore.instance;
    final doc =
        await firestore.collection('provider_public').doc(providerId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return ProviderSearchProfile.fromPrestadorDoc(
      id: doc.id,
      data: data,
    );
  }

  void _retryProfiles() {
    setState(() {
      _profileCacheKey = '';
      _profilesFuture = null;
    });
  }

  Future<void> _toggleFavorite(ProviderSearchProfile profile) async {
    if (_toggleInProgress.contains(profile.id)) return;
    setState(() => _toggleInProgress.add(profile.id));

    try {
      final toggle =
          widget.onToggleFavorite ?? FavoritesService.instance.toggleFavorite;
      final isFavorite = await toggle(profile.id);
      if (!mounted) return;
      if (!widget.experienceV2) return;
      _showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? 'Prestador guardado.' : 'Removido dos guardados.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar os guardados.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _toggleInProgress.remove(profile.id));
    }
  }

  void _showSnackBar(SnackBar snackBar) {
    if (Scaffold.maybeOf(context) == null) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(snackBar);
  }

  void _openProfile(ProviderSearchProfile profile) {
    final callback = widget.onOpenProfile;
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

  void _browseProviders() {
    final callback = widget.onBrowseProviders;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProviderSearchScreen()),
    );
  }

  Future<String?> _resolveCurrentCustomerUid() async {
    final current = AuthService.currentUser;
    if (current != null) return current.uid;
    try {
      final user = await AuthService.ensureSignedInAnonymously();
      return user.uid;
    } catch (_) {
      return null;
    }
  }

  List<String> _normalizeIds(Iterable<String> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isEmpty || !seen.add(normalized)) continue;
      result.add(normalized);
    }
    return result;
  }
}

class _LegacyFavoritesEmpty extends StatelessWidget {
  const _LegacyFavoritesEmpty();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      key: const Key('favoritos_legacy_empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            'Ainda nÃ£o tens favoritos.',
            style: TextStyle(
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacySavedProvidersList extends StatelessWidget {
  const _LegacySavedProvidersList({
    required this.profiles,
    required this.toggleInProgress,
    required this.onOpen,
    required this.onToggle,
  });

  final List<ProviderSearchProfile> profiles;
  final Set<String> toggleInProgress;
  final ValueChanged<ProviderSearchProfile> onOpen;
  final ValueChanged<ProviderSearchProfile> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      key: const Key('favoritos_legacy_list'),
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return Card(
          key: Key('favoritos_legacy_provider_${profile.id}'),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: profile.photoUrl == null
                  ? null
                  : NetworkImage(profile.photoUrl!),
              child: profile.photoUrl == null
                  ? Text(
                      profile.displayName.isEmpty
                          ? 'P'
                          : profile.displayName[0].toUpperCase(),
                    )
                  : null,
            ),
            title: Text(
              profile.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.ratingCount == null ||
                              profile.ratingCount == 0 ||
                              profile.ratingAvg == null
                          ? 'Sem avaliaÃ§Ãµes'
                          : '${(profile.ratingAvg ?? 0).toStringAsFixed(1)} '
                              '(${profile.ratingCount})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                if (profile.city.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.city,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              key: Key('favoritos_legacy_remove_${profile.id}'),
              tooltip: 'Remover dos favoritos',
              icon: toggleInProgress.contains(profile.id)
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.favorite, color: Colors.red),
              onPressed: toggleInProgress.contains(profile.id)
                  ? null
                  : () => onToggle(profile),
            ),
            onTap: () => onOpen(profile),
          ),
        );
      },
    );
  }
}

class _SavedProvidersList extends StatelessWidget {
  const _SavedProvidersList({
    required this.profiles,
    required this.unavailableCount,
    required this.toggleInProgress,
    required this.onOpen,
    required this.onToggle,
  });

  final List<ProviderSearchProfile> profiles;
  final int unavailableCount;
  final Set<String> toggleInProgress;
  final ValueChanged<ProviderSearchProfile> onOpen;
  final ValueChanged<ProviderSearchProfile> onToggle;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const Key('favoritos_list'),
      padding: const EdgeInsets.only(bottom: AppSpacing.x5),
      itemCount: profiles.length + (unavailableCount > 0 ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x3),
      itemBuilder: (context, index) {
        if (unavailableCount > 0 && index == 0) {
          return Semantics(
            liveRegion: true,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(
                context.chegaJaTheme.radiusMd,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x3),
                child: Text(
                  unavailableCount == 1
                      ? '1 perfil guardado está temporariamente indisponível.'
                      : '$unavailableCount perfis guardados estão temporariamente indisponíveis.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          );
        }

        final profileIndex = index - (unavailableCount > 0 ? 1 : 0);
        final profile = profiles[profileIndex];
        return ProviderSearchCard(
          key: Key('favoritos_provider_${profile.id}'),
          profile: profile,
          isFavorite: true,
          favoriteLoading: toggleInProgress.contains(profile.id),
          onToggleFavorite: () => onToggle(profile),
          onTap: () => onOpen(profile),
        );
      },
    );
  }
}

class _SavedProfilesLoadResult {
  const _SavedProfilesLoadResult({
    required this.profiles,
    required this.failedCount,
  });

  final List<ProviderSearchProfile> profiles;
  final int failedCount;
}

class _SavedProfileOutcome {
  const _SavedProfileOutcome({
    required this.profile,
    required this.failed,
  });

  final ProviderSearchProfile? profile;
  final bool failed;
}
