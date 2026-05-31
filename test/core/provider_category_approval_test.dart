import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/provider_category_approval.dart';

void main() {
  group('ProviderCategoryApproval', () {
    test('approved sem expiracao esta ativo', () {
      const approval = ProviderCategoryApproval(
        providerId: 'provider1',
        categoryId: 'electricity',
        categoryName: 'Eletricidade',
        status: ProviderCategoryApprovalStatus.approved,
        sourceRequestId: 'request1',
      );

      expect(approval.isCurrentlyApproved, isTrue);
      expect(approval.toMap()['status'], 'approved');
    });

    test('approved expirado deixa de estar ativo', () {
      final approval = ProviderCategoryApproval(
        providerId: 'provider1',
        categoryId: 'electricity',
        categoryName: 'Eletricidade',
        status: ProviderCategoryApprovalStatus.approved,
        expiresAt: DateTime(2026, 1, 1),
      );

      expect(approval.isCurrentlyApprovedAt(DateTime(2026, 5, 31)), isFalse);
    });

    test('status diferente de approved nao conta como aprovado', () {
      final approval = ProviderCategoryApproval.fromMap(
        const {
          'providerId': 'provider1',
          'categoryId': 'gas',
          'categoryName': 'Gas',
          'status': 'revoked',
        },
        id: 'provider1_gas',
      );

      expect(approval.status, ProviderCategoryApprovalStatus.revoked);
      expect(approval.isCurrentlyApproved, isFalse);
    });
  });
}
