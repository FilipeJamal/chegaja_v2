import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chegaja_v2/core/services/locale_service.dart';
import 'package:chegaja_v2/core/services/user_country_service.dart';
import 'package:chegaja_v2/core/utils/currency_utils.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('supports all expected app locales', () {
    final codes =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    expect(
      codes,
      containsAll(
        <String>{'pt', 'en', 'es', 'fr', 'de', 'ar', 'ru', 'zh', 'hi'},
      ),
    );
  });

  test('pilot forces Portuguese even when another locale is requested',
      () async {
    await LocaleService.instance.setLocale(const Locale('pt'));
    expect(LocaleService.instance.locale.languageCode, 'pt');

    await LocaleService.instance.setLocale(const Locale('en'));
    expect(LocaleService.instance.locale.languageCode, 'pt');
    expect(LocaleService.instance.locale.countryCode, 'PT');
  });

  test('Coimbra pilot currency stays EUR while formatting follows locale',
      () async {
    await LocaleService.instance.setLocale(const Locale('en'));

    await UserCountryService.instance.setManualCountry('US');
    expect(UserCountryService.instance.countryCode, 'PT');
    expect(UserCountryService.instance.currencyCode, 'EUR');
    final us = CurrencyUtils.format(1.5, localeName: 'en_US');

    await UserCountryService.instance.setManualCountry('BR');
    expect(UserCountryService.instance.countryCode, 'PT');
    expect(UserCountryService.instance.currencyCode, 'EUR');
    final br = CurrencyUtils.format(1.5, localeName: 'pt_BR');

    expect(CurrencyUtils.format(1, localeName: 'pt_PT'), contains('€'));
    expect(us, isNotEmpty);
    expect(br, isNotEmpty);
    expect(us, isNot(equals(br)));
    expect(us, contains('€'));
    expect(br, contains('€'));
    expect(br, contains(','));
    expect(CurrencyUtils.currencySymbol(localeName: 'pt_BR'), isNotEmpty);
  });
}
