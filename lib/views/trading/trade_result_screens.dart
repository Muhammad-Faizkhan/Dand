import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/chip_image.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';
import '../../widgets/success_view.dart';

/// "Trade offer sent!" — green ring, pending status, follow-up actions.
class TradeSentScreen extends StatelessWidget {
  const TradeSentScreen({super.key, this.completed = false, this.trade});

  final bool completed;

  /// The real trade; null for the design's sample flow.
  final ApiTradeRequest? trade;

  @override
  Widget build(BuildContext context) {
    final t = trade;
    if (t != null) return _LiveTradeSent(trade: t, completed: completed);
    return AppScaffold(
      body: SuccessView(
        topSpace: 135,
        accent: AppColors.green,
        iconColor: const Color(0xFF3CCB84),
        title: completed ? 'Trade completed!' : 'Trade offer sent!',
        message: completed
            ? 'The trade with HDCollector is complete.\nBoth items have been released.'
            : "HDCollector has been notified.\nWe'll alert you when they respond.",
        details: [
          MapEntry(
            'Status',
            StatusBadge(
              label: completed ? 'Completed' : 'Pending',
              background: completed
                  ? AppColors.greenDark.withValues(alpha: 0.55)
                  : const Color(0xFF3C2F0B),
              textColor: completed ? const Color(0xFF3CCB84) : AppColors.planGold,
              radius: 9.r,
              fontSize: 15,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            ),
          ),
          MapEntry('Trade ID', Text('#RC-4827', style: AppText.h5.copyWith(fontSize: 13.6.sp))),
        ],
        secondaryLabel: 'Message HDCollector',
        onSecondary: () => Navigator.pushNamed(context, AppRoutes.chat, arguments: 'HDCollector'),
        primaryLabel: 'Back to Home',
        onPrimary: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false),
      ),
    );
  }
}

/// Trade confirmed / rejected outcome screens.
class TradeOutcomeScreen extends StatelessWidget {
  const TradeOutcomeScreen({super.key, required this.rejected, this.trade});

  final bool rejected;
  final ApiTradeRequest? trade;

  @override
  Widget build(BuildContext context) {
    final t = trade;
    if (t != null) return _LiveTradeSent(trade: t, completed: !rejected, rejected: rejected);
    final accent = rejected ? AppColors.redSolid : AppColors.green;
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(66)),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
            ),
            SizedBox(height: 34.h),
            Center(
              child: Container(
                width: 92.w,
                height: 92.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent, width: 2),
                ),
                child: rejected
                    ? Text(
                        'X',
                        style: AppText.h1.copyWith(fontSize: 27.2.sp, color: accent),
                      )
                    : Icon(Icons.check_rounded, size: 36.8.sp, color: const Color(0xFF3CCB84)),
              ),
            ),
            SizedBox(height: 26.h),
            Center(
              child: Text(
                rejected ? 'Trade Rejected' : 'Trade Confirmed',
                style: AppText.h1.copyWith(fontSize: 21.5.sp),
              ),
            ),
            SizedBox(height: 14.h),
            Center(
              child: Text(
                'Your Yankee Bristol is on its way.',
                style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              height: 145.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(AppAssetsRef.give, width: 96.w, height: 96.w),
                  ),
                  SizedBox(width: 20.w),
                  Container(
                    width: 52.w,
                    height: 52.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                    child: Icon(Icons.swap_vert_rounded, size: 20.8.sp, color: AppColors.white),
                  ),
                  SizedBox(width: 20.w),
                  ClipOval(
                    child: Image.asset(AppAssetsRef.get, width: 96.w, height: 96.w),
                  ),
                ],
              ),
            ),
            SizedBox(height: 22.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _row('Trade with', 'HD Collector'),
                  _row('Service fee', '\$1.50'),
                  Divider(height: 1, color: AppColors.border),
                  SizedBox(
                    height: 56.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: AppText.h4.copyWith(fontSize: 13.6.sp)),
                        Text(
                          '\$1.50',
                          style: AppText.h2.copyWith(fontSize: 16.8.sp, color: AppColors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Both items are held in escrow until the trade is confirmed by you.',
              style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.5),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => SizedBox(
    height: 56.h,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.bodyDim.copyWith(fontSize: 13.2.sp)),
        Text(value, style: AppText.h5.copyWith(fontSize: 13.6.sp)),
      ],
    ),
  );
}

void _openChat(BuildContext context, ApiTradeRequest t) {
  final id = t.otherId;
  Navigator.pushNamed(
    context,
    AppRoutes.chat,
    arguments: id == null ? t.otherUsername : context.read<ChatController>().threadWith(id, t.otherUsername, null),
  );
}

/// Outcome of a real trade: sent, completed (accepted) or rejected. No money
/// changes hands in the app; the two collectors arrange shipping in Messages.
class _LiveTradeSent extends StatelessWidget {
  const _LiveTradeSent({required this.trade, required this.completed, this.rejected = false});

  final ApiTradeRequest trade;
  final bool completed;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final other = trade.otherUsername;
    final (title, message) = switch ((completed, rejected)) {
      (_, true) => (
        'Trade declined',
        trade.incoming ? "You declined $other's offer." : "$other didn't accept this offer.",
      ),
      (true, _) => ('Trade completed!', "The chips are now in each other's collections.\nMessage $other to arrange shipping."),
      _ => ('Trade offer sent!', "$other has been notified.\nWe'll alert you when they respond."),
    };
    final chip = trade.chip;
    return AppScaffold(
      body: SuccessView(
        topSpace: 135,
        accent: rejected ? AppColors.redSolid : AppColors.green,
        iconColor: rejected ? AppColors.redSolid : const Color(0xFF3CCB84),
        icon: rejected ? Icons.close_rounded : Icons.check_rounded,
        title: title,
        message: message,
        details: [
          MapEntry(
            'Status',
            StatusBadge(
              label: rejected ? 'Declined' : (completed ? 'Completed' : 'Pending'),
              background: rejected
                  ? AppColors.redSolid.withValues(alpha: 0.2)
                  : completed
                  ? AppColors.greenDark.withValues(alpha: 0.55)
                  : const Color(0xFF3C2F0B),
              textColor: rejected ? AppColors.redSolid : (completed ? const Color(0xFF3CCB84) : AppColors.planGold),
              radius: 9.r,
              fontSize: 15,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
            ),
          ),
          if (trade.giveItems.isNotEmpty) MapEntry('You give', _value(trade.giveItems.join(', '))),
          if (trade.getItems.isNotEmpty)
            MapEntry(
              'You get',
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chip != null) ...[
                    ClipOval(child: ChipImage(chip, width: 26.w, height: 26.w)),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(child: _value(trade.getItems.join(', '))),
                ],
              ),
            ),
          if (trade.id > 0) MapEntry('Trade ID', _value('#${trade.id}')),
        ],
        secondaryLabel: 'Message $other',
        onSecondary: () => _openChat(context, trade),
        primaryLabel: 'Back to Home',
        onPrimary: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false),
      ),
    );
  }

  Widget _value(String text) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: 190.w),
    child: Text(text, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.h5.copyWith(fontSize: 13.6.sp)),
  );
}

/// The two chips shown on the outcome screens.
class AppAssetsRef {
  AppAssetsRef._();
  static String get give => AppData.myCollection[0].image;
  static String get get => AppData.yankeeBristol.image;
}
