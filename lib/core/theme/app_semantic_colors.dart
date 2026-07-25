import 'package:flutter/material.dart';

import 'app_theme_extension.dart';
import 'app_tokens.dart';

enum AppStatusTone { neutral, info, success, warning, danger }

@immutable
class AppToneColors {
  const AppToneColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

/// Accessible, opaque color pairs for semantic and selectable surfaces.
///
/// Keeping these pairs in one place prevents components from tinting a dark
/// surface with a light-mode foreground and silently losing contrast.
abstract final class AppSemanticColors {
  static ChegaJaTheme _visualTokens(ThemeData theme) =>
      theme.extension<ChegaJaTheme>() ??
      (theme.brightness == Brightness.dark
          ? ChegaJaTheme.legacyDark
          : ChegaJaTheme.legacyLight);

  static AppToneColors status(ThemeData theme, AppStatusTone tone) {
    final isDark = theme.brightness == Brightness.dark;
    if (isDark) {
      return switch (tone) {
        AppStatusTone.info => const AppToneColors(
            foreground: Color(0xFFA7D0FF),
            background: Color(0xFF1C2E4D),
            border: Color(0xFF6EA8E6),
          ),
        AppStatusTone.success => const AppToneColors(
            foreground: Color(0xFF8CF2B3),
            background: Color(0xFF163A2A),
            border: Color(0xFF55C987),
          ),
        AppStatusTone.warning => const AppToneColors(
            foreground: Color(0xFFFFD978),
            background: Color(0xFF3D2F16),
            border: Color(0xFFD6A934),
          ),
        AppStatusTone.danger => const AppToneColors(
            foreground: Color(0xFFFFB4AB),
            background: Color(0xFF4D2024),
            border: Color(0xFFE27B79),
          ),
        AppStatusTone.neutral => AppToneColors(
            foreground: theme.colorScheme.onSurfaceVariant,
            background: theme.colorScheme.surfaceContainerHighest,
            border: theme.colorScheme.outline,
          ),
      };
    }

    return switch (tone) {
      AppStatusTone.info => const AppToneColors(
          foreground: Color(0xFF2459B8),
          background: Color(0xFFEAF1FF),
          border: Color(0xFF2459B8),
        ),
      AppStatusTone.success => const AppToneColors(
          foreground: Color(0xFF0D6A3B),
          background: Color(0xFFE7F6ED),
          border: Color(0xFF0D6A3B),
        ),
      AppStatusTone.warning => const AppToneColors(
          foreground: Color(0xFF774500),
          background: Color(0xFFFFF3D8),
          border: Color(0xFF774500),
        ),
      AppStatusTone.danger => const AppToneColors(
          foreground: Color(0xFF9B1C13),
          background: Color(0xFFFFE9E7),
          border: Color(0xFF9B1C13),
        ),
      AppStatusTone.neutral => AppToneColors(
          foreground: theme.colorScheme.onSurfaceVariant,
          background: theme.colorScheme.surfaceContainerHighest,
          border: theme.colorScheme.outline,
        ),
    };
  }

  static AppToneColors primarySelection(ThemeData theme) {
    final visualTokens = _visualTokens(theme);
    if (!visualTokens.usesU1) {
      return AppToneColors(
        foreground: AppPalette.primaryPressed,
        background: theme.brightness == Brightness.dark
            ? const Color(0xFF153C39)
            : const Color(0xFFE5F8F4),
        border: AppPalette.primaryPressed,
      );
    }
    if (theme.brightness == Brightness.dark) {
      return const AppToneColors(
        foreground: Color(0xFFE2D6FF),
        background: Color(0xFF382E51),
        border: Color(0xFF9E7DE8),
      );
    }
    return const AppToneColors(
      foreground: AppPalette.u1PrimaryPressed,
      background: Color(0xFFF0EAFF),
      border: Color(0xFF8E6ADD),
    );
  }

  static AppToneColors secondarySelection(ThemeData theme) {
    final visualTokens = _visualTokens(theme);
    if (!visualTokens.usesU1) {
      return AppToneColors(
        foreground: theme.brightness == Brightness.dark
            ? AppPalette.darkTextPrimary
            : AppPalette.secondary,
        background: theme.brightness == Brightness.dark
            ? AppPalette.darkSurfaceAlt
            : AppPalette.lightSurfaceAlt,
        border: theme.brightness == Brightness.dark
            ? AppPalette.darkTextSecondary
            : AppPalette.secondary,
      );
    }
    if (theme.brightness == Brightness.dark) {
      return const AppToneColors(
        foreground: AppPalette.u1DarkTextPrimary,
        background: Color(0xFF3A2D45),
        border: Color(0xFFA895B4),
      );
    }
    return const AppToneColors(
      foreground: AppPalette.u1Secondary,
      background: Color(0xFFF1E9F5),
      border: Color(0xFF806B8D),
    );
  }

  static Color secondaryActionForeground(ThemeData theme) {
    final visualTokens = _visualTokens(theme);
    if (!visualTokens.usesU1 && theme.brightness == Brightness.dark) {
      return AppPalette.accentBlue;
    }
    return visualTokens.secondary;
  }

  static Color secondaryActionHover(ThemeData theme) {
    final visualTokens = _visualTokens(theme);
    if (!visualTokens.usesU1 && theme.brightness == Brightness.dark) {
      return const Color(0xFF60A5FA);
    }
    return visualTokens.secondaryHover;
  }

  static Color secondaryActionPressed(ThemeData theme) {
    final visualTokens = _visualTokens(theme);
    if (!visualTokens.usesU1 && theme.brightness == Brightness.dark) {
      return const Color(0xFF3B82F6);
    }
    return visualTokens.secondaryPressed;
  }

  static Color ghostActionForeground(ThemeData theme) =>
      _visualTokens(theme).primary;

  static Color ghostActionPressed(ThemeData theme) =>
      _visualTokens(theme).primaryPressed;
}
