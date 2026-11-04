import 'package:flutter/material.dart';
import '../../widgets/chip_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../models/models.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/offer_dialog.dart';

/// "How would you like to get this item?" bottom sheet.
class GetItemSheet extends StatelessWidget {
  const GetItemSheet({super.key, required this.item, required this.host});

  final ChipItem item;

  /// The screen that opened the sheet; still mounted after the sheet closes.
  final BuildContext host;

  static Future<void> show(BuildContext context, ChipItem item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      constraints: BoxConstraints(maxWidth: AppResponsive.overlayMaxWidth(context)),
      builder: (_) => GetItemSheet(item: item, host: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 30.h),
      decoration: BoxDecoration(
        color: AppColors.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: const Color(0xFF4A4A4E),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Container(
                width: 62.w,
                height: 62.w,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: ChipImage(item),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppText.h2.copyWith(fontSize: 17.6.sp)),
                  SizedBox(height: 5.h),
                  Text(
                    '${item.priceLabel} · ${item.rarity.label}',
                    style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 26.h),
          Text(
            'How would you like to get this item?',
            style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
          ),
          SizedBox(height: 18.h),
          _Option(
            accent: AppColors.redSolid,
            gradient: AppColors.redGradient,
            icon: Icons.swap_vert_rounded,
            title: 'Propose Trade',
            subtitle: 'Exchange from your collection',
            onTap: () {
              Navigator.pop(context);
              host.read<TradeController>()
                ..reset()
                ..setTarget(item);
              Navigator.pushNamed(host, AppRoutes.proposeTrade, arguments: item);
            },
          ),
          if (item.type == ListingType.sale && item.price > 0) ...[
            SizedBox(height: 16.h),
            _Option(
              accent: AppColors.blue,
              gradient: const LinearGradient(colors: [Color(0xFF3453D4), Color(0xFF1E3AA8)]),
              icon: Icons.local_offer_outlined,
              title: 'Make an Offer',
              subtitle: 'Asking ${item.priceLabel} · pay the seller directly',
              onTap: () {
                Navigator.pop(context);
                _makeOffer(host, item);
              },
            ),
          ],
          SizedBox(height: 16.h),
          _Option(
            accent: const Color(0xFF4FD6C9),
            gradient: const LinearGradient(colors: [Color(0xFF1F9E93), Color(0xFF136B63)]),
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Message Seller',
            subtitle: 'Ask questions, agree payment & shipping',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                host,
                AppRoutes.chat,
                arguments: item.sellerId == null
                    ? item.seller.name
                    : host.read<ChatController>().threadWith(item.sellerId!, item.owner.isEmpty ? item.seller.name : item.owner, null),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Sends an offer on a sale listing. Money and shipping are settled between
/// buyer and seller; the app only records the offer and the seller's answer.
Future<void> _makeOffer(BuildContext context, ChipItem item) async {
  final cents = await OfferDialog.ask(context, itemName: item.name, askingPrice: item.price);
  if (cents == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceAlt,
      content: Text(text, style: AppText.body.copyWith(fontSize: 12.8.sp)),
    ),
  );

  final client = context.read<UserController>().client;
  if (client == null) {
    say('Offer sent to ${item.seller.name}.');
    return;
  }
  final listingId = item.listingId;
  if (listingId == null) {
    say("This chip isn't listed for sale. Message the owner instead.");
    return;
  }
  try {
    await client.post('/api/orders/requests', body: {'listingId': listingId, 'offerAmountCents': cents});
    say("Offer sent. You'll get a notification when the seller answers.");
  } on ApiException catch (e) {
    say(e.message);
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.accent,
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color accent;
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: accent.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: AppColors.white, size: 22.4.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h3.copyWith(fontSize: 16.sp)),
                  SizedBox(height: 4.h),
                  Text(subtitle, style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent, size: 20.8.sp),
          ],
        ),
      ),
    );
  }
}
