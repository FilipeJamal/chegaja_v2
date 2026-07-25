import '../analytics/analytics_event.dart';
import '../analytics/analytics_privacy_policy.dart';
import '../analytics/analytics_sink.dart';

typedef AnalyticsContextProvider = AnalyticsContext Function();
typedef AnalyticsErrorHandler = void Function(Object error, StackTrace trace);

class AnalyticsService {
  AnalyticsService({
    AnalyticsSink sink = const NoOpAnalyticsSink(),
    AnalyticsContextProvider? contextProvider,
    AnalyticsErrorHandler? onError,
  })  : _sink = sink,
        _contextProvider =
            contextProvider ?? _safeDefaultAnalyticsContextProvider,
        _onError = onError;

  static AnalyticsService _instance = AnalyticsService();

  /// Safe no-op until the application explicitly injects an approved sink.
  static AnalyticsService get instance => _instance;

  static void configure({
    required AnalyticsSink sink,
    AnalyticsContextProvider? contextProvider,
    AnalyticsErrorHandler? onError,
  }) {
    _instance = AnalyticsService(
      sink: sink,
      contextProvider: contextProvider,
      onError: onError,
    );
  }

  static void resetToSafeDefault() {
    _instance = AnalyticsService();
  }

  final AnalyticsSink _sink;
  final AnalyticsContextProvider _contextProvider;
  final AnalyticsErrorHandler? _onError;

  Future<void> track(AnalyticsEvent event) async {
    if (!AnalyticsPrivacyPolicy.accepts(event)) {
      return;
    }
    try {
      await _sink.record(event.toRecord());
    } catch (error, trace) {
      try {
        _onError?.call(error, trace);
      } catch (_) {
        // Analytics observability must never break the product flow.
      }
    }
  }

  /// Temporary compatibility bridge for pre-U1 call sites.
  ///
  /// Only known event names and categorical fields survive. Identifiers,
  /// coordinates, URLs, contact data and free text are never forwarded.
  @Deprecated('Use track(AnalyticsEvent) with typed dimensions.')
  Future<void> logEvent(String name, Map<String, Object> params) async {
    try {
      final eventName = AnalyticsEventName.fromWireName(name);
      if (eventName == null) {
        return;
      }

      final safe = AnalyticsPrivacyPolicy.sanitizeLegacyParameters(params);
      await track(
        AnalyticsEvent(
          name: eventName,
          context: _contextProvider(),
          role: safe.containsKey('role')
              ? AnalyticsRole.fromWireName(safe['role'])
              : null,
          serviceMode: safe.containsKey('modo')
              ? AnalyticsServiceMode.fromWireName(safe['modo'])
              : null,
          priceType: safe.containsKey('tipo_preco')
              ? AnalyticsPriceType.fromWireName(safe['tipo_preco'])
              : null,
          pedidoState: safe.containsKey('estado')
              ? AnalyticsPedidoState.fromWireName(safe['estado'])
              : null,
        ),
      );
    } catch (error, trace) {
      try {
        _onError?.call(error, trace);
      } catch (_) {
        // The compatibility bridge remains best-effort by design.
      }
    }
  }

  /// Compatibility bridge kept while pedido flows migrate to typed events.
  ///
  /// `pedidoId` is intentionally accepted for source compatibility and then
  /// discarded. It is never included in the analytics record.
  @Deprecated('Use track(AnalyticsEvent); identifiers are not analytics data.')
  Future<void> logPedidoEvent({
    required String name,
    required String pedidoId,
    required String estado,
    String? modo,
    String? tipoPreco,
    String? role,
  }) {
    return logEvent(name, <String, Object>{
      'estado': estado,
      if (modo != null) 'modo': modo,
      if (tipoPreco != null) 'tipo_preco': tipoPreco,
      if (role != null) 'role': role,
    });
  }
}

AnalyticsContext _safeDefaultAnalyticsContextProvider() {
  return const AnalyticsContext.safeDefault();
}
