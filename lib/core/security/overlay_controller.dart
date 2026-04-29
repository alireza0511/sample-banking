import 'package:flutter/foundation.dart';
import 'package:fraud_protection/fraud_protection.dart';

/// Single in-app abstraction over the underlying `fraud_protection` plugin's
/// overlay-blocking surface.
///
/// Why we own this class instead of using the plugin's static methods directly:
///
///   * The rest of the app (the [FraudProtectionService] singleton, the
///     [SensitiveRouteObserver]) holds a *reference* to a real,
///     locally-declared type, so refactors and version bumps of
///     `fraud_protection` don't ripple through the codebase.
///   * Swapping plugins (e.g. moving to `freerasp`) only touches this file.
///   * Tests can inject a fake [OverlayController] into
///     [FraudProtectionService] without monkey-patching static methods.
///
/// `engage()` turns on **both** plugin defenses at once:
///   * `setHideOverlayWindows(true)`  — OS rendering hides foreign overlays
///     (Android 12+ via `Window.setHideOverlayWindows`).
///   * `setBlockOverlayTouches(true)` — drops `MotionEvent`s flagged
///     `FLAG_WINDOW_IS_OBSCURED` / `FLAG_WINDOW_IS_PARTIALLY_OBSCURED`.
///
/// Together these cover every row of the Overlay Tapjacking Test Plan.
class OverlayController {
  OverlayController();

  /// Process-wide single instance. Holding a reference here (rather than
  /// `OverlayController()` being called at multiple sites) means callers all
  /// share state, the plugin doesn't get engaged twice, the ref-count stays
  /// authoritative, and tests can inject a different instance via
  /// [FraudProtectionService]'s `forTesting` factory.
  static final OverlayController instance = OverlayController();

  Future<void> engage() async {
    await _invoke(() => FraudProtection.setHideOverlayWindows(true));
    await _invoke(() => FraudProtection.setBlockOverlayTouches(true));
  }

  Future<void> disengage() async {
    await _invoke(() => FraudProtection.setHideOverlayWindows(false));
    await _invoke(() => FraudProtection.setBlockOverlayTouches(false));
  }

  Future<void> _invoke(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      // Plugin failures must never break navigation.
      debugPrint('OverlayController call failed: $e\n$st');
    }
  }
}
