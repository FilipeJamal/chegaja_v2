// lib/core/services/pedido_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/services/analytics_service.dart';
import 'package:chegaja_v2/core/utils/pedido_state_machine.dart';

/// Serviço central de fluxo de pedidos:
/// - Prestador envia faixa de preço (mín/máx)
/// - Cliente aceita / rejeita prestador
/// - Prestador inicia serviço
/// - Prestador lança valor final
/// - Cliente confirma valor final
/// - C3: calcula métricas virtuais de comissão (15%)
/// - Cliente / Prestador podem cancelar o pedido antes de concluir
class PedidoService {
  PedidoService._();

  static final PedidoService instance = PedidoService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _colPedidos =>
      _db.collection('pedidos');

  /// Taxa de comissão SIMULADA (15%).
  static const double _commissionRateSimulada = 0.15;

  /// Atualiza o status/estado de forma consistente
  Map<String, dynamic> _statusPatch(String novoStatus) {
    return {
      'status': novoStatus,
      'estado': novoStatus, // compatibilidade com código antigo
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  void _ensureTransition({
    required Pedido pedido,
    required String to,
    required String role,
  }) {
    PedidoStateMachine.assertTransition(
      role: role,
      from: pedido.estado,
      to: to,
    );
  }

  /// 1) PRESTADOR → envia FAIXA de preço (mín/máx) + mensagem
  ///
  /// Resultado:
  /// - prestadorId definido
  /// - valorMinEstimadoPrestador / valorMaxEstimadoPrestador preenchidos
  /// - statusProposta = "pendente_cliente"
  /// - status = "aguarda_resposta_cliente"
  Future<void> enviarPropostaFaixa({
    required Pedido pedido,
    required String prestadorId,
    required double valorMin,
    required double valorMax,
    String? mensagem,
  }) async {
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aguardaRespostaCliente,
      role: 'prestador',
    );
    await _colPedidos.doc(pedido.id).update({
      'prestadorId': prestadorId,
      'valorMinEstimadoPrestador': valorMin,
      'valorMaxEstimadoPrestador': valorMax,
      'mensagemPropostaPrestador': mensagem,
      'statusProposta': 'pendente_cliente',
      'statusConfirmacaoValor': 'nenhum',
      'precoPropostoPrestador': null,
      'precoFinal': null,
      'commissionPlatform': null,
      'earningsProvider': null,
      'earningsTotal': null,
      ..._statusPatch('aguarda_resposta_cliente'),
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_proposta_enviada',
      pedidoId: pedido.id,
      estado: 'aguarda_resposta_cliente',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'prestador',
    );
  }

  /// 2) CLIENTE → aceita a proposta do prestador
  ///
  /// Resultado:
  /// - statusProposta = "aceita_cliente"
  /// - status = "aceito"
  Future<void> aceitarProposta({required Pedido pedido}) async {
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aceito,
      role: 'cliente',
    );
    await _colPedidos.doc(pedido.id).update({
      'statusProposta': 'aceita_cliente',
      ..._statusPatch('aceito'),
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_proposta_aceita',
      pedidoId: pedido.id,
      estado: 'aceito',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'cliente',
    );
  }

  /// 3) CLIENTE → rejeita a proposta do prestador
  ///
  /// Resultado:
  /// - limpa faixa de preço e prestador
  /// - statusProposta = "rejeitada_cliente"
  /// - status volta a "criado"
  Future<void> rejeitarProposta({required Pedido pedido}) async {
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.criado,
      role: 'cliente',
    );
    await _colPedidos.doc(pedido.id).update({
      'prestadorId': null,
      'valorMinEstimadoPrestador': null,
      'valorMaxEstimadoPrestador': null,
      'mensagemPropostaPrestador': null,
      'statusProposta': 'rejeitada_cliente',
      'statusConfirmacaoValor': 'nenhum',
      'precoPropostoPrestador': null,
      'precoFinal': null,
      'commissionPlatform': null,
      'earningsProvider': null,
      'earningsTotal': null,
      ..._statusPatch('criado'),
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_proposta_rejeitada',
      pedidoId: pedido.id,
      estado: 'criado',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'cliente',
    );
  }

  /// 3b) CLIENTE envia convite direto a um prestador (selecao manual)
  ///
  /// Resultado:
  /// - prestadorId definido
  /// - status = "aguarda_resposta_prestador"
  /// - limpa proposta/valores anteriores
  Future<void> convidarPrestadorManual({
    required Pedido pedido,
    required String prestadorId,
  }) async {
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aguardaRespostaPrestador,
      role: 'cliente',
    );
    await _colPedidos.doc(pedido.id).update({
      'prestadorId': prestadorId,
      'valorMinEstimadoPrestador': null,
      'valorMaxEstimadoPrestador': null,
      'mensagemPropostaPrestador': null,
      'statusProposta': 'nenhuma',
      'statusConfirmacaoValor': 'nenhum',
      'precoPropostoPrestador': null,
      'precoFinal': null,
      'commissionPlatform': null,
      'earningsProvider': null,
      'earningsTotal': null,
      ..._statusPatch('aguarda_resposta_prestador'),
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_convite_manual',
      pedidoId: pedido.id,
      estado: 'aguarda_resposta_prestador',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'cliente',
    );
  }

  /// 3c) PRESTADOR responde ao convite manual (aceitar)
  Future<void> aceitarConvitePrestador({
    required Pedido pedido,
    required String prestadorId,
  }) async {
    if (pedido.prestadorId != null &&
        pedido.prestadorId != prestadorId) {
      throw Exception('Convite nao pertence a este prestador.');
    }

    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aceito,
      role: 'prestador',
    );
    await _colPedidos.doc(pedido.id).update({
      'prestadorId': prestadorId,
      ..._statusPatch('aceito'),
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_convite_aceite',
      pedidoId: pedido.id,
      estado: 'aceito',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'prestador',
    );
  }

  /// 3d) PRESTADOR recusa convite manual
  Future<void> recusarConvitePrestador({
    required Pedido pedido,
    required String prestadorId,
  }) async {
    if (pedido.prestadorId != null &&
        pedido.prestadorId != prestadorId) {
      return;
    }

    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.criado,
      role: 'prestador',
    );
    await _colPedidos.doc(pedido.id).update({
      'prestadorId': null,
      'valorMinEstimadoPrestador': null,
      'valorMaxEstimadoPrestador': null,
      'mensagemPropostaPrestador': null,
      'statusProposta': 'nenhuma',
      'statusConfirmacaoValor': 'nenhum',
      'precoPropostoPrestador': null,
      'precoFinal': null,
      'commissionPlatform': null,
      'earningsProvider': null,
      'earningsTotal': null,
      ..._statusPatch('criado'),
      'ultimoCancelamentoPrestadorId': prestadorId,
      'ultimoCancelamentoPrestadorMotivo': 'convite_recusado',
      'ultimoCancelamentoPrestadorEm': FieldValue.serverTimestamp(),
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_convite_recusado',
      pedidoId: pedido.id,
      estado: 'criado',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'prestador',
    );
  }

  /// 4) PRESTADOR → INICIA o serviço
  ///
  /// Resultado:
  /// - status = "em_andamento"
  Future<void> iniciarServico({required Pedido pedido}) async {
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.emAndamento,
      role: 'prestador',
    );
    await _colPedidos.doc(pedido.id).update(
      _statusPatch('em_andamento'),
    );

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_iniciado',
      pedidoId: pedido.id,
      estado: 'em_andamento',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'prestador',
    );
  }

