// lib/core/repositories/pedido_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido.dart';
import '../services/analytics_service.dart';
import '../utils/geohash_utils.dart';
import '../utils/pedido_state_machine.dart';

class PedidosRepo {
  PedidosRepo._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  }) async {
    final categoriaFinal =
        (servicoNome != null && servicoNome.trim().isNotEmpty)
            ? servicoNome.trim()
            : (categoria ?? '').trim();

    final Timestamp? agTs =
        (modo == 'AGENDADO' && agendadoPara != null)
            ? Timestamp.fromDate(agendadoPara)
            : null;

    final geo = (latitude != null && longitude != null)
        ? GeoHashUtils.toGeoData(latitude: latitude, longitude: longitude)
        : null;

    final statusFinal = status ?? 'criado';
    if (!PedidoStateMachine.isValidEstado(statusFinal)) {
      throw ArgumentError('Estado invalido: $statusFinal');
    }

    final docRef = await _db.collection('pedidos').add({
      'clienteId': clienteId,
      'prestadorId': prestadorId,

      'servicoId': servicoId,
      'servicoNome': categoriaFinal.isEmpty ? null : categoriaFinal,
      'categoria': categoriaFinal.isEmpty ? null : categoriaFinal,

      'titulo': titulo,
      'descricao': descricao,
      'modo': modo,
      'agendadoPara': agTs,

      'tipoPreco': tipoPreco ?? 'a_combinar',
      'tipoPagamento': tipoPagamento ?? 'dinheiro',

      'estado': statusFinal,
      'status': statusFinal,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),

      'latitude': latitude,
      'longitude': longitude,
      if (geo != null) 'geo': geo,
      'enderecoTexto': enderecoTexto,

      'statusProposta': 'nenhuma',
      'statusConfirmacaoValor': 'nenhum',
    });

    await AnalyticsService.instance.logPedidoEvent(
      name: 'pedido_criado',
      pedidoId: docRef.id,
      estado: statusFinal,
      modo: modo,
      tipoPreco: tipoPreco ?? 'a_combinar',
      role: 'cliente',
    );

    return docRef.id;
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
  }) async {
    final categoriaFinal =
        (servicoNome != null && servicoNome.trim().isNotEmpty)
            ? servicoNome.trim()
            : (categoria ?? '').trim();

    final Timestamp? agTs =
        (modo == 'AGENDADO' && agendadoPara != null)
            ? Timestamp.fromDate(agendadoPara)
            : null;

    final geo = (latitude != null && longitude != null)
        ? GeoHashUtils.toGeoData(latitude: latitude, longitude: longitude)
        : null;

    final data = <String, dynamic>{
      'titulo': titulo,
      'descricao': descricao,
      'modo': modo,
      'agendadoPara': agTs,

      'servicoId': servicoId,
      'servicoNome': categoriaFinal.isEmpty ? null : categoriaFinal,
      'categoria': categoriaFinal.isEmpty ? null : categoriaFinal,

      'latitude': latitude,
      'longitude': longitude,
      // mantém geo consistente com lat/lng
      'geo': geo ?? FieldValue.delete(),
      'enderecoTexto': enderecoTexto,

      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (tipoPreco != null) data['tipoPreco'] = tipoPreco;
    if (tipoPagamento != null) data['tipoPagamento'] = tipoPagamento;
    final ref = _db.collection('pedidos').doc(pedidoId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('Pedido nao encontrado.');
      }
      final doc = snap.data();
      final estado = (doc?['estado'] ?? doc?['status'] ?? 'criado').toString();
      if (estado != PedidoStateMachine.criado) {
        throw StateError('Nao podes editar pedido em estado: $estado');
      }
      tx.update(ref, data);
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Pedido.fromMap(d.id, d.data())).toList());
  }

  static Stream<List<Pedido>> streamPedidosDisponiveis() {
    return _db
        .collection('pedidos')
        .where('estado', isEqualTo: 'criado')
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
}
