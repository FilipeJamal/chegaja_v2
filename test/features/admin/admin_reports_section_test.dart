import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_reports_section.dart';

void main() {
  const report = <String, dynamic>{
    'id': 'report1',
    'reporterId': 'client1',
    'targetType': 'provider_profile',
    'targetId': 'provider1',
    'targetOwnerId': 'provider1',
    'reasonCode': 'fraud',
    'severity': 'high',
    'status': 'pending_review',
    'details': 'Perfil suspeito',
    'createdAt': 1710000000000,
  };

  Future<void> pumpSection(
    WidgetTester tester, {
    List<Map<String, dynamic>> reports = const [report],
    String? error,
    ThemeData? theme,
    Future<void> Function({
      required String reportId,
      required String status,
      String? decisionReason,
    })? onUpdateStatus,
    ValueChanged<String>? onFilterChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListView(
            children: [
              AdminReportsSection(
                reports: reports,
                statusFilter: 'pending_review',
                error: error,
                onFilterChanged: onFilterChanged ?? (_) {},
                onUpdateStatus: onUpdateStatus ??
                    ({
                      required reportId,
                      required status,
                      decisionReason,
                    }) async {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('mostra lista de denuncias com metadados principais',
      (tester) async {
    await pumpSection(tester);

    expect(find.text('Moderacao e denuncias'), findsOneWidget);
    expect(find.text('Tipo: Perfil prestador'), findsOneWidget);
    expect(find.text('Motivo: Fraude/golpe'), findsOneWidget);
    expect(find.text('Severidade: Alta'), findsOneWidget);
    expect(find.text('Status: Pendente'), findsOneWidget);
    expect(find.textContaining('Perfil suspeito'), findsOneWidget);
    expect(find.textContaining('Reporter: client1'), findsOneWidget);
    expect(find.textContaining('Target: provider1'), findsOneWidget);
    expect(find.textContaining('Owner: provider1'), findsOneWidget);
    expect(find.text('pending_review'), findsNothing);
  });

  testWidgets('estado vazio e erro renderizam sem quebrar', (tester) async {
    await pumpSection(tester, reports: const []);
    expect(find.text('Sem denuncias para este filtro.'), findsOneWidget);

    await pumpSection(
      tester,
      reports: const [],
      error: 'permission-denied',
    );
    expect(find.textContaining('Falha ao carregar'), findsOneWidget);
    expect(find.textContaining('permission-denied'), findsOneWidget);
  });

  testWidgets('acoes chamam callback com status correto', (tester) async {
    final calls = <String>[];
    await pumpSection(
      tester,
      onUpdateStatus: ({
        required reportId,
        required status,
        decisionReason,
      }) async {
        calls.add('$reportId:$status:$decisionReason');
      },
    );

    await tester.tap(find.text('Marcar analisada'));
    await tester.pump();
    await tester.tap(find.text('Descartar'));
    await tester.pump();
    await tester.tap(find.text('Escalar'));
    await tester.pump();

    expect(calls, <String>[
      'report1:reviewed:Marcada como analisada no admin.',
      'report1:dismissed:Descartada no admin.',
      'report1:escalated:Escalada para analise posterior.',
    ]);
  });

  testWidgets('filtro chama callback e dark mode renderiza', (tester) async {
    String? selected;
    await pumpSection(
      tester,
      theme: ThemeData.dark(),
      onFilterChanged: (value) => selected = value,
    );

    await tester.tap(find.text('Pendentes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escaladas').last);
    await tester.pump();

    expect(selected, 'escalated');
    expect(find.text('Moderacao e denuncias'), findsOneWidget);
  });
}
