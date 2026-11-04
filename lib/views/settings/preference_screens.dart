import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/api/user_api.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/api_feedback.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/settings_widgets.dart';

class PushNotificationsScreen extends StatelessWidget {
  const PushNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, s, _) => AppScaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppLayout.top(62)),
              SettingsHeader(title: 'Push Notifications'),
              SizedBox(height: 24.h),
              ToggleGroup(
                rows: [
                  ToggleRow(
                    title: 'New wishlist matches',
                    subtitle: 'When items near you match',
                    value: s.pushTrades,
                    onChanged: (_) => s.toggle('trades'),
                  ),
                  ToggleRow(
                    title: 'Auction alerts',
                    subtitle: 'Outbid & ending soon',
                    value: s.pushAuctions,
                    onChanged: (_) => s.toggle('auctions'),
                  ),
                  ToggleRow(
                    title: 'Weekly digest',
                    subtitle: 'Top trades in your area',
                    value: s.pushMessages,
                    onChanged: (_) => s.toggle('messages'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TradePreferencesScreen extends StatelessWidget {
  const TradePreferencesScreen({super.key});

  static const _chips = ['Harley chips', 'Rally pins', 'Coins', 'Patches'];

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, s, _) => AppScaffold(
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppLayout.top(62)),
              SettingsHeader(title: 'Trade Preferences'),
              SizedBox(height: 24.h),
              ToggleGroup(
                rows: [
                  ToggleRow(
                    title: 'Auto-accept fair trades',
                    value: s.localTradesOnly,
                    onChanged: (_) => s.toggle('local'),
                  ),
                  ToggleRow(
                    title: 'Only trade within 100 mi',
                    value: s.shipNationwide,
                    onChanged: (_) => s.toggle('nationwide'),
                  ),
                ],
              ),
              SizedBox(height: 26.h),
              Row(
                children: [
                  Text('Willing to trade for', style: AppText.bodyDim.copyWith(fontSize: 13.6.sp)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.editCollect),
                    child: Container(
                      width: 46.w,
                      height: 46.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(Icons.edit_outlined, size: 16.8.sp, color: AppColors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 14.h,
                children: _chips.map((c) {
                  final on =
                      s.tradeInterests.contains(c) ||
                      (c == 'Harley chips' || c == 'Rally pins') &&
                          s.tradeInterests.length == 2 &&
                          s.tradeInterests.contains('Harley-Davidson');
                  return GestureDetector(
                    onTap: () => s.toggleInterest(c),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
                      decoration: BoxDecoration(
                        gradient: on ? AppColors.redGradient : null,
                        color: on ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: on ? Colors.transparent : AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c,
                            style: AppText.body.copyWith(
                              fontSize: 13.2.sp,
                              fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                              color: on ? AppColors.white : AppColors.textSecondary,
                            ),
                          ),
                          if (on) ...[
                            SizedBox(width: 7.w),
                            Icon(Icons.check, size: 13.6.sp, color: AppColors.white),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final client = context.read<UserController>().client;
    if (client == null) {
      Navigator.pushNamed(context, AppRoutes.thankYouPassword);
      return;
    }
    final problem = switch ((_current.text, _next.text, _confirm.text)) {
      ('', _, _) => 'Enter your current password.',
      (_, final n, _) when n.length < 8 => 'The new password needs at least 8 characters.',
      (_, final n, final c) when n != c => "The new passwords don't match.",
      _ => null,
    };
    if (problem != null) {
      showAppMessage(context, problem);
      return;
    }
    setState(() => _saving = true);
    try {
      await UserApi(client).changePassword(_current.text, _next.text);
      if (mounted) Navigator.pushNamed(context, AppRoutes.thankYouPassword);
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(62)),
            SettingsHeader(title: 'Change Password'),
            SizedBox(height: 26.h),
            AppTextField(label: 'Current password', obscure: true, height: 53.h, controller: _current),
            SizedBox(height: 18.h),
            AppTextField(label: 'New password', obscure: true, height: 53.h, controller: _next),
            SizedBox(height: 18.h),
            AppTextField(label: 'Confirm new password', obscure: true, height: 53.h, controller: _confirm),
            SizedBox(height: 26.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w),
              child: PrimaryButton(
                label: 'Update Password',
                height: 54.h,
                radius: 15.r,
                enabled: !_saving,
                onTap: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Long-form legal copy (Privacy Policy / Terms & Condition).
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key, required this.title});

  final String title;

  static const _copy =
      "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum "
      "has been the industry's standard dummy text ever since 1966, when designers at Letraset "
      "and James Mosley, the librarian at St Bride Printing Library in London, took a 1914 Cicero "
      "translation and scrambled it to make dummy text for Letraset's Body Type sheets. It has "
      "survived not only many decades, but also the leap into electronic typesetting, remaining "
      "essentially unchanged. It was popularised thanks to these sheets and more recently with "
      "desktop publishing software like Aldus PageMaker and Microsoft Word including versions of "
      "Lorem Ipsum. ";

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(64)),
            SettingsHeader(title: title),
            SizedBox(height: 22.h),
            Text(_copy * 2, style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.55)),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
