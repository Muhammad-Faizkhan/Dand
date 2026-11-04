import 'dart:convert';

import 'package:dandcollection/controllers/app_controller.dart';
import 'package:dandcollection/core/api/api_client.dart';
import 'package:dandcollection/core/api/token_store.dart';
import 'package:dandcollection/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

const _auction = ChipItem(
  id: '9',
  name: 'Bourbon Street',
  image: 'assets/images/chip_bourbon.jpg',
  price: 110,
  type: ListingType.auction,
  auctionId: 42,
  bidIncrement: 10,
);

Map<String, Object?> _me(int bidCount) => {
  'plan': {'name': 'Free Trial', 'billingPeriod': 'trial_15d', 'bidLimit': 20, 'itemLimit': 100},
  'bidCount': bidCount,
  'itemCount': 0,
  'trialEndsAt': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
};

AuctionController _controller(Future<http.Response> Function(http.Request) handler, List<http.Request> seen) {
  final client = ApiClient(
    tokens: MemoryTokenStore(),
    baseUrl: 'https://api.test',
    httpClient: MockClient((req) {
      seen.add(req);
      return handler(req);
    }),
  );
  return AuctionController(client: client);
}

void main() {
  test('a bid goes to the auction endpoint in cents and refreshes the counter', () async {
    final seen = <http.Request>[];
    var bids = 4;
    final c = _controller((req) async {
      if (req.url.path == '/api/subscriptions/me') return _json(_me(bids));
      if (req.method == 'POST') bids++;
      return _json({'id': 1}, 201);
    }, seen);

    c.open(_auction);
    expect(c.myBid, 120, reason: 'opens at current price + the auction increment');

    final result = await c.placeBid(_auction);

    expect(result.status, BidStatus.placed);
    final bid = seen.singleWhere((r) => r.method == 'POST');
    expect(bid.url.path, '/api/auctions/42/bids');
    expect(jsonDecode(bid.body), {'amountCents': 12000});
    expect(c.currentBid, 120);
    expect(c.plan?.bidsLeft, 15);
  });

  test('UPGRADE_REQUIRED becomes an upgrade result, not a generic failure', () async {
    final c = _controller((req) async {
      if (req.url.path == '/api/subscriptions/me') return _json(_me(20));
      return _json({
        'error': "You've used all 20 bids on the Free Trial plan. Subscribe for unlimited bidding.",
        'details': {'code': 'UPGRADE_REQUIRED', 'reason': 'bid_limit', 'limit': 20, 'used': 20},
      }, 403);
    }, []);

    c.open(_auction);
    final result = await c.placeBid(_auction);

    expect(result.status, BidStatus.upgradeRequired);
    expect(result.message, contains('20 bids'));
    expect(c.currentBid, 110, reason: 'a refused bid must not move the price');
    expect(c.plan?.bidsLeft, 0);
  });

  test('other errors stay ordinary failures', () async {
    final c = _controller((req) async {
      if (req.url.path == '/api/subscriptions/me') return _json(_me(0));
      return _json({'error': 'Auction has already ended'}, 400);
    }, []);

    c.open(_auction);
    final result = await c.placeBid(_auction);

    expect(result.status, BidStatus.failed);
    expect(result.message, 'Auction has already ended');
  });

  test('paid plans report unlimited bids', () {
    final plan = PlanStatus.fromJson({
      'plan': {'name': 'Silver Package', 'billingPeriod': 'year', 'bidLimit': null, 'itemLimit': 200},
      'bidCount': 300,
    });
    expect(plan.bidsLeft, isNull);
    expect(plan.trialEnded, isFalse);
  });
}
