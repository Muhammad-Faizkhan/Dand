import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive.dart';
import 'responsive_layout.dart';

/// The dark, red-grunge texture that sits behind every screen in the design.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.overlay});

  final Widget child;
  final Color? overlay;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        image: DecorationImage(
          image: AssetImage(AppAssets.bgTexture),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
      child: overlay == null
          ? child
          : DecoratedBox(
              decoration: BoxDecoration(color: overlay),
              child: child,
            ),
    );
  }
}

/// Convenience scaffold: texture background + transparent chrome.
///
/// This is also where the app answers a viewport wider than a phone: the body
/// is held to [contentWidth] and centred, so a tablet gets margins and a
/// readable measure instead of a line of text running the full width of the
/// screen. The texture behind it stays full-bleed.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.extendBody = true,
    this.resizeToAvoidBottomInset = true,
    this.safeAreaTop = true,
    this.safeAreaBottom = false,
    this.contentWidth = ContentWidth.readable,
  });

  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final bool extendBody;
  final bool resizeToAvoidBottomInset;
  final bool safeAreaTop;
  final bool safeAreaBottom;

  /// How far the body may spread on a viewport wider than a phone. Screens
  /// that answer width with more columns pass [ContentWidth.wide]; full-bleed
  /// canvases such as the map pass [ContentWidth.full].
  final ContentWidth contentWidth;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: extendBody,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        drawer: drawer,
        drawerScrimColor: const Color(0x99000000),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        body: SafeArea(
          top: safeAreaTop,
          bottom: safeAreaBottom,
          child: ResponsiveCanvas(width: contentWidth, child: body),
        ),
      ),
    );
  }
}
