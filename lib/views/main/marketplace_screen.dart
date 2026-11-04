import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/chip_grid_card.dart';
import '../../widgets/responsive_layout.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, required this.onMenu, required this.onTab});

  final VoidCallback onMenu;
  final ValueChanged<int> onTab;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mk = context.read<MarketplaceController>();
      if (!mk.hasApiData && !mk.loading) mk.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceController>(
      builder: (context, mk, _) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppLayout.top(60)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onMenu,
                          child: Container(
                            width: 44.w,
                            height: 44.w,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.grid_view_rounded,
                              size: 16.8.sp,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Text('Marketplace', style: AppText.h1.copyWith(fontSize: 22.5.sp)),
                        const Spacer(),
                        _RoundAction(
                          icon: Icons.search,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                        ),
                        SizedBox(width: 12.w),
                        _RoundAction(
                          icon: Icons.tune_rounded,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.filters),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 22.h),
                  SizedBox(
                    height: 44.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                      itemCount: MarketplaceController.filters.length,
                      separatorBuilder: (_, _) => SizedBox(width: 12.w),
                      itemBuilder: (context, i) {
                        final active = mk.filter == i;
                        return GestureDetector(
                          onTap: () => mk.setFilter(i),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 22.w),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: active ? AppColors.redGradient : null,
                              color: active ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(22.r),
                              border: Border.all(
                                color: active ? Colors.transparent : AppColors.border,
                              ),
                            ),
                            child: Text(
                              MarketplaceController.filters[i],
                              style: AppText.body.copyWith(
                                fontSize: 12.8.sp,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                color: active ? AppColors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: mk.loading
                        ? Row(
                            children: [
                              SizedBox(
                                width: 14.w,
                                height: 14.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Loading listings…',
                                style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                              ),
                            ],
                          )
                        : Text(
                            '📈 ${mk.total > 0 ? mk.total : mk.items.length} active listings',
                            style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                          ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
                      decoration: BoxDecoration(
                        color: AppColors.redTint,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Match',
                            style: AppText.h4.copyWith(fontSize: 15.2.sp, color: AppColors.red),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '3 dealers have wishlist items near you',
                            style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                          ),
                          SizedBox(height: 16.h),
                          GestureDetector(
                            onTap: () => widget.onTab(2),
                            child: Container(
                              height: 46.h,
                              width: 158.w,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppColors.redGradient,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'View on Map',
                                style: AppText.button.copyWith(fontSize: 13.6.sp),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppLayout.gutter,
                0,
                AppLayout.gutter,
                AppBottomNav.heightOf(context) + 20.h,
              ),
              sliver: SliverGrid(
                gridDelegate: responsiveGridDelegate(
                  context,
                  tileDesign: const Size(167, 206),
                  spacing: 13,
                  runSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ChipGridCard(item: mk.items[i]),
                  childCount: mk.items.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46.w,
        height: 46.w,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Icon(icon, size: 17.6.sp, color: AppColors.white),
      ),
    );
  }
}
