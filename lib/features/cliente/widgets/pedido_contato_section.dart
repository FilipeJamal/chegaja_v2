// lib/features/cliente/widgets/pedido_contato_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/models/pedido.dart';
import 'package:chegaja_v2/features/common/utils/open_public_profile.dart';

/// Shows the contact information (phone) for the other party in an order.
class ContatoSection extends StatelessWidget {
  final Pedido pedido;
  final bool isCliente;
  final String Function(Map<String, dynamic>) resolvePhone;
  final Future<void> Function(String) onCall;
  final FirebaseFirestore? firestore;

  const ContatoSection({
    super.key,
    required this.pedido,
    required this.isCliente,
    required this.resolvePhone,
    required this.onCall,
    this.firestore,
  });

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final otherId = isCliente ? pedido.prestadorId : pedido.clienteId;
    if (otherId == null || otherId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final collection = isCliente ? 'prestadores' : 'users';
    final fallbackCollection = isCliente ? 'users' : null;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection(collection).doc(otherId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildContactCard(
            context,
            phone: '',
            loading: true,
            profileUserId: isCliente ? otherId : null,
          );
        }
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final primaryPhone = resolvePhone(data);
        final profileName = _resolveProfileName(data);
        final profilePhotoUrl = _resolveProfilePhotoUrl(data);
        final shouldFallback =
            primaryPhone.isEmpty && fallbackCollection != null;

        if (shouldFallback) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db.collection(fallbackCollection).doc(otherId).snapshots(),
            builder: (context, fallbackSnap) {
              final fallbackData =
                  fallbackSnap.data?.data() ?? <String, dynamic>{};
              final fallbackPhone = resolvePhone(fallbackData);
              return _buildContactCard(
                context,
                phone: fallbackPhone,
                profileUserId: isCliente ? otherId : null,
                profileName: profileName.isNotEmpty
                    ? profileName
                    : _resolveProfileName(fallbackData),
                profilePhotoUrl:
                    profilePhotoUrl ?? _resolveProfilePhotoUrl(fallbackData),
              );
            },
          );
        }

        return _buildContactCard(
          context,
          phone: primaryPhone,
          profileUserId: isCliente ? otherId : null,
          profileName: profileName,
          profilePhotoUrl: profilePhotoUrl,
        );
      },
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required String phone,
    bool loading = false,
    String? profileUserId,
    String? profileName,
    String? profilePhotoUrl,
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
        PedidoProviderProfileAction(
          prestadorId: profileUserId,
          onPressed: () => openPublicProfile(
            context,
            userId: profileUserId ?? '',
            role: 'prestador',
            initialName: profileName,
            initialPhotoUrl: profilePhotoUrl,
          ),
        ),
      ],
    );
  }

  String _resolveProfileName(Map<String, dynamic> data) {
    return _firstNonEmpty([
      data['nome'],
      data['displayName'],
      data['name'],
    ]);
  }

  String? _resolveProfilePhotoUrl(Map<String, dynamic> data) {
    return _firstValidUrl([
      data['photoUrl'],
      data['fotoUrl'],
      data['avatarUrl'],
    ]);
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

String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') {
      return text;
    }
  }
  return '';
}

String? _firstValidUrl(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') continue;
    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme) {
      return text;
    }
  }
  return null;
}
