import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../controllers/dealers_controller.dart';
import '../controllers/rewards_controller.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/models.dart';
import 'api_feedback.dart';

/// Pops up over the main tabs while the user is within 50 m of a dealer they
/// can check in at. Only runs while the app is open.
class CheckInBanner extends StatefulWidget {
  const CheckInBanner({super.key});

  @override
  State<CheckInBanner> createState() => _CheckInBannerState();
}

class _CheckInBannerState extends State<CheckInBanner> with WidgetsBindingObserver {
  static const _every = Duration(minutes: 2);

  Timer? _timer;
  int? _dismissedId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Offline builds (tests, design review) have no dealers to poll for.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<DealersController?>()?.client != null) {
        _timer = Timer.periodic(_every, (_) => _refresh());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<DealersController?>()?.refresh();
  }

  Future<void> _checkIn(DealersController dealers, Dealer dealer) async {
    final p = dealers.position;
    final id = dealer.id;
    if (p == null || id == null) return;
    setState(() => _busy = true);
    final (points, error) = await context.read<RewardsController>().checkIn(id, lat: p.latitude, lng: p.longitude, accuracyM: p.accuracy);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showAppMessage(context, error);
      return;
    }
    showAppMessage(context, 'Checked in at ${dealer.name}: +$points point${points == 1 ? '' : 's'}');
    dealers.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dealers = context.watch<DealersController?>();
    final here = dealers?.dealerHere;
    if (dealers == null || dealers.client == null || here == null || !here.checkInOpen || here.id == _dismissedId) {
      return const SizedBox.shrink();
    }
    final first = here.nextCheckInAt == null;
    return SafeArea(
      bottom: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 12.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.redBorder),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: AppColors.redGradient, borderRadius: BorderRadius.circular(12.r)),
              child: Icon(Icons.storefront_outlined, size: 18.sp, color: AppColors.white),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're at ${here.name}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.h4.copyWith(fontSize: 13.6.sp),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    first ? 'First visit: check in for 5 points' : 'Check in again for 1 point',
                    style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _busy ? null : () => _checkIn(dealers, here),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                decoration: BoxDecoration(gradient: AppColors.redGradient, borderRadius: BorderRadius.circular(10.r)),
                child: Text(_busy ? '…' : 'Check In', style: AppText.buttonSm.copyWith(fontSize: 12.sp)),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _dismissedId = here.id),
              icon: Icon(Icons.close_rounded, size: 18.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
