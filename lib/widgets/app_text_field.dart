import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// Labelled dark input used on every form screen in the design.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscure = false,
    this.showToggle = true,
    this.keyboardType,
    this.suffix,
    this.prefix,
    this.height,
    this.maxLines = 1,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;

  /// Whether an obscured field gets the eye toggle. On by default so no
  /// password field in the app can end up without one.
  final bool showToggle;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final Widget? prefix;
  final double? height;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppText.label),
          SizedBox(height: 8.h),
        ],
        Container(
          height: widget.maxLines > 1 ? null : (widget.height ?? 56.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (widget.prefix != null) ...[widget.prefix!, SizedBox(width: 10.w)],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: _obscured,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  onChanged: widget.onChanged,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  style: AppText.field,
                  cursorColor: AppColors.red,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: widget.maxLines > 1 ? 16.h : 0),
                    hintText: widget.hint,
                    hintStyle: AppText.field.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
              if (widget.obscure && widget.showToggle)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _obscured = !_obscured),
                  child: Padding(
                    // Widens the target to the 44 minimum without moving the
                    // icon off the field's 16 inset.
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                    child: Icon(
                      _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 19.2.sp,
                      color: AppColors.textSecondary,
                      semanticLabel: _obscured ? 'Show password' : 'Hide password',
                    ),
                  ),
                ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
      ],
    );
  }
}

/// Labelled select box with the small chevron used on the listing forms.
class DropdownField extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label),
        SizedBox(height: 8.h),
        Container(
          height: 58.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12.r),
              icon: Icon(Icons.arrow_drop_down, size: 17.6.sp, color: AppColors.textSecondary),
              style: AppText.field,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => v == null ? null : onChanged(v),
            ),
          ),
        ),
      ],
    );
  }
}
