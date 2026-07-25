import 'dart:collection';

import 'engine_context.dart';
import 'engine_reason_code.dart';

enum EngineDecisionStatus { accepted, rejected, needsReview, notEvaluated }

enum EngineConfidenceBand { low, medium, high, unavailable }

enum EngineActorRole { client, provider, admin, system }

enum ServiceIntentKind { immediate, scheduled, quote }

enum PricingModel {
  fixed,
  hourly,
  estimatedRange,
  customQuote,
  diagnosticVisit,
  milestones,
  toBeAgreed,
}

enum SelectionModel { automatic, manual, shortlist, team }

enum RiskTier { low, moderate, high, regulated }

enum TrustSignal {
  phoneConfirmed,
  identityConfirmed,
  categoryApproved,
  documentsCurrent,
  firstJobProtected,
}

enum RequiredEvidence {
  phone,
  identity,
  categoryApproval,
  professionalDocument,
  insurance,
  training,
  humanReview,
}

enum JobState {
  draft,
  submitted,
  searching,
  proposalReceived,
  providerAssigned,
  awaitingConfirmation,
  confirmed,
  scheduled,
  enRoute,
  arrived,
  inProgress,
  awaitingFinalConfirmation,
  completed,
  cancelled,
  expired,
  noProvider,
  replacementInProgress,
  disputed,
  correctionRequired,
  refunded,
}

enum PaymentOperation {
  authorize,
  charge,
  commission,
  transfer,
  cancel,
  refund,
  dispute,
}

enum PaymentRail { cash, mpesa, emola, stripe, unavailable }

enum ReputationBand { newProvider, developing, established, trusted }

enum SupportCaseType {
  general,
  delay,
  noShow,
  cancellation,
  safety,
  payment,
  dispute,
  correction,
}

enum SupportSeverity { low, medium, high, critical }

enum SupportRoute { selfService, operations, trustSafety, payments, emergency }

enum GrowthTrigger {
  repeatService,
  recurringService,
  referral,
  retention,
  abandonedRequest,
}

enum GrowthAction {
  none,
  repeatPrompt,
  recurringOffer,
  referralPrompt,
  recoveryPrompt,
}

enum EngineAnalyticsEvent {
  requestCreated,
  matchingStarted,
  opportunityPresented,
  requestAccepted,
  jobCompleted,
  serviceRepeated,
  disputeOpened,
}

enum EngineAnalyticsIngestion { accepted, rejected }

enum EngineAuditEventType {
  serviceIntentEvaluated,
  requestScoped,
  matchingEvaluated,
  pricingEvaluated,
  trustPolicyEvaluated,
  jobTransitionEvaluated,
  paymentEvaluated,
  reputationEvaluated,
  supportCaseRouted,
  growthEvaluated,
  analyticsIngested,
}

final class EngineAuditEvent {
  EngineAuditEvent({
    required this.type,
    required this.correlationId,
    required this.occurredAt,
    this.idempotencyKey,
  }) {
    if (!isValid) {
      throw ArgumentError(
        'Engine audit events require a valid correlation id, an optional '
        'valid idempotency key, and a UTC timestamp.',
      );
    }
  }

  final EngineAuditEventType type;
  final String correlationId;
  final DateTime occurredAt;
  final String? idempotencyKey;

  bool get isValid {
    final correlationValid =
        RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$').hasMatch(correlationId);
    final idempotency = idempotencyKey;
    final idempotencyValid = idempotency == null ||
        RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$').hasMatch(idempotency);
    return correlationValid && idempotencyValid && occurredAt.isUtc;
  }
}

final class EngineDecision<T> {
  EngineDecision({
    required this.context,
    required this.status,
    required this.value,
    required this.engineVersion,
    required List<EngineReasonCode> reasonCodes,
    required this.evaluatedAt,
    required this.auditEvent,
    this.contractVersion = engineContractVersion,
  }) : reasonCodes = UnmodifiableListView(
          List<EngineReasonCode>.from(reasonCodes),
        ) {
    if (!context.isValid) {
      throw ArgumentError.value(
        context,
        'context',
        'Engine decisions require a valid execution context.',
      );
    }
    if (engineVersion.trim().isEmpty) {
      throw ArgumentError.value(
        engineVersion,
        'engineVersion',
        'Engine version cannot be empty.',
      );
    }
    if (contractVersion != engineContractVersion) {
      throw ArgumentError.value(
        contractVersion,
        'contractVersion',
        'Unsupported engine contract version.',
      );
    }
    if (reasonCodes.isEmpty) {
      throw ArgumentError.value(
        reasonCodes,
        'reasonCodes',
        'At least one stable reason code is required.',
      );
    }
    if (!evaluatedAt.isUtc) {
      throw ArgumentError.value(
        evaluatedAt,
        'evaluatedAt',
        'Engine evaluation timestamps must be UTC.',
      );
    }
    if (!auditEvent.isValid) {
      throw ArgumentError.value(
        auditEvent,
        'auditEvent',
        'Engine decisions require a valid audit event.',
      );
    }
    if (auditEvent.correlationId != context.correlationId) {
      throw ArgumentError.value(
        auditEvent.correlationId,
        'auditEvent.correlationId',
        'Audit correlation id must match the execution context.',
      );
    }
  }

