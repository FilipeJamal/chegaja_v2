import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('U1 ships with all automatic telemetry collectors fail-closed', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();
    final androidManifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final iosPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final macosPlist = File('macos/Runner/Info.plist').readAsStringSync();

    expect(pubspec, isNot(contains('firebase_analytics:')));
    expect(pubspec, isNot(contains('firebase_crashlytics:')));
    expect(pubspec, isNot(contains('firebase_performance:')));
    expect(mainSource, isNot(contains('FirebaseCrashlytics.instance')));
    for (final key in [
      'firebase_analytics_collection_enabled',
      'google_analytics_adid_collection_enabled',
      'firebase_crashlytics_collection_enabled',
      'firebase_performance_collection_enabled',
    ]) {
      expect(
        RegExp(
          'android:name="$key"\\s+android:value="false"',
          multiLine: true,
        ).hasMatch(androidManifest),
        isTrue,
        reason: '$key must stay disabled in the merged Android source.',
      );
    }
    expect(
      androidManifest,
      contains('com.google.android.gms.permission.AD_ID'),
      reason: 'The manifest must explicitly remove the advertising ID.',
    );
    expect(
      androidManifest,
      contains('tools:node="remove"'),
      reason: 'The advertising ID removal must survive manifest merging.',
    );
    for (final plist in [iosPlist, macosPlist]) {
      for (final key in [
        'FIREBASE_ANALYTICS_COLLECTION_ENABLED',
        'GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED',
        'FirebaseCrashlyticsCollectionEnabled',
        'firebase_performance_collection_enabled',
      ]) {
        expect(
          RegExp(
            '<key>$key</key>\\s*<false/>',
            multiLine: true,
          ).hasMatch(plist),
          isTrue,
          reason: '$key must stay disabled in Apple configuration.',
        );
      }
    }
  });
}
