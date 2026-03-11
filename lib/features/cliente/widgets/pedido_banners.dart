// lib/features/cliente/widgets/pedido_banners.dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/cliente/aguardando_prestador_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

/// Banner shown while searching for a provider.
class BannerAguardandoPrestador extends StatelessWidget {
  final String pedidoId;

  const BannerAguardandoPrestador({
    super.key,
    required this.pedidoId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.lookingForProviderBanner,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AguardandoPrestadorScreen(
                    pedidoId: pedidoId,
                  ),
                ),
              );
            },
            child: Text(l10n.actionView),
          ),
        ],
      ),
    );
  }
}

/// Generic action banner for the provider (icon + text + button).
class BannerAcaoPrestador extends StatelessWidget {
  final IconData icon;
  final String texto;
  final String botao;
  final VoidCallback onPressed;

  const BannerAcaoPrestador({
    super.key,
    required this.icon,
    required this.texto,
    required this.botao,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onPressed,
            child: Text(botao),
          ),
        ],
      ),
    );
  }
}
