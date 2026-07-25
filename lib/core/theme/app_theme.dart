import 'package:flutter/material.dart';

import 'app_theme_extension.dart';
import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData legacyLightTheme = _buildTheme(
    Brightness.light,
    useU1: false,
  );
  static final ThemeData legacyDarkTheme = _buildTheme(
    Brightness.dark,
    useU1: false,
  );
  static final ThemeData u1LightTheme = _buildTheme(
    Brightness.light,
    useU1: true,
  );
  static final ThemeData u1DarkTheme = _buildTheme(
    Brightness.dark,
    useU1: true,
  );

  /// Backwards-compatible aliases for code and tests written during U1.
  static final ThemeData lightTheme = u1LightTheme;
  static final ThemeData darkTheme = u1DarkTheme;

  static ThemeData _buildTheme(
    Brightness brightness, {
    required bool useU1,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final visualTokens = useU1
        ? (isDark ? ChegaJaTheme.u1Dark : ChegaJaTheme.u1Light)
        : (isDark ? ChegaJaTheme.legacyDark : ChegaJaTheme.legacyLight);

    final primary = visualTokens.primary;
    final primaryHover = visualTokens.primaryHover;
    final primaryPressed = visualTokens.primaryPressed;
    final primaryDisabled = visualTokens.primaryDisabled;
    final secondary = visualTokens.secondary;
    final secondaryHover = visualTokens.secondaryHover;
    final secondaryPressed = visualTokens.secondaryPressed;
    final secondaryDisabled = visualTokens.secondaryDisabled;
    final background = useU1
        ? (isDark ? AppPalette.u1DarkBg : AppPalette.u1LightBg)
        : (isDark ? AppPalette.darkBg : AppPalette.lightBg);
    final surface = useU1
        ? (isDark ? AppPalette.u1DarkSurface : AppPalette.u1LightSurface)
        : (isDark ? AppPalette.darkSurface : AppPalette.lightSurface);
    final surfaceAlt = useU1
        ? (isDark ? AppPalette.u1DarkSurfaceAlt : AppPalette.u1LightSurfaceAlt)
        : (isDark ? AppPalette.darkSurfaceAlt : AppPalette.lightSurfaceAlt);
    final textPrimary = useU1
        ? (isDark
            ? AppPalette.u1DarkTextPrimary
            : AppPalette.u1LightTextPrimary)
        : (isDark ? AppPalette.darkTextPrimary : AppPalette.lightTextPrimary);
    final textSecondary = useU1
        ? (isDark
            ? AppPalette.u1DarkTextSecondary
            : AppPalette.u1LightTextSecondary)
        : (isDark
            ? AppPalette.darkTextSecondary
            : AppPalette.lightTextSecondary);
    final decorativeBorder = useU1
        ? (isDark ? AppPalette.u1DarkBorder : AppPalette.u1LightBorder)
        : (isDark ? AppPalette.darkBorder : AppPalette.lightBorder);
    final controlOutline = useU1
        ? (isDark
            ? AppPalette.u1DarkControlOutline
            : AppPalette.u1LightControlOutline)
        : decorativeBorder;
    final tertiary = useU1
        ? (isDark ? const Color(0xFFA7D0FF) : AppPalette.u1AccentBlue)
        : AppPalette.accentBlue;
    final error = useU1
        ? (isDark ? const Color(0xFFFFB4AB) : AppPalette.u1Error)
        : AppPalette.error;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );

    final scheme = baseScheme.copyWith(
      primary: primary,
      onPrimary: useU1 && isDark ? AppPalette.brandPlum : Colors.white,
      secondary: secondary,
      onSecondary: useU1 && isDark ? AppPalette.brandPlum : Colors.white,
      tertiary: tertiary,
      onTertiary: useU1 && isDark ? const Color(0xFF102A43) : Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceAlt,
      onSurfaceVariant: textSecondary,
      outline: controlOutline,
      outlineVariant: useU1 ? decorativeBorder : null,
      error: error,
      onError: useU1 && isDark ? const Color(0xFF4D2024) : Colors.white,
    );

    final textTheme = _buildTextTheme(textPrimary, textSecondary);
    final secondaryAction = secondary;
    final secondaryActionHover = secondaryHover;
    final secondaryActionPressed = secondaryPressed;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      extensions: [
        visualTokens,
      ],
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      dividerColor: decorativeBorder,
      focusColor: useU1 ? visualTokens.focusRing : null,
      hoverColor: useU1 ? scheme.primary.withValues(alpha: 0.08) : null,
      disabledColor: useU1
          ? scheme.onSurface.withValues(alpha: AppOpacity.disabled)
          : null,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: AppElevation.level2,
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(visualTokens.radiusLg),
          side: BorderSide(color: decorativeBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isDark ? surfaceAlt : surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        helperStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.labelMedium?.copyWith(
          color: scheme.error,
        ),
        border: _outlinedBorder(
          scheme.outline,
          radius: visualTokens.radiusMd,
        ),
        enabledBorder: _outlinedBorder(
          scheme.outline,
          radius: visualTokens.radiusMd,
        ),
        focusedBorder: _outlinedBorder(
          scheme.primary,
          radius: visualTokens.radiusMd,
          width: 1.6,
        ),
        errorBorder: _outlinedBorder(
          scheme.error,
          radius: visualTokens.radiusMd,
        ),
        focusedErrorBorder: _outlinedBorder(
          scheme.error,
          radius: visualTokens.radiusMd,
          width: 1.6,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(0, visualTokens.buttonMd),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.x5,
              vertical: AppSpacing.x3,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                useU1 ? visualTokens.radiusMd : visualTokens.radiusSm,
              ),
            ),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) {
              return AppElevation.level1;
            }
            return AppElevation.level2;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return primaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return primaryPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return primaryHover;
            }
            return primary;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(0, visualTokens.buttonMd),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.x5,
              vertical: AppSpacing.x3,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                useU1 ? visualTokens.radiusMd : visualTokens.radiusSm,
              ),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: secondaryDisabled);
            }
            if (states.contains(WidgetState.pressed)) {
              return BorderSide(color: secondaryActionPressed);
            }
            if (states.contains(WidgetState.hovered)) {
              return BorderSide(color: secondaryActionHover);
            }
            return BorderSide(color: secondaryAction);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return secondaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return secondaryActionPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return secondaryActionHover;
            }
            return secondaryAction;
          }),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(0, visualTokens.buttonSm),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                useU1 ? visualTokens.radiusMd : visualTokens.radiusSm,
              ),
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurfaceVariant;
            }
            if (states.contains(WidgetState.pressed)) {
              return primaryPressed;
            }
            return primary;
          }),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? surfaceAlt : surface,
        disabledColor: decorativeBorder,
        selectedColor: primary.withValues(alpha: 0.18),
        secondarySelectedColor: primary.withValues(alpha: 0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: useU1 ? scheme.outline : decorativeBorder,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x1,
        ),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium,
        brightness: brightness,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelMedium,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: decorativeBorder,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x1,
        ),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(visualTokens.radiusMd),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: AppElevation.level3,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: useU1 ? AppElevation.level2 : AppElevation.level3,
        height: AppSizes.compactNavigationHeight,
        indicatorColor: primary.withValues(alpha: useU1 ? 0.14 : 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return (isSelected
                  ? textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)
                  : textTheme.labelMedium)
              ?.copyWith(
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        indicatorColor: primary.withValues(alpha: 0.16),
        useIndicator: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(visualTokens.radiusLg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? surfaceAlt : secondary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(visualTokens.radiusMd),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: decorativeBorder,
        thickness: 1,
      ),
      iconButtonTheme: useU1
          ? IconButtonThemeData(
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(
                  Size.square(AppSizes.iconButton),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(visualTokens.radiusMd),
                  ),
                ),
              ),
            )
          : null,
      switchTheme: useU1
          ? SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.onSurface.withValues(alpha: 0.38);
                }
                if (states.contains(WidgetState.selected)) {
                  return scheme.onPrimary;
                }
                return scheme.onSurfaceVariant;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.onSurface.withValues(alpha: 0.12);
                }
                if (states.contains(WidgetState.selected)) {
                  return scheme.primary;
                }
                return scheme.surfaceContainerHighest;
              }),
            )
          : null,
      checkboxTheme: useU1
          ? CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return scheme.primary;
                }
                return Colors.transparent;
              }),
              checkColor: WidgetStatePropertyAll(scheme.onPrimary),
              side: BorderSide(color: scheme.outline, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visualTokens.radiusXs / 2),
              ),
            )
          : null,
      radioTheme: useU1
          ? RadioThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return scheme.primary;
                }
                return scheme.onSurfaceVariant;
              }),
            )
          : null,
      dialogTheme: useU1
          ? DialogThemeData(
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visualTokens.radiusXl),
              ),
            )
          : null,
      bottomSheetTheme: useU1
          ? BottomSheetThemeData(
              backgroundColor: scheme.surface,
              modalBackgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              showDragHandle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sheetTop),
                ),
              ),
            )
          : null,
      tooltipTheme: useU1
          ? TooltipThemeData(
              decoration: BoxDecoration(
                color: useU1
                    ? (isDark
                        ? AppPalette.u1DarkTextPrimary
                        : AppPalette.brandPlum)
                    : (isDark
                        ? AppPalette.darkTextPrimary
                        : AppPalette.secondary),
                borderRadius: BorderRadius.circular(visualTokens.radiusSm),
              ),
              textStyle: textTheme.labelMedium?.copyWith(
                color: isDark
                    ? (useU1 ? AppPalette.brandPlum : AppPalette.darkBg)
                    : Colors.white,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x3,
                vertical: AppSpacing.x2,
              ),
            )
          : null,
      progressIndicatorTheme: useU1
          ? ProgressIndicatorThemeData(
              color: scheme.primary,
              linearTrackColor: scheme.surfaceContainerHighest,
              circularTrackColor: scheme.surfaceContainerHighest,
            )
          : null,
      popupMenuTheme: useU1
          ? PopupMenuThemeData(
              color: scheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(visualTokens.radiusMd),
              ),
            )
          : null,
    );
  }

  static TextTheme _buildTextTheme(Color textPrimary, Color textSecondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: AppTypography.displayLgSize,
        height: AppTypography.displayLgHeight,
        fontWeight: AppTypography.displayLgWeight,
        color: textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: AppTypography.displayMdSize,
        height: AppTypography.displayMdHeight,
        fontWeight: AppTypography.displayMdWeight,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: AppTypography.titleLgSize,
        height: AppTypography.titleLgHeight,
        fontWeight: AppTypography.titleLgWeight,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: AppTypography.titleMdSize,
        height: AppTypography.titleMdHeight,
        fontWeight: AppTypography.titleMdWeight,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: AppTypography.bodyLgSize,
        height: AppTypography.bodyLgHeight,
        fontWeight: AppTypography.bodyLgWeight,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTypography.bodyMdSize,
        height: AppTypography.bodyMdHeight,
        fontWeight: AppTypography.bodyMdWeight,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: AppTypography.labelLgSize,
        height: AppTypography.labelLgHeight,
        fontWeight: AppTypography.labelLgWeight,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: AppTypography.labelMdSize,
        height: AppTypography.labelMdHeight,
        fontWeight: AppTypography.labelMdWeight,
        color: textSecondary,
      ),
    );
  }

  static OutlineInputBorder _outlinedBorder(
    Color color, {
    required double radius,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
