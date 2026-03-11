import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/services/pedido_service.dart';
import 'package:chegaja_v2/core/utils/pedido_state_machine.dart';

Pedido _buildPedido({
  required String id,
  String clienteId = 'cliente_1',
  String? prestadorId,
  String estado = PedidoStateMachine.criado,
  String servicoId = 'srv_eletricista',
  String? servicoNome = 'Eletricista',
  double? precoPropostoPrestador,
  double? valorMinEstimadoPrestador,
  double? valorMaxEstimadoPrestador,
  String statusProposta = 'nenhuma',
}) {
  return Pedido(
    id: id,
    clienteId: clienteId,
    prestadorId: prestadorId,
    servicoId: servicoId,
    servicoNome: servicoNome,
    titulo: 'Trocar disjuntor',
    descricao: 'Quadro a desligar.',
    modo: 'IMEDIATO',
    status: estado,
    tipoPreco: 'a_combinar',
    tipoPagamento: 'dinheiro',
    valorMinEstimadoPrestador: valorMinEstimadoPrestador,
    valorMaxEstimadoPrestador: valorMaxEstimadoPrestador,
    mensagemPropostaPrestador: null,
    statusProposta: statusProposta,
    propostaExpiresAt: null,
    precoPropostoPrestador: precoPropostoPrestador,
    precoFinal: null,
    statusConfirmacaoValor: 'nenhum',
    commissionPlatform: null,
    earningsProvider: null,
    earningsTotal: null,
    latitude: 38.7223,
    longitude: -9.1393,
    enderecoTexto: 'Lisboa',
    canceladoPor: null,
    motivoCancelamento: null,
    tipoReembolso: null,
    noShowReportedBy: null,
    noShowReason: null,
    noShowAt: null,
    dataAgendada: null,
    createdAt: DateTime(2026, 2, 1),
    updatedAt: DateTime(2026, 2, 1),
  );
}

Future<void> _seedPedido(FakeFirebaseFirestore db, Pedido pedido) async {
  await db.collection('pedidos').doc(pedido.id).set(pedido.toMap());
}

double _asDouble(dynamic value) => (value as num).toDouble();

