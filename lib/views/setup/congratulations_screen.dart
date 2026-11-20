import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/buttons.dart';

class CongratulationsScreen extends StatelessWidget {
  const CongratulationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          // Underlying step chrome, dimmed behind the celebration card.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppLayout.top(75)),
                Icon(
                  Icons.arrow_back,
                  size: 20.8.sp,
                  color: AppColors.white.withValues(alpha: 0.5),
                ),
                SizedBox(height: 22.h),
                Opacity(opacity: 0.55, child: const StepProgress(step: 2)),
                SizedBox(height: 26.h),
                Opacity(
                  opacity: 0.55,
                  child: AuthIconBadge(icon: Icons.password_rounded, size: 60.w),
                ),
              ],
            ),
          ),
          Positioned(
            left: 22.w,
            right: 22.w,
            top: AppLayout.top(340),
            child: Container(
              padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 30.h),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(26.r),
                border: Border.all(color: AppColors.planGold.withValues(alpha: 0.55)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 78.w,
                    height: 78.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.planGold.withValues(alpha: 0.16),
                    ),
                    child: Icon(Icons.schedule_rounded, color: AppColors.planGold, size: 32.sp),
                  ),
                  SizedBox(height: 22.h),
                  Text('Congratulations!', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                  SizedBox(height: 16.h),
                  Text(
                    'Congratulation your profile have been verified and your 30 days trial has Started.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.5),
                  ),
                  SizedBox(height: 18.h),
                  Text.rich(
                    TextSpan(
                      style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.5),
                      children: [
                        const TextSpan(text: 'Enjoy full access and upload up to '),
                        TextSpan(
                          text: '100 chips',
                          style: AppText.body.copyWith(
                            fontSize: 12.8.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                        const TextSpan(text: ' to your collection. Upgrade anytime for more.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: PrimaryButton(
                      label: 'Start Exploring',
                      height: 52.h,
                      radius: 26.r,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.whatYouCollect),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.choosePlan),
                    child: Text(
                      'See all plans',
                      style: AppText.link.copyWith(fontSize: 12.8.sp, color: AppColors.planGold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
