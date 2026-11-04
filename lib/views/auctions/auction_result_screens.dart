import 'package:flutter/material.dart';
import '../../widgets/chip_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../models/models.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../../widgets/success_view.dart';

class BidPlacedScreen extends StatelessWidget {
  const BidPlacedScreen({super.key, this.item});

  /// The auction bid on; null for the design's sample flow.
  final ChipItem? item;

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    final live = item?.auctionId != null;
    final auction = context.read<AuctionController>();
    return AppScaffold(
      body: SuccessView(
        topSpace: 168,
        accent: AppColors.green,
        iconColor: const Color(0xFF3CCB84),
        title: 'Bid Placed!',
        message: live ? "You're the top bidder on ${item!.name}" : 'Wait for the win',
        details: [
          MapEntry(
            'Status',
            StatusBadge(
              label: live ? 'Leading' : 'Pending',
              background: const Color(0xFF3C2F0B),
              textColor: AppColors.planGold,
              radius: 9.r,
              fontSize: 15,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            ),
          ),
          live
              ? MapEntry('Ends in', Text(auction.endsIn, style: AppText.h5.copyWith(fontSize: 13.6.sp)))
              : MapEntry('Bid ID', Text('#DD-9142', style: AppText.h5.copyWith(fontSize: 13.6.sp))),
        ],
        secondaryFirst: false,
        primaryLabel: live && item!.sellerId == null ? 'Back to Auction' : 'Message Seller',
        onPrimary: () {
          if (!live) {
            Navigator.pushNamed(context, AppRoutes.chat, arguments: 'ChipKing92');
          } else if (item!.sellerId == null) {
            Navigator.pop(context);
          } else {
            final name = item.owner.isEmpty ? item.seller.name : item.owner;
            Navigator.pushNamed(context, AppRoutes.chat, arguments: context.read<ChatController>().threadWith(item.sellerId!, name, null));
          }
        },
        secondaryLabel: 'Back to Marketplace',
        onSecondary: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false),
      ),
    );
  }
}

/// Auction Winner / Auction Lost outcome frames.
class AuctionOutcomeScreen extends StatelessWidget {
  const AuctionOutcomeScreen({super.key, required this.won});

  final bool won;

  @override
  Widget build(BuildContext context) {
    final accent = won ? AppColors.green : AppColors.redSolid;
    final item = AppData.bourbonSpecial;

    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(66)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
            ),
            SizedBox(height: 32.h),
            Center(
              child: Container(
                width: 92.w,
                height: 92.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent, width: 2),
                ),
                child: won
                    ? Icon(Icons.check_rounded, size: 36.8.sp, color: const Color(0xFF3CCB84))
                    : Text(
                        'X',
                        style: AppText.h1.copyWith(fontSize: 27.2.sp, color: accent),
                      ),
              ),
            ),
            SizedBox(height: 26.h),
            Center(
              child: Text(
                won ? 'Auction Winner' : 'Auction Lost',
                style: AppText.h1.copyWith(fontSize: 21.5.sp),
              ),
            ),
            SizedBox(height: 14.h),
            Center(
              child: Text(
                'Auction Time has been Completed',
                style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ClipOval(
                    child: ChipImage(item, fit: BoxFit.contain, width: 96.w, height: 96.w),
                  ),
                  SizedBox(height: 16.h),
                  Text(item.name, style: AppText.h3.copyWith(fontSize: 16.8.sp)),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _row('Start Bid', '\$100.00'),
                  _row('Total bids', '8'),
                  Divider(height: 1, color: AppColors.border),
                  SizedBox(
                    height: 56.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          won ? 'Winner bid' : 'Winning bid',
                          style: AppText.h4.copyWith(fontSize: 13.6.sp),
                        ),
                        Text(
                          '\$145.00',
                          style: AppText.h2.copyWith(fontSize: 16.8.sp, color: AppColors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => SizedBox(
    height: 56.h,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.bodyDim.copyWith(fontSize: 13.2.sp)),
        Text(value, style: AppText.h5.copyWith(fontSize: 13.6.sp)),
      ],
    ),
  );
}
