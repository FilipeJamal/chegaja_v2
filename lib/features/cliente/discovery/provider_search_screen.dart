import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_matcher.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_normalizer.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:chegaja_v2/features/cliente/discovery/widgets/provider_search_card.dart';
import 'package:chegaja_v2/features/cliente/discovery/widgets/provider_search_empty_state.dart';
import 'package:chegaja_v2/features/common/utils/open_public_profile.dart';
import 'package:flutter/material.dart';

typedef ProviderSearchOpenCallback = void Function(
  BuildContext context,
  ProviderSearchProfile profile,
);

class ProviderSearchScreen extends StatefulWidget {
  const ProviderSearchScreen({
    super.key,
    this.firestore,
    this.profilesStream,
    this.onOpenProfile,
    this.limit = 80,
  });

  final FirebaseFirestore? firestore;
  final Stream<List<ProviderSearchProfile>>? profilesStream;
  final ProviderSearchOpenCallback? onOpenProfile;
  final int limit;

  @override
  State<ProviderSearchScreen> createState() => _ProviderSearchScreenState();
}

class _ProviderSearchScreenState extends State<ProviderSearchScreen> {
  late final TextEditingController _queryController;
  late final Stream<List<ProviderSearchProfile>> _profilesStream;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _profilesStream = widget.profilesStream ?? _buildFirestoreStream();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesquisar prestadores'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('provider_search_query_field'),
                    controller: _queryController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    cursorColor: colorScheme.primary,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Pesquisa manual de prestadores',
                      hintText: 'Nome, servico ou cidade',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colorScheme.primary,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              key: const Key('provider_search_clear_button'),
                              tooltip: 'Limpar pesquisa',
                              onPressed: _clearQuery,
                              icon: Icon(
                                Icons.close_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _query = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Stream<List<ProviderSearchProfile>> _buildFirestoreStream() {
    final db = widget.firestore ?? FirebaseFirestore.instance;
    return db.collection('prestadores').limit(widget.limit).snapshots().map(
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

  Widget _buildBody() {
    final normalizedQuery = ProviderSearchNormalizer.normalize(_query);
    if (normalizedQuery.length < 2) {
      return const ProviderSearchEmptyState(
        icon: Icons.search_rounded,
        title: 'Pesquisa manual de prestadores',
        message: 'Procura por nome, servico ou cidade.',
      );
    }

    return StreamBuilder<List<ProviderSearchProfile>>(
      stream: _profilesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ProviderSearchEmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Nao conseguimos carregar os prestadores agora.',
            message: 'Verifica a ligacao e tenta novamente.',
          );
        }

        if (!snapshot.hasData) {
          return const _ProviderSearchLoadingState();
        }

        final results = _filterAndSort(snapshot.data ?? const []);
        if (results.isEmpty) {
          return const ProviderSearchEmptyState(
            icon: Icons.person_search_rounded,
            title: 'Nenhum prestador encontrado',
            message: 'Tenta pesquisar por nome, servico ou cidade.',
          );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x3),
          itemBuilder: (context, index) {
            final profile = results[index];
            return ProviderSearchCard(
              profile: profile,
              onTap: () => _openProfile(profile),
            );
          },
        );
      },
    );
  }

  List<ProviderSearchProfile> _filterAndSort(
    List<ProviderSearchProfile> profiles,
  ) {
    final results = profiles
        .where((profile) => profile.isSearchableLocal)
        .where((profile) => matchesProviderSearch(profile, _query))
        .toList();

    results.sort((a, b) {
      final scoreCompare = scoreProviderSearch(b, _query)
          .compareTo(scoreProviderSearch(a, _query));
      if (scoreCompare != 0) return scoreCompare;
      return a.displayName.compareTo(b.displayName);
    });

    return results;
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

  void _clearQuery() {
    _queryController.clear();
    setState(() => _query = '');
  }
}

class _ProviderSearchLoadingState extends StatelessWidget {
  const _ProviderSearchLoadingState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: AppSpacing.x3),
          Text(
            'A carregar prestadores...',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
