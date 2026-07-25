enum EngineReasonCode {
  notEvaluated('system.not_evaluated'),
  invalidContext('system.invalid_context'),
  unsupportedContractVersion('system.unsupported_contract_version'),
  insufficientInput('input.insufficient'),
  legacyCompatibility('input.legacy_compatibility'),
  requestedImmediate('intent.requested_immediate'),
  requestedScheduled('intent.requested_scheduled'),
  requestedQuote('intent.requested_quote'),
  schedulePresent('scope.schedule_present'),
  diagnosisRequired('scope.diagnosis_required'),
  teamRequired('scope.team_required'),
  candidateCategoryCompatible('matching.category_compatible'),
  candidateWithinServiceArea('matching.within_service_area'),
  candidateAvailable('matching.available'),
  candidateTrustEligible('matching.trust_eligible'),
  candidateQualityEligible('matching.quality_eligible'),
  candidateResponseEligible('matching.response_eligible'),
  opportunityBalanceApplied('matching.opportunity_balance_applied'),
  noEligibleCandidates('matching.no_eligible_candidates'),
  fallbackRequired('matching.fallback_required'),
  fixedPriceEligible('pricing.fixed_eligible'),
  hourlyPriceEligible('pricing.hourly_eligible'),
  estimateRequired('pricing.estimate_required'),
  customQuoteRequired('pricing.custom_quote_required'),
  diagnosticVisitRequired('pricing.diagnostic_visit_required'),
  milestonePricingRequired('pricing.milestones_required'),
  riskLow('trust.risk_low'),
  riskModerate('trust.risk_moderate'),
  riskHigh('trust.risk_high'),
  riskRegulated('trust.risk_regulated'),
  policyAllowed('trust.policy_allowed'),
  policyBlocked('trust.policy_blocked'),
  humanReviewRequired('trust.human_review_required'),
  evidenceRequired('trust.evidence_required'),
  transitionAllowed('job.transition_allowed'),
  transitionRejected('job.transition_rejected'),
  idempotentReplay('job.idempotent_replay'),
  paymentRailAvailable('payment.rail_available'),
  paymentRailUnavailable('payment.rail_unavailable'),
  paymentReviewRequired('payment.review_required'),
  reputationEvidenceSufficient('reputation.evidence_sufficient'),
  reputationEvidenceInsufficient('reputation.evidence_insufficient'),
  supportSelfServiceEligible('support.self_service_eligible'),
  supportHumanRequired('support.human_required'),
  supportSafetyEscalation('support.safety_escalation'),
  growthEligible('growth.eligible'),
  growthIneligible('growth.ineligible'),
  analyticsAccepted('analytics.accepted'),
  analyticsPrivacyRejected('analytics.privacy_rejected');

  const EngineReasonCode(this.wireName);

  final String wireName;

  static EngineReasonCode? fromWireName(String value) {
    final normalized = value.trim().toLowerCase();
    for (final reason in values) {
      if (reason.wireName == normalized) {
        return reason;
      }
    }
    return null;
  }
}
