import 'package:chegaja_v2/app.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_service.dart';
import 'package:chegaja_v2/core/feature_flags/feature_flag_snapshot.dart';
import 'package:chegaja_v2/core/services/role_mode_service.dart';
import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/core/theme/app_theme_extension.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:chegaja_v2/core/widgets/app_button.dart';
import 'package:chegaja_v2/core/widgets/app_card.dart';
import 'package:chegaja_v2/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FeatureFlagSnapshot _snapshot({required bool u1Enabled}) {
  final defaults = FeatureFlagSnapshot.defaults();
  return FeatureFlagSnapshot(
    contractVersion: FeatureFlagContract.version,
    releaseId: u1Enabled ? 'test-u1-on' : 'test-u1-off',
    source: FeatureFlagSnapshotSource.bundledDefaults,
    fetchStatus: FeatureFlagFetchStatus.notFetched,
    remoteValues: {
      ...defaults.remoteValues,
      FeatureFlag.u1NavigationV2: u1Enabled,
    },
  );
}

class _VisualProbe extends StatelessWidget {
  const _VisualProbe();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: ColoredBox(
        key: const Key('theme-surface'),
        color: theme.scaffoldBackgroundColor,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              key: Key('brand-button'),
              label: 'Continuar',
              variant: AppButtonVariant.brand,
              onPressed: _noop,
            ),
            AppCard(
              key: Key('sample-card'),
              child: Text('Cartao'),
            ),
            AppTextField(
              key: Key('sample-input'),
              label: 'Servico',
            ),
          ],
        ),
      ),
    );
  }

  static void _noop() {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('legacy and U1 ThemeData expose independent visual contracts', () {
    final legacy = AppTheme.legacyLightTheme;
    final u1 = AppTheme.u1LightTheme;
    final legacyTokens = legacy.extension<ChegaJaTheme>()!;
    final u1Tokens = u1.extension<ChegaJaTheme>()!;

    expect(legacy.colorScheme.primary, const Color(0xFF12BA9B));
    expect(legacy.scaffoldBackgroundColor, const Color(0xFFF6F8F8));
    expect(legacyTokens.designSystem, ChegaJaDesignSystem.legacy);
    expect(legacyTokens.radiusMd, 12);
    expect(legacyTokens.radiusLg, 16);
    expect(legacyTokens.inputMd, 48);
    expect(legacyTokens.buttonMd, 44);
    expect(legacyTokens.brandGradientEnabled, isFalse);
    expect(legacy.navigationBarTheme.elevation, AppElevation.level3);
    expect(legacy.iconButtonTheme.style, isNull);
    expect(legacy.switchTheme.thumbColor, isNull);
    expect(legacy.switchTheme.trackColor, isNull);
    expect(legacy.checkboxTheme.fillColor, isNull);
    expect(legacy.radioTheme.fillColor, isNull);
    expect(legacy.dialogTheme.shape, isNull);
    expect(legacy.bottomSheetTheme.showDragHandle, isNull);
    expect(legacy.tooltipTheme.decoration, isNull);
    expect(legacy.progressIndicatorTheme.color, isNull);
    expect(legacy.popupMenuTheme.shape, isNull);

    expect(u1.colorScheme.primary, AppPalette.u1Primary);
    expect(u1.scaffoldBackgroundColor, AppPalette.u1LightBg);
    expect(u1Tokens.designSystem, ChegaJaDesignSystem.u1);
    expect(u1Tokens.radiusMd, 16);
    expect(u1Tokens.radiusLg, 20);
    expect(u1Tokens.inputMd, 52);
    expect(u1Tokens.buttonMd, 52);
    expect(u1Tokens.brandGradientEnabled, isTrue);
    expect(u1.navigationBarTheme.elevation, AppElevation.level2);
    expect(u1.iconButtonTheme.style, isNotNull);
    expect(u1.switchTheme.thumbColor, isNotNull);
    expect(u1.checkboxTheme.fillColor, isNotNull);
    expect(u1.dialogTheme.shape, isNotNull);
    expect(u1.bottomSheetTheme.showDragHandle, isTrue);
    expect(u1.tooltipTheme.decoration, isNotNull);
    expect(u1.progressIndicatorTheme.color, AppPalette.u1Primary);
    expect(u1.popupMenuTheme.shape, isNotNull);

    final legacyCardShape = legacy.cardTheme.shape! as RoundedRectangleBorder;
    final u1CardShape = u1.cardTheme.shape! as RoundedRectangleBorder;
    expect(legacyCardShape.borderRadius, BorderRadius.circular(16));
    expect(u1CardShape.borderRadius, BorderRadius.circular(20));

    final legacyInput =
        legacy.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
    final u1Input =
        u1.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
    expect(legacyInput.borderRadius, BorderRadius.circular(12));
    expect(u1Input.borderRadius, BorderRadius.circular(16));

    final legacyButton = legacy.elevatedButtonTheme.style!;
    final u1Button = u1.elevatedButtonTheme.style!;
    expect(legacyButton.minimumSize!.resolve({}), const Size(0, 44));
    expect(u1Button.minimumSize!.resolve({}), const Size(0, 52));
    expect(
      (legacyButton.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(10),
    );
    expect(
      (u1Button.shape!.resolve({})! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(16),
    );
  });

  testWidgets(
    'single U1 flag atomically rebuilds rendered theme and components',
    (tester) async {
      final flags = FeatureFlagService(
        initialSnapshot: _snapshot(u1Enabled: false),
      );
      final roleMode = RoleModeService.forTesting();
      await roleMode.load();

      await tester.pumpWidget(
        ChegaJaApp(
          roleModeService: roleMode,
          featureFlagService: flags,
          roleSelectorBuilder: (_) => const _VisualProbe(),
        ),
      );
      await tester.pumpAndSettle();

      _expectRenderedDesign(tester, usesU1: false);

      flags.applySnapshot(_snapshot(u1Enabled: true));
      await tester.pumpAndSettle();

      _expectRenderedDesign(tester, usesU1: true);

      flags.applySnapshot(_snapshot(u1Enabled: false));
      await tester.pumpAndSettle();

      _expectRenderedDesign(tester, usesU1: false);
    },
  );
}

void _expectRenderedDesign(
  WidgetTester tester, {
  required bool usesU1,
}) {
  final probeContext = tester.element(find.byKey(const Key('theme-surface')));
  final theme = Theme.of(probeContext);
  final visualTokens = theme.extension<ChegaJaTheme>()!;
  expect(visualTokens.usesU1, usesU1);

  final surface = tester.widget<ColoredBox>(
    find.byKey(const Key('theme-surface')),
  );
  expect(
    surface.color,
    usesU1 ? AppPalette.u1LightBg : AppPalette.lightBg,
  );

  final buttonScope = find.byKey(const Key('brand-button'));
  final elevated = tester.widget<ElevatedButton>(
    find.descendant(
      of: buttonScope,
      matching: find.byType(ElevatedButton),
    ),
  );
  expect(
    elevated.style?.minimumSize?.resolve({}),
    Size(0, usesU1 ? 52 : 44),
  );

  final buttonDecoration = tester.widget<DecoratedBox>(
    find.descendant(
      of: buttonScope,
      matching: find.byType(DecoratedBox),
    ),
  );
  final boxDecoration = buttonDecoration.decoration as BoxDecoration;
  expect(boxDecoration.gradient, usesU1 ? isNotNull : isNull);
  expect(
    boxDecoration.color,
    usesU1 ? isNull : AppPalette.primary,
  );
  expect(
    boxDecoration.borderRadius,
    BorderRadius.circular(usesU1 ? 16 : 12),
  );

  final cardContainer = tester.widget<Container>(
    find.descendant(
      of: find.byKey(const Key('sample-card')),
      matching: find.byType(Container),
    ),
  );
  final cardDecoration = cardContainer.decoration! as BoxDecoration;
  expect(
    cardDecoration.borderRadius,
    BorderRadius.circular(usesU1 ? 20 : 16),
  );

  final inputDecorator = tester.widget<InputDecorator>(
    find.descendant(
      of: find.byKey(const Key('sample-input')),
      matching: find.byType(InputDecorator),
    ),
  );
  expect(
    inputDecorator.decoration.constraints?.minHeight,
    usesU1 ? 52 : 48,
  );
  final inputBorder =
      inputDecorator.decoration.enabledBorder! as OutlineInputBorder;
  expect(
    inputBorder.borderRadius,
    BorderRadius.circular(usesU1 ? 16 : 12),
  );
}
