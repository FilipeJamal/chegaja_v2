import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pedido.dart';

class PedidosRepo {
  PedidosRepo._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Criar pedido completo (usado pelo formulário do cliente).
  static Future<String> criarPedido({
    required String clienteId,
    required String titulo,
    String? descricao,
    required String modo, // 'IMEDIATO' ou 'AGENDADO'
    DateTime? agendadoPara,
    String? categoria,
  }) async {
    final docRef = await _db.collection('pedidos').add({
      'clienteId': clienteId,
      'prestadorId': null,
      'titulo': titulo,
      'descricao': descricao,
      'modo': modo,
      'estado': 'criado',
      'createdAt': FieldValue.serverTimestamp(),
      'agendadoPara': agendadoPara,
      'categoria': categoria,
      'preco': null,
      'concluidoEm': null,
    });

    return docRef.id;
  }

  /// Ainda deixamos o pedido de teste (se quisermos usar em debug).
  static Future<String> criarPedidoTeste({required String clienteId}) async {
    return criarPedido(
      clienteId: clienteId,
      titulo: 'Pedido de teste – Canalizador',
      descricao: 'Criado a partir do app ChegaJá v2 (teste rápido)',
      modo: 'IMEDIATO',
      agendadoPara: null,
      categoria: 'Canalizador',
    );
  }

  /// Atualizar pedido pelo cliente (título, descrição, modo, data, categoria).
  static Future<void> atualizarPedidoCliente({
    required String pedidoId,
    required String titulo,
    String? descricao,
    required String modo,
    DateTime? agendadoPara,
    String? categoria,
  }) async {
    await _db.collection('pedidos').doc(pedidoId).update({
      'titulo': titulo,
      'descricao': descricao,
      'modo': modo,
      'agendadoPara': agendadoPara,
      'categoria': categoria,
    });
  }

  /// Cancelar pedido pelo cliente (marca estado como 'cancelado').
  static Future<void> cancelarPedidoCliente({
    required String pedidoId,
  }) async {
    await _db.collection('pedidos').doc(pedidoId).update({
      'estado': 'cancelado',
      'canceladoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Stream com um único pedido (para o ecrã de detalhe).
  static Stream<Pedido?> streamPedidoPorId(String pedidoId) {
    return _db.collection('pedidos').doc(pedidoId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return Pedido.fromMap(doc.id, data as Map<String, dynamic>);
    });
  }

  /// Stream com todos os pedidos do cliente, ordenados por data (mais recentes primeiro).
  static Stream<List<Pedido>> streamPedidosDoCliente(String clienteId) {
    return _db
        .collection('pedidos')
        .where('clienteId', isEqualTo: clienteId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Pedido.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Stream de pedidos "disponíveis" para prestadores:
  /// todos os pedidos com estado = 'criado' e sem prestador atribuído.
  static Stream<List<Pedido>> streamPedidosDisponiveis() {
    return _db
        .collection('pedidos')
        .where('estado', isEqualTo: 'criado')
        .where('prestadorId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Pedido.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Aceitar um pedido: define prestadorId e muda o estado para 'aceito'.
  static Future<void> aceitarPedido({
    required String pedidoId,
    required String prestadorId,
  }) async {
    await _db.collection('pedidos').doc(pedidoId).update({
      'prestadorId': prestadorId,
      'estado': 'aceito',
    });
  }

  /// Marcar pedido como "em andamento".
  static Future<void> iniciarPedido({
    required String pedidoId,
  }) async {
    await _db.collection('pedidos').doc(pedidoId).update({
      'estado': 'em_andamento',
    });
  }

  /// Concluir pedido: define estado 'concluido', guarda preço e data de conclusão.
  static Future<void> concluirPedido({
    required String pedidoId,
    required double preco,
  }) async {
    await _db.collection('pedidos').doc(pedidoId).update({
      'estado': 'concluido',
      'preco': preco,
      'concluidoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Stream de pedidos que foram aceites por um prestador específico.
  /// Usamos createdAt em ORDEM CRESCENTE para combinar com o índice existente.
  static Stream<List<Pedido>> streamPedidosDoPrestador(String prestadorId) {
    return _db
        .collection('pedidos')
        .where('prestadorId', isEqualTo: prestadorId)
        .orderBy('createdAt') // ascending (default)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Pedido.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }
}
