import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/common/perfil_publico_screen.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

Future<void> _pumpProfile(
  WidgetTester tester, {
  required FakeFirebaseFirestore db,
  String userId = 'prestador1',
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PublicProfileScreen(
        userId: userId,
        role: 'prestador',
        firestore: db,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _scrollProfileDown(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -900));
  await tester.pump();
}

Future<void> _seedPrestador(
  FakeFirebaseFirestore db, {
  Map<String, Object?> overrides = const {},
}) async {
  await db.collection('prestadores').doc('prestador1').set({
    'nome': 'Joao Silva',
    'bio': 'Canalizador com experiencia em reparos urgentes.',
    'city': 'Coimbra',
    'country': 'Portugal',
    'radiusKm': 12,
    'photoUrl': 'https://example.com/avatar.jpg',
    'servicosNomes': ['Canalizacao', 'Instalacao de torneira'],
    'portfolioUrls': [
      'https://example.com/obra-1.jpg',
      'https://example.com/obra-2.jpg',
      'https://example.com/obra-1.jpg',
      '',
    ],
    ...overrides,
  });
}

void main() {
  testWidgets('perfil publico renderiza dados principais e portfolio',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    await _pumpProfile(tester, db: db);

    expect(find.text('Joao Silva'), findsOneWidget);
    expect(find.text('Canalizador com experiencia em reparos urgentes.'),
        findsOneWidget);
    expect(find.text('Atende em Coimbra, Portugal'), findsWidgets);
    expect(find.text('Raio aproximado: ate 12 km'), findsOneWidget);
    await _scrollProfileDown(tester);
    expect(find.text('Canalizacao'), findsOneWidget);
    expect(find.text('Instalacao de torneira'), findsOneWidget);
    expect(find.text('2 imagens'), findsOneWidget);
  });

  testWidgets('perfil sem foto mostra fallback com inicial', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {'photoUrl': ''});

    await _pumpProfile(tester, db: db);

    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('badges leves aparecem apenas com dados reais', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    await _pumpProfile(tester, db: db);

    expect(find.text('Foto adicionada'), findsOneWidget);
    expect(find.text('Area definida'), findsOneWidget);
    expect(find.text('Portfolio adicionado'), findsOneWidget);
    expect(find.text('Perfil ativo'), findsOneWidget);
  });

  testWidgets('perfil incompleto nao exagera sinais de confianca',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'bio': '',
      'city': '',
      'country': '',
      'radiusKm': null,
      'photoUrl': '',
      'servicosNomes': <String>[],
      'portfolioUrls': <String>[],
    });

    await _pumpProfile(tester, db: db);

    expect(find.text('Foto adicionada'), findsNothing);
    expect(find.text('Area definida'), findsNothing);
    expect(find.text('Portfolio adicionado'), findsNothing);
    expect(find.text('Perfil ativo'), findsNothing);
    expect(
      find.text('Este perfil ainda precisa de mais informacao.'),
      findsOneWidget,
    );
  });

  testWidgets('foto do perfil abre em ecra inteiro quando existe',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    await _pumpProfile(tester, db: db);

    await tester.tap(find.byKey(const Key('public_profile_photo_open_button')));
    await tester.pumpAndSettle();

    expect(find.text('Foto de perfil'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('perfil sem portfolio mostra estado vazio', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {'portfolioUrls': <String>[]});

    await _pumpProfile(tester, db: db);
    await _scrollProfileDown(tester);

    expect(find.text('Ainda sem portfolio'), findsOneWidget);
    expect(
      find.text('Quando o prestador adicionar trabalhos, eles aparecem aqui.'),
      findsOneWidget,
    );
  });

  testWidgets('nao mostra badges proibidos', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    await _pumpProfile(tester, db: db);

    expect(find.text('Identidade verificada'), findsNothing);
    expect(find.text('Documento verificado'), findsNothing);
    expect(find.text('Prestador certificado'), findsNothing);
    expect(find.text('Pagamento seguro'), findsNothing);
    expect(find.text('Profissional aprovado oficialmente'), findsNothing);
    expect(find.text('Verificado oficialmente'), findsNothing);
    expect(find.text('Certificado pelo ChegaJa'), findsNothing);
    expect(find.text('Garantido pelo ChegaJa'), findsNothing);
    expect(find.text('Prestador disponivel'), findsNothing);
    expect(find.text('Servicos concluidos'), findsNothing);
  });

  testWidgets('imagem quebrada no portfolio nao quebra a tela', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'portfolioUrls': ['https://example.invalid/broken.jpg'],
    });

    await _pumpProfile(tester, db: db);
    await _scrollProfileDown(tester);

    expect(find.text('1 imagem'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usa contraste do tema em dark mode', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'photoUrl': '',
      'portfolioUrls': <String>[],
    });

    await _pumpProfile(tester, db: db, theme: AppTheme.darkTheme);
    await _scrollProfileDown(tester);

    final emptyPortfolio =
        tester.widget<Text>(find.text('Ainda sem portfolio'));

    expect(
      emptyPortfolio.style?.color,
      AppTheme.darkTheme.colorScheme.onSurface,
    );
  });
}
