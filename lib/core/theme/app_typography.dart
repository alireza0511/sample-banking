import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography design tokens - Kind Banking
/// Based on PRD Section 7.2.2
class AppTypography {
  AppTypography._();

  // Font family
  static const String fontFamily = 'Roboto';

  // Font sizes
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;
  static const double fontSize3xl = 30.0;
  static const double fontSize4xl = 36.0;

  // Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // Text Styles - Standard
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize4xl,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize3xl,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        color: AppColors.textPrimary,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize2xl,
        fontWeight: FontWeight.w600,
        height: lineHeightTight,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXl,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeLg,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w500,
        height: lineHeightNormal,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w500,
        height: lineHeightNormal,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  // Balance amount style
  static TextStyle get balanceAmount => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize3xl,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        color: AppColors.textPrimary,
      );

  // Large text accessibility variant (18sp minimum)
  static TextStyle get accessibilityBody => const TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSizeLg,
        fontWeight: FontWeight.w400,
        height: lineHeightRelaxed,
        color: AppColors.textPrimary,
      );
}
