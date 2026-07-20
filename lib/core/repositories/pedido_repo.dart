// lib/core/repositories/pedido_repo.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../config/app_config.dart';
import '../models/pedido.dart';
import '../services/analytics_service.dart';
import '../utils/pedido_state_machine.dart';

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
    return _db.collection('pedidos').doc(pedidoId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return Pedido.fromMap(doc.id, data);
    });
  }

  static Stream<List<Pedido>> streamPedidosDoCliente(String clienteId) {
    return _db
        .collection('pedidos')
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map((s) {
      final pedidos =
          s.docs.map((d) => Pedido.fromMap(d.id, d.data())).toList();
      pedidos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pedidos;
    });
  }

  static Stream<List<Pedido>> streamPedidosDisponiveis() {
    return _db
        .collection('pedido_dispatch')
        // Projecao sanitizada: nunca contem cliente, morada ou GPS exato.
        .where('status', isEqualTo: 'criado')
        .where('prestadorId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Pedido.fromMap(d.id, d.data())).toList());
  }

  static Future<void> aceitarPedido({
    required String pedidoId,
    required String prestadorId,
  }) async {
    final ref = _db.collection('pedidos').doc(pedidoId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('Pedido nao encontrado.');
      }
      final doc = snap.data();
      final estado = (doc?['estado'] ?? doc?['status'] ?? 'criado').toString();
      if (!PedidoStateMachine.canTransitionForRole(
        role: 'prestador',
        from: estado,
        to: PedidoStateMachine.aceito,
      )) {
        throw StateError('Transicao invalida: $estado -> aceito');
      }

      tx.update(ref, {
        'prestadorId': prestadorId,
        'estado': 'aceito',
        'status': 'aceito',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> iniciarPedido({required String pedidoId}) async {
    final ref = _db.collection('pedidos').doc(pedidoId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('Pedido nao encontrado.');
      }
      final doc = snap.data();
      final estado = (doc?['estado'] ?? doc?['status'] ?? 'criado').toString();
      if (!PedidoStateMachine.canTransitionForRole(
        role: 'prestador',
        from: estado,
        to: PedidoStateMachine.emAndamento,
      )) {
        throw StateError('Transicao invalida: $estado -> em_andamento');
      }

      tx.update(ref, {
        'estado': 'em_andamento',
        'status': 'em_andamento',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> concluirPedido({
    required String pedidoId,
    required double preco,
  }) async {
    final ref = _db.collection('pedidos').doc(pedidoId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('Pedido nao encontrado.');
      }
      final doc = snap.data();
      final estado = (doc?['estado'] ?? doc?['status'] ?? 'criado').toString();
      if (!PedidoStateMachine.canTransitionForRole(
        role: 'sistema',
        from: estado,
        to: PedidoStateMachine.concluido,
      )) {
        throw StateError('Transicao invalida: $estado -> concluido');
      }

      tx.update(ref, {
        'estado': 'concluido',
        'status': 'concluido',
        'preco': preco,
        'precoFinal': preco,
        'concluidoEm': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Stream<List<Pedido>> streamPedidosDoPrestador(String prestadorId) {
    return _db
        .collection('pedidos')
        .where('prestadorId', isEqualTo: prestadorId)
        // Descendente para bater com o índice (prestadorId ASC + createdAt DESC)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Pedido.fromMap(d.id, d.data())).toList());
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
    final docRef = _db.collection('pedidos').doc(pedidoId);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Pedido não encontrado para cancelar.');
      }

      final data = snapshot.data()!;
      final currentStatus = data['status'] as String? ?? 'criado';

      // 1. Validar transição
      PedidoStateMachine.assertTransition(
        role: role,
        from: currentStatus,
        to: PedidoStateMachine.cancelado,
      );

      // 2. Updates
      final updates = <String, dynamic>{
        'status': PedidoStateMachine.cancelado,
        'estado': PedidoStateMachine.cancelado, // Manter consistência
        'updatedAt': FieldValue.serverTimestamp(),
        'canceladoPor': role,
        'motivoCancelamento': motivo,
      };

      if (tipoReembolso != null) {
        updates['tipoReembolso'] = tipoReembolso;
      }

      // Adicionar evento ao histórico
      // Precisamos importar PedidoHistoricoItem se não estiver importado,
      // mas como estava no código anterior, assumo que está ok ou vou usar Map direto para evitar erros de import.
      final novoEvento = <String, dynamic>{
        'evento': PedidoStateMachine.cancelado,
        'timestamp': Timestamp.now(),
        'userId': userId,
        'descricao': motivoDetalhe != null ? '$motivo: $motivoDetalhe' : motivo,
      };

      updates['historico'] = FieldValue.arrayUnion([novoEvento]);

      transaction.update(docRef, updates);

      // Analytics
      unawaited(
        AnalyticsService.instance.logPedidoEvent(
          name: 'pedido_cancelado',
          pedidoId: pedidoId,
          estado: 'cancelado',
          role: role,
          modo: data['modo'] ?? '?',
          tipoPreco: data['tipoPreco'] ?? '?',
        ),
      );
    });
  }
}
