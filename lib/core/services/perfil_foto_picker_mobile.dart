// lib/core/services/perfil_foto_picker_mobile.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Picker para Android / iOS usando o plugin image_picker.
Future<Uint8List?> pickImageBytes(BuildContext context) async {
  final picker = ImagePicker();

  final XFile? picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );

  if (picked == null) {
    return null; // utilizador cancelou
  }

  return picked.readAsBytes();
}
