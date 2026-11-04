import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/api_feedback.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/image_source_sheet.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  String? _avatarPath;

  Future<void> _pickAvatar() async {
    final path = await ImageSourceSheet.pick(
      context,
      title: 'Profile photo',
      canRemove: _avatarPath != null,
    );
    if (path == null || !mounted) return;
    setState(() => _avatarPath = path.isEmpty ? null : path);
  }

  /// The picked photo can only be uploaded once the account exists, so it goes
  /// up right after registering. A failed upload doesn't block sign-up.
  Future<bool> _register(AuthController auth) async {
    final ok = await auth.register();
    final path = _avatarPath;
    if (ok && path != null && mounted) {
      await context.read<ProfileController>().uploadAvatar(path);
    }
    return ok;
  }

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
            Text('Create account', style: AppText.h1.copyWith(fontSize: 27.sp)),
            SizedBox(height: 8.h),
            Text(
              'Join the collector community.',
              style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
            ),
            SizedBox(height: 30.h),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _pickAvatar,
                child: SizedBox(
                  width: 92.w,
                  height: 82.w,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 78.w,
                        height: 78.w,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.06),
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.55)),
                        ),
                        child: _avatarPath == null
                            ? Icon(Icons.person_outline, color: AppColors.white, size: 25.6.sp)
                            : Image.file(
                                File(_avatarPath!),
                                fit: BoxFit.cover,
                                width: 78.w,
                                height: 78.w,
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 4.h,
                        child: Container(
                          width: 30.w,
                          height: 30.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.redSolid,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 2),
                          ),
                          child: Icon(Icons.photo_camera, color: AppColors.white, size: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 26.h),
            AppTextField(label: 'Full name', controller: auth.nameCtrl, height: 53.h),
            SizedBox(height: 18.h),
            AppTextField(
              label: 'Email',
              controller: auth.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              height: 53.h,
            ),
            SizedBox(height: 18.h),
            AppTextField(
              label: 'Password',
              controller: auth.passwordCtrl,
              obscure: true,
              height: 53.h,
            ),
            SizedBox(height: 18.h),
            AppTextField(
              label: 'Confirm password',
              controller: auth.confirmCtrl,
              obscure: true,
              height: 53.h,
            ),
            SizedBox(height: 28.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: PrimaryButton(
                label: 'Create Account',
                height: 54.h,
                radius: 27.r,
                onTap: () => submitAuth(context, _register, () => Navigator.pushNamed(context, AppRoutes.verifyEmail)),
              ),
            ),
            SizedBox(height: 24.h),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text.rich(
                  TextSpan(
                    style: AppText.bodySm.copyWith(fontSize: 12.sp, color: AppColors.textSecondary),
                    children: [
                      const TextSpan(text: 'I already have an account '),
                      TextSpan(
                        text: 'Log in',
                        style: AppText.link.copyWith(fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 26.h),
          ],
        ),
      ),
    );
  }
}
