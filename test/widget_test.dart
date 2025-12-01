import 'package:flutter_test/flutter_test.dart';
import 'package:chegaja_v2/app.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('ChegaJá inicializa sem erros', (WidgetTester tester) async {
    // Constrói o widget principal da app.
    await tester.pumpWidget(const ChegaJaApp());

    // Verifica se algum texto básico existe na árvore de widgets.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
