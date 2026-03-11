import 'package:flutter/material.dart';

/// Shared design tokens extracted from Stitch exemplars and normalized
/// for Flutter Material 3 usage (mobile + desktop).
class AppTokens {
  AppTokens._();
}

class AppPalette {
  AppPalette._();

  // Brand accents
  static const Color primary = Color(0xFF12BA9B);
  static const Color primaryHover = Color(0xFF0FA98C);
  static const Color primaryPressed = Color(0xFF0C8E77);
  static const Color primaryDisabled = Color(0xFF9FDFD1);

  static const Color secondary = Color(0xFF0B3C5D);
  static const Color secondaryHover = Color(0xFF09324E);
  static const Color secondaryPressed = Color(0xFF07293F);
  static const Color secondaryDisabled = Color(0xFF9FB4C3);

  static const Color accentBlue = Color(0xFF1E7BFF);
  static const Color accentCoral = Color(0xFFFF5A5F);
  static const Color accentSun = Color(0xFFFFC247);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Light mode
  static const Color lightBg = Color(0xFFF6F8F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEF3F5);
  static const Color lightTextPrimary = Color(0xFF111418);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0x1A111418);

  // Dark mode
  static const Color darkBg = Color(0xFF101922);
  static const Color darkSurface = Color(0xFF16202A);
  static const Color darkSurfaceAlt = Color(0xFF1F2B36);
  static const Color darkTextPrimary = Color(0xFFF3F7FA);
  static const Color darkTextSecondary = Color(0xFFA9B6C3);
  static const Color darkBorder = Color(0x1FF3F7FA);
}

class AppSpacing {
  AppSpacing._();

  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 32;
  static const double x8 = 40;
  static const double x9 = 48;
}

class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double sheetTop = 40;
}

class AppElevation {
  AppElevation._();

  static const double level1 = 1;
  static const double level2 = 4;
  static const double level3 = 8;
  static const double level4 = 16;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x14111418),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x1F111418),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color(0x29111418),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> level4 = [
    BoxShadow(
      color: Color(0x33111418),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];
}

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  // Display
  static const double displayLgSize = 34;
  static const double displayLgHeight = 40 / 34;
  static const FontWeight displayLgWeight = FontWeight.w800;

  static const double displayMdSize = 30;
  static const double displayMdHeight = 36 / 30;
  static const FontWeight displayMdWeight = FontWeight.w700;

  // Title
  static const double titleLgSize = 24;
  static const double titleLgHeight = 30 / 24;
  static const FontWeight titleLgWeight = FontWeight.w700;

  static const double titleMdSize = 20;
  static const double titleMdHeight = 26 / 20;
  static const FontWeight titleMdWeight = FontWeight.w700;

  // Body
  static const double bodyLgSize = 16;
  static const double bodyLgHeight = 24 / 16;
  static const FontWeight bodyLgWeight = FontWeight.w500;

  static const double bodyMdSize = 14;
  static const double bodyMdHeight = 20 / 14;
  static const FontWeight bodyMdWeight = FontWeight.w400;

  // Label
  static const double labelLgSize = 14;
  static const double labelLgHeight = 18 / 14;
  static const FontWeight labelLgWeight = FontWeight.w600;

  static const double labelMdSize = 12;
  static const double labelMdHeight = 16 / 12;
  static const FontWeight labelMdWeight = FontWeight.w600;
}

class AppSizes {
  AppSizes._();

  static const double minTapTarget = 48;
  static const double inputSm = 40;
  static const double inputMd = 48;
  static const double inputLg = 56;

  static const double buttonSm = 36;
  static const double buttonMd = 44;
  static const double buttonLg = 52;

  static const double listTileMin = 56;
  static const double topBarHeight = 56;
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 599;
  static const double tabletMax = 1023;
  static const double desktopMin = 1024;

  static const double contentMaxSingleColumn = 480;
  static const double contentMaxTwoColumn = 960;
}
