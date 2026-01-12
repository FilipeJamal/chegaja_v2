// lib/core/services/perfil_foto_service.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:chegaja_v2/core/services/auth_service.dart';

// Import condicional: web → perfil_foto_picker_web.dart
// mobile → perfil_foto_picker_mobile.dart
import 'perfil_foto_picker_stub.dart'
    if (dart.library.html) 'perfil_foto_picker_web.dart'
    if (dart.library.io) 'perfil_foto_picker_mobile.dart' as picker;

class PerfilFotoService {
  PerfilFotoService._();

  static final PerfilFotoService instance = PerfilFotoService._();

  /// Altera a foto do **prestador** (usa doc em `users/{uid}`).
  Future<void> alterarFotoPrestador(BuildContext context) async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precisas de iniciar sessão para alterar a foto.'),
        ),
      );
      return;
    }

    Uint8List? bytes;
    try {
      bytes = await picker.pickImageBytes(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao escolher imagem: $e'),
        ),
      );
      return;
    }

    if (bytes == null) {
      // utilizador cancelou
      return;
    }

    try {
      // Caminho simples: users/{uid}/perfil.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('perfil.jpg');

      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await uploadTask.ref.getDownloadURL();

      // Guarda o URL na coleção users
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'photoUrl': url,
        },
        SetOptions(merge: true),
      );

      // Opcional: atualiza também o perfil do FirebaseAuth
      try {
        await user.updatePhotoURL(url);
      } catch (_) {
        // se falhar, não é grave
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil atualizada.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar imagem: $e'),
        ),
      );
    }
  }


  /// Adiciona uma imagem ao portfólio do prestador (users/{uid}.portfolioImages).
  Future<void> adicionarImagemPortfolio(BuildContext context) async {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precisas de iniciar sessão para adicionar imagens.'),
        ),
      );
      return;
    }

    Uint8List? bytes;
    try {
      bytes = await picker.pickImageBytes(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao escolher imagem: $e'),
        ),
      );
      return;
    }

    if (bytes == null) return;

    try {
      final fileName = 'p_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('portfolio')
          .child(user.uid)
          .child(fileName);

      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'portfolioImages': FieldValue.arrayUnion([url]),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem adicionada ao portfólio.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar imagem: $e'),
        ),
      );
    }
  }

  /// Remove uma imagem do portfólio (e tenta apagar do Storage).
  Future<void> removerImagemPortfolio(
    BuildContext context, {
    required String url,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'portfolioImages': FieldValue.arrayRemove([url]),
        },
        SetOptions(merge: true),
      );

      // tenta remover também do Storage
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (_) {
        // pode falhar se a URL não for do Firebase Storage ou se não houver permissão
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagem removida.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover: $e')),
      );
    }
  }

}
