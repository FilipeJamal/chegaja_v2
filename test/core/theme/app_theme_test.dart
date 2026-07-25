import 'dart:io';

import 'package:chegaja_v2/core/theme/app_theme.dart';
import 'package:chegaja_v2/core/theme/app_theme_extension.dart';
import 'package:chegaja_v2/core/theme/app_semantic_colors.dart';
import 'package:chegaja_v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrastRatio(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme accessibility', () {
    test('functional primary and action gradient support white labels', () {
      expect(
        _contrastRatio(Colors.white, AppPalette.u1Primary),
        greaterThanOrEqualTo(4.5),
      );

      for (final color in AppGradients.primaryAction.colors) {
        expect(
          _contrastRatio(Colors.white, color),
          greaterThanOrEqualTo(4.5),
          reason: 'Every action-gradient stop must support normal white text.',
        );
      }
    });

    test('canonical text colors meet WCAG AA on their main surfaces', () {
      final combinations = <(Color, Color)>[
        (AppPalette.u1LightTextPrimary, AppPalette.u1LightBg),
        (AppPalette.u1LightTextPrimary, AppPalette.u1LightSurface),
        (AppPalette.u1LightTextSecondary, AppPalette.u1LightSurface),
        (AppPalette.u1DarkTextPrimary, AppPalette.u1DarkBg),
        (AppPalette.u1DarkTextPrimary, AppPalette.u1DarkSurface),
        (AppPalette.u1DarkTextSecondary, AppPalette.u1DarkSurface),
      ];

      for (final (foreground, background) in combinations) {
        expect(
          _contrastRatio(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason: 'Canonical body text must meet WCAG AA.',
        );
      }
    });

    test('semantic pairs remain accessible in light and dark themes', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        for (final tone in const [
          AppStatusTone.info,
          AppStatusTone.success,
          AppStatusTone.warning,
          AppStatusTone.danger,
        ]) {
          final colors = AppSemanticColors.status(theme, tone);
          expect(
            _contrastRatio(colors.foreground, colors.background),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.brightness.name}/$tone labels must meet WCAG AA.',
          );
          expect(
            _contrastRatio(colors.border, theme.colorScheme.surface),
            greaterThanOrEqualTo(3),
            reason:
                '${theme.brightness.name}/$tone boundaries must remain visible.',
          );
        }
      }
    });

    test('selected chips and outline actions remain accessible', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        for (final colors in [
          AppSemanticColors.primarySelection(theme),
          AppSemanticColors.secondarySelection(theme),
        ]) {
          expect(
            _contrastRatio(colors.foreground, colors.background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrastRatio(colors.border, theme.colorScheme.surface),
            greaterThanOrEqualTo(3),
          );
        }

        expect(
          _contrastRatio(
            AppSemanticColors.secondaryActionForeground(theme),
            theme.colorScheme.surface,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(
            AppSemanticColors.ghostActionForeground(theme),
            theme.colorScheme.surface,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    test('control outlines meet non-text contrast in both themes', () {
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        expect(
          _contrastRatio(
            theme.colorScheme.outline,
            theme.colorScheme.surface,
          ),
          greaterThanOrEqualTo(3),
          reason:
              '${theme.brightness.name} control boundaries need 3:1 contrast.',
        );
        expect(
          _contrastRatio(
            theme.colorScheme.outline,
            theme.colorScheme.surfaceContainerHighest,
          ),
          greaterThanOrEqualTo(3),
          reason: '${theme.brightness.name} filled controls need 3:1 contrast.',
        );
      }
    });

    test('decorative borders stay separate from control outlines', () {
      expect(
        AppTheme.lightTheme.colorScheme.outlineVariant,
        AppPalette.u1LightBorder,
      );
      expect(
        AppTheme.darkTheme.colorScheme.outlineVariant,
        AppPalette.u1DarkBorder,
      );
      expect(
        AppTheme.lightTheme.colorScheme.outline,
        AppPalette.u1LightControlOutline,
      );
      expect(
        AppTheme.darkTheme.colorScheme.outline,
        AppPalette.u1DarkControlOutline,
      );
    });

    test('light and dark themes expose their matching ChegaJa extensions', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;
      final lightExtension = light.extension<ChegaJaTheme>();
      final darkExtension = dark.extension<ChegaJaTheme>();

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.scaffoldBackgroundColor, AppPalette.u1LightBg);
      expect(dark.scaffoldBackgroundColor, AppPalette.u1DarkBg);
      expect(lightExtension, isNotNull);
      expect(darkExtension, isNotNull);
      expect(lightExtension!.focusRing, AppPalette.u1LightFocus);
      expect(darkExtension!.focusRing, AppPalette.u1DarkFocus);
      expect(lightExtension.skeletonBase, AppPalette.u1LightSkeleton);
      expect(darkExtension.skeletonBase, AppPalette.u1DarkSkeleton);
      expect(
        lightExtension.skeletonHighlight,
        isNot(darkExtension.skeletonHighlight),
      );
    });

    test('Inter is the canonical bundled font', () {
      expect(AppTypography.fontFamily, 'Inter');
      expect(AppTheme.lightTheme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(AppTheme.darkTheme.textTheme.titleLarge?.fontFamily, 'Inter');
      expect(
        File('assets/fonts/inter/Inter-Variable.ttf').existsSync(),
        isTrue,
      );
    });
  });
}
