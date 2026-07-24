import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_pedido_acoes.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_pedido_acoes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Pedido buildPedido({
  String estado = 'aguarda_resposta_cliente',
  String tipoPreco = 'por_orcamento',
  String statusProposta = 'pendente_cliente',
  String statusConfirmacaoValor = 'nenhum',
  double? valorMinEstimadoPrestador = 20,
  double? valorMaxEstimadoPrestador = 35,
  double? precoPropostoPrestador,
  double? commissionPlatform,
  double? earningsProvider,
  double? earningsTotal,
}) {
  return Pedido(
    id: 'pedido_actions',
    clienteId: 'cliente_1',
    prestadorId: 'prestador_1',
    servicoId: 'srv_eletricista',
    servicoNome: 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida perto da cozinha',
    modo: 'IMEDIATO',
    status: estado,
    tipoPreco: tipoPreco,
    tipoPagamento: 'dinheiro',
    statusProposta: statusProposta,
    statusConfirmacaoValor: statusConfirmacaoValor,
    valorMinEstimadoPrestador: valorMinEstimadoPrestador,
    valorMaxEstimadoPrestador: valorMaxEstimadoPrestador,
    precoPropostoPrestador: precoPropostoPrestador,
    commissionPlatform: commissionPlatform,
    earningsProvider: earningsProvider,
    earningsTotal: earningsTotal,
    createdAt: DateTime(2026, 5, 19),
  );
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget wrapDark(Widget child) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );

void expectNoHardcodedDarkTextColors(WidgetTester tester) {
  final forbidden = <int>{
    Colors.black.toARGB32(),
    Colors.black87.toARGB32(),
    Colors.black54.toARGB32(),
    Colors.black45.toARGB32(),
    Colors.black38.toARGB32(),
  };

  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final color = widget.style?.color;
    if (color != null) {
      expect(
        forbidden.contains(color.toARGB32()),
        isFalse,
        reason: 'Hardcoded dark text color on "${widget.data}"',
      );
    }
  }
}

void main() {
  testWidgets('ClientePedidoAcoes agrupa proposta em AppActionPanel', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(ClientePedidoAcoes(pedido: buildPedido())));

    expect(find.byType(AppActionPanel), findsOneWidget);
    expect(find.byKey(const Key('cliente_rejeitar_proposta_button')),
        findsOneWidget);
    expect(find.byKey(const Key('cliente_aceitar_proposta_button')),
        findsOneWidget);
  });

  testWidgets('ClientePedidoAcoes agrupa valor final em AppActionPanel', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ClientePedidoAcoes(
          pedido: buildPedido(
            estado: 'aguarda_confirmacao_valor',
            statusProposta: 'aceita_cliente',
            statusConfirmacaoValor: 'pendente_cliente',
            precoPropostoPrestador: 85,
          ),
        ),
      ),
    );

    expect(find.byType(AppActionPanel), findsOneWidget);
    expect(
        find.byKey(const Key('cliente_duvida_valor_button')), findsOneWidget);
    expect(find.byKey(const Key('confirmar_valor_button')), findsOneWidget);
  });

  testWidgets('PrestadorPedidoAcoes agrupa inicio em AppActionPanel', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        PrestadorPedidoAcoes(
          pedido: buildPedido(
            estado: 'aceito',
            tipoPreco: 'a_combinar',
            statusProposta: 'nenhuma',
          ),
        ),
      ),
    );

    expect(find.byType(AppActionPanel), findsOneWidget);
    expect(find.byKey(const Key('prestador_iniciar_servico_button')),
        findsOneWidget);
  });

  testWidgets('acoes Cliente e Prestador evitam texto preto em dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapDark(
        ClientePedidoAcoes(
          pedido: buildPedido(
            estado: 'aguarda_confirmacao_valor',
            statusProposta: 'aceita_cliente',
            statusConfirmacaoValor: 'pendente_cliente',
            precoPropostoPrestador: 85,
          ),
        ),
      ),
    );
    expectNoHardcodedDarkTextColors(tester);

    await tester.pumpWidget(
      wrapDark(
        PrestadorPedidoAcoes(
          pedido: buildPedido(
            estado: 'aguarda_confirmacao_valor',
            tipoPreco: 'a_combinar',
            statusProposta: 'aceita_cliente',
            statusConfirmacaoValor: 'pendente_cliente',
            precoPropostoPrestador: 85,
          ),
        ),
      ),
    );
    expectNoHardcodedDarkTextColors(tester);
  });

  testWidgets('resumo financeiro do prestador usa contraste forte no dark mode',
      (tester) async {
    await tester.pumpWidget(
      wrapDark(
        PrestadorPedidoAcoes(
          pedido: buildPedido(
            estado: 'aguarda_confirmacao_valor',
            tipoPreco: 'a_combinar',
            statusProposta: 'aceita_cliente',
            statusConfirmacaoValor: 'pendente_cliente',
            precoPropostoPrestador: 30,
          ),
        ),
      ),
    );

    final expectedColor = AppTheme.darkTheme.colorScheme.onSurface;

    for (final label in <String>[
      'À espera da confirmação do cliente para o valor final.',
      'Valor bruto',
      'A comissão e o valor líquido exatos serão calculados pelo '
          'ChegaJá quando o cliente confirmar. Os primeiros trabalhos '
          'podem ter isenção segundo a política ativa do piloto.',
    ]) {
      final text = tester.widget<Text>(find.text(label));
      expect(
        text.style?.color?.toARGB32(),
        expectedColor.toARGB32(),
        reason: '$label precisa de contraste principal em dark mode',
      );
    }
    expect(
      find.byKey(const Key('prestador_commission_pending_summary')),
      findsOneWidget,
    );
    expect(find.text('Taxa da plataforma (15%)'), findsNothing);
  });

  testWidgets('resumo concluído mostra apenas valores autoritativos',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        PrestadorPedidoAcoes(
          pedido: buildPedido(
            estado: 'concluido',
            statusProposta: 'aceita_cliente',
            statusConfirmacaoValor: 'confirmado_cliente',
            precoPropostoPrestador: 100,
            commissionPlatform: 10,
            earningsProvider: 90,
            earningsTotal: 100,
          ),
        ),
      ),
    );

    expect(find.text('Taxa da plataforma (10%)'), findsOneWidget);
    expect(find.text('Valor líquido (para ti)'), findsOneWidget);
    expect(
      find.byKey(const Key('prestador_commission_pending_summary')),
      findsNothing,
    );
  });

  testWidgets('resumo concluído incompleto pede reconciliação sem estimar',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        PrestadorPedidoAcoes(
          pedido: buildPedido(
            estado: 'concluido',
            statusProposta: 'aceita_cliente',
            statusConfirmacaoValor: 'confirmado_cliente',
            precoPropostoPrestador: 100,
          ),
        ),
      ),
    );

    expect(
      find.textContaining('O ChegaJá precisa reconciliar este trabalho'),
      findsOneWidget,
    );
    expect(find.textContaining('quando o cliente confirmar'), findsNothing);
    expect(find.textContaining('Taxa da plataforma ('), findsNothing);
    expect(find.text('A reconciliar'), findsOneWidget);
    expect(find.textContaining('100'), findsNothing);
    expect(find.text('Valor líquido (para ti)'), findsNothing);
  });
}
