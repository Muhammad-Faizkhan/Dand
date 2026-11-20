import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../controllers/rewards_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/format.dart';
import '../../core/utils/layout.dart';
import '../../widgets/api_feedback.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/settings_widgets.dart';

const _gold = AppColors.planGold;
const _silver = AppColors.planSilver;
const _bronze = Color(0xFFD9822B);

/// Runs [load] once after the first frame, so screens fetch on open.
mixin _LoadOnOpen<T extends StatefulWidget> on State<T> {
  Future<void> load(RewardsController r);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load(context.read<RewardsController>());
    });
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.subtitle, required this.children, this.onRefresh});

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
      children: [
        SizedBox(height: AppLayout.top(62)),
        SettingsHeader(title: title),
        Padding(
          padding: EdgeInsets.only(left: 37.w, top: 6.h),
          child: Text(subtitle, style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
        ),
        SizedBox(height: 18.h),
        ...children,
        SizedBox(height: 40.h),
      ],
    );
    return AppScaffold(
      body: onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list),
    );
  }
}

Widget _empty(String text) => Padding(
  padding: EdgeInsets.symmetric(vertical: 40.h),
  child: Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
    ),
  ),
);

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url, this.size = 44, this.ring});

  final String name;
  final String? url;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final fallback = InitialsAvatar(initials: initialsOf(name), size: size.w, fontSize: size * 0.32);
    return Container(
      padding: EdgeInsets.all(ring == null ? 0 : 2.5.w),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
      child: url == null
          ? fallback
          : ClipOval(
              child: Image.network(url!, width: size.w, height: size.w, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
            ),
    );
  }
}

/// "1294" -> "1,294".
String _thousands(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

const _rowBorder = Color(0x33FFFFFF);

/// 📍 Sturgis, SD — red pin, grey text.
Widget _place(String text, {double size = 11}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(Icons.place, size: size.sp, color: AppColors.red),
    SizedBox(width: 3.w),
    Flexible(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.bodySmDim.copyWith(fontSize: size.sp),
      ),
    ),
  ],
);

/// Check-in count: red person-check icon and number.
Widget _checkIns(int n, {double size = 12}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(Icons.how_to_reg_rounded, size: (size + 2).sp, color: AppColors.red),
    SizedBox(width: 4.w),
    Text(_thousands(n), style: AppText.h5.copyWith(fontSize: size.sp, color: AppColors.red)),
  ],
);

Widget _dealerAvatar(double size) => Container(
  width: size.w,
  height: size.w,
  alignment: Alignment.center,
  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.redGradient),
  child: Text('HD', style: AppText.h5.copyWith(fontSize: (size * 0.32).sp, fontWeight: FontWeight.w700)),
);

/// "#2 RANK" tag in the place's medal colour.
Widget _rankTag(int place, Color color) => Container(
  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.r)),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (place == 1) ...[Icon(Icons.military_tech_rounded, size: 13.sp, color: AppColors.black), SizedBox(width: 3.w)],
      Text('#$place RANK', style: AppText.captionBold.copyWith(fontSize: 10.sp, color: AppColors.black, fontWeight: FontWeight.w700)),
    ],
  ),
);

Color _medal(int place) => switch (place) {
  1 => _gold,
  2 => _silver,
  _ => _bronze,
};

