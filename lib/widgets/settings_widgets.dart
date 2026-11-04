import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// Back arrow + page title used by every settings page.
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Text(title, style: AppText.h1.copyWith(fontSize: 20.5.sp)),
        ),
        ?trailing,
      ],
    );
  }
}

/// Grouped rows with a red switch, as used on the preference pages.
class ToggleGroup extends StatelessWidget {
  const ToggleGroup({super.key, required this.rows});

  final List<ToggleRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body.copyWith(fontSize: 14.4.sp)),
                if (subtitle != null) ...[
                  SizedBox(height: 5.h),
                  Text(subtitle!, style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 58.w,
              height: 33.h,
              padding: EdgeInsets.all(3.w),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? AppColors.redSolid : const Color(0xFF3A3A3E),
                borderRadius: BorderRadius.circular(17.r),
              ),
              child: Container(
                width: 27.w,
                height: 27.w,
                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
