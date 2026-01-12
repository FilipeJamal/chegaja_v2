import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:chegaja_v2/core/models/chat_message.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final timeFormat = DateFormat('dd/MM/yyyy HH:mm', locale);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.chatSearchHint,
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() => _query = value.trim());
          },
        ),
      ),
      body: StreamBuilder<List<ChatMessage>>(
        stream: ChatService.instance.streamMessages(widget.pedidoId, limit: 500),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(l10n.chatLoadError(snap.error.toString())));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_query.isEmpty) {
            return Center(child: Text(l10n.chatSearchEmpty));
          }

          final queryLower = _query.toLowerCase();
          final items = (snap.data ?? <ChatMessage>[])
              .where((m) => _matchesQuery(m, queryLower))
              .toList();

          if (items.isEmpty) {
            return Center(child: Text(l10n.chatSearchNoResults));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final msg = items[index];
              final preview = _previewForMessage(msg, l10n);
              final time = timeFormat.format(msg.createdAt);
              return ListTile(
                leading: const Icon(Icons.search),
                title: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(time),
              );
            },
          );
        },
      ),
    );
  }

  bool _matchesQuery(ChatMessage msg, String queryLower) {
    final text = msg.text.toLowerCase();
    final fileName = (msg.fileName ?? '').toLowerCase();
    return text.contains(queryLower) || fileName.contains(queryLower);
  }

  String _previewForMessage(ChatMessage msg, AppLocalizations l10n) {
    if (msg.type == 'call') {
      return msg.text.isNotEmpty ? msg.text : l10n.chatCallEntryLabel;
    }
    if (msg.isImage) return l10n.chatImageLabel;
    if (msg.isAudio) return l10n.chatAudioLabel;
    if (msg.isFile) return l10n.chatFileLabel;
    return msg.text;
  }
}
