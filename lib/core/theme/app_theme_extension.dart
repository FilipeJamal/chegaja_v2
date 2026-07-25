import 'package:flutter/material.dart';

import 'app_tokens.dart';

enum ChegaJaDesignSystem { legacy, u1 }

@immutable
class ChegaJaTheme extends ThemeExtension<ChegaJaTheme> {
  const ChegaJaTheme({
    required this.designSystem,
    required this.brandGradientEnabled,
    required this.brandGradient,
    required this.actionGradient,
    required this.softBrandGradient,
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.primaryDisabled,
    required this.secondary,
    required this.secondaryHover,
    required this.secondaryPressed,
    required this.secondaryDisabled,
    required this.focusRing,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.successSurface,
    required this.warningSurface,
    required this.infoSurface,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.inputSm,
    required this.inputMd,
    required this.inputLg,
    required this.buttonSm,
    required this.buttonMd,
    required this.buttonLg,
    required this.shadowLevel1,
    required this.shadowLevel2,
    required this.shadowLevel3,
    required this.shadowLevel4,
  });

  final ChegaJaDesignSystem designSystem;
  final bool brandGradientEnabled;
  final LinearGradient brandGradient;
  final LinearGradient actionGradient;
  final LinearGradient softBrandGradient;
  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color primaryDisabled;
  final Color secondary;
  final Color secondaryHover;
  final Color secondaryPressed;
  final Color secondaryDisabled;
  final Color focusRing;
  final Color skeletonBase;
  final Color skeletonHighlight;
  final Color successSurface;
  final Color warningSurface;
  final Color infoSurface;
  final double radiusXs;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double inputSm;
  final double inputMd;
  final double inputLg;
  final double buttonSm;
  final double buttonMd;
  final double buttonLg;
  final List<BoxShadow> shadowLevel1;
  final List<BoxShadow> shadowLevel2;
  final List<BoxShadow> shadowLevel3;
  final List<BoxShadow> shadowLevel4;

  bool get usesU1 => designSystem == ChegaJaDesignSystem.u1;

  static const _legacyGradient = LinearGradient(
    colors: [AppPalette.primary, AppPalette.primary],
  );

  static const ChegaJaTheme legacyLight = ChegaJaTheme(
    designSystem: ChegaJaDesignSystem.legacy,
    brandGradientEnabled: false,
    brandGradient: _legacyGradient,
    actionGradient: _legacyGradient,
    softBrandGradient: LinearGradient(
      colors: [AppPalette.lightSurfaceAlt, AppPalette.lightSurfaceAlt],
    ),
    primary: AppPalette.primary,
    primaryHover: AppPalette.primaryHover,
    primaryPressed: AppPalette.primaryPressed,
    primaryDisabled: AppPalette.primaryDisabled,
    secondary: AppPalette.secondary,
    secondaryHover: AppPalette.secondaryHover,
    secondaryPressed: AppPalette.secondaryPressed,
    secondaryDisabled: AppPalette.secondaryDisabled,
    focusRing: AppPalette.primary,
    skeletonBase: AppPalette.lightSurfaceAlt,
    skeletonHighlight: AppPalette.lightSurface,
    successSurface: Color(0xFFE8F8EF),
    warningSurface: Color(0xFFFFF6E5),
    infoSurface: Color(0xFFEAF2FF),
    radiusXs: AppRadius.xs,
    radiusSm: AppRadius.sm,
    radiusMd: AppRadius.md,
    radiusLg: AppRadius.lg,
    radiusXl: AppRadius.xl,
    inputSm: AppSizes.inputSm,
    inputMd: AppSizes.inputMd,
    inputLg: AppSizes.inputLg,
    buttonSm: AppSizes.buttonSm,
    buttonMd: AppSizes.buttonMd,
    buttonLg: AppSizes.buttonLg,
    shadowLevel1: AppShadows.level1,
    shadowLevel2: AppShadows.level2,
    shadowLevel3: AppShadows.level3,
    shadowLevel4: AppShadows.level4,
  );

