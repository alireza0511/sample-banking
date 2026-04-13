import 'package:flutter/services.dart';

/// Helper class for haptic feedback throughout the app
class HapticFeedbackHelper {
  /// Light impact for button taps, selections
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact for important actions, confirmations
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact for critical actions
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection feedback for toggles, switches
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Error feedback
  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }

  /// Success feedback (light impact)
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
  }
}
