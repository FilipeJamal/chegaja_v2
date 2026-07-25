import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(
        rootBundle.load('assets/fonts/inter/Inter-Variable.ttf'),
      );
    await inter.load();
  });

  group('ClienteLegacyHomeHero', () {
    testWidgets('preserva a superficie anterior quando a U1 esta desligada',
        (tester) async {
      var primaryTapped = false;
      var searchTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteLegacyHomeHero(
              greeting: 'Ola, Filipe',
              title: 'Encontra o servico certo',
              subtitle: 'Escolhe uma categoria e acompanha o pedido.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () => primaryTapped = true,
              onSearch: () => searchTapped = true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('cliente_home_legacy_hero')),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      expect(
        find.byKey(const Key('cliente_home_mode_selector')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const Key('cliente_home_legacy_primary_cta')),
      );
      await tester.tap(
        find.byKey(const Key('cliente_home_legacy_provider_search_cta')),
      );

      expect(primaryTapped, isTrue);
      expect(searchTapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('ClienteHomeHero', () {
    testWidgets('mostra promessa operacional e CTA principal', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.u1LightTheme,
          home: Scaffold(
            body: ClienteHomeHero(
              greeting: 'Ola, Filipe',
              title: 'Que servico precisas?',
              subtitle: 'Escolhe um servico e acompanha tudo num unico lugar.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () => tapped = true,
              onSearch: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('cliente_home_hero')), findsOneWidget);
      expect(find.text('Que servico precisas?'), findsOneWidget);
      expect(find.byKey(const Key('cliente_home_primary_cta')), findsOneWidget);

      await tester.tap(find.byKey(const Key('cliente_home_primary_cta')));
      expect(tapped, isTrue);
    });

    testWidgets('mantem CTA visivel em largura mobile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteHomeHero(
              greeting: 'Ola',
              title: 'Que servico precisas?',
              subtitle: 'Escolhe um servico e acompanha tudo num unico lugar.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () {},
              onSearch: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('cliente_home_primary_cta')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mantem a pergunta principal em duas linhas no mobile', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const title = 'De que serviço precisa?';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.u1LightTheme,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ClienteHomeHero(
                    title: title,
                    subtitle:
                        'Encontre prestadores de confiança perto de si e resolva já.',
                    locationLabel: 'Coimbra',
                    primaryActionLabel: 'Continuar',
                    onPrimaryAction: () {},
                    onSearch: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: title.length),
      );
      final lineTops = boxes.map((box) => box.top.round()).toSet();

      expect(
        lineTops,
        hasLength(2),
        reason:
            'hero=${tester.getSize(find.byKey(const Key('cliente_home_hero')))}; '
            'illustration=${tester.getSize(find.byKey(const Key('cliente_home_hero_illustration')))}; '
            'paragraph=${paragraph.size}; '
            'text=${paragraph.text.toPlainText()}; boxes=$boxes',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('botao de pesquisa chama callback dedicado', (tester) async {
      var searched = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteHomeHero(
              greeting: 'Ola',
              title: 'Que servico precisas?',
              subtitle: 'Escolhe um servico e acompanha tudo num unico lugar.',
              primaryActionLabel: 'Escolher servico',
              onPrimaryAction: () {},
              onSearch: () => searched = true,
            ),
          ),
        ),
      );

      await tester
          .tap(find.byKey(const Key('cliente_home_provider_search_cta')));

      expect(searched, isTrue);
    });
  });

  group('ClienteServiceModeSelector', () {
    testWidgets('mostra Orçamentos por inteiro no viewport mobile', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 316,
                child: ClienteServiceModeSelector(
                  selectedMode: 'IMEDIATO',
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      final nowRect = tester.getRect(
        find.byKey(const Key('cliente_home_mode_imediato')),
      );
      final quotesRect = tester.getRect(
        find.byKey(const Key('cliente_home_mode_orcamento')),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Orçamentos'),
      );
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 10),
      );

      expect(quotesRect.width, greaterThan(nowRect.width));
      expect(boxes, isNotEmpty);
      expect(
        boxes.map((box) => box.right).reduce((a, b) => a > b ? a : b),
        lessThanOrEqualTo(paragraph.size.width + 0.1),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ClienteServiceTile', () {
    testWidgets('mostra nome, modo e key estavel por servico', (tester) async {
      var tapped = false;
      const servico = Servico(
        id: 'canalizador-1',
        name: 'Canalizador',
        mode: 'IMEDIATO',
        keywords: ['agua', 'cano'],
        iconKey: 'canalizador',
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteServiceTile(
              servico: servico,
              localeCode: 'pt',
              modeLabel: 'Imediato',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('cliente_home_service_tile_canalizador-1')),
        findsOneWidget,
      );
      expect(find.text('Canalizador'), findsOneWidget);
      expect(find.text('Imediato'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('cliente_home_service_tile_canalizador-1')),
      );
      expect(tapped, isTrue);
    });

    test('usa icones e acentos distintos por categoria', () {
      expect(clienteServiceIconFor('bolo personalizado'), Icons.cake_rounded);
      expect(clienteServiceIconFor('carpinteiro'), Icons.carpenter_rounded);
      expect(
        clienteServiceIconFor('canalizacao'),
        Icons.plumbing_rounded,
      );

      expect(
        clienteServiceAccentFor('limpeza'),
        isNot(clienteServiceAccentFor('eletricista')),
      );
      expect(
        clienteServiceAccentFor('bolo personalizado'),
        isNot(clienteServiceAccentFor('canalizacao')),
      );
      expect(
        clienteServiceAssetFor('bolo personalizado'),
        'assets/icons/services/service_cake.svg',
      );
      expect(
        clienteServiceAssetFor('carpinteiro'),
        'assets/icons/services/service_carpentry.svg',
      );
      expect(
        clienteServiceAssetFor('retratista a lápis'),
        'assets/icons/services/service_portrait.svg',
      );
      expect(
        clienteServiceAssetFor('pedreiro'),
        'assets/icons/services/service_masonry.svg',
      );
      expect(
        clienteServiceAssetFor('ilustrador'),
        'assets/icons/services/service_illustration.svg',
      );
    });
  });

  group('ClienteQuickServicesStrip', () {
    testWidgets('mantem titulo e acao na mesma linha no mobile', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const title = 'Serviços perto de si';
      const services = <Servico>[
        Servico(
          id: 'canalizador',
          name: 'Canalizador',
          mode: 'IMEDIATO',
          keywords: ['agua'],
          isActive: true,
        ),
        Servico(
          id: 'eletricista',
          name: 'Eletricista',
          mode: 'IMEDIATO',
          keywords: ['luz'],
          isActive: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.u1LightTheme,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ClienteQuickServicesStrip(
                    title: title,
                    services: services,
                    localeCode: 'pt',
                    onSelect: (_) {},
                    onSeeAll: () {},
                    seeAllLabel: 'Ver todos',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
      final boxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: title.length),
      );
      final lineTops = boxes.map((box) => box.top.round()).toSet();

      expect(
        lineTops,
        hasLength(1),
        reason: 'paragraph=${paragraph.size}; boxes=$boxes',
      );
      expect(find.text('Ver todos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ClienteServicesLoadingPreview', () {
    testWidgets('mantem categorias uteis enquanto catalogo carrega',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClienteServicesLoadingPreview(),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('cliente_home_services_section')),
        findsOneWidget,
      );
      expect(find.text('Servicos disponiveis'), findsOneWidget);
      expect(find.text('Canalizacao'), findsOneWidget);
      expect(find.text('Limpeza'), findsOneWidget);
      expect(find.text('Eletricista'), findsOneWidget);
      expect(find.text('A carregar'), findsWidgets);
    });
  });

  group('ClienteHomeOperationsPanel', () {
    testWidgets('mostra acao pendente com CTA', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClienteHomeOperationsPanel(
              title: 'Tens algo para decidir',
              message: 'Uma proposta aguarda a tua resposta.',
              actionLabel: 'Ver pedido',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('cliente_home_operations_panel')),
        findsOneWidget,
      );
      expect(find.text('Tens algo para decidir'), findsOneWidget);

      await tester.tap(find.text('Ver pedido'));
      expect(tapped, isTrue);
    });
  });

  group('ClienteHomeEmptyServices', () {
    testWidgets('orienta primeira acao sem parecer erro tecnico',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClienteHomeEmptyServices(),
          ),
        ),
      );

      expect(
        find.text('Ainda estamos a preparar servicos para ti.'),
        findsOneWidget,
      );
      expect(
        find.text('Tenta novamente daqui a pouco ou ajusta a pesquisa.'),
        findsOneWidget,
      );
    });
  });
}
