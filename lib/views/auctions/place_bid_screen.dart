import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/upgrade_prompt.dart';

class PlaceBidScreen extends StatelessWidget {
  const PlaceBidScreen({super.key, required this.item});

  final ChipItem item;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuctionController>(
      builder: (context, auction, _) {
        final min = auction.minBid;
        final bidsLeft = auction.plan?.bidsLeft;
        return AppScaffold(
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppLayout.top(65)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                      ),
                      SizedBox(height: 26.h),
                      Text('Place your bid', style: AppText.h1.copyWith(fontSize: 21.5.sp)),
                      SizedBox(height: 10.h),
                      Text(item.name, style: AppText.bodyDim.copyWith(fontSize: 13.6.sp)),
                      SizedBox(height: 26.h),
                      Container(
                        height: 82.h,
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56.w,
                              height: 56.w,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: item.imageUrl != null
                                  ? Image.network(
                                      item.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Image.asset(item.image, fit: BoxFit.cover),
                                    )
                                  : Image.asset(item.image, fit: BoxFit.cover),
                            ),
                            SizedBox(width: 16.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Current bid',
                                  style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  '\$${auction.currentBid.toStringAsFixed(0)}',
                                  style: AppText.h2.copyWith(
                                    fontSize: 17.6.sp,
                                    color: AppColors.red,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Ends in', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                                SizedBox(height: 3.h),
                                Text(auction.endsIn, style: AppText.h4.copyWith(fontSize: 15.2.sp)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 26.h),
                      Text(
                        'Your bid (min \$${min.toStringAsFixed(0)})',
                        style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        height: 88.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.55)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$',
                              style: AppText.h1.copyWith(
                                fontSize: 20.5.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              auction.myBid.toStringAsFixed(0),
                              style: AppText.display.copyWith(fontSize: 30.4.sp),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          for (final inc in [5.0, 10.0, 25.0]) ...[
                            Expanded(
                              child: GestureDetector(
                                onTap: () => auction.increment(inc),
                                child: Container(
                                  height: 62.h,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(13.r),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    '+\$${inc.toStringAsFixed(0)}',
                                    style: AppText.h4.copyWith(fontSize: 14.4.sp),
                                  ),
                                ),
                              ),
                            ),
                            if (inc != 25.0) SizedBox(width: 14.w),
                          ],
                        ],
                      ),
                      if (bidsLeft != null) ...[
                        SizedBox(height: 18.h),
                        Text(
                          bidsLeft == 0
                              ? 'No free bids left on the ${auction.plan!.planName}. Subscribe for unlimited bidding.'
                              : '$bidsLeft of ${auction.plan!.bidLimit} free bids left on the ${auction.plan!.planName}',
                          style: AppText.bodyDim.copyWith(
                            fontSize: 12.8.sp,
                            color: bidsLeft <= 3 ? AppColors.red : AppColors.textSecondary,
                          ),
                        ),
                      ],
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(25.w, 0, 25.w, 26.h),
                child: PrimaryButton(
                  label: auction.placing ? 'Placing bid…' : 'Confirm Bid · \$${auction.myBid.toStringAsFixed(0)}',
                  height: 56.h,
                  radius: 15.r,
                  onTap: auction.placing ? null : () => _confirm(context, auction),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirm(BuildContext context, AuctionController auction) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await auction.placeBid(item);
    if (!context.mounted) return;
    switch (result.status) {
      case BidStatus.placed:
        Navigator.pushNamed(context, AppRoutes.bidPlaced, arguments: item);
      case BidStatus.upgradeRequired:
        await showUpgradePrompt(context, result.message);
      case BidStatus.failed:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.surfaceAlt,
              content: Text(
                result.message ?? "Your bid didn't go through. Try again.",
                style: AppText.body.copyWith(fontSize: 12.8.sp),
              ),
            ),
          );
    }
  }
}
