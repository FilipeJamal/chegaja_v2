import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload genérico de arquivo
  static Future<String> uploadFile({
    required File file,
    required String destinationPath,
    String? contentType,
  }) async {
    final ref = _storage.ref(destinationPath);
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {'uploadedBy': 'ChegaJaApp'},
    );

    final task = await ref.putFile(file, metadata);
    return await task.ref.getDownloadURL();
  }

  /// Upload genérico de bytes (web)
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String destinationPath,
    String? contentType,
  }) async {
    final ref = _storage.ref(destinationPath);
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: {'uploadedBy': 'ChegaJaApp'},
    );

    final task = await ref.putData(bytes, metadata);
    return await task.ref.getDownloadURL();
  }

  /// Upload de imagem (File) para um caminho específico.
  static Future<String> uploadImage({
    required File file,
    required String destinationPath,
  }) async {
    return uploadFile(
      file: file,
      destinationPath: destinationPath,
      contentType: 'image/jpeg',
    );
  }

  /// Upload de imagem (bytes) para web.
  static Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String destinationPath,
  }) async {
    return uploadBytes(
      bytes: bytes,
      destinationPath: destinationPath,
      contentType: 'image/jpeg',
    );
  }

  /// Gera um caminho único para Stories
  static String generateStoryPath(String uid) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'stories/$uid/story_$timestamp.jpg';
  }

  /// Gera caminho para anexos de Chat
  static String generateChatAttachmentPath({
    required String pedidoId, 
    required String filename,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // sanitized filename
    final safeName = filename.replaceAll(RegExp(r'[^a-zA-Z0-9.]+'), '_');
    return 'chat/$pedidoId/${timestamp}_$safeName';
  }
}