  /// Alias para manter compatibilidade com código antigo
  Future<void> iniciarPedido({required Pedido pedido}) {
    return iniciarServico(pedido: pedido);
  }

  /// 5) PRESTADOR → termina serviço e lança VALOR FINAL proposto
  ///
  /// Resultado:
  /// - precoPropostoPrestador preenchido
  /// - statusConfirmacaoValor = "pendente_cliente"
  /// - status = "aguarda_confirmacao_valor"
  Future<void> proporValorFinal({
    required Pedido pedido,
    required double valorFinal,
    String? comentario,
  }) async {
    final ref = _db.collection('pedidos').doc(pedido.id);

    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aguardaConfirmacaoValor,
      role: 'prestador',
    );
    await ref.update({
      'precoPropostoPrestador': valorFinal,
      'statusConfirmacaoValor': 'pendente_cliente',
      'estado': 'aguarda_confirmacao_valor',
      'status': 'aguarda_confirmacao_valor',
      if (comentario != null && comentario.trim().isNotEmpty)
        'mensagemPropostaPrestador': comentario.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_valor_final_proposto',
      pedidoId: pedido.id,
      estado: 'aguarda_confirmacao_valor',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'prestador',
    );
  }


  /// 6) CLIENTE → confirma o valor final proposto
  ///
  /// Resultado:
  /// - precoFinal = valorFinal
  /// - campo preco (antigo) também recebe esse valor
  /// - statusConfirmacaoValor = "confirmado_cliente"
  /// - status = "concluido"
  /// - concluidoEm / updatedAt = agora
  /// - commissionPlatform / earningsProvider / earningsTotal calculados (15%)
  Future<void> confirmarValorFinal({
    required Pedido pedido,
    required double valorFinal,
  }) async {
    final double commission = valorFinal * _commissionRateSimulada;
    final double earningsProvider = valorFinal - commission;
    final double earningsTotal = valorFinal;

    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.concluido,
      role: 'cliente',
    );
    await _colPedidos.doc(pedido.id).update({
      'precoFinal': valorFinal,
      'preco': valorFinal, // compatibilidade com código antigo
      'statusConfirmacaoValor': 'confirmado_cliente',
      'commissionPlatform': commission,
      'earningsProvider': earningsProvider,
      'earningsTotal': earningsTotal,
      'concluidoEm': FieldValue.serverTimestamp(),
      ..._statusPatch('concluido'),
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_concluido',
      pedidoId: pedido.id,
      estado: 'concluido',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'cliente',
    );
  }

