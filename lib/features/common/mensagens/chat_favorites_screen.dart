import 'package:flutter/material.dart';
import 'package:chegaja_v2/core/utils/date_time_utils.dart';

import 'package:chegaja_v2/core/models/chat_message.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

class ChatFavoritesScreen extends StatelessWidget {
  const ChatFavoritesScreen({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    // timeFormat removed

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatFavoritesTitle),
      ),
      body: StreamBuilder<List<ChatMessage>>(
        stream: ChatService.instance.streamStarredMessages(pedidoId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(l10n.chatLoadError(snap.error.toString())));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data ?? <ChatMessage>[];
          if (items.isEmpty) {
            return Center(child: Text(l10n.chatFavoritesEmpty));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final msg = items[index];
              final preview = _previewForMessage(msg, l10n);
              final time = DateTimeUtils.formatDateTime(msg.createdAt, locale: locale);
              return ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(time),
                trailing: IconButton(
                  icon: const Icon(Icons.star_border),
                  tooltip: l10n.chatUnstarAction,
                  onPressed: () {
                    ChatService.instance.setMessageStarred(
                      pedidoId: pedidoId,
                      messageId: msg.id,
                      starred: false,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
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
