import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/api_feedback.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/buttons.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _reset() {
    submitAuth(context, (auth) => auth.resetPassword(_password.text, _confirm.text), () {
      showAppMessage(context, 'Password updated. Log in with your new password.');
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => r.settings.name == AppRoutes.splash);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            AuthIconBadge(icon: Icons.lock_outline_rounded, size: 60.w),
            SizedBox(height: 26.h),
            Text('Create new password', style: AppText.h1.copyWith(fontSize: 26.sp)),
            SizedBox(height: 12.h),
            Text(
              'Must be at least 8 characters.',
              style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
            ),
            SizedBox(height: 28.h),
            AppTextField(label: 'New password', controller: _password, obscure: true, height: 53.h),
            SizedBox(height: 18.h),
            AppTextField(label: 'Confirm new password', controller: _confirm, obscure: true, height: 53.h),
            SizedBox(height: 28.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: PrimaryButton(
                label: 'Reset Password',
                height: 54.h,
                radius: 27.r,
                onTap: _reset,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
