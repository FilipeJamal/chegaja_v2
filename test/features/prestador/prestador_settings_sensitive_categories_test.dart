import 'package:chegaja_v2/core/models/category_approval_types.dart';
import 'package:chegaja_v2/core/models/servico.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_sensitive_categories_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deriva requisitos sensiveis dos servicos selecionados no settings', () {
    final requirements = sensitiveRequirementsFromSelectedServices(
      services: const [
        Servico(
          id: 'eletricista',
          name: 'Eletricista',
          mode: 'IMEDIATO',
          keywords: ['instalacao eletrica'],
          isActive: true,
        ),
        Servico(
          id: 'limpeza',
          name: 'Limpeza comum',
          mode: 'IMEDIATO',
          keywords: ['casa'],
          isActive: true,
        ),
      ],
      selectedServiceIds: {'eletricista'},
    );

    expect(requirements, hasLength(1));
    expect(requirements.single.categoryId, 'electricity');
    expect(requirements.single.riskLevel, CategoryRiskLevel.sensitive);
    expect(requirements.single.approvalRequired, isTrue);
    expect(requirements.single.evidenceTypes,
        contains(EvidenceType.workExperience));
  });

  test('nao cria requisito para servico normal ou nao selecionado', () {
    final requirements = sensitiveRequirementsFromSelectedServices(
      services: const [
        Servico(
          id: 'transporte',
          name: 'Transporte',
          mode: 'IMEDIATO',
          keywords: ['motorista'],
          isActive: true,
        ),
        Servico(
          id: 'limpeza',
          name: 'Limpeza comum',
          mode: 'IMEDIATO',
          keywords: ['casa'],
          isActive: true,
        ),
      ],
      selectedServiceIds: {'limpeza'},
    );

    expect(requirements, isEmpty);
  });
}
