import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_detail_components.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Pedido buildPedido({
  String estado = 'aceito',
  String statusConfirmacaoValor = 'nenhum',
  double? precoPropostoPrestador,
  double? precoFinal,
  double? valorMinEstimadoPrestador,
  double? valorMaxEstimadoPrestador,
}) {
  return Pedido(
    id: 'pedido_42',
    clienteId: 'cliente_1',
    prestadorId: 'prestador_1',
    servicoId: 'srv_eletricista',
    servicoNome: 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida perto da cozinha',
    modo: 'IMEDIATO',
    status: estado,
    tipoPreco: 'por_orcamento',
    tipoPagamento: 'dinheiro',
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: statusConfirmacaoValor,
    precoPropostoPrestador: precoPropostoPrestador,
    precoFinal: precoFinal,
    valorMinEstimadoPrestador: valorMinEstimadoPrestador,
    valorMaxEstimadoPrestador: valorMaxEstimadoPrestador,
    createdAt: DateTime(2026, 5, 19),
  );
}

Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('PedidoDetailLayout', () {
    testWidgets('usa uma coluna em mobile', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          PedidoDetailLayout(
            mainColumn: const SizedBox(
              key: Key('main-content'),
              height: 80,
              child: Text('Main'),
            ),
            sidePanel: const SizedBox(
              key: Key('side-content'),
              height: 80,
              child: Text('Side'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('pedido_detail_layout')), findsOneWidget);
      final mainTop = tester.getTopLeft(find.byKey(const Key('main-content')));
      final sideTop = tester.getTopLeft(find.byKey(const Key('side-content')));
      expect(sideTop.dy, lessThan(mainTop.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('usa duas colunas em desktop', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          PedidoDetailLayout(
            mainColumn: const SizedBox(
              key: Key('main-content'),
              height: 80,
              child: Text('Main'),
            ),
            sidePanel: const SizedBox(
              key: Key('side-content'),
              height: 80,
              child: Text('Side'),
            ),
          ),
        ),
      );

      final mainTop = tester.getTopLeft(find.byKey(const Key('main-content')));
      final sideTop = tester.getTopLeft(find.byKey(const Key('side-content')));
      expect(sideTop.dx, greaterThan(mainTop.dx));
      expect((sideTop.dy - mainTop.dy).abs(), lessThan(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('PedidoValueSummary', () {
    testWidgets('mostra faixa estimada como valor nao final', (tester) async {
      await tester.pumpWidget(
        wrap(
          PedidoValueSummary(
            pedido: buildPedido(
              valorMinEstimadoPrestador: 20,
              valorMaxEstimadoPrestador: 35,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('pedido_value_summary')), findsOneWidget);
      expect(find.text('Faixa estimada'), findsOneWidget);
      expect(find.textContaining('Nao e o valor final'), findsOneWidget);
    });

    testWidgets('mostra valor final pendente', (tester) async {
      await tester.pumpWidget(
        wrap(
          PedidoValueSummary(
            pedido: buildPedido(
              estado: 'aguarda_confirmacao_valor',
              statusConfirmacaoValor: 'pendente_cliente',
              precoPropostoPrestador: 85,
            ),
          ),
        ),
      );

      expect(find.text('Valor final pendente'), findsOneWidget);
      expect(find.textContaining('85'), findsOneWidget);
    });
  });

  group('PedidoDetailSidePanel', () {
    testWidgets('mostra status, proxima acao e valor', (tester) async {
      final pedido = buildPedido(precoPropostoPrestador: 80);
      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      await tester.pumpWidget(
        wrap(
          PedidoDetailSidePanel(
            pedido: pedido,
            summary: summary,
            nextAction: nextAction,
            actions: const SizedBox(
              key: Key('actions-slot'),
              child: Text('Acoes'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('pedido_detail_side_panel')), findsOneWidget);
      expect(find.byKey(const Key('pedido_value_summary')), findsOneWidget);
      expect(find.byKey(const Key('actions-slot')), findsOneWidget);
      expect(find.text('Acoes'), findsOneWidget);
    });
  });
}
