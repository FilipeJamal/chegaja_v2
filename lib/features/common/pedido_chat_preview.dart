// lib/features/common/pedido_chat_preview.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';

class PedidoChatPreview extends StatefulWidget {
  final String pedidoId;

  /// 'cliente' | 'prestador'
  ///
  /// (compatibilidade: podes passar viewerRole: ou role:)
  final String viewerRole;

  /// opcional: se já tens
  final String? pedidoTitulo;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  /// opcional: se já tens
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserPhotoUrl;

  /// opcional: indicador de mensagens por ler
  final int unreadCount;
  final bool hasUnread;

  PedidoChatPreview({
    super.key,
    required this.pedidoId,
    String? viewerRole,
    String? role, // compat
    this.pedidoTitulo,
    this.lastMessage,
    this.lastMessageAt,
    this.otherUserId,
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.unreadCount = 0,
    bool? hasUnread,
    bool? unread, // compat
  })  : viewerRole = _normalizeRole(viewerRole ?? role ?? 'cliente'),
        hasUnread = (hasUnread ?? unread ?? (unreadCount > 0));

  static String _normalizeRole(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'prestador') return 'prestador';
    return 'cliente';
  }

  @override
  State<PedidoChatPreview> createState() => _PedidoChatPreviewState();
}

class _PedidoChatPreviewState extends State<PedidoChatPreview> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late Future<_OtherUserResolved> _future;

  @override
  void initState() {
    super.initState();
    _future = _resolveOtherUser();
  }

  @override
  void didUpdateWidget(covariant PedidoChatPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pedidoId != widget.pedidoId ||
        oldWidget.viewerRole != widget.viewerRole ||
        oldWidget.otherUserId != widget.otherUserId) {
      _future = _resolveOtherUser();
    }
  }

  String get _otherRole => (widget.viewerRole == 'cliente') ? 'prestador' : 'cliente';

  Future<_OtherUserResolved> _resolveOtherUser() async {
    // 1) Se já veio pronto do caller, usa
    final givenName = (widget.otherUserName ?? '').trim();
    final givenPhoto = (widget.otherUserPhotoUrl ?? '').trim();
    final givenOtherId = (widget.otherUserId ?? '').trim();
    final givenPedidoTitulo = (widget.pedidoTitulo ?? '').trim();

    if (givenOtherId.isNotEmpty && (givenName.isNotEmpty || givenPhoto.isNotEmpty)) {
      return _OtherUserResolved(
        otherUserId: givenOtherId,
        otherUserName: givenName.isNotEmpty ? givenName : _fallbackName(),
        otherUserPhotoUrl: givenPhoto.isNotEmpty ? givenPhoto : null,
        pedidoTitulo: givenPedidoTitulo.isNotEmpty ? givenPedidoTitulo : null,
      );
    }

    String? otherId;
    String? pedidoTitulo;

    // 2) Tenta ler meta do chat em chats/{pedidoId}
    try {
      final chatSnap = await _db.collection('chats').doc(widget.pedidoId).get();
      final chat = chatSnap.data();

      if (chat != null) {
        pedidoTitulo = _pickFirstString(chat, const [
          'pedidoTitulo',
          'pedido_title',
          'titulo',
          'title',
        ]);

        if (widget.viewerRole == 'cliente') {
          otherId = _pickFirstString(chat, const [
            'prestadorId',
            'prestadorUid',
            'prestadorUID',
            'prestador_id',
            'prestadorUserId',
          ]);
        } else {
          otherId = _pickFirstString(chat, const [
            'clienteId',
            'clienteUid',
            'clienteUID',
            'cliente_id',
            'clienteUserId',
          ]);
        }
      }
    } catch (_) {
      // ignora
    }

    // 3) Se ainda não deu, tenta pedidos/{pedidoId}
    final needOtherId = (otherId == null || otherId.trim().isEmpty);
    final needTitulo = (pedidoTitulo == null || pedidoTitulo.trim().isEmpty);

    if (needOtherId || needTitulo) {
      try {
        final pedidoSnap = await _db.collection('pedidos').doc(widget.pedidoId).get();
        final pedido = pedidoSnap.data();
        if (pedido != null) {
          pedidoTitulo ??= _pickFirstString(pedido, const [
            'titulo',
            'pedidoTitulo',
            'title',
            'descricao',
          ]);

          if (widget.viewerRole == 'cliente') {
            otherId ??= _pickFirstString(pedido, const [
              'prestadorId',
              'prestadorUid',
              'prestadorUID',
              'prestador_id',
              'prestadorUserId',
            ]);
          } else {
            otherId ??= _pickFirstString(pedido, const [
              'clienteId',
              'clienteUid',
              'clienteUID',
              'cliente_id',
              'clienteUserId',
            ]);
          }
        }
      } catch (_) {
        // ignora
      }
    }

    otherId = (otherId ?? givenOtherId).trim();
    pedidoTitulo = (givenPedidoTitulo.isNotEmpty ? givenPedidoTitulo : (pedidoTitulo ?? '')).trim();

    if (otherId.isEmpty) {
      // Sem ID do outro user, não tem como buscar nome/foto
      return _OtherUserResolved(
        otherUserId: null,
        otherUserName: givenName.isNotEmpty ? givenName : _fallbackName(),
        otherUserPhotoUrl: givenPhoto.isNotEmpty ? givenPhoto : null,
        pedidoTitulo: pedidoTitulo.isNotEmpty ? pedidoTitulo : null,
      );
    }

    // 4) Busca perfil do outro user (prioriza prestadores/)
    Map<String, dynamic>? profile;

    final collections = (_otherRole == 'prestador')
        ? <String>['prestadores', 'users', 'usuarios', 'clientes']
        : <String>['users', 'clientes', 'usuarios', 'prestadores'];

    for (final col in collections) {
      try {
        final snap = await _db.collection(col).doc(otherId).get();
        if (snap.exists) {
          profile = snap.data();
          if (profile != null && profile.isNotEmpty) break;
        }
      } catch (_) {
        // ignora e tenta próxima
      }
    }

    final extractedName = _extractName(profile) ?? givenName;
    final name = extractedName.trim().isNotEmpty ? extractedName.trim() : (_otherRole == 'prestador' ? 'Prestador' : 'Cliente');

    final photo = (_extractPhoto(profile) ?? givenPhoto).trim();

    // 5) (Opcional) cache no chat meta
    try {
      final cache = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

      if (_otherRole == 'prestador') {
        cache['prestadorNome'] = name;
        if (photo.isNotEmpty) cache['prestadorPhotoUrl'] = photo;
      } else {
        cache['clienteNome'] = name;
        if (photo.isNotEmpty) cache['clientePhotoUrl'] = photo;
      }

      if (pedidoTitulo.isNotEmpty) cache['pedidoTitulo'] = pedidoTitulo;

      await _db.collection('chats').doc(widget.pedidoId).set(cache, SetOptions(merge: true));
    } catch (_) {
      // ignora
    }

    return _OtherUserResolved(
      otherUserId: otherId,
      otherUserName: name,
      otherUserPhotoUrl: photo.isNotEmpty ? photo : null,
      pedidoTitulo: pedidoTitulo.isNotEmpty ? pedidoTitulo : null,
    );
  }

  String _fallbackName() => (_otherRole == 'prestador') ? 'Prestador' : 'Cliente';

  static String? _pickFirstString(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static String? _extractName(Map<String, dynamic>? data) {
    if (data == null) return null;
    const keys = ['nome', 'displayName', 'name', 'fullName', 'usuarioNome'];
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static String? _extractPhoto(Map<String, dynamic>? data) {
    if (data == null) return null;
    const keys = ['photoUrl', 'fotoUrl', 'avatarUrl', 'photoURL', 'photo'];
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  void _openChat(_OtherUserResolved other) {
    final otherId = (other.otherUserId ?? '').trim();

    // ✅ FIX: ChatThreadScreen exige otherUserId (String).
    // Se não existir, não abrimos o chat (para não quebrar e para manter a lógica correta).
    if (otherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível abrir o chat porque falta o ID do ${_fallbackName().toLowerCase()}.\n'
            'Provavelmente o pedido ainda não tem ${_fallbackName().toLowerCase()} associado.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          pedidoId: widget.pedidoId,
          viewerRole: widget.viewerRole,
          otherUserId: otherId,
          otherUserName: other.otherUserName,
          otherUserPhotoUrl: other.otherUserPhotoUrl,
          pedidoTitulo: other.pedidoTitulo ?? widget.pedidoTitulo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM HH:mm');
    final timeStr = (widget.lastMessageAt != null) ? df.format(widget.lastMessageAt!) : '';

    return FutureBuilder<_OtherUserResolved>(
      future: _future,
      builder: (context, snap) {
        final resolved = snap.data;

        final other = resolved ??
            _OtherUserResolved(
              otherUserId: (widget.otherUserId ?? '').trim().isEmpty ? null : widget.otherUserId!.trim(),
              otherUserName: (widget.otherUserName ?? '').trim().isEmpty ? _fallbackName() : widget.otherUserName!.trim(),
              otherUserPhotoUrl: (widget.otherUserPhotoUrl ?? '').trim().isEmpty ? null : widget.otherUserPhotoUrl!.trim(),
              pedidoTitulo: (widget.pedidoTitulo ?? '').trim().isEmpty ? null : widget.pedidoTitulo!.trim(),
            );

        final name = other.otherUserName.trim().isEmpty ? _fallbackName() : other.otherUserName.trim();
        final photo = (other.otherUserPhotoUrl ?? '').trim();
        final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

        final pedidoTitulo = (other.pedidoTitulo ?? '').trim();

        return InkWell(
          onTap: () => _openChat(other),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: (photo.startsWith('http')) ? NetworkImage(photo) : null,
                      child: (!photo.startsWith('http')) ? Text(initials) : null,
                    ),
                    if (widget.hasUnread)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (widget.lastMessage ?? '').trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      if (pedidoTitulo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          pedidoTitulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OtherUserResolved {
  final String? otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final String? pedidoTitulo;

  _OtherUserResolved({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
    required this.pedidoTitulo,
  });
}
