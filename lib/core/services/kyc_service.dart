
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

class KycService {
  KycService._();
  static final KycService instance = KycService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _uid => AuthService.currentUser?.uid;

  /// Faz upload de um documento para a pasta segura de KYC.
  /// Type: 'front' ou 'back'.
  Future<String> uploadDocument(File file, String type) async {
    final uid = _uid;
    if (uid == null) throw Exception('Utilizador não autenticado');

    final ext = file.path.split('.').last;
    final path = 'kyc/$uid/${type}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child(path);
    
    // Metadata pode ser usada para regras de segurança (ex: admin only read)
    final meta = SettableMetadata(contentType: 'image/$ext', customMetadata: {'type': 'kyc'});

    await ref.putFile(file, meta);
    return await ref.getDownloadURL();
  }

  /// Submete o pedido de KYC com as URLs dos documentos.
  Future<void> submitKyc(String frontUrl, String backUrl) async {
    final uid = _uid;
    if (uid == null) throw Exception('Utilizador não autenticado');

    await _db.collection('prestadores').doc(uid).set({
      'kycStatus': 'pending',
      'kycSubmittedAt': FieldValue.serverTimestamp(),
      'kycDocs': {
        'front': frontUrl,
        'back': backUrl,
      },
    }, SetOptions(merge: true),);
  }

  /// Obtém o status atual do KYC.
  Future<String> getKycStatus() async {
    final uid = _uid;
    if (uid == null) return 'none';

    final doc = await _db.collection('prestadores').doc(uid).get();
    if (!doc.exists) return 'none';
    
    return (doc.data()?['kycStatus'] as String?) ?? 'none';
  }
}