  final EngineExecutionContext context;
  final EngineDecisionStatus status;
  final T value;
  final String contractVersion;
  final String engineVersion;
  final List<EngineReasonCode> reasonCodes;
  final DateTime evaluatedAt;
  final EngineAuditEvent auditEvent;
}

final class ServiceIntentInput {
  const ServiceIntentInput({
    required this.context,
    required this.categoryCode,
    this.requestedIntent,
    this.scheduledFor,
  }) : assert(categoryCode != '');

  final EngineExecutionContext context;
  final String categoryCode;
  final ServiceIntentKind? requestedIntent;
  final DateTime? scheduledFor;
}

final class ServiceIntentOutcome {
  const ServiceIntentOutcome({
    required this.intent,
    required this.confidence,
  });

  final ServiceIntentKind intent;
  final EngineConfidenceBand confidence;
}

final class RequestScopingInput {
  const RequestScopingInput({
    required this.context,
    required this.categoryCode,
    required this.intent,
    this.hasSchedule = false,
    this.requiresDiagnosis = false,
    this.requestedTeamSize = 1,
  })  : assert(categoryCode != ''),
        assert(requestedTeamSize > 0);

  final EngineExecutionContext context;
  final String categoryCode;
  final ServiceIntentKind intent;
  final bool hasSchedule;
  final bool requiresDiagnosis;
  final int requestedTeamSize;
}

final class RequestScope {
  const RequestScope({
    required this.intent,
    required this.pricingModel,
    required this.selectionModel,
    required this.riskTier,
  });

  final ServiceIntentKind intent;
  final PricingModel pricingModel;
  final SelectionModel selectionModel;
  final RiskTier riskTier;
}

final class MatchingCandidateSnapshot {
  const MatchingCandidateSnapshot({
    required this.providerRef,
    required this.categoryCompatible,
    required this.withinServiceArea,
    required this.available,
    required this.trustEligible,
  }) : assert(providerRef != '');

  final String providerRef;
  final bool categoryCompatible;
  final bool withinServiceArea;
  final bool available;
  final bool trustEligible;
}

final class MatchingInput {
  MatchingInput({
    required this.context,
    required this.requestRef,
    required this.scope,
    required List<MatchingCandidateSnapshot> candidates,
  })  : assert(requestRef != ''),
        candidates = UnmodifiableListView(
          List<MatchingCandidateSnapshot>.from(candidates),
        );

  final EngineExecutionContext context;
  final String requestRef;
  final RequestScope scope;
  final List<MatchingCandidateSnapshot> candidates;
}

final class MatchRecommendation {
  MatchRecommendation({
    required this.providerRef,
    required this.confidence,
    required List<EngineReasonCode> reasonCodes,
  })  : assert(providerRef != ''),
        reasonCodes = UnmodifiableListView(
          List<EngineReasonCode>.from(reasonCodes),
        );

  final String providerRef;
  final EngineConfidenceBand confidence;
  final List<EngineReasonCode> reasonCodes;
}

final class MatchingOutcome {
  MatchingOutcome({
    required List<MatchRecommendation> recommendations,
    this.fallbackIntent,
  }) : recommendations = UnmodifiableListView(
          List<MatchRecommendation>.from(recommendations),
        );

  final List<MatchRecommendation> recommendations;
  final ServiceIntentKind? fallbackIntent;
}

final class PricingInput {
  const PricingInput({
    required this.context,
    required this.requestRef,
    required this.scope,
    this.estimatedMinutes,
    this.materialsExpected = false,
  })  : assert(requestRef != ''),
        assert(estimatedMinutes == null || estimatedMinutes > 0);

  final EngineExecutionContext context;
  final String requestRef;
  final RequestScope scope;
  final int? estimatedMinutes;
  final bool materialsExpected;
}

final class PricingOutcome {
  const PricingOutcome({
    required this.model,
    this.minimumMinor,
    this.maximumMinor,
  })  : assert(minimumMinor == null || minimumMinor >= 0),
        assert(maximumMinor == null || maximumMinor >= 0),
        assert(
          minimumMinor == null ||
              maximumMinor == null ||
              maximumMinor >= minimumMinor,
        );

  final PricingModel model;
  final int? minimumMinor;
  final int? maximumMinor;
}

final class TrustPolicyInput {
  TrustPolicyInput({
    required this.context,
    required this.subjectRef,
    required this.actorRole,
    required this.categoryCode,
    required this.riskTier,
    Set<TrustSignal> signals = const <TrustSignal>{},
  })  : assert(subjectRef != ''),
        assert(categoryCode != ''),
        signals = Set<TrustSignal>.unmodifiable(signals);

  final EngineExecutionContext context;
  final String subjectRef;
  final EngineActorRole actorRole;
  final String categoryCode;
  final RiskTier riskTier;
  final Set<TrustSignal> signals;
}

