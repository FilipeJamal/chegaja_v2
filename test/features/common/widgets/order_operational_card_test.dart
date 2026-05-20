import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/common/widgets/order_operational_card.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('OrderOperationalCard', () {
    testWidgets('renderiza titulo, servico e status', (tester) async {
      await tester.pumpWidget(
        wrap(
          OrderOperationalCard(
            title: 'Trocar tomada',
            subtitle: 'Eletricista',
            statusLabel: 'Em andamento',
            statusTone: AppStatusTone.info,
            leadingIcon: Icons.electrical_services_outlined,
          ),
        ),
      );

      expect(find.text('Trocar tomada'), findsOneWidget);
      expect(find.text('Eletricista'), findsOneWidget);
      expect(find.text('Em andamento'), findsOneWidget);
      expect(find.byType(AppStatusPill), findsWidgets);
    });

    testWidgets('renderiza CTA principal e chama callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          OrderOperationalCard(
            title: 'Canalizacao',
            subtitle: 'Canalizador',
            statusLabel: 'Novo pedido',
            primaryActionLabel: 'Aceitar',
            onPrimaryPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Aceitar'), findsOneWidget);

      await tester.tap(find.text('Aceitar'));
      expect(tapped, isTrue);
    });

    testWidgets('renderiza acao secundaria', (tester) async {
      var ignored = false;

      await tester.pumpWidget(
        wrap(
          OrderOperationalCard(
            title: 'Limpeza',
            subtitle: 'Servico imediato',
            statusLabel: 'Disponivel',
            secondaryActions: [
              OrderOperationalAction(
                label: 'Ignorar',
                onPressed: () => ignored = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Ignorar'), findsOneWidget);

      await tester.tap(find.text('Ignorar'));
      expect(ignored, isTrue);
    });

    testWidgets('funciona sem avatar ou imagem', (tester) async {
      await tester.pumpWidget(
        wrap(
          const OrderOperationalCard(
            title: 'Pedido sem foto',
            subtitle: 'Categoria',
            statusLabel: 'Pendente',
          ),
        ),
      );

      expect(find.text('Pedido sem foto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('suporta valor, local e horario', (tester) async {
      await tester.pumpWidget(
        wrap(
          const OrderOperationalCard(
            title: 'Instalacao de torneira',
            subtitle: 'Hidraulica',
            statusLabel: 'A procurar prestador',
            locationLabel: 'Rua da Liberdade, Coimbra',
            timeLabel: 'ETA ate 30 min',
            valueLabel: 'EUR 35 - 60',
          ),
        ),
      );

      expect(find.text('Rua da Liberdade, Coimbra'), findsOneWidget);
      expect(find.text('ETA ate 30 min'), findsOneWidget);
      expect(find.text('EUR 35 - 60'), findsOneWidget);
    });
  });
}
