import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/settings_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _items = <(IconData, String, String)>[
    (Icons.notifications_none_rounded, 'Push Notifications', AppRoutes.pushNotifications),
    (Icons.lock_outline_rounded, 'Change Password', AppRoutes.changePassword),
    (Icons.copy_rounded, 'Preferences', AppRoutes.tradePreferences),
    (Icons.description_outlined, 'Privacy Policy', AppRoutes.privacyPolicy),
    (Icons.description_outlined, 'Terms & Condition', AppRoutes.terms),
    (Icons.help_outline_rounded, 'Help & Feedback', AppRoutes.helpFeedback),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(62)),
            SettingsHeader(title: 'Settings'),
            SizedBox(height: 24.h),
            for (final (icon, label, route) in _items) ...[
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, route),
                child: Container(
                  height: 68.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 16.8.sp, color: AppColors.white),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(label, style: AppText.body.copyWith(fontSize: 14.4.sp)),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 19.2.sp,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
            ],
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
