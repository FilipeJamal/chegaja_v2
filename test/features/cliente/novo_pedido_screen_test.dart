import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/features/cliente/novo_pedido_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

void main() {
  testWidgets('NovoPedidoScreen alterna manual/automatico', (
    WidgetTester tester,
  ) async {
    final servicos = [
      const Servico(
        id: 's1',
        name: 'Canalizador',
        mode: 'IMEDIATO',
        keywords: ['agua'],
        iconKey: null,
        isActive: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NovoPedidoScreen(
          modo: 'IMEDIATO',
          servicosLoader: () async => servicos,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Encontrar prestador'), findsOneWidget);
    expect(
      find.text('Vamos procurar um prestador automaticamente.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Manual').first);
    await tester.pumpAndSettle();

    expect(find.text('Nenhum prestador selecionado.'), findsOneWidget);
    expect(find.text('Pesquisar prestadores'), findsOneWidget);

    await tester.tap(find.text('Automatico').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Vamos procurar um prestador automaticamente.'),
      findsOneWidget,
    );
  });
}
