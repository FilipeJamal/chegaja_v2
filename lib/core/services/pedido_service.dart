// lib/core/services/pedido_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/models/pedido_historico_item.dart';
import 'package:chegaja_v2/core/repositories/pedido_repo.dart';
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
  PedidoService({
    FirebaseFirestore? firestore,
    bool trackAnalytics = true,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _trackAnalytics = trackAnalytics;

  PedidoService._()
      : _db = FirebaseFirestore.instance,
        _trackAnalytics = true;

  static final PedidoService instance = PedidoService._();

  final FirebaseFirestore _db;
  final bool _trackAnalytics;

  CollectionReference<Map<String, dynamic>> get _colPedidos =>
      _db.collection('pedidos');

  /// Taxa de comissão SIMULADA (15%).
  static const double _commissionRateSimulada = 0.15;

  /// Helper para garantir que quem executa a ação é o dono/parte do pedido.
  void _assertOwnership({
    required Pedido pedido,
    required String userId,
    required String role,
  }) {
    if (role == 'cliente') {
      if (pedido.clienteId != userId) {
        throw Exception(
          'Acesso negado: utilizador não é o cliente deste pedido.',
        );
      }
    } else if (role == 'prestador') {
      // Nota: estados iniciais (enviar proposta/aceitar convite) podem ter lógica específica
      // mas regra geral, se o pedido já tem prestadorId, tem de bater certo.
      if (pedido.prestadorId != null && pedido.prestadorId != userId) {
        throw Exception(
          'Acesso negado: utilizador não é o prestador deste pedido.',
        );
      }
    }
  }

  /// Atualiza o status/estado de forma consistente
  Map<String, dynamic> _statusPatch(String novoStatus) {
    return {
      'status': novoStatus,
      'estado': novoStatus, // compatibilidade com código antigo
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Gera um patch para adicionar um item ao histórico (Audit Trail).
  Map<String, dynamic> _historyPatch({
    required String evento,
    required String userId, // quem causou o evento
    String? descricao,
  }) {
    final item = PedidoHistoricoItem(
      evento: evento,
      timestamp: DateTime.now(),
      userId: userId,
      descricao: descricao,
    );
    return {
      'historico': FieldValue.arrayUnion([item.toMap()]),
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

  Future<void> _logPedidoEvent({
    required String name,
    required String pedidoId,
    required String estado,
    required String modo,
    required String tipoPreco,
    required String role,
  }) {
    if (!_trackAnalytics) {
      return Future<void>.value();
    }

    return AnalyticsService.instance.logPedidoEvent(
      name: name,
      pedidoId: pedidoId,
      estado: estado,
      modo: modo,
      tipoPreco: tipoPreco,
      role: role,
    );
  }

  Future<void> _assertPrestadorMatchesPedido({
    required Pedido pedido,
    required String prestadorId,
  }) async {
    final snap = await _db.collection('prestadores').doc(prestadorId).get();
    final data = snap.data();

    final ids = (data?['servicos'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet() ??
        <String>{};

    final nomes = (data?['servicosNomes'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet() ??
        <String>{};

    final servicoId = pedido.servicoId.trim();
    final servicoNome = (pedido.servicoNome ?? pedido.categoria ?? '').trim();

    final matches = (servicoId.isNotEmpty && ids.contains(servicoId)) ||
        (servicoNome.isNotEmpty && nomes.contains(servicoNome));

    if (!matches) {
      final label = servicoNome.isNotEmpty
          ? servicoNome
          : (servicoId.isNotEmpty ? servicoId : 'este servico');
      throw Exception(
        'Nao podes aceitar este pedido: o teu perfil nao esta inscrito no servico "$label".',
      );
    }
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
    Duration validity = const Duration(hours: 24),
  }) async {
    // Validação de negócio
    if (valorMin <= 0 || valorMax <= 0 || valorMax < valorMin) {
      throw Exception('Faixa de valor inválida.');
    }

    _assertOwnership(
      pedido: pedido,
      userId: prestadorId,
      role: 'prestador',
    );

    // Business rule: prestador so pode interagir com pedidos do(s) seu(s) servico(s)
    await _assertPrestadorMatchesPedido(
      pedido: pedido,
      prestadorId: prestadorId,
    );

    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aguardaRespostaCliente,
      role: 'prestador',
    );

    final expiresAt = DateTime.now().add(validity);

    await _colPedidos.doc(pedido.id).update({
      'prestadorId': prestadorId,
      'valorMinEstimadoPrestador': valorMin,
      'valorMaxEstimadoPrestador': valorMax,
      'mensagemPropostaPrestador': mensagem,
      'statusProposta': 'pendente_cliente',
      'propostaExpiresAt': Timestamp.fromDate(expiresAt),
      'statusConfirmacaoValor': 'nenhum',
      'precoPropostoPrestador': null,
      'precoFinal': null,
      'commissionPlatform': null,
      'earningsProvider': null,
      'earningsTotal': null,
      ..._statusPatch('aguarda_resposta_cliente'),
      ..._historyPatch(
        evento: 'proposta_enviada',
        userId: prestadorId,
        descricao: 'Prestador enviou proposta: $valorMin€ - $valorMax€',
      ),
    });

    await _logPedidoEvent(
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
  Future<void> aceitarProposta({
    required Pedido pedido,
    required String clienteId,
  }) async {
    _assertOwnership(
      pedido: pedido,
      userId: clienteId,
      role: 'cliente',
    );
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aceito,
      role: 'cliente',
    );
    await _colPedidos.doc(pedido.id).update({
      'statusProposta': 'aceita_cliente',
      ..._statusPatch('aceito'),
      ..._historyPatch(
        evento: 'proposta_aceita',
        userId: clienteId,
        descricao: 'Cliente aceitou a proposta do prestador',
      ),
    });

    await _logPedidoEvent(
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
  Future<void> rejeitarProposta({
    required Pedido pedido,
    required String clienteId,
  }) async {
    _assertOwnership(
      pedido: pedido,
      userId: clienteId,
      role: 'cliente',
    );
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
      'propostaExpiresAt': null,
      'statusConfirmacaoValor': 'nenhum',
      'precoPropostoPrestador': null,
      'precoFinal': null,
      'commissionPlatform': null,
      'earningsProvider': null,
      'earningsTotal': null,
      ..._statusPatch('criado'),
      ..._historyPatch(
        evento: 'proposta_rejeitada',
        userId: clienteId,
        descricao: 'Cliente rejeitou a proposta',
      ),
    });

    await _logPedidoEvent(
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
    required String clienteId,
    required String prestadorId,
  }) async {
    _assertOwnership(
      pedido: pedido,
      userId: clienteId,
      role: 'cliente',
    );
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
      'propostaExpiresAt': null,
      'statusConfirmacaoValor': 'nenhum',
      'precoPropostoPrestador': null,
      'precoFinal': null,
      'commissionPlatform': null,
      'earningsProvider': null,
      'earningsTotal': null,
      ..._statusPatch('aguarda_resposta_prestador'),
      ..._historyPatch(
        evento: 'convite_enviado',
        userId: clienteId,
        descricao: 'Cliente convidou prestador manualmente',
      ),
    });

    await _logPedidoEvent(
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
    if (pedido.prestadorId != null && pedido.prestadorId != prestadorId) {
      throw Exception('Convite nao pertence a este prestador.');
    }

    _assertOwnership(
      pedido: pedido,
      userId: prestadorId,
      role: 'prestador',
    );

    // Business rule: convite nao deve permitir aceitar servicos fora das categorias do prestador
    await _assertPrestadorMatchesPedido(
      pedido: pedido,
      prestadorId: prestadorId,
    );

    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aceito,
      role: 'prestador',
    );
    await _colPedidos.doc(pedido.id).update({
      'prestadorId': prestadorId,
      ..._statusPatch('aceito'),
      ..._historyPatch(
        evento: 'convite_aceite',
        userId: prestadorId,
        descricao: 'Prestador aceitou o convite',
      ),
    });

    await _logPedidoEvent(
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
    if (pedido.prestadorId != null && pedido.prestadorId != prestadorId) {
      return;
    }

    _assertOwnership(
      pedido: pedido,
      userId: prestadorId,
      role: 'prestador',
    );
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
      'propostaExpiresAt': null,
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
      ..._historyPatch(
        evento: 'convite_recusado',
        userId: prestadorId,
        descricao: 'Prestador recusou o convite',
      ),
    });

    await _logPedidoEvent(
      name: 'pedido_convite_recusado',
      pedidoId: pedido.id,
      estado: 'criado',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'prestador',
    );
  }

  /// 3e) PRESTADOR ACEITA PEDIDO ABERTO (Feed)
  Future<void> aceitarPedidoAberto({
    required Pedido pedido,
    required String prestadorId,
  }) async {
    // Validar que o pedido está livre
    if (pedido.prestadorId != null) {
      throw Exception('Este pedido ja tem prestador atribuido.');
    }

    // Não usamos _assertOwnership aqui porque o prestador ainda não está no pedido
    // Mas validamos a transição
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aceito,
      role: 'prestador',
    );

    await _assertPrestadorMatchesPedido(
      pedido: pedido,
      prestadorId: prestadorId,
    );

    await _colPedidos.doc(pedido.id).update({
      'prestadorId': prestadorId,
      ..._statusPatch('aceito'),
      ..._historyPatch(
        evento: 'pedido_aceite',
        userId: prestadorId,
        descricao: 'Prestador aceitou o pedido (feed)',
      ),
    });

    await _logPedidoEvent(
      name: 'pedido_aceite_feed',
      pedidoId: pedido.id,
      estado: 'aceito',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'prestador',
    );
  }

  /// 4) PRESTADOR → INICIA o serviço
  ///
  /// Resultado:
  /// - status = "em_andamento"
  Future<void> iniciarServico({
    required Pedido pedido,
    required String prestadorId,
  }) async {
    _assertOwnership(
      pedido: pedido,
      userId: prestadorId,
      role: 'prestador',
    );
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.emAndamento,
      role: 'prestador',
    );
    await _colPedidos.doc(pedido.id).update({
      ..._statusPatch('em_andamento'),
      ..._historyPatch(
        evento: 'servico_iniciado',
        userId: prestadorId,
        descricao: 'Prestador iniciou o serviço',
      ),
    });

    await _logPedidoEvent(
      name: 'pedido_iniciado',
      pedidoId: pedido.id,
      estado: 'em_andamento',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'prestador',
    );
  }

  /// Alias para manter compatibilidade com código antigo
  Future<void> iniciarPedido({
    required Pedido pedido,
    required String prestadorId,
  }) {
    return iniciarServico(pedido: pedido, prestadorId: prestadorId);
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
    required String prestadorId,
    String? comentario,
  }) async {
    if (valorFinal <= 0) {
      throw Exception('Valor final deve ser maior que zero.');
    }

    _assertOwnership(
      pedido: pedido,
      userId: prestadorId,
      role: 'prestador',
    );
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
      ..._historyPatch(
        evento: 'valor_proposto',
        userId: prestadorId,
        descricao: 'Prestador propôs valor final: $valorFinal€',
      ),
    });

    await _logPedidoEvent(
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
    required String clienteId,
    required double valorFinal,
  }) async {
    // Validação extra: o valor confirmado tem de bater com o proposto?
    // ou aceitamos o valor que vem da UI (desde que > 0)?
    // Vamos garantir consistência com o que está no pedido para segurança.
    if (pedido.precoPropostoPrestador != null) {
      // Margem de erro mínima para double
      if ((pedido.precoPropostoPrestador! - valorFinal).abs() > 0.01) {
        throw Exception('Valor confirmado difere do valor proposto.');
      }
    }

    _assertOwnership(
      pedido: pedido,
      userId: clienteId,
      role: 'cliente',
    );

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
      ..._historyPatch(
        evento: 'concluido',
        userId: clienteId,
        descricao:
            'Cliente confirmou valor final ($valorFinal€) e concluiu pedido',
      ),
    });

    await _logPedidoEvent(
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
  Future<void> cancelarPorCliente({
    required Pedido pedido,
    required String clienteId,
    required String motivo,
    required String tipoReembolso,
    String? motivoDetalhe,
    bool motivoIsId = false,
  }) async {
    _assertOwnership(pedido: pedido, userId: clienteId, role: 'cliente');

    await PedidosRepo.cancelarPedido(
      pedidoId: pedido.id,
      userId: clienteId,
      role: 'cliente',
      motivo: motivoIsId ? motivo : motivo.trim(),
      motivoDetalhe: motivoDetalhe?.trim(),
      tipoReembolso: tipoReembolso,
    );

    // Analytics mantido no Service ou movido?
    // Por agora mantemos aqui para não perder rastreio específico de 'cliente'
    await _logPedidoEvent(
      name: 'pedido_cancelado_cliente',
      pedidoId: pedido.id,
      estado: 'cancelado',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'cliente',
    );
  }

  /// 8) PRESTADOR → cancela / desiste do pedido
  Future<void> cancelarPorPrestador({
    required Pedido pedido,
    required String prestadorId,
    required String motivo,
    required String tipoReembolso,
    String? motivoDetalhe,
    bool motivoIsId = false,
  }) async {
    _assertOwnership(pedido: pedido, userId: prestadorId, role: 'prestador');

    final estado = pedido.estado;

    // Lógica de "Desistência" (early cancel) vs "Cancelamento" (late cancel)
    // Se "desistência", o pedido volta a criado. Se "cancelamento", morre.
    // O Repo suporta apenas "Cancelamento" (estado final).
    // Pelo mapa de fases B2, queremos 'política de cancelamento'.
    // Vou manter a lógica de 'Desistência' AQUI no Service (que faz update manual para 'criado')
    // e usar o Repo APENAS para o cancelamento definitivo.

    if (estado == 'criado' ||
        estado == 'aguarda_resposta_cliente' ||
        estado == 'aguarda_resposta_prestador' ||
        estado == 'aceito') {
      // --- Lógica de Desistência (volta a procurar) ---
      // (Mantém-se implementação manual pois o Repo.cancelarPedido força estado 'cancelado')

      _ensureTransition(
        pedido: pedido,
        to: PedidoStateMachine.criado,
        role: 'prestador',
      );

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
        'propostaExpiresAt': null,
        'statusConfirmacaoValor': 'nenhum',
        'canceladoPor': null,
        'motivoCancelamento': null,
        'motivoCancelamentoDetalhe': null,
        'tipoReembolso': null,
        'ultimoCancelamentoPrestadorId': pedido.prestadorId,
        'ultimoCancelamentoPrestadorMotivo':
            motivoIsId ? motivo : motivo.trim(),
        'ultimoCancelamentoPrestadorMotivoDetalhe': motivoDetalhe?.trim(),
        'ultimoCancelamentoPrestadorEm': FieldValue.serverTimestamp(),
        ..._historyPatch(
          evento: 'desistencia_prestador',
          userId: prestadorId,
          descricao: 'Prestador desistiu/cancelou: $motivo',
        ),
      });

      await _logPedidoEvent(
        name: 'pedido_desistido_prestador',
        pedidoId: pedido.id,
        estado: 'criado',
        modo: pedido.modo,
        tipoPreco: pedido.tipoPreco,
        role: 'prestador',
      );
    } else {
      // --- Lógica de Cancelamento Definitivo (usa Repo) ---

      await PedidosRepo.cancelarPedido(
        pedidoId: pedido.id,
        userId: prestadorId,
        role: 'prestador',
        motivo: motivoIsId ? motivo : motivo.trim(),
        motivoDetalhe: motivoDetalhe?.trim(),
        tipoReembolso: tipoReembolso,
      );

      await _logPedidoEvent(
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
      ..._historyPatch(
        evento: 'noshow',
        userId: 'admin', // ou quem reportou? Idealmente ter o ID de quem chama
        descricao: '$role reportou No-Show: $motivo',
      ),
    });

    await _logPedidoEvent(
      name: 'pedido_noshow_reportado',
      pedidoId: pedido.id,
      estado: pedido.estado,
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: role,
    );
  }
}
