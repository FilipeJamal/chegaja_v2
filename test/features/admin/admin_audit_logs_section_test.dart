import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_audit_logs_section.dart';

void main() {
  testWidgets('audit logs section mostra logs recentes e transicao de estado',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const [
              AdminAuditLogsSection(
                logs: [
                  {
                    'id': 'log1',
                    'actorUid': 'admin1',
                    'action': 'report.update_status',
                    'targetType': 'report',
                    'targetId': 'report1',
                    'beforeStatus': 'pending_review',
                    'afterStatus': 'reviewed',
                    'createdAt': 1710000000000,
                  },
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Auditoria recente'), findsOneWidget);
    expect(find.text('report.update_status'), findsOneWidget);
    expect(find.text('report report1'), findsOneWidget);
    expect(find.text('admin1'), findsOneWidget);
    expect(find.text('Pendente -> Analisado'), findsOneWidget);
  });

  testWidgets('audit logs section mostra erro, vazio, fallback e dark mode',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ListView(
            children: const [
              AdminAuditLogsSection(
                logs: [],
                error: 'permission-denied',
              ),
              AdminAuditLogsSection(
                logs: [
                  {
                    'id': '',
                    'action': '',
                    'targetType': '',
                    'targetId': '',
                  },
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Falha ao carregar'), findsOneWidget);
    expect(find.text('Sem logs recentes.'), findsOneWidget);
    expect(find.text('Log sem ID'), findsOneWidget);
    expect(find.text('Acao sem nome'), findsOneWidget);
    expect(find.text('Sem dados'), findsWidgets);
  });
}
