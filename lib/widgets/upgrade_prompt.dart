import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';
import 'confirm_dialog.dart';

/// Shown when the backend answers `UPGRADE_REQUIRED` (bid, item or trade limit, or
/// trial ended). [message] is the server's wording, which names the limit.
Future<void> showUpgradePrompt(BuildContext context, String? message) async {
  final go = await ConfirmDialog.ask(
    context,
    title: 'Upgrade to keep going',
    message: message ?? 'You have used everything included in the free trial.',
    confirmLabel: 'See plans',
    cancelLabel: 'Not now',
  );
  if (go == true && context.mounted) Navigator.pushNamed(context, AppRoutes.choosePlan);
}
