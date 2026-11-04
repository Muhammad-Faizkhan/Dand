import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';

class TrackOrderScreen extends StatelessWidget {
  const TrackOrderScreen({super.key});

  static const _steps = <(String, String, int)>[
    ('Order confirmed', 'Jul 16, 10:24 AM', 0),
    ('Packed by seller', 'Jul 17, 3:10 PM', 0),
    ('In transit', 'Currently on the way', 1),
    ('Delivered', 'Est. Jul 21–23', 2),
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
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                ),
                SizedBox(width: 16.w),
                Text('Track Order', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
              ],
            ),
            SizedBox(height: 26.h),
            Container(
              height: 86.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58.w,
                    height: 58.w,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(AppData.yankeeBristol.image, fit: BoxFit.cover),
                  ),
                  SizedBox(width: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Yankee Bristol', style: AppText.h3.copyWith(fontSize: 16.sp)),
                      SizedBox(height: 5.h),
                      Text(
                        'Order #DD-9142 · \$53.00',
                        style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),
            for (var i = 0; i < _steps.length; i++) _TimelineRow(index: i, last: i == 3),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w),
              child: SecondaryButton(
                label: 'Message Seller',
                height: 56.h,
                radius: 15.r,
                onTap: () => Navigator.pushNamed(context, AppRoutes.chat, arguments: 'Tom'),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.index, required this.last});

  final int index;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final (title, sub, state) = TrackOrderScreen._steps[index];
    final done = state == 0;
    final current = state == 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.planBlue : Colors.transparent,
                  border: Border.all(
                    color: done || current ? AppColors.planBlue : const Color(0xFF3A3A3E),
                    width: 2,
                  ),
                ),
                child: done
                    ? Icon(Icons.check, size: 12.8.sp, color: AppColors.white)
                    : current
                    ? Container(
                        width: 11.w,
                        height: 11.w,
                        decoration: const BoxDecoration(
                          color: AppColors.planBlue,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2.w,
                    color: done ? AppColors.planBlue : const Color(0xFF3A3A3E),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 22.h : 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.h4.copyWith(
                      fontSize: 15.2.sp,
                      color: state == 2 ? AppColors.textSecondary : AppColors.white,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    sub,
                    style: AppText.bodyDim.copyWith(
                      fontSize: 12.8.sp,
                      color: current ? const Color(0xFF5470F0) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
