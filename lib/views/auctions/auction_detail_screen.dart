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
import '../../widgets/common.dart';

class AuctionDetailScreen extends StatefulWidget {
  const AuctionDetailScreen({super.key, required this.item});

  final ChipItem item;

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  ChipItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    if (item.auctionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<AuctionController>().open(item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuctionController>();
    final history = item.auctionId == null ? AppData.bidHistory : controller.history;
    // API auctions show their own numbers until the bid screen has opened them.
    final live = item.auctionId == null || controller.openedAuctionId == item.auctionId;
    final currentBid = live ? controller.currentBid : item.price;
    final bidCount = live ? controller.bids : item.bids;
    return AppScaffold(
      safeAreaTop: false,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 355.h,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ChipImage(item),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x55000000), Color(0x00000000), Color(0xCC0A0406)],
                              stops: [0, 0.4, 1],
                            ),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                            child: Column(
                              children: [
                                SizedBox(height: 18.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CircleIconButton(
                                      icon: Icons.arrow_back,
                                      background: AppColors.black.withValues(alpha: 0.45),
                                      onTap: () => Navigator.pop(context),
                                    ),
                                    StatusBadge(
                                      label: 'Live Auction',
                                      radius: 20.r,
                                      fontSize: 16,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 10.h,
                                      ),
                                      icon: Container(
                                        width: 9.w,
                                        height: 9.w,
                                        decoration: const BoxDecoration(
                                          color: AppColors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: AppLayout.gutter,
                          right: AppLayout.gutter,
                          bottom: 18.h,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                              SizedBox(height: 6.h),
                              Text(
                                '📍 ${item.distance} · ${item.rarity.label} edition',
                                style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
                      decoration: BoxDecoration(
                        color: AppColors.redTint,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current bid',
                                style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '\$${currentBid.toStringAsFixed(0)}',
                                style: AppText.display.copyWith(
                                  fontSize: 27.sp,
                                  color: AppColors.red,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                '$bidCount bids',
                                style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Ends in', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                              SizedBox(height: 4.h),
                              Text(item.auctionId == null ? '1h 20m' : controller.endsIn, style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Container(
                                    width: 9.w,
                                    height: 9.w,
                                    decoration: const BoxDecoration(
                                      color: AppColors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 7.w),
                                  Text(
                                    'Active now',
                                    style: AppText.body.copyWith(
                                      fontSize: 12.8.sp,
                                      color: const Color(0xFF3CCB84),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: Text('Bid history', style: AppText.h3.copyWith(fontSize: 16.sp)),
                  ),
                  SizedBox(height: 14.h),
                  for (var i = 0; i < history.length; i++)
                    Padding(
                      padding: EdgeInsets.fromLTRB(AppLayout.gutter, 0, AppLayout.gutter, 12.h),
                      child: Container(
                        height: 62.h,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              history[i].key,
                              style: AppText.body.copyWith(
                                fontSize: 13.6.sp,
                                color: i == 0 ? AppColors.white : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '\$${history[i].value}',
                              style: AppText.h4.copyWith(
                                fontSize: 14.4.sp,
                                color: i == 0 ? AppColors.red : AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 14.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 0, 25.w, 26.h),
            child: PrimaryButton(
              label: 'Place Bid',
              height: 56.h,
              radius: 15.r,
              onTap: () {
                controller.open(item);
                Navigator.pushNamed(context, AppRoutes.placeBid, arguments: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}
