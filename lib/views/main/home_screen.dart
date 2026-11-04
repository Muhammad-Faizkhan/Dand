import 'package:flutter/material.dart';
import '../../widgets/chip_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/utils/format.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/asset_icon.dart';
import '../../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onMenu, required this.onTab});

  final VoidCallback onMenu;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.watch<UserController>();
    final userName = userCtrl.displayName;
    final live = userCtrl.live;
    final u = userCtrl.user;
    final market = context.watch<MarketplaceController>();
    final trade = context.watch<TradeController>();
    // Newest listings from other collectors stand in for "trending" and the community feed.
    final others = market.hasApiData ? market.items.where((i) => i.sellerId != userCtrl.userId).toList() : const <ChipItem>[];
    final trending = live ? others.take(2).toList() : AppData.trending;
    final activity = live
        ? [
            for (final i in others.take(4))
              ActivityEntry(initials: initialsOf(i.owner), user: i.owner, detail: 'Listed ${i.name}', time: i.type.label),
          ]
        : AppData.activity;
    final perfect = live ? trade.matches.where((m) => m.giveChip != null).length : 2;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: AppBottomNav.heightOf(context) + 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppLayout.top(51)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onMenu,
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.grid_view_rounded, size: 16.8.sp, color: AppColors.white),
                  ),
                ),
                SizedBox(width: 14.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
                    SizedBox(height: 1.h),
                    Text(userName, style: AppText.h1.copyWith(fontSize: 23.5.sp)),
                  ],
                ),
                const Spacer(),
                _HeaderAction(
                  asset: AppAssets.iconMessages,
                  fallback: Icons.forum_rounded,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.messages),
                ),
                SizedBox(width: 12.w),
                _HeaderAction(
                  asset: AppAssets.iconNotifications,
                  fallback: Icons.notifications_rounded,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                ),
              ],
            ),
          ),
          SizedBox(height: 19.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: Row(
              children: [
                _StatCard(value: live ? '${u?.itemCount ?? 0}' : '247', label: 'Collection', onTap: () => onTab(1)),
                SizedBox(width: 12.w),
                _StatCard(
                  value: live ? '${u?.tradeCount ?? 0}' : '127',
                  label: 'Trades',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tradeMatches),
                ),
                SizedBox(width: 12.w),
                _StatCard(
                  value: live ? '${u?.wishlistCount ?? 0}' : '38',
                  label: 'Wishlist',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.wishlist),
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.tradeMatches),
              child: Container(
                height: 79.h,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: AppColors.redTint,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52.w,
                      height: 52.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.redGradient,
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Icon(Icons.swap_vert_rounded, size: 20.8.sp, color: AppColors.white),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            perfect == 0 ? 'Find trade matches' : '$perfect Perfect Match${perfect == 1 ? '' : 'es'}',
                            style: AppText.h4.copyWith(fontSize: 15.2.sp),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Collectors who want what you have',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.red, size: 19.2.sp),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 17.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: SectionHeader(
              title: 'Trending near you',
              action: 'See all',
              onAction: () => onTab(1),
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: trending.isEmpty
                ? Text(
                    market.loading ? 'Loading listings…' : 'No listings nearby yet.',
                    style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                  )
                : Row(
                    children: [
                      for (var i = 0; i < 2; i++) ...[
                        if (i > 0) SizedBox(width: 12.w),
                        Expanded(child: i < trending.length ? TrendingCard(item: trending[i]) : const SizedBox()),
                      ],
                    ],
                  ),
          ),
          SizedBox(height: 26.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: Text('Community activity', style: AppText.h3.copyWith(fontSize: 16.sp)),
          ),
          SizedBox(height: 14.h),
          if (activity.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
              child: Text('Nothing new from the community yet.', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
            ),
          for (final a in activity)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                child: Container(
                  height: 74.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      InitialsAvatar(initials: a.initials, size: 46.w, fontSize: 15),
                      SizedBox(width: 14.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(a.user, style: AppText.h4.copyWith(fontSize: 14.4.sp)),
                          SizedBox(height: 2.h),
                          Text(
                            '${a.detail} · ${a.time}',
                            style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.asset, required this.fallback, this.onTap});

  final String asset;
  final IconData fallback;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 46.w,
        height: 46.w,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46.w,
              height: 46.w,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: AssetIcon(
                asset: asset,
                fallback: fallback,
                size: 17.6.sp,
                color: AppColors.white,
              ),
            ),
            Positioned(
              right: 2.w,
              top: 2.h,
              child: Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: AppColors.redSolid,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 76.h,
          padding: EdgeInsets.only(left: 14.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppText.h1.copyWith(fontSize: 20.8.sp)),
              SizedBox(height: 2.h),
              Text(label, style: AppText.bodyDim.copyWith(fontSize: 11.2.sp)),
            ],
          ),
        ),
      ),
    );
  }
}

/// White-topped product card used on Home.
class TrendingCard extends StatelessWidget {
  const TrendingCard({super.key, required this.item});

  final ChipItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.itemDetail, arguments: item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 167 / 146,
                  child: Container(
                    color: AppColors.surface,
                    child: ChipImage(item),
                  ),
                ),
                if (item.isAuction)
                  Positioned(
                    right: 0,
                    top: 8.h,
                    child: StatusBadge(
                      label: 'Auction',
                      radius: 8.r,
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 13.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.h4.copyWith(fontSize: 13.6.sp),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    item.isAuction ? '${item.priceLabel} · ${item.bids} bids' : item.priceLabel,
                    style: AppText.price.copyWith(fontSize: 12.8.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
