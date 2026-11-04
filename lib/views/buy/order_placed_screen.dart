import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../../widgets/success_view.dart';

class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: AppLayout.gutter, top: AppLayout.top(65)),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
            ),
          ),
          SuccessView(
            topSpace: 170,
            title: 'Order placed!',
            message: 'Your Yankee Bristol is on its way.\nHDCollector will ship within 2 days.',
            details: [
              MapEntry(
                'Status',
                StatusBadge(
                  label: 'Processing',
                  background: AppColors.planBlue.withValues(alpha: 0.25),
                  textColor: const Color(0xFF7E97F0),
                  radius: 8.r,
                  fontSize: 15,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                ),
              ),
              MapEntry('Order ID', Text('#DD-9142', style: AppText.h5.copyWith(fontSize: 13.6.sp))),
              MapEntry(
                'Est. delivery',
                Text('Jul 21–23', style: AppText.h5.copyWith(fontSize: 13.6.sp)),
              ),
            ],
            secondaryFirst: false,
            primaryLabel: 'Track Order',
            onPrimary: () => Navigator.pushNamed(context, AppRoutes.trackOrder),
            secondaryLabel: 'Back to Home',
            onSecondary: () =>
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false),
          ),
        ],
      ),
    );
  }
}
