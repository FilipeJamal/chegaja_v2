import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'firebase_options.dart';
import 'app.dart';

import 'core/config/app_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/servico_seed.dart';
import 'core/services/deep_link_service.dart';

/// ✅ Quando corres `flutter test ...` tu já tens isto no log:
/// -DRUN_FIREBASE_EMULATOR_TESTS=true
const bool kRunFirebaseEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

bool _supportsFcm() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// Handler de mensagens em background (Android/iOS; no Web é via service worker).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
}

Future<void> main() async {

  // ? Captura erros "invis?veis" que matam o app durante testes
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Carrega .env (opcional)
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}

    AppConfig.debugPrintConfig();

    // Firebase init
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Firestore (Web): evita estado estranho em dev/tests
    if (kIsWeb) {
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: false);
    }

    // Crashlytics: NÃƒO em testes, e NÃƒO no Web
    if (!kIsWeb && !kRunFirebaseEmulatorTests) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Emuladores Firebase (DEV)
    if (AppConfig.useFirebaseEmulators) {
      final host = AppConfig.emulatorHost;
      try {
        FirebaseAuth.instance.useAuthEmulator(host, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
        FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion)
            .useFunctionsEmulator(host, 5001);
        FirebaseStorage.instance.useStorageEmulator(host, 9199);

        if (kDebugMode) {
          // ignore: avoid_print
          print('[Firebase] Emuladores configurados em $host');
        }
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[Firebase] ERRO ao configurar emuladores: $e');
        }
      }
    }

    // App Check: NÃO em testes (muitas vezes dá confusão)
    if (!kRunFirebaseEmulatorTests) {
      try {
        if (kIsWeb) {
          final siteKey = AppConfig.appCheckWebRecaptchaSiteKey;
          if (siteKey != null && siteKey.trim().isNotEmpty) {
            await FirebaseAppCheck.instance.activate(
              providerWeb: ReCaptchaV3Provider(siteKey),
            );
          }
        } else {
          await FirebaseAppCheck.instance.activate(
            providerAndroid: kDebugMode
                ? const AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
            providerApple: kDebugMode
                ? const AppleDebugProvider()
                : const AppleDeviceCheckProvider(),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[AppCheck] Falhou/ignorado: $e');
        }
      }
    }

    // Stripe: NÃƒO em testes
    if (!kRunFirebaseEmulatorTests) {
      final pk = AppConfig.stripePublishableKey;
      if (pk != null && pk.trim().isNotEmpty) {
        if (!kIsWeb) {
          Stripe.publishableKey = pk;
          await Stripe.instance.applySettings();
        }
      }
    }

    // ✅ Background handler: só Android/iOS (nunca Windows)
    if (_supportsFcm() && !kIsWeb && !kRunFirebaseEmulatorTests) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    // Login anónimo + users/{uid}
    await AuthService.ensureSignedInAnonymously();

    // ✅ Notificações: NÃO em testes (e NotificationService também protege Windows)
    if (!kRunFirebaseEmulatorTests) {
      try {
        await NotificationService.instance.init();
      } catch (e, st) {
        // ignore: avoid_print
        print('Erro ao inicializar notificações: $e\n$st');
      }
    }

    // Seed de serviços: só em emuladores
    if (AppConfig.useFirebaseEmulators) {
      try {
        await ServicoSeed.ensureSeeded();
      } catch (e, st) {
        // ignore: avoid_print
        print('Erro ao fazer seed de servicos: $e\n$st');
      }
    }

    runApp(const ChegaJaApp());

    // Deep links: NÃƒO em testes
    if (!kRunFirebaseEmulatorTests) {
      try {
        await DeepLinkService.instance.init();
      } catch (_) {}
    }
  }, (error, stack) {
    // ignore: avoid_print
    print('? ERRO FATAL (Zone): $error\n$stack');
  });
}



