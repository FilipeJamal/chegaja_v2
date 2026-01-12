// lib/core/services/perfil_foto_picker_web.dart
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Picker para **Flutter Web** usando <input type="file">.
/// Não depende de plugin nenhum.
Future<Uint8List?> pickImageBytes(BuildContext context) async {
  final completer = Completer<Uint8List?>();

  try {
    final input = web.HTMLInputElement()..accept = 'image/*';
    input.click();

    web.EventStreamProviders.changeEvent.forTarget(input).first.then(
      (_) async {
        final files = input.files;
        final file =
            (files != null && files.length > 0) ? files.item(0) : null;
        if (file == null) {
          completer.complete(null); // utilizador cancelou
          return;
        }

        try {
          final buffer = await file.arrayBuffer().toDart;
          completer.complete(Uint8List.view(buffer.toDart));
        } catch (e) {
          completer.completeError('Erro ao ler ficheiro: $e');
        }
      },
      onError: (e) {
        completer.completeError('Erro ao selecionar ficheiro: $e');
      },
    );
  } catch (e) {
    completer.completeError(e);
  }

  return completer.future;
}