  /// Helper: ver se o valor final ficou fora da faixa estimada pelo prestador
  static bool valorForaDaFaixa({
    required double valor,
    double? min,
    double? max,
  }) {
    if (min != null && valor < min) return true;
    if (max != null && valor > max) return true;
    return false;
  }

  /// Helper: simula comissão/ganhos a partir de um valor bruto
  /// usando a taxa de 15% (_commissionRateSimulada).
  static Map<String, double> simularComissao(double valorBruto) {
    final double commission = valorBruto * _commissionRateSimulada;
    final double earningsProvider = valorBruto - commission;
    final double earningsTotal = valorBruto;

    return {
      'commissionPlatform': commission,
      'earningsProvider': earningsProvider,
      'earningsTotal': earningsTotal,
    };
  }

  /// 7) CLIENTE → cancela o pedido antes de concluído
  ///
  /// Guardamos:
  /// - estado/status = cancelado
  /// - quem cancelou
  /// - motivo
  /// - tipoReembolso: 'total' | 'parcial' | 'nenhum'
  Future<void> cancelarPorCliente({
    required Pedido pedido,
    required String motivo,
    required String tipoReembolso,
    String? motivoDetalhe,
    bool motivoIsId = false,
  }) async {
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.cancelado,
      role: 'cliente',
    );
    await _colPedidos.doc(pedido.id).update({
      ..._statusPatch('cancelado'),
      'statusProposta': 'nenhuma',
      'statusConfirmacaoValor': 'nenhum',
      'canceladoPor': 'cliente',
      'motivoCancelamento': motivoIsId ? motivo : motivo.trim(),
      'motivoCancelamentoDetalhe': motivoDetalhe?.trim(),
      'tipoReembolso': tipoReembolso,
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_cancelado_cliente',
      pedidoId: pedido.id,
      estado: 'cancelado',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'cliente',
    );
  }

