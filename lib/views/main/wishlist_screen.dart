import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/chip_grid_card.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/utils/responsive.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistController>(
      builder: (context, wishlist, _) {
        return AppScaffold(
          contentWidth: ContentWidth.wide,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppLayout.top(60)),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                          ),
                          SizedBox(width: 16.w),
                          Text('Wishlist', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                          SizedBox(width: 14.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(9.r),
                            ),
                            child: Text(
                              '38 items',
                              style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppColors.redTint,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🔔', style: TextStyle(fontSize: 17.6.sp)),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Text(
                                "We'll alert you when a wishlist item is listed nearby.",
                                style: AppText.body.copyWith(fontSize: 13.2.sp, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 22.h),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(AppLayout.gutter, 0, AppLayout.gutter, 40.h),
                sliver: SliverGrid(
                  gridDelegate: responsiveGridDelegate(
                    context,
                    tileDesign: const Size(167, 206),
                    spacing: 13,
                    runSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final item = wishlist.items[i];
                    return ChipGridCard(
                      item: item,
                      showDistance: false,
                      showTypeBadge: false,
                      showOwner: false,
                      favourite: true,
                      onFavourite: () => wishlist.toggle(item),
                    );
                  }, childCount: wishlist.items.length),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