// Rankings: one screen with User Ranking / Dealership Ranking tabs, as in the Figma "Rankings" frames.

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key, this.dealers = false});

  /// Open on the Dealership Ranking tab.
  final bool dealers;

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  late bool _dealers = widget.dealers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() {
    final r = context.read<RewardsController>();
    return _dealers ? r.loadDealerRanking() : r.loadLeaderboard();
  }

  void _show(bool dealers) {
    if (dealers == _dealers) return;
    setState(() => _dealers = dealers);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RewardsController>();
    final myId = context.watch<UserController>().userId;
    return _Page(
      title: 'Rankings',
      subtitle: 'Ranked purely by verified owned biker chips',
      onRefresh: _load,
      children: [
        _RankTabs(dealers: _dealers, onChanged: _show),
        SizedBox(height: 16.h),
        if (_dealers) ..._dealerList(r) else ..._userList(r, myId),
      ],
    );
  }

  List<Widget> _userList(RewardsController r, int myId) {
    final top = r.leaders;
    final me = r.me;
    if (top.isEmpty) return [_empty(r.loading ? 'Loading…' : 'No collectors ranked yet. Add chips to your collection to get on the board.')];
    return [
      _Podium(top: top.take(3).toList(), myId: myId),
      SizedBox(height: 14.h),
      for (final u in top.skip(3)) _UserRow(user: u, isMe: u.id == myId),
      if (me != null && !top.any((u) => u.id == me.id)) ...[SizedBox(height: 4.h), _UserRow(user: me, isMe: true)],
    ];
  }

  List<Widget> _dealerList(RewardsController r) {
    final list = r.dealerRanking;
    if (list.isEmpty) return [_empty(r.loading ? 'Loading…' : 'No dealerships listed yet.')];
    return [
      _TopDealer(dealer: list.first),
      if (list.length > 1) ...[
        SizedBox(height: 12.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _RunnerUpDealer(dealer: list[1])),
            SizedBox(width: 12.w),
            Expanded(child: list.length > 2 ? _RunnerUpDealer(dealer: list[2]) : const SizedBox()),
          ],
        ),
      ],
      SizedBox(height: 12.h),
      for (final d in list.skip(3)) _DealerRow(dealer: d),
    ];
  }
}

class _RankTabs extends StatelessWidget {
  const _RankTabs({required this.dealers, required this.onChanged});

