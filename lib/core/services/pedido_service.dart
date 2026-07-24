// lib/core/services/pedido_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_normalizer.dart';
import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/core/services/analytics_service.dart';
import 'package:chegaja_v2/core/utils/pedido_state_machine.dart';

abstract class PedidoValueFunctionsGateway {
  Future<void> applyAction({
    required String pedidoId,
    required String action,
    Map<String, dynamic> data = const <String, dynamic>{},
  });

  Future<void> aceitarPedidoDispatch({required String pedidoId});

  Future<void> proporValorFinalPedido({
    required String pedidoId,
    required double valorFinal,
    String? comentario,
  });

  Future<void> confirmarValorFinalPedido({required String pedidoId});
}

class FirebasePedidoValueFunctionsGateway
    implements PedidoValueFunctionsGateway {
  FirebasePedidoValueFunctionsGateway({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _functions;

  HttpsCallable _callable(String name) => _functions.httpsCallable(name);

  @override
  Future<void> applyAction({
    required String pedidoId,
    required String action,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) async {
    await _callable('pedidos_applyActionSecure').call({
      'pedidoId': pedidoId,
      'action': action,
      ...data,
    });
  }

  @override
  Future<void> aceitarPedidoDispatch({required String pedidoId}) async {
    await _callable('pedidos_acceptDispatch').call({'pedidoId': pedidoId});
  }

  @override
  Future<void> proporValorFinalPedido({
    required String pedidoId,
    required double valorFinal,
    String? comentario,
  }) async {
    await _callable('proporValorFinalPedido').call({
      'pedidoId': pedidoId,
      'valorFinal': valorFinal,
      if (comentario != null && comentario.trim().isNotEmpty)
        'comentario': comentario.trim(),
    });
  }

  @override
  Future<void> confirmarValorFinalPedido({required String pedidoId}) async {
    await _callable('confirmarValorFinalPedido').call({
      'pedidoId': pedidoId,
    });
  }
}

/// Serviço central de fluxo de pedidos:
/// - Prestador envia faixa de preço (mín/máx)
/// - Cliente aceita / rejeita prestador
/// - Prestador inicia serviço
/// - Prestador lança valor final
/// - Cliente confirma valor final
/// - Backend persiste a economia autoritativa depois da confirmação
/// - Cliente / Prestador podem cancelar o pedido antes de concluir
class PedidoService {
  PedidoService({
    FirebaseFirestore? firestore,
    bool trackAnalytics = true,
    PedidoValueFunctionsGateway? valueFunctionsGateway,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _trackAnalytics = trackAnalytics,
        _valueFunctionsGateway = valueFunctionsGateway;

  PedidoService._()
      : _db = FirebaseFirestore.instance,
        _trackAnalytics = true,
        _valueFunctionsGateway = null;

  static final PedidoService instance = PedidoService._();

  final FirebaseFirestore _db;
  final bool _trackAnalytics;
  final PedidoValueFunctionsGateway? _valueFunctionsGateway;

  PedidoValueFunctionsGateway get _authoritativeValueFunctions =>
      _valueFunctionsGateway ?? FirebasePedidoValueFunctionsGateway();

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
    final snap = await _db.collection('provider_public').doc(prestadorId).get();
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
    final customServiceSearchTerms =
        (data?['customServiceSearchTerms'] as List?)
                ?.map((e) => ServiceTaxonomyNormalizer.normalize(e.toString()))
                .where((e) => e.isNotEmpty)
                .toSet() ??
            <String>{};

    final servicoId = pedido.servicoId.trim();
    final servicoNome = (pedido.servicoNome ?? pedido.categoria ?? '').trim();
    final approvedSensitiveCategoryIds =
        (data?['approvedSensitiveCategoryIds'] as List?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toSet() ??
            <String>{};

    final genericOther = _isGenericOtherService(
      servicoId: servicoId,
      servicoNome: servicoNome,
    );
    final pedidoCustomTerms = _pedidoCustomSearchTerms(pedido);
    final matchesByCustomTerms = pedidoCustomTerms.isNotEmpty &&
        customServiceSearchTerms.any(
          (providerTerm) => pedidoCustomTerms.any(
            (pedidoTerm) =>
                providerTerm == pedidoTerm ||
                providerTerm.contains(pedidoTerm) ||
                pedidoTerm.contains(providerTerm),
          ),
        );

    final matches = (!genericOther &&
            ((servicoId.isNotEmpty && ids.contains(servicoId)) ||
                (servicoNome.isNotEmpty && nomes.contains(servicoNome)))) ||
        matchesByCustomTerms;

    if (!matches) {
      final label = servicoNome.isNotEmpty
          ? servicoNome
          : (servicoId.isNotEmpty ? servicoId : 'este servico');
      throw Exception(
        'Nao podes aceitar este pedido: o teu perfil nao esta inscrito no servico "$label".',
      );
    }

    if (pedido.categoryApprovalRequired) {
      final requiredCategory =
          (pedido.categoryRequirementId ?? pedido.servicoId).trim();
      if (requiredCategory.isEmpty ||
          !approvedSensitiveCategoryIds.contains(requiredCategory)) {
        throw Exception(
          'Este servico exige prestador com aprovacao na categoria.',
        );
      }
    }
  }

  bool _isGenericOtherService({
    required String servicoId,
    required String servicoNome,
  }) {
    final normalizedName = ServiceTaxonomyNormalizer.normalize(servicoNome);
    return servicoId == 'other_service' &&
        (normalizedName.isEmpty || normalizedName == 'outro servico');
  }

  Set<String> _pedidoCustomSearchTerms(Pedido pedido) {
    final values = <String>[
      pedido.customServiceName ?? '',
      pedido.customServiceDescription ?? '',
      ...pedido.customServiceSearchTerms,
    ];
    if (pedido.isCustomService) {
      values.add(pedido.servicoNome ?? '');
    }
    return values
        .map(ServiceTaxonomyNormalizer.normalize)
        .where((term) => term.isNotEmpty && term != 'outro servico')
        .toSet();
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

    final validityMinutes = validity.inMinutes;
    if (validityMinutes < 15 || validityMinutes > 10080) {
      throw Exception(
        'A validade da proposta deve ficar entre 15 minutos e 7 dias.',
      );
    }

    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'provider_submit_quote',
      data: {
        'valorMin': valorMin,
        'valorMax': valorMax,
        if (mensagem != null && mensagem.trim().isNotEmpty)
          'mensagem': mensagem.trim(),
        'validadeMinutos': validityMinutes,
      },
    );

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
    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'client_accept_quote',
    );

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
    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'client_reject_quote',
    );

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
    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'client_invite_provider',
      data: {'prestadorId': prestadorId},
    );

    await _logPedidoEvent(
      name: 'pedido_convite_manual',
      pedidoId: pedido.id,
      estado: 'aguarda_resposta_prestador',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'cliente',
    );
  }

  /// Substitui, de forma autoritativa, um convite que ainda esta pendente.
  Future<void> trocarPrestadorConvidado({
    required Pedido pedido,
    required String clienteId,
    required String prestadorId,
  }) async {
    _assertOwnership(
      pedido: pedido,
      userId: clienteId,
      role: 'cliente',
    );
    if (pedido.estado != PedidoStateMachine.aguardaRespostaPrestador ||
        pedido.prestadorId == null) {
      throw StateError('O pedido nao tem um convite pendente para substituir.');
    }
    if (pedido.prestadorId == prestadorId) {
      throw StateError('Seleciona um prestador diferente.');
    }

    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'client_replace_invited_provider',
      data: {'prestadorId': prestadorId},
    );

    await _logPedidoEvent(
      name: 'pedido_convite_substituido',
      pedidoId: pedido.id,
      estado: PedidoStateMachine.aguardaRespostaPrestador,
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
    await _authoritativeValueFunctions.aceitarPedidoDispatch(
      pedidoId: pedido.id,
    );

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
    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'provider_decline_invite',
    );

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

    await _authoritativeValueFunctions.aceitarPedidoDispatch(
      pedidoId: pedido.id,
    );

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
    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'provider_start_service',
    );

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
    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.aguardaConfirmacaoValor,
      role: 'prestador',
    );

    await _authoritativeValueFunctions.proporValorFinalPedido(
      pedidoId: pedido.id,
      valorFinal: valorFinal,
      comentario: comentario,
    );

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
  /// - comissão/líquido calculados exclusivamente pela Function autoritativa
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

    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.concluido,
      role: 'cliente',
    );

    await _authoritativeValueFunctions.confirmarValorFinalPedido(
      pedidoId: pedido.id,
    );

    await _logPedidoEvent(
      name: 'pedido_concluido',
      pedidoId: pedido.id,
      estado: 'concluido',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'cliente',
    );
  }

  /// 6b) CLIENTE -> rejeita o valor final e devolve o pedido ao servico.
  ///
  /// Resultado:
  /// - statusConfirmacaoValor = "rejeitado_cliente"
  /// - status = "em_andamento"
  /// - prestador pode propor um novo valor final
  Future<void> rejeitarValorFinal({
    required Pedido pedido,
    required String clienteId,
    String? motivo,
  }) async {
    _assertOwnership(
      pedido: pedido,
      userId: clienteId,
      role: 'cliente',
    );

    if (pedido.precoPropostoPrestador == null) {
      throw Exception('Valor final proposto nao encontrado.');
    }

    if (pedido.statusConfirmacaoValor != 'pendente_cliente') {
      throw Exception('Valor final nao esta pendente de confirmacao.');
    }

    _ensureTransition(
      pedido: pedido,
      to: PedidoStateMachine.emAndamento,
      role: 'cliente',
    );

    final motivoTrim = motivo?.trim();
    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'client_reject_final_value',
      data: {
        if (motivoTrim != null && motivoTrim.isNotEmpty) 'motivo': motivoTrim,
      },
    );

    await _logPedidoEvent(
      name: 'pedido_valor_final_rejeitado',
      pedidoId: pedido.id,
      estado: 'em_andamento',
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

    // O cliente não decide reembolsos. O backend conserva esse parâmetro
    // apenas na API de compatibilidade e aplica a política financeira real.
    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'client_cancel',
      data: {
        'motivo': motivoIsId ? motivo : motivo.trim(),
        if (motivoDetalhe != null && motivoDetalhe.trim().isNotEmpty)
          'motivoDetalhe': motivoDetalhe.trim(),
      },
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

    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: 'provider_cancel',
      data: {
        'motivo': motivoIsId ? motivo : motivo.trim(),
        if (motivoDetalhe != null && motivoDetalhe.trim().isNotEmpty)
          'motivoDetalhe': motivoDetalhe.trim(),
      },
    );

    final withdrawalStates = {
      PedidoStateMachine.aguardaRespostaPrestador,
      PedidoStateMachine.aguardaRespostaCliente,
      PedidoStateMachine.aceito,
    };
    await _logPedidoEvent(
      name: withdrawalStates.contains(pedido.estado)
          ? 'pedido_desistido_prestador'
          : 'pedido_cancelado_prestador',
      pedidoId: pedido.id,
      estado: withdrawalStates.contains(pedido.estado) ? 'criado' : 'cancelado',
      modo: pedido.modo,
      tipoPreco: pedido.tipoPreco,
      role: 'prestador',
    );
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

    await _authoritativeValueFunctions.applyAction(
      pedidoId: pedido.id,
      action: role == 'cliente'
          ? 'client_report_no_show'
          : 'provider_report_no_show',
      data: {
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      },
    );

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
