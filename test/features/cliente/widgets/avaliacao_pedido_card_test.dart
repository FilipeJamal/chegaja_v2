import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/features/cliente/widgets/avaliacao_pedido_card.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';

Future<void> _pumpCard(
  WidgetTester tester, {
  required FakeFirebaseFirestore db,
  ThemeData? theme,
  Stream<DocumentSnapshot<Map<String, dynamic>>>? avaliacaoStream,
  Future<void> Function({
    required String pedidoId,
    required String clienteId,
    required String prestadorId,
    required int estrelas,
    String? comentario,
  })? onSubmit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: AvaliacaoPedidoCard(
            pedidoId: 'pedido_1',
            prestadorId: 'prestador_1',
            clienteId: 'cliente_1',
            firestore: db,
            avaliacaoStream: avaliacaoStream,
            onSubmit: onSubmit,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('renderiza formulario quando nao ha avaliacao', (tester) async {
    final db = FakeFirebaseFirestore();

    await _pumpCard(tester, db: db);

    expect(find.text('Avalia este prestador'), findsOneWidget);
    expect(
      find.text('A tua avaliação ajuda outros clientes depois do serviço.'),
      findsOneWidget,
    );
    expect(find.text('0/500'), findsOneWidget);
    expect(find.text('Enviar avaliação'), findsOneWidget);
  });

  testWidgets('renderiza resumo quando avaliacao existe', (tester) async {
    final db = FakeFirebaseFirestore();
    await db.collection('avaliacoes').doc('pedido_1_cliente_1').set({
      'pedidoId': 'pedido_1',
      'clienteId': 'cliente_1',
      'prestadorId': 'prestador_1',
      'estrelas': 4,
      'comentario': 'Servico bem feito',
      'createdAt': DateTime(2026, 5, 29),
    });

    await _pumpCard(tester, db: db);

    expect(find.text('Avaliação enviada'), findsOneWidget);
    expect(find.text('Obrigado pelo feedback.'), findsOneWidget);
    expect(find.text('Servico bem feito'), findsOneWidget);
    expect(find.text('Enviar avaliação'), findsNothing);
  });

  testWidgets('selecionar estrela muda estado visual', (tester) async {
    final db = FakeFirebaseFirestore();

    await _pumpCard(tester, db: db);
    await tester.tap(find.byKey(const Key('avaliacao_star_4')));
    await tester.pump();

    expect(find.byKey(const Key('avaliacao_rating_value_4')), findsOneWidget);
  });

  testWidgets('enviar sem estrela mostra erro', (tester) async {
    final db = FakeFirebaseFirestore();

    await _pumpCard(tester, db: db);
    await tester.tap(find.text('Enviar avaliação'));
    await tester.pump();

    expect(find.text('Escolhe uma nota.'), findsWidgets);
  });

  testWidgets('comentario acima de 500 bloqueia envio', (tester) async {
    final db = FakeFirebaseFirestore();
    var submitted = false;

    await _pumpCard(
      tester,
      db: db,
      onSubmit: ({
        required pedidoId,
        required clienteId,
        required prestadorId,
        required estrelas,
        comentario,
      }) async {
        submitted = true;
      },
    );
    await tester.tap(find.byKey(const Key('avaliacao_star_5')));
    await tester.enterText(
      find.byKey(const Key('avaliacao_comment_field')),
      'x' * 501,
    );
    await tester.pump();
    await tester.tap(find.text('Enviar avaliação'));
    await tester.pump();

    expect(submitted, isFalse);
    expect(find.text('O comentário não pode passar de 500 caracteres.'),
        findsOneWidget);
  });

  testWidgets('contador de comentario aparece e atualiza', (tester) async {
    final db = FakeFirebaseFirestore();

    await _pumpCard(tester, db: db);
    expect(find.text('0/500'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('avaliacao_comment_field')),
      'bom serviço',
    );
    await tester.pump();

    expect(find.text('11/500'), findsOneWidget);
  });

  testWidgets('botao fica disabled durante envio', (tester) async {
    final db = FakeFirebaseFirestore();
    final completer = Completer<void>();

    await _pumpCard(
      tester,
      db: db,
      onSubmit: ({
        required pedidoId,
        required clienteId,
        required prestadorId,
        required estrelas,
        comentario,
      }) =>
          completer.future,
    );
    await tester.tap(find.byKey(const Key('avaliacao_star_5')));
    await tester.pump();
    await tester.tap(find.text('Enviar avaliação'));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    completer.complete();
    await tester.pump();
  });

  testWidgets('StreamBuilder loading mostra estado adequado', (tester) async {
    final db = FakeFirebaseFirestore();
    final controller =
        StreamController<DocumentSnapshot<Map<String, dynamic>>>();
    addTearDown(controller.close);

    await _pumpCard(
      tester,
      db: db,
      avaliacaoStream: controller.stream,
    );

    expect(find.text('A carregar avaliação...'), findsOneWidget);
  });

  testWidgets('StreamBuilder erro mostra estado adequado', (tester) async {
    final db = FakeFirebaseFirestore();

    await _pumpCard(
      tester,
      db: db,
      avaliacaoStream:
          Stream<DocumentSnapshot<Map<String, dynamic>>>.error(Exception()),
    );
    await tester.pump();

    expect(find.text('Não conseguimos carregar a avaliação agora.'),
        findsOneWidget);
  });

  testWidgets('dark mode renderiza sem erros', (tester) async {
    final db = FakeFirebaseFirestore();

    await _pumpCard(
      tester,
      db: db,
      theme: AppTheme.darkTheme,
    );

    expect(find.text('Avalia este prestador'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