  static const ChegaJaTheme legacyDark = ChegaJaTheme(
    designSystem: ChegaJaDesignSystem.legacy,
    brandGradientEnabled: false,
    brandGradient: _legacyGradient,
    actionGradient: _legacyGradient,
    softBrandGradient: LinearGradient(
      colors: [AppPalette.darkSurfaceAlt, AppPalette.darkSurfaceAlt],
    ),
    primary: AppPalette.primary,
    primaryHover: AppPalette.primaryHover,
    primaryPressed: AppPalette.primaryPressed,
    primaryDisabled: AppPalette.primaryDisabled,
    secondary: AppPalette.secondary,
    secondaryHover: AppPalette.secondaryHover,
    secondaryPressed: AppPalette.secondaryPressed,
    secondaryDisabled: AppPalette.secondaryDisabled,
    focusRing: AppPalette.primary,
    skeletonBase: AppPalette.darkSurfaceAlt,
    skeletonHighlight: AppPalette.darkSurface,
    successSurface: Color(0xFF173B2B),
    warningSurface: Color(0xFF3D311A),
    infoSurface: Color(0xFF1A3150),
    radiusXs: AppRadius.xs,
    radiusSm: AppRadius.sm,
    radiusMd: AppRadius.md,
    radiusLg: AppRadius.lg,
    radiusXl: AppRadius.xl,
    inputSm: AppSizes.inputSm,
    inputMd: AppSizes.inputMd,
    inputLg: AppSizes.inputLg,
    buttonSm: AppSizes.buttonSm,
    buttonMd: AppSizes.buttonMd,
    buttonLg: AppSizes.buttonLg,
    shadowLevel1: AppShadows.level1,
    shadowLevel2: AppShadows.level2,
    shadowLevel3: AppShadows.level3,
    shadowLevel4: AppShadows.level4,
  );

  static const ChegaJaTheme u1Light = ChegaJaTheme(
    designSystem: ChegaJaDesignSystem.u1,
    brandGradientEnabled: true,
    brandGradient: AppGradients.brand,
    actionGradient: AppGradients.primaryAction,
    softBrandGradient: AppGradients.softBrand,
    primary: AppPalette.u1Primary,
    primaryHover: AppPalette.u1PrimaryHover,
    primaryPressed: AppPalette.u1PrimaryPressed,
    primaryDisabled: AppPalette.u1PrimaryDisabled,
    secondary: AppPalette.u1Secondary,
    secondaryHover: AppPalette.u1SecondaryHover,
    secondaryPressed: AppPalette.u1SecondaryPressed,
    secondaryDisabled: AppPalette.u1SecondaryDisabled,
    focusRing: AppPalette.u1LightFocus,
    skeletonBase: AppPalette.u1LightSkeleton,
    skeletonHighlight: AppPalette.u1LightSkeletonHighlight,
    successSurface: Color(0xFFE7F6ED),
    warningSurface: Color(0xFFFFF3D8),
    infoSurface: Color(0xFFEAF1FF),
    radiusXs: AppRadius.u1Xs,
    radiusSm: AppRadius.u1Sm,
    radiusMd: AppRadius.u1Md,
    radiusLg: AppRadius.u1Lg,
    radiusXl: AppRadius.u1Xl,
    inputSm: AppSizes.u1InputSm,
    inputMd: AppSizes.u1InputMd,
    inputLg: AppSizes.u1InputLg,
    buttonSm: AppSizes.u1ButtonSm,
    buttonMd: AppSizes.u1ButtonMd,
    buttonLg: AppSizes.u1ButtonLg,
    shadowLevel1: AppShadows.u1Level1,
    shadowLevel2: AppShadows.u1Level2,
    shadowLevel3: AppShadows.u1Level3,
    shadowLevel4: AppShadows.u1Level4,
  );

