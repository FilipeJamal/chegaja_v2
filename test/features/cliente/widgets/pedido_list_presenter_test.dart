import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_list_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';

Pedido buildPedido({
  String estado = 'criado',
  String? prestadorId,
  String tipoPreco = 'a_combinar',
  String tipoPagamento = 'dinheiro',
  String statusProposta = 'nenhuma',
  String statusConfirmacaoValor = 'nenhum',
  double? precoPropostoPrestador,
  double? precoFinal,
  double? valorMinEstimadoPrestador,
  double? valorMaxEstimadoPrestador,
  String? canceladoPor,
  String? servicoNome,
  String modo = 'IMEDIATO',
  DateTime? agendadoPara,
}) {
  return Pedido(
    id: 'pedido_1',
    clienteId: 'cliente_1',
    prestadorId: prestadorId,
    servicoId: 'srv_eletricista',
    servicoNome: servicoNome ?? 'Eletricista',
    titulo: 'Trocar tomada',
    descricao: 'Tomada partida',
    modo: modo,
    status: estado,
    tipoPreco: tipoPreco,
    tipoPagamento: tipoPagamento,
    statusProposta: statusProposta,
    statusConfirmacaoValor: statusConfirmacaoValor,
    precoPropostoPrestador: precoPropostoPrestador,
    precoFinal: precoFinal,
    valorMinEstimadoPrestador: valorMinEstimadoPrestador,
    valorMaxEstimadoPrestador: valorMaxEstimadoPrestador,
    canceladoPor: canceladoPor,
    dataAgendada: agendadoPara,
    createdAt: DateTime(2026, 5, 19),
  );
}

void main() {
  group('PedidoListPresenter', () {
    test('cliente com valor final pendente mostra acao curta', () {
      final pedido = buildPedido(
        estado: 'aguarda_confirmacao_valor',
        prestadorId: 'prestador_1',
        statusConfirmacaoValor: 'pendente_cliente',
        precoPropostoPrestador: 120,
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(data.title, 'Trocar tomada');
      expect(data.category, 'Eletricista');
      expect(data.statusLabel, 'Confirma o valor final');
      expect(data.actionLabel, 'Confirmar valor final');
      expect(data.hasUserAction, isTrue);
      expect(data.bucket, PedidoListBucket.ativo);
      expect(data.valueLabel, contains('Valor a confirmar'));
    });

    test('prestador com convite pendente mostra aceitar ou recusar', () {
      final pedido = buildPedido(
        estado: 'aguarda_resposta_prestador',
        prestadorId: 'prestador_1',
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.prestador,
      );

      expect(data.statusLabel, 'Convite recebido');
      expect(data.actionLabel, 'Aceitar ou recusar convite');
      expect(data.hasUserAction, isTrue);
      expect(data.bucket, PedidoListBucket.ativo);
    });

    test('pedido concluido nao mostra urgencia', () {
      final pedido = buildPedido(
        estado: 'concluido',
        prestadorId: 'prestador_1',
        statusConfirmacaoValor: 'confirmado_cliente',
        precoFinal: 80,
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(data.statusLabel, 'Pedido concluido');
      expect(data.actionLabel, 'Sem acao pendente');
      expect(data.hasUserAction, isFalse);
      expect(data.bucket, PedidoListBucket.concluido);
      expect(data.valueLabel, contains('Valor final'));
    });

    test('pedido cancelado mostra estado final', () {
      final pedido = buildPedido(
        estado: 'cancelado',
        canceladoPor: 'prestador',
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(data.statusLabel, 'Pedido cancelado');
      expect(data.actionLabel, 'Pedido cancelado');
      expect(data.hasUserAction, isFalse);
      expect(data.bucket, PedidoListBucket.cancelado);
    });

    test('faixa estimada e apresentada sem virar valor final', () {
      final pedido = buildPedido(
        estado: 'aguarda_resposta_cliente',
        statusProposta: 'pendente_cliente',
        tipoPreco: 'por_orcamento',
        valorMinEstimadoPrestador: 40,
        valorMaxEstimadoPrestador: 70,
      );

      final data = PedidoListPresenter.dataFor(
        pedido,
        role: PedidoViewerRole.cliente,
      );

      expect(data.valueLabel, contains('Faixa estimada'));
      expect(data.valueLabel, isNot(contains('Valor final')));
    });
  });
}
