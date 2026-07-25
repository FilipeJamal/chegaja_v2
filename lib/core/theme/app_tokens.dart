import 'package:flutter/material.dart';

/// Canonical ChegaJá 2.0 design tokens for Android, web and desktop.
class AppTokens {
  AppTokens._();
}

class AppPalette {
  AppPalette._();

  // Legacy aliases are deliberately kept identical to the pre-U1 design
  // system. Code that has not opted into U1 must never inherit the new brand
  // merely because the new tokens exist in the binary.
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
  static const Color info = accentBlue;

  static const Color lightBg = Color(0xFFF6F8F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEF3F5);
  static const Color lightTextPrimary = Color(0xFF111418);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0x1A111418);

  static const Color darkBg = Color(0xFF101922);
  static const Color darkSurface = Color(0xFF16202A);
  static const Color darkSurfaceAlt = Color(0xFF1F2B36);
  static const Color darkTextPrimary = Color(0xFFF3F7FA);
  static const Color darkTextSecondary = Color(0xFFA9B6C3);
  static const Color darkBorder = Color(0x1FF3F7FA);

  // U1 / Design System 2.0 brand identity. Orange and magenta are expressive
  // accents; the darker purple is the functional primary because it keeps
  // white text accessible.
  static const Color brandOrange = Color(0xFFF26A2E);
  static const Color brandCoral = Color(0xFFD93663);
  static const Color brandMagenta = Color(0xFFC32A83);
  static const Color brandPurple = Color(0xFF6D3BD1);
  static const Color brandPlum = Color(0xFF2B184A);

  static const Color u1Primary = brandPurple;
  static const Color u1PrimaryHover = Color(0xFF5C2ABF);
  static const Color u1PrimaryPressed = Color(0xFF4B209F);
  static const Color u1PrimaryDisabled = Color(0xFFC8B9E9);

  static const Color u1Secondary = brandPlum;
  static const Color u1SecondaryHover = Color(0xFF211137);
  static const Color u1SecondaryPressed = Color(0xFF180B2A);
  static const Color u1SecondaryDisabled = Color(0xFFB8AFBF);

  static const Color u1AccentBlue = Color(0xFF2D6CDF);
  static const Color u1AccentCoral = brandCoral;
  static const Color u1AccentSun = Color(0xFFE6A000);
  static const Color u1AccentTeal = Color(0xFF14866D);

  static const Color u1Success = Color(0xFF14804A);
  static const Color u1Warning = Color(0xFF9A5B00);
  static const Color u1Error = Color(0xFFB42318);
  static const Color u1Info = u1AccentBlue;

  // U1 light mode
  static const Color u1LightBg = Color(0xFFFFF9F6);
  static const Color u1LightSurface = Color(0xFFFFFFFF);
  static const Color u1LightSurfaceAlt = Color(0xFFF7EFEA);
  static const Color u1LightSurfaceStrong = Color(0xFFF0E4DE);
  static const Color u1LightTextPrimary = Color(0xFF241A2B);
  static const Color u1LightTextSecondary = Color(0xFF6F6374);
  // Opaque interactive boundary. It keeps at least 3:1 contrast on both the
  // main surface and the filled input surface.
  static const Color u1LightControlOutline = Color(0xFF918397);
  // Decorative separation may remain subtle because it is not the only cue
  // for an interactive control.
  static const Color u1LightBorder = Color(0x242B184A);
  static const Color u1LightFocus = Color(0xFF4D2EAF);
  static const Color u1LightSkeleton = Color(0xFFEDE3DF);
  static const Color u1LightSkeletonHighlight = Color(0xFFF9F3F0);

  // U1 dark mode
  static const Color u1DarkBg = Color(0xFF17111C);
  static const Color u1DarkSurface = Color(0xFF211828);
  static const Color u1DarkSurfaceAlt = Color(0xFF2B2033);
  static const Color u1DarkSurfaceStrong = Color(0xFF382941);
  static const Color u1DarkTextPrimary = Color(0xFFFFF8FC);
  static const Color u1DarkTextSecondary = Color(0xFFC9BDCE);
  static const Color u1DarkControlOutline = Color(0xFF827489);
  static const Color u1DarkBorder = Color(0x33FFF8FC);
  static const Color u1DarkFocus = Color(0xFFD8C5FF);
  static const Color u1DarkSkeleton = Color(0xFF35283D);
  static const Color u1DarkSkeletonHighlight = Color(0xFF44334D);
}

class AppGradients {
  AppGradients._();

  /// Decorative brand gradient. Do not place small white copy over the orange
  /// stop; use [primaryAction] for interactive surfaces.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppPalette.brandOrange,
      AppPalette.brandMagenta,
      AppPalette.brandPurple,
    ],
  );

  /// Accessible action gradient: every stop is dark enough for bold white
  /// button text at the supported sizes.
  static const LinearGradient primaryAction = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFB72A58),
      Color(0xFF8A2E91),
      Color(0xFF5930B8),
    ],
  );

  static const LinearGradient softBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFEFE5),
      Color(0xFFFFEAF3),
      Color(0xFFF0EAFF),
    ],
  );
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

  static const double u1Xs = 8;
  static const double u1Sm = 12;
  static const double u1Md = 16;
  static const double u1Lg = 20;
  static const double u1Xl = 28;
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

  static const List<BoxShadow> u1Level1 = [
    BoxShadow(
      color: Color(0x102B184A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> u1Level2 = [
    BoxShadow(
      color: Color(0x182B184A),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> u1Level3 = [
    BoxShadow(
      color: Color(0x242B184A),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> u1Level4 = [
    BoxShadow(
      color: Color(0x302B184A),
      blurRadius: 40,
      offset: Offset(0, 18),
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

  static const double u1InputSm = 48;
  static const double u1InputMd = 52;
  static const double u1InputLg = 56;

  static const double u1ButtonSm = 48;
  static const double u1ButtonMd = 52;
  static const double u1ButtonLg = 56;

  static const double listTileMin = 56;
  static const double topBarHeight = 56;
  static const double compactNavigationHeight = 72;
  static const double iconButton = 48;
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileMax = 599;
  static const double tabletMin = 600;
  static const double tabletMax = 1023;
  static const double desktopMin = 1024;
  static const double wideDesktopMin = 1280;

  static const double contentMaxSingleColumn = 520;
  static const double contentMaxTwoColumn = 960;
  static const double contentMaxDashboard = 1180;
  static const double contentMaxWide = 1320;
}

class AppLayout {
  AppLayout._();

  static const double mobileHorizontalPadding = AppSpacing.x4;
  static const double tabletHorizontalPadding = AppSpacing.x6;
  static const double desktopHorizontalPadding = AppSpacing.x7;

  static const double desktopSidePanelWidth = 360;
  static const double desktopRailGap = AppSpacing.x6;
  static const double sectionGap = AppSpacing.x5;
  static const double pageGap = AppSpacing.x7;
}

class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 180);
  static const Duration deliberate = Duration(milliseconds: 260);
  static const Curve standardCurve = Curves.easeOutCubic;
}

class AppOpacity {
  AppOpacity._();

  static const double disabled = 0.48;
  static const double subtle = 0.12;
  static const double selected = 0.16;
}

class AppFocus {
  AppFocus._();

  static const double ringWidth = 3;
  static const double ringGap = 2;
}
