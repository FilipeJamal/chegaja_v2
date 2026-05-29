import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/trust_safety/trust_safety_text_normalizer.dart';

class SensitiveCategory {
  const SensitiveCategory({
    required this.id,
    required this.terms,
    required this.reasonCode,
    required this.severity,
  });

  final String id;
  final List<String> terms;
  final ReportReasonCode reasonCode;
  final ReportSeverity severity;
}

class SensitiveCategories {
  const SensitiveCategories._();

  static List<SensitiveCategory> match(String text) {
    final normalized = TrustSafetyTextNormalizer.normalize(text);
    if (normalized.isEmpty) return const <SensitiveCategory>[];

    final matches = <SensitiveCategory>[];
    for (final category in values) {
      if (category.terms.any((term) => _containsPhrase(normalized, term))) {
        matches.add(category);
      }
    }
    return matches;
  }

  static bool _containsPhrase(String text, String phrase) {
    final haystack = ' $text ';
    final needle = ' ${TrustSafetyTextNormalizer.normalize(phrase)} ';
    return haystack.contains(needle);
  }

  static const List<SensitiveCategory> values = [
    SensitiveCategory(
      id: 'health',
      terms: [
        'saude',
        'medico',
        'enfermagem',
        'psicologia',
        'terapia',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
    ),
    SensitiveCategory(
      id: 'child_care',
      terms: [
        'cuidados infantis',
        'criancas',
        'baba',
        'babysitter',
      ],
      reasonCode: ReportReasonCode.childSafety,
      severity: ReportSeverity.medium,
    ),
    SensitiveCategory(
      id: 'elder_care',
      terms: [
        'cuidados idosos',
        'idosos',
        'pessoas vulneraveis',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
    ),
    SensitiveCategory(
      id: 'electricity',
      terms: [
        'eletricidade',
        'eletricista',
        'instalacao eletrica',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
    ),
    SensitiveCategory(
      id: 'gas',
      terms: [
        'gas',
        'instalacao de gas',
        'canalizacao de gas',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
    ),
    SensitiveCategory(
      id: 'private_security',
      terms: [
        'seguranca privada',
        'vigilancia',
        'seguranca',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
    ),
    SensitiveCategory(
      id: 'professional_food',
      terms: [
        'alimentacao profissional',
        'catering profissional',
        'catering',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
    ),
    SensitiveCategory(
      id: 'training_nutrition',
      terms: [
        'treino',
        'nutricao',
        'nutricionista',
        'personal trainer',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
    ),
    SensitiveCategory(
      id: 'transport',
      terms: [
        'transporte',
        'motorista',
        'transfer',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
    ),
    SensitiveCategory(
      id: 'in_home_service',
      terms: [
        'servico em casa',
        'em casa do cliente',
        'domicilio',
      ],
      reasonCode: ReportReasonCode.unsafeService,
      severity: ReportSeverity.medium,
    ),
  ];
}
