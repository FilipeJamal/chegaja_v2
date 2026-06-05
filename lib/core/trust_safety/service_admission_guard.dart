import 'package:chegaja_v2/core/catalog/service_taxonomy_matcher.dart';
import 'package:chegaja_v2/core/catalog/service_taxonomy_normalizer.dart';
import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/trust_safety_classifier.dart';

enum ServiceAdmissionDecision {
  allow,
  sensitiveReview,
  block,
  unknownReview,
}

class ServiceAdmissionResult {
  const ServiceAdmissionResult({
    required this.decision,
    required this.safetyClassification,
    required this.matchedPolicyGroup,
    required this.normalizedText,
    required this.userMessage,
    required this.internalReason,
    required this.shouldSave,
    required this.shouldRenderPublicly,
    required this.shouldIndexForSearch,
    required this.shouldMatch,
  });

  final ServiceAdmissionDecision decision;
  final TrustSafetyClassification safetyClassification;
  final String matchedPolicyGroup;
  final String normalizedText;
  final String userMessage;
  final String internalReason;
  final bool shouldSave;
  final bool shouldRenderPublicly;
  final bool shouldIndexForSearch;
  final bool shouldMatch;

  bool get isBlocked => decision == ServiceAdmissionDecision.block;
  bool get needsReview =>
      decision == ServiceAdmissionDecision.sensitiveReview ||
      decision == ServiceAdmissionDecision.unknownReview;
}

class ServiceAdmissionGuard {
  const ServiceAdmissionGuard._();

  static const blockedMessage =
      'Este tipo de servi\u00e7o n\u00e3o \u00e9 permitido no ChegaJ\u00e1.';

  static const unknownReviewMessage =
      'Este servi\u00e7o precisa de an\u00e1lise antes de ficar dispon\u00edvel.';

  static const sensitiveReviewMessage =
      'Este servi\u00e7o pode exigir aprova\u00e7\u00e3o antes de ficares dispon\u00edvel nesta categoria.';

  static ServiceAdmissionResult classify({
    required String title,
    String description = '',
    Iterable<String> aliases = const [],
    String queryOriginal = '',
    Iterable<String> normalizedSearchTerms = const [],
    ServiceTaxonomyMatch? taxonomyMatch,
  }) {
    final fields = <String>[
      title,
      description,
      queryOriginal,
      ...aliases,
      ...normalizedSearchTerms,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).toList();
    final normalizedText = ServiceTaxonomyNormalizer.normalize(
      fields.join(' '),
    );
    final safety = TrustSafetyClassifier.classifyFields(fields);

    if (safety.decision == TrustSafetyDecision.block) {
      return _result(
        decision: ServiceAdmissionDecision.block,
        safety: safety,
        normalizedText: normalizedText,
        matchedPolicyGroup: _firstOrDefault(safety.internalReason, 'blocked'),
        userMessage: blockedMessage,
        internalReason: 'blocked:${safety.internalReason}',
        public: false,
      );
    }

    if (safety.decision == TrustSafetyDecision.needsReview &&
        !_isSensitiveAllowOverride(normalizedText)) {
      return _result(
        decision: ServiceAdmissionDecision.sensitiveReview,
        safety: safety,
        normalizedText: normalizedText,
        matchedPolicyGroup: _firstOrDefault(
          safety.internalReason,
          'sensitive_review',
        ),
        userMessage: sensitiveReviewMessage,
        internalReason: 'sensitive:${safety.internalReason}',
        public: true,
      );
    }

    if (fields.isEmpty ||
        _isExplicitlyUnknown(normalizedText) ||
        !_hasAdmissionSignal(
          fields: fields,
          normalizedText: normalizedText,
          taxonomyMatch: taxonomyMatch,
        )) {
      return _result(
        decision: ServiceAdmissionDecision.unknownReview,
        safety: safety,
        normalizedText: normalizedText,
        matchedPolicyGroup: 'unknown_service',
        userMessage: unknownReviewMessage,
        internalReason: 'unknown:no_taxonomy_or_professional_signal',
        public: false,
      );
    }

    return _result(
      decision: ServiceAdmissionDecision.allow,
      safety: safety,
      normalizedText: normalizedText,
      matchedPolicyGroup: 'allowed_service',
      userMessage: '',
      internalReason: 'allow',
      public: true,
    );
  }

  static bool shouldRenderServiceTextPublicly(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return false;
    return classify(title: normalized).shouldRenderPublicly;
  }

  static ServiceAdmissionResult _result({
    required ServiceAdmissionDecision decision,
    required TrustSafetyClassification safety,
    required String normalizedText,
    required String matchedPolicyGroup,
    required String userMessage,
    required String internalReason,
    required bool public,
  }) {
    return ServiceAdmissionResult(
      decision: decision,
      safetyClassification: safety,
      matchedPolicyGroup: matchedPolicyGroup,
      normalizedText: normalizedText,
      userMessage: userMessage,
      internalReason: internalReason,
      shouldSave: public,
      shouldRenderPublicly: public,
      shouldIndexForSearch: public,
      shouldMatch: public,
    );
  }

