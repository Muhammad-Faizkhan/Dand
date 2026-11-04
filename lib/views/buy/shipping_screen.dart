import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/payment_widgets.dart';

class ShippingScreen extends StatelessWidget {
  const ShippingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutController>(
      builder: (context, checkout, _) {
        return AppScaffold(
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppLayout.top(61)),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                          ),
                          SizedBox(width: 16.w),
                          Text('Shipping', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      const BluePlanProgress(step: 0),
                      SizedBox(height: 26.h),
                      Text(
                        'DELIVER TO',
                        style: AppText.captionBold.copyWith(
                          fontSize: 11.2.sp,
                          letterSpacing: 0.9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(color: AppColors.planBlue),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44.w,
                              height: 44.w,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.planBlue.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(11.r),
                              ),
                              child: Icon(
                                Icons.place_outlined,
                                size: 17.6.sp,
                                color: const Color(0xFF7E97F0),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daniel Dermaree · Home',
                                    style: AppText.h4.copyWith(fontSize: 14.4.sp),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    '1240 Main St, Sturgis, SD\n57785',
                                    style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Change',
                              style: AppText.link.copyWith(
                                fontSize: 13.2.sp,
                                color: const Color(0xFF7E97F0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Container(
                        height: 66.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '+ Add new address',
                          style: AppText.h5.copyWith(
                            fontSize: 13.6.sp,
                            color: const Color(0xFF7E97F0),
                          ),
                        ),
                      ),
                      SizedBox(height: 26.h),
                      Text(
                        'DELIVERY METHOD',
                        style: AppText.captionBold.copyWith(
                          fontSize: 11.2.sp,
                          letterSpacing: 0.9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      _MethodTile(
                        title: 'Standard · 3–5 days',
                        subtitle: 'Insured & tracked',
                        price: '\$6.00',
                        selected: checkout.shippingMethod == 0,
                        onTap: () => checkout.setShipping(0),
                      ),
                      SizedBox(height: 14.h),
                      _MethodTile(
                        title: 'Express · 1–2 days',
                        subtitle: 'Priority shipping',
                        price: '\$14.00',
                        selected: checkout.shippingMethod == 1,
                        onTap: () => checkout.setShipping(1),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 30.h),
                child: PrimaryButton(
                  label: 'Continue to Payment',
                  height: 56.h,
                  radius: 15.r,
                  gradient: AppColors.blueGradient,
                  glowColor: AppColors.planBlue,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.checkout),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 82.h,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: selected ? AppColors.planBlue : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.planBlue : const Color(0xFF6B6B70),
                  width: 2,
                ),
              ),
              child: selected
                  ? Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: const BoxDecoration(
                        color: AppColors.planBlue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: AppText.h4.copyWith(fontSize: 14.4.sp)),
                  SizedBox(height: 4.h),
                  Text(subtitle, style: AppText.bodyDim.copyWith(fontSize: 12.4.sp)),
                ],
              ),
            ),
            Text(price, style: AppText.h4.copyWith(fontSize: 14.4.sp)),
          ],
        ),
      ),
    );
  }
}
