// lib/features/cliente/widgets/pedido_contato_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';

/// Shows the contact information (phone) for the other party in an order.
class ContatoSection extends StatelessWidget {
  final Pedido pedido;
  final bool isCliente;
  final String Function(Map<String, dynamic>) resolvePhone;
  final Future<void> Function(String) onCall;

  const ContatoSection({
    super.key,
    required this.pedido,
    required this.isCliente,
    required this.resolvePhone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final otherId = isCliente ? pedido.prestadorId : pedido.clienteId;
    if (otherId == null || otherId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final collection = isCliente ? 'prestadores' : 'users';
    final fallbackCollection = isCliente ? 'users' : null;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .doc(otherId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildContactCard(context, phone: '', loading: true);
        }
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final primaryPhone = resolvePhone(data);
        final shouldFallback =
            primaryPhone.isEmpty && fallbackCollection != null;

        if (shouldFallback) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(fallbackCollection)
                .doc(otherId)
                .snapshots(),
            builder: (context, fallbackSnap) {
              final fallbackData =
                  fallbackSnap.data?.data() ?? <String, dynamic>{};
              final fallbackPhone = resolvePhone(fallbackData);
              return _buildContactCard(
                context,
                phone: fallbackPhone,
              );
            },
          );
        }

        return _buildContactCard(
          context,
          phone: primaryPhone,
        );
      },
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required String phone,
    bool loading = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPhone = phone.isNotEmpty;
    final label = loading
        ? 'A carregar...'
        : (hasPhone ? phone : 'Telefone nao informado');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacto',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                Icons.phone_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (hasPhone)
                IconButton(
                  tooltip: 'Ligar',
                  onPressed: () => onCall(phone),
                  icon: Icon(Icons.call, color: colorScheme.primary),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
