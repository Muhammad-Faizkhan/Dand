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

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

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
            SizedBox(height: 30.h),
            AuthIconBadge(icon: Icons.mail_outline_rounded, size: 60.w),
            SizedBox(height: 26.h),
            Text('Forgot password?', style: AppText.h1.copyWith(fontSize: 26.sp)),
            SizedBox(height: 12.h),
            Text(
              "Enter your email and we'll send you a 6 Digit OTP.",
              style: AppText.bodyDim.copyWith(fontSize: 13.2.sp, height: 1.45),
            ),
            SizedBox(height: 30.h),
            AppTextField(
              label: 'Email',
              controller: auth.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              height: 53.h,
            ),
            SizedBox(height: 26.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: PrimaryButton(
                label: 'Send OTP',
                height: 54.h,
                radius: 27.r,
                onTap: () => submitAuth(
                  context,
                  (auth) => auth.requestPasswordReset(),
                  () => Navigator.pushNamed(context, AppRoutes.enterOtp),
                ),
              ),
            ),
            SizedBox(height: 22.h),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.popUntil(context, ModalRoute.withName(AppRoutes.login)),
                child: Text('Back to login', style: AppText.bodyDim.copyWith(fontSize: 13.2.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
