import 'dart:convert';

import 'package:chegaja_v2/core/services/auth_service.dart';
import 'package:chegaja_v2/core/services/locale_service.dart';
import 'package:chegaja_v2/core/services/location_data_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bool kFastDevMode =
    bool.fromEnvironment('FAST_DEV_MODE', defaultValue: false);

class UserCountryService extends ChangeNotifier {
  UserCountryService._();
  static final UserCountryService instance = UserCountryService._();

  String? _countryCode;
  String? _currencyCode;
  bool _isManualOverride = false;
  static const String _overrideKey = 'user_country_code';
  static const Map<String, String> _currencyOverrides = {
    'AQ': 'USD', // No official currency, keep deterministic fallback.
  };

  // Map country -> currency loaded from country_state_city.
  final Map<String, String> _countryCurrencyMap = {};
  bool _currencyMapLoaded = false;

  /// Initialize and detect country.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCountry = prefs.getString(_overrideKey);

    if (savedCountry != null && savedCountry.trim().isNotEmpty) {
      _countryCode = savedCountry.trim().toUpperCase();
      _isManualOverride = true;
      await _ensureCurrencyMapLoaded();
      _updateCurrency();
      if (kDebugMode) {
        print('[UserCountryService] Loaded override: $_countryCode');
      }
      return;
    }

    if (kFastDevMode) {
      _countryCode = _fetchCountryFromSystemLocale() ?? 'PT';
      _currencyCode = _currencyFromLocale(_countryCode!) ?? 'EUR';
      notifyListeners();
      if (kDebugMode) {
        print(
            '[UserCountryService] Fast dev mode active: $_countryCode/$_currencyCode');
      }
      return;
    }

    final profileCountry = await _loadUserRegion();
    if (profileCountry != null && profileCountry.trim().isNotEmpty) {
      _countryCode = profileCountry.trim().toUpperCase();
      _isManualOverride = true;
      await _ensureCurrencyMapLoaded();
      _updateCurrency();
      if (kDebugMode) {
        print('[UserCountryService] Loaded from profile: $_countryCode');
      }
      return;
    }

    try {
      await _ensureCurrencyMapLoaded();

      // 1) Try system locale.
      final localeCountry = _fetchCountryFromSystemLocale();
      if (localeCountry != null && localeCountry.isNotEmpty) {
        _countryCode = localeCountry;
        if (kDebugMode) {
          print('[UserCountryService] Detected via locale: $_countryCode');
        }
      }

      // 2) If locale failed, try IP.
      if (_countryCode == null) {
        _countryCode = await _fetchCountryFromIP();
        if (kDebugMode) {
          print('[UserCountryService] Detected via IP: $_countryCode');
        }
      }

      _updateCurrency();

      if (kDebugMode) {
        print(
            '[UserCountryService] Final country: $_countryCode, currency: $_currencyCode');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('[UserCountryService] Fatal error: $e\n$st');
      }
    }
  }

  void _updateCurrency() {
    if (_countryCode != null) {
      final code = _countryCode!.trim().toUpperCase();
      var mapped = _countryCurrencyMap[code];
      if (mapped == null || mapped.trim().isEmpty) {
        mapped = _currencyFromLocale(code);
      }
      _currencyCode = (mapped != null && mapped.trim().isNotEmpty)
          ? mapped.trim().toUpperCase()
          : 'USD';
    } else {
      _currencyCode = 'USD';
    }
    notifyListeners();
  }

  Future<void> _ensureCurrencyMapLoaded() async {
    if (_currencyMapLoaded) return;
    try {
      final countries = await LocationDataService.instance.getCountries();
      for (final c in countries) {
        final code = c.isoCode.trim().toUpperCase();
        final currency = c.currency.trim().toUpperCase();
        if (code.isEmpty || currency.isEmpty) continue;
        _countryCurrencyMap[code] = currency;
      }
      _currencyOverrides.forEach((code, currency) {
        _countryCurrencyMap[code] = currency;
      });
      _currencyMapLoaded = true;
    } catch (e) {
      if (kDebugMode) {
        print('[UserCountryService] Currency map load failed: $e');
      }
    }
  }

  Future<void> setManualCountry(String countryCode) async {
    final normalized = countryCode.trim().toUpperCase();
    if (normalized.isEmpty) return;

    _countryCode = normalized;
    _isManualOverride = true;
    await _ensureCurrencyMapLoaded();
    _updateCurrency();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_overrideKey, normalized);

    try {
      await AuthService.updateUserRegion(normalized);
    } catch (_) {}
  }

  String? _currencyFromLocale(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return null;
    final language = LocaleService.instance.locale.languageCode;
    if (language.trim().isEmpty) return null;
    final localeName = '${language}_$code';
    try {
      final formatter = NumberFormat.simpleCurrency(locale: localeName);
      final name = formatter.currencyName;
      if (name == null || name.trim().isEmpty) return null;
      return name.trim().toUpperCase();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearManualOverride() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_overrideKey);
    _isManualOverride = false;
    _countryCode = null;
    _currencyCode = 'USD';
    await init();
  }

  String get countryCode => _countryCode ?? 'US';
  String get currencyCode => _currencyCode ?? 'USD';
  bool get isManualOverride => _isManualOverride;

  String? _fetchCountryFromSystemLocale() {
    final appLocaleCountry = LocaleService.instance.locale.countryCode;
    if (appLocaleCountry != null && appLocaleCountry.trim().isNotEmpty) {
      return appLocaleCountry.trim().toUpperCase();
    }

    try {
      for (final locale in PlatformDispatcher.instance.locales) {
        final localeCountry = locale.countryCode;
        if (localeCountry != null && localeCountry.trim().isNotEmpty) {
          return localeCountry.trim().toUpperCase();
        }
      }
    } catch (_) {
      // Ignore locale read errors.
    }
    return null;
  }

  /// Lightweight request to infer country by IP.
  Future<String?> _fetchCountryFromIP() async {
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['countryCode'] as String?;
      }
    } catch (_) {
      // Ignore timeout or network errors.
    }
    return null;
  }

  Future<String?> _loadUserRegion() async {
    try {
      return await AuthService.getUserRegion();
    } catch (_) {
      return null;
    }
  }
}
