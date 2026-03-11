// lib/features/cliente/widgets/pedido_chat_widgets.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chegaja_v2/core/models/chat_message.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/features/common/mensagens/chat_thread_screen.dart';
import 'package:chegaja_v2/features/common/mensagens/widgets/chat_audio_player.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

// --------- CHAT EXPANDABLE ---------

/// Collapsible chat section shown in order details.
class ChatExpandable extends StatefulWidget {
  final String pedidoId;
  final bool isCliente;
  final String? otherUserId;
  final String? pedidoTitulo;

  const ChatExpandable({
    super.key,
    required this.pedidoId,
    required this.isCliente,
    this.otherUserId,
    this.pedidoTitulo,
  });

  @override
  State<ChatExpandable> createState() => _ChatExpandableState();
}

class _ChatExpandableState extends State<ChatExpandable> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = widget.isCliente ? 'cliente' : 'prestador';
      ChatService.instance.marcarEntreguesParaRole(
        pedidoId: widget.pedidoId,
        role: role,
      );
    });
  }

  void _toggleExpanded() {
    final newValue = !_expanded;
    setState(() {
      _expanded = newValue;
    });

    if (newValue) {
      final role = widget.isCliente ? 'cliente' : 'prestador';
      ChatService.instance.marcarVistasParaRole(
        pedidoId: widget.pedidoId,
        role: role,
      );
    }
  }

  void _openFullChat() {
    final l10n = AppLocalizations.of(context)!;
    final otherId = (widget.otherUserId ?? '').trim();
    if (otherId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatOpenFullUnavailable)),
      );
      return;
    }

    final viewerRole = widget.isCliente ? 'cliente' : 'prestador';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          pedidoId: widget.pedidoId,
          viewerRole: viewerRole,
          otherUserId: otherId,
          pedidoTitulo: widget.pedidoTitulo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ChatService.instance.streamChatMeta(widget.pedidoId),
      builder: (context, snapshot) {
        String subtitle = l10n.chatNoMessagesSubtitle;
        String countLabel = '';

        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data()!;
          final lastMessage = (data['lastMessage'] as String?) ?? '';
          final ts = data['lastMessageAt'];
          final messageCount = (data['messageCount'] as int?) ?? 0;

          DateTime? lastAt;
          if (ts is Timestamp) {
            lastAt = ts.toDate();
          } else if (ts is DateTime) {
            lastAt = ts;
          }

          if (lastMessage.isNotEmpty) {
            final preview = lastMessage.length > 40
                ? '${lastMessage.substring(0, 40)}...'
                : lastMessage;
            if (lastAt != null) {
              final time = DateFormat('HH:mm', l10n.localeName).format(lastAt);
              subtitle = l10n.chatPreviewWithTime(preview, time);
            } else {
              subtitle = preview;
            }
          } else {
            subtitle = l10n.chatNoMessagesSubtitle;
          }

          if (messageCount > 0) {
            countLabel = l10n.chatMessageCount(messageCount);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _toggleExpanded,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.orderChatTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (countLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        countLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _expanded ? l10n.actionClose : l10n.actionOpen,
                      style: TextStyle(
                        fontSize: 12,
                        color: primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: primary,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openFullChat,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l10n.chatOpenFullAction),
                ),
              ),
              const SizedBox(height: 4),
              ChatSection(
                pedidoId: widget.pedidoId,
                isCliente: widget.isCliente,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------- CHAT SECTION ----------------

/// Inline chat section with message list and send bar.
class ChatSection extends StatefulWidget {
  final String pedidoId;
  final bool isCliente;

  const ChatSection({
    super.key,
    required this.pedidoId,
    required this.isCliente,
  });

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentPosition() async {
    final l10n = AppLocalizations.of(context)!;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationServiceDisabled)),
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationPermissionDenied)),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationPermissionDeniedForever)),
      );
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.locationFetchError(e.toString()))),
      );
      return null;
    }
  }

  Future<void> _sendLocation() async {
    if (_sending) return;

    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.chatAuthRequired,
          ),
        ),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final pos = await _getCurrentPosition();
      if (pos == null) return;

      if (!mounted) return;
      final lat = pos.latitude;
      final lng = pos.longitude;
      final url = 'https://maps.google.com/?q=$lat,$lng';
      final label = l10n.locationApproxLabel;
      final role = widget.isCliente ? 'cliente' : 'prestador';

      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderId: user.uid,
        senderRole: role,
        text: '$label: $url',
        extra: {
          'type': 'location',
          'latitude': lat,
          'longitude': lng,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatSendError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.chatAuthRequired,
          ),
        ),
      );
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
    });

    try {
      await ChatService.instance.sendMessage(
        pedidoId: widget.pedidoId,
        senderId: user.uid,
        senderRole: widget.isCliente ? 'cliente' : 'prestador',
        text: text,
      );
      _controller.clear();

      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.chatSendError(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Hoje" / "Ontem" / data (dd/MM/yyyy)
  String _buildDayLabel(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    final diff = today.difference(d).inDays;

    if (diff == 0) return l10n.todayLabel;
    if (diff == 1) return l10n.yesterdayLabel;

    return DateFormat('dd/MM/yyyy', l10n.localeName).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.currentUser;
    final canSend = user != null;
    final viewerRole = widget.isCliente ? 'cliente' : 'prestador';

    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream:
                  ChatService.instance.streamMessagesForPedido(widget.pedidoId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      l10n.chatLoadError(snapshot.error.toString()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.chatEmptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    final bool isMine;
                    if (widget.isCliente) {
                      isMine = msg.senderRole == 'cliente';
                    } else {
                      isMine = msg.senderRole == 'prestador';
                    }

                    // ----- HEADER DE DIA (Hoje / Ontem / data) -----
                    Widget? dayHeader;
                    final msgDate = msg.createdAt;
                    final next = (index + 1 < messages.length)
                        ? messages[index + 1]
                        : null;
                    final nextDate = next?.createdAt ?? msgDate;
                    final showHeader =
                        next == null || !_isSameDay(msgDate, nextDate);

                    if (showHeader) {
                      final label = _buildDayLabel(msgDate);
                      dayHeader = Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (dayHeader != null) dayHeader,
                        ChatBubble(
                          message: msg,
                          isMine: isMine,
                          viewerRole: viewerRole,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.locationUseCurrent,
                  onPressed: canSend && !_sending ? _sendLocation : null,
                  icon: const Icon(Icons.my_location),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: canSend && !_sending,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText:
                          canSend ? l10n.chatInputHint : l10n.chatLoginHint,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: canSend && !_sending ? _send : null,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------- CHAT BUBBLE ---------

/// Single chat message bubble with status indicators.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final String viewerRole; // "cliente" ou "prestador"

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.viewerRole,
  });

  static final RegExp _urlPattern = RegExp(r'(https?://[^\s]+)');

  String? _extractUrl(String text) {
    final match = _urlPattern.firstMatch(text);
    if (match == null) return null;
    return match.group(0);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(
      uri,
      mode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    final bgColor = isMine ? const Color(0xFFE1FFC7) : Colors.white;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isMine ? 12 : 0),
      bottomRight: Radius.circular(isMine ? 0 : 12),
    );

    final senderLabel = message.senderRole == 'prestador'
        ? l10n.roleLabelProvider
        : message.senderRole == 'cliente'
            ? l10n.roleLabelCustomer
            : l10n.roleLabelSystem;

    final timeStr =
        DateFormat('HH:mm', l10n.localeName).format(message.createdAt);

    final contentAlignment =
        isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mediaUrl = message.mediaUrl;
    final isAudio = message.isAudio && mediaUrl != null;
    final isFile = message.isFile && mediaUrl != null;
    final isImage = message.isImage && mediaUrl != null;
    final text = message.text;
    final url = _extractUrl(text);
    final Widget messageBody;

    if (isAudio) {
      final audioUrl = mediaUrl;
      final name = (message.fileName ?? l10n.chatAudioLabel).trim();
      final player = ChatAudioPlayer(
        url: audioUrl,
        title: name,
        compact: true,
        accentColor: theme.colorScheme.primary,
      );
      if (message.text.trim().isNotEmpty) {
        messageBody = Column(
          crossAxisAlignment: contentAlignment,
          children: [
            player,
            const SizedBox(height: 6),
            Text(
              message.text,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        );
      } else {
        messageBody = player;
      }
    } else if (isFile) {
      final name = (message.fileName ?? l10n.chatFileLabel).trim();
      final subtitle = message.fileSize != null
          ? '${(message.fileSize! / 1024).toStringAsFixed(0)} KB'
          : null;

      messageBody = InkWell(
        onTap: () => _openUrl(mediaUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : l10n.chatFileLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (isImage) {
      messageBody = InkWell(
        onTap: () => _openUrl(mediaUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, size: 18),
            const SizedBox(width: 6),
            Text(
              l10n.chatImageLabel,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
    } else if (url != null) {
      messageBody = Column(
        crossAxisAlignment: contentAlignment,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => _openUrl(url),
            icon: const Icon(Icons.open_in_new, size: 14),
            label: Text(l10n.chatOpenLink),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      );
    } else {
      messageBody = Text(
        text,
        style: const TextStyle(fontSize: 13),
      );
    }

    // STATUS enviado/entregue/visto azul para mensagens enviadas por mim
    Widget? statusIcon;
    if (isMine &&
        (message.senderRole == 'cliente' ||
            message.senderRole == 'prestador')) {
      final bool viewerIsCliente = viewerRole == 'cliente';
      final bool deliveredToOther = viewerIsCliente
          ? message.deliveredToPrestador
          : message.deliveredToCliente;
      final bool seenByOther =
          viewerIsCliente ? message.seenByPrestador : message.seenByCliente;

      if (seenByOther) {
        // dois certinhos azuis
        statusIcon = const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.blueAccent,
        );
      } else if (deliveredToOther) {
        // dois certinhos cinza
        statusIcon = Icon(
          Icons.done_all,
          size: 14,
          color: Colors.grey.shade600,
        );
      } else {
        // um certinho cinza
        statusIcon = Icon(
          Icons.check,
          size: 14,
          color: Colors.grey.shade600,
        );
      }
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: isMine
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: contentAlignment,
          children: [
            Text(
              isMine ? l10n.youLabel : senderLabel,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            messageBody,
            if (timeStr.isNotEmpty || statusIcon != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timeStr.isNotEmpty)
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (statusIcon != null) ...[
                    const SizedBox(width: 4),
                    statusIcon,
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
