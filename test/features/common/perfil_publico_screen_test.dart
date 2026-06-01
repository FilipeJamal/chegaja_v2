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
  String role = 'prestador',
  ThemeData? theme,
  Future<void> Function(String url)? onCopyProfileLink,
  Future<bool> Function(Uri uri)? onOpenWhatsApp,
  Future<bool> Function(Uri uri)? onOpenFacebook,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PublicProfileScreen(
        userId: userId,
        role: role,
        firestore: db,
        onCopyProfileLink: onCopyProfileLink,
        onOpenProfileWhatsApp: onOpenWhatsApp,
        onOpenProfileFacebook: onOpenFacebook,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _scrollProfileDown(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -900));
  await tester.pump();
}

Future<void> _scrollUntilTextVisible(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    120,
    scrollable: find.byType(Scrollable).first,
  );
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
    'handle': 'joao_canalizador',
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
    expect(find.text('@joao_canalizador'), findsOneWidget);
    expect(find.text('Canalizador com experiencia em reparos urgentes.'),
        findsOneWidget);
    expect(find.text('Atende em Coimbra, Portugal'), findsWidgets);
    await _scrollUntilTextVisible(tester, 'Raio aproximado: ate 12 km');
    expect(find.text('Raio aproximado: ate 12 km'), findsOneWidget);
    await _scrollUntilTextVisible(tester, 'Canalizacao');
    expect(find.text('Canalizacao'), findsOneWidget);
    expect(find.text('Instalacao de torneira'), findsOneWidget);
    await _scrollUntilTextVisible(tester, '2 imagens');
    expect(find.text('2 imagens'), findsOneWidget);
  });

  testWidgets('perfil publico filtra servicos proibidos persistidos',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'servicos': ['custom_puta', 'custom_vadia', 'plumbing'],
      'servicosNomes': ['puta', 'prostituta', 'vadia', 'Canalizacao'],
      'customServiceNames': ['p.u.t.a'],
      'customServiceSearchTerms': ['prostituta'],
      'customServices': [
        {
          'id': 'custom_puta',
          'title': 'puta',
          'trustSafetyDecision': 'allow',
        },
      ],
    });

    await _pumpProfile(tester, db: db);

    await _scrollUntilTextVisible(tester, 'Canalizacao');
    expect(find.text('Canalizacao'), findsOneWidget);
    expect(find.text('puta'), findsNothing);
    expect(find.text('prostituta'), findsNothing);
    expect(find.text('vadia'), findsNothing);
  });

  testWidgets('nao mostra @handle quando ausente', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {'handle': ''});

    await _pumpProfile(tester, db: db);

    expect(find.text('@joao_canalizador'), findsNothing);
  });

  testWidgets('prestador com handle mostra acoes de partilha', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    await _pumpProfile(tester, db: db);
    await _scrollProfileDown(tester);

    expect(find.text('Partilhar perfil'), findsOneWidget);
    expect(find.text('Copiar link'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
  });

  testWidgets('copiar link do perfil publico chama callback', (tester) async {
    final db = FakeFirebaseFirestore();
    final copied = <String>[];
    await _seedPrestador(db);

    await _pumpProfile(
      tester,
      db: db,
      onCopyProfileLink: (url) async => copied.add(url),
    );
    await _scrollUntilTextVisible(tester, 'Copiar link');

    await tester.tap(find.text('Copiar link'));
    await tester.pumpAndSettle();

    expect(copied, ['https://chegaja-ac88d.web.app/p/joao_canalizador']);
    expect(find.text('Link copiado.'), findsOneWidget);
  });

  testWidgets('prestador sem handle nao mostra acoes de partilha',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {'handle': ''});

    await _pumpProfile(tester, db: db);

    expect(find.text('Partilhar perfil'), findsNothing);
    expect(find.text('Copiar link'), findsNothing);
  });

  testWidgets('cliente nao mostra acoes de partilha de prestador',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('cliente1').set({
      'nome': 'Maria Cliente',
      'handle': 'maria_cliente',
    });

    await _pumpProfile(tester, db: db, userId: 'cliente1', role: 'cliente');

    expect(find.text('Partilhar perfil'), findsNothing);
  });

  testWidgets('perfil publico nao expoe telefone por defeito', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'phoneE164': '+351900000000',
      'phoneNumber': '900000000',
      'phone': '900 000 000',
      'phoneRaw': '900000000',
    });

    await _pumpProfile(tester, db: db);
    await _scrollProfileDown(tester);

    expect(find.text('Contacto'), findsNothing);
    expect(find.textContaining('900'), findsNothing);
  });

  testWidgets('perfil publico mostra categorias com aprovacao segura',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'approvedSensitiveCategoryIds': ['electricity'],
      'approvedSensitiveCategoryNames': ['Eletricidade'],
    });

    await _pumpProfile(tester, db: db);
    await _scrollUntilTextVisible(tester, 'Categorias com aprovacao');

    expect(find.text('Categorias com aprovacao'), findsOneWidget);
    expect(find.text('Aprovacao ativa'), findsOneWidget);
    expect(find.text('Eletricidade'), findsOneWidget);
    expect(
      find.text(
        'Estas categorias foram analisadas pelo ChegaJa com base nas informacoes enviadas pelo prestador.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('certificado'), findsNothing);
    expect(find.textContaining('verificado'), findsNothing);
    expect(find.textContaining('garantido'), findsNothing);
    expect(find.textContaining('pagamento seguro'), findsNothing);
  });

  testWidgets('perfil publico sem aprovacao nao mostra seccao de categorias',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    await _pumpProfile(tester, db: db);
    await _scrollProfileDown(tester);

    expect(find.text('Categorias com aprovacao'), findsNothing);
    expect(find.text('Aprovacao ativa'), findsNothing);
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

  testWidgets('prestador com rating valido mostra reputacao media',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'ratingAvg': 4.833,
      'ratingCount': 12,
    });

    await _pumpProfile(tester, db: db);

    expect(find.text('Avaliacao media'), findsOneWidget);
    expect(find.text('4,8 de 5'), findsOneWidget);
    expect(find.text('Baseado em 12 avaliacoes'), findsOneWidget);
  });

  testWidgets('ratingCount 1 usa singular avaliacao', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'ratingAvg': 5.0,
      'ratingCount': 1,
    });

    await _pumpProfile(tester, db: db);

    expect(find.text('5,0 de 5'), findsOneWidget);
    expect(find.text('Baseado em 1 avaliacao'), findsOneWidget);
  });

  testWidgets('prestador sem rating mostra estado neutro', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db);

    await _pumpProfile(tester, db: db);

    expect(find.text('Ainda sem avaliacoes publicas'), findsOneWidget);
    expect(
      find.text(
        'Quando clientes concluirem servicos e avaliarem, a media aparecera aqui.',
      ),
      findsOneWidget,
    );
    expect(find.text('Avaliacao media'), findsNothing);
  });

  testWidgets('ratingCount zero mostra estado neutro', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'ratingAvg': 4.7,
      'ratingCount': 0,
    });

    await _pumpProfile(tester, db: db);

    expect(find.text('Ainda sem avaliacoes publicas'), findsOneWidget);
    expect(find.text('4,7 de 5'), findsNothing);
  });

  testWidgets('ratingAvg ausente mostra estado neutro', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {'ratingCount': 3});

    await _pumpProfile(tester, db: db);

    expect(find.text('Ainda sem avaliacoes publicas'), findsOneWidget);
    expect(find.text('Avaliacao media'), findsNothing);
  });

  testWidgets('ratingAvg invalido nao mostra media', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'ratingAvg': 5.8,
      'ratingCount': 7,
    });

    await _pumpProfile(tester, db: db);

    expect(find.text('Ainda sem avaliacoes publicas'), findsOneWidget);
    expect(find.text('5,8 de 5'), findsNothing);
  });

  testWidgets('ratingAvg abaixo de 1 nao mostra media', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'ratingAvg': 0.8,
      'ratingCount': 7,
    });

    await _pumpProfile(tester, db: db);

    expect(find.text('Ainda sem avaliacoes publicas'), findsOneWidget);
    expect(find.text('0,8 de 5'), findsNothing);
  });

  testWidgets('perfil de cliente nao mostra reputacao de prestador',
      (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('cliente1').set({
      'nome': 'Maria Cliente',
      'ratingAvg': 4.9,
      'ratingCount': 8,
    });

    await _pumpProfile(tester, db: db, userId: 'cliente1', role: 'cliente');

    expect(find.text('Maria Cliente'), findsOneWidget);
    expect(find.text('Avaliacao media'), findsNothing);
    expect(find.text('Ainda sem avaliacoes publicas'), findsNothing);
  });

  testWidgets('reputacao nao mostra textos proibidos', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'ratingAvg': 4.8,
      'ratingCount': 12,
    });

    await _pumpProfile(tester, db: db);

    expect(find.text('Prestador verificado'), findsNothing);
    expect(find.text('Prestador certificado'), findsNothing);
    expect(find.text('Garantido pelo ChegaJa'), findsNothing);
    expect(find.text('Pagamento seguro'), findsNothing);
    expect(find.text('Identidade confirmada'), findsNothing);
    expect(find.text('Verificado oficialmente'), findsNothing);
    expect(find.text('Servicos concluidos'), findsNothing);
    expect(find.text('Prestador disponivel'), findsNothing);
  });

  testWidgets('reputacao renderiza em dark mode', (tester) async {
    final db = FakeFirebaseFirestore();
    await _seedPrestador(db, overrides: {
      'ratingAvg': 4.25,
      'ratingCount': 2,
    });

    await _pumpProfile(tester, db: db, theme: AppTheme.darkTheme);

    expect(find.text('4,3 de 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
