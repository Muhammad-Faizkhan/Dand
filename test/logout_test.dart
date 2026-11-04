import 'dart:io';

import 'package:dandcollection/controllers/app_controller.dart';
import 'package:dandcollection/controllers/collections_controller.dart';
import 'package:dandcollection/controllers/notifications_controller.dart';
import 'package:dandcollection/controllers/rewards_controller.dart';
import 'package:dandcollection/controllers/user_controller.dart';
import 'package:dandcollection/controllers/auth_controller.dart';
import 'package:dandcollection/core/routes/route_generator.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:dandcollection/widgets/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

late AuthController auth;
final _drawerKey = GlobalKey<ScaffoldState>();

Widget _app() {
  auth = AuthController()..login();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>.value(value: auth),
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
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        onGenerateRoute: RouteGenerator.generate,
        home: Scaffold(key: _drawerKey, drawer: const SideMenu(), body: const SizedBox()),
      ),
    ),
  );
}

Future<void> _openDrawer(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  _drawerKey.currentState!.openDrawer();
  await tester.pumpAndSettle();
}

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

  group('Log Out from the drawer', () {
    // It used to drop the session on the first tap, with no way back.
    testWidgets('asks before doing anything', (tester) async {
      await _openDrawer(tester);

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(find.text('Stay signed in'), findsOneWidget);
      expect(auth.loggedIn, isTrue, reason: 'nothing should happen until it is confirmed');
    });

    testWidgets('"Stay signed in" leaves the session alone', (tester) async {
      await _openDrawer(tester);
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsNothing);
      expect(auth.loggedIn, isTrue);
      expect(find.byType(SideMenu), findsOneWidget, reason: 'still in the drawer');
    });

    testWidgets('dismissing the dialog also counts as staying', (tester) async {
      await _openDrawer(tester);
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.text('Log out?'))).pop();
      await tester.pumpAndSettle();

      expect(auth.loggedIn, isTrue);
    });

    testWidgets('confirming logs out and lands on Login', (tester) async {
      await _openDrawer(tester);
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // The dialog's own button, not the drawer's row behind it.
      await tester.tap(find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Log Out'),
      ));
      await tester.pumpAndSettle();

      expect(auth.loggedIn, isFalse);
      expect(find.byType(SideMenu), findsNothing, reason: 'the stack should be cleared');
      expect(find.text('Log out?'), findsNothing);
    });
  });
}
