import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'chat_thread_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

class MensagensTab extends StatefulWidget {
  /// 'cliente' | 'prestador'
  final String viewerRole;

  const MensagensTab({
    super.key,
    required this.viewerRole,
  });

  @override
  State<MensagensTab> createState() => _MensagensTabState();
}

class _MensagensTabState extends State<MensagensTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;
    if (user == null) {
      return Center(child: Text(l10n.userNotAuthenticatedError));
    }

    final uid = user.uid;
    final df = DateFormat('dd/MM HH:mm', l10n.localeName);

    final field = (widget.viewerRole == 'cliente') ? 'clienteId' : 'prestadorId';

    final query = FirebaseFirestore.instance
        .collection('chats')
        .where(field, isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.messagesTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.messagesSearchHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(
                    child: Text(
                      l10n.messagesLoadError(snap.error.toString()),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.messagesEmpty,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final q = _searchCtrl.text.trim().toLowerCase();

                final tiles = docs.map((d) {
                  final data = d.data();

                  final pedidoId = d.id;
                  final pedidoTitulo = (data['pedidoTitulo'] as String?) ?? '';

                  final clienteId = (data['clienteId'] as String?) ?? '';
                  final prestadorId = (data['prestadorId'] as String?) ?? '';

                  final otherId = (widget.viewerRole == 'cliente') ? prestadorId : clienteId;

                  // Compat: em vários pontos do projeto usa-se "prestadorNome/clienteNome" (PT)
                  // mas noutros (ou versões antigas) pode existir "prestadorName/clienteName".
                  final otherName = (widget.viewerRole == 'cliente')
                      ? ((data['prestadorNome'] as String?) ??
                          (data['prestadorName'] as String?) ??
                          l10n.roleLabelProvider)
                      : ((data['clienteNome'] as String?) ??
                          (data['clienteName'] as String?) ??
                          l10n.roleLabelCustomer);

                  final otherPhoto = (widget.viewerRole == 'cliente')
                      ? ((data['prestadorPhotoUrl'] as String?) ?? '')
                      : ((data['clientePhotoUrl'] as String?) ?? '');

                  final lastMessage = (data['lastMessage'] as String?) ?? '';
                  final ts = data['lastMessageAt'];
                  DateTime? lastAt;
                  if (ts is Timestamp) lastAt = ts.toDate();

                  final hasUnread = (widget.viewerRole == 'cliente')
                      ? (data['hasUnreadCliente'] == true)
                      : (data['hasUnreadPrestador'] == true);

                  final unreadCount = (widget.viewerRole == 'cliente')
                      ? ((data['unreadByCliente'] as num?)?.toInt() ?? 0)
                      : ((data['unreadByPrestador'] as num?)?.toInt() ?? 0);

                  final effectiveHasUnread = hasUnread || unreadCount > 0;

                  return _ChatTileData(
                    pedidoId: pedidoId,
                    pedidoTitulo: pedidoTitulo,
                    otherUserId: otherId,
                    otherUserName: otherName,
                    otherUserPhotoUrl: otherPhoto,
                    lastMessage: lastMessage,
                    lastAt: lastAt,
                    hasUnread: effectiveHasUnread,
                    unreadCount: unreadCount,
                  );
                }).where((t) {
                  if (q.isEmpty) return true;
                  return t.otherUserName.toLowerCase().contains(q) ||
                      t.pedidoTitulo.toLowerCase().contains(q) ||
                      t.lastMessage.toLowerCase().contains(q);
                }).toList();

                final theme = Theme.of(context);
                final primary = theme.colorScheme.primary;

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: tiles.length,
                  itemBuilder: (context, i) {
                    final t = tiles[i];
                    final timeStr = (t.lastAt != null) ? df.format(t.lastAt!) : '';

                    final borderColor = t.hasUnread
                        ? primary.withValues(alpha: 0.55)
                        : Colors.grey.shade200;
                    final bgColor = t.hasUnread
                        ? primary.withValues(alpha: 0.08)
                        : Colors.transparent;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.1),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: (t.otherUserPhotoUrl.isNotEmpty)
                                  ? NetworkImage(t.otherUserPhotoUrl)
                                  : null,
                              child: (t.otherUserPhotoUrl.isEmpty)
                                  ? Text(
                                      t.otherUserName.isNotEmpty
                                          ? t.otherUserName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    )
                                  : null,
                            ),
                            if (t.hasUnread)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          t.otherUserName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: t.hasUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (t.lastMessage.isNotEmpty)
                              Text(
                                t.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              Text(
                                l10n.chatNoMessagesSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (t.pedidoTitulo.isNotEmpty)
                              Text(
                                t.pedidoTitulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (timeStr.isNotEmpty)
                              Text(
                                timeStr,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            if (t.unreadCount > 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${t.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () async {
                          // garante meta (importante para chats antigos)
                          await ChatService.instance.ensureChatMetaForPedido(t.pedidoId);

                          if (!context.mounted) return;

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatThreadScreen(
                                pedidoId: t.pedidoId,
                                viewerRole: widget.viewerRole,
                                otherUserId: t.otherUserId,
                                otherUserName: t.otherUserName,
                                otherUserPhotoUrl: t.otherUserPhotoUrl,
                                pedidoTitulo: t.pedidoTitulo,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTileData {
  final String pedidoId;
  final String pedidoTitulo;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhotoUrl;
  final String lastMessage;
  final DateTime? lastAt;
  final bool hasUnread;
  final int unreadCount;

  _ChatTileData({
    required this.pedidoId,
    required this.pedidoTitulo,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
    required this.lastMessage,
    required this.lastAt,
    required this.hasUnread,
    required this.unreadCount,
  });
}
