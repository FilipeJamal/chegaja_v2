import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_metric_tile.dart';
import 'package:chegaja_v2/core/widgets/app_section_header.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('visual foundation components', () {
    testWidgets('AppSectionHeader renders title, subtitle and trailing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSectionHeader(
              title: 'Pedidos ativos',
              subtitle: 'Acompanha os trabalhos em curso',
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Ver todos'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pedidos ativos'), findsOneWidget);
      expect(find.text('Acompanha os trabalhos em curso'), findsOneWidget);
      expect(find.text('Ver todos'), findsOneWidget);
    });

    testWidgets('AppStatusPill renders icon and label by tone', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppStatusPill(
              label: 'Em andamento',
              tone: AppStatusTone.success,
              icon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      expect(find.text('Em andamento'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('AppMetricTile renders value and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppMetricTile(
              label: 'Pedidos ativos',
              value: '3',
              supportingText: 'Hoje',
              icon: Icons.work_outline,
              tone: AppStatusTone.info,
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Pedidos ativos'), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
    });

    testWidgets('AppActionPanel renders action buttons', (tester) async {
      var primaryPressed = false;
      var secondaryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppActionPanel(
              title: 'Proxima acao',
              message: 'Envia uma estimativa para o cliente decidir.',
              icon: Icons.payments_outlined,
              tone: AppStatusTone.warning,
              primaryAction: AppActionPanelAction(
                label: 'Enviar estimativa',
                icon: Icons.send_outlined,
                onPressed: () => primaryPressed = true,
              ),
              secondaryAction: AppActionPanelAction(
                label: 'Cancelar',
                onPressed: () => secondaryPressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Proxima acao'), findsOneWidget);
      expect(
        find.text('Envia uma estimativa para o cliente decidir.'),
        findsOneWidget,
      );
      expect(find.text('Enviar estimativa'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      await tester.tap(find.text('Enviar estimativa'));
      await tester.pump();
      expect(primaryPressed, isTrue);

      await tester.tap(find.text('Cancelar'));
      await tester.pump();
      expect(secondaryPressed, isTrue);
    });
  });
}
