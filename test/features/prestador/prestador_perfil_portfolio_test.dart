import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_portfolio_manager_section.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('mostra estado vazio e contador recomendado', (tester) async {
    var addCalled = false;

    await tester.pumpWidget(
      _wrap(
        PrestadorPortfolioManagerSection(
          urls: const [],
          uploading: false,
          onAdd: () => addCalled = true,
          onPreview: (_, __) {},
          onRemoveConfirmed: (_) async {},
        ),
      ),
    );

    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('0/12 imagens recomendadas'), findsOneWidget);
    expect(
      find.text(
        'Adiciona fotos de trabalhos anteriores para ajudar o Cliente a confiar no teu serviço.',
      ),
      findsOneWidget,
    );
    expect(find.text('Fotos nitidas'), findsOneWidget);
    expect(find.text('Antes/depois'), findsOneWidget);
    expect(find.text('Trabalhos reais'), findsOneWidget);

    await tester.tap(find.text('Adicionar imagens'));
    expect(addCalled, isTrue);
  });

  testWidgets('mostra imagens existentes e abre preview', (tester) async {
    final previewed = <String>[];

    await tester.pumpWidget(
      _wrap(
        PrestadorPortfolioManagerSection(
          urls: const [
            'https://example.invalid/a.jpg',
            'https://example.invalid/b.jpg',
          ],
          uploading: false,
          onAdd: () {},
          onPreview: (url, index) => previewed.add('$index:$url'),
          onRemoveConfirmed: (_) async {},
        ),
      ),
    );

    expect(find.text('2/12 imagens recomendadas'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));

    await tester.tap(find.byTooltip('Ver imagem').first);
    expect(previewed, ['0:https://example.invalid/a.jpg']);
  });

  testWidgets('botao de upload fica bloqueado durante carregamento',
      (tester) async {
    var addCount = 0;

    await tester.pumpWidget(
      _wrap(
        PrestadorPortfolioManagerSection(
          urls: const [],
          uploading: true,
          onAdd: () => addCount++,
          onPreview: (_, __) {},
          onRemoveConfirmed: (_) async {},
        ),
      ),
    );

    expect(find.text('A carregar...'), findsOneWidget);
    await tester.tap(find.text('A carregar...'));
    expect(addCount, 0);
  });

  testWidgets('remocao pede confirmacao antes de chamar callback',
      (tester) async {
    final removed = <String>[];

    await tester.pumpWidget(
      _wrap(
        PrestadorPortfolioManagerSection(
          urls: const ['https://example.invalid/a.jpg'],
          uploading: false,
          onAdd: () {},
          onPreview: (_, __) {},
          onRemoveConfirmed: (url) async => removed.add(url),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Remover imagem'));
    await tester.pumpAndSettle();

    expect(find.text('Remover imagem?'), findsOneWidget);
    expect(
      find.text(
        'Esta imagem será removida do teu portfólio. Esta ação não pode ser desfeita.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(removed, isEmpty);

    await tester.tap(find.byTooltip('Remover imagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(removed, ['https://example.invalid/a.jpg']);
  });

  testWidgets('dark mode usa cores do tema no bloco principal', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorPortfolioManagerSection(
          urls: const [],
          uploading: false,
          onAdd: () {},
          onPreview: (_, __) {},
          onRemoveConfirmed: (_) async {},
        ),
        theme: AppTheme.darkTheme,
      ),
    );

    final title = tester.widget<Text>(find.text('Portfolio'));
    final emptyTitle = tester.widget<Text>(
      find.text('Mostra o teu trabalho com fotos reais'),
    );

    expect(title.style?.color, AppTheme.darkTheme.colorScheme.onSurface);
    expect(emptyTitle.style?.color, AppTheme.darkTheme.colorScheme.onSurface);
  });

  testWidgets('layout aguenta varias imagens sem overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        PrestadorPortfolioManagerSection(
          urls: List.generate(
            8,
            (index) => 'https://example.invalid/$index.jpg',
          ),
          uploading: false,
          onAdd: () {},
          onPreview: (_, __) {},
          onRemoveConfirmed: (_) async {},
        ),
      ),
    );

    expect(find.text('8/12 imagens recomendadas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
