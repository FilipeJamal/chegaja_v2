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
     final raw = dotenv.env['USE_FIREBASE_EMULATORS'];
     if (raw != null && raw.trim().isNotEmpty) {
       return raw.trim().toLowerCase() == 'true';
     }
     return kDebugMode;
  }

  static String get emulatorHost {
    final envHost = dotenv.env['FIREBASE_EMULATOR_HOST'];
    if (envHost != null && envHost.trim().isNotEmpty) {
      return envHost.trim();
    }
    return defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : '127.0.0.1';
  }

  static String get functionsRegion {
    final envRegion = dotenv.env['FIREBASE_FUNCTIONS_REGION'];
    if (envRegion != null && envRegion.trim().isNotEmpty) {
      return envRegion.trim();
    }
    return 'europe-west1';
  }

  static String? get appCheckWebRecaptchaSiteKey => dotenv.env['APP_CHECK_WEB_KEY'];
  
  static String? get stripePublishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'];

  static String? get googlePlacesApiKey => dotenv.env['GOOGLE_PLACES_API_KEY'];

  static void debugPrintConfig() {
    if (kDebugMode) {
      print('--- AppConfig ---');
      print('Flavor: (Dynamic)');
      print('Emulators: $useFirebaseEmulators ($emulatorHost)');
      print('-----------------');
    }
  }
}
