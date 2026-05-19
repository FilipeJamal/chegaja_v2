import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/cliente/widgets/pedido_empty_state.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

void main() {
  group('PedidoListCard', () {
    testWidgets('mostra estado, valor e proxima acao', (tester) async {
      var tapped = false;
      const data = PedidoListCardData(
        title: 'Trocar tomada',
        category: 'Eletricista',
        statusLabel: 'Confirma o valor final',
        valueLabel: 'Valor a confirmar: 120,00 EUR',
        actionLabel: 'Confirmar valor final',
        tone: PedidoStatusTone.warning,
        icon: Icons.price_check_rounded,
        hasUserAction: true,
        bucket: PedidoListBucket.ativo,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PedidoListCard(
              data: data,
              metaLabels: const ['Por orcamento', 'Dinheiro'],
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Trocar tomada'), findsOneWidget);
      expect(find.text('Eletricista'), findsOneWidget);
      expect(find.text('Confirma o valor final'), findsOneWidget);
      expect(find.text('Valor a confirmar: 120,00 EUR'), findsOneWidget);
      expect(find.text('Confirmar valor final'), findsOneWidget);
      expect(find.text('Por orcamento'), findsOneWidget);

      await tester.tap(find.byType(PedidoListCard));
      expect(tapped, isTrue);
    });

    testWidgets('mostra empty state humano', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PedidoEmptyState(
              title: 'Sem pedidos ativos',
              message: 'Quando criares um pedido, ele aparece aqui.',
              icon: Icons.inbox_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Sem pedidos ativos'), findsOneWidget);
      expect(
        find.text('Quando criares um pedido, ele aparece aqui.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });
  });
}
