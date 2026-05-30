import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_panel_content.dart';

void main() {
  const dashboard = <String, dynamic>{
    'openTickets': 2,
    'pendingNoShow': 1,
  };

  const ops = <String, dynamic>{
    'funnel': {
      'created': 12,
      'completed': 8,
    },
    'revenue': {
      'netCents': 2500,
    },
    'noShow': {
      'approved': 1,
    },
  };

  const cost = <String, dynamic>{
    'acquisition': {
      'newUsers30': 5,
      'cacCents': 1200,
    },
    'retention': {
      'churnRate30': 0.1,
    },
    'revenue': {
      'ltvCents': 5000,
    },
  };

  Future<void> pumpContent(WidgetTester tester, {ThemeData? theme}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: AdminPanelContent(
            dashboard: dashboard,
            ops: ops,
            cost: cost,
            tickets: const [
              {
                'id': 'ticket1',
                'subject': 'Ajuda',
                'message': 'Preciso de suporte',
                'status': 'open',
                'userType': 'cliente',
                'createdAt': 1710000000000,
              },
            ],
            reports: const [
              {
                'id': 'report1',
                'reporterId': 'client1',
                'targetType': 'provider_profile',
                'targetId': 'provider1',
                'reasonCode': 'fraud',
                'severity': 'high',
                'status': 'pending_review',
                'createdAt': 1710000000000,
              },
            ],
            noShowCases: const [
              {
                'pedidoId': 'pedido1',
                'titulo': 'Limpeza',
                'noShowReportedBy': 'cliente',
                'noShowDecision': 'pending',
                'updatedAt': 1710000000000,
              },
            ],
            stories: const [
              {
                'id': 'story1',
                'prestadorNome': 'Maria',
                'descricao': 'Portfolio',
                'expiresAt': 1710000000000,
              },
            ],
            ledgerAnomalies: const [
              {
                'paymentIntentId': 'pi_123',
                'pedidoId': 'pedido1',
                'amount': 3000,
                'updatedAt': 1710000000000,
              },
            ],
            ticketFilter: 'open',
            reportFilter: 'pending_review',
            noShowFilter: 'pending',
            sectionErrors: const {},
            onTicketFilterChanged: (_) async {},
            onReportFilterChanged: (_) async {},
            onNoShowFilterChanged: (_) async {},
            onChangeTicketStatus: ({
              required ticketId,
              required status,
            }) async {},
            onChangeReportStatus: ({
              required reportId,
              required status,
              decisionReason,
            }) async {},
            onDecideNoShow: ({
              required pedidoId,
              required decision,
            }) async {},
            onDeleteStory: (_) async {},
          ),
        ),
      ),
    );
  }

  testWidgets('navegacao comeca em visao geral e alterna secoes',
      (tester) async {
    await pumpContent(tester);

    expect(find.text('Visao geral'), findsOneWidget);
    expect(find.text('Resumo operacional'), findsOneWidget);

    await tester.tap(find.text('Moderacao'));
    await tester.pumpAndSettle();
    expect(find.text('Moderacao e denuncias'), findsOneWidget);

    await tester.tap(find.text('Suporte'));
    await tester.pumpAndSettle();
    expect(find.text('Suporte interno'), findsOneWidget);
    expect(find.text('Ajuda'), findsOneWidget);

    await tester.tap(find.text('No-show'));
    await tester.pumpAndSettle();
    expect(find.text('Moderacao no-show'), findsOneWidget);
    expect(find.textContaining('pedido1'), findsOneWidget);

    await tester.tap(find.text('Conteudo'));
    await tester.pumpAndSettle();
    expect(find.text('Moderacao de historias'), findsOneWidget);
    expect(find.text('Prestador: Maria'), findsOneWidget);

    await tester.tap(find.text('Financeiro'));
    await tester.pumpAndSettle();
    expect(find.text('Financeiro e ledger'), findsOneWidget);
    expect(find.textContaining('pi_123'), findsOneWidget);
  });

  testWidgets('navegacao renderiza em dark mode', (tester) async {
    await pumpContent(tester, theme: ThemeData.dark());

    expect(find.text('Visao geral'), findsOneWidget);
    expect(find.text('Resumo operacional'), findsOneWidget);
  });
}
