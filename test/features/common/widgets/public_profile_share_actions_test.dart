import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/common/widgets/public_profile_share_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('mostra acoes de partilha para handle valido', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PublicProfileShareActions(
          handle: 'maria_bolos',
          displayName: 'Maria Bolos',
          onCopyLink: (_) async {},
          onOpenWhatsApp: (_) async => true,
          onOpenFacebook: (_) async => true,
        ),
      ),
    );

    expect(find.text('Partilhar perfil'), findsOneWidget);
    expect(find.text('Copiar link'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(
      find.text(
          'Para Instagram, copia o link e cola na bio, story ou mensagem.'),
      findsOneWidget,
    );
  });

  testWidgets('copiar link chama callback com URL publica', (tester) async {
    final copied = <String>[];

    await tester.pumpWidget(
      _wrap(
        PublicProfileShareActions(
          handle: '@Maria_Bolos',
          displayName: 'Maria Bolos',
          onCopyLink: (url) async => copied.add(url),
          onOpenWhatsApp: (_) async => true,
          onOpenFacebook: (_) async => true,
        ),
      ),
    );

    await tester.tap(find.text('Copiar link'));
    await tester.pumpAndSettle();

    expect(copied, ['https://chegaja-ac88d.web.app/p/maria_bolos']);
    expect(find.text('Link copiado.'), findsOneWidget);
  });

  testWidgets('WhatsApp e Facebook chamam callbacks com URIs seguras',
      (tester) async {
    final opened = <Uri>[];

    await tester.pumpWidget(
      _wrap(
        PublicProfileShareActions(
          handle: 'maria_bolos',
          displayName: 'Maria Bolos',
          onCopyLink: (_) async {},
          onOpenWhatsApp: (uri) async {
            opened.add(uri);
            return true;
          },
          onOpenFacebook: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Facebook'));
    await tester.pumpAndSettle();

    expect(opened.map((uri) => uri.host), ['wa.me', 'www.facebook.com']);
  });

  testWidgets('handle ausente ou invalido nao renderiza acoes', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PublicProfileShareActions(
          handle: '',
          displayName: 'Maria Bolos',
          onCopyLink: (_) async {},
          onOpenWhatsApp: (_) async => true,
          onOpenFacebook: (_) async => true,
        ),
      ),
    );

    expect(find.text('Partilhar perfil'), findsNothing);
    expect(find.text('Copiar link'), findsNothing);
  });

  testWidgets('dark mode renderiza sem erro', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PublicProfileShareActions(
          handle: 'maria_bolos',
          displayName: 'Maria Bolos',
          onCopyLink: (_) async {},
          onOpenWhatsApp: (_) async => true,
          onOpenFacebook: (_) async => true,
        ),
        theme: AppTheme.darkTheme,
      ),
    );

    expect(find.text('Partilhar perfil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
