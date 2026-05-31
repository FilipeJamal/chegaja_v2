import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/sensitive_category_request.dart';

void main() {
  group('SensitiveCategoryRequest', () {
    test('cria draft para o prestador com dados minimos', () {
      final request = SensitiveCategoryRequest.draft(
        providerId: 'provider1',
        categoryId: 'elder_care',
        categoryName: 'Cuidados a idosos',
        evidenceTypes: const [EvidenceType.workExperience],
        evidenceText: 'Tenho experiencia comprovada.',
      );

      expect(request.providerId, 'provider1');
      expect(request.status, SensitiveCategoryRequestStatus.draft);
      expect(request.canProviderEdit, isTrue);
      expect(request.toMap()['status'], 'draft');
      expect(request.toMap()['evidenceTypes'], ['work_experience']);
    });

    test('parseia pedido submetido com evidencias e referencias', () {
      final parsed = SensitiveCategoryRequest.fromMap(
        const {
          'providerId': 'provider1',
          'categoryId': 'electricity',
          'categoryName': 'Eletricidade',
          'status': 'pending_review',
          'evidenceTypes': ['certificate', 'portfolio_reference'],
          'evidenceText': 'Certificado tecnico e portfolio.',
          'portfolioUrls': ['https://example.com/work'],
          'documentRefs': ['providerEvidence/provider1/request1/doc.pdf'],
        },
        id: 'request1',
      );

      expect(parsed.id, 'request1');
      expect(parsed.status, SensitiveCategoryRequestStatus.pendingReview);
      expect(parsed.evidenceTypes, [
        EvidenceType.certificate,
        EvidenceType.portfolioReference,
      ]);
      expect(parsed.portfolioUrls, ['https://example.com/work']);
      expect(
          parsed.documentRefs, ['providerEvidence/provider1/request1/doc.pdf']);
      expect(parsed.canProviderEdit, isFalse);
    });

    test('needs_more_info continua editavel pelo prestador', () {
      final parsed = SensitiveCategoryRequest.fromMap(
        const {
          'providerId': 'provider1',
          'categoryId': 'gas',
          'categoryName': 'Gas',
          'status': 'needs_more_info',
        },
        id: 'request2',
      );

      expect(parsed.status, SensitiveCategoryRequestStatus.needsMoreInfo);
      expect(parsed.canProviderEdit, isTrue);
      expect(parsed.isFinal, isFalse);
    });
  });
}
