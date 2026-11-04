import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/app_background.dart';
import '../../widgets/success_view.dart';

class ProfileCompletedScreen extends StatelessWidget {
  const ProfileCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SuccessView(
        topSpace: 232,
        title: 'Profile Completed!',
        message: 'Your profile has been created\nSuccessfully.',
        secondaryLabel: 'Go to Home',
        onSecondary: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false),
      ),
    );
  }
}
