import 'package:flutter/material.dart';

@immutable
class MarketBounds {
  const MarketBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  bool contains({required double latitude, required double longitude}) {
    return latitude >= south &&
        latitude <= north &&
        longitude >= west &&
        longitude <= east;
  }
}

@immutable
class MarketConfig {
  const MarketConfig({
    required this.id,
    required this.countryCode,
    required this.currencyCode,
    required this.locale,
    required this.timeZone,
    required this.callingCode,
    required this.city,
    required this.supportedCities,
    required this.serviceAreaLabel,
    required this.bounds,
  });

  final String id;
  final String countryCode;
  final String currencyCode;
  final Locale locale;
  final String timeZone;
  final String callingCode;
  final String city;
  final List<String> supportedCities;
  final String serviceAreaLabel;
  final MarketBounds bounds;

  static const MarketConfig coimbraPilot = MarketConfig(
    id: 'pt-coimbra',
    countryCode: 'PT',
    currencyCode: 'EUR',
    locale: Locale('pt', 'PT'),
    timeZone: 'Europe/Lisbon',
    callingCode: '+351',
    city: 'Coimbra',
    supportedCities: ['Coimbra'],
    serviceAreaLabel: 'Coimbra e zonas próximas',
    bounds: MarketBounds(
      south: 40.13,
      west: -8.52,
      north: 40.30,
      east: -8.30,
    ),
  );

  /// Historical baseline for the later Mozambique adaptation.
  static const MarketConfig maputoAdaptation = MarketConfig(
    id: 'mz-maputo',
    countryCode: 'MZ',
    currencyCode: 'MZN',
    locale: Locale('pt', 'MZ'),
    timeZone: 'Africa/Maputo',
    callingCode: '+258',
    city: 'Maputo',
    supportedCities: ['Maputo', 'Matola'],
    serviceAreaLabel: 'Maputo e Matola',
    bounds: MarketBounds(
      south: -26.15,
      west: 32.35,
      north: -25.75,
      east: 32.75,
    ),
  );

  static const Map<String, MarketConfig> supported = {
    'pt-coimbra': coimbraPilot,
    'mz-maputo': maputoAdaptation,
  };

  static MarketConfig resolve(String? marketId) {
    final normalized = marketId?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return coimbraPilot;
    return supported[normalized] ?? coimbraPilot;
  }
}
