import 'package:flutter/foundation.dart';

class PlatformCaps {
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  static bool get isDesktop => isWindows || isLinux || isMacOS;

  /// Firebase Messaging: Web + Android + iOS
  static bool get supportsMessaging => kIsWeb || isAndroid || isIOS;

  /// Cloud Functions: Web + Android + iOS (+ macOS, se tu quiseres usar)
  /// (Windows/Linux costumam dar MissingPluginException)
  static bool get supportsCloudFunctions => kIsWeb || isAndroid || isIOS || isMacOS;

  /// Crashlytics: só Android + iOS (não Web / não Windows / não Linux)
  static bool get supportsCrashlytics => isAndroid || isIOS;

  /// App Check: Web + Android + iOS (desktop geralmente não)
  static bool get supportsAppCheck => kIsWeb || isAndroid || isIOS;

  /// Stripe: Android + iOS (não Web / não Windows / não Linux)
  static bool get supportsStripe => isAndroid || isIOS;

  /// Detecta modo testes
  static const bool isFlutterTest =
      bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  static const bool runEmulatorTests =
      bool.fromEnvironment('RUN_FIREBASE_EMULATOR_TESTS', defaultValue: false);

  static bool get isTestMode => isFlutterTest || runEmulatorTests;
}
