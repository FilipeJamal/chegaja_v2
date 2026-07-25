import 'package:chegaja_v2/core/config/market_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Coimbra is the safe default and canonical first pilot market', () {
    final market = MarketConfig.resolve(null);

    expect(market.id, 'pt-coimbra');
    expect(market.countryCode, 'PT');
    expect(market.currencyCode, 'EUR');
    expect(market.locale.toLanguageTag(), 'pt-PT');
    expect(market.timeZone, 'Europe/Lisbon');
    expect(market.callingCode, '+351');
    expect(market.supportedCities, const ['Coimbra']);
  });

  test('unknown market ids fail safely to Coimbra', () {
    expect(MarketConfig.resolve('unknown').id, 'pt-coimbra');
  });

  test('Mozambique remains explicit later-adaptation configuration', () {
    final market = MarketConfig.resolve('mz-maputo');

    expect(market.countryCode, 'MZ');
    expect(market.currencyCode, 'MZN');
    expect(market.id, isNot(MarketConfig.coimbraPilot.id));
    expect(market.supportedCities, const ['Maputo', 'Matola']);
  });

  test('Coimbra bounds contain the city centre but reject Maputo', () {
    expect(
      MarketConfig.coimbraPilot.bounds.contains(
        latitude: 40.2033,
        longitude: -8.4103,
      ),
      isTrue,
    );
    expect(
      MarketConfig.coimbraPilot.bounds.contains(
        latitude: -25.9692,
        longitude: 32.5732,
      ),
      isFalse,
    );
  });
}
