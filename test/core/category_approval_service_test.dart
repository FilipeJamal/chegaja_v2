import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/services/category_approval_service.dart';

void main() {
  group('CategoryApprovalService', () {
    test('buildRequestDraft cria pedido local sem escrever no Firestore', () {
      final db = FakeFirebaseFirestore();
      final service = CategoryApprovalService(firestore: db);

      final draft = service.buildRequestDraft(
        providerId: 'provider1',
        categoryId: 'electricity',
        categoryName: 'Eletricidade',
        evidenceTypes: const [EvidenceType.certificate],
      );

      expect(draft.providerId, 'provider1');
      expect(draft.status, SensitiveCategoryRequestStatus.draft);
      expect(draft.evidenceTypes, [EvidenceType.certificate]);
    });

    test('createSensitiveCategoryRequest grava pending_review para provider',
        () async {
      final db = FakeFirebaseFirestore();
      final service = CategoryApprovalService(firestore: db);

      final created = await service.createSensitiveCategoryRequest(
        providerId: 'provider1',
        categoryId: 'electricity',
        categoryName: 'Eletricidade',
        evidenceTypes: const [EvidenceType.certificate],
        evidenceText: 'Tenho certificado profissional.',
      );

      final snap = await db.collection('sensitiveCategoryRequests').get();
      expect(snap.docs, hasLength(1));
      expect(created.id, snap.docs.single.id);
      expect(snap.docs.single.data()['providerId'], 'provider1');
      expect(snap.docs.single.data()['status'], 'pending_review');
      expect(snap.docs.single.data()['evidenceTypes'], ['certificate']);
    });

    test('getProviderCategoryRequests devolve apenas pedidos do provider',
        () async {
      final db = FakeFirebaseFirestore();
      await db.collection('sensitiveCategoryRequests').doc('req1').set({
        'providerId': 'provider1',
        'categoryId': 'electricity',
        'categoryName': 'Eletricidade',
        'status': 'pending_review',
      });
      await db.collection('sensitiveCategoryRequests').doc('req2').set({
        'providerId': 'provider2',
        'categoryId': 'gas',
        'categoryName': 'Gas',
        'status': 'pending_review',
      });

      final requests = await CategoryApprovalService(firestore: db)
          .getProviderCategoryRequests('provider1');

      expect(requests, hasLength(1));
      expect(requests.single.id, 'req1');
    });

    test('getCategoryRequirement parseia requisito existente', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('categoryRequirements').doc('gas').set({
        'categoryId': 'gas',
        'categoryName': 'Gas',
        'riskLevel': 'sensitive',
        'approvalRequired': true,
        'evidenceTypes': ['license'],
      });

      final requirement = await CategoryApprovalService(firestore: db)
          .getCategoryRequirement('gas');

      expect(requirement?.categoryId, 'gas');
      expect(requirement?.requiresApproval, isTrue);
      expect(requirement?.evidenceTypes, [EvidenceType.license]);
    });

    test('isCategoryApprovedForProvider respeita status e expiracao', () async {
      final db = FakeFirebaseFirestore();
      await db
          .collection('prestadores')
          .doc('provider1')
          .collection('categoryApprovals')
          .doc('electricity')
          .set({
        'providerId': 'provider1',
        'categoryId': 'electricity',
        'categoryName': 'Eletricidade',
        'status': 'approved',
      });
      await db
          .collection('prestadores')
          .doc('provider1')
          .collection('categoryApprovals')
          .doc('gas')
          .set({
        'providerId': 'provider1',
        'categoryId': 'gas',
        'categoryName': 'Gas',
        'status': 'revoked',
      });

      final service = CategoryApprovalService(firestore: db);

      expect(
        await service.isCategoryApprovedForProvider('provider1', 'electricity'),
        isTrue,
      );
      expect(
        await service.isCategoryApprovedForProvider('provider1', 'gas'),
        isFalse,
      );
      expect(
        await service.isCategoryApprovedForProvider('provider1', 'transport'),
        isFalse,
      );
    });
  });
}
