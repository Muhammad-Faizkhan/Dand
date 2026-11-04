import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/notifications_api.dart';
import '../core/constants/app_colors.dart';
import '../core/routes/app_routes.dart';
import '../core/utils/format.dart';
import '../models/models.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController({this.client});

  final ApiClient? client;

  List<ApiNotification> _notifications = [];
  bool _loading = false;
  bool _loaded = false;

  List<ApiNotification> get notifications => _notifications;
  bool get loading => _loading;
  bool get loaded => _loaded;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> load() async {
    final c = client;
    if (c == null) return;
    _loading = true;
    notifyListeners();
    try {
      _notifications = await NotificationsApi(c).getNotifications();
      _loaded = true;
    } on ApiException {
      // Keep whatever was shown last.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    final c = client;
    if (c == null) return;
    _notifications = [for (final n in _notifications) n.id == id ? n.copyWith(read: true) : n];
    notifyListeners();
    try {
      await NotificationsApi(c).markRead(id);
    } on ApiException {
      // Marked read locally; the server catches up on the next load.
    }
  }

  Future<void> markAllRead() async {
    final c = client;
    if (c == null) return;
    _notifications = [for (final n in _notifications) n.copyWith(read: true)];
    notifyListeners();
    try {
      await NotificationsApi(c).markAllRead();
    } on ApiException {
      // Same as markRead.
    }
  }

  /// The tile the Notifications screen draws for [n].
  static AppNotification tileFor(ApiNotification n) {
    final (icon, color, route) = switch (n.type) {
      'trade_request' || 'trade_accepted' || 'trade_rejected' => (Icons.swap_horiz_rounded, AppColors.redSolid, AppRoutes.tradeMatches),
      'bid_outbid' => (Icons.gavel_rounded, const Color(0xFFF5A623), AppRoutes.myActivity),
      'auction_won' => (Icons.emoji_events_outlined, AppColors.green, AppRoutes.myActivity),
      'order_request' || 'order_request_accepted' || 'order_request_rejected' => (Icons.request_quote_outlined, const Color(0xFF5B8DEF), AppRoutes.orderRequests),
      'order_placed' || 'order_status' => (Icons.local_shipping_outlined, const Color(0xFF5B8DEF), AppRoutes.ordersPurchase),
      'new_message' => (Icons.chat_bubble_outline_rounded, AppColors.green, AppRoutes.messages),
      _ => (Icons.notifications_none_rounded, AppColors.redSolid, null),
    };
    return AppNotification(
      title: n.title.isNotEmpty ? n.title : n.body,
      body: n.title.isNotEmpty ? n.body : '',
      time: timeAgo(n.createdAt),
      icon: icon,
      color: color,
      unread: !n.read,
      route: route,
    );
  }
}
