import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/app_background.dart';
import '../../widgets/success_view.dart';

/// Green confirmation used after changing a password or sending feedback.
class ThankYouScreen extends StatelessWidget {
  const ThankYouScreen({
    super.key,
    required this.message,
    required this.buttonLabel,
    this.goLogin = false,
  });

  final String message;
  final String buttonLabel;
  final bool goLogin;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SuccessView(
        topSpace: 435,
        accent: AppColors.green,
        iconColor: const Color(0xFF3CCB84),
        title: 'Thank You!',
        message: message,
        secondaryFirst: false,
        primaryLabel: buttonLabel,
        onPrimary: () => goLogin
            ? Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false)
            : Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false),
      ),
    );
  }
}
