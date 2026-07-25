import 'package:chegaja_v2/core/theme/app_semantic_colors.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_action_panel.dart';
import 'package:chegaja_v2/core/widgets/app_brand_wordmark.dart';
import 'package:chegaja_v2/core/widgets/app_chip.dart';
import 'package:chegaja_v2/core/widgets/app_metric_tile.dart';
import 'package:chegaja_v2/core/widgets/app_product_header.dart';
import 'package:chegaja_v2/core/widgets/app_state_views.dart';
import 'package:chegaja_v2/core/widgets/app_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required ThemeData theme,
  required Widget child,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SizedBox(width: 640, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ProductHeader restores legacy brand and enables U1 wordmark',
      (tester) async {
    const header = AppProductHeader(title: 'Pedidos');

    await _pump(
      tester,
      theme: AppTheme.legacyLightTheme,
      child: header,
    );
    expect(
      find.byKey(const Key('app_product_header_legacy_brand')),
      findsOneWidget,
    );
    expect(find.byType(AppBrandWordmark), findsNothing);

    await _pump(
      tester,
      theme: AppTheme.u1LightTheme,
      child: header,
    );
    expect(
      find.byKey(const Key('app_product_header_legacy_brand')),
      findsNothing,
    );
    expect(find.byType(AppBrandWordmark), findsOneWidget);
  });

  testWidgets('StatusPill resolves exact legacy and U1 semantic colors',
      (tester) async {
    const pill = AppStatusPill(
      label: 'Informacao',
      tone: AppStatusTone.info,
    );

    await _pump(
      tester,
      theme: AppTheme.legacyLightTheme,
      child: pill,
    );
    var decoration = tester
        .widget<DecoratedBox>(
          find.descendant(
            of: find.byType(AppStatusPill),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration as BoxDecoration;
    expect(
      decoration.color,
      AppPalette.accentBlue.withValues(alpha: 0.10),
    );

    await _pump(
      tester,
      theme: AppTheme.u1LightTheme,
      child: pill,
    );
    decoration = tester
        .widget<DecoratedBox>(
          find.descendant(
            of: find.byType(AppStatusPill),
            matching: find.byType(DecoratedBox),
          ),
        )
        .decoration as BoxDecoration;
    expect(
      decoration.color,
      AppSemanticColors.status(
        AppTheme.u1LightTheme,
        AppStatusTone.info,
      ).background,
    );
  });

  testWidgets('ActionPanel and MetricTile add semantic borders only in U1',
      (tester) async {
    const content = Column(
      children: [
        AppActionPanel(
          title: 'Acao',
          message: 'Mensagem',
          icon: Icons.info_outline,
        ),
        AppMetricTile(
          label: 'Pedidos',
          value: '3',
          icon: Icons.analytics_outlined,
        ),
      ],
    );

    await _pump(
      tester,
      theme: AppTheme.legacyLightTheme,
      child: content,
    );
    _expectIconBorder(tester, width: 40, present: false);
    _expectIconBorder(tester, width: 38, present: false);

    await _pump(
      tester,
      theme: AppTheme.u1LightTheme,
      child: content,
    );
    _expectIconBorder(tester, width: 40, present: true);
    _expectIconBorder(tester, width: 38, present: true);
  });

  testWidgets('ErrorView restores legacy markup and mode-specific defaults',
      (tester) async {
    final error = AppErrorView(
      message: 'Falhou',
      onRetry: () {},
    );

    await _pump(
      tester,
      theme: AppTheme.legacyLightTheme,
      child: error,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Nao foi possivel concluir'), findsNothing);
    expect(find.text('Não foi possível concluir'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);

    await _pump(
      tester,
      theme: AppTheme.u1LightTheme,
      child: error,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Não foi possível concluir'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('Chip restores legacy size and enables U1 tap target and colors',
      (tester) async {
    const chip = AppChip(
      label: 'Selecionado',
      selected: true,
    );

    await _pump(
      tester,
      theme: AppTheme.legacyLightTheme,
      child: chip,
    );
    expect(_hasMinimumTapTarget(tester), isFalse);
    var decoration = _chipDecoration(tester);
    expect(
      decoration.color,
      AppPalette.primary.withValues(alpha: 0.15),
    );

    await _pump(
      tester,
      theme: AppTheme.u1LightTheme,
      child: chip,
    );
    expect(_hasMinimumTapTarget(tester), isTrue);
    decoration = _chipDecoration(tester);
    expect(
      decoration.color,
      AppSemanticColors.primarySelection(
        AppTheme.u1LightTheme,
      ).background,
    );
  });
}

void _expectIconBorder(
  WidgetTester tester, {
  required double width,
  required bool present,
}) {
  final container =
      tester.widgetList<Container>(find.byType(Container)).firstWhere(
            (candidate) =>
                candidate.constraints?.minWidth == width &&
                candidate.constraints?.maxWidth == width,
          );
  final decoration = container.decoration! as BoxDecoration;
  expect(decoration.border, present ? isNotNull : isNull);
}

bool _hasMinimumTapTarget(WidgetTester tester) {
  return tester
      .widgetList<ConstrainedBox>(
        find.descendant(
          of: find.byType(AppChip),
          matching: find.byType(ConstrainedBox),
        ),
      )
      .any(
        (box) =>
            box.constraints.minWidth == AppSizes.minTapTarget &&
            box.constraints.minHeight == AppSizes.minTapTarget,
      );
}

BoxDecoration _chipDecoration(WidgetTester tester) {
  final animated = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(AppChip),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return animated.decoration! as BoxDecoration;
}
