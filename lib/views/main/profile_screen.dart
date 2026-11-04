import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_grid_card.dart';
import '../../widgets/responsive_layout.dart';

/// Stands in for a real deep link until the backend issues profile URLs.
const _kProfileLink = 'https://dandcollection.app/u/rider-mike';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBack = false, this.initialTab = 0});

  final bool showBack;
  final int initialTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _tab = widget.initialTab;

  static const _tabs = ['Listings', 'Wishlist', 'Activity'];

  List<ChipItem> _itemsFor(UserController user, WishlistController wishlist) => !user.live
      ? switch (_tab) {
          1 => const [AppData.oldSchoolHd, AppData.bourbonStreet, AppData.asheville],
          2 => const [AppData.grizzly, AppData.skyline],
          _ => const [
            AppData.paradise,
            AppData.almostHeaven,
            AppData.bristolWide,
            AppData.classicReading,
          ],
        }
      : switch (_tab) {
          1 => wishlist.items,
          2 => user.activityItems,
          _ => user.myItems,
        };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<UserController>();
      if (!user.live) return;
      user.load();
      context.read<WishlistController>().load();
    });
  }

  /// Hands the profile to the OS share sheet. [sharePositionOrigin] is what
  /// anchors the popover on iPad; without it the sheet throws there.
  Future<void> _shareProfile(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final messenger = ScaffoldMessenger.of(context);
    final u = context.read<UserController>().user;
    final name = u?.displayName ?? 'Rider Mike';
    final stats = u == null ? '247 items, 127 trades, rated 4.9' : '${u.itemCount} items, ${u.tradeCount} trades';
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: '$name on DAN D COLLECTION',
          text:
              '$name collects Harley-Davidson poker chips on DAN D COLLECTION — '
              '$stats.\n${u == null ? _kProfileLink : 'https://dandcollection.app/u/${u.username}'}',
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.surfaceAlt,
            content: Text(
              "Couldn't open the share sheet.",
              style: AppText.body.copyWith(fontSize: 12.8.sp),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.watch<UserController>();
    final u = userCtrl.user;
    final items = _itemsFor(userCtrl, context.watch<WishlistController>());
    final localAvatar = context.watch<ProfileController>();
    // A photo picked on this device wins; otherwise the uploaded one from the account.
    final ImageProvider avatar = !localAvatar.hasCustomAvatar && u?.avatarUrl != null
        ? NetworkImage(u!.avatarUrl!)
        : localAvatar.avatar;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: AppLayout.top(58)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                child: Row(
                  children: [
                    if (widget.showBack) ...[
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                      ),
                      SizedBox(width: 14.w),
                    ],
                    Text('My Profile', style: AppText.h1.copyWith(fontSize: 20.8.sp)),
                    const Spacer(),
                    _CircleAction(
                      icon: Icons.settings_outlined,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                    ),
                    SizedBox(width: 12.w),
                    _CircleAction(
                      icon: Icons.ios_share_rounded,
                      onTap: () => _shareProfile(context),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22.h),
              // Display only: the photo is changed on Edit Profile, and lands
              // here through ProfileController.
              ClipOval(
                child: Image(
                  image: avatar,
                  width: 116.w,
                  height: 116.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image(image: localAvatar.avatar, width: 116.w, height: 116.w, fit: BoxFit.cover),
                ),
              ),
              SizedBox(height: 16.h),
              Text(userCtrl.live ? userCtrl.displayName : 'Rider Mike', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
              if (!userCtrl.live || (u?.address?.isNotEmpty ?? false)) ...[
                SizedBox(height: 8.h),
                Text('📍 ${userCtrl.live ? u!.address! : 'Sturgis, SD'}', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
              ],
              if (!userCtrl.live || (u?.bio?.isNotEmpty ?? false)) ...[
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Text(
                    userCtrl.live ? u!.bio! : 'Passionate Harley collector since 2010.\nAlways looking for rare CT & SD chips!',
                    textAlign: TextAlign.center,
                    style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.45),
                  ),
                ),
              ],
              SizedBox(height: 22.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                child: Row(
                  children: [
                    _ProfileStat(icon: Icons.hexagon_outlined, value: userCtrl.live ? '${u?.itemCount ?? 0}' : '247', label: 'Items'),
                    _ProfileStat(
                      icon: Icons.swap_vert_rounded,
                      value: userCtrl.live ? '${u?.tradeCount ?? 0}' : '127',
                      label: 'Trades',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.ordersTrade),
                    ),
                    // There is no rating system yet, so live accounts show listings instead.
                    userCtrl.live
                        ? _ProfileStat(icon: Icons.storefront_outlined, value: '${u?.listingCount ?? 0}', label: 'Listings')
                        : const _ProfileStat(icon: Icons.star_rounded, value: '4.9', label: 'Rating'),
                  ],
                ),
              ),
              SizedBox(height: 22.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                child: SecondaryButton(
                  label: 'Edit Profile',
                  height: 56.h,
                  radius: 15.r,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
              ),
              SizedBox(height: 14.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                child: PrimaryButton(
                  label: 'Collections',
                  height: 56.h,
                  radius: 15.r,
                  glow: false,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.collections),
                ),
              ),
              SizedBox(height: 18.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                child: Container(
                  height: 54.h,
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final active = _tab == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: active ? AppColors.redGradient : null,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              _tabs[i],
                              style: AppText.body.copyWith(
                                fontSize: 13.2.sp,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                color: active ? AppColors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              if (userCtrl.live && items.isEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(AppLayout.gutter, 10.h, AppLayout.gutter, 0),
                  child: Text(
                    switch (_tab) {
                      1 => 'Nothing on your wishlist yet. Tap the heart on any chip to save it.',
                      2 => 'No activity yet. Chips you list or bid on show up here.',
                      _ => 'No chips yet. Tap + to scan and add your first one.',
                    },
                    textAlign: TextAlign.center,
                    style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5),
                  ),
                ),
            ],
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.gutter,
            0,
            AppLayout.gutter,
            AppBottomNav.heightOf(context) + 20.h,
          ),
          sliver: SliverGrid(
            gridDelegate: responsiveGridDelegate(
              context,
              tileDesign: const Size(167, 206),
              spacing: 13,
              runSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => ChipGridCard(
                item: items[i],
                showDistance: false,
                showTypeBadge: false,
                showOwner: false,
                rarityBadge: items[i].rarity.label,
              ),
              childCount: items.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46.w,
        height: 46.w,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
        child: Icon(icon, size: 17.6.sp, color: AppColors.white),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.icon, required this.value, required this.label, this.onTap});

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 108.h,
          margin: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19.2.sp, color: AppColors.redSolid),
              SizedBox(height: 10.h),
              Text(value, style: AppText.h1.copyWith(fontSize: 20.8.sp)),
              SizedBox(height: 2.h),
              Text(label, style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
            ],
          ),
        ),
      ),
    );
  }
}
