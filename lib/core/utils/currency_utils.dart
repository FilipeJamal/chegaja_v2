import 'package:intl/intl.dart';
import '../services/user_country_service.dart';
import '../services/locale_service.dart';

class CurrencyUtils {
  /// Formata um valor double como string de moeda.
  /// 
  /// Ursa a moeda detetada pelo UserCountryService (SIM ou IP),
  /// mas usa o locale do telemóvel para formatação numérica (vírgula vs ponto).
  /// 
  /// Exemplo (PT, Angola): "1.000,00 Kz"
  /// Exemplo (EN, Angola): "Kz 1,000.00"
  static String format(double? value, {String? localeName}) {
    if (value == null) return '-';

    // simpleCurrency cria um formatador adaptado ao locale, mas forcando a moeda
    // Se nao passarmos locale explicito, usa o do sistema (que e o que queremos para separadores)
    return formatter(localeName: localeName).format(value);
  }

  static NumberFormat formatter({String? localeName}) {
    final currencyCode = UserCountryService.instance.currencyCode;
    final resolvedLocale = localeName ?? _defaultLocaleName();
    return NumberFormat.simpleCurrency(name: currencyCode, locale: resolvedLocale);
  }

  /// Retorna apenas o simbolo da moeda atual (ex: EUR ou $)
  static String currencySymbol({String? localeName}) {
    return formatter(localeName: localeName).currencySymbol;
  }

  static String _defaultLocaleName() {
    final language = LocaleService.instance.locale.languageCode;
    final region = UserCountryService.instance.countryCode;
    if (language.isEmpty) return region;
    if (region.isEmpty) return language;
    return '${language}_$region';
  }
}
