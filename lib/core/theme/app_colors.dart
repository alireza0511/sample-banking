import 'package:flutter/material.dart';

/// Design tokens for colors - Kind Banking
/// Based on PRD Section 7.2.1
class AppColors {
  AppColors._();

  // Primary Palette (Light Mode)
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFFE3F2FD);

  // Semantic Colors
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC04);
  static const Color error = Color(0xFFEA4335);
  static const Color info = Color(0xFF4285F4);

  // Neutral Palette
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF9AA0A6);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE8EAED);

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE8EAED);
  static const Color darkTextSecondary = Color(0xFF9AA0A6);
  static const Color darkPrimaryBlue = Color(0xFF8AB4F8);

  // High Contrast (Accessibility)
  static const Color highContrastText = Color(0xFF000000);
  static const Color highContrastBackground = Color(0xFFFFFFFF);
  static const Color highContrastPrimary = Color(0xFF0000EE);
  static const Color highContrastError = Color(0xFFCC0000);

  // Color Blind Safe Palette (Deuteranopia/Protanopia)
  static const Color cbSafeBlue = Color(0xFF0072B2);
  static const Color cbSafeOrange = Color(0xFFE69F00);
  static const Color cbSafeCyan = Color(0xFF56B4E9);
  static const Color cbSafeYellow = Color(0xFFF0E442);
  static const Color cbSafePink = Color(0xFFCC79A7);

  // Privacy Indicator Colors
  static const Color privacyOnDevice = Color(0xFF34A853); // Green - secure
  static const Color privacyCloud = Color(0xFFFBBC04); // Yellow - caution
  static const Color privacyOffline = Color(0xFF9AA0A6); // Gray - offline
}
