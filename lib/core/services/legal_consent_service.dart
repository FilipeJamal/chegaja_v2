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
    if (!LegalDocuments.isAvailableForCurrentMarket) return false;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return false;
    final snapshot = await _db.collection('users_private').doc(uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final consent = data['legalConsent'];
    if (consent is! Map ||
        consent['version'] != LegalDocuments.version ||
        consent['ageConfirmed'] != true) {
      return false;
    }
    final consentMarketId = consent['marketId']?.toString().trim();
    if (consentMarketId == null || consentMarketId.isEmpty) {
      // Compatibilidade limitada aos consentimentos históricos do mercado
      // para o qual esta versão jurídica foi escrita. Um consentimento legado
      // sem mercado nunca pode atravessar para uma nova operação.
      return AppConfig.pilotMarket.id == LegalDocuments.marketId;
    }
    return consentMarketId == AppConfig.pilotMarket.id;
  }

  Future<void> acceptCurrent({String? locale}) async {
    if (!LegalDocuments.isAvailableForCurrentMarket) {
      throw StateError(LegalDocuments.availabilityMessage);
    }
    await _functions.httpsCallable('legal_acceptDocuments').call({
      'version': LegalDocuments.version,
      'marketId': AppConfig.pilotMarket.id,
      'locale': locale ?? AppConfig.pilotMarket.locale.toString(),
      'termsAccepted': true,
      'privacyAccepted': true,
      'ageConfirmed': true,
    });
  }
}