  final bool dealers;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool selected, bool value) => Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected ? AppColors.redGradientH : null,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              label,
              style: AppText.h5.copyWith(
                fontSize: 12.8.sp,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      height: 46.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [tab('User Ranking', !dealers, false), tab('Dealership Ranking', dealers, true)]),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top, required this.myId});

  final List<RankedUser> top;
  final int myId;

  // Light pedestal tints from the design: cream for gold, pale blue for silver, peach for bronze.
  static const _pedestal = {1: Color(0xFFFFF1C4), 2: Color(0xFFE4E9FA), 3: Color(0xFFFFE2C6)};

  @override
  Widget build(BuildContext context) {
    Widget spot(RankedUser? u, int place) {
      if (u == null) return const Expanded(child: SizedBox());
      final first = place == 1;
      final color = _medal(place);
      final avatar = first ? 62.0 : 50.0;
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (first) Icon(Icons.workspace_premium_rounded, color: _gold, size: 22.sp),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _Avatar(name: u.name, url: u.avatarUrl, size: avatar, ring: color),
                Positioned(
                  right: -4.w,
                  bottom: -4.w,
                  child: Container(
                    width: 22.w,
                    height: 22.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: Text('#$place', style: AppText.captionBold.copyWith(fontSize: 8.8.sp, color: AppColors.black, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              u.id == myId ? 'You' : u.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h5.copyWith(fontSize: first ? 13.6.sp : 12.8.sp, fontWeight: FontWeight.w700),
            ),
            if (u.place != null) _place(u.place!, size: 10.4),
            SizedBox(height: 8.h),
            Container(
              height: (first ? 74 : 54).h,
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_pedestal[place]!, _pedestal[place]!.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                border: Border(top: BorderSide(color: color, width: 3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 13.w,
                          height: 13.w,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.white, width: 2),
                            boxShadow: [BoxShadow(color: color, spreadRadius: 1)],
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          _thousands(u.chips),
                          style: AppText.h4.copyWith(fontSize: first ? 15.sp : 12.sp, color: const Color(0xFF1B1B22), letterSpacing: first ? 1 : 0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'TOTAL CHIPS',
                    style: AppText.captionBold.copyWith(
                      fontSize: 9.sp,
                      letterSpacing: 0.5,
                      color: first ? const Color(0xFF5A4300) : const Color(0xFF3A3A44),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    RankedUser? at(int i) => i < top.length ? top[i] : null;
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 14.h, 8.w, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.blueBorder.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [spot(at(1), 2), spot(at(0), 1), spot(at(2), 3)],
      ),
    );
  }
}

/// Rank #4 onward.
class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.isMe});

  final RankedUser user;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isMe ? AppColors.redTint : AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isMe ? AppColors.redBorder : _rowBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36.w,
            child: Text('#${user.rank}', style: AppText.h4.copyWith(fontSize: 14.4.sp)),
          ),
          _Avatar(name: user.name, url: user.avatarUrl, size: 40),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMe ? 'You' : user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h4.copyWith(fontSize: 14.4.sp)),
                if (user.place != null) ...[SizedBox(height: 3.h), _place(user.place!)],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hexagon_outlined, size: 15.sp, color: AppColors.red),
                SizedBox(width: 6.w),
                Text(_thousands(user.chips), style: AppText.h4.copyWith(fontSize: 14.4.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopDealer extends StatelessWidget {
  const _TopDealer({required this.dealer});

  final RankedDealer dealer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.95, -0.9),
          radius: 1.1,
          colors: [Color(0x99A91318), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.blueBorder.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _rankTag(1, _gold),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(color: AppColors.redTint, borderRadius: BorderRadius.circular(8.r)),
                          child: Text(
                            'ULTRA RARE STOP',
                            style: AppText.captionBold.copyWith(fontSize: 9.6.sp, color: AppColors.red, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(dealer.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.h2.copyWith(fontSize: 17.6.sp)),
                    if (dealer.address.isNotEmpty) ...[SizedBox(height: 3.h), _place(dealer.address, size: 11.6)],
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              _dealerAvatar(48),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF2CB55), Color(0xFFD9A62A)]),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              children: [
                Text('Total Checked-In', style: AppText.h5.copyWith(fontSize: 13.sp, color: AppColors.black)),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.how_to_reg_rounded, size: 20.sp, color: AppColors.redDark),
                    SizedBox(width: 6.w),
                    Text(
                      dealer.checkIns.toString().padLeft(2, '0'),
                      style: AppText.h1.copyWith(color: AppColors.redDark, fontSize: 22.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// #2 and #3, side by side.
class _RunnerUpDealer extends StatelessWidget {
  const _RunnerUpDealer({required this.dealer});

  final RankedDealer dealer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _rowBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _rankTag(dealer.rank, _medal(dealer.rank)),
              const Spacer(),
              _checkIns(dealer.checkIns, size: 11),
            ],
          ),
          SizedBox(height: 10.h),
          Text(dealer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h4.copyWith(fontSize: 14.sp)),
          if (dealer.address.isNotEmpty) ...[SizedBox(height: 3.h), _place(dealer.address, size: 10.4)],
        ],
      ),
    );
  }
}

/// Dealer rank #4 onward.
class _DealerRow extends StatelessWidget {
  const _DealerRow({required this.dealer});

  final RankedDealer dealer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _rowBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36.w,
            child: Text('#${dealer.rank}', style: AppText.h4.copyWith(fontSize: 14.4.sp)),
          ),
          _dealerAvatar(40),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dealer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h4.copyWith(fontSize: 14.4.sp)),
                if (dealer.address.isNotEmpty) ...[SizedBox(height: 3.h), _place(dealer.address)],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _checkIns(dealer.checkIns, size: 11),
        ],
      ),
    );
  }
}

// Wallet

