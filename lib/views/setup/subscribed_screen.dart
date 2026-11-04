import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../../widgets/success_view.dart';

class SubscribedScreen extends StatelessWidget {
  const SubscribedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SuccessView(
        topSpace: 136,
        title: 'Successfully Subscribed',
        message: 'You have successfully\nsubscribed silver Subcsription',
        details: [
          MapEntry(
            'Status',
            StatusBadge(
              label: 'Active',
              background: AppColors.planBlue.withValues(alpha: 0.25),
              textColor: const Color(0xFF7E97F0),
              radius: 8.r,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              fontSize: 15,
            ),
          ),
          MapEntry('Client ID', Text('#DD-9142', style: AppText.h5.copyWith(fontSize: 12.8.sp))),
          MapEntry(
            'Starts From',
            Text('Aug 1, 2026', style: AppText.h5.copyWith(fontSize: 12.8.sp)),
          ),
        ],
        secondaryLabel: 'Go to Home',
        onSecondary: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false),
      ),
    );
  }
}
