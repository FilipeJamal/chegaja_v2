import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

class KycService {
  KycService._();

  static final KycService instance = KycService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  String? _activeSubmissionId;

  String? get _uid => AuthService.currentUser?.uid;

  void _assertEnabled() {
    if (!AppConfig.kycEnabled) {
      throw StateError(
        'A verificacao de identidade ainda nao esta disponivel.',
      );
    }
    if (!AuthService.hasVerifiedPhone) {
      throw StateError('Confirma primeiro o telefone.');
    }
  }

  /// Uploads a document without creating or persisting a download URL.
  /// The returned value is an internal Storage object path.
  Future<String> uploadDocument(File file, String type) async {
    _assertEnabled();
    final uid = _uid;
    if (uid == null) throw StateError('Utilizador nao autenticado.');
    await _ensureUploadWindow();
    final normalizedType = type == 'back' ? 'back' : 'front';
    final extension = file.path.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final submissionId = _activeSubmissionId!;
    final path = 'kyc_pending/$uid/$submissionId/$normalizedType.$extension';
    await _storage.ref(path).putFile(
          file,
          SettableMetadata(
            contentType: contentType,
            customMetadata: {
              'ownerUid': uid,
              'documentSide': normalizedType,
            },
          ),
        );
    return path;
  }

  Future<void> submitKyc(
    String frontPath,
    String backPath, {
    String consentVersion = 'kyc-consent-2026-07-20',
  }) async {
    _assertEnabled();
    await submitDocumentPaths(
      [frontPath, backPath],
      consentVersion: consentVersion,
    );
  }

  Future<void> submitDocumentPaths(
    List<String> documentPaths, {
    String consentVersion = 'kyc-consent-2026-07-20',
  }) async {
    _assertEnabled();
    await _functions.httpsCallable('kyc_submit').call({
      'documentPaths': documentPaths,
      'consentVersion': consentVersion,
    });
    _activeSubmissionId = null;
  }

  Future<String> getKycStatus() async {
    final uid = _uid;
    if (uid == null || !AppConfig.kycEnabled) return 'none';
    final doc = await _db.collection('kyc_submissions').doc(uid).get();
    return (doc.data()?['status'] as String?) ?? 'none';
  }

  Future<void> deleteMySubmission() async {
    if (_uid == null) throw StateError('Utilizador nao autenticado.');
    await _functions.httpsCallable('kyc_deleteMySubmission').call();
    _activeSubmissionId = null;
  }

  Future<void> _ensureUploadWindow() async {
    if (_activeSubmissionId != null) return;
    final response =
        await _functions.httpsCallable('kyc_beginSubmission').call();
    final data = Map<String, dynamic>.from(response.data as Map);
    final submissionId = (data['submissionId'] as String?)?.trim();
    if (submissionId == null || submissionId.isEmpty) {
      throw StateError('Nao foi possivel abrir a janela segura de envio.');
    }
    _activeSubmissionId = submissionId;
    await AuthService.currentUser?.getIdTokenResult(true);
  }
}
