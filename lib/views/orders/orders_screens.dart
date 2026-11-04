import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/format.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_image.dart';
import '../../widgets/common.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/settings_widgets.dart';
import '../../widgets/upgrade_prompt.dart';

/// Segmented pill selector shared by the order screens.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58.h,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: active ? AppColors.redGradient : null,
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Text(
                  tabs[i],
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
    );
  }
}

/// "Orders" — purchases, trades and auctions.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late int _tab = widget.initialTab;

  List<Map<String, dynamic>>? _orders;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<UserController>();
    final client = user.client;
    if (client == null) return;
    context.read<TradeController>().loadTrades(user.userId);
    user.loadActivity();
    try {
      final data = (await client.get('/api/orders') as List<dynamic>).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _orders = data);
    } on ApiException {
      if (mounted) setState(() => _orders = const []);
    }
  }

  static String _orderStatus(String? s) => switch (s) {
    'PENDING' => 'Awaiting payment',
    'PAID' => 'Paid',
    'SHIPPED' => 'Shipped',
    'DELIVERED' => 'Delivered',
    'CANCELLED' => 'Cancelled',
    _ => s ?? '',
  };

  static String _tradeStatus(ApiTradeRequest t) => switch (t.status) {
    'PENDING' => t.incoming ? 'Offer from ${t.otherUsername} · tap to respond' : 'Waiting for ${t.otherUsername}',
    'COMPLETED' => 'Completed with ${t.otherUsername}',
    'REJECTED' => 'Declined by ${t.incoming ? 'you' : t.otherUsername}',
    'CANCELLED' => 'Cancelled',
    _ => t.status,
  };

  Future<void> _openTrade(ApiTradeRequest t) async {
    final trade = context.read<TradeController>();
    final myId = context.read<UserController>().userId;
    if (t.status == 'PENDING' && t.incoming) {
      final accept = await ConfirmDialog.ask(
        context,
        title: 'Trade offer from ${t.otherUsername}',
        message: 'You give: ${t.giveItems.join(', ')}\nYou get: ${t.getItems.join(', ')}'
            '${t.message == null ? '' : '\n\n"${t.message}"'}',
        confirmLabel: 'Accept',
        cancelLabel: 'Decline',
      );
      if (accept == null || !mounted) return;
      final ok = await trade.respondToTrade(t.id, accept: accept, myId: myId);
      if (!mounted) return;
      if (ok) {
        context.read<UserController>().load();
        Navigator.pushNamed(context, accept ? AppRoutes.tradeConfirmed : AppRoutes.tradeRejected, arguments: t);
      } else if (trade.upgradeRequired) {
        await showUpgradePrompt(context, trade.tradesError);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trade.tradesError ?? "Couldn't respond to the trade.")),
        );
      }
      return;
    }
    Navigator.pushNamed(
      context,
      switch (t.status) {
        'COMPLETED' => AppRoutes.tradeCompleted,
        'REJECTED' || 'CANCELLED' => AppRoutes.tradeRejected,
        _ => AppRoutes.tradeSent,
      },
      arguments: t,
    );
  }

  Widget _live(BuildContext context) {
    final user = context.watch<UserController>();
    final trade = context.watch<TradeController>();
    final List<Widget> rows;
    switch (_tab) {
      case 1:
        rows = [
          for (final t in trade.trades)
            _OrderRow(
              name: t.getItems.isEmpty ? 'Trade #${t.id}' : t.getItems.join(', '),
              type: _tradeStatus(t),
              image: AppAssets.chipAshevilleSq,
              chip: t.chip,
              onTap: () => _openTrade(t),
            ),
        ];
      case 2:
        rows = [
          for (final b in user.myBids)
            _OrderRow(
              name: b.chip.name,
              type: '${b.winning ? 'Winning' : 'Outbid'} · your bid ${dollars(b.amountCents)}',
              image: AppAssets.chipHighStakes,
              chip: b.chip,
              onTap: () => Navigator.pushNamed(context, AppRoutes.itemDetail, arguments: b.chip),
            ),
        ];
      default:
        rows = [
          for (final o in _orders ?? const <Map<String, dynamic>>[])
            () {
              final items = (o['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
              final item = items.isEmpty ? null : items.first['item'] as Map<String, dynamic>?;
              final chip = item == null ? null : ChipItem.fromApiItem(item);
              final selling = o['sellerId'] == user.userId;
              return _OrderRow(
                name: chip?.name ?? 'Order #${o['id']}',
                type: '${selling ? 'Sold' : 'Bought'} · ${_orderStatus(o['status'] as String?)} · ${dollars(o['totalCents'] as int?)}',
                image: AppAssets.chipHighStakes,
                chip: chip,
                onTap: () => Navigator.pushNamed(context, AppRoutes.trackOrder, arguments: o),
              );
            }(),
        ];
    }
    final loading = switch (_tab) {
      1 => trade.tradesLoading,
      2 => user.loading,
      _ => _orders == null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rows.isEmpty)
          Text(
            loading
                ? 'Loading…'
                : switch (_tab) {
                    1 => 'No trades yet. Propose one from a chip you like.',
                    2 => "You haven't bid on any auctions yet.",
                    _ => 'No orders yet. Chips you buy or sell show up here.',
                  },
            style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5),
          ),
        for (final r in rows) ...[r, SizedBox(height: 14.h)],
      ],
    );
  }

  /// Name, kind, thumbnail and the screen the row opens.
  List<(String, String, String, String)> get _rows => switch (_tab) {
    1 => const [
      ('Order 2', 'Trade', AppAssets.chipAshevilleSq, AppRoutes.tradeCompleted),
      ('Order 5', 'Trade', AppAssets.chipAshevilleSq, AppRoutes.tradeConfirmed),
      ('Order 2', 'Trade', AppAssets.chipAshevilleSq, AppRoutes.tradeCompleted),
      ('Order 5', 'Trade', AppAssets.chipAshevilleSq, AppRoutes.tradeRejected),
    ],
    2 => const [
      ('Order 3', 'Auction', AppAssets.chipHighStakes, AppRoutes.auctionWinner),
      ('Order 6', 'Auction', AppAssets.chipHighStakes, AppRoutes.auctionLost),
    ],
    _ => const [
      ('Order 1', 'Purchase', AppAssets.chipHighStakes, AppRoutes.trackOrder),
      ('Order 4', 'Purchase', AppAssets.chipHighStakes, AppRoutes.trackOrder),
      ('Order 1', 'Purchase', AppAssets.chipHighStakes, AppRoutes.trackOrder),
      ('Order 4', 'Purchase', AppAssets.chipHighStakes, AppRoutes.trackOrder),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(62)),
            SettingsHeader(title: 'Orders'),
            SizedBox(height: 22.h),
            SegmentedTabs(
              tabs: const ['Orders', 'Trade', 'Auction'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            SizedBox(height: 18.h),
            if (context.read<UserController>().live)
              _live(context)
            else
              for (final (name, type, image, route) in _rows) ...[
                _OrderRow(
                  name: name,
                  type: type,
                  image: image,
                  onTap: () => Navigator.pushNamed(context, route),
                ),
                SizedBox(height: 14.h),
              ],
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.name,
    required this.type,
    required this.image,
    this.chip,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String type;
  final String image;

  /// An API item; its photo replaces [image] when there is one.
  final ChipItem? chip;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 62.w,
              height: 62.w,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(7.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: chip?.imageUrl != null ? ChipImage(chip!) : Image.asset(image, fit: BoxFit.cover),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h4.copyWith(fontSize: 15.2.sp)),
                  SizedBox(height: 5.h),
                  Text(type, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.price.copyWith(fontSize: 13.6.sp)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// "Order Request" — incoming and outgoing requests.
class OrderRequestsScreen extends StatefulWidget {
  const OrderRequestsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<OrderRequestsScreen> createState() => _OrderRequestsScreenState();
}

class _OrderRequestsScreenState extends State<OrderRequestsScreen> {
  late int _tab = widget.initialTab;

  List<Map<String, dynamic>>? _requests;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<UserController>().client;
    if (client == null) return;
    try {
      final data = (await client.get('/api/orders/requests/mine') as List<dynamic>).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _requests = data);
    } on ApiException {
      if (mounted) setState(() => _requests = const []);
    }
  }

  Future<void> _respond(Map<String, dynamic> r, String title) async {
    final accept = await ConfirmDialog.ask(
      context,
      title: 'Offer on $title',
      message: 'A buyer offered ${dollars(r['offerAmountCents'] as int?)}. If you accept, message them to agree payment and shipping.',
      confirmLabel: 'Accept',
      cancelLabel: 'Decline',
    );
    if (accept == null || !mounted) return;
    final client = context.read<UserController>().client!;
    try {
      await client.post('/api/orders/requests/${r['id']}/respond', body: {'accept': accept});
      if (!mounted) return;
      await _load();
      if (mounted) Navigator.pushNamed(context, accept ? AppRoutes.requestSent : AppRoutes.orderRejected);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  List<Widget> _liveRows() {
    final me = context.read<UserController>().userId;
    final mine = [
      for (final r in _requests ?? const <Map<String, dynamic>>[])
        if ((_tab == 0 ? r['sellerId'] : r['buyerId']) == me) r,
    ];
    if (mine.isEmpty) {
      return [
        Text(
          _requests == null
              ? 'Loading…'
              : (_tab == 0 ? 'No offers on your listings yet.' : "You haven't made any offers yet."),
          style: AppText.bodyDim.copyWith(fontSize: 13.6.sp),
        ),
      ];
    }
    return [
      for (final r in mine) ...[
        () {
          final item = (r['listing'] as Map<String, dynamic>?)?['item'] as Map<String, dynamic>?;
          final chip = item == null ? null : ChipItem.fromApiItem(item);
          final title = chip?.name ?? 'Listing #${r['listingId']}';
          final status = r['status'] as String? ?? 'PENDING';
          final canRespond = _tab == 0 && status == 'PENDING';
          return _OrderRow(
            name: title,
            type: 'Offer ${dollars(r['offerAmountCents'] as int?)} · ${status[0]}${status.substring(1).toLowerCase()}',
            image: AppAssets.chipHighStakes,
            chip: chip,
            trailing: canRespond
                ? GestureDetector(
                    onTap: () => _respond(r, title),
                    child: Text(
                      'Respond',
                      style: AppText.link.copyWith(
                        fontSize: 13.6.sp,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.red,
                      ),
                    ),
                  )
                : null,
          );
        }(),
        SizedBox(height: 14.h),
      ],
    ];
  }

  static const _types = [
    'Trade Request',
    'Order Request',
    'Order Request',
    'Trade Request',
    'Order Request',
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(62)),
            SettingsHeader(title: 'Order Request'),
            SizedBox(height: 22.h),
            SegmentedTabs(
              tabs: const ['Request Received', 'Request Sent'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            SizedBox(height: 18.h),
            if (context.read<UserController>().live) ..._liveRows() else for (final type in _types) ...[
              _OrderRow(
                name: 'Yankee Bristol',
                type: type,
                image: AppAssets.chipHighStakes,
                trailing: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, switch ((_tab, type)) {
                    (0, _) => AppRoutes.confirmRequest,
                    (_, 'Trade Request') => AppRoutes.tradeSent,
                    _ => AppRoutes.requestSent,
                  }),
                  child: Text(
                    'View Details',
                    style: AppText.link.copyWith(
                      fontSize: 13.6.sp,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.red,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
            ],
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

/// Accept / reject an incoming request.
class ConfirmRequestScreen extends StatelessWidget {
  const ConfirmRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppLayout.top(64)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                  ),
                  SizedBox(height: 30.h),
                  Center(child: _blueRing()),
                  SizedBox(height: 26.h),
                  Center(
                    child: Text('Confirm Request', style: AppText.h1.copyWith(fontSize: 21.5.sp)),
                  ),
                  SizedBox(height: 30.h),
                  const RequestItemCard(),
                  SizedBox(height: 18.h),
                  const RequesterCard(),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 0, 25.w, 24.h),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Accept',
                  height: 56.h,
                  radius: 15.r,
                  gradient: AppColors.blueGradient,
                  glowColor: AppColors.planBlue,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.requestSent),
                ),
                SizedBox(height: 14.h),
                PrimaryButton(
                  label: 'Reject',
                  height: 56.h,
                  radius: 15.r,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.orderRejected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blueRing() => Container(
    width: 92.w,
    height: 92.w,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.planBlue.withValues(alpha: 0.14),
      border: Border.all(color: AppColors.planBlue, width: 2),
    ),
    child: Icon(Icons.check_rounded, size: 36.8.sp, color: const Color(0xFF8AA0F2)),
  );
}

class RequestItemCard extends StatelessWidget {
  const RequestItemCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(7.r),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(AppAssets.chipHighStakes, fit: BoxFit.cover),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Yankee Bristol', style: AppText.h3.copyWith(fontSize: 16.sp)),
              SizedBox(height: 5.h),
              Text('HD Collector', style: AppText.bodyDim.copyWith(fontSize: 13.6.sp)),
            ],
          ),
        ],
      ),
    );
  }
}

