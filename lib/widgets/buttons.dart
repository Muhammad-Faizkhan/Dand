import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// The primary red gradient CTA used across the whole app, glow included.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.height,
    this.enabled = true,
    this.radius,
    this.icon,
    this.textStyle,
    this.glow = true,
    this.gradient,
    this.glowColor,
  });

  final String label;
  final VoidCallback? onTap;
  final double? height;
  final bool enabled;
  final double? radius;
  final Widget? icon;
  final TextStyle? textStyle;
  final bool glow;
  final Gradient? gradient;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius ?? 16.r);
    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: height ?? 56.h,
          decoration: BoxDecoration(
            gradient: gradient ?? AppColors.redGradient,
            borderRadius: r,
            boxShadow: glow && enabled
                ? [
                    BoxShadow(
                      color: (glowColor ?? AppColors.red).withValues(alpha: 0.35),
                      blurRadius: 26.r,
                      spreadRadius: -2,
                      offset: Offset(0, 8.h),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[icon!, SizedBox(width: 8.w)],
                Text(label, style: textStyle ?? AppText.button),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Flat dark button with a hairline border ("I HAVE THIS", "Upload", ...).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.height,
    this.radius,
    this.icon,
    this.color,
    this.borderColor,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onTap;
  final double? height;
  final double? radius;
  final Widget? icon;
  final Color? color;
  final Color? borderColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 56.h,
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: BorderRadius.circular(radius ?? 16.r),
          border: Border.all(color: borderColor ?? AppColors.border, width: 1),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, SizedBox(width: 8.w)],
              Text(label, style: textStyle ?? AppText.button),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round translucent icon button (back arrow, favourite, close).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size,
    this.iconSize,
    this.background,
    this.iconColor,
    this.border,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double? size;
  final double? iconSize;
  final Color? background;
  final Color? iconColor;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final s = size ?? 44.w;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: background ?? AppColors.surface,
          shape: BoxShape.circle,
          border: border != null ? Border.all(color: border!) : null,
        ),
        child: Icon(icon, size: iconSize ?? 21.sp, color: iconColor ?? AppColors.white),
      ),
    );
  }
}
