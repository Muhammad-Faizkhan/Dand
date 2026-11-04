import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How wide a screen's content column is allowed to grow once there is more
/// room than a phone offers.
enum ContentWidth {
  /// Forms, detail pages, settings — anything that is read line by line.
  /// Capped near a comfortable measure so text never runs the full width of a
  /// tablet.
  readable,

  /// Grids, card lists and anything that answers extra width with extra
  /// columns rather than longer lines.
  wide,

  /// Maps and other full-bleed canvases. Never constrained.
  full,
}

/// The single source of truth for how the app answers a screen it was not
/// drawn for.
///
/// The design is a 390 x 844 phone frame and every widget in the app sizes
/// itself through `flutter_screenutil` (`.w` / `.h` / `.sp` / `.r`), which
/// scales linearly against that frame. On a phone that is exactly right. On a
/// tablet it is not: an 820-wide iPad would scale every padding, glyph and
/// font by 2.1x, producing a phone screenshot blown up to poster size.
///
/// Two things fix that, and this class owns both:
///
///  1. **A tapered scale** ([uiScale] / [designSizeFor]). Growth is linear
///     across the phone range and then all but stops, so a tablet renders at
///     roughly 1.24-1.30x rather than 2.1-2.6x.
///  2. **Somewhere for the leftover width to go** ([contentMaxWidth],
///     [gridColumns]). The space the taper frees up becomes margins and extra
///     grid columns instead of bigger text.
class AppResponsive {
  AppResponsive._();

  /// The frame the design was drawn on.
  static const Size phoneDesign = Size(390, 844);

  /// Shortest side at or above which a device is treated as a tablet. 600dp is
  /// the long-standing Android/iOS threshold and is orientation independent,
  /// so rotating a device never changes which branch it takes.
  static const double tabletMin = 600;

  /// `splitScreenMode: true` makes ScreenUtil treat the viewport as at least
  /// 700 tall. Mirrored here so the design height we hand it produces exactly
  /// the scale we asked for.
  static const double _splitScreenFloor = 700;

  /// Where linear growth stops. 1.22x lands just above the widest phone
  /// (~450dp shortest side scales to ~1.15x), so no phone is affected by the
  /// cap and there is no jump at the tablet threshold.
  static const double _scaleCap = 1.22;

  /// How much of the growth past [_scaleCap] still gets through. Small on
  /// purpose: a 12.9" iPad should show *more* than a 7.9" one, not a bigger
  /// version of the same thing. Across the whole tablet range this moves the
  /// scale from about 1.24 to about 1.30.
  static const double _scaleCreep = 0.06;

  // ---------------------------------------------------------------------
  // Scale
  // ---------------------------------------------------------------------

  /// The factor every `.w` / `.h` / `.sp` / `.r` in the app is multiplied by.
  ///
  /// Derived from the **shortest side**, so it is identical in portrait and
  /// landscape — rotating a tablet re-flows the layout without resizing a
  /// single glyph.
  ///
  /// The curve is continuous: below the cap it is the plain linear ratio the
  /// app has always used, above it the same value plus a trickle.
  static double uiScale(Size screen) {
    final raw = screen.shortestSide / phoneDesign.width;
    if (raw <= _scaleCap) return raw;
    return _scaleCap + (raw - _scaleCap) * _scaleCreep;
  }

  /// The design size to hand `ScreenUtilInit` for a given viewport.
  ///
  /// A phone held upright keeps the literal 390 x 844 frame, so its rendering
  /// is bit-for-bit what it has always been. Every other shape gets a design
  /// size computed back from [uiScale], which makes the horizontal and
  /// vertical scales *equal*: the frame is reproportioned to the viewport
  /// instead of stretched, so absolutely positioned artwork stays where the
  /// designer put it in any orientation.
  static Size designSizeFor(Size screen) {
    final isPhone = screen.shortestSide < tabletMin;
    final isPortrait = screen.height >= screen.width;
    if (isPhone && isPortrait) return phoneDesign;

    final scale = uiScale(screen);
    final height = math.max(screen.height, _splitScreenFloor);
    return Size(screen.width / scale, height / scale);
  }

  // ---------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------

  static Size _sizeOf(BuildContext context) => MediaQuery.sizeOf(context);

  /// True once the viewport is big enough to be worth laying out differently.
  /// Uses the shortest side, so a tablet counts in both orientations and a
  /// phone counts in neither.
  static bool isTablet(BuildContext context) => _sizeOf(context).shortestSide >= tabletMin;

  /// Scale in effect for this context, for the rare widget that needs to do
  /// its own arithmetic.
  static double scaleOf(BuildContext context) => uiScale(_sizeOf(context));

  // ---------------------------------------------------------------------
  // Content width
  // ---------------------------------------------------------------------

  /// Caps in *design units* — the same units every screen is written in, so
  /// these read against the 390-wide frame the app was drawn on.
  static const double _readableDesignWidth = 460;
  static const double _wideDesignWidth = 780;

  /// How wide the content column may grow, in logical pixels.
  ///
  /// Returns [double.infinity] on phones and for [ContentWidth.full], which
  /// makes the constraint a no-op rather than something callers must branch
  /// around.
  static double contentMaxWidth(BuildContext context, ContentWidth mode) {
    if (mode == ContentWidth.full || !isTablet(context)) return double.infinity;
    final scale = scaleOf(context);
    final design = mode == ContentWidth.readable ? _readableDesignWidth : _wideDesignWidth;
    return design * scale;
  }

  /// The width the content column actually occupies — the cap, or the screen
  /// if the screen is narrower. Used to work out column counts.
  static double contentWidth(BuildContext context, ContentWidth mode) =>
      math.min(contentMaxWidth(context, mode), _sizeOf(context).width);

  // ---------------------------------------------------------------------
  // Grids
  // ---------------------------------------------------------------------

  /// Columns for a card grid, chosen so tiles stay close to the width they
  /// have in the design rather than stretching.
  ///
  /// [tileDesignWidth] and [gutterDesignWidth] are in design units. The result
  /// is never below 2 — the design's column count — so a phone is unaffected.
  static int gridColumns(
    BuildContext context, {
    double tileDesignWidth = 167,
    double gutterDesignWidth = 22,
    double spacingDesignWidth = 14,
    ContentWidth mode = ContentWidth.wide,
    int minColumns = 2,
    int maxColumns = 5,
  }) {
    if (!isTablet(context)) return minColumns;
    final scale = scaleOf(context);
    final available = contentWidth(context, mode) - gutterDesignWidth * 2 * scale;
    final tile = tileDesignWidth * scale;
    final spacing = spacingDesignWidth * scale;
    if (tile <= 0 || available <= 0) return minColumns;
    // Solve n*tile + (n-1)*spacing <= available for n.
    final fit = ((available + spacing) / (tile + spacing)).floor();
    return fit.clamp(minColumns, maxColumns);
  }

  // ---------------------------------------------------------------------
  // Chrome
  // ---------------------------------------------------------------------

  /// Drawer width.
  ///
  /// The design's 293-unit panel carries over as-is — [uiScale] already grows
  /// it to about 370 on a tablet, in step with everything else. The cap only
  /// bites on a narrow window, where a drawer should never swallow the screen.
  static double drawerWidth(BuildContext context) =>
      math.min(293 * scaleOf(context), _sizeOf(context).width * 0.62);

  /// Width cap for modal sheets and dialogs, which otherwise stretch edge to
  /// edge on a tablet.
  static double overlayMaxWidth(BuildContext context) {
    if (!isTablet(context)) return double.infinity;
    return _readableDesignWidth * scaleOf(context);
  }
}
