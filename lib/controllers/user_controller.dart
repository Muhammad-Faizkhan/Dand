import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../core/api/user_api.dart';
import '../models/models.dart';

/// Holds the signed-in user's profile. Loaded once on sign-in; any screen
/// that shows the user's name, avatar or stats reads from here.
class UserController extends ChangeNotifier {
  UserController({this.client});

  final ApiClient? client;

  ApiUser? _user;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  ApiUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get categories => _categories;

  /// True when screens should show this account rather than the seeded design data.
  bool get live => client != null;

  String get displayName => _user?.displayName ?? 'Rider';
  String? get avatarUrl => _user?.avatarUrl;
  int get userId => _user?.id ?? 0;

  List<ChipItem> myItems = const [];
  List<ChipItem> activityItems = const [];

  /// `/api/users/me/activity` as returned, newest first.
  List<Map<String, dynamic>> activity = const [];

  /// Your latest bid on each auction you've bid on.
  List<({ChipItem chip, bool winning, int amountCents})> myBids = const [];

  /// Category ids from the profile's interests; empty until the user picks some.
  Set<int> interestIds = {};

  Future<void> load() async {
    final c = client;
    if (c == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await UserApi(c).me();
      await Future.wait([loadMyItems(), loadActivity()]);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyItems() async {
    final c = client;
    final id = _user?.id;
    if (c == null || id == null) return;
    try {
      final data = await c.get('/api/items', query: {'ownerId': id, 'pageSize': 100}) as Map<String, dynamic>;
      myItems = [
        for (final i in data['items'] as List<dynamic>? ?? const [])
          ChipItem.fromApiItem(i as Map<String, dynamic>, owner: _user!.username),
      ];
      notifyListeners();
    } on ApiException {
      // Keep the previous list.
    }
  }

  Future<void> loadActivity() async {
    final c = client;
    if (c == null) return;
    try {
      final data = (await c.get('/api/users/me/activity') as List<dynamic>).cast<Map<String, dynamic>>();
      activity = data;
      final seen = <int>{};
      activityItems = [
        for (final e in data)
          if (e['item'] case final Map<String, dynamic> item when seen.add(item['id'] as int? ?? -1))
            ChipItem.fromApiItem(item),
      ];
      final bidOn = <int>{};
      // Newest first, so the first entry per auction is your latest bid on it.
      myBids = [
        for (final e in data)
          if (e['type'] == 'bid' && e['item'] is Map<String, dynamic> && bidOn.add(e['auctionId'] as int? ?? -1))
            (
              chip: ChipItem.fromApiItem(e['item'] as Map<String, dynamic>),
              winning: e['winning'] == true,
              amountCents: e['amountCents'] as int? ?? 0,
            ),
      ];
      notifyListeners();
    } on ApiException {
      // Activity is a nice-to-have.
    }
  }

  Future<void> loadCategories() async {
    final c = client;
    if (c == null || _categories.isNotEmpty) return;
    try {
      _categories = await UserApi(c).getCategories();
      notifyListeners();
    } on ApiException {
      // non-fatal — categories stay empty
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? bio,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    final c = client;
    if (c == null) return true;
    try {
      _user = await UserApi(c).updateProfile(
        fullName: fullName,
        bio: bio,
        phone: phone,
        address: address,
        avatarUrl: avatarUrl,
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Every category, parents then their children, flattened for the interest picker.
  List<({int id, String name})> get flatCategories => [
    for (final c in _categories) ...[
      (id: c['id'] as int, name: c['name'] as String? ?? ''),
      for (final child in (c['children'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>())
        (id: child['id'] as int, name: child['name'] as String? ?? ''),
    ],
  ];

  void toggleInterest(int id) {
    interestIds.contains(id) ? interestIds.remove(id) : interestIds.add(id);
    notifyListeners();
  }

  Future<bool> setInterests(List<int> categoryIds) async {
    final c = client;
    if (c == null) return true;
    try {
      await UserApi(c).setInterests(categoryIds);
      interestIds = categoryIds.toSet();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void updateFromAvatar(String? url) {
    if (_user == null || url == _user!.avatarUrl) return;
    _user = ApiUser(
      id: _user!.id,
      email: _user!.email,
      username: _user!.username,
      fullName: _user!.fullName,
      avatarUrl: url,
      bio: _user!.bio,
      phone: _user!.phone,
      address: _user!.address,
      planCode: _user!.planCode,
      planName: _user!.planName,
      itemCount: _user!.itemCount,
      tradeCount: _user!.tradeCount,
      listingCount: _user!.listingCount,
      collectionCount: _user!.collectionCount,
      wishlistCount: _user!.wishlistCount,
      createdAt: _user!.createdAt,
    );
    notifyListeners();
  }

  void clear() {
    _user = null;
    myItems = const [];
    activityItems = const [];
    activity = const [];
    myBids = const [];
    _error = null;
    notifyListeners();
  }
}
