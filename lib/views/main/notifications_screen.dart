import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/notifications_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificationsController>();
    final live = ctrl.client != null;
    final List<AppNotification> today;
    final List<AppNotification> earlier;
    final List<int?> todayIds;
    final List<int?> earlierIds;
    if (live) {
      final now = DateTime.now();
      bool isToday(ApiNotification n) {
        final t = DateTime.tryParse(n.createdAt)?.toLocal();
        return t != null && t.year == now.year && t.month == now.month && t.day == now.day;
      }

      final t = ctrl.notifications.where(isToday).toList();
      final e = ctrl.notifications.where((n) => !isToday(n)).toList();
      today = t.map(NotificationsController.tileFor).toList();
      earlier = e.map(NotificationsController.tileFor).toList();
      todayIds = [for (final n in t) n.id];
      earlierIds = [for (final n in e) n.id];
    } else {
      today = AppData.notifications.take(2).toList();
      earlier = AppData.notifications.skip(2).toList();
      todayIds = List.filled(today.length, null);
      earlierIds = List.filled(earlier.length, null);
    }

    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(62)),
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                ),
                SizedBox(width: 16.w),
                Text('Notifications', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                if (live && ctrl.unreadCount > 0) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: ctrl.markAllRead,
                    child: Text('Mark all read', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, color: AppColors.red)),
                  ),
                ],
              ],
            ),
            SizedBox(height: 24.h),
            if (live && ctrl.loading && ctrl.notifications.isEmpty)
              const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary))
            else if (live && ctrl.notifications.isEmpty)
              Text("You're all caught up. Trades, bids, orders and messages will show up here.",
                  style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5))
            else ...[
              if (today.isNotEmpty) ...[
                _section('Today'),
                for (var i = 0; i < today.length; i++) _Tile(item: today[i], id: todayIds[i]),
                SizedBox(height: 12.h),
              ],
              if (earlier.isNotEmpty) ...[
                _section('Earlier'),
                for (var i = 0; i < earlier.length; i++) _Tile(item: earlier[i], id: earlierIds[i]),
              ],
            ],
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: EdgeInsets.only(bottom: 14.h),
    child: Text(
      t,
      style: AppText.h5.copyWith(fontSize: 13.6.sp, color: AppColors.textSecondary),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, this.id});

  final AppNotification item;

  /// The API notification id, null for the seeded ones.
  final int? id;

  @override
  Widget build(BuildContext context) {
    final accent = item.color ?? AppColors.redSolid;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: item.route == null && id == null
          ? null
          : () {
              final id = this.id;
              if (id != null && item.unread) context.read<NotificationsController>().markRead(id);
              if (item.route != null) Navigator.pushNamed(context, item.route!, arguments: item.arguments);
            },
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: item.unread ? AppColors.red.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Icon(item.icon, size: 18.4.sp, color: accent),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppText.body.copyWith(fontSize: 13.6.sp, height: 1.35),
                      children: [
                        TextSpan(
                          text: item.title,
                          style: AppText.h4.copyWith(fontSize: 13.6.sp),
                        ),
                        if (item.body.isNotEmpty) TextSpan(text: '\n${item.body}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(item.time, style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
                ],
              ),
            ),
            if (item.unread)
              Container(
                width: 10.w,
                height: 10.w,
                margin: EdgeInsets.only(top: 4.h),
                decoration: const BoxDecoration(color: AppColors.redSolid, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
