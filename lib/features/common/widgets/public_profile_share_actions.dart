import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:chegaja_v2/core/services/public_profile_link_service.dart';

typedef PublicProfileCopyCallback = Future<void> Function(String publicUrl);
typedef PublicProfileOpenUriCallback = Future<bool> Function(Uri uri);

class PublicProfileShareActions extends StatelessWidget {
  const PublicProfileShareActions({
    super.key,
    required this.handle,
    required this.displayName,
    this.baseUrl = PublicProfileLinkService.defaultBaseUrl,
    this.showWhatsApp = true,
    this.showFacebook = true,
    this.framed = true,
    this.onCopyLink,
    this.onOpenWhatsApp,
    this.onOpenFacebook,
  });

  final String? handle;
  final String? displayName;
  final String baseUrl;
  final bool showWhatsApp;
  final bool showFacebook;
  final bool framed;
  final PublicProfileCopyCallback? onCopyLink;
  final PublicProfileOpenUriCallback? onOpenWhatsApp;
  final PublicProfileOpenUriCallback? onOpenFacebook;

  @override
  Widget build(BuildContext context) {
    final shareData = _ShareData.tryCreate(
      handle: handle,
      displayName: displayName,
      baseUrl: baseUrl,
    );
    if (shareData == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Partilhar perfil',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shareData.url,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              key: const Key('public_profile_copy_link_button'),
              onPressed: () => _copyLink(context, shareData.url),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Copiar link'),
            ),
            if (showWhatsApp)
              OutlinedButton.icon(
                key: const Key('public_profile_whatsapp_button'),
                onPressed: () => _openShare(
                  context,
                  uri: PublicProfileLinkService.whatsAppShareUri(
                    shareData.text,
                  ),
                  fallbackUrl: shareData.url,
                  opener: onOpenWhatsApp,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('WhatsApp'),
              ),
            if (showFacebook)
              OutlinedButton.icon(
                key: const Key('public_profile_facebook_button'),
                onPressed: () => _openShare(
                  context,
                  uri: PublicProfileLinkService.facebookShareUri(
                    shareData.url,
                  ),
                  fallbackUrl: shareData.url,
                  opener: onOpenFacebook,
                ),
                icon: const Icon(Icons.public_rounded),
                label: const Text('Facebook'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Para Instagram, copia o link e cola na bio, story ou mensagem.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (!framed) return content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: content,
    );
  }

  Future<void> _copyLink(
    BuildContext context,
    String url, {
    bool showSuccess = true,
  }) async {
    try {
      if (onCopyLink != null) {
        await onCopyLink!(url);
      } else {
        await Clipboard.setData(ClipboardData(text: url));
      }
      if (showSuccess && context.mounted) {
        _showSnack(context, 'Link copiado.');
      }
    } catch (_) {
      if (context.mounted) {
        _showSnack(context, 'Nao conseguimos copiar o link agora.');
      }
    }
  }

  Future<void> _openShare(
    BuildContext context, {
    required Uri uri,
    required String fallbackUrl,
    required PublicProfileOpenUriCallback? opener,
  }) async {
    var opened = false;
    try {
      if (opener != null) {
        opened = await opener(uri);
      } else {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      opened = false;
    }

    if (opened) return;

    await _copyLink(context, fallbackUrl, showSuccess: false);
    if (context.mounted) {
      _showSnack(context, 'Nao conseguimos abrir a partilha. Link copiado.');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ShareData {
  const _ShareData({
    required this.url,
    required this.text,
  });

  final String url;
  final String text;

  static _ShareData? tryCreate({
    required String? handle,
    required String? displayName,
    required String baseUrl,
  }) {
    try {
      final url = PublicProfileLinkService.publicUrlForHandle(
        handle ?? '',
        baseUrl: baseUrl,
      );
      final text = PublicProfileLinkService.shareTextForProvider(
        displayName: displayName ?? '',
        handle: handle ?? '',
        url: url,
      );
      return _ShareData(url: url, text: text);
    } catch (_) {
      return null;
    }
  }
}
