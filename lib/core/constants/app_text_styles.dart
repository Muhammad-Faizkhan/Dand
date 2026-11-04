import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

/// Typography scale measured off the Figma frames (390 x 844 base).
class AppText {
  AppText._();

  static const String family = 'Inter';

  static TextStyle _s(double size, FontWeight w, Color c, {double? height, double? spacing}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size.sp,
        fontWeight: w,
        color: c,
        height: height,
        letterSpacing: spacing,
      );

  // Display / headings
  static TextStyle get display =>
      _s(27.2, FontWeight.w800, AppColors.textPrimary, height: 1.12, spacing: -0.6);
  static TextStyle get h1 =>
      _s(24, FontWeight.w800, AppColors.textPrimary, height: 1.15, spacing: -0.5);
  static TextStyle get h2 =>
      _s(19.2, FontWeight.w700, AppColors.textPrimary, height: 1.2, spacing: -0.3);
  static TextStyle get h3 =>
      _s(16, FontWeight.w700, AppColors.textPrimary, height: 1.25, spacing: -0.2);
  static TextStyle get h4 => _s(13.6, FontWeight.w700, AppColors.textPrimary, height: 1.3);
  static TextStyle get h5 => _s(12, FontWeight.w600, AppColors.textPrimary, height: 1.3);

  // Body
  static TextStyle get body => _s(12, FontWeight.w400, AppColors.textPrimary, height: 1.45);
  static TextStyle get bodyDim => _s(12, FontWeight.w400, AppColors.textSecondary, height: 1.5);
  static TextStyle get bodySm => _s(10.8, FontWeight.w400, AppColors.textPrimary, height: 1.4);
  static TextStyle get bodySmDim => _s(10.8, FontWeight.w400, AppColors.textSecondary, height: 1.4);
  static TextStyle get caption => _s(9.6, FontWeight.w400, AppColors.textSecondary, height: 1.35);
  static TextStyle get captionBold => _s(9.6, FontWeight.w600, AppColors.textPrimary, height: 1.35);

  // Controls
  static TextStyle get button => _s(13.2, FontWeight.w700, AppColors.white, spacing: 0.1);
  static TextStyle get buttonSm => _s(11.6, FontWeight.w700, AppColors.white);
  static TextStyle get label => _s(10.4, FontWeight.w400, AppColors.textSecondary);
  static TextStyle get field => _s(12.8, FontWeight.w400, AppColors.textPrimary);
  static TextStyle get link => _s(11.2, FontWeight.w700, AppColors.red);
  static TextStyle get price => _s(12.4, FontWeight.w700, AppColors.red);
}
