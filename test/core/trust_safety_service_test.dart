import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/services/trust_safety_service.dart';

void main() {
  group('TrustSafetyService', () {
    test('createReport writes a pending review report for current user',
        () async {
      final db = FakeFirebaseFirestore();
      final service = TrustSafetyService(
        firestore: db,
        currentUserIdProvider: () => 'client1',
      );

      await service.createReport(
        targetType: ReportTargetType.providerProfile,
        targetId: 'provider1',
        reasonCode: ReportReasonCode.fraud,
        severity: ReportSeverity.high,
        details: 'Perfil parece enganoso',
        targetOwnerId: 'provider1',
      );

      final snap = await db.collection('reports').get();
      expect(snap.docs, hasLength(1));

      final data = snap.docs.single.data();
      expect(data['reporterId'], 'client1');
      expect(data['targetType'], 'provider_profile');
      expect(data['targetId'], 'provider1');
      expect(data['reasonCode'], 'fraud');
      expect(data['severity'], 'high');
      expect(data['status'], 'pending_review');
      expect(data['details'], 'Perfil parece enganoso');
      expect(data.containsKey('reviewedBy'), isFalse);
    });

    test('createReport requires authentication', () async {
      final db = FakeFirebaseFirestore();
      final service = TrustSafetyService(
        firestore: db,
        currentUserIdProvider: () => null,
      );

      expect(
        service.createReport(
          targetType: ReportTargetType.providerProfile,
          targetId: 'provider1',
          reasonCode: ReportReasonCode.fraud,
          severity: ReportSeverity.high,
        ),
        throwsStateError,
      );
    });

    test('blockUser writes under the current user and unblockUser removes it',
        () async {
      final db = FakeFirebaseFirestore();
      final service = TrustSafetyService(
        firestore: db,
        currentUserIdProvider: () => 'client1',
      );

      await service.blockUser(
        blockedUid: 'provider1',
        reason: 'Nao quero contacto',
        source: 'chat',
      );

      final ref = db
          .collection('users')
          .doc('client1')
          .collection('blockedUsers')
          .doc('provider1');

      final created = await ref.get();
      expect(created.exists, isTrue);
      expect(created.data()?['blockedUid'], 'provider1');
      expect(created.data()?['reason'], 'Nao quero contacto');

      await service.unblockUser('provider1');

      final removed = await ref.get();
      expect(removed.exists, isFalse);
    });

    test('blockUser rejects self-block before writing', () async {
      final db = FakeFirebaseFirestore();
      final service = TrustSafetyService(
        firestore: db,
        currentUserIdProvider: () => 'client1',
      );

      expect(
        service.blockUser(blockedUid: 'client1'),
        throwsArgumentError,
      );

      final snap = await db
          .collection('users')
          .doc('client1')
          .collection('blockedUsers')
          .get();
      expect(snap.docs, isEmpty);
    });
  });
}
