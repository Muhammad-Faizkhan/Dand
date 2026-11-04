import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/dealers_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_data.dart';
import '../../widgets/app_background.dart';
import 'map_screen.dart';
import '../../core/utils/responsive.dart';

/// Map with the "Dealers near you" sheet pulled up.
class MapDealersScreen extends StatelessWidget {
  const MapDealersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DealersController?>();
    final live = ctrl?.client != null;
    // (name, rating, wishlist items, distance) for the design data; (name, address, distance) when live.
    final rows = live
        ? [for (final d in ctrl!.dealers) (d.name, d.address.isEmpty ? 'Dealer' : d.address, d.distance)]
        : [for (final (name, rating, items, distance) in AppData.shops) (name, '⭐ $rating · $items wishlist items', distance)];
    final found = live ? '${rows.length} found' : '16 found';
    return AppScaffold(
      contentWidth: ContentWidth.full,
      safeAreaTop: false,
      body: Stack(
        children: [
          const Positioned.fill(child: MapScreen(showBack: true, showSearch: false)),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppResponsive.overlayMaxWidth(context)),
              child: Container(
                height: 424.h,
                padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 16.h),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A4A4E),
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 26.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Dealers near you', style: AppText.h1.copyWith(fontSize: 20.sp)),
                        const Spacer(),
                        Text(found, style: AppText.bodyDim.copyWith(fontSize: 13.6.sp)),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    if (live && rows.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            ctrl!.loading
                                ? 'Finding dealers…'
                                : ctrl.located
                                ? 'No dealers within 100 miles yet.'
                                : 'No dealers listed yet.',
                            textAlign: TextAlign.center,
                            style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
                          ),
                        ),
                      )
                    else
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => SizedBox(height: 14.h),
                        itemBuilder: (context, i) {
                          final (name, detail, distance) = rows[i];
                          return Container(
                            height: 88.h,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(15.r),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 58.w,
                                  height: 58.w,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.redGradient,
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Icon(
                                    Icons.storefront_outlined,
                                    size: 20.8.sp,
                                    color: AppColors.white,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(name, style: AppText.h4.copyWith(fontSize: 15.2.sp)),
                                      SizedBox(height: 5.h),
                                      Text(
                                        distance.isEmpty ? detail : '$detail · $distance',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.bodyDim.copyWith(fontSize: 12.4.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 19.2.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
