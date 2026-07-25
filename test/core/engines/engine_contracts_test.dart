import 'package:chegaja_v2/core/engines/engines.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const market = EngineMarketContext(
    marketCode: 'pt-coimbra',
    countryCode: 'PT',
    currencyCode: 'EUR',
    localeTag: 'pt-PT',
    timeZone: 'Europe/Lisbon',
  );
  final context = EngineExecutionContext(
    market: market,
    requestedAt: DateTime.utc(2026, 7, 24, 10),
    correlationId: 'corr-request-0001',
  );
  const scope = RequestScope(
    intent: ServiceIntentKind.scheduled,
    pricingModel: PricingModel.customQuote,
    selectionModel: SelectionModel.shortlist,
    riskTier: RiskTier.moderate,
  );

  test('market and execution context are explicit and versioned', () {
    expect(market.isValid, isTrue);
    expect(context.isValid, isTrue);
    expect(context.contractVersion, engineContractVersion);

    const invalid = EngineMarketContext(
      marketCode: 'Coimbra, Portugal',
      countryCode: 'Portugal',
      currencyCode: '€',
      localeTag: 'Português',
      timeZone: 'Lisbon',
    );
    expect(invalid.isValid, isFalse);
  });

  test('reason codes are unique and round-trip by stable wire value', () {
    final wireNames =
        EngineReasonCode.values.map((reason) => reason.wireName).toList();

    expect(wireNames.toSet(), hasLength(wireNames.length));
    for (final reason in EngineReasonCode.values) {
      expect(EngineReasonCode.fromWireName(reason.wireName), reason);
    }
    expect(EngineReasonCode.fromWireName('matching.renamed'), isNull);
    expect(
      wireNames,
      containsAll(<String>[
        'intent.requested_immediate',
        'matching.opportunity_balance_applied',
        'pricing.custom_quote_required',
        'trust.human_review_required',
        'job.transition_allowed',
        'payment.review_required',
        'reputation.evidence_sufficient',
        'support.safety_escalation',
        'growth.eligible',
        'analytics.privacy_rejected',
      ]),
    );
  });

  test('decisions carry contract version, engine version and reason codes', () {
    final decision = EngineDecision<ServiceIntentOutcome>(
      context: context,
      status: EngineDecisionStatus.accepted,
      value: const ServiceIntentOutcome(
        intent: ServiceIntentKind.scheduled,
        confidence: EngineConfidenceBand.high,
      ),
      engineVersion: 'intent-0.0.1',
      reasonCodes: const <EngineReasonCode>[
        EngineReasonCode.requestedScheduled,
      ],
      evaluatedAt: DateTime.utc(2026, 7, 24, 10, 1),
      auditEvent: EngineAuditEvent(
        type: EngineAuditEventType.serviceIntentEvaluated,
        correlationId: context.correlationId,
        occurredAt: DateTime.utc(2026, 7, 24, 10, 1),
      ),
    );

    expect(decision.contractVersion, engineContractVersion);
    expect(decision.engineVersion, 'intent-0.0.1');
    expect(
      decision.reasonCodes,
      <EngineReasonCode>[EngineReasonCode.requestedScheduled],
    );
    expect(
      () => decision.reasonCodes.add(EngineReasonCode.notEvaluated),
      throwsUnsupportedError,
    );
  });

  test('all eleven U1 ports are declared as independent contracts', () {
    expect(_ServiceIntentPort(), isA<ServiceIntentEnginePort>());
    expect(_RequestScopingPort(), isA<RequestScopingEnginePort>());
    expect(_MatchingPort(), isA<MatchingEnginePort>());
    expect(_PricingPort(), isA<PricingEnginePort>());
    expect(_TrustPolicyPort(), isA<TrustPolicyEnginePort>());
    expect(_JobOrchestratorPort(), isA<JobOrchestratorPort>());
    expect(_PaymentOrchestratorPort(), isA<PaymentOrchestratorPort>());
    expect(_ReputationPort(), isA<ReputationEnginePort>());
    expect(_SupportCasePort(), isA<SupportCaseEnginePort>());
    expect(_GrowthPort(), isA<GrowthEnginePort>());
    expect(_AnalyticsPort(), isA<AnalyticsEnginePort>());
  });

  test('every engine input requires the same market execution context', () {
    final inputs = <Object>[
      ServiceIntentInput(context: context, categoryCode: 'limpeza'),
      RequestScopingInput(
        context: context,
        categoryCode: 'limpeza',
        intent: ServiceIntentKind.scheduled,
      ),
      MatchingInput(
        context: context,
        requestRef: 'request-ref',
        scope: scope,
        candidates: const <MatchingCandidateSnapshot>[],
      ),
      PricingInput(
        context: context,
        requestRef: 'request-ref',
        scope: scope,
      ),
      TrustPolicyInput(
        context: context,
        subjectRef: 'provider-ref',
        actorRole: EngineActorRole.provider,
        categoryCode: 'limpeza',
        riskTier: RiskTier.moderate,
      ),
      JobTransitionInput(
        context: context,
        jobRef: 'job-ref',
        idempotencyKey: 'idem-job-0001',
        currentState: JobState.confirmed,
        targetState: JobState.scheduled,
        actorRole: EngineActorRole.system,
      ),
      PaymentInput(
        context: context,
        jobRef: 'job-ref',
        idempotencyKey: 'idem-payment-0001',
        operation: PaymentOperation.authorize,
        rail: PaymentRail.stripe,
        amountMinor: 1000,
      ),
      ReputationInput(
        context: context,
        providerRef: 'provider-ref',
        categoryCode: 'limpeza',
        completedJobs: 5,
        ratingBasisPoints: 480,
      ),
      SupportCaseInput(
        context: context,
        caseRef: 'case-ref',
        type: SupportCaseType.general,
        severity: SupportSeverity.low,
      ),
      GrowthInput(
        context: context,
        subjectRef: 'client-ref',
        trigger: GrowthTrigger.repeatService,
        completedJobs: 1,
      ),
      EngineAnalyticsInput(
        context: context,
        event: EngineAnalyticsEvent.requestCreated,
      ),
    ];

    expect(inputs, hasLength(11));
    expect(
      inputs.map(_contextOf),
      everyElement(same(context)),
    );
  });

  test('candidate snapshots and outcomes are defensively immutable', () {
    final candidates = <MatchingCandidateSnapshot>[
      const MatchingCandidateSnapshot(
        providerRef: 'provider-ref',
        categoryCompatible: true,
        withinServiceArea: true,
        available: true,
        trustEligible: true,
      ),
    ];
    final input = MatchingInput(
      context: context,
      requestRef: 'request-ref',
      scope: scope,
      candidates: candidates,
    );
    candidates.clear();

    expect(input.candidates, hasLength(1));
    expect(
      () => input.candidates.add(input.candidates.single),
      throwsUnsupportedError,
    );
  });

  test('critical job and payment inputs require idempotency keys', () {
    final job = JobTransitionInput(
      context: context,
      jobRef: 'job-ref',
      idempotencyKey: 'idem-job-0001',
      currentState: JobState.confirmed,
      targetState: JobState.scheduled,
      actorRole: EngineActorRole.system,
    );
    final payment = PaymentInput(
      context: context,
      jobRef: 'job-ref',
      idempotencyKey: 'idem-payment-0001',
      operation: PaymentOperation.authorize,
      rail: PaymentRail.stripe,
      amountMinor: 1000,
    );

    expect(job.idempotencyKey, 'idem-job-0001');
    expect(payment.idempotencyKey, 'idem-payment-0001');

    expect(
      () => JobTransitionInput(
        context: context,
        jobRef: 'job-ref',
        idempotencyKey: '',
        currentState: JobState.confirmed,
        targetState: JobState.scheduled,
        actorRole: EngineActorRole.system,
      ),
      throwsArgumentError,
    );
    expect(
      () => PaymentInput(
        context: context,
        jobRef: 'job-ref',
        idempotencyKey: 'short',
        operation: PaymentOperation.authorize,
        rail: PaymentRail.stripe,
        amountMinor: 1000,
      ),
      throwsArgumentError,
    );
    expect(
      () => PaymentInput(
        context: context,
        jobRef: 'job-ref',
        idempotencyKey: 'idem-payment-0002',
        operation: PaymentOperation.authorize,
        rail: PaymentRail.stripe,
        amountMinor: -1,
      ),
      throwsArgumentError,
    );
  });

  test('audit events carry the same valid correlation id as the context', () {
    final audit = EngineAuditEvent(
      type: EngineAuditEventType.jobTransitionEvaluated,
      correlationId: context.correlationId,
      occurredAt: DateTime.utc(2026, 7, 24, 10, 2),
      idempotencyKey: 'idem-job-0001',
    );

    expect(audit.isValid, isTrue);
    expect(audit.correlationId, context.correlationId);
  });

  test('decisions reject audit events from another execution context', () {
    expect(
      () => EngineDecision<ServiceIntentOutcome>(
        context: context,
        status: EngineDecisionStatus.accepted,
        value: const ServiceIntentOutcome(
          intent: ServiceIntentKind.scheduled,
          confidence: EngineConfidenceBand.high,
        ),
        engineVersion: 'intent-0.0.1',
        reasonCodes: const <EngineReasonCode>[
          EngineReasonCode.requestedScheduled,
        ],
        evaluatedAt: DateTime.utc(2026, 7, 24, 10, 3),
        auditEvent: EngineAuditEvent(
          type: EngineAuditEventType.serviceIntentEvaluated,
          correlationId: 'corr-request-other',
          occurredAt: DateTime.utc(2026, 7, 24, 10, 3),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('decision invariants are enforced at runtime', () {
    expect(
      () => EngineDecision<ServiceIntentOutcome>(
        context: context,
        status: EngineDecisionStatus.accepted,
        value: const ServiceIntentOutcome(
          intent: ServiceIntentKind.scheduled,
          confidence: EngineConfidenceBand.high,
        ),
        engineVersion: '',
        reasonCodes: const <EngineReasonCode>[],
        evaluatedAt: DateTime(2026, 7, 24, 10, 3),
        auditEvent: EngineAuditEvent(
          type: EngineAuditEventType.serviceIntentEvaluated,
          correlationId: context.correlationId,
          occurredAt: DateTime.utc(2026, 7, 24, 10, 3),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => EngineAuditEvent(
        type: EngineAuditEventType.serviceIntentEvaluated,
        correlationId: 'bad',
        occurredAt: DateTime.utc(2026, 7, 24, 10, 3),
      ),
      throwsArgumentError,
    );
  });

  test('legacy service intents and job states round-trip safely', () {
    expect(ServiceIntentKind.immediate.legacyMode, 'IMEDIATO');
    expect(ServiceIntentKind.scheduled.legacyMode, 'AGENDADO');
    expect(ServiceIntentKind.quote.legacyMode, 'POR_PROPOSTA');

    for (final state in JobState.values) {
      expect(
        LegacyJobStateAdapter.fromStatus(
          LegacyJobStateAdapter.toStatus(state),
        ),
        state,
      );
    }
    expect(
      LegacyJobStateAdapter.fromStatus('aguarda_resposta_cliente'),
      JobState.awaitingConfirmation,
    );
  });
}

EngineExecutionContext _contextOf(Object input) {
  return switch (input) {
    final ServiceIntentInput value => value.context,
    final RequestScopingInput value => value.context,
    final MatchingInput value => value.context,
    final PricingInput value => value.context,
    final TrustPolicyInput value => value.context,
    final JobTransitionInput value => value.context,
    final PaymentInput value => value.context,
    final ReputationInput value => value.context,
    final SupportCaseInput value => value.context,
    final GrowthInput value => value.context,
    final EngineAnalyticsInput value => value.context,
    _ => throw ArgumentError.value(input),
  };
}

final class _ServiceIntentPort implements ServiceIntentEnginePort {
  @override
  Future<EngineDecision<ServiceIntentOutcome>> classify(
    ServiceIntentInput input,
  ) {
    throw UnimplementedError();
  }
}

final class _RequestScopingPort implements RequestScopingEnginePort {
  @override
  Future<EngineDecision<RequestScope>> scope(RequestScopingInput input) {
    throw UnimplementedError();
  }
}

final class _MatchingPort implements MatchingEnginePort {
  @override
  Future<EngineDecision<MatchingOutcome>> match(MatchingInput input) {
    throw UnimplementedError();
  }
}

final class _PricingPort implements PricingEnginePort {
  @override
  Future<EngineDecision<PricingOutcome>> price(PricingInput input) {
    throw UnimplementedError();
  }
}

final class _TrustPolicyPort implements TrustPolicyEnginePort {
  @override
  Future<EngineDecision<TrustPolicyOutcome>> evaluate(
    TrustPolicyInput input,
  ) {
    throw UnimplementedError();
  }
}

final class _JobOrchestratorPort implements JobOrchestratorPort {
  @override
  Future<EngineDecision<JobTransitionOutcome>> transition(
    JobTransitionInput input,
  ) {
    throw UnimplementedError();
  }
}

final class _PaymentOrchestratorPort implements PaymentOrchestratorPort {
  @override
  Future<EngineDecision<PaymentOutcome>> process(PaymentInput input) {
    throw UnimplementedError();
  }
}

final class _ReputationPort implements ReputationEnginePort {
  @override
  Future<EngineDecision<ReputationOutcome>> evaluate(
    ReputationInput input,
  ) {
    throw UnimplementedError();
  }
}

final class _SupportCasePort implements SupportCaseEnginePort {
  @override
  Future<EngineDecision<SupportCaseOutcome>> route(SupportCaseInput input) {
    throw UnimplementedError();
  }
}

final class _GrowthPort implements GrowthEnginePort {
  @override
  Future<EngineDecision<GrowthOutcome>> recommend(GrowthInput input) {
    throw UnimplementedError();
  }
}

final class _AnalyticsPort implements AnalyticsEnginePort {
  @override
  Future<EngineDecision<EngineAnalyticsOutcome>> ingest(
    EngineAnalyticsInput input,
  ) {
    throw UnimplementedError();
  }
}
