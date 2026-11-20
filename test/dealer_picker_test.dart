import 'package:dandcollection/core/api/api_client.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:dandcollection/main.dart';
import 'package:dandcollection/models/models.dart';
import 'package:dandcollection/widgets/dealer_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _kenai = Dealer(id: 4, name: 'Kenai Peninsula Harley-Davidson Shop', address: '41605 Sterling Hwy, Soldotna, AK', lat: 60.5, lng: -151.1);
const _taku = Dealer(id: 5, name: 'Taku Harley-Davidson Shop', address: '263 Marine Way, Juneau, AK', lat: 58.3, lng: -134.4);
const _insidePassage = Dealer(id: 6, name: 'Inside Passage Harley-Davidson', address: 'Juneau, AK', lat: 58.3, lng: -134.4, closed: true);

void main() {
  late List<String> queries;
  late Object? Function(String q) answer;
  DealerChoice? chosen;

  Future<List<Dealer>> search(String q) async {
    queries.add(q);
    final a = answer(q);
    if (a is ApiException) throw a;
    return a as List<Dealer>;
  }

  Future<void> open(WidgetTester tester, {Dealer? dealer, String typed = ''}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ResponsiveScreenUtil(
        builder: (context, child) => MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: DealerPickerField(dealer: dealer, typed: typed, search: search, onChanged: (c) => chosen = c),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    queries = [];
    chosen = null;
    answer = (q) => q.toLowerCase().contains('juneau') ? [_taku] : [_kenai, _taku];
  });

  test('a closed dealer reads closedAt, is labelled Closed and never offers a check-in', () {
    final closed = Dealer.fromJson({'id': 6, 'name': 'Inside Passage Harley-Davidson', 'lat': 58.3, 'lng': -134.4, 'closedAt': '2026-11-20T00:00:00Z'});
    expect(closed.closed, isTrue);
    expect(closed.displayName, 'Inside Passage Harley-Davidson (Closed)');
    expect(closed.checkInOpen, isFalse);
    final open = Dealer.fromJson({'id': 5, 'name': 'Taku', 'lat': 58.3, 'lng': -134.4, 'closedAt': null});
    expect(open.closed, isFalse);
    expect(open.displayName, 'Taku');
    expect(open.checkInOpen, isTrue);
  });

  testWidgets('closed dealers can still be picked, marked Closed', (tester) async {
    answer = (q) => [_taku, _insidePassage];
    await open(tester, typed: 'Juneau');
    await tester.tap(find.byKey(const Key('dealer-picker-field')));
    await tester.pumpAndSettle();
    expect(find.text('Inside Passage Harley-Davidson (Closed)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dealer-6')));
    await tester.pumpAndSettle();
    expect(chosen?.dealer?.id, 6);
    expect(chosen?.typed, 'Inside Passage Harley-Davidson', reason: 'the saved name has no (Closed) suffix');
  });

  testWidgets('empty field asks for a dealership', (tester) async {
    await open(tester);
    expect(find.text('Choose the dealership'), findsOneWidget);
  });

  testWidgets('a picked dealer shows its name and address', (tester) async {
    await open(tester, dealer: _kenai, typed: _kenai.name);
    expect(find.text(_kenai.name), findsOneWidget);
    expect(find.text(_kenai.address), findsOneWidget);
  });

  testWidgets('opens with the scanned name as the search and returns the tapped dealer', (tester) async {
    await open(tester, typed: 'Harley-Davidson Juneau');
    expect(find.text('Not matched to a dealer. Tap to pick one.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('dealer-picker-field')));
    await tester.pumpAndSettle();
    expect(queries, ['Harley-Davidson Juneau']);
    expect(find.byKey(const Key('dealer-5')), findsOneWidget);
    expect(find.byKey(const Key('dealer-4')), findsNothing);

    await tester.tap(find.byKey(const Key('dealer-5')));
    await tester.pumpAndSettle();
    expect(chosen?.dealer?.id, 5);
    expect(chosen?.typed, _taku.name);
  });

  testWidgets('typing searches again after a short pause', (tester) async {
    await open(tester, typed: 'juneau');
    await tester.tap(find.byKey(const Key('dealer-picker-field')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('dealer-search')), 'kenai');
    await tester.pump(const Duration(milliseconds: 100));
    expect(queries, ['juneau'], reason: 'no request while still typing');
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(queries, ['juneau', 'kenai']);
    expect(find.byKey(const Key('dealer-4')), findsOneWidget);
  });

  testWidgets('no match offers to keep the typed name without a dealer', (tester) async {
    answer = (_) => <Dealer>[];
    await open(tester, typed: 'Old School Ellington');
    await tester.tap(find.byKey(const Key('dealer-picker-field')));
    await tester.pumpAndSettle();

    expect(find.textContaining('No dealership matches'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dealer-not-listed')));
    await tester.pumpAndSettle();
    expect(chosen?.dealer, isNull);
    expect(chosen?.typed, 'Old School Ellington');
  });

  testWidgets('a failed search says so and still allows keeping the name', (tester) async {
    answer = (_) => ApiException(0, 'No internet connection.');
    await open(tester, typed: 'Bristol');
    await tester.tap(find.byKey(const Key('dealer-picker-field')));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't load dealers"), findsOneWidget);
    expect(find.byKey(const Key('dealer-not-listed')), findsOneWidget);
  });
}
