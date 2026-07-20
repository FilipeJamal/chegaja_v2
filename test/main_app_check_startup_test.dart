import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/main.dart';

void main() {
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
