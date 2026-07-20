import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/legal/legal_documents.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

class LegalConsentService {
  LegalConsentService._();

  static final instance = LegalConsentService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  Future<bool> hasCurrentConsent() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return false;
    final snapshot = await _db.collection('users_private').doc(uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final consent = data['legalConsent'];
    return consent is Map &&
        consent['version'] == LegalDocuments.version &&
        consent['ageConfirmed'] == true;
  }

  Future<void> acceptCurrent({String locale = 'pt_MZ'}) async {
    await _functions.httpsCallable('legal_acceptDocuments').call({
      'version': LegalDocuments.version,
      'locale': locale,
      'termsAccepted': true,
      'privacyAccepted': true,
      'ageConfirmed': true,
    });
  }
}
