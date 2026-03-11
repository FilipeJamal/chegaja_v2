import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chegaja_v2/core/config/app_config.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: AppConfig.functionsRegion,
  );
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  HttpsCallable _callable(String name) => _functions.httpsCallable(name);

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return <String, dynamic>{};
  }

  Stream<Map<String, dynamic>?> watchCurrentSubscription() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('subscriptions').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() ?? <String, dynamic>{};
      return {
        'id': snap.id,
        ...data,
      };
    });
  }

  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final res = await _callable('payments_getMySubscription').call();
    final data = _asMap(res.data);
    final sub = data['subscription'];
    if (sub == null) return null;
    return _asMap(sub);
  }

  Future<String> createCheckoutUrl({
    required String planId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final payload = <String, dynamic>{
      'planId': planId,
      if (successUrl != null && successUrl.trim().isNotEmpty)
        'successUrl': successUrl.trim(),
      if (cancelUrl != null && cancelUrl.trim().isNotEmpty)
        'cancelUrl': cancelUrl.trim(),
    };
    final res =
        await _callable('payments_createSubscriptionCheckout').call(payload);
    final data = _asMap(res.data);
    final url = (data['url'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw Exception('URL de checkout não retornou.');
    }
    return url;
  }

  Future<String> createBillingPortalUrl({String? returnUrl}) async {
    final payload = <String, dynamic>{
      if (returnUrl != null && returnUrl.trim().isNotEmpty)
        'returnUrl': returnUrl.trim(),
    };
    final res =
        await _callable('payments_createBillingPortalLink').call(payload);
    final data = _asMap(res.data);
    final url = (data['url'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw Exception('URL do portal não retornou.');
    }
    return url;
  }
}
