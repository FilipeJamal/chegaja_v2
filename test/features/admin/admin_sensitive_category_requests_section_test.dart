import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_sensitive_category_requests_section.dart';

void main() {
  const request = <String, dynamic>{
    'id': 'req1',
    'providerId': 'provider1',
    'categoryId': 'electricity',
    'categoryName': 'Eletricidade',
    'status': 'pending_review',
    'evidenceTypes': ['work_experience', 'portfolio_reference'],
    'evidenceText': 'Tenho experiencia comprovavel nesta categoria.',
    'portfolioUrls': ['https://example.com/obra.jpg'],
    'submittedAt': 1710000000000,
  };

  Future<void> pumpSection(
    WidgetTester tester, {
    List<Map<String, dynamic>> requests = const [request],
    String? error,
    ThemeData? theme,
    Future<void> Function({
      required Map<String, dynamic> request,
      required String decision,
    })? onReviewRequested,
    ValueChanged<String>? onFilterChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListView(
            children: [
              AdminSensitiveCategoryRequestsSection(
                requests: requests,
                statusFilter: 'pending_review',
                error: error,
                onFilterChanged: onFilterChanged ?? (_) {},
                onReviewRequested: onReviewRequested ??
                    ({
                      required request,
                      required decision,
                    }) async {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('mostra pedidos com categoria, provider e evidencias',
      (tester) async {
    await pumpSection(tester);

    expect(find.text('Comprovativos profissionais'), findsOneWidget);
    expect(find.text('Eletricidade'), findsOneWidget);
    expect(find.textContaining('Provider: provider1'), findsOneWidget);
    expect(find.text('Status: Pendente'), findsOneWidget);
    expect(find.text('Categoria: electricity'), findsOneWidget);
    expect(find.textContaining('Experiencia de trabalho'), findsOneWidget);
    expect(find.textContaining('Portfolio publico'), findsOneWidget);
    expect(
        find.textContaining('Tenho experiencia comprovavel'), findsOneWidget);
    expect(find.textContaining('https://example.com/obra.jpg'), findsOneWidget);
  });

  testWidgets('estado vazio e erro renderizam', (tester) async {
    await pumpSection(tester, requests: const []);
    expect(find.text('Sem pedidos de comprovativo para este filtro.'),
        findsOneWidget);

    await pumpSection(tester, requests: const [], error: 'permission-denied');
    expect(find.textContaining('Falha ao carregar'), findsOneWidget);
    expect(find.textContaining('permission-denied'), findsOneWidget);
  });

  testWidgets('acoes chamam callback com decisao correta', (tester) async {
    final calls = <String>[];
    await pumpSection(
      tester,
      onReviewRequested: ({
        required request,
        required decision,
      }) async {
        calls.add('${request['id']}:$decision');
      },
    );

    await tester.tap(find.text('Aprovar'));
    await tester.pump();
    await tester.tap(find.text('Rejeitar'));
    await tester.pump();
    await tester.tap(find.text('Pedir mais informacao'));
    await tester.pump();

    expect(calls, [
      'req1:approved',
      'req1:rejected',
      'req1:needs_more_info',
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
    await tester.tap(find.text('Mais info').last);
    await tester.pump();

    expect(selected, 'needs_more_info');
    expect(find.text('Comprovativos profissionais'), findsOneWidget);
  });
}
