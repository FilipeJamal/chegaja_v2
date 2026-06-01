import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_sensitive_category_decision_sheet.dart';

void main() {
  const request = <String, dynamic>{
    'id': 'req1',
    'providerId': 'provider1',
    'categoryId': 'electricity',
    'categoryName': 'Eletricidade',
    'status': 'pending_review',
  };

  Widget wrap(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(body: child),
    );
  }

  testWidgets('approve permite motivo opcional e envia decisao',
      (tester) async {
    final calls = <SensitiveCategoryDecisionInput>[];

    await tester.pumpWidget(
      wrap(
        AdminSensitiveCategoryDecisionSheet(
          request: request,
          decision: 'approved',
          onSubmit: (input) async => calls.add(input),
        ),
      ),
    );

    expect(find.text('Aprovar categoria'), findsOneWidget);
    await tester.tap(find.text('Confirmar decisao'));
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single.requestId, 'req1');
    expect(calls.single.decision, 'approved');
    expect(calls.single.decisionReason, '');
  });

  testWidgets('reject e needs_more_info exigem motivo', (tester) async {
    final calls = <SensitiveCategoryDecisionInput>[];

    await tester.pumpWidget(
      wrap(
        AdminSensitiveCategoryDecisionSheet(
          request: request,
          decision: 'rejected',
          onSubmit: (input) async => calls.add(input),
        ),
      ),
    );

    await tester.tap(find.text('Confirmar decisao'));
    await tester.pump();

    expect(find.text('Escreve um motivo para esta decisao.'), findsOneWidget);
    expect(calls, isEmpty);

    await tester.enterText(
      find.byKey(const Key('admin_sensitive_category_decision_reason')),
      'Falta comprovativo minimo.',
    );
    await tester.tap(find.text('Confirmar decisao'));
    await tester.pumpAndSettle();

    expect(calls.single.decision, 'rejected');
    expect(calls.single.decisionReason, 'Falta comprovativo minimo.');

    await tester.pumpWidget(
      wrap(
        AdminSensitiveCategoryDecisionSheet(
          request: request,
          decision: 'needs_more_info',
          onSubmit: (input) async => calls.add(input),
        ),
      ),
    );

    expect(find.text('Pedir mais informacao'), findsOneWidget);
  });

  testWidgets('loading bloqueia duplo clique e erro mostra feedback seguro',
      (tester) async {
    final completer = Completer<void>();
    var count = 0;

    await tester.pumpWidget(
      wrap(
        AdminSensitiveCategoryDecisionSheet(
          request: request,
          decision: 'approved',
          onSubmit: (_) {
            count++;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('Confirmar decisao'));
    await tester.pump();
    await tester.tap(find.text('A guardar...'), warnIfMissed: false);
    await tester.pump();

    expect(count, 1);
    completer.complete();
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      wrap(
        AdminSensitiveCategoryDecisionSheet(
          request: request,
          decision: 'approved',
          onSubmit: (_) async => throw Exception('backend detail'),
        ),
      ),
    );

    await tester.tap(find.text('Confirmar decisao'));
    await tester.pumpAndSettle();

    expect(find.text('Nao foi possivel gravar esta decisao.'), findsOneWidget);
    expect(find.textContaining('backend detail'), findsNothing);
  });

  testWidgets('dark mode renderiza sem textos proibidos', (tester) async {
    await tester.pumpWidget(
      wrap(
        AdminSensitiveCategoryDecisionSheet(
          request: request,
          decision: 'approved',
          onSubmit: (_) async {},
        ),
        theme: ThemeData.dark(),
      ),
    );

    expect(find.text('Aprovar categoria'), findsOneWidget);
    expect(find.textContaining('Prestador certificado'), findsNothing);
    expect(find.textContaining('pagamento seguro'), findsNothing);
  });
}
