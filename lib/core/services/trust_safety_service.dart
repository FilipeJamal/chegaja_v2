import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/models/trust_safety_report.dart';
import 'package:chegaja_v2/core/models/user_block.dart';
import 'package:chegaja_v2/core/services/auth_service.dart';

typedef CurrentUserIdProvider = String? Function();

class TrustSafetyService {
  TrustSafetyService({
    FirebaseFirestore? firestore,
    CurrentUserIdProvider? currentUserIdProvider,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _currentUserIdProvider =
            currentUserIdProvider ?? (() => AuthService.currentUser?.uid);

  static final TrustSafetyService instance = TrustSafetyService();

  final FirebaseFirestore _db;
  final CurrentUserIdProvider _currentUserIdProvider;

  String get _requiredUid {
    final uid = _currentUserIdProvider()?.trim();
    if (uid == null || uid.isEmpty) {
      throw StateError('Utilizador nao autenticado');
    }
    return uid;
  }

  Future<DocumentReference<Map<String, dynamic>>> createReport({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReasonCode reasonCode,
    required ReportSeverity severity,
    String? details,
    String? targetOwnerId,
    String? sourceContext,
    String? pedidoId,
    String? chatId,
    String? messageId,
    String? mediaUrl,
    String? mediaPath,
  }) async {
    final uid = _requiredUid;
    final report = TrustSafetyReport.create(
      reporterId: uid,
      targetType: targetType,
      targetId: targetId,
      reasonCode: reasonCode,
      severity: severity,
      details: details,
      targetOwnerId: targetOwnerId,
      sourceContext: sourceContext,
      pedidoId: pedidoId,
      chatId: chatId,
      messageId: messageId,
      mediaUrl: mediaUrl,
      mediaPath: mediaPath,
    );

    final payload = report.toFirestore()
      ..addAll(<String, dynamic>{
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

    return _db.collection('reports').add(payload);
  }

  Future<void> blockUser({
    required String blockedUid,
    String? reason,
    String? source,
  }) async {
    final uid = _requiredUid;
    final block = UserBlock.create(
      ownerUid: uid,
      blockedUid: blockedUid,
      reason: reason,
      source: source,
    );

    await _blockedUsersRef(uid).doc(block.blockedUid).set(
          block.toFirestore()
            ..addAll(<String, dynamic>{
              'createdAt': FieldValue.serverTimestamp(),
            }),
        );
  }

  Future<void> unblockUser(String blockedUid) async {
    final uid = _requiredUid;
    await _blockedUsersRef(uid).doc(blockedUid.trim()).delete();
  }

  Stream<List<UserBlock>> blockedUsersStream() {
    final uid = _requiredUid;
    return _blockedUsersRef(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserBlock.fromFirestoreMap(
                ownerUid: uid,
                id: doc.id,
                data: doc.data(),
              ))
          .whereType<UserBlock>()
          .toList(growable: false);
    });
  }

  Future<List<UserBlock>> getBlockedUsers() async {
    final uid = _requiredUid;
    final snapshot = await _blockedUsersRef(uid).get();
    return snapshot.docs
        .map((doc) => UserBlock.fromFirestoreMap(
              ownerUid: uid,
              id: doc.id,
              data: doc.data(),
            ))
        .whereType<UserBlock>()
        .toList(growable: false);
  }

  CollectionReference<Map<String, dynamic>> _blockedUsersRef(String uid) {
    return _db.collection('users_private').doc(uid).collection('blockedUsers');
  }
}
