import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Anchored to the bottom of the frame, as in the design, so the CTA cannot
    // slide under the home indicator on a taller screen.
    final ctaBottom = math.max(51.h, MediaQuery.viewPaddingOf(context).bottom + 17.h);

    return AppScaffold(
      safeAreaTop: false,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 263.h,
            child: Center(
              child: Image.asset(AppAssets.logo, width: 158.w, height: 158.w),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 452.h,
            child: Column(
              children: [
                Text(
                  'DAN D',
                  textAlign: TextAlign.center,
                  style: AppText.display.copyWith(fontSize: 30.4.sp, height: 1.18),
                ),
                Text(
                  'COLLECTION',
                  textAlign: TextAlign.center,
                  style: AppText.display.copyWith(fontSize: 30.4.sp, height: 1.18),
                ),
                SizedBox(height: 22.h),
                Text(
                  'Collect · Discover · Trade',
                  style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
                ),
              ],
            ),
          ),
          Positioned(
            left: 58.w,
            right: 58.w,
            bottom: ctaBottom,
            child: PrimaryButton(
              label: 'Get Started',
              height: 54.h,
              radius: 27.r,
              onTap: () => Navigator.pushNamed(context, AppRoutes.onboarding),
            ),
          ),
        ],
      ),
    );
  }
}
