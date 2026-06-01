import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/catalog/service_intent.dart';
import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/features/cliente/widgets/service_taxonomy_picker_section.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

void main() {
  testWidgets('NovoPedidoScreen mostra escolha profissional de servico', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NovoPedidoScreen(
          modo: 'IMEDIATO',
          servicosLoader: () async => const [],
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1. Serviço'), findsOneWidget);
    expect(find.text('2. Quando e como?'), findsOneWidget);
    expect(find.text('3. Detalhes'), findsOneWidget);
    expect(find.text('Que servico precisas?'), findsOneWidget);
    expect(find.text('Escolhe uma categoria'), findsOneWidget);
    expect(find.text('Casa e reparacoes'), findsOneWidget);
    expect(find.text('Limpeza e manutencao'), findsOneWidget);
  });

  testWidgets('ServiceTaxonomyPickerSection sugere por linguagem natural', (
    WidgetTester tester,
  ) async {
    ServiceTaxonomySelection? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ServiceTaxonomyPickerSection(
              value: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('service_taxonomy_query_field')),
      'arranjar luz',
    );
    await tester.pumpAndSettle();

    expect(find.text('Eletricidade'), findsWidgets);

    await tester.tap(find.text('Eletricidade').first);
    await tester.pumpAndSettle();

    expect(selected?.subcategory.id, 'electricity');
    expect(selected?.intent, ServiceIntent.now);
    expect(find.text('Quando precisas?'), findsOneWidget);
    expect(find.text('Preciso agora'), findsOneWidget);
    expect(find.text('Quero agendar'), findsOneWidget);
    expect(find.text('Quero receber orcamento'), findsOneWidget);
    expect(
      find.text('Este servico exige prestador com aprovacao na categoria.'),
      findsOneWidget,
    );
  });

  testWidgets('ServiceTaxonomyPickerSection altera intent para orcamento', (
    WidgetTester tester,
  ) async {
    ServiceTaxonomySelection? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ServiceTaxonomyPickerSection(
              value: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('service_taxonomy_query_field')),
      'bolo aniversario',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bolos e confeitaria').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Quero receber orcamento').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quero receber orcamento').first);
    await tester.pumpAndSettle();

    expect(selected?.subcategory.id, 'cakes_confectionery');
    expect(selected?.intent, ServiceIntent.quote);
    expect(selected?.legacyMode, 'POR_PROPOSTA');
  });

  testWidgets('ServiceTaxonomyPickerSection oferece Outros quando nao encontra',
      (
    WidgetTester tester,
  ) async {
    ServiceTaxonomySelection? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ServiceTaxonomyPickerSection(
              value: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('service_taxonomy_query_field')),
      'servico muito especifico que nao existe',
    );
    await tester.pumpAndSettle();

    expect(find.text('Outro servico'), findsWidgets);
    expect(find.text('Descreve o serviço que precisas'), findsOneWidget);
    expect(find.text('Nome do serviço'), findsOneWidget);
    expect(find.text('Palavras relacionadas'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('client_custom_service_name_field')),
      'servico muito especifico que nao existe',
    );
    await tester.enterText(
      find.byKey(const Key('client_custom_service_description_field')),
      'Preciso de ajuda com uma tarefa fora do catalogo.',
    );
    await tester.tap(find.byKey(const Key('client_custom_service_add_button')));
    await tester.pumpAndSettle();

    expect(selected?.subcategory.id, 'other_service');
    expect(selected?.category.id, 'other');
    expect(
      selected?.customService?.title,
      'servico muito especifico que nao existe',
    );
    expect(
      selected?.servicoId,
      'custom_servico_muito_especifico_que_nao_existe',
    );
    expect(selected?.servicoNome, 'servico muito especifico que nao existe');
  });

  testWidgets('ServiceTaxonomyPickerSection bloqueia Outro proibido', (
    WidgetTester tester,
  ) async {
    ServiceTaxonomySelection? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ServiceTaxonomyPickerSection(
              value: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('service_taxonomy_query_field')),
      'servicos sexuais',
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('client_custom_service_description_field')),
      'Atendimento privado',
    );
    await tester.tap(find.byKey(const Key('client_custom_service_add_button')));
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(
      find.text('Este tipo de serviço não é permitido no ChegaJá.'),
      findsOneWidget,
    );
    expect(find.textContaining('sexuais'), findsNothing);
  });
}
