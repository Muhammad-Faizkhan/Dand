import 'dart:io';

import 'package:dandcollection/controllers/app_controller.dart';
import 'package:dandcollection/controllers/collections_controller.dart';
import 'package:dandcollection/controllers/notifications_controller.dart';
import 'package:dandcollection/controllers/rewards_controller.dart';
import 'package:dandcollection/controllers/user_controller.dart';
import 'package:dandcollection/controllers/auth_controller.dart';
import 'package:dandcollection/core/routes/app_routes.dart';
import 'package:dandcollection/core/routes/route_generator.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:dandcollection/core/utils/responsive.dart';
import 'package:dandcollection/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Every viewport the app is expected to survive.
const viewports = <String, Size>{
  'phone portrait': Size(390, 844),
  'phone small': Size(375, 667),
  'phone large': Size(430, 932),
  'phone landscape': Size(844, 390),
  'tablet 7in portrait': Size(744, 1133),
  'tablet 10in portrait': Size(820, 1180),
  'tablet 10in landscape': Size(1180, 820),
  'tablet 13in portrait': Size(1024, 1366),
  'tablet 13in landscape': Size(1366, 1024),
};

/// Routes that render without a platform channel. The map needs
/// `path_provider`, which has no implementation under `flutter test`.
final routes = <String>[
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.createAccount,
  AppRoutes.verifyEmail,
  AppRoutes.enterCode,
  AppRoutes.forgotPassword,
  AppRoutes.createNewPassword,
  AppRoutes.congratulations,
  AppRoutes.choosePlan,
  AppRoutes.planPayment,
  AppRoutes.subscribed,
  AppRoutes.whatYouCollect,
  AppRoutes.profileCompleted,
  AppRoutes.filters,
  AppRoutes.wishlist,
  AppRoutes.search,
  AppRoutes.notifications,
  AppRoutes.tradeMatches,
  AppRoutes.proposeTrade,
  AppRoutes.addToTrade,
  AppRoutes.reviewConfirm,
  AppRoutes.tradeSent,
  AppRoutes.tradeConfirmed,
  AppRoutes.tradeRejected,
  AppRoutes.itemDetail,
  AppRoutes.shipping,
  AppRoutes.checkout,
  AppRoutes.orderPlaced,
  AppRoutes.trackOrder,
  AppRoutes.auctionDetail,
  AppRoutes.placeBid,
  AppRoutes.bidPlaced,
  AppRoutes.auctionWinner,
  AppRoutes.messages,
  AppRoutes.chat,
  AppRoutes.myProfile,
  AppRoutes.editProfile,
  AppRoutes.sellerProfile,
  AppRoutes.collections,
  AppRoutes.eventDetail,
  AppRoutes.myActivity,
  AppRoutes.addItem,
  AppRoutes.itemForm,
  AppRoutes.createCategory,
  AppRoutes.addToCollection,
  AppRoutes.settings,
  AppRoutes.pushNotifications,
  AppRoutes.tradePreferences,
  AppRoutes.changePassword,
  AppRoutes.privacyPolicy,
  AppRoutes.helpFeedback,
  AppRoutes.thankYouPassword,
  AppRoutes.paymentMethods,
  AppRoutes.addCard,
  AppRoutes.manageCard,
  AppRoutes.orderRequests,
  AppRoutes.confirmRequest,
  AppRoutes.requestSent,
  AppRoutes.orderRejected,
  AppRoutes.ordersPurchase,
  AppRoutes.ordersTrade,
  AppRoutes.tradeCompleted,
  AppRoutes.auctionLost,
  AppRoutes.editCollect,
];

