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

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.highlight = false,
  });

  final int rank;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: highlight ? AppColors.redTint : AppColors.surface,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: highlight ? AppColors.redBorder : AppColors.borderStrong),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34.w,
            child: Text('#$rank', style: AppText.h4.copyWith(fontSize: 13.6.sp)),
          ),
          leading,
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h4.copyWith(fontSize: 14.4.sp),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    '📍 $subtitle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyDim.copyWith(fontSize: 11.6.sp),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

Widget _pill(String text, {Color color = AppColors.red}) => Container(
  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.14),
    borderRadius: BorderRadius.circular(18.r),
    border: Border.all(color: color.withValues(alpha: 0.5)),
  ),
  child: Text(
    text,
    style: AppText.h4.copyWith(fontSize: 13.6.sp, color: AppColors.white),
  ),
);

// Leaderboard

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with _LoadOnOpen {
  @override
  Future<void> load(RewardsController r) => r.loadLeaderboard();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RewardsController>();
    final top = r.leaders;
    final me = r.me;
    final myId = context.watch<UserController>().userId;
    return _Page(
      title: 'Leaderboard',
      subtitle: 'Ranked by chips in each collection',
      onRefresh: r.loadLeaderboard,
      children: [
        if (top.isEmpty)
          _empty(r.loading ? 'Loading…' : 'No collectors ranked yet. Add chips to your collection to get on the board.')
        else ...[
          _Podium(top: top.take(3).toList(), myId: myId),
          SizedBox(height: 18.h),
          for (final u in top.skip(3))
            _RankRow(
              rank: u.rank,
              highlight: u.id == myId,
              leading: _Avatar(name: u.name, url: u.avatarUrl, size: 40),
              title: u.id == myId ? 'You' : u.name,
              subtitle: u.place ?? '',
              trailing: _pill('${u.chips}'),
            ),
          if (me != null && !top.any((u) => u.id == me.id)) ...[
            SizedBox(height: 6.h),
            _RankRow(
              rank: me.rank,
              highlight: true,
              leading: _Avatar(name: me.name, url: me.avatarUrl, size: 40),
              title: 'You',
              subtitle: me.place ?? '',
              trailing: _pill('${me.chips}'),
            ),
          ],
        ],
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top, required this.myId});

  final List<RankedUser> top;
  final int myId;

  @override
  Widget build(BuildContext context) {
    Widget spot(RankedUser? u, Color color, double height, {bool crown = false}) {
      if (u == null) return const Expanded(child: SizedBox());
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (crown) Icon(Icons.workspace_premium_rounded, color: _gold, size: 22.sp),
            _Avatar(name: u.name, url: u.avatarUrl, size: crown ? 66 : 52, ring: color),
            SizedBox(height: 6.h),
            Text(
              u.id == myId ? 'You' : u.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h5.copyWith(fontSize: 12.sp),
            ),
            if (u.place != null) Text(u.place!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySmDim),
            SizedBox(height: 8.h),
            Container(
              height: height.h,
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                border: Border.all(color: color.withValues(alpha: 0.6)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${u.chips}', style: AppText.h2.copyWith(fontSize: crown ? 18.sp : 15.sp)),
                  Text('TOTAL CHIPS', style: AppText.captionBold.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    RankedUser? at(int i) => i < top.length ? top[i] : null;
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 14.h, 10.w, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [spot(at(1), _silver, 58), spot(at(0), _gold, 78, crown: true), spot(at(2), _bronze, 58)],
      ),
    );
  }
}

// Dealer Ships Ranking

class DealerRankingScreen extends StatefulWidget {
  const DealerRankingScreen({super.key});

  @override
  State<DealerRankingScreen> createState() => _DealerRankingScreenState();
}

class _DealerRankingScreenState extends State<DealerRankingScreen> with _LoadOnOpen {
  @override
  Future<void> load(RewardsController r) => r.loadDealerRanking();

  @override
  Widget build(BuildContext context) {
    final r = context.watch<RewardsController>();
    final list = r.dealerRanking;
    Widget count(int n) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.how_to_reg_rounded, size: 14.sp, color: AppColors.red),
        SizedBox(width: 4.w),
        Text('$n', style: AppText.h5.copyWith(color: AppColors.red)),
      ],
    );
    final dealerIcon = InitialsAvatar(initials: 'HD', size: 40.w, fontSize: 13);
    return _Page(
      title: 'Dealer Ships Ranking',
      subtitle: 'The least visited stops, rarest first',
      onRefresh: r.loadDealerRanking,
      children: [
        if (list.isEmpty)
          _empty(r.loading ? 'Loading…' : 'No dealerships listed yet.')
        else ...[
          _TopDealer(dealer: list.first),
          SizedBox(height: 14.h),
          for (final d in list.skip(1))
            _RankRow(rank: d.rank, leading: dealerIcon, title: d.name, subtitle: d.address, trailing: count(d.checkIns)),
        ],
      ],
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(label: '#1 RANK', background: _gold, textColor: AppColors.black, radius: 8.r, fontSize: 11),
              SizedBox(width: 8.w),
              StatusBadge(label: 'ULTRA RARE STOP', background: AppColors.redTint, textColor: AppColors.red, radius: 8.r, fontSize: 11),
              const Spacer(),
              InitialsAvatar(initials: 'HD', size: 44.w, fontSize: 14),
            ],
          ),
          SizedBox(height: 10.h),
          Text(dealer.name, style: AppText.h2.copyWith(fontSize: 17.6.sp)),
          if (dealer.address.isNotEmpty) Text('📍 ${dealer.address}', style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
          SizedBox(height: 14.h),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 10.h),
              decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(10.r)),
              child: Column(
                children: [
                  Text('Total Checked-In', style: AppText.h5.copyWith(color: AppColors.black)),
                  Text(
                    dealer.checkIns.toString().padLeft(2, '0'),
                    style: AppText.h1.copyWith(color: AppColors.redDark, fontSize: 22.sp),
                  ),
                ],
              ),
            ),
          ),
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
    return _Page(
      title: 'Transaction History',
      subtitle: 'Every point earned and spent',
      onRefresh: r.loadWallet,
      children: [_TxnList(items: r.transactions, loading: r.loading)],
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: AppColors.borderStrong),
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
    final color = earned ? AppColors.green : AppColors.red;
    final icon = switch (t.reason) {
      'CHIP_PURCHASE' => Icons.toll_outlined,
      _ when earned => Icons.arrow_downward_rounded,
      _ => Icons.arrow_upward_rounded,
    };
    final d = t.createdAt;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final when = '${months[d.month - 1]} ${d.day}, ${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.7)),
            ),
            child: Icon(icon, size: 16.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontSize: 13.sp),
                ),
                Text(when, style: AppText.bodySmDim),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${earned ? '+' : '-'}${usd(t.points.abs() * centsPerPoint)}',
                style: AppText.h5.copyWith(color: color, fontSize: 13.sp),
              ),
              Text('${earned ? '+' : ''}${t.points} pts', style: AppText.bodySmDim),
            ],
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
