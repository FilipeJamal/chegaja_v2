import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/locale_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/remote_config_service.dart';
import 'core/services/servico_seed.dart';
import 'core/services/theme_mode_service.dart';
import 'core/services/user_country_service.dart';
import 'firebase_options.dart';

const bool kRunFirebaseEmulatorTests =
    bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

const bool kFastDevMode =
    bool.fromEnvironment('FAST_DEV_MODE', defaultValue: false);

const bool kForceWebSemantics =
    bool.fromEnvironment('FORCE_WEB_SEMANTICS', defaultValue: false);

SemanticsHandle? _webSemanticsHandle;

bool _shouldForceWebSemantics() {
  if (kForceWebSemantics) return true;
  final raw = dotenv.env['FORCE_WEB_SEMANTICS'];
  if (raw != null && raw.trim().isNotEmpty) {
    return raw.trim().toLowerCase() == 'true';
  }
  return kDebugMode;
}

Duration _authStartupTimeout() {
  if (kIsWeb) return const Duration(seconds: 12);
  return const Duration(seconds: 8);
}

bool _supportsFcm() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

void _configureBackgroundMessaging() {
  if (_supportsFcm() && !kIsWeb && !kRunFirebaseEmulatorTests) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
}

void _scheduleDeferredStartupTasks() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_runDeferredStartupTasks());
  });
}

Future<void> _runDeferredStartupTasks() async {
  final bootstrap = Stopwatch()..start();

  if (!kRunFirebaseEmulatorTests && !kFastDevMode) {
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
        print('[AppCheck] Ignorado: $e');
      }
    }
  }

  if (!kRunFirebaseEmulatorTests && !kFastDevMode) {
    final pk = AppConfig.stripePublishableKey;
    if (pk != null && pk.trim().isNotEmpty && !kIsWeb) {
      Stripe.publishableKey = pk;
      await Stripe.instance.applySettings();
    }
  }

  _configureBackgroundMessaging();

  try {
    await AuthService.ensureSignedInAnonymously()
        .timeout(_authStartupTimeout());
  } catch (e, st) {
    // ignore: avoid_print
    print('[Auth] ensureSignedInAnonymously falhou/timeout: $e\n$st');
  }

  if (!kRunFirebaseEmulatorTests && !kFastDevMode) {
    try {
      unawaited(
        NotificationService.instance
            .init()
            .timeout(const Duration(seconds: 10))
            .catchError((e, st) {
          // ignore: avoid_print
          print('Erro ao inicializar notificacoes: $e\n$st');
        }),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('Erro ao inicializar notificacoes: $e\n$st');
    }
  }

  try {
    await Future.wait<void>([
      LocaleService.instance.load(),
      ThemeModeService.instance.load(),
    ]);
  } catch (_) {}

  unawaited(
    UserCountryService.instance.init().catchError((e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[UserCountryService] init error: $e\n$st');
      }
    }),
  );

  if (AppConfig.useFirebaseEmulators) {
    try {
      unawaited(
        ServicoSeed.ensureSeeded().catchError((e, st) {
          // ignore: avoid_print
          print('Erro ao fazer seed de servicos: $e\n$st');
        }),
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('Erro ao fazer seed de servicos: $e\n$st');
    }
  }

  if (!kRunFirebaseEmulatorTests && !kFastDevMode) {
    try {
      unawaited(RemoteConfigService.instance.init());
    } catch (e) {
      // ignore: avoid_print
      print('[Observability] Init error: $e');
    }
  }

  if (!kRunFirebaseEmulatorTests && !kFastDevMode) {
    try {
      await DeepLinkService.instance.init();
    } catch (_) {}
  }

  if (kDebugMode) {
    // ignore: avoid_print
    print(
      '[Startup] Deferred bootstrap finished in ${bootstrap.elapsedMilliseconds}ms',
    );
  }
}

Future<void> main() async {
  const prodConfig = AppConfig(
    flavor: Flavor.prod,
    appName: 'ChegaJá',
    apiBaseUrl: 'https://api.chegaja.com',
    child: ChegaJaApp(),
  );
  await mainCommon(prodConfig);
}

Future<void> mainCommon(AppConfig config) async {
  await (runZonedGuarded(() async {
        WidgetsFlutterBinding.ensureInitialized();

        try {
          await dotenv.load(fileName: '.env');
        } catch (_) {}

        if (kIsWeb && _shouldForceWebSemantics()) {
          _webSemanticsHandle ??= WidgetsBinding.instance.ensureSemantics();
          if (kDebugMode) {
            // ignore: avoid_print
            print('[Web] Semantics forced ON (FORCE_WEB_SEMANTICS=true)');
          }
        }

        AppConfig.debugPrintConfig();

        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        if (!kIsWeb && !kRunFirebaseEmulatorTests) {
          FlutterError.onError =
              FirebaseCrashlytics.instance.recordFlutterFatalError;

          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };
        }

        if (AppConfig.useFirebaseEmulators) {
          final host = AppConfig.emulatorHost;
          try {
            await FirebaseAuth.instance.useAuthEmulator(host, 9099);
            FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
            FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion)
                .useFunctionsEmulator(host, 5001);
            await FirebaseStorage.instance.useStorageEmulator(host, 9199);

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

        if (kIsWeb) {
          FirebaseFirestore.instance.settings =
              const Settings(persistenceEnabled: false);
        }

        runApp(config);
        _scheduleDeferredStartupTasks();
      }, (error, stack) {
        final text = '$error';
        if (kRunFirebaseEmulatorTests &&
            text.contains('[cloud_firestore/permission-denied]') &&
            text.contains("false for 'list' @ L401")) {
          return;
        }
        // ignore: avoid_print
        print('[App] ERRO FATAL (Zone): $error\n$stack');
      }) ??
      Future<void>.value());
}
