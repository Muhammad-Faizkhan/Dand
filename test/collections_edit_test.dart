import 'dart:convert';

import 'package:dandcollection/controllers/app_controller.dart';
import 'package:dandcollection/controllers/collections_controller.dart';
import 'package:dandcollection/controllers/user_controller.dart';
import 'package:dandcollection/core/api/api_client.dart';
import 'package:dandcollection/core/api/token_store.dart';
import 'package:dandcollection/core/routes/app_routes.dart';
import 'package:dandcollection/core/routes/route_generator.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:dandcollection/main.dart';
import 'package:dandcollection/models/models.dart';
import 'package:dandcollection/views/item/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

const _me = 7;

final _collections = [
  {'id': 1, 'name': 'Dealer Chips', 'kind': 'dealer-chips', '_count': {'items': 3}},
  {'id': 2, 'name': 'Dealer Plates', 'kind': 'dealer-plates', '_count': {'items': 0}},
  {'id': 9, 'name': 'Sturgis 2024', 'kind': null, '_count': {'items': 1}},
  {
    'id': 20,
    'name': 'Merchandise',
    'kind': 'merchandise',
    '_count': {'items': 2},
    'children': [
      {'id': 21, 'name': 'Shirts', 'kind': 'shirts', 'parentId': 20, '_count': {'items': 2}},
      {'id': 22, 'name': 'Hats', 'kind': 'hats', 'parentId': 20, '_count': {'items': 0}},
      {'id': 23, 'name': 'Cups', 'kind': 'cups', 'parentId': 20, '_count': {'items': 0}},
    ],
  },
  {'id': 30, 'name': 'Bike Night', 'kind': null, 'isPrivate': true, '_count': {'items': 0}},
];

/// A fake API that records every request and answers the calls these screens make.
class _Server {
  final requests = <http.Request>[];
  var plates = <Map<String, Object?>>[];

  ApiClient client() => ApiClient(
    tokens: MemoryTokenStore(),
    baseUrl: 'https://api.test',
    httpClient: MockClient((req) async {
      requests.add(req);
      final path = req.url.path;
      if (path == '/api/users/me') return _json({'id': _me, 'email': 'a@b.c', 'username': 'tom'});
      if (path == '/api/collections' && req.method == 'GET') return _json(_collections);
      if (path == '/api/collections/2') return _json({..._collections[1], 'items': plates});
      if (path == '/api/collections/9' && req.method == 'GET') return _json({..._collections[2], 'items': []});
      if (path == '/api/collections/9' && req.method == 'DELETE') return http.Response('', 204);
      if (path == '/api/collections/20') return _json({..._collections[3], 'items': []});
      if (path == '/api/collections/21') {
        final shirts = (_collections[3]['children'] as List)[0] as Map<String, Object?>;
        return _json({...shirts, 'items': [], 'children': [], 'parent': {'id': 20, 'name': 'Merchandise'}});
      }
      if (path == '/api/items/55' && req.method == 'DELETE') return http.Response('', 204);
      if (path == '/api/collections/30' && req.method == 'GET') return _json({..._collections[4], 'items': []});
      if (path == '/api/collections/30' && req.method == 'PATCH') {
        return _json({..._collections[4], ...(jsonDecode(req.body) as Map<String, dynamic>)});
      }
      return _json({'error': 'not found'}, 404);
    }),
  );

  Iterable<String> get calls => requests.map((r) => '${r.method} ${r.url.path}');
}

