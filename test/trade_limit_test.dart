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

ApiClient _client(Future<http.Response> Function(http.Request) handler, List<http.Request> seen) => ApiClient(
  tokens: MemoryTokenStore(),
  baseUrl: 'https://api.test',
  httpClient: MockClient((req) {
    seen.add(req);
    return handler(req);
  }),
);

const _theirs = ChipItem(
  id: 'item-7',
  name: 'Yankee Bristol',
  image: 'assets/images/chip_buckeye_big.jpg',
  price: 0,
  itemId: 7,
  sellerId: 3,
  owner: 'hd_collector',
);

const _mine = ChipItem(id: 'item-12', name: 'Bristol Wide', image: 'assets/images/chip_buckeye_big.jpg', price: 0, itemId: 12);

TradeController _readyToSend(ApiClient client) => TradeController(client: client)
  ..setTarget(_theirs)
  ..toggleOffer(_mine);

void main() {
  test('a sent offer is remembered for the "offer sent" screen', () async {
    final seen = <http.Request>[];
    final trade = _readyToSend(_client((_) async => _json({'id': 55}, 201), seen));

    expect(await trade.sendProposal(), isNull);

    final body = jsonDecode(seen.single.body) as Map<String, dynamic>;
    expect(body['recipientId'], 3);
    expect(body['offerItems'], [
      {'itemId': 12, 'side': 'GIVE'},
      {'itemId': 7, 'side': 'GET'},
    ]);
    expect(trade.upgradeRequired, isFalse);
    expect(trade.lastSent?.id, 55);
    expect(trade.lastSent?.otherUsername, 'hd_collector');
    expect(trade.lastSent?.otherId, 3);
  });

  test('hitting the trial trade limit asks for an upgrade', () async {
    final trade = _readyToSend(
      _client(
        (_) async => _json({
          'error': "You've used all 3 trades on the Free Trial plan. Subscribe for unlimited trading.",
          'details': {'code': 'UPGRADE_REQUIRED', 'reason': 'trade_limit', 'limit': 3, 'used': 3},
        }, 403),
        [],
      ),
    );

    final error = await trade.sendProposal();

    expect(error, contains('3 trades'));
    expect(trade.upgradeRequired, isTrue);
  });

  test('accepting over the limit asks for an upgrade; other errors do not', () async {
    var limited = true;
    final trade = TradeController(
      client: _client((req) async {
        if (req.method == 'GET') return _json(<Object>[]);
        return limited
            ? _json({'error': 'Upgrade', 'details': {'code': 'UPGRADE_REQUIRED', 'reason': 'trade_limit'}}, 403)
            : _json({'error': 'Trade request has already been responded to'}, 400);
      }, []),
    );

    expect(await trade.respondToTrade(9, accept: true, myId: 1), isFalse);
    expect(trade.upgradeRequired, isTrue);

    limited = false;
    expect(await trade.respondToTrade(9, accept: true, myId: 1), isFalse);
    expect(trade.upgradeRequired, isFalse);
    expect(trade.tradesError, 'Trade request has already been responded to');
  });

  test('preferences load from the server and each toggle saves only its own field', () async {
    final seen = <http.Request>[];
    final settings = SettingsController(
      client: _client((req) async {
        if (req.method == 'GET') {
          return _json({
            'push': {'auctionAlerts': true, 'wishlistMatches': false, 'nearbyTopTrades': false, 'weeklyDigest': true},
            'trade': {'autoAcceptFairTrades': false, 'willingToTradeFor': ['Patches']},
          });
        }
        final patch = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({
          'push': {'auctionAlerts': false, 'wishlistMatches': false, 'nearbyTopTrades': false, 'weeklyDigest': true},
          'trade': {'autoAcceptFairTrades': false, 'willingToTradeFor': ['Patches'], ...?patch['trade'] as Map<String, dynamic>?},
        });
      }, seen),
    );

    await settings.load();
    expect(settings.pushAuctions, isTrue);
    expect(settings.pushMessages, isTrue);
    expect(settings.tradeInterests, {'Patches'});

    settings.toggle('auctions');
    await pumpEventQueue();
    final patch = seen.last;
    expect(patch.method, 'PATCH');
    expect(jsonDecode(patch.body), {
      'push': {'auctionAlerts': false},
    });
    expect(settings.pushAuctions, isFalse);

    settings.toggleInterest('Coins');
    await pumpEventQueue();
    expect(jsonDecode(seen.last.body), {
      'trade': {
        'willingToTradeFor': ['Patches', 'Coins'],
      },
    });
  });
}