void main() {
  group('PedidoService', () {
    test('enviarPropostaFaixa atualiza proposta e estado', () async {
      final db = FakeFirebaseFirestore();
      final service = PedidoService(firestore: db, trackAnalytics: false);

      await db.collection('prestadores').doc('prest_1').set({
        'servicos': ['srv_eletricista'],
        'servicosNomes': ['Eletricista'],
      });

      final pedido = _buildPedido(id: 'pedido_1');
      await _seedPedido(db, pedido);

      await service.enviarPropostaFaixa(
        pedido: pedido,
        prestadorId: 'prest_1',
        valorMin: 20,
        valorMax: 35,
        mensagem: 'Inclui deslocacao',
      );

      final snap = await db.collection('pedidos').doc('pedido_1').get();
      final data = snap.data()!;

      expect(data['prestadorId'], 'prest_1');
      expect(data['status'], PedidoStateMachine.aguardaRespostaCliente);
      expect(data['estado'], PedidoStateMachine.aguardaRespostaCliente);
      expect(data['statusProposta'], 'pendente_cliente');
      expect(_asDouble(data['valorMinEstimadoPrestador']), 20);
      expect(_asDouble(data['valorMaxEstimadoPrestador']), 35);
      expect(data['mensagemPropostaPrestador'], 'Inclui deslocacao');

      final historico = (data['historico'] as List<dynamic>);
      expect(historico, isNotEmpty);
      final ultimoEvento = historico.last as Map<String, dynamic>;
      expect(ultimoEvento['evento'], 'proposta_enviada');
    });

    test('aceitarPedidoAberto falha quando prestador nao bate com servico',
        () async {
      final db = FakeFirebaseFirestore();
      final service = PedidoService(firestore: db, trackAnalytics: false);

      await db.collection('prestadores').doc('prest_2').set({
        'servicos': ['srv_canalizacao'],
        'servicosNomes': ['Canalizacao'],
      });

      final pedido = _buildPedido(id: 'pedido_2');
      await _seedPedido(db, pedido);

      expect(
        service.aceitarPedidoAberto(
          pedido: pedido,
          prestadorId: 'prest_2',
        ),
        throwsException,
      );
    });

    test('confirmarValorFinal conclui e calcula comissao', () async {
      final db = FakeFirebaseFirestore();
      final service = PedidoService(firestore: db, trackAnalytics: false);

      final pedido = _buildPedido(
        id: 'pedido_3',
        prestadorId: 'prest_3',
        estado: PedidoStateMachine.aguardaConfirmacaoValor,
        precoPropostoPrestador: 100,
      );
      await _seedPedido(db, pedido);

      await service.confirmarValorFinal(
        pedido: pedido,
        clienteId: 'cliente_1',
        valorFinal: 100,
      );

      final snap = await db.collection('pedidos').doc('pedido_3').get();
      final data = snap.data()!;

      expect(data['status'], PedidoStateMachine.concluido);
      expect(data['estado'], PedidoStateMachine.concluido);
      expect(data['statusConfirmacaoValor'], 'confirmado_cliente');
      expect(_asDouble(data['precoFinal']), 100);
      expect(_asDouble(data['preco']), 100);
      expect(_asDouble(data['commissionPlatform']), closeTo(15.0, 0.001));
      expect(_asDouble(data['earningsProvider']), closeTo(85.0, 0.001));
      expect(_asDouble(data['earningsTotal']), closeTo(100.0, 0.001));
    });

    test('confirmarValorFinal rejeita valor diferente do proposto', () async {
      final db = FakeFirebaseFirestore();
      final service = PedidoService(firestore: db, trackAnalytics: false);

      final pedido = _buildPedido(
        id: 'pedido_4',
        prestadorId: 'prest_4',
        estado: PedidoStateMachine.aguardaConfirmacaoValor,
        precoPropostoPrestador: 120,
      );
      await _seedPedido(db, pedido);

      expect(
        service.confirmarValorFinal(
          pedido: pedido,
          clienteId: 'cliente_1',
          valorFinal: 100,
        ),
        throwsException,
      );
    });

    test('cancelarPorPrestador em estado inicial volta para criado', () async {
      final db = FakeFirebaseFirestore();
      final service = PedidoService(firestore: db, trackAnalytics: false);

      final pedido = _buildPedido(
        id: 'pedido_5',
        prestadorId: 'prest_5',
        estado: PedidoStateMachine.aceito,
        valorMinEstimadoPrestador: 30,
        valorMaxEstimadoPrestador: 40,
        statusProposta: 'aceita_cliente',
      );
      await _seedPedido(db, pedido);

      await service.cancelarPorPrestador(
        pedido: pedido,
        prestadorId: 'prest_5',
        motivo: 'indisponivel',
        tipoReembolso: 'nenhum',
      );

      final snap = await db.collection('pedidos').doc('pedido_5').get();
      final data = snap.data()!;

      expect(data['status'], PedidoStateMachine.criado);
      expect(data['estado'], PedidoStateMachine.criado);
      expect(data['prestadorId'], isNull);
      expect(data['statusProposta'], 'nenhuma');
      expect(data['statusConfirmacaoValor'], 'nenhum');
      expect(data['ultimoCancelamentoPrestadorId'], 'prest_5');
      expect(data['ultimoCancelamentoPrestadorMotivo'], 'indisponivel');
    });
  });

  group('PedidoService helpers', () {
    test('valorForaDaFaixa funciona para min e max', () {
      expect(
        PedidoService.valorForaDaFaixa(valor: 10, min: 15, max: 20),
        isTrue,
      );
      expect(
        PedidoService.valorForaDaFaixa(valor: 25, min: 15, max: 20),
        isTrue,
      );
      expect(
        PedidoService.valorForaDaFaixa(valor: 18, min: 15, max: 20),
        isFalse,
      );
    });

    test('simularComissao usa taxa de 15%', () {
      final result = PedidoService.simularComissao(200);

      expect(result['commissionPlatform'], closeTo(30.0, 0.001));
      expect(result['earningsProvider'], closeTo(170.0, 0.001));
      expect(result['earningsTotal'], closeTo(200.0, 0.001));
    });
  });
}
