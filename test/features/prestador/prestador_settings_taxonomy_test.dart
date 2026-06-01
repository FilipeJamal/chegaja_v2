import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/catalog/provider_custom_service.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_service_taxonomy_selector.dart';

void main() {
  testWidgets('PrestadorServiceTaxonomySelector mostra categorias e aliases', (
    WidgetTester tester,
  ) async {
    var selected = <String>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrestadorServiceTaxonomySelector(
              selectedSubcategoryIds: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Categorias profissionais'), findsOneWidget);
    expect(find.text('Casa e reparacoes'), findsOneWidget);
    expect(find.text('Canalizacao'), findsOneWidget);
    expect(find.textContaining('cano'), findsWidgets);

    await tester.tap(find.text('Canalizacao').first);
    await tester.pumpAndSettle();

    expect(selected, contains('plumbing'));
  });

  testWidgets('PrestadorServiceTaxonomySelector pesquisa e marca sensivel', (
    WidgetTester tester,
  ) async {
    var selected = <String>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrestadorServiceTaxonomySelector(
              selectedSubcategoryIds: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_service_taxonomy_query_field')),
      'arranjar luz',
    );
    await tester.pumpAndSettle();

    expect(find.text('Eletricidade'), findsOneWidget);
    expect(
      find.text('Exige prestador com aprovacao na categoria.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Eletricidade').first);
    await tester.pumpAndSettle();

    expect(selected, contains('electricity'));
    expect(find.textContaining('certificado'), findsNothing);
    expect(find.textContaining('verificado'), findsNothing);
    expect(find.textContaining('garantido'), findsNothing);
  });

  testWidgets('PrestadorServiceTaxonomySelector encontra artes marciais', (
    WidgetTester tester,
  ) async {
    var selected = <String>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrestadorServiceTaxonomySelector(
              selectedSubcategoryIds: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_service_taxonomy_query_field')),
      'professor de karate',
    );
    await tester.pumpAndSettle();

    expect(find.text('Artes marciais'), findsOneWidget);
    expect(find.textContaining('Educacao'), findsWidgets);

    await tester.tap(find.text('Artes marciais').first);
    await tester.pumpAndSettle();

    expect(selected, contains('martial_arts'));
  });

  testWidgets('PrestadorServiceTaxonomySelector encontra consultoria de imagem',
      (
    WidgetTester tester,
  ) async {
    var selected = <String>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrestadorServiceTaxonomySelector(
              selectedSubcategoryIds: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_service_taxonomy_query_field')),
      'consultora de imagem',
    );
    await tester.pumpAndSettle();

    expect(find.text('Consultoria de imagem'), findsOneWidget);
    expect(find.textContaining('Beleza e bem-estar'), findsWidgets);

    await tester.tap(find.text('Consultoria de imagem').first);
    await tester.pumpAndSettle();

    expect(selected, contains('image_consulting'));
  });

  testWidgets('PrestadorServiceTaxonomySelector permite servico personalizado',
      (
    WidgetTester tester,
  ) async {
    var selected = <String>{};
    var customServices = <ProviderCustomService>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrestadorServiceTaxonomySelector(
              selectedSubcategoryIds: selected,
              onChanged: (value) => selected = value,
              customServices: customServices,
              onCustomServicesChanged: (value) => customServices = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_service_taxonomy_query_field')),
      'zzzxqo qqqyyy',
    );
    await tester.pumpAndSettle();

    expect(find.text('Outro servico'), findsOneWidget);
    expect(find.text('Adicionar servico personalizado'), findsOneWidget);
    expect(find.text('zzzxqo qqqyyy'), findsWidgets);
    expect(
      find.textContaining('Guarda o nome real do servico'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('custom_service_description_field')),
      'Leitura simbolica, orientacao espiritual e mapas pessoais.',
    );
    final addButton = find.byKey(const Key('add_custom_service_button'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(customServices, hasLength(1));
    expect(customServices.single.id, 'custom_zzzxqo_qqqyyy');
    expect(customServices.single.name, 'zzzxqo qqqyyy');
    expect(customServices.single.description, contains('mapas pessoais'));
    expect(selected, contains('custom_zzzxqo_qqqyyy'));
    expect(find.text('zzzxqo qqqyyy'), findsNothing);
  });

  testWidgets('PrestadorServiceTaxonomySelector mostra servicos personalizados',
      (
    WidgetTester tester,
  ) async {
    var selected = {'custom_consultora_de_imagem'};
    var customServices = const [
      ProviderCustomService(
        id: 'custom_consultora_de_imagem',
        name: 'Consultora de imagem',
        description: 'Estilo pessoal e guarda-roupa.',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrestadorServiceTaxonomySelector(
              selectedSubcategoryIds: selected,
              onChanged: (value) => selected = value,
              customServices: customServices,
              onCustomServicesChanged: (value) => customServices = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Servicos personalizados'), findsOneWidget);
    expect(find.text('Consultora de imagem'), findsOneWidget);
    expect(find.text('Estilo pessoal e guarda-roupa.'), findsOneWidget);

    final removeButton = find
        .byKey(const Key('remove_custom_service_custom_consultora_de_imagem'));
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pumpAndSettle();

    expect(customServices, isEmpty);
    expect(selected, isNot(contains('custom_consultora_de_imagem')));
  });
}
