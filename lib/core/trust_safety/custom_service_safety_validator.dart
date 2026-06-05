import 'package:chegaja_v2/core/catalog/service_taxonomy_normalizer.dart';
import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/service_admission_guard.dart';
import 'package:chegaja_v2/core/trust_safety/trust_safety_classifier.dart';

const customServiceBlockedMessage =
    'Este tipo de serviço não é permitido no ChegaJá.';

const customServiceNeedsReviewMessage =
    'Este serviço pode precisar de análise antes de ficar disponível como categoria aprovada.';

class CustomServiceSafetyResult {
  const CustomServiceSafetyResult({
    required this.classification,
    required this.admission,
    required this.normalizedSearchTerms,
  });

  final TrustSafetyClassification classification;
  final ServiceAdmissionResult admission;
  final List<String> normalizedSearchTerms;

  TrustSafetyDecision get decision => classification.decision;
  ServiceAdmissionDecision get admissionDecision => admission.decision;
  bool get shouldSave => admission.shouldSave;
  bool get shouldRenderPublicly => admission.shouldRenderPublicly;
  bool get shouldIndexForSearch => admission.shouldIndexForSearch;
  bool get shouldMatch => admission.shouldMatch;
  bool get isBlocked => !shouldSave;

  String get messageForUser {
    if (admission.userMessage.isNotEmpty) return admission.userMessage;
    switch (decision) {
      case TrustSafetyDecision.block:
        return customServiceBlockedMessage;
      case TrustSafetyDecision.needsReview:
        return customServiceNeedsReviewMessage;
      case TrustSafetyDecision.warn:
        return 'Confirma se este serviço respeita as regras da plataforma.';
      case TrustSafetyDecision.allow:
        return '';
    }
  }

  List<String> get reasonCodes =>
      classification.reasonCodes.map((code) => code.name).toList();
}

class CustomServiceSafetyValidator {
  const CustomServiceSafetyValidator._();

  static CustomServiceSafetyResult validate({
    required String title,
    String description = '',
    Iterable<String> aliases = const [],
    String query = '',
  }) {
    final rawFields = <String>[
      title,
      description,
      query,
      ...aliases,
    ];
    final normalizedTerms = _normalizedTerms(rawFields);
    final admission = ServiceAdmissionGuard.classify(
      title: title,
      description: description,
      aliases: aliases,
      queryOriginal: query,
      normalizedSearchTerms: normalizedTerms,
    );

    final classifications = <TrustSafetyClassification>[
      for (final field in rawFields)
        if (field.trim().isNotEmpty) TrustSafetyClassifier.classifyText(field),
      if (normalizedTerms.isNotEmpty)
        TrustSafetyClassifier.classifyFields(normalizedTerms),
    ];

    final classification = classifications.isEmpty
        ? TrustSafetyClassifier.classifyText('')
        : classifications.reduce(_moreSevere);

    return CustomServiceSafetyResult(
      classification: classification,
      admission: admission,
      normalizedSearchTerms: normalizedTerms,
    );
  }

  static TrustSafetyClassification _moreSevere(
    TrustSafetyClassification a,
    TrustSafetyClassification b,
  ) {
    return _decisionRank(a.decision) >= _decisionRank(b.decision) ? a : b;
  }

  static int _decisionRank(TrustSafetyDecision decision) {
    switch (decision) {
      case TrustSafetyDecision.allow:
        return 0;
      case TrustSafetyDecision.warn:
        return 1;
      case TrustSafetyDecision.needsReview:
        return 2;
      case TrustSafetyDecision.block:
        return 3;
    }
  }

  static List<String> _normalizedTerms(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];

    void addTerm(String value) {
      final normalized = ServiceTaxonomyNormalizer.normalize(value);
      if (normalized.isEmpty || seen.contains(normalized)) return;
      seen.add(normalized);
      result.add(normalized);
    }

    for (final value in values) {
      addTerm(value);
      for (final fragment in _searchFragments(value)) {
        addTerm(fragment);
      }
    }
    return List.unmodifiable(result);
  }

  static Iterable<String> _searchFragments(String value) {
    final normalized = ServiceTaxonomyNormalizer.normalize(value);
    if (normalized.isEmpty) return const [];
    return normalized
        .split(RegExp(r'\s+(?:e|ou)\s+'))
        .map((item) => item.trim())
        .where((item) => item.length >= 3);
  }
}
