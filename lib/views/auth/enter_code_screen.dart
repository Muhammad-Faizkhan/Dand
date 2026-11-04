import 'dart:async';

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
import '../../widgets/auth_widgets.dart';
import '../../widgets/buttons.dart';

/// Shared by "Enter the code" (sign-up) and "Enter OTP" (password reset), so
/// both flows get the same input and the same resend countdown.
class EnterCodeScreen extends StatefulWidget {
  const EnterCodeScreen({super.key, this.isReset = false});

  final bool isReset;

  @override
  State<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends State<EnterCodeScreen> {
  static const _resendSeconds = 30;

  Timer? _timer;
  int _remaining = _resendSeconds;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remaining = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _resend() async {
    if (_remaining > 0) return;
    final auth = context.read<AuthController>();
    auth.setOtp('');
    _startCountdown();
    final ok = await (widget.isReset ? auth.requestPasswordReset() : auth.resendVerification());
    if (!mounted) return;
    if (!ok) {
      showAppMessage(context, auth.error ?? "Couldn't send a new code.");
      return;
    }
    // A dev code shows in the card on this screen instead.
    if (auth.devCode == null) showAppMessage(context, 'We sent a new code to ${auth.emailCtrl.text}');
  }

  String get _clock {
    final m = _remaining ~/ 60;
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _remaining == 0;

    return Consumer<AuthController>(
      builder: (context, auth, _) {
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
                StepProgress(step: widget.isReset ? 1 : 2),
                SizedBox(height: 26.h),
                AuthIconBadge(icon: Icons.password_rounded, size: 60.w),
                SizedBox(height: 24.h),
                Text(
                  widget.isReset ? 'Enter OTP' : 'Enter the code',
                  style: AppText.h1.copyWith(fontSize: 26.sp),
                ),
                SizedBox(height: 12.h),
                Text.rich(
                  TextSpan(
                    style: AppText.bodyDim.copyWith(fontSize: 13.2.sp, height: 1.45),
                    children: [
                      const TextSpan(text: 'We sent a 6-digit code to\n'),
                      TextSpan(
                        text: auth.emailCtrl.text,
                        style: AppText.body.copyWith(
                          fontSize: 13.2.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: ' Edit',
                        style: AppText.link.copyWith(fontSize: 12.8.sp),
                      ),
                    ],
                  ),
                ),
                // Until email (SMTP) is set up, the server returns the code and we show it here.
                if (auth.devCode case final code?) ...[
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 10.w, 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.redTint,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your code', style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
                              SizedBox(height: 2.h),
                              Text(code, style: AppText.h1.copyWith(fontSize: 24.sp, letterSpacing: 6)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => auth.setOtp(code),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              gradient: AppColors.redGradient,
                              borderRadius: BorderRadius.circular(11.r),
                            ),
                            child: Text('Use code', style: AppText.button.copyWith(fontSize: 12.8.sp)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 30.h),
                OtpInput(
                  value: auth.otp,
                  autofocus: true,
                  onChanged: auth.setOtp,
                  onCompleted: (_) => _verify(),
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: canResend ? _resend : null,
                      child: Text(
                        'Resend code',
                        style: AppText.bodyDim.copyWith(
                          fontSize: 12.sp,
                          color: canResend ? AppColors.redSolid : AppColors.textSecondary,
                          fontWeight: canResend ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      canResend ? 'Ready' : _clock,
                      style: AppText.h5.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: canResend ? AppColors.redSolid : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: PrimaryButton(label: 'Verify', height: 54.h, radius: 27.r, onTap: _verify),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _verify() {
    submitAuth(
      context,
      (auth) => widget.isReset ? auth.verifyResetCode() : auth.verifyEmail(),
      () => Navigator.pushNamed(
        context,
        widget.isReset ? AppRoutes.createNewPassword : AppRoutes.congratulations,
      ),
    );
  }
}
