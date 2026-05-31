import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:chegaja_v2/features/cliente/discovery/widgets/provider_search_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderSearchProfile _profile({
  double? ratingAvg = 4.8,
  int? ratingCount = 12,
  String? handle,
}) {
  return ProviderSearchProfile(
    id: 'prestador-1',
    displayName: 'Joao Bolos',
    photoUrl: 'https://example.com/avatar.jpg',
    bio: 'Bolos de aniversario e sobremesas.',
    city: 'Coimbra',
    state: '',
    country: 'Portugal',
    services: const ['Bolos personalizados', 'Sobremesas'],
    categories: const ['Pastelaria'],
    portfolioPreviewUrls: const ['https://example.com/bolo.jpg'],
    ratingAvg: ratingAvg,
    ratingCount: ratingCount,
    searchTerms: const ['joao bolos', 'bolos personalizados'],
    latitude: null,
    longitude: null,
    handle: handle,
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required ProviderSearchProfile profile,
  VoidCallback? onTap,
  VoidCallback? onToggleFavorite,
  bool isFavorite = false,
  bool favoriteLoading = false,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: ProviderSearchCard(
          profile: profile,
          onTap: onTap ?? () {},
          isFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
          favoriteLoading: favoriteLoading,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mostra dados publicos principais do prestador', (tester) async {
    await _pumpCard(tester, profile: _profile(handle: 'joao_bolos'));

    expect(find.text('Joao Bolos'), findsOneWidget);
    expect(find.text('@joao_bolos'), findsOneWidget);
    expect(find.text('Bolos personalizados, Sobremesas'), findsOneWidget);
    expect(find.text('Coimbra, Portugal'), findsOneWidget);
    expect(find.text('4,8'), findsOneWidget);
    expect(find.text('12 avaliacoes'), findsOneWidget);
  });

  testWidgets('nao mostra @handle quando ausente', (tester) async {
    await _pumpCard(tester, profile: _profile());

    expect(find.text('@joao_bolos'), findsNothing);
  });

  testWidgets('nao mostra rating quando os agregados sao invalidos',
      (tester) async {
    await _pumpCard(tester, profile: _profile(ratingAvg: 6, ratingCount: 12));

    expect(find.text('4,8'), findsNothing);
    expect(find.textContaining('avaliacoes'), findsNothing);
  });

  testWidgets('mostra botao de favorito quando callback existe',
      (tester) async {
    await _pumpCard(
      tester,
      profile: _profile(),
      onToggleFavorite: () {},
    );

    expect(
      find.byKey(const Key('provider_search_favorite_button_prestador-1')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
  });

  testWidgets('favorito true mostra icone preenchido', (tester) async {
    await _pumpCard(
      tester,
      profile: _profile(),
      isFavorite: true,
      onToggleFavorite: () {},
    );

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });

  testWidgets('tocar no favorito chama callback sem abrir perfil',
      (tester) async {
    var favoriteTapped = false;
    var cardTapped = false;

    await _pumpCard(
      tester,
      profile: _profile(),
      onTap: () => cardTapped = true,
      onToggleFavorite: () => favoriteTapped = true,
    );

    await tester.tap(
      find.byKey(const Key('provider_search_favorite_button_prestador-1')),
    );

    expect(favoriteTapped, isTrue);
    expect(cardTapped, isFalse);
  });

  testWidgets('estado loading bloqueia toggle favorito', (tester) async {
    var favoriteTaps = 0;

    await _pumpCard(
      tester,
      profile: _profile(),
      favoriteLoading: true,
      onToggleFavorite: () => favoriteTaps++,
    );

    await tester.tap(
      find.byKey(const Key('provider_search_favorite_button_prestador-1')),
    );

    expect(favoriteTaps, 0);
  });

  testWidgets('nao mostra telefone nem email', (tester) async {
    await _pumpCard(tester, profile: _profile());

    expect(find.textContaining('912345678'), findsNothing);
    expect(find.textContaining('@example.com'), findsNothing);
  });

  testWidgets('chama callback ao tocar no card', (tester) async {
    var tapped = false;
    await _pumpCard(
      tester,
      profile: _profile(),
      onTap: () => tapped = true,
    );

    await tester.tap(find.byKey(const Key('provider_search_card_prestador-1')));

    expect(tapped, isTrue);
  });

  testWidgets('renderiza em dark mode sem erro', (tester) async {
    await _pumpCard(
      tester,
      profile: _profile(),
      theme: ThemeData.dark(),
    );

    expect(find.byKey(const Key('provider_search_card_prestador-1')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
