import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// intl removed

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/core/utils/date_time_utils.dart';
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
  String _filterMode = 'all'; // 'all', 'unread', 'favorites', 'groups'
  late Future<void> _authBootstrapFuture;

  @override
  void initState() {
    super.initState();
    _authBootstrapFuture = _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    try {
      await AuthService.ensureSignedInAnonymously();
      await AuthService.setActiveRole(widget.viewerRole);
    } catch (_) {
      // A UI trata a indisponibilidade de sessão sem rebentar a aba.
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<void>(
      future: _authBootstrapFuture,
      builder: (context, authSnap) {
        final user = AuthService.currentUser;
        if (user == null && authSnap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.userNotAuthenticatedError,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _authBootstrapFuture = _bootstrapSession();
                      });
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final uid = user.uid;
        final field =
            (widget.viewerRole == 'cliente') ? 'clienteId' : 'prestadorId';

        final query = FirebaseFirestore.instance
            .collection('chats')
            .where(field, isEqualTo: uid)
            .orderBy('lastMessageAt', descending: true);

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.messagesNewConversationTitle),
                  content: Text(l10n.messagesNewConversationBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.actionClose),
                    ),
                  ],
                ),
              );
            },
            child: const Icon(Icons.add_comment_rounded),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.messagesTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.camera_alt_outlined),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_vert),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: l10n.messagesSearchHint,
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(l10n.messagesFilterAll, 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip(l10n.messagesFilterUnread, 'unread'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        l10n.messagesFilterFavorites,
                        'favorites',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(l10n.messagesFilterGroups, 'groups'),
                    ],
                  ),
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
                        final pedidoTitulo =
                            (data['pedidoTitulo'] as String?) ?? '';

                        final clienteId = (data['clienteId'] as String?) ?? '';
                        final prestadorId =
                            (data['prestadorId'] as String?) ?? '';

                        final otherId = (widget.viewerRole == 'cliente')
                            ? prestadorId
                            : clienteId;

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

                        final lastMessage =
                            (data['lastMessage'] as String?) ?? '';
                        final ts = data['lastMessageAt'];
                        DateTime? lastAt;
                        if (ts is Timestamp) lastAt = ts.toDate();

                        final hasUnread = (widget.viewerRole == 'cliente')
                            ? (data['hasUnreadCliente'] == true)
                            : (data['hasUnreadPrestador'] == true);

                        final unreadCount = (widget.viewerRole == 'cliente')
                            ? ((data['unreadByCliente'] as num?)?.toInt() ?? 0)
                            : ((data['unreadByPrestador'] as num?)?.toInt() ??
                                0);

                        final effectiveHasUnread = hasUnread || unreadCount > 0;

                        final favs =
                            List<String>.from(data['favoritedBy'] ?? []);
                        final isFav = favs.contains(uid);

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
                          isFavorite: isFav,
                        );
                      }).where((t) {
                        // Search filter
                        if (q.isNotEmpty) {
                          final matches =
                              t.otherUserName.toLowerCase().contains(q) ||
                                  t.pedidoTitulo.toLowerCase().contains(q) ||
                                  t.lastMessage.toLowerCase().contains(q);
                          if (!matches) return false;
                        }

                        // Mode filter
                        if (_filterMode == 'unread') {
                          return t.hasUnread;
                        } else if (_filterMode == 'favorites') {
                          return t.isFavorite;
                        } else if (_filterMode == 'groups') {
                          // Placeholder for groups
                          return false;
                        }
                        return true;
                      }).toList();

                      final filterLabel = {
                            'all': l10n.messagesFilterAll,
                            'unread': l10n.messagesFilterUnread,
                            'favorites': l10n.messagesFilterFavorites,
                            'groups': l10n.messagesFilterGroups,
                          }[_filterMode] ??
                          l10n.messagesFilterAll;

                      if (tiles.isEmpty && q.isNotEmpty) {
                        return Center(
                            child: Text(l10n.messagesSearchNoResults));
                      }

                      if (tiles.isEmpty && _filterMode != 'all') {
                        return Center(
                          child: Text(l10n.messagesFilterEmpty(filterLabel)),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 80),
                        itemCount: tiles.length,
                        itemBuilder: (context, i) {
                          final t = tiles[i];

                          // Date formatting logic
                          String timeStr = '';
                          if (t.lastAt != null) {
                            final now = DateTime.now();
                            final diff = now.difference(t.lastAt!);
                            if (diff.inDays == 0 && now.day == t.lastAt!.day) {
                              timeStr = DateTimeUtils.formatTime(t.lastAt!,
                                  locale: l10n.localeName);
                            } else if (diff.inDays < 7) {
                              timeStr = DateTimeUtils.formatDate(t.lastAt!,
                                  locale: l10n.localeName);
                            } else {
                              timeStr = DateTimeUtils.formatDate(t.lastAt!,
                                  locale: l10n.localeName);
                            }
                          }

                          return InkWell(
                            onTap: () async {
                              await ChatService.instance
                                  .ensureChatMetaForPedido(t.pedidoId);
                              if (!context.mounted) return;
                              await Navigator.of(context).push(
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
                            onLongPress: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (ctx) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: Icon(
                                          t.isFavorite
                                              ? Icons.push_pin_outlined
                                              : Icons.push_pin,
                                        ),
                                        title: Text(
                                          t.isFavorite
                                              ? l10n.messagesUnpinConversation
                                              : l10n.messagesPinConversation,
                                        ),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          ChatService.instance
                                              .toggleChatFavorite(
                                            pedidoId: t.pedidoId,
                                            uid: uid,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.grey.shade300,
                                    backgroundImage:
                                        (t.otherUserPhotoUrl.isNotEmpty)
                                            ? NetworkImage(t.otherUserPhotoUrl)
                                            : null,
                                    child: (t.otherUserPhotoUrl.isEmpty)
                                        ? Text(
                                            t.otherUserName.isNotEmpty
                                                ? t.otherUserName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                t.otherUserName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                if (t.isFavorite)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 4),
                                                    child: Icon(
                                                      Icons.push_pin,
                                                      size: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                Text(
                                                  timeStr,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: t.hasUnread
                                                        ? Colors.green.shade600
                                                        : Colors.grey.shade600,
                                                    fontWeight: t.hasUnread
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                t.lastMessage.isNotEmpty
                                                    ? t.lastMessage
                                                    : l10n
                                                        .chatNoMessagesSubtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: t.hasUnread
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            if (t.unreadCount > 0)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 8),
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  '${t.unreadCount}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterMode == value;
    return ActionChip(
      label: Text(label),
      onPressed: () => setState(() => _filterMode = value),
      backgroundColor:
          isSelected ? Colors.green.shade100 : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade900 : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.green.shade200 : Colors.transparent,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
  final bool isFavorite;

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
    this.isFavorite = false,
  });
}
