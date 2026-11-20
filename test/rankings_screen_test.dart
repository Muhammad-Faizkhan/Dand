import 'dart:io';

import 'package:dandcollection/controllers/rewards_controller.dart';
import 'package:dandcollection/controllers/user_controller.dart';
import 'package:dandcollection/core/routes/app_routes.dart';
import 'package:dandcollection/core/routes/route_generator.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:dandcollection/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Rankings (User / Dealership tabs) and Transaction History, laid out as in the
/// Figma "Rankings" and "Transaction History" frames.
void main() {
  setUpAll(() async {
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final loader = FontLoader('Inter')
        ..addFont(File('assets/fonts/Inter-$w.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
      await loader.load();
    }
    final root = Platform.environment['FLUTTER_ROOT'];
    final icons = root == null ? null : File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons != null && icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(icons.readAsBytes().then((b) => ByteData.view(b.buffer)))).load();
    }
  });

  /// Decode the background art before a golden, so it never captures a half-loaded screen.
  Future<void> settleImages(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
      await Future<void>.delayed(const Duration(milliseconds: 60));
    });
    await tester.pump(const Duration(milliseconds: 50));
  }

  RewardsController seeded() {
    final now = DateTime.now();
    return RewardsController()
      ..leaders = const [
        RankedUser(rank: 1, id: 11, name: 'Marcus Vance', chips: 1294, place: 'Sturgis, SD'),
        RankedUser(rank: 2, id: 12, name: 'Rider Mike', chips: 842, place: 'Sturgis, SD'),
        RankedUser(rank: 3, id: 13, name: 'Iron Road King', chips: 789, place: 'Sturgis, SD'),
        RankedUser(rank: 4, id: 14, name: 'Rider John', chips: 654, place: 'Sturgis, SD'),
        RankedUser(rank: 5, id: 15, name: 'Dusty Miles', chips: 610, place: 'Rapid City, SD'),
        RankedUser(rank: 6, id: 16, name: 'Chrome Kate', chips: 588, place: 'Deadwood, SD'),
      ]
      ..dealerRanking = const [
        RankedDealer(rank: 1, id: 1, name: 'Abc Dealer Shop', address: 'Sturgis, SD', checkIns: 70),
        RankedDealer(rank: 2, id: 2, name: 'Vintage Collector', address: 'Sturgis, SD', checkIns: 60),
        RankedDealer(rank: 3, id: 3, name: 'Black Hills HD', address: 'Rapid City, SD', checkIns: 55),
        RankedDealer(rank: 4, id: 4, name: 'HD Collector', address: 'Sturgis, SD', checkIns: 50),
        RankedDealer(rank: 5, id: 5, name: 'Badlands HD', address: 'Wall, SD', checkIns: 44),
      ]
      ..transactions = [
        PointsTxn(points: 500, reason: 'CHECK_IN_FIRST', note: 'Black Hills HD', createdAt: now.subtract(const Duration(days: 1))),
        PointsTxn(points: -350, reason: 'CHIP_PURCHASE', note: 'Bristol Wide', createdAt: now.subtract(const Duration(days: 2))),
        PointsTxn(points: 100, reason: 'CHECK_IN_REPEAT', note: 'Abc Dealer Shop', createdAt: now.subtract(const Duration(days: 5))),
        PointsTxn(points: 900, reason: 'CHECK_IN_FIRST', note: 'Too old', createdAt: now.subtract(const Duration(days: 45))),
      ];
  }

  Future<void> open(WidgetTester tester, String route, RewardsController rewards) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: rewards),
          ChangeNotifierProvider(create: (_) => UserController()),
        ],
        child: ResponsiveScreenUtil(
          builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            initialRoute: route,
            onGenerateRoute: RouteGenerator.generate,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await settleImages(tester);
  }

  testWidgets('Rankings opens on User Ranking and switches to Dealership Ranking', (tester) async {
    await open(tester, AppRoutes.leaderboard, seeded());

    expect(find.text('Rankings'), findsOneWidget);
    expect(find.text('Ranked purely by verified owned biker chips'), findsOneWidget);
    expect(find.text('1,294'), findsOneWidget, reason: 'podium numbers use thousands separators');
    expect(find.text('Rider John'), findsOneWidget);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/rankings_users.png'));

    await tester.tap(find.text('Dealership Ranking'));
    await tester.pumpAndSettle();
    await settleImages(tester);

    expect(find.text('Abc Dealer Shop'), findsOneWidget);
    expect(find.text('#2 RANK'), findsOneWidget);
    expect(find.text('#3 RANK'), findsOneWidget);
    expect(find.text('Rider John'), findsNothing);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/rankings_dealers.png'));
  });

  testWidgets('Transaction History lists the last 30 days in dollars', (tester) async {
    await open(tester, AppRoutes.walletHistory, seeded());

    expect(find.text('LAST 30 DAYS TRANSACTIONS'), findsOneWidget);
    expect(find.text('+\$50.00'), findsOneWidget);
    expect(find.text('-\$35.00'), findsOneWidget);
    expect(find.textContaining('Too old'), findsNothing, reason: 'older than 30 days');
    expect(find.textContaining('pts'), findsNothing);
    // No golden here: the rows show real dates relative to today, so the image changes daily.
  });
}
