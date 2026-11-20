import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/app_controller.dart';
import '../controllers/user_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/routes/app_routes.dart';
import 'confirm_dialog.dart';
import '../core/utils/responsive.dart';

/// The maroon slide-in menu from the Home header.
class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  static const _items = <(IconData, String, String)>[
    (Icons.inventory_2_outlined, 'Orders', AppRoutes.ordersPurchase),
    (Icons.layers_outlined, 'Collections', AppRoutes.collections),
    (Icons.favorite_border, 'Wish list', AppRoutes.wishlist),
    // Same entries and order as the Figma "Side Menu" frame. Settings is on Profile,
    // Chip Marketplace on Wallet.
    (Icons.leaderboard_outlined, 'Rankings', AppRoutes.leaderboard),
    (Icons.assignment_ind_outlined, 'Order Request', AppRoutes.orderRequests),
    (Icons.assignment_outlined, 'Activity', AppRoutes.myActivity),
    (Icons.account_balance_wallet_outlined, 'Wallet', AppRoutes.wallet),
    (Icons.workspace_premium_outlined, 'Subscription Plan', AppRoutes.choosePlan),
  ];

  /// Logging out drops the session, so it asks first. A dismissed dialog
  /// (tap outside, back gesture) counts as staying put.
  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    final ok = await ConfirmDialog.ask(
      context,
      title: 'Log out?',
      message: "You'll need to sign in again to reach your collection, trades and orders.",
      confirmLabel: 'Log Out',
      cancelLabel: 'Stay signed in',
      destructive: true,
    );
    if (ok != true) return;
    auth.logout();
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Cards are only for in-app checkout, which the live app doesn't offer yet.
    final items = context.read<UserController>().live
        ? [for (final e in _items) if (e.$3 != AppRoutes.paymentMethods) e]
        : _items;
    return Drawer(
      width: AppResponsive.drawerWidth(context),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.drawer,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(26.r),
            bottomRight: Radius.circular(26.r),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 18.w, top: 8.h),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 17.6.sp, color: AppColors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.myProfile);
                },
                child: Builder(
                  builder: (context) {
                    final local = context.watch<ProfileController>();
                    final user = context.watch<UserController>();
                    final url = user.avatarUrl;
                    final address = user.user?.address;
                    return Column(
                      children: [
                        ClipOval(
                          child: Image(
                            image: !local.hasCustomAvatar && url != null ? NetworkImage(url) : local.avatar,
                            width: 96.w,
                            height: 96.w,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image(image: local.avatar, width: 96.w, height: 96.w, fit: BoxFit.cover),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(user.live ? user.displayName : 'Rider Mike', style: AppText.h1.copyWith(fontSize: 20.sp)),
                        if (!user.live || (address?.isNotEmpty ?? false)) ...[
                          SizedBox(height: 6.h),
                          Text('📍 ${user.live ? address : 'Sturgis, SD'}', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                        ],
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 22.w),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: AppColors.white.withValues(alpha: 0.12)),
                  itemBuilder: (context, i) {
                    final (icon, label, route) = items[i];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, route);
                      },
                      child: SizedBox(
                        height: 59.h,
                        child: Row(
                          children: [
                            Icon(icon, size: 19.2.sp, color: AppColors.white),
                            SizedBox(width: 18.w),
                            Text(label, style: AppText.body.copyWith(fontSize: 13.6.sp)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 22.h),
                child: GestureDetector(
                  onTap: () => _confirmLogout(context),
                  child: Container(
                    height: 54.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
                    ),
                    child: Text(
                      'Log Out',
                      style: AppText.button.copyWith(fontSize: 13.6.sp, color: AppColors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
