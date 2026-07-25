import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/main.dart';

void main() {
  group('preview local U1', () {
    test('pode ser usado em builds nao distribuiveis', () {
      expect(
        shouldApplyLocalU1Preview(
          isReleaseMode: false,
          previewRequested: true,
        ),
        isTrue,
      );
    });

    test('nunca pode ser forçado numa build de release', () {
      expect(
        shouldApplyLocalU1Preview(
          isReleaseMode: true,
          previewRequested: true,
        ),
        isFalse,
      );
      expect(
        shouldApplyLocalU1Preview(
          isReleaseMode: false,
          previewRequested: false,
        ),
        isFalse,
      );
    });
  });

  group('Firebase Messaging em segundo plano', () {
    test('fica ativo apenas em mobile de producao', () {
      expect(
        shouldConfigureBackgroundMessaging(
          supportsFcm: true,
          isWeb: false,
          emulatorTests: false,
          fastDevMode: false,
          useFirebaseEmulators: false,
        ),
        isTrue,
      );
    });

    test('fica desativado no modo rapido e nos emuladores', () {
      expect(
        shouldConfigureBackgroundMessaging(
          supportsFcm: true,
          isWeb: false,
          emulatorTests: false,
          fastDevMode: true,
          useFirebaseEmulators: false,
        ),
        isFalse,
      );
      expect(
        shouldConfigureBackgroundMessaging(
          supportsFcm: true,
          isWeb: false,
          emulatorTests: false,
          fastDevMode: false,
          useFirebaseEmulators: true,
        ),
        isFalse,
      );
      expect(
        shouldConfigureBackgroundMessaging(
          supportsFcm: true,
          isWeb: false,
          emulatorTests: true,
          fastDevMode: false,
          useFirebaseEmulators: false,
        ),
        isFalse,
      );
    });

    test('fica desativado na web e em plataformas sem FCM', () {
      expect(
        shouldConfigureBackgroundMessaging(
          supportsFcm: true,
          isWeb: true,
          emulatorTests: false,
          fastDevMode: false,
          useFirebaseEmulators: false,
        ),
        isFalse,
      );
      expect(
        shouldConfigureBackgroundMessaging(
          supportsFcm: false,
          isWeb: false,
          emulatorTests: false,
          fastDevMode: false,
          useFirebaseEmulators: false,
        ),
        isFalse,
      );
    });
  });

  test('App Check concluido permite continuar o arranque', () async {
    final activated = await activateAppCheckWithTimeout(
      () async {},
      timeout: const Duration(milliseconds: 50),
    );

    expect(activated, isTrue);
  });

  test('App Check indisponivel nao bloqueia indefinidamente o arranque',
      () async {
    final pending = Completer<void>();
    final activated = await activateAppCheckWithTimeout(
      () => pending.future,
      timeout: const Duration(milliseconds: 10),
    );

    expect(activated, isFalse);
  });

  test('erro do fornecedor App Check nao impede o arranque', () async {
    final activated = await activateAppCheckWithTimeout(
      () => Future<void>.error(StateError('provider unavailable')),
      timeout: const Duration(milliseconds: 50),
    );

    expect(activated, isFalse);
  });
}
