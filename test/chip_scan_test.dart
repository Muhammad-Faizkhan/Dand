import 'dart:convert';
import 'dart:io';

import 'package:dandcollection/controllers/app_controller.dart';
import 'package:dandcollection/core/api/api_client.dart';
import 'package:dandcollection/core/api/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _url = 'https://api.test/uploads/0123456789abcdef0123456789abcdef.jpg';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

final _suggestion = {
  'isChip': true,
  'title': 'Harley-Davidson of Bristol \$5 Chip',
  'dealership': 'Harley-Davidson of Bristol',
  'city': 'Bristol',
  'state': 'CT',
  'year': 2004,
  'denomination': '\$5',
  'colors': ['blue', 'white'],
  'condition': 'Excellent',
  'description': 'Blue and white Bristol dealership chip.',
  'confidence': 'high',
  'unreadable': null,
};

File _photo() {
  final f = File('${Directory.systemTemp.path}/dandc_scan_test.jpg');
  f.writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xD9]);
  return f;
}

SellController _sell(Future<http.Response> Function(http.Request) items, List<http.BaseRequest> seen) {
  final client = ApiClient(
    tokens: MemoryTokenStore(),
    baseUrl: 'https://api.test',
    httpClient: MockClient((req) async {
      seen.add(req);
      if (req.url.path == '/api/uploads') return _json({'urls': [_url]}, 201);
      if (req.url.path == '/api/items/scan') return _json({'imageUrl': _url, 'suggestion': _suggestion});
      return items(req);
    }),
  );
  return SellController(client: client);
}

void main() {
  test('the scan fills the form, and nothing is saved until the user confirms', () async {
    final seen = <http.BaseRequest>[];
    final sell = _sell((req) async => _json({'id': 7}, 201), seen);

    await sell.scanPhoto(_photo().path);

    expect(sell.titleCtrl.text, 'Harley-Davidson of Bristol \$5 Chip');
    expect(sell.dealerCtrl.text, 'Harley-Davidson of Bristol');
    expect(sell.yearCtrl.text, '2004');
    expect(sell.condition, 'Near Mint');
    expect(sell.scan!.summary, 'Bristol CT · \$5');
    expect(seen.where((r) => r.url.path == '/api/items'), isEmpty, reason: 'scanning must not create the item');

    sell.titleCtrl.text = 'Bristol \$5 (corrected)';
    final result = await sell.save();

    expect(result.status, SaveStatus.saved);
    final create = seen.whereType<http.Request>().singleWhere((r) => r.url.path == '/api/items');
    final body = jsonDecode(create.body) as Map<String, dynamic>;
    expect(body['title'], 'Bristol \$5 (corrected)', reason: "the user's edit wins over the scan");
    expect(body['brand'], 'Harley-Davidson of Bristol');
    expect(body['year'], 2004);
    expect(body['imageUrls'], [_url]);
    expect(body['status'], 'FOR_TRADE');
  });

  test('hitting the chip limit asks for an upgrade', () async {
    final sell = _sell(
      (req) async => _json({
        'error': 'Upload limit reached for the Free Trial plan (100 items). Upgrade to raise your limit.',
        'details': {'code': 'UPGRADE_REQUIRED', 'reason': 'item_limit'},
      }, 403),
      [],
    );
    await sell.scanPhoto(_photo().path);

    final result = await sell.save();

    expect(result.status, SaveStatus.upgradeRequired);
    expect(result.message, contains('Upload limit'));
  });

  test('a failed scan leaves an empty form for the user to fill in', () async {
    final client = ApiClient(
      tokens: MemoryTokenStore(),
      baseUrl: 'https://api.test',
      httpClient: MockClient((req) async {
        if (req.url.path == '/api/uploads') return _json({'urls': [_url]}, 201);
        return _json({'error': "Couldn't read the chip from that photo. Enter the details by hand."}, 422);
      }),
    );
    final sell = SellController(client: client);

    await sell.scanPhoto(_photo().path);

    expect(sell.scan, isNull);
    expect(sell.scanError, contains("Couldn't read the chip"));
    expect(sell.titleCtrl.text, isEmpty);
    expect(sell.canSave, isFalse, reason: 'needs a title before saving');
  });
}
