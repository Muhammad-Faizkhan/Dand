import 'package:flutter/material.dart';
import '../../widgets/chip_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/models.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/utils/responsive.dart';

class AddToTradeScreen extends StatelessWidget {
  const AddToTradeScreen({super.key, this.empty = false});

  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Consumer<TradeController>(
      builder: (context, trade, _) {
        final items = empty ? const <ChipItem>[] : trade.myCollection;
        final count = trade.offered.length;

        return AppScaffold(
          contentWidth: ContentWidth.wide,
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: AppLayout.top(61)),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Icon(
                                    Icons.arrow_back,
                                    size: 20.8.sp,
                                    color: AppColors.white,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Text('Add to trade', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Padding(
                              padding: EdgeInsets.only(left: 42.w),
                              child: Text(
                                'Pick an item from your collection to give',
                                style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                              ),
                            ),
                            SizedBox(height: 22.h),
                            AppTextField(
                              hint: 'Search your collection',
                              height: 56.h,
                              prefix: Icon(
                                Icons.search,
                                size: 16.8.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 20.h),
                            if (empty)
                              Padding(
                                padding: EdgeInsets.only(top: 120.h),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 44.8.sp,
                                        color: AppColors.textTertiary,
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        'Nothing in your collection yet',
                                        style: AppText.bodyDim.copyWith(fontSize: 13.6.sp),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                      sliver: SliverGrid(
                        gridDelegate: responsiveGridDelegate(
                          context,
                          tileDesign: const Size(167, 206),
                          spacing: 13,
                          runSpacing: 14,
                        ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final item = items[i];
                          final selected = trade.isOffered(item);
                          return GestureDetector(
                            onTap: () => trade.toggleOffer(item),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: selected ? AppColors.redSolid : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      color: AppColors.surface,
                                      child: ChipImage(item),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(12.w, 9.h, 12.w, 10.h),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppText.h4.copyWith(fontSize: 13.2.sp),
                                        ),
                                        SizedBox(height: 3.h),
                                        Text(
                                          'Est. ${item.priceLabel}',
                                          style: AppText.h5.copyWith(
                                            fontSize: 12.8.sp,
                                            fontWeight: FontWeight.w700,
                                            color: selected
                                                ? AppColors.red
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: items.length),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 26.h),
                child: PrimaryButton(
                  label: count == 0 ? 'Add items' : 'Add $count item${count == 1 ? '' : 's'}',
                  height: 56.h,
                  radius: 15.r,
                  enabled: count > 0,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
