import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_chip.dart';
import 'package:chegaja_v2/core/widgets/app_state_views.dart';
import 'package:chegaja_v2/features/cliente/widgets/cliente_home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _accessibleHarness({
  required Widget child,
  ThemeData? theme,
  double textScale = 2,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.lightTheme,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('U1 accessibility', () {
    testWidgets('core actions keep 48px targets at 200% text scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _accessibleHarness(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClienteServiceModeSelector(
                selectedMode: 'IMEDIATO',
                onChanged: (_) {},
              ),
              const SizedBox(height: AppSpacing.x4),
              AppButton(
                label: 'Continuar',
                onPressed: () {},
                expanded: true,
              ),
              const SizedBox(height: AppSpacing.x4),
              Align(
                alignment: Alignment.centerLeft,
                child: AppChip(
                  label: 'Limpeza',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      for (final label in ['Agora', 'Agendar', 'Orçamentos', 'Continuar']) {
        final target = find.bySemanticsLabel(label);
        expect(target, findsOneWidget);
        expect(
          tester.getSize(target).height,
          greaterThanOrEqualTo(AppSizes.minTapTarget),
          reason: '$label must keep a minimum 48px touch target.',
        );
      }
      expect(
        tester.getSize(find.bySemanticsLabel('Limpeza')).height,
        greaterThanOrEqualTo(AppSizes.minTapTarget),
      );
      expect(
        tester.getSize(find.bySemanticsLabel('Limpeza')).width,
        greaterThanOrEqualTo(AppSizes.minTapTarget),
      );
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('mobile hero has no overflow at 200% text scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _accessibleHarness(
          child: ClienteHomeHero(
            title: 'Encontra ajuda local com confiança',
            subtitle:
                'Escolhe como precisas do serviço e descreve o teu pedido.',
            onSearch: () {},
            onContinue: (_) {},
            onModeChanged: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('cliente_home_hero')), findsOneWidget);
      expect(find.text('Agora'), findsOneWidget);
      expect(find.text('Agendar'), findsOneWidget);
      expect(find.text('Orçamentos'), findsOneWidget);
    });

    testWidgets('minimum targets remain valid in dark mode', (tester) async {
      await tester.pumpWidget(
        _accessibleHarness(
          theme: AppTheme.darkTheme,
          child: ClienteServiceModeSelector(
            selectedMode: 'AGENDADO',
            onChanged: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });

    testWidgets('hero illustration remains intentionally framed in dark mode',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _accessibleHarness(
          theme: AppTheme.darkTheme,
          textScale: 1,
          child: ClienteHomeHero(
            title: 'Encontra ajuda local com confiança',
            subtitle: 'Descreve o serviço e escolhe quando precisas.',
            onSearch: () {},
            onContinue: (_) {},
            onModeChanged: (_) {},
          ),
        ),
      );

      final illustration = tester.widget<Container>(
        find.byKey(const Key('cliente_home_hero_illustration')),
      );
      final decoration = illustration.decoration! as BoxDecoration;
      expect(decoration.color, AppPalette.u1LightSurface);
      expect(decoration.border, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'button, chip and recovery actions remain screen-reader tappable',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _accessibleHarness(
            textScale: 1,
            child: Column(
              children: [
                AppButton(label: 'Continuar', onPressed: () {}),
                AppChip(label: 'Limpeza', onTap: () {}),
                AppRecoveryView(
                  title: 'Pedido interrompido',
                  message: 'Podes continuar sem perder os dados.',
                  recoveryLabel: 'Retomar',
                  onRecover: () {},
                  secondaryLabel: 'Cancelar',
                  onSecondary: () {},
                ),
              ],
            ),
          ),
        );
        for (final label in ['Continuar', 'Limpeza', 'Retomar', 'Cancelar']) {
          final node = tester.getSemantics(find.bySemanticsLabel(label));
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
            reason: '$label must expose a semantic tap action.',
          );
        }
      } finally {
        semantics.dispose();
      }
    });
  });
}
