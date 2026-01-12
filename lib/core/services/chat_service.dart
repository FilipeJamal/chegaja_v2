import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ⚠️ Se o teu ChatMessage estiver noutro caminho, ajusta este import.
import 'package:chegaja_v2/core/models/chat_message.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final ChatService instance = ChatService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _chatDoc(String pedidoId) =>
      _db.collection('chats').doc(pedidoId);

  CollectionReference<Map<String, dynamic>> _messagesCol(String pedidoId) =>
      _chatDoc(pedidoId).collection('messages');

  // ============================================================
  // META DO CHAT (garante que o doc chats/{pedidoId} existe)
  // ============================================================
  Future<void> ensureChatMetaForPedido(String pedidoId) async {
    final ref = _chatDoc(pedidoId);
    final snap = await ref.get();

    // Tenta carregar o pedido para preencher clienteId/prestadorId e título.
    Map<String, dynamic>? pedido;
    try {
      final pedidoSnap = await _db.collection('pedidos').doc(pedidoId).get();
      pedido = pedidoSnap.data();
    } catch (_) {
      pedido = null;
    }

    String? clienteId;
    String? prestadorId;
    String? pedidoTitulo;

    if (pedido != null) {
      final c = pedido['clienteId'];
      final p = pedido['prestadorId'];
      final t = pedido['titulo'] ?? pedido['pedidoTitulo'] ?? pedido['title'];

      if (c is String && c.trim().isNotEmpty) clienteId = c.trim();
      if (p is String && p.trim().isNotEmpty) prestadorId = p.trim();
      if (t is String && t.trim().isNotEmpty) pedidoTitulo = t.trim();
    }

    final now = FieldValue.serverTimestamp();

    if (!snap.exists) {
      await ref.set(
        {
          'pedidoId': pedidoId,
          if (clienteId != null) 'clienteId': clienteId,
          'prestadorId': prestadorId,
          if (pedidoTitulo != null) 'pedidoTitulo': pedidoTitulo,

          'createdAt': now,
          'updatedAt': now,
          'lastMessageAt': now,
          'lastMessage': '',
          'lastSenderRole': '',
          'hasUnreadCliente': false,
          'hasUnreadPrestador': false,
          'unreadByCliente': 0,
          'unreadByPrestador': 0,
        },
        SetOptions(merge: true),
      );
      return;
    }

    await ref.set(
      {
        'pedidoId': pedidoId,
        'updatedAt': now,
        if (clienteId != null && (snap.data()?['clienteId'] == null))
          'clienteId': clienteId,
        if ((snap.data()?['prestadorId'] == null))
          'prestadorId': prestadorId ?? snap.data()?['prestadorId'],
        if (pedidoTitulo != null && (snap.data()?['pedidoTitulo'] == null))
          'pedidoTitulo': pedidoTitulo,

        if (snap.data()?['lastMessageAt'] == null) 'lastMessageAt': now,
        if (snap.data()?['lastMessage'] == null) 'lastMessage': '',
        if (snap.data()?['lastSenderRole'] == null) 'lastSenderRole': '',
        if (snap.data()?['hasUnreadCliente'] == null) 'hasUnreadCliente': false,
        if (snap.data()?['hasUnreadPrestador'] == null) 'hasUnreadPrestador': false,
        if (snap.data()?['unreadByCliente'] == null) 'unreadByCliente': 0,
        if (snap.data()?['unreadByPrestador'] == null) 'unreadByPrestador': 0,
      },
      SetOptions(merge: true),
    );

    // Backfill preview (se já existiam msgs mas meta estava vazio)
    try {
      final data = snap.data() ?? <String, dynamic>{};
      final lastMessage = (data['lastMessage'] as String?) ?? '';

      if (lastMessage.trim().isEmpty) {
        final lastMsgQs = await _messagesCol(pedidoId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (lastMsgQs.docs.isNotEmpty) {
          final m = lastMsgQs.docs.first.data();
          final text = (m['text'] ?? m['texto'] ?? m['message'] ?? m['conteudo'] ?? '')
              .toString()
              .trim();
          final senderRole = (m['senderRole'] ?? '').toString();
          final createdAt = m['createdAt'];

          await ref.set(
            {
              'updatedAt': FieldValue.serverTimestamp(),
              if (text.isNotEmpty) 'lastMessage': text,
              if (createdAt is Timestamp)
                'lastMessageAt': createdAt
              else
                'lastMessageAt': FieldValue.serverTimestamp(),
              if (senderRole.isNotEmpty) 'lastSenderRole': senderRole,
            },
            SetOptions(merge: true),
          );
        }
      }
    } catch (_) {
      // ignora - é só para preview
    }
  }

  Future<void> ensureChatMeta(String pedidoId) => ensureChatMetaForPedido(pedidoId);

  // ============================================================
  // STREAMS
  // ============================================================
  Stream<List<ChatMessage>> streamMessagesForPedido(
    String pedidoId, {
    int limit = 200,
  }) {
    return _messagesCol(pedidoId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((qs) => qs.docs.map(ChatMessage.fromFirestore).toList());
  }

  Stream<List<ChatMessage>> streamMessages(String pedidoId, {int limit = 200}) =>
      streamMessagesForPedido(pedidoId, limit: limit);

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamChatMeta(String pedidoId) {
    return _chatDoc(pedidoId).snapshots();
  }

  /// Lista as conversas (threads) do utilizador.
  ///
  /// - role: 'cliente' | 'prestador'
  /// - ordena por lastMessageAt desc (mais recente primeiro)
  ///
  /// Nota: já existe índice em `firestore.indexes.json` para:
  ///   chats where clienteId/prestadorId + orderBy lastMessageAt desc
  Stream<QuerySnapshot<Map<String, dynamic>>> streamThreadsForUser({
    required String uid,
    required String role,
    int limit = 100,
  }) {
    final r = role.trim().toLowerCase();
    final col = _db.collection('chats');

    Query<Map<String, dynamic>> q;
    if (r == 'prestador') {
      q = col.where('prestadorId', isEqualTo: uid);
    } else {
      // default: cliente
      q = col.where('clienteId', isEqualTo: uid);
    }

    return q.orderBy('lastMessageAt', descending: true).limit(limit).snapshots();
  }


  // ============================================================
  // ENVIAR MENSAGEM
  // ============================================================
  Future<void> sendMessage({
    required String pedidoId,
    String? text,
    String? texto,
    String? message,
    String? conteudo,
    String? senderId,
    String? senderRole,
    String? role,
    Map<String, dynamic>? extra,
  }) async {
    final pid = pedidoId.trim();
    final content = (text ?? texto ?? message ?? conteudo ?? '').trim();
    final sRole = (senderRole ?? role ?? '').trim();

    if (pid.isEmpty) {
      throw ArgumentError('sendMessage: pedidoId vazio.');
    }

    final extraMap = extra ?? const <String, dynamic>{};
    final mediaUrl = (extraMap['mediaUrl'] ?? extraMap['fileUrl'] ?? extraMap['url'])
        ?.toString()
        .trim();
    final hasMedia = mediaUrl != null && mediaUrl.isNotEmpty;
    final typeFromExtra = (extraMap['type'] as String?)?.trim();
    final msgType = (typeFromExtra != null && typeFromExtra.isNotEmpty) ? typeFromExtra : 'text';

    if (content.isEmpty && !hasMedia) return;

    final uid = (senderId ?? _auth.currentUser?.uid ?? '').trim();
    final roleFinal = sRole.isEmpty ? 'cliente' : sRole;

    await ensureChatMetaForPedido(pid);

    final now = FieldValue.serverTimestamp();

    final msgRef = _messagesCol(pid).doc();
    final msgData = <String, dynamic>{
      'pedidoId': pid,
      'type': msgType,

      if (content.isNotEmpty) 'text': content,
      if (content.isNotEmpty) 'texto': content,
      if (content.isNotEmpty) 'message': content,
      if (content.isNotEmpty) 'conteudo': content,

      'senderId': uid,
      'senderRole': roleFinal,
      'createdAt': now,

      'seenByCliente': roleFinal == 'cliente',
      'seenByPrestador': roleFinal == 'prestador',
      'deliveredToCliente': roleFinal == 'cliente',
      'deliveredToPrestador': roleFinal == 'prestador',
    };

    if (extraMap.isNotEmpty) {
      msgData.addAll(extraMap);
    }

    final String preview = content.isNotEmpty
        ? content
        : () {
            if (msgType == 'call') {
              final callType = (extraMap['callType'] ?? '').toString().trim();
              return callType == 'video' ? 'Chamada de video' : 'Chamada de voz';
            }
            if (msgType == 'image') return 'Foto';
            if (msgType == 'sticker') return 'Sticker';
            if (msgType == 'gif') return 'GIF';
            if (msgType == 'audio') return 'Audio';
            if (msgType == 'file') {
              final name = (extraMap['fileName'] ?? '').toString().trim();
              return name.isNotEmpty ? 'Arquivo: $name' : 'Arquivo';
            }
            return 'Mensagem';
          }();

    final chatUpdate = <String, dynamic>{
      'updatedAt': now,
      'lastMessageAt': now,
      'lastMessage': preview,
      'lastSenderRole': roleFinal,
    };

    if (roleFinal == 'cliente') {
      chatUpdate['hasUnreadPrestador'] = true;
      chatUpdate['unreadByPrestador'] = FieldValue.increment(1);
    } else {
      chatUpdate['hasUnreadCliente'] = true;
      chatUpdate['unreadByCliente'] = FieldValue.increment(1);
    }

    final batch = _db.batch();
    batch.set(msgRef, msgData);
    batch.set(_chatDoc(pid), chatUpdate, SetOptions(merge: true));
    await batch.commit();
  }

  // ============================================================
  // MARCAR ENTREGUE / VISTO
  // ============================================================
  Future<void> marcarEntreguesParaRole({
    required String pedidoId,
    required String role,
  }) async {
    final pid = pedidoId.trim();
    final r = role.trim();
    if (pid.isEmpty || r.isEmpty) return;

    final deliveredField =
        (r == 'cliente') ? 'deliveredToCliente' : 'deliveredToPrestador';

    final qs = await _messagesCol(pid)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();

    final batch = _db.batch();
    var updates = 0;

    for (final d in qs.docs) {
      final data = d.data();
      final senderRole = (data['senderRole'] as String?) ?? '';

      if (senderRole == r) continue;

      final delivered = data[deliveredField] == true;
      if (delivered) continue;

      batch.update(d.reference, {deliveredField: true});
      updates++;
      if (updates >= 450) break;
    }

    if (updates > 0) {
      await batch.commit();
    }
  }

  Future<void> marcarVistasParaRole({
    required String pedidoId,
    required String role,
  }) async {
    final pid = pedidoId.trim();
    final r = role.trim();
    if (pid.isEmpty || r.isEmpty) return;

    final seenField = (r == 'cliente') ? 'seenByCliente' : 'seenByPrestador';
    final now = FieldValue.serverTimestamp();

    final qs = await _messagesCol(pid)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();

    final batch = _db.batch();
    var updates = 0;

    for (final d in qs.docs) {
      final data = d.data();
      final senderRole = (data['senderRole'] as String?) ?? '';

      if (senderRole == r) continue;

      final seen = data[seenField] == true;
      if (seen) continue;

      batch.update(d.reference, {seenField: true});
      updates++;
      if (updates >= 450) break;
    }

    batch.set(
      _chatDoc(pid),
      <String, dynamic>{
        'updatedAt': now,
        if (r == 'cliente') 'hasUnreadCliente': false,
        if (r == 'prestador') 'hasUnreadPrestador': false,
        if (r == 'cliente') 'unreadByCliente': 0,
        if (r == 'prestador') 'unreadByPrestador': 0,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ============================================================
  // ⭐ FAVORITOS (STARRED)
  // ============================================================
  Future<void> setMessageStarred({
    required String pedidoId,
    required String messageId,
    required bool starred,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final ref = _messagesCol(pedidoId).doc(messageId);
    if (starred) {
      await ref.set(
        {'starredBy': FieldValue.arrayUnion([uid])},
        SetOptions(merge: true),
      );
    } else {
      await ref.set(
        {'starredBy': FieldValue.arrayRemove([uid])},
        SetOptions(merge: true),
      );
    }
  }

  Stream<List<ChatMessage>> streamStarredMessages(String pedidoId) {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return const Stream<List<ChatMessage>>.empty();
    }
    return _messagesCol(pedidoId)
        .where('starredBy', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(ChatMessage.fromFirestore).toList());
  }
}
