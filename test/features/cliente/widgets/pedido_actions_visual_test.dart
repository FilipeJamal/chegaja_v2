import 'package:chegaja_v2/core/models/pedido.dart';
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
    createdAt: DateTime(2026, 5, 19),
  );
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

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
}
