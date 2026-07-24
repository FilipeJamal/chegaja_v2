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
  String statusConfirmacaoValor = 'nenhum',
  bool categoryApprovalRequired = false,
  String? categoryRequirementId,
}) {
  return Pedido(
    id: id,
    clienteId: clienteId,
    prestadorId: prestadorId,
    servicoId: servicoId,
    servicoNome: servicoNome,
    categoryApprovalRequired: categoryApprovalRequired,
    categoryRequirementId: categoryRequirementId,
    categoryRequirementName: servicoNome,
    categoryRiskLevel: categoryApprovalRequired ? 'sensitive' : null,
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
    statusConfirmacaoValor: statusConfirmacaoValor,
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

Future<void> _seedPedido(FakeFirebaseFirestore db, Pedido pedido) {
  return db.collection('pedidos').doc(pedido.id).set(pedido.toMap());
}

Future<void> _seedMatchingProvider(
  FakeFirebaseFirestore db,
  String prestadorId, {
  String servicoId = 'srv_eletricista',
  String servicoNome = 'Eletricista',
  List<String> customServiceSearchTerms = const <String>[],
  List<String> approvedSensitiveCategoryIds = const <String>[],
}) {
  return db.collection('provider_public').doc(prestadorId).set({
    'servicos': [servicoId],
    'servicosNomes': [servicoNome],
    'customServiceSearchTerms': customServiceSearchTerms,
    'approvedSensitiveCategoryIds': approvedSensitiveCategoryIds,
  });
}

class _FakePedidoValueFunctionsGateway implements PedidoValueFunctionsGateway {
  final actions = <Map<String, dynamic>>[];
  final dispatches = <String>[];
  final propostas = <Map<String, dynamic>>[];
  final confirmacoes = <String>[];

  Object? applyActionError;

  @override
  Future<void> applyAction({
    required String pedidoId,
    required String action,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) async {
    if (applyActionError case final error?) {
      throw error;
    }
    actions.add({
      'pedidoId': pedidoId,
      'action': action,
      'data': Map<String, dynamic>.from(data),
    });
  }

  @override
  Future<void> aceitarPedidoDispatch({required String pedidoId}) async {
    dispatches.add(pedidoId);
  }

  @override
  Future<void> proporValorFinalPedido({
    required String pedidoId,
    required double valorFinal,
    String? comentario,
  }) async {
    propostas.add({
      'pedidoId': pedidoId,
      'valorFinal': valorFinal,
      'comentario': comentario,
    });
  }

  @override
  Future<void> confirmarValorFinalPedido({required String pedidoId}) async {
    confirmacoes.add(pedidoId);
  }
}

PedidoService _buildService(
  FakeFirebaseFirestore db,
  _FakePedidoValueFunctionsGateway gateway,
) {
  return PedidoService(
    firestore: db,
    trackAnalytics: false,
    valueFunctionsGateway: gateway,
  );
}

Map<String, dynamic> _action(
  String pedidoId,
  String action, [
  Map<String, dynamic> data = const <String, dynamic>{},
]) {
  return {
    'pedidoId': pedidoId,
    'action': action,
    'data': data,
  };
}

void main() {
  group('PedidoService - validacao e matching', () {
    test('aceitarPedidoAberto falha quando prestador nao bate com servico',
        () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await _seedMatchingProvider(
        db,
        'prest_2',
        servicoId: 'srv_canalizacao',
        servicoNome: 'Canalizacao',
      );

      expect(
        service.aceitarPedidoAberto(
          pedido: _buildPedido(id: 'pedido_2'),
          prestadorId: 'prest_2',
        ),
        throwsException,
      );
      expect(gateway.dispatches, isEmpty);
    });

    test('pedido custom nao faz match amplo com outro servico generico',
        () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await _seedMatchingProvider(
        db,
        'prest_outro',
        servicoId: 'other_service',
        servicoNome: 'Outro servico',
      );

      expect(
        service.aceitarPedidoAberto(
          pedido: _buildPedido(
            id: 'pedido_custom',
            servicoId: 'custom_consultoria_de_imagem',
            servicoNome: 'Consultoria de imagem',
          ),
          prestadorId: 'prest_outro',
        ),
        throwsException,
      );
      expect(gateway.dispatches, isEmpty);
    });

    test('pedido custom faz match por termos personalizados compativeis',
        () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await _seedMatchingProvider(
        db,
        'prest_custom',
        servicoId: 'custom_consultoria_de_imagem',
        servicoNome: 'Consultoria de imagem',
        customServiceSearchTerms: ['consultoria de imagem', 'moda'],
      );
      final pedido = _buildPedido(
        id: 'pedido_custom_match',
        servicoId: 'custom_consultoria_de_imagem',
        servicoNome: 'Consultoria de imagem',
      );
      await _seedPedido(db, pedido);

      await service.aceitarPedidoAberto(
        pedido: pedido,
        prestadorId: 'prest_custom',
      );

      expect(gateway.dispatches, ['pedido_custom_match']);
      final persisted =
          await db.collection('pedidos').doc('pedido_custom_match').get();
      expect(persisted.data()!['prestadorId'], isNull);
      expect(persisted.data()!['status'], PedidoStateMachine.criado);
    });

    test('enviarPropostaFaixa exige aprovacao em categoria sensivel', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await _seedMatchingProvider(
        db,
        'prest_1',
        servicoId: 'electricity',
        servicoNome: 'Eletricidade',
      );

      expect(
        service.enviarPropostaFaixa(
          pedido: _buildPedido(
            id: 'pedido_sensivel',
            servicoId: 'electricity',
            servicoNome: 'Eletricidade',
            categoryApprovalRequired: true,
            categoryRequirementId: 'electricity',
          ),
          prestadorId: 'prest_1',
          valorMin: 20,
          valorMax: 35,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('exige prestador com aprovacao'),
          ),
        ),
      );
      expect(gateway.actions, isEmpty);
    });

    test('enviarPropostaFaixa rejeita valores e validade invalidos', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);
      final pedido = _buildPedido(id: 'pedido_invalido');

      expect(
        service.enviarPropostaFaixa(
          pedido: pedido,
          prestadorId: 'prest_1',
          valorMin: 50,
          valorMax: 20,
        ),
        throwsException,
      );

      await _seedMatchingProvider(db, 'prest_1');
      expect(
        service.enviarPropostaFaixa(
          pedido: pedido,
          prestadorId: 'prest_1',
          valorMin: 20,
          valorMax: 50,
          validity: const Duration(minutes: 14),
        ),
        throwsException,
      );
      expect(gateway.actions, isEmpty);
    });

    test('confirmarValorFinal rejeita valor diferente do proposto', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      expect(
        service.confirmarValorFinal(
          pedido: _buildPedido(
            id: 'pedido_4',
            prestadorId: 'prest_4',
            estado: PedidoStateMachine.aguardaConfirmacaoValor,
            precoPropostoPrestador: 120,
          ),
          clienteId: 'cliente_1',
          valorFinal: 100,
        ),
        throwsException,
      );
      expect(gateway.confirmacoes, isEmpty);
    });
  });

  group('PedidoService - acoes autoritativas', () {
    test('mapeia envio de proposta e nao escreve fallback no Firestore',
        () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);
      await _seedMatchingProvider(db, 'prest_1');
      final pedido = _buildPedido(id: 'pedido_quote');
      await _seedPedido(db, pedido);

      await service.enviarPropostaFaixa(
        pedido: pedido,
        prestadorId: 'prest_1',
        valorMin: 20,
        valorMax: 35,
        mensagem: '  Inclui deslocacao  ',
        validity: const Duration(hours: 2),
      );

      expect(gateway.actions, [
        _action('pedido_quote', 'provider_submit_quote', {
          'valorMin': 20.0,
          'valorMax': 35.0,
          'mensagem': 'Inclui deslocacao',
          'validadeMinutos': 120,
        }),
      ]);
      final persisted =
          await db.collection('pedidos').doc('pedido_quote').get();
      expect(persisted.data()!['prestadorId'], isNull);
      expect(persisted.data()!['status'], PedidoStateMachine.criado);
      expect(persisted.data()!['historico'], isEmpty);
    });

    test('propaga falha da callable sem recorrer a escrita local', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway()
        ..applyActionError = StateError('backend indisponivel');
      final service = _buildService(db, gateway);
      await _seedMatchingProvider(db, 'prest_1');
      final pedido = _buildPedido(id: 'pedido_no_fallback');
      await _seedPedido(db, pedido);

      expect(
        service.enviarPropostaFaixa(
          pedido: pedido,
          prestadorId: 'prest_1',
          valorMin: 20,
          valorMax: 35,
        ),
        throwsStateError,
      );

      final persisted =
          await db.collection('pedidos').doc('pedido_no_fallback').get();
      expect(persisted.data()!['prestadorId'], isNull);
      expect(persisted.data()!['status'], PedidoStateMachine.criado);
      expect(persisted.data()!['historico'], isEmpty);
    });

    test('mapeia aceitar e rejeitar proposta', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);
      final pedido = _buildPedido(
        id: 'pedido_quote_response',
        prestadorId: 'prest_1',
        estado: PedidoStateMachine.aguardaRespostaCliente,
        statusProposta: 'pendente_cliente',
      );

      await service.aceitarProposta(
        pedido: pedido,
        clienteId: 'cliente_1',
      );
      await service.rejeitarProposta(
        pedido: pedido,
        clienteId: 'cliente_1',
      );

      expect(gateway.actions, [
        _action('pedido_quote_response', 'client_accept_quote'),
        _action('pedido_quote_response', 'client_reject_quote'),
      ]);
    });

    test('mapeia convite manual e recusa do prestador', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await service.convidarPrestadorManual(
        pedido: _buildPedido(id: 'pedido_invite'),
        clienteId: 'cliente_1',
        prestadorId: 'prest_2',
      );
      await service.recusarConvitePrestador(
        pedido: _buildPedido(
          id: 'pedido_invite',
          prestadorId: 'prest_2',
          estado: PedidoStateMachine.aguardaRespostaPrestador,
        ),
        prestadorId: 'prest_2',
      );

      expect(gateway.actions, [
        _action('pedido_invite', 'client_invite_provider', {
          'prestadorId': 'prest_2',
        }),
        _action('pedido_invite', 'provider_decline_invite'),
      ]);
    });

    test('mapeia troca de convite pendente para acao autoritativa', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await service.trocarPrestadorConvidado(
        pedido: _buildPedido(
          id: 'pedido_replace_invite',
          prestadorId: 'prest_1',
          estado: PedidoStateMachine.aguardaRespostaPrestador,
        ),
        clienteId: 'cliente_1',
        prestadorId: 'prest_2',
      );

      expect(gateway.actions, [
        _action('pedido_replace_invite', 'client_replace_invited_provider', {
          'prestadorId': 'prest_2',
        }),
      ]);
    });

    test('mapeia aceitacao de convite para dispatch autoritativo', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);
      await _seedMatchingProvider(db, 'prest_2');

      await service.aceitarConvitePrestador(
        pedido: _buildPedido(
          id: 'pedido_accept_invite',
          prestadorId: 'prest_2',
          estado: PedidoStateMachine.aguardaRespostaPrestador,
        ),
        prestadorId: 'prest_2',
      );

      expect(gateway.dispatches, ['pedido_accept_invite']);
    });

    test('mapeia inicio do servico', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await service.iniciarServico(
        pedido: _buildPedido(
          id: 'pedido_start',
          prestadorId: 'prest_3',
          estado: PedidoStateMachine.aceito,
        ),
        prestadorId: 'prest_3',
      );

      expect(gateway.actions, [
        _action('pedido_start', 'provider_start_service'),
      ]);
    });

    test('valores finais usam apenas callables autoritativas', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await service.proporValorFinal(
        pedido: _buildPedido(
          id: 'pedido_value',
          prestadorId: 'prest_3',
          estado: PedidoStateMachine.emAndamento,
        ),
        prestadorId: 'prest_3',
        valorFinal: 100,
        comentario: 'Servico terminado',
      );
      await service.confirmarValorFinal(
        pedido: _buildPedido(
          id: 'pedido_value',
          prestadorId: 'prest_3',
          estado: PedidoStateMachine.aguardaConfirmacaoValor,
          precoPropostoPrestador: 100,
          statusConfirmacaoValor: 'pendente_cliente',
        ),
        clienteId: 'cliente_1',
        valorFinal: 100,
      );

      expect(gateway.propostas, [
        {
          'pedidoId': 'pedido_value',
          'valorFinal': 100.0,
          'comentario': 'Servico terminado',
        },
      ]);
      expect(gateway.confirmacoes, ['pedido_value']);
    });

    test('mapeia rejeicao do valor final com motivo normalizado', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await service.rejeitarValorFinal(
        pedido: _buildPedido(
          id: 'pedido_reject_value',
          prestadorId: 'prest_6',
          estado: PedidoStateMachine.aguardaConfirmacaoValor,
          precoPropostoPrestador: 120,
          statusConfirmacaoValor: 'pendente_cliente',
        ),
        clienteId: 'cliente_1',
        motivo: '  Preciso confirmar o material.  ',
      );

      expect(gateway.actions, [
        _action('pedido_reject_value', 'client_reject_final_value', {
          'motivo': 'Preciso confirmar o material.',
        }),
      ]);
    });

    test('mapeia cancelamento do cliente sem decisao de reembolso', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await service.cancelarPorCliente(
        pedido: _buildPedido(id: 'pedido_cancel_client'),
        clienteId: 'cliente_1',
        motivo: '  ja nao preciso  ',
        motivoDetalhe: '  agenda alterada  ',
        tipoReembolso: 'total_forjado_no_cliente',
      );

      expect(gateway.actions, [
        _action('pedido_cancel_client', 'client_cancel', {
          'motivo': 'ja nao preciso',
          'motivoDetalhe': 'agenda alterada',
        }),
      ]);
    });

    test('mapeia cancelamento do prestador', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);

      await service.cancelarPorPrestador(
        pedido: _buildPedido(
          id: 'pedido_cancel_provider',
          prestadorId: 'prest_5',
          estado: PedidoStateMachine.aceito,
        ),
        prestadorId: 'prest_5',
        motivo: 'indisponivel',
        motivoDetalhe: '  avaria na viatura  ',
        tipoReembolso: 'nenhum',
        motivoIsId: true,
      );

      expect(gateway.actions, [
        _action('pedido_cancel_provider', 'provider_cancel', {
          'motivo': 'indisponivel',
          'motivoDetalhe': 'avaria na viatura',
        }),
      ]);
    });

    test('mapeia no-show por cliente e prestador', () async {
      final db = FakeFirebaseFirestore();
      final gateway = _FakePedidoValueFunctionsGateway();
      final service = _buildService(db, gateway);
      final pedido = _buildPedido(
        id: 'pedido_no_show',
        prestadorId: 'prest_8',
        estado: PedidoStateMachine.aceito,
      );

      await service.reportNoShow(
        pedido: pedido,
        reporterRole: ' CLIENTE ',
        motivo: '  nao apareceu  ',
      );
      await service.reportNoShow(
        pedido: pedido,
        reporterRole: 'prestador',
      );

      expect(gateway.actions, [
        _action('pedido_no_show', 'client_report_no_show', {
          'motivo': 'nao apareceu',
        }),
        _action('pedido_no_show', 'provider_report_no_show'),
      ]);
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
  });
}
