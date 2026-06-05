import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/provider_custom_service.dart';
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
    expect(find.text('Descreve o teu serviço'), findsOneWidget);
    expect(find.text('Como os clientes costumam procurar?'), findsOneWidget);
    expect(find.text('zzzxqo qqqyyy'), findsWidgets);
    expect(
      find.textContaining('Este serviço ficará associado ao teu perfil'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('custom_service_description_field')),
      'Leitura simbolica, orientacao espiritual e mapas pessoais.',
    );
    await tester.enterText(
      find.byKey(const Key('custom_service_aliases_field')),
      'mapas, orientacao espiritual',
    );
    final addButton = find.byKey(const Key('add_custom_service_button'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(customServices, hasLength(1));
    expect(customServices.single.id, 'custom_zzzxqo_qqqyyy');
    expect(customServices.single.name, 'zzzxqo qqqyyy');
    expect(customServices.single.description, contains('mapas pessoais'));
    expect(customServices.single.aliases, contains('mapas'));
    expect(selected, contains('custom_zzzxqo_qqqyyy'));
    expect(find.text('zzzxqo qqqyyy'), findsNothing);
  });

  testWidgets('PrestadorServiceTaxonomySelector abre formulario ao tocar Outro',
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

    await tester.tap(find.text('Outros'));
    await tester.pumpAndSettle();
    final otherTile =
        find.byKey(const Key('prestador_subcategory_other_service'));
    await tester.ensureVisible(otherTile);
    await tester.tap(otherTile);
    await tester.pumpAndSettle();

    expect(selected, isNot(contains('other_service')));
    expect(find.text('Descreve o teu serviço'), findsOneWidget);
    expect(find.byKey(const Key('custom_service_name_field')), findsOneWidget);
    expect(find.text('Adicionar serviço personalizado'), findsOneWidget);
  });

  testWidgets('PrestadorServiceTaxonomySelector bloqueia servico proibido', (
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
      'servicos sexuais',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('custom_service_description_field')),
      'Atendimento privado',
    );
    final addButton = find.byKey(const Key('add_custom_service_button'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(customServices, isEmpty);
    expect(selected, isEmpty);
    expect(
      find.text('Este tipo de serviço não é permitido no ChegaJá.'),
      findsOneWidget,
    );
    expect(find.textContaining('sexuais'), findsNothing);
  });

  testWidgets('PrestadorServiceTaxonomySelector bloqueia prostituta', (
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
      'prostituta',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('custom_service_description_field')),
      'trabalho com o corpo',
    );
    final addButton = find.byKey(const Key('add_custom_service_button'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(customServices, isEmpty);
    expect(selected, isEmpty);
    expect(find.textContaining('permitido no ChegaJ'), findsOneWidget);
    expect(find.textContaining('prostituta'), findsNothing);
  });

  testWidgets('PrestadorServiceTaxonomySelector bloqueia puta e vadia', (
    WidgetTester tester,
  ) async {
    for (final term in const ['p.u.t.a', 'vadia']) {
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
        term,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('custom_service_description_field')),
        'Descricao profissional qualquer.',
      );
      final addButton = find.byKey(const Key('add_custom_service_button'));
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(customServices, isEmpty, reason: term);
      expect(selected, isEmpty, reason: term);
      expect(find.textContaining('permitido no ChegaJ'), findsOneWidget);
      expect(find.textContaining(term), findsNothing);
    }
  });

  testWidgets('PrestadorServiceTaxonomySelector bloqueia alias proibido', (
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
      'zzzyyy alias limpo',
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('custom_service_description_field')),
      'Descricao profissional qualquer.',
    );
    await tester.enterText(
      find.byKey(const Key('custom_service_aliases_field')),
      'moda, p-u-t-a',
    );
    final addButton = find.byKey(const Key('add_custom_service_button'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(customServices, isEmpty);
    expect(selected, isEmpty);
    expect(find.textContaining('permitido no ChegaJ'), findsOneWidget);
    expect(find.textContaining('p-u-t-a'), findsNothing);
  });

  testWidgets('PrestadorServiceTaxonomySelector bloqueia servicos ilicitos', (
    WidgetTester tester,
  ) async {
    for (final term in const [
      'burlador',
      'burlas',
      'assassino',
      'pedofilia',
      'vender droga',
      'documento falso',
    ]) {
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
        term,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('custom_service_description_field')),
        'Descricao profissional qualquer.',
      );
      final addButton = find.byKey(const Key('add_custom_service_button'));
      await tester.ensureVisible(addButton);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(customServices, isEmpty, reason: term);
      expect(selected, isEmpty, reason: term);
      expect(find.textContaining('permitido no ChegaJ'), findsOneWidget);
      expect(find.textContaining(term), findsNothing);
    }
  });

  testWidgets(
      'PrestadorServiceTaxonomySelector manda servico vago para analise', (
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
      'servico especial',
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('custom_service_description_field')),
      'coisa discreta',
    );
    final addButton = find.byKey(const Key('add_custom_service_button'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(customServices, isEmpty);
    expect(selected, isEmpty);
    expect(find.textContaining('precisa de an'), findsOneWidget);
    expect(find.textContaining('servico especial'), findsNothing);
  });

  testWidgets('PrestadorServiceTaxonomySelector mostra servicos personalizados',
      (
    WidgetTester tester,
  ) async {
    var selected = {'custom_consultora_de_imagem'};
    var customServices = const [
      ProviderCustomService(
        id: 'custom_consultora_de_imagem',
        title: 'Consultora de imagem',
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
