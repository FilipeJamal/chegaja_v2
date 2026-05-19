import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

Pedido buildPedido({
  String estado = 'criado',
  String? prestadorId,
  String tipoPreco = 'a_combinar',
  String statusProposta = 'nenhuma',
  String statusConfirmacaoValor = 'nenhum',
  double? precoPropostoPrestador,
  String? canceladoPor,
}) {
  return Pedido(
    id: 'pedido_1',
    clienteId: 'cliente_1',
    prestadorId: prestadorId,
    servicoId: 'srv_eletricista',
    servicoNome: 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida',
    modo: 'IMEDIATO',
    status: estado,
    tipoPreco: tipoPreco,
    tipoPagamento: 'dinheiro',
    statusProposta: statusProposta,
    precoPropostoPrestador: precoPropostoPrestador,
    statusConfirmacaoValor: statusConfirmacaoValor,
    canceladoPor: canceladoPor,
    createdAt: DateTime(2026, 5, 19),
  );
}

void main() {
  group('PedidoStatusPresenter', () {
    test('cliente ve proxima acao correta em valor final pendente', () {
      final pedido = buildPedido(
        estado: 'aguarda_confirmacao_valor',
        prestadorId: 'prestador_1',
        statusConfirmacaoValor: 'pendente_cliente',
        precoPropostoPrestador: 100,
      );

      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(summary.title, 'Confirma o valor final');
      expect(summary.tone, PedidoStatusTone.warning);
      expect(summary.icon, Icons.price_check_rounded);
      expect(nextAction.title, 'Proxima acao');
      expect(nextAction.description, contains('confirma'));
      expect(nextAction.description, contains('valor final'));
      expect(nextAction.nextStep, contains('pedido fica concluido'));
      expect(nextAction.hasUserAction, isTrue);
    });

    test('prestador ve proxima acao correta em convite pendente', () {
      final pedido = buildPedido(
        estado: 'aguarda_resposta_prestador',
        prestadorId: 'prestador_1',
      );

      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.prestador,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.prestador,
      );

      expect(summary.title, 'Convite recebido');
      expect(summary.actor, 'Acao do prestador');
      expect(nextAction.description, contains('Aceita ou recusa'));
      expect(nextAction.hasUserAction, isTrue);
    });

    test('pedido concluido mostra estado final sem acao indevida', () {
      final pedido = buildPedido(
        estado: 'concluido',
        prestadorId: 'prestador_1',
      );

      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(summary.title, 'Pedido concluido');
      expect(summary.tone, PedidoStatusTone.success);
      expect(nextAction.hasUserAction, isFalse);
      expect(nextAction.description, contains('consultar os detalhes'));
      expect(nextAction.description, isNot(contains('avaliar')));
    });

    test('pedido cancelado mostra cancelamento', () {
      final pedido = buildPedido(
        estado: 'cancelado',
        canceladoPor: 'prestador',
      );

      final summary = PedidoStatusPresenter.summaryFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );
      final nextAction = PedidoStatusPresenter.nextActionFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(summary.title, 'Pedido cancelado');
      expect(summary.actor, 'Cancelado pelo prestador');
      expect(summary.tone, PedidoStatusTone.danger);
      expect(nextAction.hasUserAction, isFalse);
    });

    test('timeline mapeia estados principais', () {
      expect(PedidoStatusPresenter.timelineStepFor('criado'), 0);
      expect(
        PedidoStatusPresenter.timelineStepFor('aguarda_resposta_prestador'),
        0,
      );
      expect(
        PedidoStatusPresenter.timelineStepFor('aguarda_resposta_cliente'),
        0,
      );
      expect(PedidoStatusPresenter.timelineStepFor('aceito'), 1);
      expect(PedidoStatusPresenter.timelineStepFor('em_andamento'), 2);
      expect(
        PedidoStatusPresenter.timelineStepFor('aguarda_confirmacao_valor'),
        2,
      );
      expect(PedidoStatusPresenter.timelineStepFor('concluido'), 3);
      expect(PedidoStatusPresenter.timelineStepFor('cancelado'), 3);
    });
  });
}
