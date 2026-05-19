import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

Pedido buildPedido({
  String id = 'pedido_1',
  String estado = 'criado',
  String tipoPreco = 'por_orcamento',
  String tipoPagamento = 'dinheiro',
  String modo = 'IMEDIATO',
  DateTime? agendadoPara,
}) {
  return Pedido(
    id: id,
    clienteId: 'cliente_1',
    prestadorId: null,
    servicoId: 'srv_eletricista',
    servicoNome: 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida perto da cozinha',
    modo: modo,
    status: estado,
    tipoPreco: tipoPreco,
    tipoPagamento: tipoPagamento,
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: 'nenhum',
    dataAgendada: agendadoPara,
    createdAt: DateTime(2026, 5, 19),
  );
}

Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('PrestadorAvailabilityPanel', () {
    testWidgets('mostra estado online e alterna disponibilidade',
        (tester) async {
      bool? toggled;

      await tester.pumpWidget(
        wrap(
          PrestadorAvailabilityPanel(
            online: true,
            onChanged: (value) => toggled = value,
          ),
        ),
      );

      expect(
        find.byKey(const Key('prestador_home_availability_panel')),
        findsOneWidget,
      );
      expect(find.text('Online'), findsOneWidget);
      expect(
        find.text('Pronto para receber pedidos compativeis.'),
        findsOneWidget,
      );

      await tester.tap(find.byType(Switch));
      expect(toggled, isFalse);
    });

    testWidgets('mostra estado offline com orientacao de acao', (tester) async {
      await tester.pumpWidget(
        wrap(
          PrestadorAvailabilityPanel(
            online: false,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Ativa para receber novos pedidos.'), findsOneWidget);
    });
  });

  group('PrestadorMetricStrip', () {
    testWidgets('mostra ganhos e servicos com AppMetricTile', (tester) async {
      await tester.pumpWidget(
        wrap(
          const PrestadorMetricStrip(
            liquidoHoje: 'EUR 85.00',
            brutoHoje: 'EUR 100.00',
            taxaHoje: 'EUR 15.00',
            servicosMes: '4',
          ),
        ),
      );

      expect(
        find.byKey(const Key('prestador_home_metric_strip')),
        findsOneWidget,
      );
      expect(find.text('EUR 85.00'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Bruto: EUR 100.00 | Taxa: EUR 15.00'), findsOneWidget);
    });
  });

  group('PrestadorCategoriesPanel', () {
    testWidgets('mostra categorias e chama edicao', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          PrestadorCategoriesPanel(
            categories: const ['Eletricista', 'Canalizador'],
            loading: false,
            onEdit: () => tapped = true,
          ),
        ),
      );

      expect(
        find.byKey(const Key('prestador_home_categories_panel')),
        findsOneWidget,
      );
      expect(find.text('2 selecionadas'), findsOneWidget);
      expect(find.text('Eletricista'), findsOneWidget);

      await tester.tap(find.text('Editar categorias'));
      expect(tapped, isTrue);
    });

    testWidgets('orienta configuracao quando nao ha categorias',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrestadorCategoriesPanel(
            categories: const <String>[],
            loading: false,
            onEdit: () {},
          ),
        ),
      );

      expect(
        find.text('Seleciona categorias para receber pedidos compativeis.'),
        findsOneWidget,
      );
      expect(find.text('Selecionar categorias'), findsOneWidget);
    });
  });

  group('PrestadorAvailableOrderCard', () {
    testWidgets('preserva keys criticas e chama aceitar/ignorar',
        (tester) async {
      var accepted = false;
      var ignored = false;
      final pedido = buildPedido(id: 'pedido_42');

      await tester.pumpWidget(
        wrap(
          PrestadorAvailableOrderCard(
            pedido: pedido,
            descricao: pedido.descricao,
            agendadoPara: pedido.agendadoPara,
            modo: pedido.modo,
            tipoPrecoLabel: 'Por orcamento',
            tipoPagamentoLabel: 'Pagamento em dinheiro',
            df: DateFormat('dd/MM HH:mm'),
            onAceitar: () => accepted = true,
            onIgnorar: () => ignored = true,
          ),
        ),
      );

      expect(
        find.byKey(const Key('prestador_pedido_card_pedido_42')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('prestador_aceitar_pedido_pedido_42')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('prestador_ignorar_pedido_pedido_42')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('prestador_aceitar_pedido_pedido_42')),
      );
      expect(accepted, isTrue);

      await tester.tap(
        find.byKey(const Key('prestador_ignorar_pedido_pedido_42')),
      );
      expect(ignored, isTrue);
    });

    testWidgets('mantem largura mobile sem overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          PrestadorAvailableOrderCard(
            pedido: buildPedido(id: 'pedido_mobile'),
            descricao: 'Pedido com descricao curta',
            agendadoPara: null,
            modo: 'IMEDIATO',
            tipoPrecoLabel: 'Por orcamento',
            tipoPagamentoLabel: 'Pagamento em dinheiro',
            df: DateFormat('dd/MM HH:mm'),
            onAceitar: () {},
            onIgnorar: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
