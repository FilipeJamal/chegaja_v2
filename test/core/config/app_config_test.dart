import 'package:chegaja_v2/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.resolveUseFirebaseEmulators', () {
    test('release ignora USE_FIREBASE_EMULATORS=true', () {
      expect(
        AppConfig.resolveUseFirebaseEmulators(
          isReleaseMode: true,
          isDebugMode: false,
          configuredValue: 'true',
        ),
        isFalse,
      );
    });

    test('debug respeita configuracao explicita', () {
      expect(
        AppConfig.resolveUseFirebaseEmulators(
          isReleaseMode: false,
          isDebugMode: true,
          configuredValue: 'false',
        ),
        isFalse,
      );
      expect(
        AppConfig.resolveUseFirebaseEmulators(
          isReleaseMode: false,
          isDebugMode: false,
          configuredValue: 'true',
        ),
        isTrue,
      );
    });
  });
}
