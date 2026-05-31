import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/category_requirement.dart';

void main() {
  group('CategoryRequirement', () {
    test('serializa e parseia categoria sensivel com evidencias', () {
      const requirement = CategoryRequirement(
        categoryId: 'electricity',
        categoryName: 'Eletricidade',
        riskLevel: CategoryRiskLevel.sensitive,
        approvalRequired: true,
        evidenceTypes: [
          EvidenceType.certificate,
          EvidenceType.workExperience,
        ],
        userMessage: 'Esta categoria exige comprovativo profissional.',
        isActive: true,
      );

      final map = requirement.toMap();
      expect(map['categoryId'], 'electricity');
      expect(map['riskLevel'], 'sensitive');
      expect(map['approvalRequired'], isTrue);
      expect(map['evidenceTypes'], ['certificate', 'work_experience']);

      final parsed = CategoryRequirement.fromMap(map, id: 'electricity');

      expect(parsed.categoryId, 'electricity');
      expect(parsed.categoryName, 'Eletricidade');
      expect(parsed.riskLevel, CategoryRiskLevel.sensitive);
      expect(parsed.requiresApproval, isTrue);
      expect(parsed.evidenceTypes, [
        EvidenceType.certificate,
        EvidenceType.workExperience,
      ]);
    });

    test('usa fallbacks seguros para valores ausentes ou invalidos', () {
      final parsed = CategoryRequirement.fromMap(
        const {
          'categoryName': 'Categoria sem metadados',
          'riskLevel': 'desconhecido',
          'evidenceTypes': ['license', 'bad_value'],
        },
        id: 'unknown',
      );

      expect(parsed.categoryId, 'unknown');
      expect(parsed.riskLevel, CategoryRiskLevel.normal);
      expect(parsed.approvalRequired, isFalse);
      expect(parsed.evidenceTypes, [EvidenceType.license]);
      expect(parsed.isActive, isTrue);
    });
  });
}
