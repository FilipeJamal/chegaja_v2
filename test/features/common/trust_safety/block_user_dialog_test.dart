import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/common/trust_safety/block_user_dialog.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    required BlockUserCallback onConfirm,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: BlockUserDialog(
            blockedUid: 'provider1',
            userLabel: 'Joao Silva',
            onConfirm: onConfirm,
          ),
        ),
      ),
    );
  }

  testWidgets('mostra confirmacao e cancelar nao chama callback',
      (tester) async {
    var calls = 0;
    await pumpDialog(tester, onConfirm: (_) async => calls++);

    expect(find.text('Bloquear utilizador?'), findsOneWidget);
    expect(find.textContaining('Joao Silva'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('confirmar chama callback', (tester) async {
    String? blockedUid;
    await pumpDialog(tester, onConfirm: (uid) async => blockedUid = uid);

    await tester.tap(find.text('Bloquear'));
    await tester.pumpAndSettle();

    expect(blockedUid, 'provider1');
  });

  testWidgets('loading bloqueia duplo clique', (tester) async {
    var calls = 0;
    final completer = Completer<void>();

    await pumpDialog(
      tester,
      onConfirm: (_) async {
        calls++;
        await completer.future;
      },
    );

    await tester.tap(find.text('Bloquear'));
    await tester.pump();
    await tester.tap(find.text('Bloquear'));
    await tester.pump();

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('erro mostra feedback', (tester) async {
    await pumpDialog(
      tester,
      onConfirm: (_) async => throw Exception('falhou'),
    );

    await tester.tap(find.text('Bloquear'));
    await tester.pump();
    await tester.pump();

    expect(
        find.text('Nao conseguimos bloquear este utilizador.'), findsOneWidget);
  });

  testWidgets('renderiza em dark mode', (tester) async {
    await pumpDialog(
      tester,
      theme: ThemeData.dark(),
      onConfirm: (_) async {},
    );

    expect(find.text('Bloquear utilizador?'), findsOneWidget);
  });
}