Future<void> _cardsComingSoon(BuildContext context) =>
    ConfirmDialog.ask(
      context,
      title: 'Coming soon',
      message:
          'Adding money by card and withdrawing to your bank are on the way. For now, earn points by checking in at dealerships: 10 points = \$1.',
      confirmLabel: 'Find dealerships',
      cancelLabel: 'OK',
    ).then((go) {
      if (go == true && context.mounted) Navigator.pushNamed(context, AppRoutes.mapDealers);
    });

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with _LoadOnOpen {
  @override
  Future<void> load(RewardsController r) => r.loadWallet();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RewardsController>();
    return _Page(
      title: 'Wallet',
      subtitle: 'Your points and what you did with them',
      onRefresh: r.loadWallet,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 18.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A4A8A), Color(0xFF1B3266)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: AppColors.blueBorder),
          ),
          child: Column(
            children: [
              Text('AVAILABLE WALLET BALANCE', style: AppText.captionBold.copyWith(letterSpacing: 0.9, color: AppColors.textSecondary)),
              SizedBox(height: 8.h),
              Text(usd(r.balanceCents), style: AppText.display.copyWith(fontSize: 32.sp)),
              SizedBox(height: 4.h),
              Text('${r.points} points · 10 points = \$1', style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(label: 'Add Funds', height: 46.h, radius: 12.r, onTap: () => _cardsComingSoon(context)),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SecondaryButton(label: 'Withdraw', height: 46.h, radius: 12.r, onTap: () => _cardsComingSoon(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        PrimaryButton(
          label: 'Spend points in the Chip Marketplace',
          height: 48.h,
          radius: 12.r,
          gradient: AppColors.blueGradient,
          onTap: () => Navigator.pushNamed(context, AppRoutes.chipStore),
        ),
        SizedBox(height: 22.h),
        Row(
          children: [
            Text('Recent Transactions', style: AppText.h3.copyWith(fontSize: 15.sp)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.walletHistory),
              child: Text('See all', style: AppText.link.copyWith(fontSize: 13.sp)),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _TxnList(items: r.transactions.take(5).toList(), loading: r.loading),
      ],
    );
  }
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with _LoadOnOpen {
  @override
  Future<void> load(RewardsController r) => r.loadWallet();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RewardsController>();
    final since = DateTime.now().subtract(const Duration(days: 30));
    return _Page(
      title: 'Transaction History',
      subtitle: 'Your transaction history will show here',
      onRefresh: r.loadWallet,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 12.sp, color: AppColors.textSecondary),
            SizedBox(width: 6.w),
            Text(
              'LAST 30 DAYS TRANSACTIONS',
              style: AppText.captionBold.copyWith(fontSize: 10.sp, letterSpacing: 0.6, color: AppColors.textSecondary),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        _TxnList(items: r.transactions.where((t) => t.createdAt.isAfter(since)).toList(), loading: r.loading),
      ],
    );
  }
}

class _TxnList extends StatelessWidget {
  const _TxnList({required this.items, required this.loading});

  final List<PointsTxn> items;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _empty(loading ? 'Loading…' : 'Nothing yet. Check in at a dealership to earn your first points.');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: _rowBorder),
      ),
      child: Column(
        children: [
          for (final (i, t) in items.indexed) ...[if (i > 0) const Divider(height: 1, color: AppColors.borderStrong), _TxnRow(t: t)],
        ],
      ),
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.t});

  final PointsTxn t;

  @override
  Widget build(BuildContext context) {
    final earned = t.points > 0;
    final purchase = t.reason == 'CHIP_PURCHASE';
    final color = earned ? AppColors.green : AppColors.red;
    final d = t.createdAt;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final when = '${months[d.month - 1]} ${d.day}, ${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final titleStyle = AppText.body.copyWith(fontSize: 13.sp);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          // Green ↓ for money in, red ↑ for money out, grey coin for a chip bought (as in the design).
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: purchase ? AppColors.surfaceLight : color.withValues(alpha: 0.08),
              border: Border.all(color: purchase ? AppColors.borderStrong : color.withValues(alpha: 0.7)),
            ),
            child: Icon(
              purchase ? Icons.toll_outlined : (earned ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
              size: 17.sp,
              color: purchase ? AppColors.white : color,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  purchase
                      ? TextSpan(
                          text: 'Purchased: ',
                          children: [TextSpan(text: t.note ?? 'chip', style: titleStyle.copyWith(fontWeight: FontWeight.w700))],
                        )
                      : TextSpan(text: t.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                SizedBox(height: 2.h),
                Text(when, style: AppText.bodySmDim.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '${earned ? '+' : '-'}${usd(t.points.abs() * centsPerPoint)}',
            style: AppText.h5.copyWith(
              color: color,
              fontSize: 13.6.sp,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// Chip Marketplace (DanD's official chips, bought with points)

class ChipStoreScreen extends StatefulWidget {
  const ChipStoreScreen({super.key});

  @override
  State<ChipStoreScreen> createState() => _ChipStoreScreenState();
}

class _ChipStoreScreenState extends State<ChipStoreScreen> with _LoadOnOpen {
  int? _buying;

  @override
  Future<void> load(RewardsController r) => r.loadChips();

  Future<void> _buy(RewardsController r, OfficialChip chip) async {
    final ok = await ConfirmDialog.ask(
      context,
      title: 'Buy ${chip.title}?',
      message: '${chip.pricePoints} points (${usd(chip.priceCents)}) will come out of your wallet and the chip goes into your collection.',
      confirmLabel: 'Buy for ${chip.pricePoints} pts',
      cancelLabel: 'Cancel',
    );
    if (ok != true || !mounted) return;
    setState(() => _buying = chip.id);
    final error = await r.buy(chip);
    if (!mounted) return;
    setState(() => _buying = null);
    if (error != null) {
      showAppMessage(context, error);
      return;
    }
    context.read<UserController>().loadMyItems();
    showAppMessage(context, '${chip.title} is in your collection.');
  }

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RewardsController>();
    return _Page(
      title: 'Chip Marketplace',
      subtitle: 'Official chips, paid with points · balance ${usd(r.balanceCents)}',
      onRefresh: r.loadChips,
      children: [
        if (r.chips.isEmpty)
          _empty(r.loading ? 'Loading…' : 'No official chips on sale right now.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: r.chips.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              mainAxisExtent: 300.h,
            ),
            itemBuilder: (context, i) {
              final c = r.chips[i];
              return _StoreCard(chip: c, busy: _buying == c.id, canAfford: r.points >= c.pricePoints, onBuy: () => _buy(r, c));
            },
          ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.chip, required this.busy, required this.canAfford, required this.onBuy});

  final OfficialChip chip;
  final bool busy;
  final bool canAfford;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final blocked = chip.soldOut || chip.limitReached;
    final label = switch (chip) {
      _ when chip.soldOut => 'Sold Out',
      _ when chip.limitReached => 'Max Owned',
      _ when busy => 'Buying…',
      _ when chip.owned > 0 => 'Buy Another',
      _ => 'Buy Chip',
    };
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  chip.series ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.captionBold.copyWith(color: AppColors.textSecondary),
                ),
              ),
              if (chip.badge != null)
                StatusBadge(label: chip.badge!, background: AppColors.redTint, textColor: AppColors.red, radius: 6.r, fontSize: 9),
            ],
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: Center(
              child: ClipOval(
                child: chip.imageUrl == null
                    ? Container(
                        width: 96.w,
                        height: 96.w,
                        color: AppColors.surfaceAlt,
                        child: Icon(Icons.toll_rounded, size: 40.sp, color: _gold),
                      )
                    : Image.network(chip.imageUrl!, width: 96.w, height: 96.w, fit: BoxFit.cover),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            chip.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.h4.copyWith(fontSize: 13.6.sp),
          ),
          if (chip.location != null) Text('📍 ${chip.location}', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySmDim),
          Text(chip.owned > 0 ? 'Owned: ${chip.owned}' : 'Not owned', style: AppText.bodySmDim),
          SizedBox(height: 6.h),
          Text(
            '${chip.pricePoints} pts · ${usd(chip.priceCents)}',
            style: AppText.h5.copyWith(fontSize: 13.sp, color: canAfford ? AppColors.white : AppColors.red),
          ),
          SizedBox(height: 8.h),
          PrimaryButton(label: label, height: 36.h, radius: 10.r, enabled: !blocked && !busy, onTap: onBuy),
        ],
      ),
    );
  }
}
