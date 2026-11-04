import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import 'buttons.dart';
import '../core/utils/responsive.dart';

/// Two-way confirmation, styled like the app's bottom sheets. [ask] returns
/// true when the user takes the action, false when they back out, and null if
/// they dismissed the dialog by tapping outside or going back — callers that
/// only act on a yes can treat null the same as false.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
  });

  final String title;
  final String message;

  /// The label on the button that goes ahead with the action.
  final String confirmLabel;

  /// The label on the button that backs out. This is the safe choice, so it is
  /// the one placed under the thumb and given the calmer styling.
  final String cancelLabel;

  /// Tints the confirm button red, for actions that undo or destroy something.
  final bool destructive;

  static Future<bool?> ask(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.62),
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      // Without a cap the dialog grows to the full width of a tablet.
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppResponsive.overlayMaxWidth(context)),
        child: Container(
          padding: EdgeInsets.fromLTRB(22.w, 26.h, 22.w, 20.h),
          decoration: BoxDecoration(
            color: AppColors.sheet,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.h2.copyWith(fontSize: 17.6.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.45),
              ),
              SizedBox(height: 24.h),
              PrimaryButton(
                label: confirmLabel,
                height: 50.h,
                radius: 14.r,
                gradient: destructive ? AppColors.redGradient : null,
                onTap: () => Navigator.pop(context, true),
              ),
              SizedBox(height: 12.h),
              SecondaryButton(
                label: cancelLabel,
                height: 50.h,
                radius: 14.r,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
