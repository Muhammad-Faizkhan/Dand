import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/api_feedback.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/buttons.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(75)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
            ),
            SizedBox(height: 22.h),
            const StepProgress(step: 1),
            SizedBox(height: 26.h),
            AuthIconBadge(icon: Icons.mail_outline_rounded, size: 60.w),
            SizedBox(height: 24.h),
            Text('Verify your email', style: AppText.h1.copyWith(fontSize: 26.sp)),
            SizedBox(height: 12.h),
            Text(
              "We'll email you a code to confirm it's really you.",
              style: AppText.bodyDim.copyWith(fontSize: 13.2.sp, height: 1.45),
            ),
            SizedBox(height: 30.h),
            AppTextField(
              label: 'Email address',
              controller: auth.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              height: 53.h,
            ),
            SizedBox(height: 26.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: PrimaryButton(
                label: 'Send Code',
                height: 54.h,
                radius: 27.r,
                onTap: () => submitAuth(
                  context,
                  (auth) => auth.resendVerification(),
                  () => Navigator.pushNamed(context, AppRoutes.enterCode),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
