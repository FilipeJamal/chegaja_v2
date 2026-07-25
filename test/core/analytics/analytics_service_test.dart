import 'package:chegaja_v2/core/analytics/analytics_event.dart';
import 'package:chegaja_v2/core/analytics/analytics_sink.dart';
import 'package:chegaja_v2/core/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const safeContext = AnalyticsContext(
    marketCode: 'pt-coimbra',
    countryCode: 'PT',
    languageCode: 'pt',
    platform: AnalyticsPlatform.android,
    appVersion: '1.0.0+1',
    releaseChannel: 'pilot',
  );

  tearDown(AnalyticsService.resetToSafeDefault);

  test('defaults to a safe no-op sink', () async {
    await AnalyticsService.instance.track(
      const AnalyticsEvent(
        name: AnalyticsEventName.pedidoCriado,
        context: safeContext,
      ),
    );
  });

  test('records only typed aggregate dimensions', () async {
    final sink = _MemorySink();
    final service = AnalyticsService(sink: sink);

    await service.track(
      const AnalyticsEvent(
        name: AnalyticsEventName.pedidoConcluido,
        context: safeContext,
        role: AnalyticsRole.cliente,
        serviceMode: AnalyticsServiceMode.agendado,
        priceType: AnalyticsPriceType.fixo,
        pedidoState: AnalyticsPedidoState.concluido,
        outcome: AnalyticsOutcome.success,
      ),
    );

    expect(sink.events, hasLength(1));
    final record = sink.events.single;
    expect(record.name, 'pedido_concluido');
    expect(record.schemaVersion, analyticsSchemaVersion);
    expect(
      record.parameters,
      containsPair('market_code', 'pt-coimbra'),
    );
    expect(record.parameters, containsPair('estado', 'concluido'));
    expect(record.parameters, isNot(contains('pedido_id')));
    expect(record.parameters, isNot(contains('uid')));
    expect(record.parameters, isNot(contains('descricao')));
  });

  test('drops events with an unsafe coarse context', () async {
    final sink = _MemorySink();
    final service = AnalyticsService(sink: sink);

    await service.track(
      const AnalyticsEvent(
        name: AnalyticsEventName.pedidoCriado,
        context: AnalyticsContext(
          marketCode: 'Filipe Jamal',
          countryCode: 'PT',
          languageCode: 'pt',
          platform: AnalyticsPlatform.web,
          appVersion: '1.0.0',
        ),
      ),
    );

    expect(sink.events, isEmpty);
  });

  test('legacy pedido bridge discards pedidoId before the sink', () async {
    final sink = _MemorySink();
    final service = AnalyticsService(
      sink: sink,
      contextProvider: () => safeContext,
    );

    // ignore: deprecated_member_use_from_same_package
    await service.logPedidoEvent(
      name: 'pedido_criado',
      pedidoId: 'pedido-secret-123',
      estado: 'criado',
      modo: 'IMEDIATO',
      tipoPreco: 'a_combinar',
      role: 'cliente',
    );

    expect(sink.events, hasLength(1));
    expect(
      sink.events.single.parameters,
      containsPair('modo', 'imediato'),
    );
    expect(
      sink.events.single.parameters.values,
      isNot(contains('pedido-secret-123')),
    );
  });

  test('legacy service modes map to stable categorical values', () async {
    final sink = _MemorySink();
    final service = AnalyticsService(
      sink: sink,
      contextProvider: () => safeContext,
    );

    // ignore: deprecated_member_use_from_same_package
    await service.logPedidoEvent(
      name: 'pedido_criado',
      pedidoId: 'discarded',
      estado: 'criado',
      modo: 'POR_PROPOSTA',
    );

    expect(
      sink.events.single.parameters,
      containsPair('modo', 'orcamento'),
    );
  });

  test('legacy bridge rejects identifiers, PII, coordinates, URLs and text',
      () async {
    final sink = _MemorySink();
    final service = AnalyticsService(
      sink: sink,
      contextProvider: () => safeContext,
    );

    // ignore: deprecated_member_use_from_same_package
    await service.logEvent('pedido_criado', <String, Object>{
      'pedido_id': 'pedido-1',
      'user_id': 'user-1',
      'email': 'pessoa@example.com',
      'telefone': '+351912345678',
      'latitude': 40.2033,
      'longitude': -8.4103,
      'url': 'https://example.com/private',
      'descricao': 'Texto livre do pedido',
      'estado': 'criado',
      'modo': 'AGENDADO',
      'role': 'cliente',
    });

    expect(sink.events, hasLength(1));
    final parameters = sink.events.single.parameters;
    expect(
      parameters.keys,
      everyElement(
        isIn(<String>{
          'market_code',
          'country_code',
          'language_code',
          'platform',
          'app_version',
          'release_channel',
          'role',
          'modo',
          'estado',
          'schema_version',
        }),
      ),
    );
    expect(parameters.values.join('|'), isNot(contains('example.com')));
    expect(parameters.values.join('|'), isNot(contains('Texto livre')));
  });

  test('unknown legacy event names are rejected', () async {
    final sink = _MemorySink();
    final service = AnalyticsService(
      sink: sink,
      contextProvider: () => safeContext,
    );

    // ignore: deprecated_member_use_from_same_package
    await service.logEvent(
      'Filipe abriu o pedido 123',
      const <String, Object>{'estado': 'criado'},
    );

    expect(sink.events, isEmpty);
  });

  test('sink failures never break the product flow', () async {
    Object? reportedError;
    final service = AnalyticsService(
      sink: _ThrowingSink(),
      onError: (error, _) => reportedError = error,
    );

    await expectLater(
      service.track(
        const AnalyticsEvent(
          name: AnalyticsEventName.pedidoCriado,
          context: safeContext,
        ),
      ),
      completes,
    );

    expect(reportedError, isA<StateError>());
  });

  test('a failing error observer is also isolated', () async {
    final service = AnalyticsService(
      sink: _ThrowingSink(),
      onError: (_, __) => throw StateError('observer offline'),
    );

    await expectLater(
      service.track(
        const AnalyticsEvent(
          name: AnalyticsEventName.pedidoCriado,
          context: safeContext,
        ),
      ),
      completes,
    );
  });

  test('a failing legacy context provider is isolated', () async {
    final service = AnalyticsService(
      sink: _MemorySink(),
      contextProvider: () => throw StateError('context unavailable'),
    );

    await expectLater(
      // ignore: deprecated_member_use_from_same_package
      service.logEvent(
        'pedido_criado',
        const <String, Object>{'estado': 'criado'},
      ),
      completes,
    );
  });

  test('records expose immutable parameters', () {
    final record = const AnalyticsEvent(
      name: AnalyticsEventName.pedidoCriado,
      context: safeContext,
    ).toRecord();

    expect(
      () => record.parameters['pedido_id'] = 'not-allowed',
      throwsUnsupportedError,
    );
  });
}

final class _MemorySink implements AnalyticsSink {
  final List<AnalyticsRecord> events = <AnalyticsRecord>[];

  @override
  Future<void> record(AnalyticsRecord event) async {
    events.add(event);
  }
}

final class _ThrowingSink implements AnalyticsSink {
  @override
  Future<void> record(AnalyticsRecord event) {
    throw StateError('sink offline');
  }
}