  static const ChegaJaTheme u1Dark = ChegaJaTheme(
    designSystem: ChegaJaDesignSystem.u1,
    brandGradientEnabled: true,
    brandGradient: AppGradients.brand,
    actionGradient: AppGradients.primaryAction,
    softBrandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF35211E),
        Color(0xFF38202F),
        Color(0xFF2C2444),
      ],
    ),
    primary: AppPalette.u1DarkFocus,
    primaryHover: Color(0xFFE9DEFF),
    primaryPressed: Color(0xFFF2EAFF),
    primaryDisabled: AppPalette.u1PrimaryDisabled,
    secondary: Color(0xFFE2D6FF),
    secondaryHover: Color(0xFFC5E0FF),
    secondaryPressed: Color(0xFFD8E9FF),
    secondaryDisabled: AppPalette.u1SecondaryDisabled,
    focusRing: AppPalette.u1DarkFocus,
    skeletonBase: AppPalette.u1DarkSkeleton,
    skeletonHighlight: AppPalette.u1DarkSkeletonHighlight,
    successSurface: Color(0xFF163A2A),
    warningSurface: Color(0xFF3D2F16),
    infoSurface: Color(0xFF1C2E4D),
    radiusXs: AppRadius.u1Xs,
    radiusSm: AppRadius.u1Sm,
    radiusMd: AppRadius.u1Md,
    radiusLg: AppRadius.u1Lg,
    radiusXl: AppRadius.u1Xl,
    inputSm: AppSizes.u1InputSm,
    inputMd: AppSizes.u1InputMd,
    inputLg: AppSizes.u1InputLg,
    buttonSm: AppSizes.u1ButtonSm,
    buttonMd: AppSizes.u1ButtonMd,
    buttonLg: AppSizes.u1ButtonLg,
    shadowLevel1: AppShadows.u1Level1,
    shadowLevel2: AppShadows.u1Level2,
    shadowLevel3: AppShadows.u1Level3,
    shadowLevel4: AppShadows.u1Level4,
  );

  // Backwards-compatible aliases for code written during U1 development.
  static const ChegaJaTheme light = u1Light;
  static const ChegaJaTheme dark = u1Dark;

  @override
  ChegaJaTheme copyWith({
    ChegaJaDesignSystem? designSystem,
    bool? brandGradientEnabled,
    LinearGradient? brandGradient,
    LinearGradient? actionGradient,
    LinearGradient? softBrandGradient,
    Color? primary,
    Color? primaryHover,
    Color? primaryPressed,
    Color? primaryDisabled,
    Color? secondary,
    Color? secondaryHover,
    Color? secondaryPressed,
    Color? secondaryDisabled,
    Color? focusRing,
    Color? skeletonBase,
    Color? skeletonHighlight,
    Color? successSurface,
    Color? warningSurface,
    Color? infoSurface,
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? inputSm,
    double? inputMd,
    double? inputLg,
    double? buttonSm,
    double? buttonMd,
    double? buttonLg,
    List<BoxShadow>? shadowLevel1,
    List<BoxShadow>? shadowLevel2,
    List<BoxShadow>? shadowLevel3,
    List<BoxShadow>? shadowLevel4,
  }) {
    return ChegaJaTheme(
      designSystem: designSystem ?? this.designSystem,
      brandGradientEnabled: brandGradientEnabled ?? this.brandGradientEnabled,
      brandGradient: brandGradient ?? this.brandGradient,
      actionGradient: actionGradient ?? this.actionGradient,
      softBrandGradient: softBrandGradient ?? this.softBrandGradient,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryDisabled: primaryDisabled ?? this.primaryDisabled,
      secondary: secondary ?? this.secondary,
      secondaryHover: secondaryHover ?? this.secondaryHover,
      secondaryPressed: secondaryPressed ?? this.secondaryPressed,
      secondaryDisabled: secondaryDisabled ?? this.secondaryDisabled,
      focusRing: focusRing ?? this.focusRing,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      successSurface: successSurface ?? this.successSurface,
      warningSurface: warningSurface ?? this.warningSurface,
      infoSurface: infoSurface ?? this.infoSurface,
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      inputSm: inputSm ?? this.inputSm,
      inputMd: inputMd ?? this.inputMd,
      inputLg: inputLg ?? this.inputLg,
      buttonSm: buttonSm ?? this.buttonSm,
      buttonMd: buttonMd ?? this.buttonMd,
      buttonLg: buttonLg ?? this.buttonLg,
      shadowLevel1: shadowLevel1 ?? this.shadowLevel1,
      shadowLevel2: shadowLevel2 ?? this.shadowLevel2,
      shadowLevel3: shadowLevel3 ?? this.shadowLevel3,
      shadowLevel4: shadowLevel4 ?? this.shadowLevel4,
    );
  }

  @override
  ChegaJaTheme lerp(covariant ChegaJaTheme? other, double t) {
    if (other == null) return this;
    return ChegaJaTheme(
      designSystem: t < 0.5 ? designSystem : other.designSystem,
      brandGradientEnabled:
          t < 0.5 ? brandGradientEnabled : other.brandGradientEnabled,
      brandGradient:
          LinearGradient.lerp(brandGradient, other.brandGradient, t) ??
              brandGradient,
      actionGradient:
          LinearGradient.lerp(actionGradient, other.actionGradient, t) ??
              actionGradient,
      softBrandGradient:
          LinearGradient.lerp(softBrandGradient, other.softBrandGradient, t) ??
              softBrandGradient,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryHover:
          Color.lerp(primaryHover, other.primaryHover, t) ?? primaryHover,
      primaryPressed:
          Color.lerp(primaryPressed, other.primaryPressed, t) ?? primaryPressed,
      primaryDisabled: Color.lerp(primaryDisabled, other.primaryDisabled, t) ??
          primaryDisabled,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      secondaryHover:
          Color.lerp(secondaryHover, other.secondaryHover, t) ?? secondaryHover,
      secondaryPressed:
          Color.lerp(secondaryPressed, other.secondaryPressed, t) ??
              secondaryPressed,
      secondaryDisabled:
          Color.lerp(secondaryDisabled, other.secondaryDisabled, t) ??
              secondaryDisabled,
      focusRing: Color.lerp(focusRing, other.focusRing, t) ?? focusRing,
      skeletonBase:
          Color.lerp(skeletonBase, other.skeletonBase, t) ?? skeletonBase,
      skeletonHighlight:
          Color.lerp(skeletonHighlight, other.skeletonHighlight, t) ??
              skeletonHighlight,
      successSurface:
          Color.lerp(successSurface, other.successSurface, t) ?? successSurface,
      warningSurface:
          Color.lerp(warningSurface, other.warningSurface, t) ?? warningSurface,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t) ?? infoSurface,
      radiusXs: _lerpDouble(radiusXs, other.radiusXs, t),
      radiusSm: _lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: _lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: _lerpDouble(radiusLg, other.radiusLg, t),
      radiusXl: _lerpDouble(radiusXl, other.radiusXl, t),
      inputSm: _lerpDouble(inputSm, other.inputSm, t),
      inputMd: _lerpDouble(inputMd, other.inputMd, t),
      inputLg: _lerpDouble(inputLg, other.inputLg, t),
      buttonSm: _lerpDouble(buttonSm, other.buttonSm, t),
      buttonMd: _lerpDouble(buttonMd, other.buttonMd, t),
      buttonLg: _lerpDouble(buttonLg, other.buttonLg, t),
      shadowLevel1: t < 0.5 ? shadowLevel1 : other.shadowLevel1,
      shadowLevel2: t < 0.5 ? shadowLevel2 : other.shadowLevel2,
      shadowLevel3: t < 0.5 ? shadowLevel3 : other.shadowLevel3,
      shadowLevel4: t < 0.5 ? shadowLevel4 : other.shadowLevel4,
    );
  }

  static double _lerpDouble(double first, double second, double t) =>
      first + (second - first) * t;
}

extension ChegaJaThemeContext on BuildContext {
  ChegaJaTheme get chegaJaTheme =>
      Theme.of(this).extension<ChegaJaTheme>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? ChegaJaTheme.legacyDark
          : ChegaJaTheme.legacyLight);
}
