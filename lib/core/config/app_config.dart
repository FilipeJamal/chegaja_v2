import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuração central do app.
///
/// Ordem de prioridade (por chave):
/// 1) `.env` (flutter_dotenv)
/// 2) `--dart-define` (String.fromEnvironment)
/// 3) valores por defeito
class AppConfig {
  AppConfig._();

  static String? _env(String key) {
    final v = dotenv.env[key];
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  /// Web Push (FCM) — chave VAPID pública.
  static String? get fcmVapidKey {
    return _env('FCM_VAPID_KEY') ?? const String.fromEnvironment('FCM_VAPID_KEY');
  }

  /// Stripe publishable key (pk_...).
  static String? get stripePublishableKey {
    return _env('STRIPE_PUBLISHABLE_KEY') ??
        const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  }

  /// Usa emuladores Firebase no dev.
  static bool get useFirebaseEmulators {
    final v = _env('USE_FIREBASE_EMULATORS') ??
        const String.fromEnvironment('USE_FIREBASE_EMULATORS');
    return v.trim().toLowerCase() == 'true';
  }

  /// Região das Cloud Functions.
  ///
  /// Mantém igual à definida em `functions/index.js`.
  static String get functionsRegion {
    final v = _env('FUNCTIONS_REGION')?.trim();
    if (v != null && v.isNotEmpty) return v;
    const d = String.fromEnvironment('FUNCTIONS_REGION', defaultValue: 'europe-west1');
    return d.trim().isNotEmpty ? d.trim() : 'europe-west1';
  }

  static String get emulatorHost {
    return _env('FIREBASE_EMULATOR_HOST') ??
        const String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: 'localhost');
  }

  /// Comissão da plataforma (fallback). Pode ser sobrescrita por Remote Config.
  static double get defaultCommissionRate {
    final v = _env('DEFAULT_COMMISSION_RATE') ??
        const String.fromEnvironment('DEFAULT_COMMISSION_RATE', defaultValue: '0.15');
    return double.tryParse(v.replaceAll(',', '.')) ?? 0.15;
  }

  /// URL base do domínio (para App Links/Universal Links). Ex.: https://app.chegaja.pt
  static String? get appBaseUrl {
    return _env('APP_BASE_URL') ?? const String.fromEnvironment('APP_BASE_URL');
  }

  /// Base URL for calls (Jitsi). Override with CALL_BASE_URL if needed.
  static String get callBaseUrl {
    final v = _env('CALL_BASE_URL') ?? const String.fromEnvironment('CALL_BASE_URL');
    final trimmed = v.trim();
    return trimmed.isNotEmpty ? trimmed : 'https://meet.jit.si';
  }

  /// App Check (Web) — reCAPTCHA v3 site key (opcional).
  static String? get appCheckWebRecaptchaSiteKey {
    return _env('APPCHECK_WEB_RECAPTCHA_SITE_KEY') ??
        const String.fromEnvironment('APPCHECK_WEB_RECAPTCHA_SITE_KEY');
  }

  static void debugPrintConfig() {
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('[AppConfig] useEmulators=$useFirebaseEmulators host=$emulatorHost');
  }
}
