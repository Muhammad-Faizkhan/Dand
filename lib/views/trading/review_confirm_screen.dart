import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_image.dart';
import '../../widgets/upgrade_prompt.dart';

class ReviewConfirmScreen extends StatelessWidget {
  const ReviewConfirmScreen({super.key, this.disabled = false});

  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final trade = context.watch<TradeController>();
    final live = trade.client != null;
    final give = trade.offered.isEmpty ? AppData.bristolWideGive : trade.offered.first;
    final get = trade.target ?? AppData.yankeeBristol;

    return AppScaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppLayout.top(62)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                      ),
                      SizedBox(width: 16.w),
                      Text('Review & Confirm', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                    ],
                  ),
                  SizedBox(height: 26.h),
                  Container(
                    height: 145.h,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: ChipImage(give, width: 96.w, height: 96.w),
                        ),
                        SizedBox(width: 20.w),
                        Container(
                          width: 52.w,
                          height: 52.w,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.swap_vert_rounded,
                            size: 20.8.sp,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(width: 20.w),
                        ClipOval(
                          child: ChipImage(get, width: 96.w, height: 96.w),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _Row(
                          label: 'Trade with',
                          value: live ? get.owner : 'HD Collector',
                          valueStyle: AppText.h5.copyWith(fontSize: 13.6.sp),
                        ),
                        if (live)
                          _Row(
                            label: 'You offer',
                            value: '${trade.offered.length} chip${trade.offered.length == 1 ? '' : 's'}',
                            valueStyle: AppText.h5.copyWith(fontSize: 13.6.sp),
                          )
                        else ...[
                          _Row(
                            label: 'Service fee',
                            value: '\$1.50',
                            valueStyle: AppText.h5.copyWith(fontSize: 13.6.sp),
                          ),
                          Divider(height: 1, color: AppColors.border),
                          _Row(
                            label: 'Total',
                            labelStyle: AppText.h4.copyWith(fontSize: 13.6.sp),
                            value: '\$1.50',
                            valueStyle: AppText.h2.copyWith(fontSize: 16.8.sp, color: AppColors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    live
                        ? 'Nothing changes hands until ${get.owner.isEmpty ? 'they' : get.owner} accepts. Then the chips swap owners automatically.'
                        : 'Both items are held in escrow untill the trade is confirmed byu both parties',
                    style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.5),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 26.h),
            child: PrimaryButton(
              label: 'Send Trade Offer',
              height: 56.h,
              radius: 15.r,
              enabled: !disabled,
              onTap: () async {
                if (!live) {
                  Navigator.pushNamed(context, AppRoutes.tradeSent);
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                final error = await trade.sendProposal();
                if (!context.mounted) return;
                if (error == null) {
                  final sent = trade.lastSent;
                  trade.reset();
                  Navigator.pushNamed(context, AppRoutes.tradeSent, arguments: sent);
                } else if (trade.upgradeRequired) {
                  await showUpgradePrompt(context, error);
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.surfaceAlt,
                      content: Text(error, style: AppText.body.copyWith(fontSize: 12.8.sp)),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.labelStyle, this.valueStyle});

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle ?? AppText.bodyDim.copyWith(fontSize: 13.2.sp)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
