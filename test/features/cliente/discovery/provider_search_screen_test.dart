import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:chegaja_v2/features/cliente/discovery/provider_search_screen.dart';

ProviderSearchProfile _profile({
  required String id,
  required String name,
  List<String> services = const <String>[],
  List<String> categories = const <String>[],
  String city = '',
  String country = 'Portugal',
  double? ratingAvg,
  int? ratingCount,
}) {
  return ProviderSearchProfile(
    id: id,
    displayName: name,
    photoUrl: null,
    bio: 'Perfil publico de $name',
    city: city,
    state: '',
    country: country,
    services: services,
    categories: categories,
    portfolioPreviewUrls: const <String>[],
    ratingAvg: ratingAvg,
    ratingCount: ratingCount,
    searchTerms: const <String>[],
    latitude: null,
    longitude: null,
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  Stream<List<ProviderSearchProfile>>? profilesStream,
  Stream<List<String>>? favoriteIdsStream,
  FakeFirebaseFirestore? firestore,
  Future<bool> Function(String providerId)? onToggleFavorite,
  ProviderSearchOpenCallback? onOpenProfile,
  bool enableFavoriteActions = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProviderSearchScreen(
        profilesStream: profilesStream,
        favoriteIdsStream: favoriteIdsStream,
        firestore: firestore,
        onToggleFavorite: onToggleFavorite,
        onOpenProfile: onOpenProfile,
        enableFavoriteActions: enableFavoriteActions,
      ),
    ),
  );
}

Future<void> _typeQuery(WidgetTester tester, String query) async {
  await tester.enterText(
      find.byKey(const Key('provider_search_query_field')), query);
  await tester.pump();
}

void main() {
  testWidgets('estado inicial orienta o utilizador', (tester) async {
    await _pumpScreen(
      tester,
      profilesStream: Stream.value(const <ProviderSearchProfile>[]),
    );

    expect(find.text('Pesquisa manual de prestadores'), findsWidgets);
    expect(find.text('Procura por nome, servico ou cidade.'), findsOneWidget);
  });

  testWidgets('loading renderiza enquanto carrega prestadores', (tester) async {
    final controller = StreamController<List<ProviderSearchProfile>>();
    addTearDown(controller.close);

    await _pumpScreen(tester, profilesStream: controller.stream);
    await _typeQuery(tester, 'jo');

    expect(find.text('A carregar prestadores...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('erro renderiza estado simples', (tester) async {
    final controller = StreamController<List<ProviderSearchProfile>>();
    addTearDown(controller.close);

    await _pumpScreen(tester, profilesStream: controller.stream);
    await _typeQuery(tester, 'jo');
    controller.addError(Exception('falha'));
    await tester.pump();

    expect(find.text('Nao conseguimos carregar os prestadores agora.'),
        findsOneWidget);
  });

  testWidgets('query por nome, servico e cidade mostra resultados',
      (tester) async {
    final profiles = [
      _profile(id: 'p1', name: 'Joao Bolos', services: ['Bolos']),
      _profile(id: 'p2', name: 'Maria Luz', services: ['Eletricista']),
      _profile(id: 'p3', name: 'Ana Limpeza', city: 'Coimbra'),
    ];

    await _pumpScreen(tester, profilesStream: Stream.value(profiles));

    await _typeQuery(tester, 'joao');
    await tester.pump();
    expect(find.text('Joao Bolos'), findsOneWidget);

    await _typeQuery(tester, 'eletricista');
    await tester.pump();
    expect(find.text('Maria Luz'), findsOneWidget);

    await _typeQuery(tester, 'coimbra');
    await tester.pump();
    expect(find.text('Ana Limpeza'), findsOneWidget);
  });

  testWidgets('query sem resultados mostra estado vazio', (tester) async {
    await _pumpScreen(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos', services: ['Bolos']),
      ]),
    );

    await _typeQuery(tester, 'canalizador');
    await tester.pump();

    expect(find.text('Nenhum prestador encontrado'), findsOneWidget);
    expect(find.text('Tenta pesquisar por nome, servico ou cidade.'),
        findsOneWidget);
  });

  testWidgets('tocar no card chama abertura de perfil', (tester) async {
    ProviderSearchProfile? openedProfile;

    await _pumpScreen(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos', services: ['Bolos']),
      ]),
      onOpenProfile: (_, profile) {
        openedProfile = profile;
      },
    );

    await _typeQuery(tester, 'joao');
    await tester.pump();
    await tester.tap(find.byKey(const Key('provider_search_card_p1')));

    expect(openedProfile?.id, 'p1');
  });

  testWidgets('resultado mostra estado favorito correto', (tester) async {
    await _pumpScreen(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos', services: ['Bolos']),
      ]),
      favoriteIdsStream: Stream.value(['p1']),
    );

    await _typeQuery(tester, 'joao');
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('toggle favorito chama callback injetado', (tester) async {
    String? toggledId;

    await _pumpScreen(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos', services: ['Bolos']),
      ]),
      favoriteIdsStream: Stream.value(const <String>[]),
      onToggleFavorite: (providerId) async {
        toggledId = providerId;
        return true;
      },
    );

    await _typeQuery(tester, 'joao');
    await tester.pump();
    await tester
        .tap(find.byKey(const Key('provider_search_favorite_button_p1')));
    await tester.pump();

    expect(toggledId, 'p1');
    expect(find.text('Adicionado aos favoritos.'), findsOneWidget);
  });

  testWidgets('erro ao favoritar mostra feedback simples', (tester) async {
    await _pumpScreen(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos', services: ['Bolos']),
      ]),
      favoriteIdsStream: Stream.value(const <String>[]),
      onToggleFavorite: (_) async => throw Exception('sem auth'),
    );

    await _typeQuery(tester, 'joao');
    await tester.pump();
    await tester
        .tap(find.byKey(const Key('provider_search_favorite_button_p1')));
    await tester.pump();

    expect(find.text('Nao foi possivel atualizar favorito.'), findsOneWidget);
  });

  testWidgets('card sem favorito continua abrindo perfil', (tester) async {
    ProviderSearchProfile? openedProfile;

    await _pumpScreen(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos', services: ['Bolos']),
      ]),
      enableFavoriteActions: false,
      onOpenProfile: (_, profile) => openedProfile = profile,
    );

    await _typeQuery(tester, 'joao');
    await tester.pump();

    expect(find.byKey(const Key('provider_search_favorite_button_p1')),
        findsNothing);

    await tester.tap(find.byKey(const Key('provider_search_card_p1')));

    expect(openedProfile?.id, 'p1');
  });

  testWidgets('usa provider_public pesquisavel como fonte Firestore inicial',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('provider_public').doc('p1').set({
      'nome': 'Joao Bolos',
      'servicosNomes': ['Bolos personalizados'],
      'city': 'Coimbra',
      'country': 'Portugal',
      'isSearchable': true,
    });
    await db.collection('users_private').doc('u1').set({
      'displayName': 'Utilizador Prestador Legado',
      'roles': {'prestador': true},
    });

    await _pumpScreen(tester, firestore: db);
    await _typeQuery(tester, 'bolos');
    await tester.pump();

    expect(find.text('Joao Bolos'), findsOneWidget);
    expect(find.text('Utilizador Prestador Legado'), findsNothing);
  });
}
