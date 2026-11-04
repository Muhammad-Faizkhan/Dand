import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import 'buttons.dart';

/// The confirmation layout shared by every "success" frame — the ring colour,
/// detail rows and button stack vary per screen.
class SuccessView extends StatelessWidget {
  const SuccessView({
    super.key,
    required this.title,
    required this.message,
    this.topSpace,
    this.details,
    this.accent = AppColors.planBlue,
    this.iconColor,
    this.icon = Icons.check_rounded,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.linkLabel,
    this.onLink,
    this.secondaryFirst = true,
  });

  final String title;
  final String message;
  final double? topSpace;
  final List<MapEntry<String, Widget>>? details;
  final Color accent;
  final Color? iconColor;
  final IconData icon;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? linkLabel;
  final VoidCallback? onLink;
  final bool secondaryFirst;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel == null
        ? null
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            child: SecondaryButton(
              label: secondaryLabel!,
              height: 56.h,
              radius: 15.r,
              onTap: onSecondary,
            ),
          );
    final primary = primaryLabel == null
        ? null
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.w),
            child: PrimaryButton(
              label: primaryLabel!,
              height: 56.h,
              radius: 15.r,
              onTap: onPrimary,
            ),
          );

    final buttons = <Widget>[
      if (secondaryFirst) ...[
        ?secondary,
        if (secondary != null && primary != null) SizedBox(height: 14.h),
        ?primary,
      ] else ...[
        ?primary,
        if (secondary != null && primary != null) SizedBox(height: 14.h),
        ?secondary,
      ],
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: topSpace?.h ?? 235.h),
          Container(
            width: 90.w,
            height: 90.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent, width: 2),
            ),
            child: Icon(icon, color: iconColor ?? const Color(0xFF8AA0F2), size: 35.2.sp),
          ),
          SizedBox(height: 28.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.h1.copyWith(fontSize: 21.6.sp),
            ),
          ),
          SizedBox(height: 14.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 34.w),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.5),
            ),
          ),
          if (details != null) ...[
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 22.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < details!.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: AppColors.border),
                      SizedBox(
                        height: 54.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              details![i].key,
                              style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                            ),
                            details![i].value,
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 30.h),
          ...buttons,
          if (linkLabel != null) ...[
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: onLink,
              child: Text(linkLabel!, style: AppText.link.copyWith(fontSize: 12.8.sp)),
            ),
          ],
          SizedBox(height: 40.h),
        ],
      ),
    );
  }
}
