import 'dart:collection';

/// Version of the privacy-safe analytics contract.
const int analyticsSchemaVersion = 1;

enum AnalyticsEventName {
  pedidoCriado('pedido_criado'),
  pedidoPropostaEnviada('pedido_proposta_enviada'),
  pedidoPropostaAceita('pedido_proposta_aceita'),
  pedidoPropostaRejeitada('pedido_proposta_rejeitada'),
  pedidoConviteManual('pedido_convite_manual'),
  pedidoConviteSubstituido('pedido_convite_substituido'),
  pedidoConviteAceite('pedido_convite_aceite'),
  pedidoConviteRecusado('pedido_convite_recusado'),
  pedidoAceiteFeed('pedido_aceite_feed'),
  pedidoIniciado('pedido_iniciado'),
  pedidoValorFinalProposto('pedido_valor_final_proposto'),
  pedidoValorFinalRejeitado('pedido_valor_final_rejeitado'),
  pedidoConcluido('pedido_concluido'),
  pedidoCanceladoCliente('pedido_cancelado_cliente'),
  pedidoCanceladoPrestador('pedido_cancelado_prestador'),
  pedidoDesistidoPrestador('pedido_desistido_prestador'),
  pedidoNoShowReportado('pedido_noshow_reportado'),
  matchingIniciado('matching_iniciado'),
  oportunidadeApresentada('oportunidade_apresentada'),
  pedidoRepetido('pedido_repetido'),
  disputaAberta('disputa_aberta');

  const AnalyticsEventName(this.wireName);

  final String wireName;

  static AnalyticsEventName? fromWireName(String value) {
    final normalized = value.trim().toLowerCase();
    for (final event in values) {
      if (event.wireName == normalized) {
        return event;
      }
    }
    return null;
  }
}

enum AnalyticsRole {
  cliente('cliente'),
  prestador('prestador'),
  admin('admin'),
  sistema('sistema'),
  unknown('unknown');

  const AnalyticsRole(this.wireName);

  final String wireName;

  static AnalyticsRole fromWireName(Object? value) {
    final normalized = '$value'.trim().toLowerCase();
    return values.firstWhere(
      (role) => role.wireName == normalized,
      orElse: () => unknown,
    );
  }
}

enum AnalyticsServiceMode {
  imediato('imediato'),
  agendado('agendado'),
  orcamento('orcamento'),
  unknown('unknown');

  const AnalyticsServiceMode(this.wireName);

  final String wireName;

  static AnalyticsServiceMode fromWireName(Object? value) {
    final normalized = '$value'.trim().toLowerCase();
    if (normalized == 'por_proposta' ||
        normalized == 'por_orcamento' ||
        normalized == 'quote') {
      return orcamento;
    }
    if (normalized == 'now') {
      return imediato;
    }
    if (normalized == 'scheduled') {
      return agendado;
    }
    return values.firstWhere(
      (mode) => mode.wireName == normalized,
      orElse: () => unknown,
    );
  }
}

enum AnalyticsPriceType {
  aCombinar('a_combinar'),
  fixo('fixo'),
  porOrcamento('por_orcamento'),
  porHora('por_hora'),
  intervalo('intervalo'),
  diagnostico('diagnostico'),
  porEtapas('por_etapas'),
  unknown('unknown');

  const AnalyticsPriceType(this.wireName);

  final String wireName;

  static AnalyticsPriceType fromWireName(Object? value) {
    final normalized = '$value'.trim().toLowerCase();
    return values.firstWhere(
      (type) => type.wireName == normalized,
      orElse: () => unknown,
    );
  }
}

enum AnalyticsPedidoState {
  criado('criado'),
  aguardaRespostaCliente('aguarda_resposta_cliente'),
  aguardaRespostaPrestador('aguarda_resposta_prestador'),
  aceite('aceito'),
  emAndamento('em_andamento'),
  aguardaConfirmacaoValor('aguarda_confirmacao_valor'),
  concluido('concluido'),
  cancelado('cancelado'),
  expirado('expirado'),
  semPrestador('sem_prestador'),
  substituicaoEmCurso('substituicao_em_curso'),
  emDisputa('em_disputa'),
  unknown('unknown');

