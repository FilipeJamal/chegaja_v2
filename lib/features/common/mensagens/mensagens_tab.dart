import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// intl removed

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/utils/date_time_utils.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_content_shell.dart';
import 'package:chegaja_v2/core/widgets/app_filter_button.dart';
import 'package:chegaja_v2/core/widgets/app_premium_search_bar.dart';
import 'package:chegaja_v2/core/widgets/app_product_header.dart';
import 'package:chegaja_v2/core/widgets/app_segmented_tabs.dart';
import 'package:chegaja_v2/features/auth/phone_verification_screen.dart';
import 'package:chegaja_v2/features/common/mensagens/widgets/conversation_list_card.dart';
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

        if (!AuthService.hasVerifiedPhone) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phonelink_lock_outlined, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Confirma o telefone para abrir mensagens',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A sessao temporaria permite explorar a app, mas nao '
                    'consulta conversas privadas.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () async {
                      final allowed = await VerifiedPhoneGate.ensure(
                        context,
                        action: 'abrir as tuas mensagens',
                      );
                      if (allowed && mounted) setState(() {});
                    },
                    icon: const Icon(Icons.phone_android_rounded),
                    label: const Text('Confirmar telefone'),
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

        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AppContentShell(
                  width: AppContentWidth.dashboard,
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppProductHeader(
                          title: l10n.messagesTitle,
                          subtitle: _subtitleForRole(),
                          actions: [
                            IconButton(
                              tooltip: l10n.messagesNewConversationTitle,
                              onPressed: () => _showNewConversationDialog(l10n),
                              icon: const Icon(Icons.add_comment_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        Row(
                          children: [
                            Expanded(
                              child: AppPremiumSearchBar(
                                controller: _searchCtrl,
                                hintText: l10n.messagesSearchHint,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            AppFilterButton(
                              active: _filterMode != 'all',
                              tooltip: 'Filtrar conversas',
                              onPressed: () => _showFilterSheet(l10n),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        AppSegmentedTabs(
                          items: [
                            AppSegmentedTab(label: l10n.messagesFilterAll),
                            AppSegmentedTab(label: l10n.messagesFilterUnread),
                            AppSegmentedTab(
                              label: l10n.messagesFilterFavorites,
                            ),
                            AppSegmentedTab(label: l10n.messagesFilterGroups),
                          ],
                          selectedIndex: _filterIndex,
                          onChanged: _setFilterIndex,
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Expanded(
                          child: StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: query.snapshots(),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const _MessagesStateCard(
                                  icon: Icons.mark_chat_unread_outlined,
                                  title: 'A carregar conversas',
                                  message:
                                      'Estamos a preparar as mensagens mais recentes.',
                                  loading: true,
                                );
                              }

                              if (snap.hasError) {
                                return _MessagesStateCard(
                                  icon: Icons.error_outline_rounded,
                                  title: 'Nao foi possivel carregar mensagens',
                                  message: l10n.messagesLoadError(
                                    snap.error.toString(),
                                  ),
                                );
                              }

                              final docs = snap.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return _MessagesStateCard(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  title: 'Sem conversas ainda',
                                  message: l10n.messagesEmpty,
                                );
                              }

                              final q = _searchCtrl.text.trim().toLowerCase();

                              final tiles = docs.map((d) {
                                final data = d.data();

                                final pedidoId = d.id;
                                final pedidoTitulo =
                                    (data['pedidoTitulo'] as String?) ?? '';

                                final clienteId =
                                    (data['clienteId'] as String?) ?? '';
                                final prestadorId =
                                    (data['prestadorId'] as String?) ?? '';

                                final otherId = (widget.viewerRole == 'cliente')
                                    ? prestadorId
                                    : clienteId;

                                final otherName = (widget.viewerRole ==
                                        'cliente')
                                    ? ((data['prestadorNome'] as String?) ??
                                        (data['prestadorName'] as String?) ??
                                        l10n.roleLabelProvider)
                                    : ((data['clienteNome'] as String?) ??
                                        (data['clienteName'] as String?) ??
                                        l10n.roleLabelCustomer);

                                final otherPhoto = (widget.viewerRole ==
                                        'cliente')
                                    ? ((data['prestadorPhotoUrl'] as String?) ??
                                        '')
                                    : ((data['clientePhotoUrl'] as String?) ??
                                        '');

                                final lastMessage =
                                    (data['lastMessage'] as String?) ?? '';
                                final ts = data['lastMessageAt'];
                                DateTime? lastAt;
                                if (ts is Timestamp) lastAt = ts.toDate();

                                final hasUnread =
                                    (widget.viewerRole == 'cliente')
                                        ? (data['hasUnreadCliente'] == true)
                                        : (data['hasUnreadPrestador'] == true);

                                final unreadCount =
                                    (widget.viewerRole == 'cliente')
                                        ? ((data['unreadByCliente'] as num?)
                                                ?.toInt() ??
                                            0)
                                        : ((data['unreadByPrestador'] as num?)
                                                ?.toInt() ??
                                            0);

                                final effectiveHasUnread =
                                    hasUnread || unreadCount > 0;

                                final favs = List<String>.from(
                                  data['favoritedBy'] ?? [],
                                );
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
                                if (q.isNotEmpty) {
                                  final matches = t.otherUserName
                                          .toLowerCase()
                                          .contains(q) ||
                                      t.pedidoTitulo
                                          .toLowerCase()
                                          .contains(q) ||
                                      t.lastMessage.toLowerCase().contains(q);
                                  if (!matches) return false;
                                }

                                if (_filterMode == 'unread') {
                                  return t.hasUnread;
                                } else if (_filterMode == 'favorites') {
                                  return t.isFavorite;
                                } else if (_filterMode == 'groups') {
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
                                return _MessagesStateCard(
                                  icon: Icons.search_off_rounded,
                                  title: 'Sem resultados',
                                  message: l10n.messagesSearchNoResults,
                                );
                              }

                              if (tiles.isEmpty && _filterMode != 'all') {
                                return _MessagesStateCard(
                                  icon: Icons.filter_alt_off_outlined,
                                  title: 'Filtro sem conversas',
                                  message:
                                      l10n.messagesFilterEmpty(filterLabel),
                                );
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.x1,
                                  bottom: AppSpacing.x7,
                                ),
                                itemCount: tiles.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.x3),
                                itemBuilder: (context, i) {
                                  final t = tiles[i];
                                  final timeStr = _formatTimeLabel(
                                    t.lastAt,
                                    locale: l10n.localeName,
                                  );

                                  return ConversationListCard(
                                    name: t.otherUserName,
                                    message: t.lastMessage.isNotEmpty
                                        ? t.lastMessage
                                        : l10n.chatNoMessagesSubtitle,
                                    timeLabel: timeStr,
                                    avatarUrl: t.otherUserPhotoUrl,
                                    serviceLabel: t.pedidoTitulo,
                                    unreadCount: t.unreadCount,
                                    isFavorite: t.isFavorite,
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
                                            otherUserPhotoUrl:
                                                t.otherUserPhotoUrl,
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
                                                      ? l10n
                                                          .messagesUnpinConversation
                                                      : l10n
                                                          .messagesPinConversation,
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
            ),
          ),
        );
      },
    );
  }

  int get _filterIndex {
    return switch (_filterMode) {
      'unread' => 1,
      'favorites' => 2,
      'groups' => 3,
      _ => 0,
    };
  }

  void _setFilterIndex(int index) {
    final next = switch (index) {
      1 => 'unread',
      2 => 'favorites',
      3 => 'groups',
      _ => 'all',
    };
    setState(() => _filterMode = next);
  }

  String _subtitleForRole() {
    if (widget.viewerRole == 'prestador') {
      return 'Converse com clientes e acompanhe oportunidades.';
    }
    return 'Converse com prestadores e acompanhe os seus servicos.';
  }

  String _formatTimeLabel(DateTime? lastAt, {required String locale}) {
    if (lastAt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(lastAt);
    if (diff.inDays == 0 && now.day == lastAt.day) {
      return DateTimeUtils.formatTime(lastAt, locale: locale);
    }
    return DateTimeUtils.formatDate(lastAt, locale: locale);
  }

  void _showNewConversationDialog(AppLocalizations l10n) {
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
  }

  void _showFilterSheet(AppLocalizations l10n) {
    final options = [
      _FilterOption(l10n.messagesFilterAll, 'all'),
      _FilterOption(l10n.messagesFilterUnread, 'unread'),
      _FilterOption(l10n.messagesFilterFavorites, 'favorites'),
      _FilterOption(l10n.messagesFilterGroups, 'groups'),
    ];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x4,
            0,
            AppSpacing.x4,
            AppSpacing.x4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                ListTile(
                  leading: Icon(
                    option.value == _filterMode
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                  ),
                  title: Text(option.label),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _filterMode = option.value);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption(this.label, this.value);

  final String label;
  final String value;
}

class _MessagesStateCard extends StatelessWidget {
  const _MessagesStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: AppCard(
        variant: AppCardVariant.outlined,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.x3),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.x3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
