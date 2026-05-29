import 'package:chegaja_v2/core/models/moderation_types.dart';
import 'package:chegaja_v2/core/models/trust_safety_classification.dart';
import 'package:chegaja_v2/core/trust_safety/prohibited_terms.dart';
import 'package:chegaja_v2/core/trust_safety/sensitive_categories.dart';

class TrustSafetyClassifier {
  const TrustSafetyClassifier._();

  static TrustSafetyClassification classifyText(String text) {
    return classifyFields([text]);
  }

  static TrustSafetyClassification classifyFields(Iterable<String?> fields) {
    final joined = fields
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ');

    final termMatches = ProhibitedTerms.match(joined);
    final categoryMatches = SensitiveCategories.match(joined);

    final matchedTerms = _unique(termMatches.map((match) => match.phrase));
    final matchedCategories =
        _unique(categoryMatches.map((category) => category.id));
    final reasonCodes = _uniqueEnums<ReportReasonCode>([
      ...termMatches.map((match) => match.term.reasonCode),
      ...categoryMatches.map((category) => category.reasonCode),
    ]);

    final severities = <ReportSeverity>[
      ...termMatches.map((match) => match.term.severity),
      ...categoryMatches.map((category) => category.severity),
    ];

    final decision = _resolveDecision(termMatches, categoryMatches);
    final severity = _maxSeverity(severities);

    return TrustSafetyClassification(
      decision: decision,
      matchedTerms: matchedTerms,
      matchedCategories: matchedCategories,
      reasonCodes: reasonCodes,
      severity: severity,
      messageForUser: _messageFor(decision),
      internalReason: _internalReason(
        decision: decision,
        matchedTerms: matchedTerms,
        matchedCategories: matchedCategories,
      ),
    );
  }

  static TrustSafetyDecision _resolveDecision(
    List<ProhibitedTermMatch> termMatches,
    List<SensitiveCategory> categoryMatches,
  ) {
    if (termMatches.any(
      (match) => match.term.decision == TrustSafetyDecision.block,
    )) {
      return TrustSafetyDecision.block;
    }
    if (termMatches.any(
          (match) => match.term.decision == TrustSafetyDecision.needsReview,
        ) ||
        categoryMatches.isNotEmpty) {
      return TrustSafetyDecision.needsReview;
    }
    if (termMatches.any(
      (match) => match.term.decision == TrustSafetyDecision.warn,
    )) {
      return TrustSafetyDecision.warn;
    }
    return TrustSafetyDecision.allow;
  }

  static ReportSeverity _maxSeverity(List<ReportSeverity> severities) {
    if (severities.isEmpty) return ReportSeverity.low;
    return severities.reduce((a, b) {
      return _severityRank(a) >= _severityRank(b) ? a : b;
    });
  }

  static int _severityRank(ReportSeverity severity) {
    switch (severity) {
      case ReportSeverity.low:
        return 0;
      case ReportSeverity.medium:
        return 1;
      case ReportSeverity.high:
        return 2;
      case ReportSeverity.critical:
        return 3;
    }
  }

  static String _messageFor(TrustSafetyDecision decision) {
    switch (decision) {
      case TrustSafetyDecision.allow:
        return '';
      case TrustSafetyDecision.warn:
        return 'Confirma se a descricao respeita as regras da plataforma.';
      case TrustSafetyDecision.needsReview:
        return 'Este servico pode precisar de analise antes de ficar disponivel.';
      case TrustSafetyDecision.block:
        return 'Este tipo de servico nao e permitido no ChegaJa.';
    }
  }

  static String _internalReason({
    required TrustSafetyDecision decision,
    required List<String> matchedTerms,
    required List<String> matchedCategories,
  }) {
    if (decision == TrustSafetyDecision.allow) return 'allow';
    final parts = <String>[
      if (matchedTerms.isNotEmpty) 'terms=${matchedTerms.join(',')}',
      if (matchedCategories.isNotEmpty)
        'categories=${matchedCategories.join(',')}',
    ];
    return '${decision.name}:${parts.join(';')}';
  }

  static List<String> _unique(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static List<T> _uniqueEnums<T>(Iterable<T> values) {
    return values.toSet().toList(growable: false);
  }
}
