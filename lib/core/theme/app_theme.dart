import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = _buildTheme(Brightness.light);
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: brightness,
    );

    final scheme = baseScheme.copyWith(
      primary: AppPalette.primary,
      onPrimary: Colors.white,
      secondary: AppPalette.secondary,
      onSecondary: Colors.white,
      tertiary: AppPalette.accentBlue,
      onTertiary: Colors.white,
      surface: isDark ? AppPalette.darkSurface : AppPalette.lightSurface,
      onSurface:
          isDark ? AppPalette.darkTextPrimary : AppPalette.lightTextPrimary,
      surfaceContainerHighest:
          isDark ? AppPalette.darkSurfaceAlt : AppPalette.lightSurfaceAlt,
      onSurfaceVariant:
          isDark ? AppPalette.darkTextSecondary : AppPalette.lightTextSecondary,
      outline: isDark ? AppPalette.darkBorder : AppPalette.lightBorder,
      error: AppPalette.error,
      onError: Colors.white,
    );

    final textTheme = _buildTextTheme(
      isDark ? AppPalette.darkTextPrimary : AppPalette.lightTextPrimary,
      isDark ? AppPalette.darkTextSecondary : AppPalette.lightTextSecondary,
    );

    final dividerColor =
        isDark ? AppPalette.darkBorder : AppPalette.lightBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: isDark ? AppPalette.darkBg : AppPalette.lightBg,
      textTheme: textTheme,
      dividerColor: dividerColor,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppPalette.darkBg : AppPalette.lightBg,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: AppElevation.level2,
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: dividerColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isDark ? AppPalette.darkSurfaceAlt : AppPalette.lightSurface,
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
        border: _outlinedBorder(scheme.outline),
        enabledBorder: _outlinedBorder(scheme.outline),
        focusedBorder: _outlinedBorder(scheme.primary, width: 1.6),
        errorBorder: _outlinedBorder(scheme.error),
        focusedErrorBorder: _outlinedBorder(scheme.error, width: 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSizes.buttonMd),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.x5,
              vertical: AppSpacing.x3,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
              return AppPalette.primaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppPalette.primaryPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppPalette.primaryHover;
            }
            return AppPalette.primary;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSizes.buttonMd),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.x5,
              vertical: AppSpacing.x3,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppPalette.secondaryDisabled);
            }
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(color: AppPalette.secondaryPressed);
            }
            if (states.contains(WidgetState.hovered)) {
              return const BorderSide(color: AppPalette.secondaryHover);
            }
            return const BorderSide(color: AppPalette.secondary);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppPalette.secondaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppPalette.secondaryPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppPalette.secondaryHover;
            }
            return AppPalette.secondary;
          }),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSizes.buttonSm),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurfaceVariant;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppPalette.primaryPressed;
            }
            return AppPalette.primary;
          }),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppPalette.darkSurfaceAlt : AppPalette.lightSurface,
        disabledColor: isDark ? AppPalette.darkBorder : AppPalette.lightBorder,
        selectedColor: AppPalette.primary.withValues(alpha: 0.18),
        secondarySelectedColor: AppPalette.primary.withValues(alpha: 0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: dividerColor),
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
        dividerColor: dividerColor,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x1,
        ),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
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
        elevation: AppElevation.level3,
        height: 72,
        indicatorColor: AppPalette.primary.withValues(alpha: 0.16),
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
        indicatorColor: AppPalette.primary.withValues(alpha: 0.16),
        useIndicator: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? AppPalette.darkSurfaceAlt : AppPalette.secondary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
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
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
