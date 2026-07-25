import '../catalog/service_intent.dart';
import 'engine_models.dart';

extension ServiceIntentEngineAdapter on ServiceIntent {
  ServiceIntentKind get engineKind => switch (this) {
        ServiceIntent.now => ServiceIntentKind.immediate,
        ServiceIntent.scheduled => ServiceIntentKind.scheduled,
        ServiceIntent.quote => ServiceIntentKind.quote,
      };
}

extension ServiceIntentKindLegacyAdapter on ServiceIntentKind {
  ServiceIntent get legacyIntent => switch (this) {
        ServiceIntentKind.immediate => ServiceIntent.now,
        ServiceIntentKind.scheduled => ServiceIntent.scheduled,
        ServiceIntentKind.quote => ServiceIntent.quote,
      };

  String get legacyMode => legacyIntent.legacyMode;
}

abstract final class LegacyJobStateAdapter {
  static JobState fromStatus(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'rascunho' => JobState.draft,
      'submetido' || 'criado' || 'aberto' => JobState.submitted,
      'a_procura' || 'procurando' => JobState.searching,
      'proposta_recebida' => JobState.proposalReceived,
      'prestador_atribuido' => JobState.providerAssigned,
      'aguarda_confirmacao' ||
      'aguarda_resposta_cliente' ||
      'aguarda_resposta_prestador' =>
        JobState.awaitingConfirmation,
      'aceito' || 'confirmado' => JobState.confirmed,
      'agendado' => JobState.scheduled,
      'a_caminho' => JobState.enRoute,
      'chegou' => JobState.arrived,
      'em_andamento' || 'em_execucao' => JobState.inProgress,
      'aguarda_confirmacao_final' ||
      'aguarda_confirmacao_valor' =>
        JobState.awaitingFinalConfirmation,
      'concluido' => JobState.completed,
      'cancelado' => JobState.cancelled,
      'expirado' => JobState.expired,
      'sem_prestador' => JobState.noProvider,
      'substituicao_em_curso' => JobState.replacementInProgress,
      'em_disputa' => JobState.disputed,
      'correcao_necessaria' => JobState.correctionRequired,
      'reembolsado' => JobState.refunded,
      _ => JobState.draft,
    };
  }

  static String toStatus(JobState state) => switch (state) {
        JobState.draft => 'rascunho',
        JobState.submitted => 'submetido',
        JobState.searching => 'a_procura',
        JobState.proposalReceived => 'proposta_recebida',
        JobState.providerAssigned => 'prestador_atribuido',
        JobState.awaitingConfirmation => 'aguarda_confirmacao',
        JobState.confirmed => 'confirmado',
        JobState.scheduled => 'agendado',
        JobState.enRoute => 'a_caminho',
        JobState.arrived => 'chegou',
        JobState.inProgress => 'em_execucao',
        JobState.awaitingFinalConfirmation => 'aguarda_confirmacao_final',
        JobState.completed => 'concluido',
        JobState.cancelled => 'cancelado',
        JobState.expired => 'expirado',
        JobState.noProvider => 'sem_prestador',
        JobState.replacementInProgress => 'substituicao_em_curso',
        JobState.disputed => 'em_disputa',
        JobState.correctionRequired => 'correcao_necessaria',
        JobState.refunded => 'reembolsado',
      };
}
