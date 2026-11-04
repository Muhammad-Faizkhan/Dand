import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Helpers for translating Figma frame coordinates (390 x 844, status bar
/// included) into offsets inside a SafeArea body.
class AppLayout {
  AppLayout._();

  /// Status-bar height baked into the Figma frames.
  static const double statusBar = 47;

  /// Standard horizontal page padding.
  static double get gutter => 22.w;

  /// Vertical offset from the top of the safe area for a design Y coordinate.
  static double top(double designY) => (designY - statusBar).h;
}
