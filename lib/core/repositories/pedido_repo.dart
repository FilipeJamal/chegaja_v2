// lib/core/repositories/pedido_repo.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/pedido.dart';
import '../services/analytics_service.dart';

class PedidosRepo {
  PedidosRepo._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  static Future<String> criarPedido({
    required String clienteId,
    String? prestadorId,
    String? status,
    String? servicoId,
    String? servicoNome,
    required String titulo,
    String? descricao,
    required String modo, // IMEDIATO | AGENDADO
    DateTime? agendadoPara,
    String? categoria,
    double? latitude,
    double? longitude,
    String? enderecoTexto,
    String? tipoPreco,
    String? tipoPagamento,
    List<String>? anexos,
    bool categoryApprovalRequired = false,
    String? categoryRequirementId,
    String? categoryRequirementName,
    String? categoryRiskLevel,
    bool isCustomService = false,
    String? customServiceName,
    String? customServiceDescription,
    List<String>? customServiceSearchTerms,
  }) async {
    final Timestamp? agTs = (modo == 'AGENDADO' && agendadoPara != null)
        ? Timestamp.fromDate(agendadoPara)
        : null;
    final response =
        await _functions.httpsCallable('pedidos_createSecure').call({
      'prestadorId': prestadorId,
      'servicoId': servicoId,
      'servicoNome': servicoNome ?? categoria,
      'titulo': titulo,
      'descricao': descricao,
      'modo': modo,
      'agendadoPara': agTs,
      'tipoPreco': tipoPreco ?? 'a_combinar',
      'tipoPagamento': tipoPagamento ?? 'dinheiro',
      'latitude': latitude,
      'longitude': longitude,
      'enderecoTexto': enderecoTexto,
      if (anexos != null) 'anexos': anexos,
      'isCustomService': isCustomService,
      'customServiceName': customServiceName,
      'customServiceDescription': customServiceDescription,
      'customServiceSearchTerms': customServiceSearchTerms ?? const <String>[],
    });
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final pedidoId = (responseData['pedidoId'] as String?)?.trim();
    if (pedidoId == null || pedidoId.isEmpty) {
      throw StateError('O servidor nao devolveu o identificador do pedido.');
    }

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_criado',
      pedidoId: pedidoId,
      estado: status ?? 'criado',
      modo: modo,
      tipoPreco: tipoPreco ?? 'a_combinar',
      role: 'cliente',
    );

