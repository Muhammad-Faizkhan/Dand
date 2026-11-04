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
import 'package:dandcollection/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dandcollection/views/main/home_screen.dart';
import 'package:dandcollection/views/main/marketplace_screen.dart';
import 'package:dandcollection/widgets/app_background.dart';
import 'package:provider/provider.dart';

/// Renders every route at the Figma frame size and writes a PNG per screen so
/// the implementation can be diffed against the design export.
///
/// Run `flutter test --update-goldens` to refresh `test/goldens/`.
/// The `/main` shell is covered by the `tab_home` / `tab_market` cases instead:
/// its map tab needs `path_provider`, which has no implementation in tests.
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
    // Material icon glyphs so the goldens show real icons, not tofu boxes.
    final iconFont = _materialIconFont();
    if (iconFont != null) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(iconFont.readAsBytes().then((b) => ByteData.view(b.buffer)));
      await icons.load();
    }
  });

  final routes = <String, Object?>{
    'splash': AppRoutes.splash,
    'onboarding': AppRoutes.onboarding,
    'login': AppRoutes.login,
    'create_account': AppRoutes.createAccount,
    'verify_email': AppRoutes.verifyEmail,
    'enter_code': AppRoutes.enterCode,
    'forgot_password': AppRoutes.forgotPassword,
    'create_new_password': AppRoutes.createNewPassword,
    'congratulations': AppRoutes.congratulations,
    'choose_plan': AppRoutes.choosePlan,
    'plan_payment': AppRoutes.planPayment,
    'subscribed': AppRoutes.subscribed,
    'what_you_collect': AppRoutes.whatYouCollect,
    'profile_completed': AppRoutes.profileCompleted,
    'filters': AppRoutes.filters,
    'wishlist': AppRoutes.wishlist,
    'search': AppRoutes.search,
    'notifications': AppRoutes.notifications,
    'trade_matches': AppRoutes.tradeMatches,
    'propose_trade': AppRoutes.proposeTrade,
    'add_to_trade': AppRoutes.addToTrade,
    'review_confirm': AppRoutes.reviewConfirm,
    'trade_sent': AppRoutes.tradeSent,
    'trade_confirmed': AppRoutes.tradeConfirmed,
    'trade_rejected': AppRoutes.tradeRejected,
    'item_detail': AppRoutes.itemDetail,
    'shipping': AppRoutes.shipping,
    'checkout': AppRoutes.checkout,
    'order_placed': AppRoutes.orderPlaced,
    'track_order': AppRoutes.trackOrder,
    'auction_detail': AppRoutes.auctionDetail,
    'place_bid': AppRoutes.placeBid,
    'bid_placed': AppRoutes.bidPlaced,
    'auction_winner': AppRoutes.auctionWinner,
    'messages': AppRoutes.messages,
    'chat': AppRoutes.chat,
    'my_profile': AppRoutes.myProfile,
    'edit_profile': AppRoutes.editProfile,
    'seller_profile': AppRoutes.sellerProfile,
    'collections': AppRoutes.collections,
    'event_detail': AppRoutes.eventDetail,
    'my_activity': AppRoutes.myActivity,
    'add_item': AppRoutes.addItem,
    'item_form': AppRoutes.itemForm,
    'create_category': AppRoutes.createCategory,
    'add_to_collection': AppRoutes.addToCollection,
    'settings': AppRoutes.settings,
    'push_notifications': AppRoutes.pushNotifications,
    'trade_preferences': AppRoutes.tradePreferences,
    'change_password': AppRoutes.changePassword,
    'privacy_policy': AppRoutes.privacyPolicy,
    'help_feedback': AppRoutes.helpFeedback,
    'thank_you_password': AppRoutes.thankYouPassword,
    'payment_methods': AppRoutes.paymentMethods,
    'add_card': AppRoutes.addCard,
    'manage_card': AppRoutes.manageCard,
    'order_requests': AppRoutes.orderRequests,
    'confirm_request': AppRoutes.confirmRequest,
    'request_sent': AppRoutes.requestSent,
    'order_rejected': AppRoutes.orderRejected,
    'orders_purchase': AppRoutes.ordersPurchase,
    'orders_trade': AppRoutes.ordersTrade,
    'trade_completed': AppRoutes.tradeCompleted,
    'auction_lost': AppRoutes.auctionLost,
    'edit_collect': AppRoutes.editCollect,
  };

  final widgets = <String, Widget>{
    'tab_home': AppScaffold(
      body: HomeScreen(onMenu: () {}, onTab: (_) {}),
    ),
    'tab_market': AppScaffold(
      body: MarketplaceScreen(onMenu: () {}, onTab: (_) {}),
    ),
  };

  widgets.forEach((name, widget) {
    testWidgets('render $name', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthController()),
            ChangeNotifierProvider(create: (_) => NavController()),
            ChangeNotifierProvider(create: (_) => UserController()),
            ChangeNotifierProvider(create: (_) => MarketplaceController()),
            ChangeNotifierProvider(create: (_) => WishlistController()),
          ],
          // The production wrapper, so these goldens guard the real
          // design-size selection. Every case here renders at 390x844, where
          // it resolves to the same Size(390, 844) this used to hard-code.
          child: ResponsiveScreenUtil(
            builder: (context, child) =>
                MaterialApp(debugShowCheckedModeBanner: false, theme: AppTheme.dark, home: widget),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage((element.widget as Image).image, element);
        }
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pump(const Duration(milliseconds: 50));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    });
  });

  routes.forEach((name, route) {
    testWidgets('render $name', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
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
          // The production wrapper, so these goldens guard the real
          // design-size selection. Every case here renders at 390x844, where
          // it resolves to the same Size(390, 844) this used to hard-code.
          child: ResponsiveScreenUtil(
            builder: (context, child) => MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              initialRoute: route as String,
              onGenerateRoute: RouteGenerator.generate,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      // Let asset images decode.
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          final image = element.widget as Image;
          await precacheImage(image.image, element);
        }
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pump(const Duration(milliseconds: 50));

      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    });
  });
}

/// Locates the engine's bundled Material icon font, whatever Flutter version
/// is installed. The path used to be hard-coded at 3.32.0, which silently
/// started rendering tofu once the toolchain moved on.
File? _materialIconFont() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final roots = <String>[
    ?flutterRoot,
    '/opt/homebrew/Caskroom/flutter',
    '/usr/local/Caskroom/flutter',
  ];
  for (final root in roots) {
    final direct = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (direct.existsSync()) return direct;
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entry in dir.listSync()) {
      final nested = File(
        '${entry.path}/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (nested.existsSync()) return nested;
    }
  }
  return null;
}
