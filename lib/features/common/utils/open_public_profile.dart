import 'package:flutter/material.dart';

import 'package:chegaja_v2/features/common/perfil_publico_screen.dart';

Future<T?> openPublicProfile<T>(
  BuildContext context, {
  required String userId,
  required String role,
  String? initialName,
  String? initialPhotoUrl,
}) {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty) {
    return Future<T?>.value();
  }

  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => PublicProfileScreen(
        userId: normalizedUserId,
        role: role,
        initialName: _emptyToNull(initialName),
        initialPhotoUrl: _emptyToNull(initialPhotoUrl),
      ),
    ),
  );
}

String? _emptyToNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
