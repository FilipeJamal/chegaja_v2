import 'analytics_event.dart';

abstract final class AnalyticsPrivacyPolicy {
  static const allowedParameterKeys = <String>{
    'market_code',
    'country_code',
    'language_code',
    'platform',
    'app_version',
    'release_channel',
    'role',
    'modo',
    'tipo_preco',
    'estado',
    'outcome',
    'schema_version',
  };

  static const legacyAllowedKeys = <String>{
    'estado',
    'modo',
    'tipo_preco',
    'role',
  };

  static const discardedLegacyIdentifierKeys = <String>{
    'pedido_id',
  };

  static bool accepts(AnalyticsEvent event) {
    if (!event.isPrivacySafe) {
      return false;
    }
    final record = event.toRecord();
    return record.parameters.keys.every(allowedParameterKeys.contains);
  }

  /// Returns only the four categorical fields supported by the temporary
  /// bridge. Everything else, including `pedido_id`, is rejected.
  static Map<String, Object> sanitizeLegacyParameters(
    Map<String, Object> parameters,
  ) {
    final safe = <String, Object>{};
    for (final entry in parameters.entries) {
      final key = entry.key.trim().toLowerCase();
      if (discardedLegacyIdentifierKeys.contains(key)) {
        continue;
      }
      if (legacyAllowedKeys.contains(key)) {
        safe[key] = entry.value;
      }
    }
    return safe;
  }
}