  static bool _hasAdmissionSignal({
    required List<String> fields,
    required String normalizedText,
    ServiceTaxonomyMatch? taxonomyMatch,
  }) {
    final match = taxonomyMatch ?? _bestTaxonomyMatch(fields);
    if (match != null &&
        (match.hasMatch || match.suggestions.isNotEmpty) &&
        match.confidence != ServiceTaxonomyMatchConfidence.none) {
      return true;
    }

    if (_containsAnyPhrase(normalizedText, _knownLegitimatePhrases)) {
      return true;
    }

    final tokens = ServiceTaxonomyNormalizer.tokenize(normalizedText).toSet();
    if (tokens.intersection(_knownLegitimateTokens).isNotEmpty) {
      return true;
    }

    final titleTokens = ServiceTaxonomyNormalizer.tokenize(fields.first);
    final hasDescription = fields.skip(1).any((field) {
      return ServiceTaxonomyNormalizer.tokenize(field).length >= 3;
    });
    return hasDescription && titleTokens.length >= 2;
  }

  static ServiceTaxonomyMatch? _bestTaxonomyMatch(List<String> fields) {
    ServiceTaxonomyMatch? best;
    for (final field in fields) {
      final match = ServiceTaxonomyMatcher.matchServiceQuery(field);
      if (best == null || _matchRank(match) > _matchRank(best)) {
        best = match;
      }
    }
    return best;
  }

  static int _matchRank(ServiceTaxonomyMatch match) {
    if (match.hasMatch) {
      switch (match.confidence) {
        case ServiceTaxonomyMatchConfidence.high:
          return 5;
        case ServiceTaxonomyMatchConfidence.medium:
          return 4;
        case ServiceTaxonomyMatchConfidence.low:
          return 3;
        case ServiceTaxonomyMatchConfidence.none:
          return 0;
      }
    }
    if (match.suggestions.isNotEmpty) return 2;
    return 0;
  }

  static bool _isExplicitlyUnknown(String normalizedText) {
    return _containsAnyPhrase(normalizedText, _unknownReviewPhrases);
  }

  static bool _isSensitiveAllowOverride(String normalizedText) {
    return _containsAnyPhrase(normalizedText, _sensitiveAllowOverridePhrases);
  }

  static bool _containsAnyPhrase(String normalizedText, Iterable<String> raw) {
    if (normalizedText.isEmpty) return false;
    final padded = ' $normalizedText ';
    for (final value in raw) {
      final phrase = ServiceTaxonomyNormalizer.normalize(value);
      if (phrase.isEmpty) continue;
      if (padded.contains(' $phrase ')) return true;
    }
    return false;
  }

  static String _firstOrDefault(String value, String fallback) {
    final normalized = value.trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  static const Set<String> _unknownReviewPhrases = {
    'servico especial',
    'trabalho secreto',
    'faco de tudo',
    'qualquer coisa',
    'servico privado',
    'coisa discreta',
    'contactos especiais',
    'ajuda confidencial',
  };

  static const Set<String> _knownLegitimatePhrases = {
    'apoio psicologico',
    'bolo de aniversario',
    'consultoria de imagem',
    'design de interiores',
    'disputa contratual',
    'enfermagem ao domicilio',
    'exterminador de pragas',
    'fotografia de eventos',
    'matar baratas',
    'mentoria de carreira',
    'organizacao de guarda roupa',
    'personal stylist',
    'reparacao de computadores',
    'reparacao de maquinas',
    'seguranca informatica',
    'suporte informatico',
    'trafego pago',
    'transporte de moveis',
  };

  static const Set<String> _sensitiveAllowOverridePhrases = {
    'seguranca informatica',
    'suporte de seguranca informatica',
  };

  static const Set<String> _knownLegitimateTokens = {
    'aula',
    'aulas',
    'apoio',
    'assistencia',
    'beleza',
    'bolo',
    'canalizador',
    'carpintaria',
    'computador',
    'computadores',
    'conserto',
    'consultoria',
    'cozinha',
    'cuidados',
    'design',
    'eletricista',
    'enfermagem',
    'entrega',
    'eventos',
    'farmacia',
    'fisioterapia',
    'fotografia',
    'formacao',
    'informatica',
    'instalacao',
    'jardinagem',
    'limpeza',
    'manutencao',
    'maquinas',
    'marketing',
    'mecanica',
    'mentoria',
    'moda',
    'montagem',
    'organizacao',
    'pastelaria',
    'pintura',
    'reparacao',
    'reputacao',
    'seguranca',
    'stylist',
    'suporte',
    'trafego',
    'transporte',
  };
}
