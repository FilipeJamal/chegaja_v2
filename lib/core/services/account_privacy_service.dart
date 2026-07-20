import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

class AccountDeletionState {
  const AccountDeletionState({
    required this.status,
    this.executeAt,
  });

  final String status;
  final DateTime? executeAt;

  bool get isPending => status == 'pending' || status == 'pending_active_work';

  factory AccountDeletionState.fromMap(Map<String, dynamic> data) {
    final rawDate = data['executeAt'];
    return AccountDeletionState(
      status: data['status']?.toString() ?? '',
      executeAt: rawDate is Timestamp ? rawDate.toDate() : null,
    );
  }
}

class AccountPrivacyService {
  AccountPrivacyService._();

  static final AccountPrivacyService instance = AccountPrivacyService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  Stream<AccountDeletionState?> watchDeletionState() {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('account_deletion_requests').doc(uid).snapshots().map(
          (snapshot) => snapshot.exists
              ? AccountDeletionState.fromMap(snapshot.data()!)
              : null,
        );
  }

  Future<void> requestDeletion(String confirmation) async {
    await _functions.httpsCallable('account_requestDeletion').call({
      'confirmation': confirmation,
    });
  }

  Future<void> cancelDeletion() async {
    await _functions.httpsCallable('account_cancelDeletion').call();
  }
}