final class TrustPolicyOutcome {
  TrustPolicyOutcome({
    required this.allowed,
    Set<RequiredEvidence> requiredEvidence = const <RequiredEvidence>{},
  }) : requiredEvidence = Set<RequiredEvidence>.unmodifiable(requiredEvidence);

  final bool allowed;
  final Set<RequiredEvidence> requiredEvidence;
}

final class JobTransitionInput {
  JobTransitionInput({
    required this.context,
    required this.jobRef,
    required this.idempotencyKey,
    required this.currentState,
    required this.targetState,
    required this.actorRole,
  }) {
    _validateCriticalEngineInput(
      context: context,
      jobRef: jobRef,
      idempotencyKey: idempotencyKey,
    );
  }

  final EngineExecutionContext context;
  final String jobRef;
  final String idempotencyKey;
  final JobState currentState;
  final JobState targetState;
  final EngineActorRole actorRole;
}

final class JobTransitionOutcome {
  const JobTransitionOutcome({
    required this.transitionAccepted,
    required this.resultingState,
  });

  final bool transitionAccepted;
  final JobState resultingState;
}

final class PaymentInput {
  PaymentInput({
    required this.context,
    required this.jobRef,
    required this.idempotencyKey,
    required this.operation,
    required this.rail,
    required this.amountMinor,
  }) {
    _validateCriticalEngineInput(
      context: context,
      jobRef: jobRef,
      idempotencyKey: idempotencyKey,
    );
    if (amountMinor < 0) {
      throw ArgumentError.value(
        amountMinor,
        'amountMinor',
        'Payment amount cannot be negative.',
      );
    }
  }

  final EngineExecutionContext context;
  final String jobRef;
  final String idempotencyKey;
  final PaymentOperation operation;
  final PaymentRail rail;
  final int amountMinor;
}

final class PaymentOutcome {
  const PaymentOutcome({
    required this.operation,
    required this.rail,
    required this.allowed,
  });

  final PaymentOperation operation;
  final PaymentRail rail;
  final bool allowed;
}

final class ReputationInput {
  const ReputationInput({
    required this.context,
    required this.providerRef,
    required this.categoryCode,
    required this.completedJobs,
    required this.ratingBasisPoints,
  })  : assert(providerRef != ''),
        assert(categoryCode != ''),
        assert(completedJobs >= 0),
        assert(ratingBasisPoints >= 0 && ratingBasisPoints <= 500);

  final EngineExecutionContext context;
  final String providerRef;
  final String categoryCode;
  final int completedJobs;
  final int ratingBasisPoints;
}

final class ReputationOutcome {
  const ReputationOutcome({
    required this.band,
    required this.confidence,
  });

  final ReputationBand band;
  final EngineConfidenceBand confidence;
}

final class SupportCaseInput {
  const SupportCaseInput({
    required this.context,
    required this.caseRef,
    required this.type,
    required this.severity,
    this.jobRef,
    this.hasSafetyRisk = false,
  }) : assert(caseRef != '');

  final EngineExecutionContext context;
  final String caseRef;
  final String? jobRef;
  final SupportCaseType type;
  final SupportSeverity severity;
  final bool hasSafetyRisk;
}

final class SupportCaseOutcome {
  const SupportCaseOutcome({
    required this.route,
    required this.humanReviewRequired,
  });

  final SupportRoute route;
  final bool humanReviewRequired;
}

final class GrowthInput {
  const GrowthInput({
    required this.context,
    required this.subjectRef,
    required this.trigger,
    required this.completedJobs,
    this.returningUser = false,
  })  : assert(subjectRef != ''),
        assert(completedJobs >= 0);

  final EngineExecutionContext context;
  final String subjectRef;
  final GrowthTrigger trigger;
  final int completedJobs;
  final bool returningUser;
}

final class GrowthOutcome {
  const GrowthOutcome({required this.action});

  final GrowthAction action;
}

final class EngineAnalyticsInput {
  const EngineAnalyticsInput({
    required this.context,
    required this.event,
    this.role,
    this.serviceIntent,
  });

  final EngineExecutionContext context;
  final EngineAnalyticsEvent event;
  final EngineActorRole? role;
  final ServiceIntentKind? serviceIntent;
}

final class EngineAnalyticsOutcome {
  const EngineAnalyticsOutcome({required this.ingestion});

  final EngineAnalyticsIngestion ingestion;
}

void _validateCriticalEngineInput({
  required EngineExecutionContext context,
  required String jobRef,
  required String idempotencyKey,
}) {
  if (!context.isValid) {
    throw ArgumentError.value(
      context,
      'context',
      'Critical engine operations require a valid execution context.',
    );
  }
  if (jobRef.trim().isEmpty) {
    throw ArgumentError.value(
      jobRef,
      'jobRef',
      'Job reference cannot be empty.',
    );
  }
  if (!RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$',
  ).hasMatch(idempotencyKey)) {
    throw ArgumentError.value(
      idempotencyKey,
      'idempotencyKey',
      'Idempotency keys must be stable opaque identifiers.',
    );
  }
}
