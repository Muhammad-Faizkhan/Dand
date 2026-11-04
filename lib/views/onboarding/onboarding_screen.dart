import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';

const _kBodies = [
  'Snap a photo and our AI identifies the dealer, year, and rarity your collection organizes itself.',
  'Smart matches find people who want what you have swap chips locally or ship nationwide.',
  'Browse the marketplace, place bids on rare finds, and cash out with secure escrow payments.',
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _finish() {
    context.read<AuthController>().setOnboardingPage(2);
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    // The design puts the CTA 53 above the bottom of the 844 frame. Anchoring
    // it there — rather than at a design Y measured from the top — keeps it
    // clear of the home indicator on every screen height, and the floor keeps
    // it clear of a taller gesture area too.
    final ctaBottom = math.max(53.h, MediaQuery.viewPaddingOf(context).bottom + 19.h);

    return AppScaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: const [_PageCatalog(), _PageTrade(), _PageBuySell()],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: ctaBottom + 82.h,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.symmetric(horizontal: 5.w),
                    width: active ? 27.w : 7.w,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: active ? AppColors.redSolid : const Color(0xFF4A4A4E),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            left: 53.w,
            right: 53.w,
            bottom: ctaBottom,
            child: PrimaryButton(
              label: _page == 2 ? 'Get Started' : 'Next',
              height: 50.h,
              radius: 25.r,
              onTap: _next,
            ),
          ),
          Positioned(
            right: 21.w,
            top: 26.h,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _finish,
              child: Container(
                width: 96.w,
                height: 33.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11.r),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Text('Skip', style: AppText.h5.copyWith(fontSize: 12.8.sp)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared title + supporting copy block underneath each illustration card.
class _Copy extends StatelessWidget {
  const _Copy({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.h1.copyWith(fontSize: 20.5.sp),
        ),
        SizedBox(height: 18.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 34.w),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.55),
          ),
        ),
      ],
    );
  }
}

/// Holds one onboarding page.
///
/// Each page is a fixed column measured off the 844-high design frame, which
/// is taller than the space a phone turned sideways has to give. Scrolling
/// instead of overflowing keeps every page reachable, and the trailing gap
/// keeps the copy clear of the dots and CTA that sit over the pager. On a
/// frame with room to spare the column never scrolls, so nothing moves.
class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.only(bottom: 150.h),
    child: child,
  );
}

class _PageCatalog extends StatelessWidget {
  const _PageCatalog();

  @override
  Widget build(BuildContext context) {
    return _PageScroll(
      child: Column(
        children: [
          SizedBox(height: 165.h),
          Center(
            child: Container(
              width: 224.w,
              height: 220.h,
              decoration: BoxDecoration(
                color: const Color(0xFF17171A),
                borderRadius: BorderRadius.circular(26.r),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Image.asset(AppAssets.chipClassicReading, width: 130.w),
                    ),
                  ),
                  Positioned(
                    right: 12.w,
                    bottom: 14.h,
                    child: StatusBadge(
                      label: 'AI scan',
                      background: AppColors.redSolid,
                      radius: 11.r,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                      icon: Icon(Icons.auto_awesome, size: 10.4.sp, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 42.h),
          _Copy(title: 'Catalog every chip', body: _kBodies[0]),
        ],
      ),
    );
  }
}

class _PageTrade extends StatelessWidget {
  const _PageTrade();

  @override
  Widget build(BuildContext context) {
    return _PageScroll(
      child: Column(
        children: [
          SizedBox(height: 180.h),
          Center(
            child: Container(
              width: 343.w,
              height: 224.h,
              decoration: BoxDecoration(
                color: const Color(0xFF17171A),
                borderRadius: BorderRadius.circular(26.r),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.chipYankeeSm, width: 84.w),
                  SizedBox(width: 22.w),
                  Container(
                    width: 44.w,
                    height: 44.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                    child: Icon(Icons.swap_horiz_rounded, color: AppColors.white, size: 19.2.sp),
                  ),
                  SizedBox(width: 22.w),
                  Image.asset(AppAssets.chipBuckeye, width: 84.w),
                ],
              ),
            ),
          ),
          SizedBox(height: 40.h),
          _Copy(title: 'Trade with collectors', body: _kBodies[1]),
        ],
      ),
    );
  }
}

class _PageBuySell extends StatelessWidget {
  const _PageBuySell();

  @override
  Widget build(BuildContext context) {
    return _PageScroll(
      child: Column(
        children: [
          SizedBox(height: 180.h),
          Center(
            child: SizedBox(
              width: 224.w,
              height: 224.h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF17171A),
                      borderRadius: BorderRadius.circular(26.r),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
                    ),
                    child: Center(child: Image.asset(AppAssets.chipSouthside, width: 108.w)),
                  ),
                  Positioned(
                    left: 14.w,
                    top: 16.h,
                    child: StatusBadge(
                      label: 'Live auction',
                      background: AppColors.green,
                      radius: 12.r,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                      icon: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12.w,
                    bottom: 16.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E21),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text('\$110', style: AppText.price.copyWith(fontSize: 12.sp)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 40.h),
          _Copy(title: 'Buy, sell & trade', body: _kBodies[2]),
        ],
      ),
    );
  }
}
