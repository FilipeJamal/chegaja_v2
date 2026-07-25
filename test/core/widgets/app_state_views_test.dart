import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/core/widgets/app_state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

Finder _liveRegion(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.liveRegion == true &&
        widget.properties.label == label,
  );
}

void main() {
  group('App state views', () {
    testWidgets('loading announces its current operation', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppLoadingView(label: 'A carregar pedidos')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('A carregar pedidos'), findsOneWidget);
      expect(_liveRegion('A carregar pedidos'), findsOneWidget);
    });

    testWidgets('empty state explains recovery and invokes its action',
        (tester) async {
      var actionCount = 0;

      await tester.pumpWidget(
        _wrap(
          AppEmptyView(
            title: 'Sem pedidos',
            message: 'Cria o primeiro pedido.',
            actionLabel: 'Criar pedido',
            onAction: () => actionCount += 1,
          ),
        ),
      );

      expect(
        _liveRegion('Sem pedidos. Cria o primeiro pedido.'),
        findsOneWidget,
      );
      expect(find.text('Criar pedido'), findsOneWidget);

      await tester.tap(find.text('Criar pedido'));
      await tester.pump();

      expect(actionCount, 1);
    });

    testWidgets('error state offers retry and support paths', (tester) async {
      var retries = 0;
      var supportRequests = 0;

      await tester.pumpWidget(
        _wrap(
          AppErrorView(
            title: 'Falha ao carregar',
            message: 'Não foi possível obter os pedidos.',
            retryLabel: 'Repetir',
            supportLabel: 'Pedir ajuda',
            onRetry: () => retries += 1,
            onSupport: () => supportRequests += 1,
          ),
        ),
      );

      expect(
        _liveRegion(
          'Falha ao carregar. Não foi possível obter os pedidos.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Repetir'));
      await tester.tap(find.text('Pedir ajuda'));
      await tester.pump();

      expect(retries, 1);
      expect(supportRequests, 1);
    });

    testWidgets('offline state announces stale access and retries',
        (tester) async {
      var retries = 0;

      await tester.pumpWidget(
        _wrap(
          AppOfflineView(
            title: 'Sem internet',
            message: 'A mostrar dados guardados.',
            onRetry: () => retries += 1,
          ),
        ),
      );

      expect(
        _liveRegion('Sem internet. A mostrar dados guardados.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(retries, 1);
    });

    testWidgets('recovery state invokes primary and secondary actions',
        (tester) async {
      var recoveries = 0;
      var cancellations = 0;

      await tester.pumpWidget(
        _wrap(
          AppRecoveryView(
            title: 'Sessão interrompida',
            message: 'Retoma sem perder os dados.',
            recoveryLabel: 'Retomar',
            onRecover: () => recoveries += 1,
            secondaryLabel: 'Cancelar',
            onSecondary: () => cancellations += 1,
          ),
        ),
      );

      expect(
        _liveRegion('Sessão interrompida. Retoma sem perder os dados.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Retomar'));
      await tester.tap(find.text('Cancelar'));
      await tester.pump();

      expect(recoveries, 1);
      expect(cancellations, 1);
    });

    testWidgets('skeleton list announces loading and hides decorative boxes',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const AppSkeletonList(itemCount: 2)),
      );

      expect(_liveRegion('A carregar conteúdo'), findsOneWidget);
      expect(find.byType(AppSkeletonBox), findsNWidgets(6));
      expect(find.byType(AppSkeletonLine), findsNWidgets(4));
    });

    testWidgets('stale banner is announced and refresh remains actionable',
        (tester) async {
      var refreshes = 0;

      await tester.pumpWidget(
        _wrap(
          AppStaleDataBanner(
            message: 'Dados atualizados há 10 minutos.',
            onRefresh: () => refreshes += 1,
          ),
        ),
      );

      expect(
        _liveRegion('Dados atualizados há 10 minutos.'),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(AppStaleDataBanner)).height,
        greaterThanOrEqualTo(48),
      );

      await tester.tap(find.text('Atualizar'));
      await tester.pump();

      expect(refreshes, 1);
    });
  });
}
