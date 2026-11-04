import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/utils/responsive.dart';

/// Holds a screen's content to a comfortable measure and centres it once the
/// viewport is wider than a phone.
///
/// On a phone this is a pass-through — [AppResponsive.contentMaxWidth] returns
/// infinity, the widget returns its child untouched and nothing about the
/// existing rendering changes.
///
/// The child is handed **tight** constraints (the capped width, the full
/// incoming height) rather than loose ones. That matters: several screens are
/// a [Stack] of nothing but `Positioned` children, which would collapse to
/// zero height under the loose constraints an [Align] or [Center] would
/// otherwise pass down.
class ResponsiveCanvas extends StatelessWidget {
  const ResponsiveCanvas({super.key, required this.child, this.width = ContentWidth.readable});

  final Widget child;
  final ContentWidth width;

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppResponsive.contentMaxWidth(context, width);
    if (maxWidth == double.infinity) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth <= maxWidth) {
          return child;
        }
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxWidth,
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}

/// A column that fills the viewport when there is room and scrolls when there
/// is not.
///
/// The screens built as a fixed [Column] with a `Spacer` in the middle sit at
/// exactly the height of the design frame. That is fine upright, but a tablet
/// turned on its side has far less height to give, and a plain Column would
/// overflow. This keeps the `Spacer` working whenever the content fits and
/// falls back to scrolling when it does not.
class FillOrScroll extends StatelessWidget {
  const FillOrScroll({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = padding?.vertical ?? 0;
        final minHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - vertical).clamp(0.0, double.infinity)
            : 0.0;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}

/// Grid delegate for the card grids, with a column count that follows the
/// viewport instead of being pinned at the design's two.
///
/// [tileDesign] is the tile's width x height in design units, so the tiles keep
/// their drawn proportions whatever the column count turns out to be.
SliverGridDelegate responsiveGridDelegate(
  BuildContext context, {
  required Size tileDesign,
  double spacing = 14,
  double runSpacing = 14,
  ContentWidth mode = ContentWidth.wide,
  int maxColumns = 5,
}) {
  final columns = AppResponsive.gridColumns(
    context,
    tileDesignWidth: tileDesign.width,
    spacingDesignWidth: spacing,
    mode: mode,
    maxColumns: maxColumns,
  );
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    mainAxisSpacing: runSpacing.h,
    crossAxisSpacing: spacing.w,
    childAspectRatio: tileDesign.width / tileDesign.height,
  );
}
