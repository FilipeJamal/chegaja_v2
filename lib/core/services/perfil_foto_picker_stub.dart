// lib/core/services/perfil_foto_picker_stub.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Implementação “vazia” usada se nenhuma outra se aplicar.
/// Na prática, no teu caso só entra se algum dia correres em
/// uma plataforma estranha.
Future<Uint8List?> pickImageBytes(BuildContext context) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Alterar foto não está disponível nesta plataforma.',
      ),
    ),
  );
  return null;
}
