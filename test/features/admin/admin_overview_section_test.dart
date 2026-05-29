import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_overview_section.dart';

void main() {
  Future<void> pumpSection(
    WidgetTester tester, {
    Map<String, dynamic> dashboard = const {
      'openTickets': 3,
      'pendingNoShow': 2,
    },
    Map<String, dynamic> ops = const {
      'funnel': {
        'created': 20,
        'completed': 15,
      },
      'revenue': {
        'netCents': 12345,
      },
      'noShow': {
        'approved': 1,
      },
    },
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListView(
            children: [
              AdminOverviewSection(
                dashboard: dashboard,
                ops: ops,
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('mostra metricas principais do resumo operacional',
      (tester) async {
    await pumpSection(tester);

    expect(find.text('Resumo operacional'), findsOneWidget);
    expect(find.text('Tickets abertos'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('No-show pendente'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Pedidos (30d)'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Concluidos (30d)'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Receita liquida (30d)'), findsOneWidget);
    expect(find.text('EUR 123.45'), findsOneWidget);
  });

  testWidgets('usa valores defensivos quando dados faltam', (tester) async {
    await pumpSection(tester, dashboard: const {}, ops: const {});

    expect(find.text('Resumo operacional'), findsOneWidget);
    expect(find.text('Tickets abertos'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('renderiza em dark mode', (tester) async {
    await pumpSection(tester, theme: ThemeData.dark());

    expect(find.text('Resumo operacional'), findsOneWidget);
  });
}
