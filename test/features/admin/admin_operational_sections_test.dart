import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_finance_ledger_section.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_no_show_section.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_section_state.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_stories_section.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_support_tickets_section.dart';

void main() {
  testWidgets('support section mostra tickets, vazio e chama callback',
      (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AdminSupportTicketsSection(
                tickets: const [
                  {
                    'id': 'ticket1',
                    'subject': 'Conta',
                    'message': 'Preciso de ajuda',
                    'status': 'open',
                    'userType': 'cliente',
                    'createdAt': 1710000000000,
                  },
                ],
                statusFilter: 'open',
                onFilterChanged: (_) {},
                onChangeStatus: ({
                  required ticketId,
                  required status,
                }) async {
                  calls.add('$ticketId:$status');
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Suporte interno'), findsOneWidget);
    expect(find.text('Conta'), findsOneWidget);

    await tester.tap(find.text('resolved'));
    await tester.pump();
    expect(calls, contains('ticket1:resolved'));
  });

  testWidgets('no-show section mostra casos, vazio e chama callback',
      (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AdminNoShowSection(
                cases: const [
                  {
                    'pedidoId': 'pedido1',
                    'titulo': 'Limpeza',
                    'noShowReportedBy': 'prestador',
                    'noShowReason': 'Cliente nao apareceu',
                    'noShowDecision': 'pending',
                    'updatedAt': 1710000000000,
                  },
                ],
                decisionFilter: 'pending',
                onFilterChanged: (_) {},
                onDecide: ({
                  required pedidoId,
                  required decision,
                }) async {
                  calls.add('$pedidoId:$decision');
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Moderacao no-show'), findsOneWidget);
    expect(find.textContaining('pedido1'), findsOneWidget);

    await tester.tap(find.text('Aprovar'));
    await tester.pump();
    expect(calls, contains('pedido1:approved'));
  });

  testWidgets('stories section mostra stories e acao de remocao',
      (tester) async {
    String? deleted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AdminStoriesSection(
                stories: const [
                  {
                    'id': 'story1',
                    'prestadorNome': 'Maria',
                    'descricao': 'Antes e depois',
                    'expiresAt': 1710000000000,
                  },
                ],
                onDeleteStory: (storyId) async => deleted = storyId,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Moderacao de historias'), findsOneWidget);
    expect(find.text('Maria'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    expect(deleted, 'story1');
  });

  testWidgets('finance section mostra custo, retencao e anomalias',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              AdminFinanceLedgerSection(
                cost: {
                  'acquisition': {
                    'newUsers30': 9,
                    'cacCents': 1500,
                  },
                  'retention': {
                    'churnRate30': 0.25,
                  },
                  'revenue': {
                    'ltvCents': 4000,
                  },
                },
                ledgerAnomalies: [
                  {
                    'paymentIntentId': 'pi_123',
                    'pedidoId': 'pedido1',
                    'amount': 2500,
                    'updatedAt': 1710000000000,
                  },
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Financeiro e ledger'), findsOneWidget);
    expect(find.text('Novos utilizadores (30d)'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.textContaining('pi_123'), findsOneWidget);
  });

  testWidgets('section error e empty state renderizam em dark mode',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: Column(
            children: [
              AdminSectionError(message: 'falha isolada'),
              AdminSectionEmptyState(message: 'sem dados'),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('falha isolada'), findsOneWidget);
    expect(find.text('sem dados'), findsOneWidget);
  });
}
