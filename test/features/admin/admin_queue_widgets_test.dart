import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chegaja_v2/features/admin/widgets/admin_queue_action_row.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_card.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_filter_bar.dart';
import 'package:chegaja_v2/features/admin/widgets/admin_queue_status_chip.dart';

void main() {
  testWidgets('status chip traduz status e severidade para labels legiveis',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              AdminQueueStatusChip(label: 'Status', value: 'pending_review'),
              AdminQueueStatusChip(label: 'Severidade', value: 'high'),
              AdminQueueStatusChip(label: 'Motivo', value: 'fraud'),
              AdminQueueStatusChip(label: 'Tipo', value: 'provider_profile'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Status: Pendente'), findsOneWidget);
    expect(find.text('Severidade: Alta'), findsOneWidget);
    expect(find.text('Motivo: Fraude/golpe'), findsOneWidget);
    expect(find.text('Tipo: Perfil prestador'), findsOneWidget);
  });

  testWidgets('queue card mostra titulo, subtitulo, meta e fallback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminQueueCard(
            title: '',
            fallbackTitle: 'Item sem ID',
            subtitle: '',
            meta: [
              AdminQueueStatusChip(label: 'Status', value: ''),
            ],
            children: [
              Text('Detalhe operacional'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Item sem ID'), findsOneWidget);
    expect(find.text('Sem dados'), findsOneWidget);
    expect(find.text('Status: -'), findsOneWidget);
    expect(find.text('Detalhe operacional'), findsOneWidget);
  });

  testWidgets('queue action row chama callbacks e bloqueia acoes sem id',
      (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminQueueActionRow(
            actions: [
              AdminQueueAction(
                label: 'Resolver',
                icon: Icons.check,
                onPressed: () => calls.add('resolver'),
              ),
              const AdminQueueAction(
                label: 'Bloqueada',
                icon: Icons.block,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Resolver'));
    await tester.pump();
    expect(calls, ['resolver']);

    final blocked = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Bloqueada'),
    );
    expect(blocked.onPressed, isNull);
  });

  testWidgets('queue filter bar renderiza filtros e dark mode', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AdminQueueFilterBar(
            title: 'Suporte interno',
            description: 'Tickets recebidos pela equipa.',
            value: 'open',
            options: const [
              AdminQueueFilterOption(value: 'open', label: 'Abertos'),
              AdminQueueFilterOption(value: 'resolved', label: 'Resolvidos'),
            ],
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('Suporte interno'), findsOneWidget);
    expect(find.text('Tickets recebidos pela equipa.'), findsOneWidget);

    await tester.tap(find.text('Abertos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resolvidos').last);
    await tester.pump();

    expect(selected, 'resolved');
  });
}
