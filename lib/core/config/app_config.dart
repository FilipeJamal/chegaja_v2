import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Flavor { dev, staging, prod }

class AppConfig extends InheritedWidget {
  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;

  const AppConfig({
    super.key,
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required super.child,
  });

  static AppConfig? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfig>();
  }

  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;

  @override
  bool updateShouldNotify(covariant AppConfig oldWidget) {
    return false;
  }

  // --- Static Configuration (Restored & Enhanced) ---

  // Emuladores: Ativos se estivermos em Debug ou se .env forçar
  static bool get useFirebaseEmulators {
    return resolveUseFirebaseEmulators(
      isReleaseMode: kReleaseMode,
      isDebugMode: kDebugMode,
      configuredValue: dotenv.env['USE_FIREBASE_EMULATORS'],
    );
  }

  @visibleForTesting
  static bool resolveUseFirebaseEmulators({
    required bool isReleaseMode,
    required bool isDebugMode,
    String? configuredValue,
  }) {
    // A versao distribuida nunca deve tentar ligar-se a localhost. O ficheiro
    // .env de desenvolvimento pode manter os emuladores ativos para
    // `flutter run`, mas nao para builds de release.
    if (isReleaseMode) return false;

    final raw = configuredValue;
    if (raw != null && raw.trim().isNotEmpty) {
      return raw.trim().toLowerCase() == 'true';
    }
    return isDebugMode;
  }

  static String get emulatorHost {
    final envHost = dotenv.env['FIREBASE_EMULATOR_HOST'];
    if (envHost != null && envHost.trim().isNotEmpty) {
      final host = envHost.trim();
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.windows &&
          (host == '127.0.0.1' || host == '::1')) {
        return 'localhost';
      }
      return host;
    }
    if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return 'localhost';
    }
    return '127.0.0.1';
  }

  static String get functionsRegion {
    String? envRegion;
    try {
      envRegion = dotenv.env['FIREBASE_FUNCTIONS_REGION'];
    } catch (_) {
      envRegion = null;
    }
    if (envRegion != null && envRegion.trim().isNotEmpty) {
      return envRegion.trim();
    }
    return 'europe-west1';
  }

  static String? get appCheckWebRecaptchaSiteKey =>
      dotenv.env['APP_CHECK_WEB_KEY'];

  static String? get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'];

  static String? get googlePlacesApiKey => dotenv.env['GOOGLE_PLACES_API_KEY'];

  static bool get kycEnabled => _readBool('ENABLE_KYC', defaultValue: false);

  static bool get stripeEnabled =>
      _readBool('ENABLE_STRIPE', defaultValue: false);

  static bool get mpesaEnabled =>
      _readBool('ENABLE_MPESA', defaultValue: false);

  static bool get emolaEnabled =>
      _readBool('ENABLE_EMOLA', defaultValue: false);

  static bool get pilotMode => _readBool('PILOT_MODE', defaultValue: true);

  static bool get pilotPortugueseOnly =>
      pilotMode && _readBool('PILOT_PORTUGUESE_ONLY', defaultValue: true);

  static bool get pilotMaputoOnly =>
      pilotMode && _readBool('PILOT_MAPUTO_ONLY', defaultValue: true);

  static bool get storiesEnabled =>
      _readBool('ENABLE_STORIES', defaultValue: false);

  static bool get callsEnabled =>
      _readBool('ENABLE_CALLS', defaultValue: false);

  static bool get subscriptionsEnabled =>
      _readBool('ENABLE_SUBSCRIPTIONS', defaultValue: false);

  static bool get advancedRankingEnabled =>
      _readBool('ENABLE_ADVANCED_RANKING', defaultValue: false);

  static bool get windowsPublicEnabled =>
      _readBool('ENABLE_WINDOWS_PUBLIC', defaultValue: false);

  static const Set<String> pilotPromotedCategoryIds = {
    'cleaning_maintenance',
    'beauty_wellbeing',
    'food_catering',
    'home_repairs',
    'technology',
    'events',
  };

  static String get currencyCode {
    String? value;
    try {
      value = dotenv.env['DEFAULT_CURRENCY_CODE']?.trim().toUpperCase();
    } catch (_) {
      value = null;
    }
    return value == null || value.isEmpty ? 'MZN' : value;
  }

  static String get legalEntityName =>
      _readString('LEGAL_ENTITY_NAME', fallback: 'Filipe Bento Jamal');

  static String get legalEntityType => _readString(
        'LEGAL_ENTITY_TYPE',
        fallback: 'individual_project_promoter',
      );

  static String get legalEntityRoleLabel {
    switch (legalEntityType) {
      case 'individual_project_promoter':
        return 'pessoa singular e promotor do projeto';
      case 'individual_entrepreneur':
        return 'empresário individual';
      case 'incorporated_company':
        return 'empresa constituída';
      default:
        return 'responsável pelo projeto';
    }
  }

  static String get legalContactEmail => _readString(
        'LEGAL_CONTACT_EMAIL',
        fallback: 'Por confirmar antes do piloto externo',
      );

  static String get legalContactAddress => _readString(
        'LEGAL_CONTACT_ADDRESS',
        fallback: 'Por confirmar antes do piloto externo',
      );

  static bool get legalContactConfigured =>
      _hasConfiguredString('LEGAL_CONTACT_EMAIL') &&
      _hasConfiguredString('LEGAL_CONTACT_ADDRESS');

  static String _readString(String key, {required String fallback}) {
    try {
      final value = dotenv.env[key]?.trim();
      return value == null || value.isEmpty ? fallback : value;
    } catch (_) {
      return fallback;
    }
  }

  static bool _hasConfiguredString(String key) {
    try {
      return dotenv.env[key]?.trim().isNotEmpty == true;
    } catch (_) {
      return false;
    }
  }

  static bool _readBool(String key, {required bool defaultValue}) {
    String? raw;
    try {
      raw = dotenv.env[key]?.trim().toLowerCase();
    } catch (_) {
      return defaultValue;
    }
    if (raw == null || raw.isEmpty) return defaultValue;
    return raw == 'true' || raw == '1' || raw == 'yes';
  }

  static void debugPrintConfig() {
    if (kDebugMode) {
      print('--- AppConfig ---');
      print('Flavor: (Dynamic)');
      print('Emulators: $useFirebaseEmulators ($emulatorHost)');
      print('-----------------');
    }
  }
}
