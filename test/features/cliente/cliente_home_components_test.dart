import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('ClienteServiceModeSelector U1', () {
    testWidgets('maps Agora, Agendar and Orçamentos to canonical modes',
        (tester) async {
      final selectedModes = <String>[];

      await tester.pumpWidget(
        _wrap(
          ClienteServiceModeSelector(
            selectedMode: 'IMEDIATO',
            onChanged: selectedModes.add,
          ),
        ),
      );

      expect(find.text('Agora'), findsOneWidget);
      expect(find.text('Agendar'), findsOneWidget);
      expect(find.text('Orçamentos'), findsOneWidget);

      await tester.tap(find.text('Agora'));
      await tester.tap(find.text('Agendar'));
      await tester.tap(find.text('Orçamentos'));
      await tester.pump();

      expect(selectedModes, ['IMEDIATO', 'AGENDADO', 'ORCAMENTO']);
    });

    testWidgets(
        'exposes selected state and disables interaction without callback',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ClienteServiceModeSelector(
            selectedMode: 'AGENDADO',
            onChanged: null,
          ),
        ),
      );

      Semantics semanticsFor(String label) => tester.widget<Semantics>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.label == label,
            ),
          );

      expect(semanticsFor('Agora').properties.selected, isFalse);
      expect(semanticsFor('Agendar').properties.selected, isTrue);
      expect(semanticsFor('Orçamentos').properties.selected, isFalse);
      expect(semanticsFor('Agendar').properties.enabled, isFalse);
    });
  });

  group('ClienteHomeHero U1', () {
    testWidgets('returns the trimmed request description through its CTA',
        (tester) async {
      String? description;

      await tester.pumpWidget(
        _wrap(
          ClienteHomeHero(
            title: 'O que precisas?',
            subtitle: 'Descreve o pedido.',
            onSearch: () {},
            onContinue: (value) => description = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '  Limpeza semanal  ');
      await tester.tap(find.byKey(const Key('cliente_home_primary_cta')));
      await tester.pump();

      expect(description, 'Limpeza semanal');
    });

    testWidgets('reports mode changes without losing the selected contract',
        (tester) async {
      String? mode;

      await tester.pumpWidget(
        _wrap(
          ClienteHomeHero(
            title: 'O que precisas?',
            subtitle: 'Escolhe como queres contratar.',
            selectedMode: 'IMEDIATO',
            onModeChanged: (value) => mode = value,
            onSearch: () {},
          ),
        ),
      );

      await tester.tap(find.text('Agendar'));
      await tester.pump();

      expect(mode, 'AGENDADO');
    });
  });
}
