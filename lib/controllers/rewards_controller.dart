import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';

/// 10 points = $1.
const centsPerPoint = 10;

class PointsTxn {
  const PointsTxn({required this.points, required this.reason, required this.createdAt, this.note});

  factory PointsTxn.fromJson(Map<String, dynamic> j) => PointsTxn(
    points: j['points'] as int? ?? 0,
    reason: j['reason'] as String? ?? '',
    note: j['note'] as String?,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
  );

  final int points;
  final String reason;
  final String? note;
  final DateTime createdAt;

  String get title => switch (reason) {
    'CHECK_IN_FIRST' => 'First check-in: ${note ?? 'dealer'}',
    'CHECK_IN_REPEAT' => 'Check-in: ${note ?? 'dealer'}',
    'CHIP_PURCHASE' => 'Purchased: ${note ?? 'chip'}',
    _ => note ?? 'Adjustment',
  };
}

class RankedUser {
  const RankedUser({required this.rank, required this.id, required this.name, required this.chips, this.avatarUrl, this.place});

  factory RankedUser.fromJson(Map<String, dynamic> j) => RankedUser(
    rank: j['rank'] as int? ?? 0,
    id: j['id'] as int? ?? 0,
    name: (j['fullName'] as String?)?.trim().isNotEmpty == true ? j['fullName'] as String : j['username'] as String? ?? 'Collector',
    chips: j['chipCount'] as int? ?? 0,
    avatarUrl: j['avatarUrl'] as String?,
    place: j['address'] as String?,
  );

  final int rank;
  final int id;
  final String name;
  final int chips;
  final String? avatarUrl;
  final String? place;
}

class RankedDealer {
  const RankedDealer({required this.rank, required this.id, required this.name, required this.address, required this.checkIns});

  factory RankedDealer.fromJson(Map<String, dynamic> j) => RankedDealer(
    rank: j['rank'] as int? ?? 0,
    id: j['id'] as int? ?? 0,
    name: j['name'] as String? ?? 'Dealer',
    address: j['address'] as String? ?? '',
    checkIns: j['checkInCount'] as int? ?? 0,
  );

  final int rank;
  final int id;
  final String name;
  final String address;
  final int checkIns;
}

class OfficialChip {
  const OfficialChip({
    required this.id,
    required this.title,
    required this.priceCents,
    required this.pricePoints,
    this.series,
    this.location,
    this.description,
    this.imageUrl,
    this.badge,
    this.owned = 0,
    this.soldOut = false,
    this.limitReached = false,
  });

  factory OfficialChip.fromJson(Map<String, dynamic> j) => OfficialChip(
    id: j['id'] as int,
    title: j['title'] as String? ?? '',
    series: j['series'] as String?,
    location: j['location'] as String?,
    description: j['description'] as String?,
    imageUrl: j['imageUrl'] as String?,
    badge: j['badge'] as String?,
    priceCents: j['priceCents'] as int? ?? 0,
    pricePoints: j['pricePoints'] as int? ?? 0,
    owned: j['owned'] as int? ?? 0,
    soldOut: j['soldOut'] == true,
    limitReached: j['limitReached'] == true,
  );

  final int id;
  final String title;
  final String? series;
  final String? location;
  final String? description;
  final String? imageUrl;
  final String? badge;
  final int priceCents;
  final int pricePoints;
  final int owned;
  final bool soldOut;
  final bool limitReached;
}

/// Wallet (points), leaderboard, dealer ranking and the official chip store.
class RewardsController extends ChangeNotifier {
  RewardsController({this.client});

  final ApiClient? client;

  int points = 0;
  int get balanceCents => points * centsPerPoint;

  List<PointsTxn> transactions = const [];
  List<RankedUser> leaders = const [];
  RankedUser? me;
  List<RankedDealer> dealerRanking = const [];
  List<OfficialChip> chips = const [];
  bool loading = false;

  Future<void> _run(Future<void> Function(ApiClient c) body) async {
    final c = client;
    if (c == null) return;
    loading = true;
    notifyListeners();
    try {
      await body(c);
    } on ApiException {
      // Screens keep showing what they had.
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _setWallet(Object? wallet) {
    if (wallet case {'points': final int p}) points = p;
  }

  Future<void> loadWallet() => _run((c) async {
    final results = await Future.wait([
      c.get('/api/wallet'),
      c.get('/api/wallet/transactions', query: {'pageSize': 50}),
    ]);
    _setWallet(results[0]);
    final page = results[1] as Map<String, dynamic>;
    transactions = [for (final t in (page['items'] as List<dynamic>).cast<Map<String, dynamic>>()) PointsTxn.fromJson(t)];
  });

  Future<void> loadLeaderboard() => _run((c) async {
    final data = await c.get('/api/leaderboard') as Map<String, dynamic>;
    leaders = [for (final u in (data['top'] as List<dynamic>).cast<Map<String, dynamic>>()) RankedUser.fromJson(u)];
    me = data['me'] is Map<String, dynamic> ? RankedUser.fromJson(data['me'] as Map<String, dynamic>) : null;
  });

  Future<void> loadDealerRanking() => _run((c) async {
    final data = await c.get('/api/dealers/ranking', auth: false) as List<dynamic>;
    dealerRanking = [for (final d in data.cast<Map<String, dynamic>>()) RankedDealer.fromJson(d)];
  });

  Future<void> loadChips() => _run((c) async {
    final results = await Future.wait([c.get('/api/official-chips'), c.get('/api/wallet')]);
    chips = [for (final j in (results[0] as List<dynamic>).cast<Map<String, dynamic>>()) OfficialChip.fromJson(j)];
    _setWallet(results[1]);
  });

  /// Returns null on success, otherwise the reason to show.
  Future<String?> buy(OfficialChip chip) async {
    final c = client;
    if (c == null) return null;
    try {
      final res = await c.post('/api/official-chips/${chip.id}/buy') as Map<String, dynamic>;
      _setWallet(res['wallet']);
      await loadChips();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Records a check-in. Returns (points earned, null) or (null, error message).
  Future<(int?, String?)> checkIn(int dealerId, {required double lat, required double lng, double? accuracyM}) async {
    final c = client;
    if (c == null) return (5, null);
    try {
      final res =
          await c.post('/api/dealers/$dealerId/check-in', body: {'lat': lat, 'lng': lng, 'accuracyM': ?accuracyM}) as Map<String, dynamic>;
      _setWallet(res['wallet']);
      notifyListeners();
      return ((res['checkIn'] as Map<String, dynamic>)['points'] as int?, null);
    } on ApiException catch (e) {
      return (null, e.message);
    }
  }
}

String usd(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
