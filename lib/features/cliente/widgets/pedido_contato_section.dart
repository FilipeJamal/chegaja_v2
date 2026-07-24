// lib/features/cliente/widgets/pedido_contato_section.dart
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';

/// Placeholder deliberately kept hidden until a backend endpoint can disclose
/// the counterparty contact after validating the accepted provider grant.
///
/// Phone numbers must never be recovered from the legacy `users` or
/// `prestadores` collections: both are private and denied by Firestore Rules.
class ContatoSection extends StatelessWidget {
  final Pedido pedido;
  final bool isCliente;

  const ContatoSection({
    super.key,
    required this.pedido,
    required this.isCliente,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class PedidoProviderProfileAction extends StatelessWidget {
  final String? prestadorId;
  final VoidCallback onPressed;

  const PedidoProviderProfileAction({
    super.key,
    required this.prestadorId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedPrestadorId = prestadorId?.trim() ?? '';
    if (normalizedPrestadorId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const Key('pedido_provider_profile_action'),
          onPressed: onPressed,
          icon: const Icon(Icons.person_outline_rounded, size: 18),
          label: const Text('Ver perfil'),
        ),
      ),
    );
  }
}