  const AnalyticsPedidoState(this.wireName);

  final String wireName;

  static AnalyticsPedidoState fromWireName(Object? value) {
    final normalized = '$value'.trim().toLowerCase();
    return values.firstWhere(
      (state) => state.wireName == normalized,
      orElse: () => unknown,
    );
  }
}

enum AnalyticsOutcome {
  success('success'),
  failure('failure'),
  cancelled('cancelled'),
  unavailable('unavailable'),
  unknown('unknown');

  const AnalyticsOutcome(this.wireName);

  final String wireName;
}

enum AnalyticsPlatform {
  android('android'),
  web('web'),
  windows('windows'),
  ios('ios'),
  macos('macos'),
  linux('linux'),
  unknown('unknown');

  const AnalyticsPlatform(this.wireName);

  final String wireName;
}

/// Coarse product context only. It deliberately contains no user, request,
/// device, address or session identifiers.
final class AnalyticsContext {
  const AnalyticsContext({
    required this.marketCode,
    required this.countryCode,
    required this.languageCode,
    required this.platform,
    required this.appVersion,
    this.releaseChannel = 'unknown',
  });

  const AnalyticsContext.safeDefault()
      : marketCode = 'unspecified',
        countryCode = 'ZZ',
        languageCode = 'und',
        platform = AnalyticsPlatform.unknown,
        appVersion = '0',
        releaseChannel = 'unknown';

  final String marketCode;
  final String countryCode;
  final String languageCode;
  final AnalyticsPlatform platform;
  final String appVersion;
  final String releaseChannel;

  bool get isPrivacySafe {
    return RegExp(r'^[a-z][a-z0-9_-]{1,31}$').hasMatch(marketCode) &&
        RegExp(r'^[A-Z]{2}$').hasMatch(countryCode) &&
        RegExp(r'^[a-z]{2,3}$|^und$').hasMatch(languageCode) &&
        RegExp(r'^[0-9]+(?:\.[0-9]+){0,3}(?:\+[0-9]+)?$')
            .hasMatch(appVersion) &&
        RegExp(r'^[a-z][a-z0-9_-]{1,23}$').hasMatch(releaseChannel);
  }
}

/// A typed, aggregate-only event. Its shape cannot carry free text, contact
/// data, coordinates, URLs or business identifiers.
final class AnalyticsEvent {
  const AnalyticsEvent({
    required this.name,
    required this.context,
    this.role,
    this.serviceMode,
    this.priceType,
    this.pedidoState,
    this.outcome,
  });

  final AnalyticsEventName name;
  final AnalyticsContext context;
  final AnalyticsRole? role;
  final AnalyticsServiceMode? serviceMode;
  final AnalyticsPriceType? priceType;
  final AnalyticsPedidoState? pedidoState;
  final AnalyticsOutcome? outcome;

  bool get isPrivacySafe => context.isPrivacySafe;

  AnalyticsRecord toRecord() {
    return AnalyticsRecord(
      name: name.wireName,
      schemaVersion: analyticsSchemaVersion,
      parameters: <String, Object>{
        'market_code': context.marketCode,
        'country_code': context.countryCode,
        'language_code': context.languageCode,
        'platform': context.platform.wireName,
        'app_version': context.appVersion,
        'release_channel': context.releaseChannel,
        if (role != null) 'role': role!.wireName,
        if (serviceMode != null) 'modo': serviceMode!.wireName,
        if (priceType != null) 'tipo_preco': priceType!.wireName,
        if (pedidoState != null) 'estado': pedidoState!.wireName,
        if (outcome != null) 'outcome': outcome!.wireName,
        'schema_version': analyticsSchemaVersion,
      },
    );
  }
}

final class AnalyticsRecord {
  AnalyticsRecord({
    required this.name,
    required this.schemaVersion,
    required Map<String, Object> parameters,
  }) : parameters = UnmodifiableMapView(
          Map<String, Object>.from(parameters),
        );

  final String name;
  final int schemaVersion;
  final Map<String, Object> parameters;
}
