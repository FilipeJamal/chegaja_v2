import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:chegaja_v2/features/cliente/favoritos_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('embedded saved providers handles unavailable auth safely',
      (tester) async {
    var profileLoads = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: FavoritosContent(
          uidResolver: () async => null,
          favoriteIdsStream: Stream.value(const ['provider-1']),
          profileLoader: (_) async {
            profileLoads += 1;
            return _profile('provider-1');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Não conseguimos preparar os guardados. Verifica a ligação e tenta novamente.',
      ),
      findsOneWidget,
    );
    expect(profileLoads, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state is embedded, accessible in dark mode and actionable',
      (tester) async {
    var browsed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: FavoritosContent(
          uidResolver: () async => 'customer-1',
          favoriteIdsStream: Stream.value(const []),
          profileLoader: (_) async => null,
          onBrowseProviders: () => browsed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('favoritos_embedded')), findsOneWidget);
    expect(find.byType(Scaffold), findsNothing);
    expect(find.text('Ainda não guardaste prestadores.'), findsOneWidget);

    await tester.tap(find.text('Pesquisar prestadores'));
    expect(browsed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one inaccessible profile does not take down the saved list',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FavoritosContent(
          uidResolver: () async => 'customer-1',
          favoriteIdsStream: Stream.value(const ['good', 'inaccessible']),
          profileLoader: (id) async {
            if (id == 'inaccessible') throw StateError('permission-denied');
            return _profile(id);
          },
          onToggleFavorite: (_) async => false,
          onOpenProfile: (_, __) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('favoritos_list')), findsOneWidget);
    expect(find.text('Prestador good'), findsOneWidget);
    expect(
      find.text('1 perfil guardado está temporariamente indisponível.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens and removes a saved provider through injected actions',
      (tester) async {
    String? openedId;
    String? toggledId;

    await tester.pumpWidget(
      MaterialApp(
        home: FavoritosContent(
          uidResolver: () async => 'customer-1',
          favoriteIdsStream: Stream.value(const ['provider-1']),
          profileLoader: (id) async => _profile(id),
          onToggleFavorite: (id) async {
            toggledId = id;
            return false;
          },
          onOpenProfile: (_, profile) => openedId = profile.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const Key('provider_search_favorite_button_provider-1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(toggledId, 'provider-1');

    await tester.tap(
      find.byKey(const Key('provider_search_card_provider-1')),
    );
    expect(openedId, 'provider-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone route keeps its Scaffold', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FavoritosScreen(
          experienceV2Override: true,
          uidResolver: () async => 'customer-1',
          favoriteIdsStream: Stream.value(const []),
          profileLoader: (_) async => null,
          onBrowseProviders: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Prestadores guardados'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('flag off keeps the standalone legacy favorites experience',
      (tester) async {
    String? openedId;
    String? toggledId;

    await tester.pumpWidget(
      MaterialApp(
        home: FavoritosScreen(
          experienceV2Override: false,
          uidResolver: () async => 'customer-1',
          favoriteIdsStream: Stream.value(const ['provider-1']),
          profileLoader: (id) async => _profile(id),
          onToggleFavorite: (id) async {
            toggledId = id;
            return false;
          },
          onOpenProfile: (_, profile) => openedId = profile.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('favoritos_standalone_legacy')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('favoritos_legacy_list')), findsOneWidget);
    expect(find.text('Meus Favoritos'), findsOneWidget);
    expect(find.text('Prestadores guardados'), findsNothing);

    await tester.tap(
      find.byKey(const Key('favoritos_legacy_remove_provider-1')),
    );
    await tester.pump();
    expect(toggledId, 'provider-1');

    await tester.tap(find.text('Prestador provider-1'));
    expect(openedId, 'provider-1');
    expect(tester.takeException(), isNull);
  });
}

ProviderSearchProfile _profile(String id) {
  return ProviderSearchProfile(
    id: id,
    displayName: 'Prestador $id',
    photoUrl: null,
    bio: 'Serviços locais em Coimbra.',
    city: 'Coimbra',
    state: '',
    country: 'Portugal',
    services: const ['Limpeza'],
    categories: const ['cleaning'],
    portfolioPreviewUrls: const [],
    ratingAvg: 4.8,
    ratingCount: 12,
    searchTerms: const ['limpeza', 'coimbra'],
    latitude: null,
    longitude: null,
  );
}
