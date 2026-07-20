import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../services/locale_service.dart';

class CurrencyUtils {
  /// Formata um valor double como string de moeda.
  ///
  /// No piloto usa MZN; o locale do telemóvel controla a formatação numérica.
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
    final currencyCode = AppConfig.currencyCode;
    final resolvedLocale = localeName ?? _defaultLocaleName();
    return NumberFormat.currency(
      name: currencyCode,
      symbol: currencyCode == 'MZN' ? 'MT' : currencyCode,
      locale: resolvedLocale,
      decimalDigits: 2,
    );
  }

  /// Retorna apenas o simbolo da moeda atual (ex: EUR ou $)
  static String currencySymbol({String? localeName}) {
    return formatter(localeName: localeName).currencySymbol;
  }

  static String _defaultLocaleName() {
    final language = LocaleService.instance.locale.languageCode;
    return language.isEmpty ? 'pt' : language;
  }
}
