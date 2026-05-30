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
        'cancelled': 2,
      },
      'revenue': {
        'grossCents': 15000,
        'feeCents': 2655,
        'netCents': 12345,
      },
      'noShow': {
        'pending': 2,
        'approved': 1,
      },
    },
    Map<String, dynamic> cost = const {
      'acquisition': {
        'newUsers30': 7,
      },
      'retention': {
        'activeUsers30': 11,
        'churnRate30': 0.125,
      },
      'revenue': {
        'ltvCents': 4500,
      },
    },
    List<Map<String, dynamic>> tickets = const [
      {'id': 'ticket1', 'status': 'open'},
      {'id': 'ticket2', 'status': 'open'},
    ],
    List<Map<String, dynamic>> reports = const [
      {'id': 'report1', 'status': 'pending_review'},
      {'id': 'report2', 'status': 'pending_review'},
    ],
    List<Map<String, dynamic>> noShowCases = const [
      {'pedidoId': 'pedido1', 'noShowDecision': 'pending'},
    ],
    List<Map<String, dynamic>> ledgerAnomalies = const [
      {'paymentIntentId': 'pi_123'},
    ],
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
                cost: cost,
                tickets: tickets,
                reports: reports,
                noShowCases: noShowCases,
                ledgerAnomalies: ledgerAnomalies,
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
    expect(find.text('Ha pendencias para rever'), findsOneWidget);
    expect(find.text('Pendencias operacionais'), findsOneWidget);
    expect(find.text('Tickets abertos'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Denuncias pendentes'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('No-show pendente'), findsOneWidget);
    expect(find.text('Anomalias de ledger'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
    expect(find.text('Pedidos criados (30d)'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('Pedidos concluidos (30d)'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Taxa simples de conclusao'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Financeiro operacional'), findsOneWidget);
    expect(find.text('Receita liquida (30d)'), findsOneWidget);
    expect(find.text('EUR 123.45'), findsOneWidget);
    expect(find.text('Crescimento e retencao'), findsOneWidget);
    expect(find.text('Novos utilizadores (30d)'), findsOneWidget);
    expect(find.text('Churn estimado (30d)'), findsOneWidget);
    expect(find.text('12.5%'), findsOneWidget);
    expect(find.text('Valores podem ser estimativas operacionais.'),
        findsOneWidget);
  });

  testWidgets('usa fallbacks honestos quando dados faltam', (tester) async {
    await pumpSection(
      tester,
      dashboard: const {},
      ops: const {},
      cost: const {},
      tickets: const [],
      reports: const [],
      noShowCases: const [],
      ledgerAnomalies: const [],
    );

    expect(find.text('Resumo operacional'), findsOneWidget);
    expect(find.text('Operacao sem pendencias criticas'), findsOneWidget);
    expect(find.text('Tickets abertos'), findsOneWidget);
    expect(find.text('Sem dados suficientes para esta metrica.'), findsWidgets);
    expect(find.text('-'), findsWidgets);
  });

  testWidgets('estado neutro aparece quando nao ha pendencias', (tester) async {
    await pumpSection(
      tester,
      dashboard: const {'openTickets': 0, 'pendingNoShow': 0},
      ops: const {
        'funnel': {'created': 10, 'completed': 10},
        'noShow': {'pending': 0},
        'revenue': {'netCents': 1000},
      },
      reports: const [],
      noShowCases: const [],
      ledgerAnomalies: const [],
    );

    expect(find.text('Operacao sem pendencias criticas'), findsOneWidget);
    expect(find.text('Nenhuma pendencia critica carregada agora.'),
        findsOneWidget);
  });

  testWidgets('renderiza em dark mode', (tester) async {
    await pumpSection(tester, theme: ThemeData.dark());

    expect(find.text('Resumo operacional'), findsOneWidget);
  });
}
