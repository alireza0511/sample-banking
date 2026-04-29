import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'overlay_controller.dart';

/// Reference-counted gatekeeper around [OverlayController].
///
/// The hub may push multiple sensitive routes onto the stack
/// (login → transfer → confirm). We engage on every push and disengage on
/// every pop, so the controller needs to be reference-counted rather than
/// toggled blindly — otherwise popping a nested route would prematurely turn
/// protection off while the parent sensitive route is still visible.
///
/// The native side only exists on Android; this class no-ops on iOS so the
/// observer can call [engage] / [disengage] unconditionally.
class FraudProtectionService {
  FraudProtectionService._({OverlayController? controller})
      : _controller = controller ?? OverlayController.instance;

  /// Process-wide singleton used by the navigator observer.
  static final FraudProtectionService instance = FraudProtectionService._();

  /// Test-only: inject a fake [OverlayController]. Never call from app code.
  @visibleForTesting
  factory FraudProtectionService.forTesting(OverlayController controller) =>
      FraudProtectionService._(controller: controller);

  final OverlayController _controller;
  int _refCount = 0;
  Future<void>? _inFlight;

  bool get isEngaged => _refCount > 0;

  /// Engage overlay protection. Safe to call multiple times — only the first
  /// call hits the platform; subsequent calls just bump the reference count.
  Future<void> engage() async {
    if (!Platform.isAndroid) return;
    _refCount++;
    if (_refCount == 1) {
      await _run(_controller.engage);
    }
  }

  /// Disengage one level. Only actually stops protection when the last
  /// sensitive route in the stack has been popped.
  Future<void> disengage() async {
    if (!Platform.isAndroid) return;
    if (_refCount == 0) return;
    _refCount--;
    if (_refCount == 0) {
      await _run(_controller.disengage);
    }
  }

  /// Force-disengage regardless of ref count. Use on logout or long
  /// backgrounding so a stale counter cannot leave the flag asserted.
  Future<void> reset() async {
    _refCount = 0;
    if (!Platform.isAndroid) return;
    await _run(_controller.disengage);
  }

  Future<void> _run(Future<void> Function() action) async {
    final previous = _inFlight ?? Future<void>.value();
    final next = previous.then((_) => action());
    _inFlight = next;
    return next;
  }
}
