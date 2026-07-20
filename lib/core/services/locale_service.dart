import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

import 'package:chegaja_v2/core/config/app_config.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService instance = LocaleService._();

  LocaleService._();

  Locale? _locale;
  final String _storageKey = 'app_locale';

  Locale get locale {
    if (AppConfig.pilotPortugueseOnly) return const Locale('pt', 'MZ');
    if (_locale != null) return _locale!;
    // Default to system locale
    return ui.PlatformDispatcher.instance.locale;
  }

  bool get isManualOverride => _locale != null;

  /// Inicializa o serviço carregando a preferência salva
  Future<void> load() async {
    if (AppConfig.pilotPortugueseOnly) {
      _locale = const Locale('pt', 'MZ');
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString(_storageKey);

    if (langCode != null) {
      _locale = Locale(langCode);
      notifyListeners();
    }
  }

  /// Muda o idioma e persiste a escolha
  Future<void> setLocale(Locale newLocale) async {
    if (AppConfig.pilotPortugueseOnly) return;
    if (newLocale == _locale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, newLocale.languageCode);
  }

  /// Limpa a preferência (volta ao automático)
  Future<void> clearLocale() async {
    if (AppConfig.pilotPortugueseOnly) return;
    _locale = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
