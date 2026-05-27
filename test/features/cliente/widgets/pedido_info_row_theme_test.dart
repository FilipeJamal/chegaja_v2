import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/cliente/widgets/pedido_info_row.dart';

void main() {
  testWidgets('PedidoInfoRow uses theme colors in dark mode', (tester) async {
    final theme = ThemeData.dark();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: PedidoInfoRow(label: 'Estado', value: 'Prestador encontrado'),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Estado'));
    final value = tester.widget<Text>(find.text('Prestador encontrado'));

    expect(label.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(value.style?.color, theme.colorScheme.onSurface);
  });
}