Widget _app(String route) => KeyedSubtree(
  // A fresh key per route: `pumpWidget` updates the tree in place rather than
  // rebuilding it, and `MaterialApp.initialRoute` is only read on the first
  // build — without this every iteration after the first keeps showing the
  // route before it.
  key: ValueKey(route),
  child: MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthController()),
      ChangeNotifierProvider(create: (_) => NavController()),
      ChangeNotifierProvider(create: (_) => UserController()),
      ChangeNotifierProvider(create: (_) => MarketplaceController()),
      ChangeNotifierProvider(create: (_) => WishlistController()),
      ChangeNotifierProvider(create: (_) => TradeController()),
      ChangeNotifierProvider(create: (_) => CheckoutController()),
      ChangeNotifierProvider(create: (_) => AuctionController()),
      ChangeNotifierProvider(create: (_) => ChatController()),
      ChangeNotifierProvider(create: (_) => SettingsController()),
      ChangeNotifierProvider(create: (_) => SellController()),
      ChangeNotifierProvider(create: (_) => ProfileController()),
      ChangeNotifierProvider(create: (_) => CollectionsController()),
      ChangeNotifierProvider(create: (_) => NotificationsController()),
      ChangeNotifierProvider(create: (_) => RewardsController()),
    ],
    // The real wrapper from main.dart, so the test exercises the production
    // design-size selection rather than a copy of it.
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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final loader = FontLoader('Inter')
        ..addFont(
          File('assets/fonts/Inter-$w.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)),
        );
      await loader.load();
    }
  });

  group('scale', () {
    test('the design frame renders at exactly 1:1, so phones are untouched', () {
      expect(AppResponsive.uiScale(const Size(390, 844)), 1.0);
      expect(AppResponsive.designSizeFor(const Size(390, 844)), const Size(390, 844));
    });

    test('phones keep the linear scale they have always had', () {
      for (final size in [Size(375, 667), Size(412, 915), Size(430, 932)]) {
        expect(
          AppResponsive.designSizeFor(size),
          AppResponsive.phoneDesign,
          reason: 'phone $size must keep the 390x844 frame',
        );
      }
    });

    test('a tablet is scaled far below the naive linear ratio', () {
      const ipad = Size(820, 1180);
      final linear = ipad.width / 390; // what a fixed design size would do
      final actual = AppResponsive.uiScale(ipad);
      expect(linear, greaterThan(2.0));
      expect(actual, lessThan(1.35));
      expect(actual, greaterThan(1.15));
    });

    test('scale is continuous across the tablet threshold', () {
      final below = AppResponsive.uiScale(const Size(599, 1200));
      final above = AppResponsive.uiScale(const Size(600, 1200));
      expect((above - below).abs(), lessThan(0.01));
    });

    test('scale grows with tablet size but never runs away', () {
      final mini = AppResponsive.uiScale(const Size(744, 1133));
      final big = AppResponsive.uiScale(const Size(1024, 1366));
      expect(big, greaterThan(mini));
      expect(big - mini, lessThan(0.1));
    });

    test('rotating never resizes anything — scale comes from the shortest side', () {
      expect(
        AppResponsive.uiScale(const Size(820, 1180)),
        AppResponsive.uiScale(const Size(1180, 820)),
      );
    });

    test('a tablet scales width and height equally, so artwork is not stretched', () {
      for (final size in [Size(820, 1180), Size(1180, 820), Size(1024, 1366)]) {
        final design = AppResponsive.designSizeFor(size);
        final scaleW = size.width / design.width;
        final scaleH = size.height / design.height;
        expect(scaleW, closeTo(scaleH, 0.001), reason: '$size must scale uniformly');
      }
    });
  });

  group('layout', () {
    testWidgets('content is capped and centred on a tablet, untouched on a phone', (tester) async {
      addTearDown(tester.view.reset);
      for (final entry in viewports.entries) {
        tester.view.physicalSize = entry.value * 3;
        tester.view.devicePixelRatio = 3.0;

        await tester.pumpWidget(_app(AppRoutes.login));
        await tester.pump(const Duration(milliseconds: 50));

        final screen = entry.value.width;
        final scaffold = tester.getSize(find.byType(Scaffold).first);
        final body = tester.getSize(find.byType(SingleChildScrollView).first);
        final isTablet = entry.value.shortestSide >= AppResponsive.tabletMin;

        expect(
          scaffold.width,
          closeTo(screen, 1),
          reason: 'the textured background must stay full-bleed on ${entry.key}',
        );

        if (isTablet) {
          expect(
            body.width,
            lessThan(screen),
            reason: 'content must be held to a measure on ${entry.key}',
          );
          final rect = tester.getRect(find.byType(SingleChildScrollView).first);
          expect(
            rect.left,
            closeTo(screen - rect.right, 1),
            reason: 'content must be centred on ${entry.key}',
          );
        } else {
          expect(
            body.width,
            closeTo(screen, 1),
            reason: 'a phone must be left exactly as it was on ${entry.key}',
          );
        }
      }
    });

    testWidgets('grids add columns on wider viewports', (tester) async {
      Future<int> columnsAt(Size size) async {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3.0;
        await tester.pumpWidget(_app(AppRoutes.wishlist));
        await tester.pump(const Duration(milliseconds: 50));
        final grid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
        final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        return delegate.crossAxisCount;
      }

      addTearDown(tester.view.reset);
      expect(await columnsAt(const Size(390, 844)), 2, reason: 'phone keeps the design grid');
      expect(await columnsAt(const Size(820, 1180)), greaterThan(2));
      expect(
        await columnsAt(const Size(1366, 1024)),
        greaterThanOrEqualTo(await columnsAt(const Size(820, 1180))),
      );
    });
  });

  group('every route lays out cleanly', () {
    for (final entry in viewports.entries) {
      testWidgets('on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value * 3;
        tester.view.devicePixelRatio = 3.0;
        tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
        addTearDown(tester.view.reset);

        final broken = <String>[];
        for (final route in routes) {
          await tester.pumpWidget(_app(route));
          await tester.pump(const Duration(milliseconds: 50));
          final error = tester.takeException();
          if (error != null) broken.add('$route: $error');
        }
        expect(broken, isEmpty, reason: broken.join('\n'));
      });
    }
  });
}
