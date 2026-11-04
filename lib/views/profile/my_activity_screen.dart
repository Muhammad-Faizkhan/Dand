import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/format.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../../widgets/settings_widgets.dart';

class _Entry {
  const _Entry(
    this.icon,
    this.tint,
    this.title,
    this.bold,
    this.sub,
    this.meta, [
    this.badge,
    this.route,
    this.arguments,
  ]);

  final IconData icon;
  final Color tint;
  final String title;
  final String bold;
  final String sub;
  final String meta;
  final String? badge;

  /// The screen this line of history opens.
  final String? route;
  final Object? arguments;
}

class MyActivityScreen extends StatelessWidget {
  const MyActivityScreen({super.key});

  static const _today = <_Entry>[
    _Entry(
      Icons.swap_vert_rounded,
      AppColors.planBlue,
      'Trade completed with ',
      'HDCollector',
      'Bristol Wide ↔ Yankee Bristol',
      '2h ago',
      'Done',
      AppRoutes.tradeCompleted,
    ),
    _Entry(
      Icons.add,
      AppColors.redSolid,
      'You listed ',
      'Old School Ellington',
      'For trade',
      '5h ago',
      null,
      AppRoutes.collections,
    ),
  ];

  static const _week = <_Entry>[
    _Entry(
      Icons.edit_outlined,
      AppColors.planBlue,
      'You placed a bid on ',
      'Bourbon Street',
      '\$125',
      '2 days ago',
      'Winning',
      AppRoutes.auctionDetail,
    ),
    _Entry(
      Icons.favorite_border,
      AppColors.redSolid,
      '',
      'Museum Collection',
      'Added to Wishlist',
      '3 days ago',
      null,
      AppRoutes.wishlist,
    ),
    _Entry(
      Icons.check,
      AppColors.green,
      'Won auction: ',
      'Bristol Wide Limited',
      '\$95',
      '4 days ago',
      null,
      AppRoutes.auctionWinner,
    ),
    _Entry(
      Icons.star_rounded,
      AppColors.planGold,
      '',
      'ChipMaster99',
      'rated you 5 stars',
      '5 days ago',
      null,
      AppRoutes.sellerProfile,
      'ChipMaster99',
    ),
  ];

  static _Entry? _fromApi(Map<String, dynamic> e) {
    final item = e['item'] as Map<String, dynamic>?;
    final title = item?['title'] as String? ?? '';
    final when = timeAgo(e['at'] as String?);
    return switch (e['type']) {
      'listed' => _Entry(
        Icons.add,
        AppColors.redSolid,
        'You listed ',
        title,
        switch (e['listingType']) {
          'SALE' => 'For sale',
          'AUCTION' => 'Auction',
          _ => 'For trade',
        },
        when,
        null,
        AppRoutes.itemDetail,
        item == null ? null : ChipItem.fromApiItem(item),
      ),
      'bid' => _Entry(
        Icons.edit_outlined,
        AppColors.planBlue,
        'You placed a bid on ',
        title,
        dollars(e['amountCents'] as int?),
        when,
        e['winning'] == true ? 'Winning' : null,
        AppRoutes.auctionDetail,
        item == null
            ? null
            : ChipItem.fromApiListing({
                'listingType': 'AUCTION',
                'sellerId': item['ownerId'],
                'item': item,
                'auction': {'id': e['auctionId'], 'currentPriceCents': e['amountCents']},
              }),
      ),
      'trade_completed' => _Entry(
        Icons.swap_vert_rounded,
        AppColors.planBlue,
        'Trade completed with ',
        (e['with'] as Map<String, dynamic>?)?['username'] as String? ?? 'a collector',
        'Chips swapped',
        when,
        'Done',
        AppRoutes.ordersTrade,
      ),
      'wishlist_added' => _Entry(
        Icons.favorite_border,
        AppColors.redSolid,
        '',
        e['query'] as String? ?? '',
        'Added to Wishlist',
        when,
        null,
        AppRoutes.wishlist,
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserController>();
    final List<Widget> rows;
    if (!user.live) {
      rows = [
        _label('TODAY'),
        for (final e in _today) _Row(entry: e),
        SizedBox(height: 14.h),
        _label('THIS WEEK'),
        for (final e in _week) _Row(entry: e),
      ];
    } else {
      final now = DateTime.now();
      final today = <_Entry>[];
      final week = <_Entry>[];
      final earlier = <_Entry>[];
      for (final e in user.activity) {
        final entry = _fromApi(e);
        if (entry == null) continue;
        final at = DateTime.tryParse(e['at'] as String? ?? '')?.toLocal();
        final age = at == null ? null : now.difference(at);
        if (at != null && at.year == now.year && at.month == now.month && at.day == now.day) {
          today.add(entry);
        } else if (age != null && age.inDays < 7) {
          week.add(entry);
        } else {
          earlier.add(entry);
        }
      }
      rows = [
        if (today.isEmpty && week.isEmpty && earlier.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: Center(
              child: Text(
                user.loading ? 'Loading…' : 'Nothing yet. Your listings, bids and trades show up here.',
                textAlign: TextAlign.center,
                style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
              ),
            ),
          ),
        for (final (label, list) in [('TODAY', today), ('THIS WEEK', week), ('EARLIER', earlier)])
          if (list.isNotEmpty) ...[
            _label(label),
            for (final e in list) _Row(entry: e),
            SizedBox(height: 14.h),
          ],
      ];
    }
    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: user.loadActivity,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppLayout.top(62)),
              SettingsHeader(title: 'My Activity'),
              SizedBox(height: 24.h),
              ...rows,
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: EdgeInsets.only(bottom: 14.h),
    child: Text(
      t,
      style: AppText.captionBold.copyWith(
        fontSize: 12.sp,
        letterSpacing: 0.8,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: entry.route == null
          ? null
          : () => Navigator.pushNamed(context, entry.route!, arguments: entry.arguments),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: entry.tint.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: entry.tint.withValues(alpha: 0.45)),
              ),
              child: Icon(entry.icon, size: 17.6.sp, color: entry.tint),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppText.body.copyWith(fontSize: 13.6.sp, height: 1.3),
                      children: [
                        TextSpan(text: entry.title),
                        TextSpan(
                          text: entry.bold,
                          style: AppText.h4.copyWith(fontSize: 13.6.sp, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    '${entry.sub} · ${entry.meta}',
                    style: AppText.bodyDim.copyWith(fontSize: 12.4.sp),
                  ),
                ],
              ),
            ),
            if (entry.badge != null) ...[
              SizedBox(width: 8.w),
              StatusBadge(
                label: entry.badge!,
                background: AppColors.greenDark.withValues(alpha: 0.6),
                textColor: const Color(0xFF3CCB84),
                radius: 8.r,
                fontSize: 14,
                padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