    return pedidoId;
  }

  static Future<void> atualizarPedidoCliente({
    required String pedidoId,
    required String titulo,
    String? servicoId,
    String? servicoNome,
    String? descricao,
    required String modo,
    DateTime? agendadoPara,
    String? categoria,
    double? latitude,
    double? longitude,
    String? enderecoTexto,
    String? tipoPreco,
    String? tipoPagamento,
    List<String>? anexos,
    bool? isCustomService,
    String? customServiceName,
    String? customServiceDescription,
    List<String>? customServiceSearchTerms,
  }) async {
    final Timestamp? agTs = (modo == 'AGENDADO' && agendadoPara != null)
        ? Timestamp.fromDate(agendadoPara)
        : null;
    await _functions.httpsCallable('pedidos_updateSecure').call({
      'pedidoId': pedidoId,
      'titulo': titulo,
      'descricao': descricao,
      'modo': modo,
      'agendadoPara': agTs,

      'servicoId': servicoId,
      'servicoNome': servicoNome ?? categoria,

      'latitude': latitude,
      'longitude': longitude,
      // mantém geo consistente com lat/lng
      'enderecoTexto': enderecoTexto,
      if (anexos != null) 'anexos': anexos,

      if (tipoPreco != null) 'tipoPreco': tipoPreco,
      if (tipoPagamento != null) 'tipoPagamento': tipoPagamento,
      if (isCustomService != null) 'isCustomService': isCustomService,
      'customServiceName': customServiceName,
      'customServiceDescription': customServiceDescription,
      'customServiceSearchTerms': customServiceSearchTerms ?? const <String>[],
    });
  }

  static Stream<Pedido?> streamPedidoPorId(String pedidoId) {
    late StreamController<Pedido?> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? privateSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? dispatchSub;
    Pedido? privatePedido;
    Pedido? dispatchPedido;
    var privateResolved = false;
    var dispatchResolved = false;
    var retryingPrivateAfterGrant = false;

    void emitBestView() {
      if (controller.isClosed || retryingPrivateAfterGrant) return;
      if (privatePedido != null) {
        controller.add(privatePedido);
        return;
      }
      if (dispatchPedido != null) {
        controller.add(dispatchPedido);
        return;
      }
      if (privateResolved && dispatchResolved) controller.add(null);
    }

    Future<void> subscribePrivate({bool afterDispatchRemoval = false}) async {
      retryingPrivateAfterGrant = afterDispatchRemoval;
      privateResolved = false;
      privatePedido = null;
      await privateSub?.cancel();
      if (controller.isClosed) return;
      privateSub = _db.collection('pedidos').doc(pedidoId).snapshots().listen(
        (doc) {
          privateResolved = true;
          retryingPrivateAfterGrant = false;
          final data = doc.data();
          privatePedido = data == null ? null : Pedido.fromMap(doc.id, data);
          emitBestView();
        },
        onError: (Object error, StackTrace stackTrace) {
          privateResolved = true;
          retryingPrivateAfterGrant = false;
          privatePedido = null;
          if (error is! FirebaseException ||
              error.code != 'permission-denied') {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          }
          emitBestView();
        },
      );
    }

    controller = StreamController<Pedido?>(
      onListen: () {
        unawaited(subscribePrivate());
        dispatchSub =
            _db.collection('pedido_dispatch').doc(pedidoId).snapshots().listen(
          (doc) {
            final previouslyTargeted = dispatchPedido != null;
            dispatchResolved = true;
            final data = doc.data();
            dispatchPedido = data == null ? null : Pedido.fromMap(doc.id, data);
            if (previouslyTargeted && dispatchPedido == null) {
              // A callable cria o grant no pedido antes de o trigger remover a
              // projecao. Uma nova subscricao passa entao a receber a vista
              // integral; se outro Prestador aceitou, termina em null.
              unawaited(subscribePrivate(afterDispatchRemoval: true));
              return;
            }
            emitBestView();
          },
          onError: (Object error, StackTrace stackTrace) {
            dispatchResolved = true;
            dispatchPedido = null;
            if (error is! FirebaseException ||
                error.code != 'permission-denied') {
              if (!controller.isClosed) controller.addError(error, stackTrace);
            }
            emitBestView();
          },
        );
      },
      onCancel: () async {
        await privateSub?.cancel();
        await dispatchSub?.cancel();
      },
    );
    return controller.stream;
  }

  static Stream<List<Pedido>> streamPedidosDoCliente(String clienteId) {
    return _db
        .collection('pedidos')
        .where('clienteId', isEqualTo: clienteId)
        .limit(200)
        .snapshots()
        .map((s) {
      final pedidos =
          s.docs.map((d) => Pedido.fromMap(d.id, d.data())).toList();
      pedidos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pedidos;
    });
  }

  static Stream<List<Pedido>> streamPedidosDisponiveis() {
    return availableDispatchQuery(_db)
        // Projecao sanitizada: nunca contem cliente, morada ou GPS exato.
        .snapshots()
        .map((s) => s.docs.map((d) => Pedido.fromMap(d.id, d.data())).toList());
  }

  @visibleForTesting
  static Query<Map<String, dynamic>> availableDispatchQuery(
    FirebaseFirestore database, {
    String? marketId,
    String? currency,
  }) {
    return database
        .collection('pedido_dispatch')
        .where(
          'marketId',
          isEqualTo: marketId ?? AppConfig.pilotMarket.id,
        )
        .where(
          'currency',
          isEqualTo: currency ?? AppConfig.pilotMarket.currencyCode,
        )
        .where('status', isEqualTo: 'criado')
        .where('prestadorId', isNull: true)
        .where('targetProviderId', isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(100);
  }

  static Future<void> aceitarPedido({
    required String pedidoId,
    required String prestadorId,
  }) async {
    if (prestadorId.trim().isEmpty) {
      throw ArgumentError.value(prestadorId, 'prestadorId');
    }
    await _functions.httpsCallable('pedidos_acceptDispatch').call({
      'pedidoId': pedidoId,
    });
  }

  static Future<void> iniciarPedido({required String pedidoId}) async {
    await _functions.httpsCallable('pedidos_applyActionSecure').call({
      'pedidoId': pedidoId,
      'action': 'provider_start_service',
    });
  }

  static Future<void> concluirPedido({
    required String pedidoId,
    required double preco,
  }) async {
    if (!preco.isFinite || preco <= 0) {
      throw ArgumentError.value(preco, 'preco');
    }
    // O backend confirma o valor que está persistido no pedido; nunca confia
    // no preço recebido por esta API legada.
    await _functions.httpsCallable('confirmarValorFinalPedido').call({
      'pedidoId': pedidoId,
    });
  }

  static Stream<List<Pedido>> streamPedidosDoPrestador(String prestadorId) {
    late StreamController<List<Pedido>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? privateSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? targetedSub;
    var privatePedidos = <Pedido>[];
    var targetedPedidos = <Pedido>[];

    void emitCombined() {
      final byId = <String, Pedido>{
        for (final pedido in targetedPedidos) pedido.id: pedido,
        for (final pedido in privatePedidos) pedido.id: pedido,
      };
      final pedidos = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) controller.add(pedidos);
    }

    controller = StreamController<List<Pedido>>(
      onListen: () {
        privateSub = _db
            .collection('pedidos')
            .where('prestadorId', isEqualTo: prestadorId)
            .where('providerAccessGranted', isEqualTo: true)
            .where('providerAccessGrantedTo', isEqualTo: prestadorId)
            .where(
              'status',
              whereIn: const [
                'aceito',
                'em_andamento',
                'aguarda_confirmacao_valor',
                'concluido',
              ],
            )
            .where(
              'providerAccessGrantedAt',
              isGreaterThan: Timestamp.fromMillisecondsSinceEpoch(0),
            )
            .where(
              'providerAccessGrantedAt',
              isLessThan: Timestamp.fromDate(DateTime.utc(2100)),
            )
            .orderBy('providerAccessGrantedAt', descending: true)
            .limit(200)
            .snapshots()
            .listen(
              (snapshot) {
                privatePedidos = snapshot.docs
                    .map((doc) => Pedido.fromMap(doc.id, doc.data()))
                    .toList();
                emitCombined();
              },
              onError: controller.addError,
            );
        targetedSub = targetedDispatchQuery(_db, prestadorId)
            .snapshots()
            .listen(
          (snapshot) {
            targetedPedidos = snapshot.docs
                .map((doc) => Pedido.fromMap(doc.id, doc.data()))
                .toList();
            emitCombined();
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await privateSub?.cancel();
        await targetedSub?.cancel();
      },
    );
    return controller.stream;
  }

  @visibleForTesting
  static Query<Map<String, dynamic>> targetedDispatchQuery(
    FirebaseFirestore database,
    String prestadorId, {
    String? marketId,
    String? currency,
  }) {
    return database
        .collection('pedido_dispatch')
        .where(
          'marketId',
          isEqualTo: marketId ?? AppConfig.pilotMarket.id,
        )
        .where(
          'currency',
          isEqualTo: currency ?? AppConfig.pilotMarket.currencyCode,
        )
        .where('targetProviderId', isEqualTo: prestadorId)
        .where('prestadorId', isNull: true)
        .limit(100);
  }

  /// Cancela o pedido (Cliente ou Prestador).
  /// Cancela o pedido com motivo e detalhe.
  static Future<void> cancelarPedido({
    required String pedidoId,
    required String userId,
    required String role,
    required String motivo,
    String? motivoDetalhe,
    String? tipoReembolso,
  }) async {
    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole != 'cliente' && normalizedRole != 'prestador') {
      throw ArgumentError.value(role, 'role');
    }
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId');
    }
    await _functions.httpsCallable('pedidos_applyActionSecure').call({
      'pedidoId': pedidoId,
      'action':
          normalizedRole == 'cliente' ? 'client_cancel' : 'provider_cancel',
      'motivo': motivo.trim(),
      if (motivoDetalhe != null && motivoDetalhe.trim().isNotEmpty)
        'motivoDetalhe': motivoDetalhe.trim(),
    });
  }
}
