import 'package:flutter/material.dart';
import '../../widgets/chip_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';

class ProposeTradeScreen extends StatelessWidget {
  const ProposeTradeScreen({super.key, this.target});

  final ChipItem? target;

  @override
  Widget build(BuildContext context) {
    return Consumer<TradeController>(
      builder: (context, trade, _) {
        final wanted = target ?? trade.target ?? AppData.yankeeBristol;
        // Signed in, an empty offer stays empty until the user adds their own chips.
        final give = trade.offered.isEmpty && trade.client == null ? [AppData.bristolWideGive] : trade.offered;

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
                          Text('Propose Trade', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                        ],
                      ),
                      SizedBox(height: 26.h),
                      Text('You Give', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                      SizedBox(height: 12.h),
                      for (final item in give) ...[
                        _TradeRow(
                          item: item,
                          onRemove: trade.offered.isEmpty ? null : () => trade.toggleOffer(item),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.addToTrade),
                        child: Container(
                          height: 74.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.red.withValues(alpha: 0.55)),
                          ),
                          child: Text(
                            '+ Add another item',
                            style: AppText.link.copyWith(fontSize: 14.4.sp),
                          ),
                        ),
                      ),
                      SizedBox(height: 26.h),
                      Center(
                        child: Container(
                          width: 56.w,
                          height: 56.w,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.swap_vert_rounded,
                            size: 22.4.sp,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 26.h),
                      Text('You Get', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                      SizedBox(height: 12.h),
                      _TradeRow(item: wanted),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 26.h),
                child: PrimaryButton(
                  label: 'Review Trade',
                  height: 56.h,
                  radius: 15.r,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.reviewConfirm),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.item, this.onRemove});

  final ChipItem item;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 62.w,
            height: 62.w,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(7.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: ChipImage(item),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.name, style: AppText.h4.copyWith(fontSize: 15.2.sp)),
                SizedBox(height: 6.h),
                Text('Est. ${item.priceLabel}', style: AppText.price.copyWith(fontSize: 13.6.sp)),
              ],
            ),
          ),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 19.2.sp, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