class RequesterCard extends StatelessWidget {
  const RequesterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 62.w,
            height: 62.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.redSolid, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(AppAssets.avatarTom, fit: BoxFit.cover),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tom', style: AppText.h4.copyWith(fontSize: 15.2.sp)),
              SizedBox(height: 4.h),
              Text('📍 Sturgis, SD', style: AppText.bodyDim.copyWith(fontSize: 13.2.sp)),
              SizedBox(height: 4.h),
              Text('⭐ 4.9 · 156 trades', style: AppText.bodyDim.copyWith(fontSize: 13.2.sp)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Outcome of an order request (sent / rejected).
class RequestResultScreen extends StatelessWidget {
  const RequestResultScreen({super.key, required this.rejected});

  final bool rejected;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: AppLayout.gutter, top: AppLayout.top(64)),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 140.h),
                Container(
                  width: 92.w,
                  height: 92.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (rejected ? AppColors.redSolid : AppColors.planBlue).withValues(
                      alpha: 0.14,
                    ),
                    border: Border.all(
                      color: rejected ? AppColors.redSolid : AppColors.planBlue,
                      width: 2,
                    ),
                  ),
                  child: rejected
                      ? Text(
                          'X',
                          style: AppText.h1.copyWith(fontSize: 27.2.sp, color: AppColors.redSolid),
                        )
                      : Icon(Icons.check_rounded, size: 36.8.sp, color: const Color(0xFF8AA0F2)),
                ),
                SizedBox(height: 26.h),
                Text(
                  rejected ? 'Order Rejected' : 'Request Sent',
                  style: AppText.h1.copyWith(fontSize: 21.5.sp),
                ),
                SizedBox(height: 14.h),
                Text(
                  'You have a Yankee Bristol Order request',
                  style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
                ),
                SizedBox(height: 26.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                  child: Column(
                    children: [
                      const RequestItemCard(),
                      SizedBox(height: 18.h),
                      const RequesterCard(),
                      SizedBox(height: 18.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 56.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Status',
                                    style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
                                  ),
                                  StatusBadge(
                                    label: rejected ? 'Rejected' : 'Pending',
                                    background: rejected
                                        ? AppColors.red.withValues(alpha: 0.2)
                                        : const Color(0xFF3C2F0B),
                                    textColor: rejected ? AppColors.red : AppColors.planGold,
                                    radius: 9.r,
                                    fontSize: 15,
                                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: AppColors.border),
                            SizedBox(
                              height: 56.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order ID',
                                    style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
                                  ),
                                  Text('#DD-9142', style: AppText.h5.copyWith(fontSize: 13.6.sp)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
