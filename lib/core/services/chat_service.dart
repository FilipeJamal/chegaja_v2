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
  final Map<String, Future<void>> _pendingEnsureChatMeta = {};

  bool _isPermissionDenied(Object error) =>
      error is FirebaseException && error.code == 'permission-denied';

  DocumentReference<Map<String, dynamic>> _chatDoc(String pedidoId) =>
      _db.collection('chats').doc(pedidoId);

  CollectionReference<Map<String, dynamic>> _messagesCol(String pedidoId) =>
      _chatDoc(pedidoId).collection('messages');

  // ============================================================
  // META DO CHAT (garante que o doc chats/{pedidoId} existe)
  // ============================================================
  Future<void> ensureChatMetaForPedido(String pedidoId) {
    final pid = pedidoId.trim();
    if (pid.isEmpty) return Future.value();

    final pending = _pendingEnsureChatMeta[pid];
    if (pending != null) return pending;

    final future = _ensureChatMetaForPedido(pid).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      if (_isPermissionDenied(error)) return;
      Error.throwWithStackTrace(error, stackTrace);
    });
    _pendingEnsureChatMeta[pid] = future;
    return future.whenComplete(() {
      if (identical(_pendingEnsureChatMeta[pid], future)) {
        _pendingEnsureChatMeta.remove(pid);
      }
    });
  }

  Future<void> _ensureChatMetaForPedido(String pedidoId) async {
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

    final data = snap.data() ?? const <String, dynamic>{};
    final patch = <String, dynamic>{
      'pedidoId': pedidoId,
      if (clienteId != null && data['clienteId'] == null)
        'clienteId': clienteId,
      if (data['prestadorId'] == null && prestadorId != null)
        'prestadorId': prestadorId,
      if (pedidoTitulo != null && data['pedidoTitulo'] == null)
        'pedidoTitulo': pedidoTitulo,
      if (data['lastMessageAt'] == null) 'lastMessageAt': now,
      if (data['lastMessage'] == null) 'lastMessage': '',
      if (data['lastSenderRole'] == null) 'lastSenderRole': '',
      if (data['hasUnreadCliente'] == null) 'hasUnreadCliente': false,
      if (data['hasUnreadPrestador'] == null) 'hasUnreadPrestador': false,
      if (data['unreadByCliente'] == null) 'unreadByCliente': 0,
      if (data['unreadByPrestador'] == null) 'unreadByPrestador': 0,
    };

    if (patch.length > 1) {
      await ref.set(
        patch,
        SetOptions(merge: true),
      );
    }

    // Backfill preview if messages existed before chat meta.
    try {
      final lastMessage = (data['lastMessage'] as String?) ?? '';

      if (lastMessage.trim().isEmpty) {
        final lastMsgQs = await _messagesCol(pedidoId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (lastMsgQs.docs.isNotEmpty) {
          final m = lastMsgQs.docs.first.data();
          final text =
              (m['text'] ?? m['texto'] ?? m['message'] ?? m['conteudo'] ?? '')
                  .toString()
                  .trim();
          final senderRole = (m['senderRole'] ?? '').toString();
          final createdAt = m['createdAt'];

          await ref.set(
            {
              'pedidoId': pedidoId,
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

  Future<void> ensureChatMeta(String pedidoId) =>
      ensureChatMetaForPedido(pedidoId);

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

  Stream<List<ChatMessage>> streamMessages(String pedidoId,
          {int limit = 200}) =>
      streamMessagesForPedido(pedidoId, limit: limit);

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamChatMeta(
      String pedidoId) {
    return _chatDoc(pedidoId).snapshots();
  }

  Stream<List<ChatMessage>> streamStarredMessages(String pedidoId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _messagesCol(pedidoId)
        .where('starredBy', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map(ChatMessage.fromFirestore).toList());
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

    return q
        .orderBy('lastMessageAt', descending: true)
        .limit(limit)
        .snapshots();
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
    String? replyToId,
    String? replyToText,
    Map<String, dynamic>? extra,
  }) async {
    final pid = pedidoId.trim();
    final content = (text ?? texto ?? message ?? conteudo ?? '').trim();
    final sRole = (senderRole ?? role ?? '').trim();

    if (pid.isEmpty) {
      throw ArgumentError('sendMessage: pedidoId vazio.');
    }

    final extraMap = extra ?? const <String, dynamic>{};
    final mediaUrl =
        (extraMap['mediaUrl'] ?? extraMap['fileUrl'] ?? extraMap['url'])
            ?.toString()
            .trim();
    final hasMedia = mediaUrl != null && mediaUrl.isNotEmpty;
    final typeFromExtra = (extraMap['type'] as String?)?.trim();
    final msgType = (typeFromExtra != null && typeFromExtra.isNotEmpty)
        ? typeFromExtra
        : 'text';

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
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToText != null) 'replyToText': replyToText,
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
              return callType == 'video'
                  ? 'Chamada de video'
                  : 'Chamada de voz';
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
      'pedidoId': pid,
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

    try {
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
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  Future<void> marcarVistasParaRole({
    required String pedidoId,
    required String role,
  }) async {
    final pid = pedidoId.trim();
    final r = role.trim();
    if (pid.isEmpty || r.isEmpty) return;

    try {
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
          'pedidoId': pid,
          'updatedAt': now,
          if (r == 'cliente') 'hasUnreadCliente': false,
          if (r == 'prestador') 'hasUnreadPrestador': false,
          if (r == 'cliente') 'unreadByCliente': 0,
          if (r == 'prestador') 'unreadByPrestador': 0,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }
  }

  // ============================================================
  // ⭐ FAVORITOS (STARRED)
  // ============================================================
  // ============================================================
  // ⭐ FAVORITOS (STARRED) & REAÇÕES
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
        {
          'starredBy': FieldValue.arrayUnion([uid])
        },
        SetOptions(merge: true),
      );
    } else {
      await ref.set(
        {
          'starredBy': FieldValue.arrayRemove([uid])
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<void> toggleReaction({
    required String pedidoId,
    required String messageId,
    required String reaction, // ex: '❤️'
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final ref = _messagesCol(pedidoId).doc(messageId);

    // Firestore não suporta toggle em Map facilmente.
    // Temos de ler, alterar e gravar ou usar Transaction.
    // Para UX rápida, vamos usar Transaction.
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});

      final List<dynamic> users = List.from(reactions[reaction] ?? []);

      if (users.contains(uid)) {
        users.remove(uid); // Toggle OFF
        if (users.isEmpty) {
          reactions.remove(reaction);
        } else {
          reactions[reaction] = users;
        }
      } else {
        users.add(uid); // Toggle ON
        reactions[reaction] = users;
      }

      tx.update(ref, {'reactions': reactions});
    });
  }

  // ============================================================
  // EDITAR / APAGAR (SOFT DELETE) / REPLY
  // ============================================================
  Future<void> deleteMessage({
    required String pedidoId,
    required String messageId,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    // Soft delete
    await _messagesCol(pedidoId).doc(messageId).update({
      'isDeleted': true,
      'text': '🚫 Esta mensagem foi apagada', // Opcional, para clientes antigos
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Check if it was last message?
    // (Opcional: atualizar lastMessage do chat se for a ultima... complexo mas melhor)
  }

  Future<void> editMessage({
    required String pedidoId,
    required String messageId,
    required String newText,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    await _messagesCol(pedidoId).doc(messageId).update({
      'isEdited': true,
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendLocation({
    required String pedidoId,
    required double latitude,
    required double longitude,
    required String senderRole,
  }) async {
    await sendMessage(
      pedidoId: pedidoId,
      text: '📍 Localização Partilhada', // Fallback text
      senderRole: senderRole,
      senderId: _auth.currentUser?.uid,
      extra: {
        'type': 'location',
        'locationLat': latitude,
        'locationLng': longitude,
      },
    );
  }

  // ============================================================
  // INDICADORES DE PRESENÇA (TYPING)
  // ============================================================
  // Usamos uma coleção separada 'typing' ou 'presence' dentro do chat
  // chats/{pid}/typing/{uid} -> { isTyping: bool, updatedAt: ... }

  Future<void> setTypingStatus({
    required String pedidoId,
    required bool isTyping,
    required String role,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _chatDoc(pedidoId).collection('typing').doc(uid);

    if (isTyping) {
      await ref.set({
        'uid': uid,
        'role': role,
        'isTyping': true,
        'lastTypedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  Stream<List<String>> streamTypingUsers(String pedidoId) {
    if (pedidoId.isEmpty) return const Stream.empty();

    // Limpar typing antigos (> 10s)? Feito idealmente via Cloud Functions ou Lazy filter na UI.
    // Aqui retornamos quem está na coleção.
    return _chatDoc(pedidoId).collection('typing').snapshots().map((snap) {
      return snap.docs
          .map((d) {
            // Opcional: verificar timestamp para ignorar stale
            return d['role'].toString(); // Retorna roles que estão escrevendo
          })
          .toSet()
          .toList();
    });
  }

  // ============================================================
  // FAVORITAR CHAT (PIN)
  // ============================================================
  Future<void> toggleChatFavorite({
    required String pedidoId,
    required String uid,
  }) async {
    final ref = _chatDoc(pedidoId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data() ?? {};
    final favs = List<String>.from(data['favoritedBy'] ?? []);

    if (favs.contains(uid)) {
      favs.remove(uid);
    } else {
      favs.add(uid);
    }

    await ref.update({'favoritedBy': favs});
  }
}
