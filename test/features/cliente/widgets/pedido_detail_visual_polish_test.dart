import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_next_action_card.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_presenter.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_status_summary.dart';
import 'package:chegaja_v2/features/cliente/widgets/pedido_timeline.dart';
import 'package:chegaja_v2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('PedidoStatusSummary usa AppActionPanel visual', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PedidoStatusSummary(
          data: PedidoStatusSummaryData(
            title: 'Servico em andamento',
            description: 'O trabalho esta em curso.',
            actor: 'A acompanhar',
            tone: PedidoStatusTone.info,
            icon: Icons.build_circle_outlined,
          ),
        ),
      ),
    );

    expect(find.byType(AppActionPanel), findsOneWidget);
    expect(find.text('Servico em andamento'), findsOneWidget);
  });

  testWidgets('PedidoNextActionCard usa AppActionPanel visual', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PedidoNextActionCard(
          data: PedidoNextActionData(
            title: 'Proxima acao',
            description: 'Envia o valor final.',
            nextStep: 'O cliente confirma depois.',
            hasUserAction: true,
          ),
        ),
      ),
    );

    expect(find.byType(AppActionPanel), findsOneWidget);
    expect(find.text('Proxima acao'), findsOneWidget);
  });

  testWidgets('PedidoTimeline mostra progresso compacto', (tester) async {
    await tester.pumpWidget(wrap(const PedidoTimeline(estado: 'aceito')));
    await tester.pump();

    expect(find.text('Progresso do pedido'), findsOneWidget);
    expect(find.text('Criado'), findsOneWidget);
    expect(find.text('Aceito'), findsOneWidget);
  });
}
