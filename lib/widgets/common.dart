import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// Small rounded status chip — "Auction", "Sale", "Trade", "95% Match" …
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.background = AppColors.green,
    this.textColor = AppColors.white,
    this.fontSize,
    this.padding,
    this.radius,
    this.icon,
  });

  final String label;
  final Color background;
  final Color textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final double? radius;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius ?? 9.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, SizedBox(width: 5.w)],
          Text(
            label,
            style: AppText.captionBold.copyWith(
              color: textColor,
              fontSize: (fontSize ?? 12.5).sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Trending near you  ·  See all" row.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppText.h3.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppText.link.copyWith(fontSize: 11.6.sp)),
          ),
      ],
    );
  }
}

/// Dark rounded surface used for every card in the design.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
    this.color,
    this.borderColor,
    this.onTap,
    this.gradient,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double? radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? AppColors.surface) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius ?? 16.r),
          border: Border.all(color: borderColor ?? AppColors.border),
        ),
        child: child,
      ),
    );
  }
}

/// Circular monogram avatar ("VH", "HM", "VC" …).
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size,
    this.background = AppColors.redSolid,
    this.fontSize,
  });

  final String initials;
  final double? size;
  final Color background;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 52.w;
    return Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        initials,
        style: AppText.h5.copyWith(fontSize: (fontSize ?? 16).sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Screen title row with a back chevron, used on the inner pages.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.leadingIcon,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? leadingIcon;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Padding(
                padding: EdgeInsets.only(right: 14.w, top: 4.h, bottom: 4.h),
                child: Icon(Icons.arrow_back, size: 19.2.sp, color: AppColors.white),
              ),
            ),
            if (leadingIcon != null) ...[leadingIcon!, SizedBox(width: 10.w)],
            Expanded(child: Text(title, style: titleStyle ?? AppText.h2)),
            ?trailing,
          ],
        ),
        if (subtitle != null) ...[SizedBox(height: 6.h), Text(subtitle!, style: AppText.bodyDim)],
      ],
    );
  }
}
