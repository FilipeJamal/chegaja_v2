import 'dart:async';

import 'package:chegaja_v2/features/cliente/discovery/provider_search_profile.dart';
import 'package:chegaja_v2/features/cliente/discovery/widgets/provider_suggestions_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderSearchProfile _profile({
  required String id,
  required String name,
  List<String> services = const <String>['Bolos personalizados'],
  String city = 'Coimbra',
  String country = 'Portugal',
  double? ratingAvg = 4.7,
  int? ratingCount = 9,
  List<String> portfolio = const <String>['https://example.com/bolo.jpg'],
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
    categories: const <String>['Pastelaria'],
    portfolioPreviewUrls: portfolio,
    ratingAvg: ratingAvg,
    ratingCount: ratingCount,
    searchTerms: const <String>[],
    latitude: null,
    longitude: null,
  );
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required Stream<List<ProviderSearchProfile>> profilesStream,
  void Function(ProviderSearchProfile profile)? onOpenProfile,
  VoidCallback? onOpenSearch,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProviderSuggestionsSection(
            profilesStream: profilesStream,
            onOpenSearch: onOpenSearch ?? () {},
            onOpenProfile: (_, profile) => onOpenProfile?.call(profile),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('mostra titulo e cards compactos com dados publicos',
      (tester) async {
    await _pumpSection(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos'),
      ]),
    );
    await tester.pump();

    expect(find.text('Prestadores para conhecer'), findsOneWidget);
    expect(find.text('Joao Bolos'), findsOneWidget);
    expect(find.text('Bolos personalizados'), findsOneWidget);
    expect(find.text('Coimbra, Portugal'), findsOneWidget);
    expect(find.text('4,7'), findsOneWidget);
    expect(find.text('9 avaliacoes'), findsOneWidget);
  });

  testWidgets('mostra rating apenas quando valido', (tester) async {
    await _pumpSection(
      tester,
      profilesStream: Stream.value([
        _profile(
          id: 'p1',
          name: 'Maria Luz',
          ratingAvg: 6,
          ratingCount: 4,
        ),
      ]),
    );
    await tester.pump();

    expect(find.text('Maria Luz'), findsOneWidget);
    expect(find.text('6,0'), findsNothing);
    expect(find.text('4 avaliacoes'), findsNothing);
  });

  testWidgets('nao mostra telefone nem email', (tester) async {
    await _pumpSection(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos'),
      ]),
    );
    await tester.pump();

    expect(find.textContaining('912345678'), findsNothing);
    expect(find.textContaining('@example.com'), findsNothing);
  });

  testWidgets('tocar no card chama callback de abrir perfil', (tester) async {
    ProviderSearchProfile? opened;

    await _pumpSection(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos'),
      ]),
      onOpenProfile: (profile) => opened = profile,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('provider_suggestion_card_p1')));

    expect(opened?.id, 'p1');
  });

  testWidgets('botao pesquisar prestadores chama callback', (tester) async {
    var openedSearch = false;

    await _pumpSection(
      tester,
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos'),
      ]),
      onOpenSearch: () => openedSearch = true,
    );
    await tester.pump();

    await tester
        .tap(find.byKey(const Key('provider_suggestions_search_button')));

    expect(openedSearch, isTrue);
  });

  testWidgets('loading renderiza sem quebrar', (tester) async {
    final controller = StreamController<List<ProviderSearchProfile>>();
    addTearDown(controller.close);

    await _pumpSection(tester, profilesStream: controller.stream);

    expect(find.text('A carregar sugestoes...'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erro renderiza estado discreto', (tester) async {
    final controller = StreamController<List<ProviderSearchProfile>>();
    addTearDown(controller.close);

    await _pumpSection(tester, profilesStream: controller.stream);
    controller.addError(Exception('falha'));
    await tester.pump();

    expect(find.text('Sugestoes indisponiveis agora.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem sugestoes esconde a seccao', (tester) async {
    await _pumpSection(
      tester,
      profilesStream: Stream.value(const <ProviderSearchProfile>[]),
    );
    await tester.pump();

    expect(find.text('Prestadores para conhecer'), findsNothing);
  });

  testWidgets('dark mode renderiza sem erro', (tester) async {
    await _pumpSection(
      tester,
      theme: ThemeData.dark(),
      profilesStream: Stream.value([
        _profile(id: 'p1', name: 'Joao Bolos'),
      ]),
    );
    await tester.pump();

    expect(
        find.byKey(const Key('provider_suggestions_section')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
