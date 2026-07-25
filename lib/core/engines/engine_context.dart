const String engineContractVersion = 'u1.1';

final class EngineMarketContext {
  const EngineMarketContext({
    required this.marketCode,
    required this.countryCode,
    required this.currencyCode,
    required this.localeTag,
    required this.timeZone,
  });

  final String marketCode;
  final String countryCode;
  final String currencyCode;
  final String localeTag;
  final String timeZone;

  bool get isValid {
    return RegExp(r'^[a-z][a-z0-9_-]{1,31}$').hasMatch(marketCode) &&
        RegExp(r'^[A-Z]{2}$').hasMatch(countryCode) &&
        RegExp(r'^[A-Z]{3}$').hasMatch(currencyCode) &&
        RegExp(r'^[a-z]{2,3}(?:-[A-Z]{2})?$').hasMatch(localeTag) &&
        (timeZone == 'UTC' ||
            RegExp(r'^[A-Za-z_]+(?:/[A-Za-z0-9_+-]+)+$').hasMatch(timeZone));
  }
}

final class EngineExecutionContext {
  const EngineExecutionContext({
    required this.market,
    required this.requestedAt,
    required this.correlationId,
    this.contractVersion = engineContractVersion,
  });

  final EngineMarketContext market;
  final DateTime requestedAt;
  final String correlationId;
  final String contractVersion;

  bool get isValid {
    return market.isValid &&
        contractVersion == engineContractVersion &&
        requestedAt.isUtc &&
        RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{7,127}$').hasMatch(correlationId);
  }
}
