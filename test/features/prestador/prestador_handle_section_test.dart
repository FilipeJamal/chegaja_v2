import 'dart:async';

import 'package:chegaja_v2/core/models/public_handle.dart';
import 'package:chegaja_v2/core/services/handle_service.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/prestador/widgets/prestador_handle_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    ),
  );
}

PublicHandle _handle(String value) {
  return PublicHandle(
    handle: value,
    uid: 'prestador1',
    role: 'prestador',
    status: PublicHandleStatus.active,
    handleDisplay: '@$value',
  );
}

void main() {
  testWidgets('mostra handle atual, prefixo e link publico real',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          currentHandle: 'maria_bolos',
          currentHandleDisplay: '@maria_bolos',
          onCheckAvailability: (_) async => const HandleAvailability(
            normalizedHandle: 'maria_bolos',
            available: true,
            reason: '',
            message: '',
          ),
          onReserveHandle: (_) async => _handle('maria_bolos'),
          onCopyPublicLink: (_) async {},
        ),
      ),
    );

    final input = tester.widget<TextField>(
      find.byKey(const Key('prestador_handle_input')),
    );

    expect(input.decoration?.prefixText, '@');
    expect(find.text('Pagina publica'), findsOneWidget);
    expect(find.text('O teu @handle atual'), findsOneWidget);
    expect(find.text('@maria_bolos'), findsOneWidget);
    expect(find.text('chegaja-ac88d.web.app/p/maria_bolos'), findsOneWidget);
    expect(find.text('Este e o teu link publico.'), findsOneWidget);
    expect(find.text('Link publico em preparacao'), findsNothing);
    expect(find.text('Copiar link'), findsOneWidget);
  });

  testWidgets('valida handle curto, caracteres invalidos e reservado',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          onCheckAvailability: (_) async => throw StateError('unexpected'),
          onReserveHandle: (_) async => throw StateError('unexpected'),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_handle_input')),
      'ab',
    );
    await tester.pump();
    expect(find.text('O @handle deve ter pelo menos 3 caracteres.'),
        findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('prestador_handle_input')),
      'maria bolos',
    );
    await tester.pump();
    expect(
      find.text('Usa apenas letras, numeros, ponto, underline ou hifen.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('prestador_handle_input')),
      'admin',
    );
    await tester.pump();
    expect(
        find.text('Este nome de perfil nao pode ser usado.'), findsOneWidget);
  });

  testWidgets('verificar disponibilidade chama callback e mostra resultado',
      (tester) async {
    final checked = <String>[];

    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          onCheckAvailability: (raw) async {
            checked.add(raw);
            return const HandleAvailability(
              normalizedHandle: 'maria_bolos',
              available: true,
              reason: '',
              message: '',
            );
          },
          onReserveHandle: (_) async => _handle('maria_bolos'),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_handle_input')),
      '@Maria_Bolos',
    );
    await tester.pump();
    await tester.tap(find.text('Verificar disponibilidade'));
    await tester.pumpAndSettle();

    expect(checked, ['@Maria_Bolos']);
    expect(find.text('@maria_bolos esta disponivel.'), findsOneWidget);
  });

  testWidgets('handle indisponivel mostra mensagem segura', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          onCheckAvailability: (_) async => const HandleAvailability(
            normalizedHandle: 'maria_bolos',
            available: false,
            reason: 'taken',
            message: 'Este @handle nao esta disponivel. Escolhe outro.',
          ),
          onReserveHandle: (_) async => _handle('maria_bolos'),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_handle_input')),
      'maria_bolos',
    );
    await tester.pump();
    await tester.tap(find.text('Verificar disponibilidade'));
    await tester.pumpAndSettle();

    expect(
      find.text('Este @handle nao esta disponivel. Escolhe outro.'),
      findsOneWidget,
    );
  });

  testWidgets('guardar chama callback, atualiza handle e mostra snackbar',
      (tester) async {
    final reserved = <String>[];

    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          onCheckAvailability: (_) async => const HandleAvailability(
            normalizedHandle: 'maria_bolos',
            available: true,
            reason: '',
            message: '',
          ),
          onReserveHandle: (raw) async {
            reserved.add(raw);
            return _handle('maria_bolos');
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_handle_input')),
      'maria_bolos',
    );
    await tester.pump();
    await tester.tap(find.text('Guardar @handle'));
    await tester.pumpAndSettle();

    expect(reserved, ['maria_bolos']);
    expect(find.text('@handle guardado com sucesso.'), findsWidgets);
    expect(find.text('@maria_bolos'), findsWidgets);
  });

  testWidgets('botao copiar link chama callback quando ha handle atual',
      (tester) async {
    final copied = <String>[];

    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          currentHandle: 'maria_bolos',
          currentHandleDisplay: '@maria_bolos',
          onCheckAvailability: (_) async => const HandleAvailability(
            normalizedHandle: 'maria_bolos',
            available: true,
            reason: '',
            message: '',
          ),
          onReserveHandle: (_) async => _handle('maria_bolos'),
          onCopyPublicLink: (url) async => copied.add(url),
        ),
      ),
    );

    await tester.tap(find.text('Copiar link'));
    await tester.pumpAndSettle();

    expect(copied, ['https://chegaja-ac88d.web.app/p/maria_bolos']);
  });

  testWidgets('sem handle atual nao mostra botao copiar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          onCheckAvailability: (_) async => const HandleAvailability(
            normalizedHandle: 'maria_bolos',
            available: true,
            reason: '',
            message: '',
          ),
          onReserveHandle: (_) async => _handle('maria_bolos'),
        ),
      ),
    );

    expect(find.text('Copiar link'), findsNothing);
  });

  testWidgets('loading bloqueia duplo clique durante reserva', (tester) async {
    final completer = Completer<PublicHandle>();
    var reserveCount = 0;

    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          onCheckAvailability: (_) async => const HandleAvailability(
            normalizedHandle: 'maria_bolos',
            available: true,
            reason: '',
            message: '',
          ),
          onReserveHandle: (_) {
            reserveCount++;
            return completer.future;
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_handle_input')),
      'maria_bolos',
    );
    await tester.pump();
    await tester.tap(find.text('Guardar @handle'));
    await tester.pump();
    await tester.tap(find.text('A guardar...'), warnIfMissed: false);
    await tester.pump();

    expect(reserveCount, 1);

    completer.complete(_handle('maria_bolos'));
    await tester.pumpAndSettle();
  });

  testWidgets('erro de reserva mostra feedback seguro', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          onCheckAvailability: (_) async => const HandleAvailability(
            normalizedHandle: 'maria_bolos',
            available: true,
            reason: '',
            message: '',
          ),
          onReserveHandle: (_) async => throw Exception('backend details'),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('prestador_handle_input')),
      'maria_bolos',
    );
    await tester.pump();
    await tester.tap(find.text('Guardar @handle'));
    await tester.pumpAndSettle();

    expect(
      find.text('Nao conseguimos guardar este @handle agora.'),
      findsWidgets,
    );
    expect(find.textContaining('backend details'), findsNothing);
  });

  testWidgets('dark mode renderiza sem erro', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PrestadorHandleSection(
          currentHandle: 'maria_bolos',
          onCheckAvailability: (_) async => const HandleAvailability(
            normalizedHandle: 'maria_bolos',
            available: true,
            reason: '',
            message: '',
          ),
          onReserveHandle: (_) async => _handle('maria_bolos'),
        ),
        theme: AppTheme.darkTheme,
      ),
    );

    expect(find.text('Pagina publica'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
