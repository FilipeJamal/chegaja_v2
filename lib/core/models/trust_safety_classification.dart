import 'moderation_types.dart';

enum TrustSafetyDecision {
  allow,
  warn,
  needsReview,
  block,
}

class TrustSafetyClassification {
  const TrustSafetyClassification({
    required this.decision,
    required this.matchedTerms,
    required this.matchedCategories,
    required this.reasonCodes,
    required this.severity,
    required this.messageForUser,
    required this.internalReason,
  });

  final TrustSafetyDecision decision;
  final List<String> matchedTerms;
  final List<String> matchedCategories;
  final List<ReportReasonCode> reasonCodes;
  final ReportSeverity severity;
  final String messageForUser;
  final String internalReason;

  bool get isAllowed => decision == TrustSafetyDecision.allow;
  bool get isBlocked => decision == TrustSafetyDecision.block;
  bool get needsHumanReview =>
      decision == TrustSafetyDecision.needsReview ||
      decision == TrustSafetyDecision.block;
}
