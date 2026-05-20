import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_final_state_panel.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';

void main() {
  testWidgets('PedidoFinalStatePanel mostra estado concluido', (tester) async {
    const data = PedidoFinalStateData(
      title: 'Pedido concluido',
      message: 'O servico ficou concluido.',
      actionHint: 'Consulta os detalhes sempre que precisares.',
      icon: Icons.check_circle_outline,
      color: Colors.green,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PedidoFinalStatePanel(data: data),
        ),
      ),
    );

    expect(find.text('Pedido concluido'), findsOneWidget);
    expect(find.text('O servico ficou concluido.'), findsOneWidget);
    expect(
      find.text('Consulta os detalhes sempre que precisares.'),
      findsOneWidget,
    );
    expect(find.byType(AppStatusPill), findsOneWidget);
  });

  testWidgets('PedidoFinalStatePanel mostra detalhe de cancelamento', (
    tester,
  ) async {
    const data = PedidoFinalStateData(
      title: 'Pedido cancelado',
      message: 'Este pedido foi cancelado pelo prestador.',
      detail: 'Motivo: Agenda indisponivel',
      actionHint: 'Consulta os detalhes ou cria um novo pedido.',
      icon: Icons.cancel_outlined,
      color: Colors.redAccent,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PedidoFinalStatePanel(data: data),
        ),
      ),
    );

    expect(find.text('Pedido cancelado'), findsOneWidget);
    expect(
      find.text('Este pedido foi cancelado pelo prestador.'),
      findsOneWidget,
    );
    expect(find.text('Motivo: Agenda indisponivel'), findsOneWidget);
  });
}
