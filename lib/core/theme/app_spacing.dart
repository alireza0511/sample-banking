/// Spacing design tokens - Kind Banking
/// Based on 8px grid system per PRD Section 7.2.3
class AppSpacing {
  AppSpacing._();

  // Base unit
  static const double unit = 8.0;

  // Spacing scale
  static const double xs = unit * 0.5; // 4px
  static const double sm = unit; // 8px
  static const double md = unit * 2; // 16px
  static const double lg = unit * 3; // 24px
  static const double xl = unit * 4; // 32px
  static const double xxl = unit * 6; // 48px
  static const double xxxl = unit * 8; // 64px

  // Component-specific spacing
  static const double cardPadding = md; // 16px
  static const double screenPadding = md; // 16px
  static const double buttonPadding = md; // 16px
  static const double listItemSpacing = sm; // 8px
  static const double sectionSpacing = lg; // 24px

  // Touch targets (44px minimum for accessibility)
  static const double minTouchTarget = 44.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;

  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusFull = 9999.0;

  // Card dimensions
  static const double cardRadius = radiusLg;
  static const double cardElevation = 2.0;
}
