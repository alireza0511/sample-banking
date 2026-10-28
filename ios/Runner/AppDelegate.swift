import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    VoiceOverImplicitScrollWorkaround.install()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

/// Temporary workaround for https://github.com/flutter/flutter/issues/192774.
///
/// The Flutter engine reports an empty `accessibilityFrame` for off-screen
/// list items (semantics nodes flagged `isHidden`). Since iOS 27, VoiceOver
/// skips elements with an empty frame, so a one-finger swipe stops at the edge
/// of a list instead of scrolling it.
///
/// This swizzles the engine's private `SemanticsObject.accessibilityFrame` so
/// that such an item reports a 1 pt strip on the edge of its enclosing
/// scrollable's viewport that faces the item. VoiceOver then treats it as a
/// clipped element and scrolls it into view. Touch exploration is unaffected:
/// the engine hit-tests with `globalRect`, not `accessibilityFrame`.
///
/// It relies on engine class and method names that are not public API
/// (`SemanticsObject`, `FlutterScrollableSemanticsObject`, `parent`,
/// `globalRect`). If any is missing, `install()` does nothing. Re-test after
/// every Flutter upgrade, and delete this once the engine fix ships.
private enum VoiceOverImplicitScrollWorkaround {
  private typealias FrameFunction = @convention(c) (AnyObject, Selector) -> CGRect

  private static let frameSelector = NSSelectorFromString("accessibilityFrame")
  private static let globalRectSelector = NSSelectorFromString("globalRect")
  private static let parentSelector = NSSelectorFromString("parent")
  private static let edgeStripExtent: CGFloat = 1

  private static var originalFrame: FrameFunction?
  private static var globalRect: FrameFunction?
  private static var scrollableClass: AnyClass?

  static func install() {
    guard originalFrame == nil,
      ProcessInfo.processInfo.isOperatingSystemAtLeast(
        OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 0)),
      let semanticsClass = NSClassFromString("SemanticsObject"),
      let scrollable = NSClassFromString("FlutterScrollableSemanticsObject"),
      let frameMethod = class_getInstanceMethod(semanticsClass, frameSelector),
      // Only swizzle the engine's own override, never an inherited UIKit one.
      frameMethod != class_getInstanceMethod(class_getSuperclass(semanticsClass), frameSelector),
      let globalRectMethod = class_getInstanceMethod(semanticsClass, globalRectSelector),
      class_getInstanceMethod(semanticsClass, parentSelector) != nil
    else {
      return
    }

    scrollableClass = scrollable
    globalRect = unsafeBitCast(method_getImplementation(globalRectMethod), to: FrameFunction.self)
    let original = unsafeBitCast(method_getImplementation(frameMethod), to: FrameFunction.self)
    originalFrame = original

    let replacement: @convention(block) (AnyObject) -> CGRect = { object in
      let frame = original(object, frameSelector)
      guard frame.isEmpty else { return frame }
      return edgeFrame(for: object) ?? frame
    }
    method_setImplementation(frameMethod, imp_implementationWithBlock(replacement))
  }

  private static func edgeFrame(for object: AnyObject) -> CGRect? {
    guard let originalFrame, let globalRect, let scrollableClass else { return nil }

    var ancestor = parent(of: object)
    while let candidate = ancestor, !candidate.isKind(of: scrollableClass) {
      ancestor = parent(of: candidate)
    }
    // A hidden scrollable reports an empty frame too; leave it alone.
    guard let scrollable = ancestor, !originalFrame(scrollable, frameSelector).isEmpty else {
      return nil
    }

    let viewport = globalRect(scrollable, globalRectSelector)
    let itemRect = globalRect(object, globalRectSelector)
    guard !viewport.isEmpty, !itemRect.isEmpty else { return nil }
    if itemRect.intersects(viewport) {
      return itemRect.intersection(viewport)
    }

    var strip = viewport
    if itemRect.minY >= viewport.maxY {
      strip.origin.y = viewport.maxY - edgeStripExtent
      strip.size.height = edgeStripExtent
    } else if itemRect.maxY <= viewport.minY {
      strip.size.height = edgeStripExtent
    } else if itemRect.minX >= viewport.maxX {
      strip.origin.x = viewport.maxX - edgeStripExtent
      strip.size.width = edgeStripExtent
    } else {
      strip.size.width = edgeStripExtent
    }
    return strip
  }

  private static func parent(of object: AnyObject) -> NSObject? {
    return (object as? NSObject)?.perform(parentSelector)?.takeUnretainedValue() as? NSObject
  }
}
