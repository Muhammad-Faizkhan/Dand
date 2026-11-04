import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_image.dart';
import '../../widgets/common.dart';

class TradeMatchesScreen extends StatefulWidget {
  const TradeMatchesScreen({super.key});

  @override
  State<TradeMatchesScreen> createState() => _TradeMatchesScreenState();
}

class _TradeMatchesScreenState extends State<TradeMatchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TradeController>().loadMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trade = context.watch<TradeController>();
    final matches = trade.matches;
    final live = trade.client != null;
    final perfect = live ? matches.where((m) => m.giveChip != null).length : 2;
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(63)),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                ),
                SizedBox(width: 14.w),
                Icon(Icons.auto_awesome, size: 17.6.sp, color: AppColors.redSolid),
                SizedBox(width: 10.w),
                Text('Trade Matches', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
              ],
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.only(left: 40.w),
              child: Text(
                'AI suggestions based on your collection',
                style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
              ),
            ),
            SizedBox(height: 22.h),
            Container(
              height: 76.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: AppColors.redTint,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$perfect Perfect Match${perfect == 1 ? '' : 'es'}',
                        style: AppText.h4.copyWith(fontSize: 15.2.sp),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Users who want what you have',
                        style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 48.w,
                    height: 48.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.redGradient,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.swap_horiz_rounded, size: 19.2.sp, color: AppColors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 22.h),
            if (live && matches.isEmpty)
              trade.matchesLoading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary))
                  : Text(
                      'No matches yet. Add chips you want to your wishlist, or mark chips as Want, and matches will appear here.',
                      style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5),
                    ),
            for (final m in matches) ...[_MatchCard(match: m), SizedBox(height: 20.h)],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final TradeMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(initials: match.initials, size: 48.w, fontSize: 15),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.user,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.h4.copyWith(fontSize: 14.4.sp),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      match.getChip == null ? '⭐ ${match.rating} · ${match.trades} trades' : '${match.trades} trades',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              StatusBadge(
                label: '${match.match}% Match',
                background: AppColors.greenDark.withValues(alpha: 0.55),
                textColor: const Color(0xFF3CCB84),
                radius: 9.r,
                fontSize: 14.5,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _Side(label: 'You Give', image: match.give, chip: match.giveChip),
              ),
              Padding(
                padding: EdgeInsets.only(top: 26.h),
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                  child: Icon(Icons.swap_horiz_rounded, size: 17.6.sp, color: AppColors.white),
                ),
              ),
              Expanded(
                child: _Side(label: 'You Get', image: match.get, chip: match.getChip, alignEnd: true),
              ),
            ],
          ),
          SizedBox(height: 22.h),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Propose Trade',
                  height: 52.h,
                  radius: 13.r,
                  glow: false,
                  textStyle: AppText.button.copyWith(fontSize: 13.6.sp),
                  onTap: () {
                    final get = match.getChip;
                    final trade = context.read<TradeController>()..reset();
                    if (get != null) trade.setTarget(get);
                    final give = match.giveChip;
                    if (give != null) trade.toggleOffer(give);
                    Navigator.pushNamed(context, AppRoutes.proposeTrade, arguments: get);
                  },
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: SecondaryButton(
                  label: 'View',
                  height: 52.h,
                  radius: 13.r,
                  color: Colors.transparent,
                  borderColor: AppColors.blueBorder,
                  textStyle: AppText.button.copyWith(
                    fontSize: 13.6.sp,
                    color: const Color(0xFF7E97F0),
                  ),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.itemDetail, arguments: match.getChip),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.label, required this.image, this.chip, this.alignEnd = false});

  final String label;
  final String image;
  final ChipItem? chip;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.body.copyWith(fontSize: 12.8.sp)),
        SizedBox(height: 10.h),
        Container(
          width: 92.w,
          height: 92.w,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: switch (chip) {
            final ChipItem c => ChipImage(c),
            // An API match where none of your chips fits what they want.
            null when image.isEmpty => Container(
              color: AppColors.surfaceAlt,
              alignment: Alignment.center,
              child: Icon(Icons.add_rounded, size: 22.sp, color: AppColors.textSecondary),
            ),
            null => Image.asset(image, fit: BoxFit.cover),
          },
        ),
      ],
    );
  }
}
