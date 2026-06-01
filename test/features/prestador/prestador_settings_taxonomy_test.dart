import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('PrestadorServiceTaxonomySelector oferece Outros sem match', (
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
      'servico muito especifico que nao existe',
    );
    await tester.pumpAndSettle();

    expect(find.text('Outro servico'), findsOneWidget);
    expect(find.textContaining('descreve esse servico'), findsOneWidget);

    await tester.tap(find.text('Outro servico').first);
    await tester.pumpAndSettle();

    expect(selected, contains('other_service'));
  });
}