  /// 8) PRESTADOR → cancela / desiste do pedido
  ///
  /// a) estados: 'criado' | 'aguarda_resposta_cliente' | 'aceito'
  ///    → o pedido volta para 'criado' e fica disponível para outro prestador
  ///
  /// b) estados: 'em_andamento' | 'aguarda_confirmacao_valor'
  ///    → o pedido é mesmo CANCELADO com reembolso registado
  Future<void> cancelarPorPrestador({
    required Pedido pedido,
    required String motivo,
    required String tipoReembolso,
    String? motivoDetalhe,
    bool motivoIsId = false,
  }) async {
    final estado = pedido.estado;

    if (estado == 'criado' ||
        estado == 'aguarda_resposta_cliente' ||
        estado == 'aguarda_resposta_prestador' ||
        estado == 'aceito') {
      _ensureTransition(
        pedido: pedido,
        to: PedidoStateMachine.criado,
        role: 'prestador',
      );
      // Liberta o pedido para outro prestador (tipo Uber: cancela e volta a procurar)
      await _colPedidos.doc(pedido.id).update({
        ..._statusPatch('criado'),
        'prestadorId': null,
        'valorMinEstimadoPrestador': null,
        'valorMaxEstimadoPrestador': null,
        'mensagemPropostaPrestador': null,
        'precoPropostoPrestador': null,
        'precoFinal': null,
        'commissionPlatform': null,
        'earningsProvider': null,
        'earningsTotal': null,
        'statusProposta': 'nenhuma',
        'statusConfirmacaoValor': 'nenhum',
        // não marcamos como pedido cancelado
        'canceladoPor': null,
        'motivoCancelamento': null,
        'motivoCancelamentoDetalhe': null,
        'tipoReembolso': null,
        // log da desistência deste prestador (opcional, só para histórico)
        'ultimoCancelamentoPrestadorId': pedido.prestadorId,
        'ultimoCancelamentoPrestadorMotivo': motivoIsId ? motivo : motivo.trim(),
        'ultimoCancelamentoPrestadorMotivoDetalhe': motivoDetalhe?.trim(),
        'ultimoCancelamentoPrestadorEm': FieldValue.serverTimestamp(),
      });

      await AnalyticsService.instance.logPedidoEvent(
        name: 'pedido_desistido_prestador',
        pedidoId: pedido.id,
        estado: 'criado',
        modo: pedido.modo,
        tipoPreco: pedido.tipoPreco,
        role: 'prestador',
      );
    } else {
      _ensureTransition(
        pedido: pedido,
        to: PedidoStateMachine.cancelado,
        role: 'prestador',
      );
      // Serviço já em algum ponto avançado → cancelamento definitivo
      await _colPedidos.doc(pedido.id).update({
        ..._statusPatch('cancelado'),
        'statusProposta': 'nenhuma',
        'statusConfirmacaoValor': 'nenhum',
        'canceladoPor': 'prestador',
        'motivoCancelamento': motivoIsId ? motivo : motivo.trim(),
        'motivoCancelamentoDetalhe': motivoDetalhe?.trim(),
        'tipoReembolso': tipoReembolso,
      });

      await AnalyticsService.instance.logPedidoEvent(
        name: 'pedido_cancelado_prestador',
        pedidoId: pedido.id,
        estado: 'cancelado',
        modo: pedido.modo,
        tipoPreco: pedido.tipoPreco,
        role: 'prestador',
      );
    }
  }

  /// Regista no-show (cliente ou prestador).
  Future<void> reportNoShow({
    required Pedido pedido,
    required String reporterRole,
    String? motivo,
  }) async {
    final role = reporterRole.trim().toLowerCase();
    if (role != 'cliente' && role != 'prestador') {
      throw Exception('reporterRole invalido');
    }

    await _colPedidos.doc(pedido.id).update({
      'noShowReportedBy': role,
      'noShowReason':
          (motivo != null && motivo.trim().isNotEmpty) ? motivo.trim() : null,
      'noShowAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_noshow_reportado',
      pedidoId: pedido.id,
      estado: pedido.estado,
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: role,
    );
  }
}
