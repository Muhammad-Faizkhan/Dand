import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceAlt,
        content: Text(message, style: AppText.body.copyWith(fontSize: 12.8.sp)),
      ),
    );
}

/// Runs an [AuthController] call, then either continues with [onSuccess] or
/// shows the controller's error. A dev code from the server is kept on the
/// controller so the code screen can show it (there is no email provider yet).
Future<void> submitAuth(
  BuildContext context,
  Future<bool> Function(AuthController auth) action,
  void Function() onSuccess,
) async {
  final auth = context.read<AuthController>();
  FocusScope.of(context).unfocus();
  final ok = await action(auth);
  if (!context.mounted) return;
  if (!ok) {
    if (auth.error != null) showAppMessage(context, auth.error!);
    return;
  }
  onSuccess();
}
