import 'package:flutter/material.dart';
import '../../widgets/chip_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/collections_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import 'get_item_sheet.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final ChipItem item;

  /// The signed-in user's own chip: instead of "I have / I want" it can be deleted.
  bool _isMine(BuildContext context) {
    final owner = item.sellerId;
    if (owner == null || item.itemId == null) return false;
    try {
      final me = context.select<UserController, int>((u) => u.live ? u.userId : 0);
      return me != 0 && me == owner;
    } on ProviderNotFoundException {
      return false;
    }
  }

  Future<void> _delete(BuildContext context) async {
    final id = item.itemId;
    if (id == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        title: Text('Delete "${item.name}"?', style: AppText.h3),
        content: Text(
          'It is removed from your collections and profile. This can’t be undone.',
          style: AppText.bodyDim.copyWith(fontSize: 13.sp),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: AppText.body)),
          TextButton(
            key: const Key('item-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: AppText.body.copyWith(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    final ctrl = context.read<CollectionsController>();
    final messenger = ScaffoldMessenger.of(context);
    if (await ctrl.deleteItem(id)) {
      ctrl.load(); // item counts on the collection covers
      // Back to wherever the chip was opened from (the collection, profile, …).
      if (context.mounted) Navigator.pop(context, true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceAlt,
          content: Text(ctrl.error ?? "Couldn't delete the chip.", style: AppText.body.copyWith(fontSize: 12.8.sp)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistController>();
    final liked = wishlist.contains(item);
    final mine = _isMine(context);

    return AppScaffold(
      safeAreaTop: false,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hero(item: item, liked: liked, onLike: () => wishlist.toggle(item)),
                  SizedBox(height: 22.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: Row(
                      children: [
                        _Spec(label: 'Price', value: item.priceLabel, red: true),
                        SizedBox(width: 12.w),
                        _Spec(label: 'Year', value: item.year),
                        SizedBox(width: 12.w),
                        _Spec(label: 'Condition', value: item.condition),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: Container(
                      height: 78.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.sellerProfile,
                              arguments: item.sellerId == null
                                  ? item.seller.name
                                  : (id: item.sellerId!, name: item.owner.isEmpty ? item.seller.name : item.owner),
                            ),
                            child: Row(
                              children: [
                                InitialsAvatar(
                                  initials: item.seller.initials,
                                  size: 50.w,
                                  fontSize: 16,
                                ),
                                SizedBox(width: 14.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.seller.name,
                                      style: AppText.h4.copyWith(fontSize: 14.4.sp),
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      item.sellerId == null
                                          ? '⭐ ${item.seller.rating} · ${item.seller.trades} trades'
                                          : 'View profile',
                                      style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.chat,
                              arguments: item.sellerId == null
                                  ? item.seller.name
                                  : context.read<ChatController>().threadWith(item.sellerId!, item.seller.name, null),
                            ),
                            child: Text('Message', style: AppText.link.copyWith(fontSize: 13.6.sp)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: Text('Description', style: AppText.h3.copyWith(fontSize: 16.sp)),
                  ),
                  SizedBox(height: 12.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                    child: Text(
                      item.description,
                      style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.55),
                    ),
                  ),
                  SizedBox(height: 26.h),
                ],
              ),
            ),
          ),
          if (mine)
            Padding(
              padding: EdgeInsets.fromLTRB(AppLayout.gutter, 0, AppLayout.gutter, 24.h),
              child: SecondaryButton(
                key: const Key('item-delete'),
                label: 'DELETE CHIP',
                height: 56.h,
                radius: 15.r,
                textStyle: AppText.button.copyWith(fontSize: 12.8.sp, letterSpacing: 0.4, color: AppColors.red),
                onTap: () => _delete(context),
              ),
            )
          else
          Padding(
            padding: EdgeInsets.fromLTRB(AppLayout.gutter, 0, AppLayout.gutter, 24.h),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'I HAVE THIS',
                    height: 56.h,
                    radius: 15.r,
                    textStyle: AppText.button.copyWith(fontSize: 12.8.sp, letterSpacing: 0.4),
                    onTap: () {
                      context.read<TradeController>()
                        ..reset()
                        ..setTarget(item);
                      Navigator.pushNamed(context, AppRoutes.proposeTrade, arguments: item);
                    },
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: PrimaryButton(
                    label: 'I WANT THIS',
                    height: 56.h,
                    radius: 15.r,
                    textStyle: AppText.button.copyWith(fontSize: 12.8.sp, letterSpacing: 0.4),
                    onTap: () => GetItemSheet.show(context, item),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.item, required this.liked, required this.onLike});

  final ChipItem item;
  final bool liked;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400.h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ChipImage(item, alignment: Alignment.topCenter),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x00000000), Color(0xCC0A0406)],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
              child: Column(
                children: [
                  SizedBox(height: 18.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleIconButton(
                        icon: Icons.arrow_back,
                        background: AppColors.black.withValues(alpha: 0.45),
                        onTap: () => Navigator.pop(context),
                      ),
                      CircleIconButton(
                        icon: liked ? Icons.favorite : Icons.favorite_border,
                        iconColor: liked ? AppColors.redSolid : AppColors.white,
                        background: AppColors.black.withValues(alpha: 0.45),
                        onTap: onLike,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppLayout.gutter,
            right: AppLayout.gutter,
            bottom: 22.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppText.h1.copyWith(fontSize: 21.5.sp)),
                      SizedBox(height: 6.h),
                      Text(
                        '📍 ${item.location} · ${item.distance} away',
                        style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: StatusBadge(
                    label: item.rarity.label,
                    background: AppColors.teal.withValues(alpha: 0.35),
                    textColor: const Color(0xFF4FD6C9),
                    radius: 10.r,
                    fontSize: 15,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec({required this.label, required this.value, this.red = false});

  final String label;
  final String value;
  final bool red;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 92.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
            SizedBox(height: 8.h),
            Text(
              value,
              style: AppText.h2.copyWith(
                fontSize: 17.6.sp,
                color: red ? AppColors.red : AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback used when a route is opened without arguments.
ChipItem itemFrom(Object? args) => args is ChipItem ? args : AppData.yankeeBristol;
