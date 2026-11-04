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

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController(text: 'Yankee');

  static const _recent = ['Yankee Bristol', 'Ellington CT', 'Sturgis rally', 'Legendary'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mk = context.watch<MarketplaceController>();
    final results = mk.items
        .where((e) => e.name.toLowerCase().contains(_ctrl.text.toLowerCase()))
        .toList();

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
                  SizedBox(height: AppLayout.top(59)),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 54.h,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: AppColors.red.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 16.8.sp, color: AppColors.textSecondary),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: TextField(
                                  controller: _ctrl,
                                  autofocus: false,
                                  style: AppText.field,
                                  cursorColor: AppColors.red,
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('Cancel', style: AppText.link.copyWith(fontSize: 14.4.sp)),
                      ),
                    ],
                  ),
                  SizedBox(height: 26.h),
                  Text(
                    'RECENT',
                    style: AppText.captionBold.copyWith(
                      fontSize: 11.2.sp,
                      letterSpacing: 0.9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: _recent
                        .map(
                          (r) => GestureDetector(
                            onTap: () {
                              _ctrl.text = r;
                              setState(() {});
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(22.r),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                r,
                                style: AppText.body.copyWith(
                                  fontSize: 12.8.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 26.h),
                  Text(
                    'RESULTS · ${results.length}',
                    style: AppText.captionBold.copyWith(
                      fontSize: 11.2.sp,
                      letterSpacing: 0.9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16.h),
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
              delegate: SliverChildBuilderDelegate(
                (context, i) => ChipGridCard(
                  item: results[i],
                  showDistance: false,
                  showTypeBadge: false,
                  showOwner: false,
                ),
                childCount: results.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
