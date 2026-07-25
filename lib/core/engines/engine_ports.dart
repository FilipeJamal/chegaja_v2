import 'engine_models.dart';

abstract interface class ServiceIntentEnginePort {
  Future<EngineDecision<ServiceIntentOutcome>> classify(
    ServiceIntentInput input,
  );
}

abstract interface class RequestScopingEnginePort {
  Future<EngineDecision<RequestScope>> scope(RequestScopingInput input);
}

abstract interface class MatchingEnginePort {
  Future<EngineDecision<MatchingOutcome>> match(MatchingInput input);
}

abstract interface class PricingEnginePort {
  Future<EngineDecision<PricingOutcome>> price(PricingInput input);
}

abstract interface class TrustPolicyEnginePort {
  Future<EngineDecision<TrustPolicyOutcome>> evaluate(
    TrustPolicyInput input,
  );
}

abstract interface class JobOrchestratorPort {
  Future<EngineDecision<JobTransitionOutcome>> transition(
    JobTransitionInput input,
  );
}

abstract interface class PaymentOrchestratorPort {
  Future<EngineDecision<PaymentOutcome>> process(PaymentInput input);
}

abstract interface class ReputationEnginePort {
  Future<EngineDecision<ReputationOutcome>> evaluate(
    ReputationInput input,
  );
}

abstract interface class SupportCaseEnginePort {
  Future<EngineDecision<SupportCaseOutcome>> route(SupportCaseInput input);
}

abstract interface class GrowthEnginePort {
  Future<EngineDecision<GrowthOutcome>> recommend(GrowthInput input);
}

abstract interface class AnalyticsEnginePort {
  Future<EngineDecision<EngineAnalyticsOutcome>> ingest(
    EngineAnalyticsInput input,
  );
}
