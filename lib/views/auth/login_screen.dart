import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/api_feedback.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return AppScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(95)),
            Padding(
              padding: EdgeInsets.only(left: 36.w),
              child: Image.asset(AppAssets.logoSmall, width: 70.w, height: 70.w),
            ),
            SizedBox(height: 26.h),
            Padding(
              padding: EdgeInsets.only(left: 30.w),
              child: Text('Welcome back', style: AppText.h1.copyWith(fontSize: 28.sp)),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.only(left: 30.w),
              child: Text(
                'Log in to your collection.',
                style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
              ),
            ),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Email',
                    controller: auth.emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    height: 53.h,
                  ),
                  SizedBox(height: 20.h),
                  AppTextField(
                    label: 'Password',
                    controller: auth.passwordCtrl,
                    obscure: true,
                    height: 53.h,
                  ),
                  SizedBox(height: 18.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                      child: Text(
                        'Forgot password?',
                        style: AppText.link.copyWith(fontSize: 12.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 54.w),
              child: PrimaryButton(
                label: 'Log In',
                height: 54.h,
                radius: 27.r,
                onTap: () => submitAuth(
                  context,
                  (auth) => auth.login(),
                  () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false),
                ),
              ),
            ),
            SizedBox(height: 222.h),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.createAccount),
                child: Text.rich(
                  TextSpan(
                    style: AppText.bodySm.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'New Here? '),
                      TextSpan(
                        text: 'Sign up',
                        style: AppText.link.copyWith(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