Future<(CollectionsController, UserController)> _pump(
  WidgetTester tester,
  _Server server, {
  required String route,
  Object? arguments,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final client = server.client();
  final collections = CollectionsController(client: client);
  final user = UserController(client: client);
  await user.load();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: collections),
        ChangeNotifierProvider.value(value: user),
        ChangeNotifierProvider(create: (_) => NavController()),
        ChangeNotifierProvider(create: (_) => SellController(client: client)),
        ChangeNotifierProvider(create: (_) => WishlistController()),
        ChangeNotifierProvider(create: (_) => TradeController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
      ],
      child: ResponsiveScreenUtil(
        builder: (context, child) => MaterialApp(
          theme: AppTheme.dark,
          onGenerateRoute: RouteGenerator.generate,
          // A route below the screen under test, so popping it has somewhere to go.
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('open'),
                  onPressed: () => Navigator.pushNamed(context, route, arguments: arguments),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await tester.pumpAndSettle();
  return (collections, user);
}

ApiCollection _col(int i) => ApiCollection.fromJson(_collections[i]);

void main() {
  test('empty text names the collection', () {
    expect(_col(1).isDefault, isTrue);
    expect(_col(1).emptyText, 'No dealer plates in this collection yet. Tap + to add one.');
    expect(_col(2).isDefault, isFalse);
    expect(_col(2).emptyText, 'Nothing in Sturgis 2024 yet. Tap + to add a chip.');
  });

  testWidgets('collections are split into Primary and My collections, two across on a phone', (tester) async {
    await _pump(tester, _Server(), route: AppRoutes.collections);

    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('My collections'), findsOneWidget);
    expect(find.text('Dealer Chips · 3'), findsOneWidget);
    expect(find.text('Sturgis 2024 · 1'), findsOneWidget);
    final first = tester.getTopLeft(find.byKey(const Key('collection-1')));
    final second = tester.getTopLeft(find.byKey(const Key('collection-2')));
    expect(second.dy, first.dy, reason: 'side by side');
    expect(tester.getSize(find.byKey(const Key('collection-1'))).width, greaterThan(140));
  });

  testWidgets('a wide landscape screen shows 5 or 6 collections across', (tester) async {
    // 13-inch tablet, landscape.
    await _pump(tester, _Server(), route: AppRoutes.collections, size: const Size(1366, 1024));
    final width = tester.getSize(find.byKey(const Key('collection-1'))).width;
    final columns = (1366 / width).floor();
    expect(columns, inInclusiveRange(5, 6));
  });

  testWidgets('a default collection has no edit / delete and names itself when empty', (tester) async {
    await _pump(tester, _Server(), route: AppRoutes.eventDetail, arguments: _col(1));

    expect(find.byKey(const Key('collection-more')), findsNothing);
    expect(find.text('No dealer plates in this collection yet. Tap + to add one.'), findsOneWidget);
  });

  testWidgets('Merchandise opens to its Shirts, Hats and Cups folders and takes no chips itself', (tester) async {
    expect(_col(3).hasSubfolders, isTrue);
    await _pump(tester, _Server(), route: AppRoutes.eventDetail, arguments: _col(3));

    expect(find.text('Shirts · 2'), findsOneWidget);
    expect(find.text('Hats · 0'), findsOneWidget);
    expect(find.text('Cups · 0'), findsOneWidget);
    expect(find.byKey(const Key('collection-add')), findsNothing, reason: 'chips go into a sub-folder');
    expect(find.textContaining('in this collection yet'), findsNothing);

    await tester.tap(find.byKey(const Key('collection-21')));
    await tester.pumpAndSettle();
    expect(find.text('No shirts in this collection yet. Tap + to add one.'), findsOneWidget);
    expect(find.byKey(const Key('collection-add')), findsOneWidget);
  });

  testWidgets('a private collection shows a lock in the grid', (tester) async {
    await _pump(tester, _Server(), route: AppRoutes.collections);
    expect(find.byKey(const Key('private-30')), findsOneWidget);
    expect(find.byKey(const Key('private-9')), findsNothing);
  });

  testWidgets('the edit form shows the Private switch and saves it', (tester) async {
    final server = _Server();
    expect(_col(4).isPrivate, isTrue);
    await _pump(tester, server, route: AppRoutes.eventDetail, arguments: _col(4));
    await tester.tap(find.byKey(const Key('collection-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-edit')));
    await tester.pumpAndSettle();

    final privateSwitch = find.descendant(of: find.byKey(const Key('collection-private')), matching: find.byType(AnimatedContainer));
    expect(privateSwitch, findsOneWidget);
    await tester.tap(privateSwitch);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    final patch = server.requests.lastWhere((r) => r.method == 'PATCH' && r.url.path == '/api/collections/30');
    expect(jsonDecode(patch.body)['isPrivate'], isFalse, reason: 'switched off before saving');
  });

  testWidgets('deleting your own collection asks first, then goes back', (tester) async {
    final server = _Server();
    await _pump(tester, server, route: AppRoutes.eventDetail, arguments: _col(2));
    expect(find.text('Nothing in Sturgis 2024 yet. Tap + to add a chip.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('collection-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collection-edit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('collection-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete "Sturgis 2024"?'), findsOneWidget);
    expect(server.calls, isNot(contains('DELETE /api/collections/9')), reason: 'nothing deleted before confirming');

    await tester.tap(find.byKey(const Key('collection-delete-confirm')));
    await tester.pumpAndSettle();
    expect(server.calls, contains('DELETE /api/collections/9'));
    expect(find.byKey(const Key('open')), findsOneWidget, reason: 'back on the screen it was opened from');
  });

  testWidgets('edit opens the collection form filled in', (tester) async {
    await _pump(tester, _Server(), route: AppRoutes.eventDetail, arguments: _col(2));
    await tester.tap(find.byKey(const Key('collection-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('collection-edit')));
    await tester.pumpAndSettle();

    expect(find.text('Edit Collection'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Sturgis 2024'), findsOneWidget);
  });

  ChipItem chipOwnedBy(int ownerId) => ChipItem.fromApiItem({
    'id': 55,
    'ownerId': ownerId,
    'title': 'Bristol \$5',
    'status': 'HAVE',
    'images': [],
    'owner': {'username': 'tom'},
  });

  testWidgets('your own chip can be deleted and closing returns to where you were', (tester) async {
    final server = _Server();
    await _pump(tester, server, route: AppRoutes.itemDetail, arguments: chipOwnedBy(_me));
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.text('I WANT THIS'), findsNothing);

    await tester.tap(find.byKey(const Key('item-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('item-delete-confirm')));
    await tester.pumpAndSettle();

    expect(server.calls, contains('DELETE /api/items/55'));
    expect(find.byKey(const Key('open')), findsOneWidget);
  });

  testWidgets("someone else's chip shows I have / I want, not delete", (tester) async {
    await _pump(tester, _Server(), route: AppRoutes.itemDetail, arguments: chipOwnedBy(99));
    expect(find.byKey(const Key('item-delete')), findsNothing);
    expect(find.text('I WANT THIS'), findsOneWidget);
  });
}
