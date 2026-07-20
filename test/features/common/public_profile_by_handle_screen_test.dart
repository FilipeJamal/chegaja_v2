import 'dart:async';

import 'package:chegaja_v2/core/handles/public_handle_resolver.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/common/public_profile_by_handle_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('loading renderiza enquanto resolve handle', (tester) async {
    final completer = Completer<PublicHandleResolveResult>();

    await _pump(
      tester,
      child: PublicProfileByHandleScreen(
        rawHandle: 'maria_bolos',
        resolveHandle: (_) => completer.future,
      ),
    );
    await tester.pump();

    expect(find.text('A abrir perfil...'), findsOneWidget);

    completer.complete(const PublicHandleResolveResult.notFound());
    await tester.pumpAndSettle();
  });

  testWidgets('sucesso renderiza PublicProfileScreen resolvido por uid',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('provider_public').doc('prestador1').set({
      'nome': 'Maria Bolos',
      'handle': 'maria_bolos',
      'bio': 'Bolos artesanais.',
      'servicosNomes': ['Bolos personalizados'],
    });

    await _pump(
      tester,
      child: PublicProfileByHandleScreen(
        rawHandle: 'maria_bolos',
        firestore: db,
        resolveHandle: (_) async => const PublicHandleResolveResult.resolved(
          uid: 'prestador1',
          handle: 'maria_bolos',
          handleDisplay: '@maria_bolos',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maria Bolos'), findsOneWidget);
    expect(find.text('@maria_bolos'), findsOneWidget);
    expect(find.text('Bolos artesanais.'), findsOneWidget);
  });

  testWidgets('notFound renderiza 404 amigavel', (tester) async {
    await _pump(
      tester,
      child: PublicProfileByHandleScreen(
        rawHandle: 'nao_existe',
        resolveHandle: (_) async => const PublicHandleResolveResult.notFound(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perfil nao encontrado'), findsOneWidget);
    expect(
      find.text('Este link pode estar incorreto ou ja nao estar disponivel.'),
      findsOneWidget,
    );
  });

  testWidgets('inactive renderiza perfil indisponivel sem detalhes internos',
      (tester) async {
    await _pump(
      tester,
      child: PublicProfileByHandleScreen(
        rawHandle: 'bloqueado',
        resolveHandle: (_) async => const PublicHandleResolveResult.inactive(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Este perfil nao esta disponivel'), findsOneWidget);
    expect(find.textContaining('uid'), findsNothing);
  });

  testWidgets('erro renderiza mensagem segura', (tester) async {
    await _pump(
      tester,
      child: PublicProfileByHandleScreen(
        rawHandle: 'maria_bolos',
        resolveHandle: (_) async => const PublicHandleResolveResult.error(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nao foi possivel abrir este perfil'), findsOneWidget);
  });

  testWidgets('dark mode renderiza sem erro', (tester) async {
    await _pump(
      tester,
      theme: AppTheme.darkTheme,
      child: PublicProfileByHandleScreen(
        rawHandle: 'nao_existe',
        resolveHandle: (_) async => const PublicHandleResolveResult.notFound(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Perfil nao encontrado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
