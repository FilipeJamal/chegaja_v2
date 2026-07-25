import 'analytics_event.dart';

abstract interface class AnalyticsSink {
  Future<void> record(AnalyticsRecord event);
}

final class NoOpAnalyticsSink implements AnalyticsSink {
  const NoOpAnalyticsSink();

  @override
  Future<void> record(AnalyticsRecord event) async {}
}
