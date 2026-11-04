import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  static const _categories = ['Casino chips', 'Coins', 'Pins', 'Patches'];
  static const _rarities = ['Common', 'Rare', 'Ultra Rare', 'Legendary'];
  static const _sorts = ['Nearest', 'Newest', 'Price ↑'];

  final Set<String> _cats = {'Casino chips'};
  int _sort = 0;

  @override
  Widget build(BuildContext context) {
    final mk = context.watch<MarketplaceController>();
    if (mk.rarities.isEmpty) {
      mk.rarities.addAll({'Rare', 'Ultra Rare'});
    }

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
                      Text('Filters', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          mk.resetFilters();
                          setState(() {
                            _cats
                              ..clear()
                              ..add('Casino chips');
                            _sort = 0;
                          });
                        },
                        child: Text(
                          'Reset',
                          style: AppText.body.copyWith(
                            fontSize: 14.4.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 26.h),
                  _label('Category'),
                  SizedBox(height: 14.h),
                  _pills(
                    _categories,
                    (c) => _cats.contains(c),
                    (c) => setState(() => _cats.contains(c) ? _cats.remove(c) : _cats.add(c)),
                  ),
                  SizedBox(height: 26.h),
                  _label('Rarity'),
                  SizedBox(height: 14.h),
                  _pills(_rarities, (c) => mk.rarities.contains(c), mk.toggleRarity),
                  SizedBox(height: 26.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Distance'),
                      Text(
                        'Within ${mk.distance.round()} mi',
                        style: AppText.h5.copyWith(fontSize: 13.6.sp, color: AppColors.red),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: _sliderTheme,
                    child: Slider(value: mk.distance, min: 5, max: 250, onChanged: mk.setDistance),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Price range'),
                      Text(
                        '\$${mk.priceRange.start.round()} – \$${mk.priceRange.end.round()}',
                        style: AppText.h5.copyWith(fontSize: 13.6.sp, color: AppColors.red),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: _sliderTheme,
                    child: RangeSlider(
                      values: mk.priceRange,
                      min: 0,
                      max: 500,
                      onChanged: mk.setPriceRange,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _label('Sort by'),
                  SizedBox(height: 14.h),
                  _pills(
                    _sorts,
                    (c) => _sorts[_sort] == c,
                    (c) => setState(() => _sort = _sorts.indexOf(c)),
                    check: false,
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 0, 25.w, 26.h),
            child: PrimaryButton(
              label: 'Show 84 results',
              height: 56.h,
              radius: 15.r,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  SliderThemeData get _sliderTheme => SliderThemeData(
    activeTrackColor: AppColors.redSolid,
    inactiveTrackColor: const Color(0xFF48484C),
    thumbColor: AppColors.white,
    overlayColor: AppColors.red.withValues(alpha: 0.15),
    trackHeight: 4.h,
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.r),
    rangeThumbShape: RoundRangeSliderThumbShape(enabledThumbRadius: 12.r),
    rangeTrackShape: const RectangularRangeSliderTrackShape(),
    showValueIndicator: ShowValueIndicator.never,
  );

  Widget _label(String t) => Text(t, style: AppText.bodyDim.copyWith(fontSize: 13.6.sp));

  Widget _pills(
    List<String> items,
    bool Function(String) isOn,
    void Function(String) onTap, {
    bool check = true,
  }) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 14.h,
      children: items.map((c) {
        final on = isOn(c);
        return GestureDetector(
          onTap: () => onTap(c),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
            decoration: BoxDecoration(
              gradient: on ? AppColors.redGradient : null,
              color: on ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: on ? Colors.transparent : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c,
                  style: AppText.body.copyWith(
                    fontSize: 13.2.sp,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                    color: on ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
                if (on && check) ...[
                  SizedBox(width: 7.w),
                  Icon(Icons.check, size: 13.6.sp, color: AppColors.white),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
