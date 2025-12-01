// lib/core/services/pedido_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/models/pedido.dart';

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
  }

  /// 2) CLIENTE → aceita a proposta do prestador
  ///
  /// Resultado:
  /// - statusProposta = "aceita_cliente"
  /// - status = "aceito"
  Future<void> aceitarProposta({required Pedido pedido}) async {
    await _colPedidos.doc(pedido.id).update({
      'statusProposta': 'aceita_cliente',
      ..._statusPatch('aceito'),
    });
  }

  /// 3) CLIENTE → rejeita a proposta do prestador
  ///
  /// Resultado:
  /// - limpa faixa de preço e prestador
  /// - statusProposta = "rejeitada_cliente"
  /// - status volta a "criado"
  Future<void> rejeitarProposta({required Pedido pedido}) async {
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
  }

  /// 4) PRESTADOR → INICIA o serviço
  ///
  /// Resultado:
  /// - status = "em_andamento"
  Future<void> iniciarServico({required Pedido pedido}) async {
    await _colPedidos.doc(pedido.id).update(
      _statusPatch('em_andamento'),
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
  }) async {
    await _colPedidos.doc(pedido.id).update({
      'precoPropostoPrestador': valorFinal,
      'statusConfirmacaoValor': 'pendente_cliente',
      ..._statusPatch('aguarda_confirmacao_valor'),
    });
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
  }) async {
    await _colPedidos.doc(pedido.id).update({
      ..._statusPatch('cancelado'),
      'statusProposta': pedido.statusProposta ?? 'nenhum',
      'statusConfirmacaoValor': 'nenhum',
      'canceladoPor': 'cliente',
      'motivoCancelamento': motivo,
      'tipoReembolso': tipoReembolso,
    });
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
  }) async {
    final estado = pedido.estado;

    if (estado == 'criado' ||
        estado == 'aguarda_resposta_cliente' ||
        estado == 'aceito') {
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
        'statusProposta': 'nenhum',
        'statusConfirmacaoValor': 'nenhum',
        // não marcamos como pedido cancelado
        'canceladoPor': null,
        'motivoCancelamento': null,
        'tipoReembolso': null,
        // log da desistência deste prestador (opcional, só para histórico)
        'ultimoCancelamentoPrestadorId': pedido.prestadorId,
        'ultimoCancelamentoPrestadorMotivo': motivo,
        'ultimoCancelamentoPrestadorEm': FieldValue.serverTimestamp(),
      });
    } else {
      // Serviço já em algum ponto avançado → cancelamento definitivo
      await _colPedidos.doc(pedido.id).update({
        ..._statusPatch('cancelado'),
        'statusProposta': pedido.statusProposta ?? 'nenhum',
        'statusConfirmacaoValor': 'nenhum',
        'canceladoPor': 'prestador',
        'motivoCancelamento': motivo,
        'tipoReembolso': tipoReembolso,
      });
    }
  }
}
