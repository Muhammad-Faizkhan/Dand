import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_assets.dart';
import '../../core/utils/format.dart';
import '../../widgets/common.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_grid_card.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/utils/responsive.dart';

/// Another collector's public profile.
class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key, this.name = 'Tom', this.userId});

  final String name;

  /// Set for a real collector; null shows the seeded profile.
  final int? userId;

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  int _tab = 0;

  Map<String, dynamic>? _user;
  List<ChipItem> _listings = const [];
  List<ChipItem> _wants = const [];
  bool _loading = false;

  bool get _live => widget.userId != null;

  List<ChipItem> get _items => !_live
      ? (_tab == 0
            ? const [AppData.paradise, AppData.almostHeaven, AppData.skyline, AppData.bourbonStreet]
            : const [AppData.oldSchoolHd, AppData.asheville])
      : (_tab == 0 ? _listings : _wants);

  @override
  void initState() {
    super.initState();
    if (_live) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<UserController>().client;
    final id = widget.userId;
    if (client == null || id == null) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        client.get('/api/users/$id', auth: false),
        client.get('/api/items', auth: false, query: {'ownerId': id, 'pageSize': 100}),
      ]);
      final user = results[0] as Map<String, dynamic>;
      final items = ((results[1] as Map<String, dynamic>)['items'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>();
      final name = user['username'] as String? ?? widget.name;
      if (!mounted) return;
      setState(() {
        _user = user;
        _listings = [for (final i in items) if (i['status'] != 'WANT') ChipItem.fromApiItem(i, owner: name)];
        _wants = [for (final i in items) if (i['status'] == 'WANT') ChipItem.fromApiItem(i, owner: name)];
      });
    } on ApiException {
      // Header falls back to the name we were given.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final stats = user?['stats'] as Map<String, dynamic>? ?? const {};
    final name = !_live ? widget.name : (user?['fullName'] as String? ?? user?['username'] as String? ?? widget.name);
    final bio = user?['bio'] as String?;
    final avatarUrl = user?['avatarUrl'] as String?;
    final isMe = _live && widget.userId == context.read<UserController>().userId;
    return AppScaffold(
      contentWidth: ContentWidth.wide,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: AppLayout.top(64)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                      ),
                      const Spacer(),
                      Container(
                        width: 46.w,
                        height: 46.w,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.ios_share_rounded, size: 17.6.sp, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                ClipOval(
                  child: avatarUrl == null
                      ? (_live
                            ? InitialsAvatar(initials: initialsOf(name), size: 116.w, fontSize: 30)
                            : Image.asset(AppAssets.avatarMike, width: 116.w, height: 116.w, fit: BoxFit.cover))
                      : Image.network(
                          avatarUrl,
                          width: 116.w,
                          height: 116.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => InitialsAvatar(initials: initialsOf(name), size: 116.w, fontSize: 30),
                        ),
                ),
                SizedBox(height: 16.h),
                Text(name, style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                if (!_live) ...[
                  SizedBox(height: 8.h),
                  Text('📍 Sturgis, SD', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                ],
                if (!_live || (bio?.isNotEmpty ?? false)) ...[
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: Text(
                      _live ? bio! : 'Passionate Harley collector since 2010.\nAlways looking for rare CT & SD chips!',
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
                      _Stat(icon: Icons.hexagon_outlined, value: _live ? '${stats['items'] ?? 0}' : '247', label: 'Items'),
                      SizedBox(width: 14.w),
                      _Stat(icon: Icons.swap_vert_rounded, value: _live ? '${stats['trades'] ?? 0}' : '127', label: 'Trades'),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                  child: _live
                      ? (isMe
                            ? const SizedBox.shrink()
                            : PrimaryButton(
                                label: 'Message',
                                height: 58.h,
                                radius: 15.r,
                                glow: false,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.chat,
                                  arguments: context.read<ChatController>().threadWith(widget.userId!, name, avatarUrl),
                                ),
                              ))
                      : PrimaryButton(
                          label: 'Collections',
                          height: 58.h,
                          radius: 15.r,
                          glow: false,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.collections),
                        ),
                ),
                SizedBox(height: 18.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                  child: Container(
                    height: 56.h,
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      children: List.generate(2, (i) {
                        final active = _tab == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tab = i),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: active ? AppColors.redGradient : null,
                                borderRadius: BorderRadius.circular(11.r),
                              ),
                              child: Text(
                                i == 0 ? 'Listings' : 'Wishlist',
                                style: AppText.body.copyWith(
                                  fontSize: 13.6.sp,
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
                if (_live && _items.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: Text(
                      _loading ? 'Loading…' : (_tab == 0 ? '$name has no chips listed yet.' : '$name has no wanted chips yet.'),
                      style: AppText.bodyDim.copyWith(fontSize: 13.6.sp),
                    ),
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(AppLayout.gutter, 0, AppLayout.gutter, 40.h),
            sliver: SliverGrid(
              gridDelegate: responsiveGridDelegate(
                context,
                tileDesign: const Size(167, 206),
                spacing: 13,
                runSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => ChipGridCard(item: _items[i]),
                childCount: _items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 118.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19.2.sp, color: AppColors.redSolid),
            SizedBox(height: 12.h),
            Text(value, style: AppText.h1.copyWith(fontSize: 20.5.sp)),
            SizedBox(height: 2.h),
            Text(label, style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
          ],
        ),
      ),
    );
  }
}
