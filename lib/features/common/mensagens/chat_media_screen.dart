import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chegaja_v2/core/models/chat_message.dart';
import 'package:chegaja_v2/core/services/chat_service.dart';
import 'package:chegaja_v2/features/common/widgets/media_viewer_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

class ChatMediaScreen extends StatelessWidget {
  ChatMediaScreen({super.key, required this.pedidoId});

  final String pedidoId;
  final RegExp _urlPattern = RegExp(r'(https?://[^\s]+)');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService.instance.streamMessages(pedidoId, limit: 500),
      builder: (context, snap) {
        final messages = snap.data ?? <ChatMessage>[];
        final images = messages.where((m) => m.isImage).toList();
        final audio = messages.where((m) => m.isAudio).toList();
        final files = messages.where((m) => m.isFile).toList();
        final links = messages.where((m) => _urlPattern.hasMatch(m.text)).toList();

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.chatMediaTitle),
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.chatMediaPhotosTab),
                  Tab(text: l10n.chatMediaLinksTab),
                  Tab(text: l10n.chatMediaAudioTab),
                  Tab(text: l10n.chatMediaFilesTab),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildImages(context, images, l10n),
                _buildLinks(context, links, l10n),
                _buildFiles(context, audio, l10n, isAudio: true),
                _buildFiles(context, files, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImages(BuildContext context, List<ChatMessage> items, AppLocalizations l10n) {
    if (items.isEmpty) {
      return Center(child: Text(l10n.chatMediaEmptyPhotos));
    }

    final urls = items.map((e) => e.mediaUrl).whereType<String>().toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) {
        final url = urls[index];
        return GestureDetector(
          onTap: () {
            MediaViewerScreen.open(
              context,
              urls: urls,
              initialIndex: index,
              title: l10n.chatMediaPhotosTab,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinks(BuildContext context, List<ChatMessage> items, AppLocalizations l10n) {
    if (items.isEmpty) {
      return Center(child: Text(l10n.chatMediaEmptyLinks));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final msg = items[index];
        final match = _urlPattern.firstMatch(msg.text);
        final url = match?.group(0) ?? msg.text;
        return ListTile(
          leading: const Icon(Icons.link),
          title: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => _openUrl(url),
        );
      },
    );
  }

  Widget _buildFiles(
    BuildContext context,
    List<ChatMessage> items,
    AppLocalizations l10n, {
    bool isAudio = false,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(isAudio ? l10n.chatMediaEmptyAudio : l10n.chatMediaEmptyFiles),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final msg = items[index];
        final name = (msg.fileName ?? (isAudio ? l10n.chatAudioLabel : l10n.chatFileLabel)).trim();
        final subtitle = msg.fileSize != null
            ? '${(msg.fileSize! / 1024).toStringAsFixed(0)} KB'
            : null;
        return ListTile(
          leading: Icon(isAudio ? Icons.audiotrack : Icons.insert_drive_file),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: subtitle != null ? Text(subtitle) : null,
          onTap: () {
            final url = msg.mediaUrl;
            if (url != null) _openUrl(url);
          },
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );
  }
}
