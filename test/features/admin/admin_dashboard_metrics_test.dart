import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_health_summary_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_metric_group_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_metric_tile.dart';

void main() {
  testWidgets('health summary destaca pendencias sem prometer saude perfeita',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminHealthSummaryCard(
            pendingCount: 3,
            helper: 'Baseado nas filas carregadas.',
          ),
        ),
      ),
    );

    expect(find.text('Ha pendencias para rever'), findsOneWidget);
    expect(find.text('3 item(ns) precisam de atencao.'), findsOneWidget);
    expect(find.text('Baseado nas filas carregadas.'), findsOneWidget);
  });

  testWidgets('health summary mostra estado neutro sem pendencias',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminHealthSummaryCard(
            pendingCount: 0,
            helper: 'Nenhuma pendencia critica carregada agora.',
          ),
        ),
      ),
    );

    expect(find.text('Operacao sem pendencias criticas'), findsOneWidget);
    expect(find.text('Nenhuma pendencia critica carregada agora.'),
        findsOneWidget);
  });

  testWidgets('metric tile renderiza helper e fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminMetricTile(
            label: 'Receita liquida (30d)',
            value: '-',
            helper: 'Sem dados suficientes para esta metrica.',
          ),
        ),
      ),
    );

    expect(find.text('Receita liquida (30d)'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
    expect(
        find.text('Sem dados suficientes para esta metrica.'), findsOneWidget);
  });

  testWidgets('metric group renderiza titulo, subtitulo e metricas',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminMetricGroupCard(
            title: 'Pedidos',
            subtitle: 'Ultimos 30 dias.',
            children: [
              AdminMetricTile(
                label: 'Pedidos criados (30d)',
                value: '20',
                helper: 'Pedidos criados nos ultimos 30 dias.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Pedidos'), findsOneWidget);
    expect(find.text('Ultimos 30 dias.'), findsOneWidget);
    expect(find.text('Pedidos criados (30d)'), findsOneWidget);
  });

  testWidgets('dashboard cards renderizam em dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: AdminMetricGroupCard(
            title: 'Pendencias operacionais',
            children: [
              AdminMetricTile(label: 'Tickets abertos', value: '0'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Pendencias operacionais'), findsOneWidget);
  });
}
