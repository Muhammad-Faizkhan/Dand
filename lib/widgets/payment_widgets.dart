import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// Blue three-segment rail used by the subscription payment flow.
class BluePlanProgress extends StatelessWidget {
  const BluePlanProgress({super.key, required this.step, this.steps = 3});

  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps, (i) {
        return Expanded(
          child: Container(
            height: 4.h,
            margin: EdgeInsets.only(right: i == steps - 1 ? 0 : 12.w),
            decoration: BoxDecoration(
              color: i <= step ? AppColors.planBlue : const Color(0xFF4A4A4E),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        );
      }),
    );
  }
}

/// Saved-card row with a radio, brand mark and masked number.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.brand,
    required this.last4,
    required this.selected,
    this.onTap,
    this.accent = AppColors.planBlue,
  });

  final String brand;
  final String last4;
  final bool selected;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isVisa = brand.toUpperCase() == 'VISA';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66.h,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: selected ? accent : AppColors.border,
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
                border: Border.all(color: selected ? accent : const Color(0xFF6B6B70), width: 2),
              ),
              child: selected
                  ? Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    )
                  : null,
            ),
            SizedBox(width: 16.w),
            Container(
              width: 52.w,
              height: 34.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isVisa ? AppColors.redSolid : const Color(0xFF2B2B2F),
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Text(
                brand.toUpperCase(),
                style: AppText.captionBold.copyWith(
                  fontSize: isVisa ? 13.sp : 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Text('••••  $last4', style: AppText.h4.copyWith(fontSize: 14.4.sp)),
          ],
        ),
      ),
    );
  }
}

class AddPaymentMethodTile extends StatelessWidget {
  const AddPaymentMethodTile({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '+ Add payment method',
          style: AppText.h5.copyWith(fontSize: 13.6.sp, color: const Color(0xFF7E97F0)),
        ),
      ),
    );
  }
}

/// Line-item + total block used on both checkout flows.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.rows,
    required this.total,
    this.totalColor = AppColors.red,
    this.totalLabel = 'Total',
  });

  final List<MapEntry<String, String>> rows;
  final String total;
  final Color totalColor;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final r in rows)
            SizedBox(
              height: 56.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.key, style: AppText.bodyDim.copyWith(fontSize: 13.2.sp)),
                  Text(r.value, style: AppText.h5.copyWith(fontSize: 13.6.sp)),
                ],
              ),
            ),
          Divider(height: 1, color: AppColors.border),
          SizedBox(
            height: 60.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(totalLabel, style: AppText.h4.copyWith(fontSize: 13.6.sp)),
                Text(
                  total,
                  style: AppText.h2.copyWith(fontSize: 17.6.sp, color: totalColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
