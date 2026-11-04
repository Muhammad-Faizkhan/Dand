import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/app_controller.dart';
import '../core/routes/app_routes.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive.dart';
import 'responsive_layout.dart';

class NavTab {
  const NavTab(this.icon, this.label, {required this.iconHeight, required this.iconTop});

  final String icon;
  final String label;

  /// Height the glyph's canvas is drawn at. The four exports are cropped with
  /// different margins, so each gets the height that lands its artwork on the
  /// size it has in the Figma frames (23.8, or 20.8 for the map pin).
  final double iconHeight;

  /// Offset of the canvas' top edge from the top edge of the bar, chosen so
  /// all four artworks share the design's baseline 45.6 above the bar bottom.
  ///
  /// The glyphs are flat `AppColors.navBar` outside the artwork rather than
  /// transparent — that is how they come out of the design export, and it is
  /// what keeps their darkest pixels reading exactly as they do in Figma.
  final double iconTop;
}

const List<NavTab> kNavTabs = [
  NavTab(AppAssets.navHome, 'Home', iconHeight: 30.74, iconTop: 18.93),
  NavTab(AppAssets.navMarket, 'Market', iconHeight: 30.74, iconTop: 18.93),
  NavTab(AppAssets.navMap, 'Map', iconHeight: 34.32, iconTop: 18.74),
  NavTab(AppAssets.navProfile, 'Profile', iconHeight: 27.08, iconTop: 18.62),
];

/// Bottom bar with the four glyph tabs, the active indicator and the docked
/// red "+" action.
///
/// Every number here is measured off the Figma frames (390 x 844):
///
/// * the bar is 91 tall — `#09090B` under a 1px `#161617` hairline — of which
///   the bottom 19.8 is the home-indicator gap, widened on devices that need
///   more;
/// * tab centres sit at x = 60.5 / 131.5 / 258.5 / 329.5. They are
///   deliberately *not* evenly spaced: the pairs hug the sides so the docked
///   "+" has the middle to itself;
/// * the active indicator is a 55 x 6 `#A2141A` bar flush with the top edge of
///   the bar, bottom corners rounded, centred on the active tab;
/// * glyphs are 23.8 tall (20.8 for the map pin) sitting on a common baseline
///   45.6 above the bottom of the bar, labels are Inter 400/14 with their cap
///   line 57.6 below the top edge.
///
/// The tab content and the indicator both derive their x from [_centres], so
/// the indicator cannot drift off its icon on any screen width.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap, this.onAdd});

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAdd;

  /// Tab centres as a fraction of the bar width (design x / 390).
  static const List<double> _centres = [0.15513, 0.33718, 0.66282, 0.84487];

  /// Tap-region edges as a fraction of the bar width. The gap between the two
  /// inner entries belongs to the docked "+", which hit-tests itself.
  static const List<List<double>> _hitRegions = [
    [0.0, 0.24615],
    [0.24615, 0.42949],
    [0.57051, 0.75385],
    [0.75385, 1.0],
  ];

  /// Bar content above the bottom home-indicator gap.
  static double get _contentHeight => 71.2.w;

  /// The bottom gap baked into the design frames.
  static double get _designBottomGap => 19.8.w;

  /// How far the docked "+" rises above the top edge of the bar.
  static double get _addOverhang => 31.5.w;

  /// Height of the bar on the design frames. [heightOf] is the one to use for
  /// scroll padding — it also covers the device's gesture inset.
  static double get barHeight => _contentHeight + _designBottomGap;

  /// Height the bar occupies on this device, safe area included.
  static double heightOf(BuildContext context) =>
      _contentHeight + math.max(_designBottomGap, MediaQuery.viewPaddingOf(context).bottom);

  @override
  Widget build(BuildContext context) {
    final barH = heightOf(context);

    return SizedBox(
      height: barH + _addOverhang,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barH,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.navBar,
                border: Border(top: BorderSide(color: AppColors.navBorder, width: 1)),
              ),
              // The tab centres are fractions of the bar's width. Left to span
              // a tablet they would push the two pairs into the far corners
              // and leave the docked "+" marooned in the middle, so the row of
              // tabs keeps a phone-like measure and centres under the "+"
              // while the bar itself stays full-bleed.
              child: ResponsiveCanvas(
                width: ContentWidth.readable,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return Stack(
                      children: [
                        for (var i = 0; i < kNavTabs.length; i++)
                          Positioned(
                            left: _hitRegions[i][0] * width,
                            width: (_hitRegions[i][1] - _hitRegions[i][0]) * width,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onTap(i),
                            ),
                          ),
                        for (var i = 0; i < kNavTabs.length; i++)
                          Positioned(
                            left: _centres[i] * width - 45.w,
                            width: 90.w,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: _TabContent(
                                key: Key('nav-tab-$i'),
                                tab: kNavTabs[i],
                                active: i == currentIndex,
                              ),
                            ),
                          ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          left: _centres[currentIndex] * width - 27.5.w,
                          top: 0,
                          child: IgnorePointer(
                            child: Container(
                              key: const Key('nav-indicator'),
                              width: 55.w,
                              height: 6.w,
                              decoration: BoxDecoration(
                                color: AppColors.navIndicator,
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.w)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: barH + _addOverhang - 55.w,
            child: Center(
              child: GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 55.w,
                  height: 55.w,
                  decoration: BoxDecoration(
                    gradient: AppColors.navAddGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.red.withValues(alpha: 0.32),
                        blurRadius: 22.r,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, color: AppColors.white, size: 25.w),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({super.key, required this.tab, required this.active});

  final NavTab tab;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: tab.iconTop.w,
          left: 0,
          right: 0,
          child: Center(
            child: Image.asset(
              key: const Key('nav-tab-icon'),
              tab.icon,
              height: tab.iconHeight.w,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        Positioned(
          top: 54.2.w,
          left: 0,
          right: 0,
          child: Text(
            tab.label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14.sp,
              height: 1.21,
              fontWeight: FontWeight.w400,
              color: active ? AppColors.redSolid : AppColors.navLabel,
            ),
          ),
        ),
      ],
    );
  }
}

/// The same bar, wired for screens pushed on top of the shell (Collections and
/// friends): tapping a tab returns to [AppRoutes.main] with that tab selected
/// instead of stacking another copy of the shell.
class ShellBottomNav extends StatelessWidget {
  const ShellBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  /// Selects [index] in the shell and unwinds back to it, rebuilding the shell
  /// if it is somehow no longer on the stack.
  static void openTab(BuildContext context, int index) {
    context.read<NavController>().setIndex(index);
    final navigator = Navigator.of(context);
    var foundShell = false;
    navigator.popUntil((route) {
      foundShell = route.settings.name == AppRoutes.main;
      return foundShell || route.isFirst;
    });
    if (!foundShell) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomNav(
      currentIndex: currentIndex,
      onTap: (i) => openTab(context, i),
      onAdd: () => Navigator.pushNamed(context, AppRoutes.addItem),
    );
  }
}
