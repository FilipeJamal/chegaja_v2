import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_flow_presenter.dart';

Pedido buildPedido({
  String estado = 'criado',
  String? prestadorId,
  String? canceladoPor,
  String? motivoCancelamento,
  double? precoPropostoPrestador,
  double? precoFinal,
  String statusConfirmacaoValor = 'nenhum',
  DateTime? updatedAt,
}) {
  return Pedido(
    id: 'pedido_flow_1',
    clienteId: 'cliente_1',
    prestadorId: prestadorId,
    servicoId: 'srv_1',
    servicoNome: 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida',
    modo: 'IMEDIATO',
    status: estado,
    tipoPreco: 'por_orcamento',
    tipoPagamento: 'dinheiro',
    statusProposta: 'nenhuma',
    statusConfirmacaoValor: statusConfirmacaoValor,
    canceladoPor: canceladoPor,
    motivoCancelamento: motivoCancelamento,
    precoPropostoPrestador: precoPropostoPrestador,
    precoFinal: precoFinal,
    createdAt: DateTime(2026, 5, 19),
    updatedAt: updatedAt,
  );
}

void main() {
  group('PedidoFlowPresenter', () {
    test('pos-criacao automatica orienta para aguardando prestador', () {
      final feedback = PedidoFlowPresenter.creationSuccess(manual: false);

      expect(feedback.title, 'Pedido criado');
      expect(feedback.message, contains('vamos procurar'));
      expect(feedback.nextStep, contains('avisamos'));
    });

    test('pos-criacao manual orienta para aguardar resposta do prestador', () {
      final feedback = PedidoFlowPresenter.creationSuccess(manual: true);

      expect(feedback.title, 'Convite enviado');
      expect(feedback.message, contains('prestador escolhido'));
      expect(feedback.nextStep, contains('aceitar ou recusar'));
    });

    test('cliente ve copy segura para confirmar valor final', () {
      final copy = PedidoFlowPresenter.clientFinalValueCopy(
        buildPedido(
          estado: 'aguarda_confirmacao_valor',
          precoPropostoPrestador: 120,
          statusConfirmacaoValor: 'pendente_cliente',
        ),
      );

      expect(copy.title, 'Confirma o valor final');
      expect(copy.primaryActionLabel, 'Confirmar valor');
      expect(copy.secondaryActionLabel, 'Tenho uma duvida');
      expect(copy.body, contains('valor final'));
      expect(copy.body, isNot(contains('backend')));
    });

    test('prestador ve copy para aguardar confirmacao do cliente', () {
      final copy = PedidoFlowPresenter.providerWaitingClientCopy(
        buildPedido(
          estado: 'aguarda_confirmacao_valor',
          precoPropostoPrestador: 90,
        ),
      );

      expect(copy.title, 'Aguardar confirmacao do cliente');
      expect(copy.body, contains('cliente confirmar'));
      expect(copy.nextStep, contains('fica concluido'));
    });

    test('pedido concluido gera estado final sem acao indevida', () {
      final state = PedidoFlowPresenter.finalStateFor(
        buildPedido(
          estado: 'concluido',
          precoFinal: 80,
          updatedAt: DateTime(2026, 5, 19, 10),
        ),
      );

      expect(state.title, 'Pedido concluido');
      expect(state.message, contains('ficou concluido'));
      expect(state.actionHint, 'Consulta os detalhes sempre que precisares.');
      expect(state.isFinal, isTrue);
    });

    test('pedido cancelado mostra responsavel quando existir', () {
      final state = PedidoFlowPresenter.finalStateFor(
        buildPedido(
          estado: 'cancelado',
          canceladoPor: 'prestador',
          motivoCancelamento: 'Agenda indisponivel',
          updatedAt: DateTime(2026, 5, 19, 11),
        ),
      );

      expect(state.title, 'Pedido cancelado');
      expect(state.message, contains('prestador'));
      expect(state.detail, contains('Agenda indisponivel'));
      expect(state.isFinal, isTrue);
    });
  });
}
