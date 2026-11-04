import 'dart:io';

import 'package:dandcollection/controllers/app_controller.dart';
import 'package:dandcollection/controllers/user_controller.dart';
import 'package:dandcollection/controllers/auth_controller.dart';
import 'package:dandcollection/core/routes/app_routes.dart';
import 'package:dandcollection/core/routes/route_generator.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// Catches what the share button hands to the platform.
class _FakeShare extends SharePlatform {
  ShareParams? received;

  @override
  Future<ShareResult> share(ShareParams params) async {
    received = params;
    return const ShareResult('fake', ShareResultStatus.success);
  }
}

final _share = _FakeShare();

/// A real 1x1 PNG on disk, so FileImage has something to decode.
File _tempAvatar() {
  final f = File('${Directory.systemTemp.path}/dandc_avatar_test.png');
  f.writeAsBytesSync(const <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
    0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB0, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
    0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);
  return f;
}

late ProfileController profile;

Widget _app(String route) {
  profile = ProfileController();
  return MultiProvider(
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
      ChangeNotifierProvider<ProfileController>.value(value: profile),
    ],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: route,
        onGenerateRoute: RouteGenerator.generate,
      ),
    ),
  );
}

Future<void> _pumpAt(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(route));
  await tester.pumpAndSettle();
}

Finder get _avatarImage => find.byWidgetPredicate(
      (w) => w is Image && (w.image is FileImage || w.image is AssetImage),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // SharePlus.instance latches the platform on first use, so swap it in
    // before any test taps the button.
    SharePlatform.instance = _share;
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final loader = FontLoader('Inter')
        ..addFont(
          File('assets/fonts/Inter-$w.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)),
        );
      await loader.load();
    }
  });

  group('My Profile', () {
    // The avatar is changed on Edit Profile; offering it here as well was a
    // second, unwired way in.
    testWidgets('the avatar carries no camera badge', (tester) async {
      await _pumpAt(tester, AppRoutes.myProfile);

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera), findsNothing);
    });

    // The share button had no onTap at all, so it was pure decoration.
    testWidgets('the share button actually shares', (tester) async {
      await _pumpAt(tester, AppRoutes.myProfile);
      _share.received = null;

      await tester.tap(find.byIcon(Icons.ios_share_rounded));
      await tester.pumpAndSettle();

      expect(_share.received, isNotNull, reason: 'the button used to have no onTap at all');
      expect(_share.received!.text, contains('Rider Mike'));
      expect(_share.received!.text, contains('dandcollection.app'));
      // iPad anchors the popover on this; without it the sheet throws there.
      expect(_share.received!.sharePositionOrigin, isNotNull);
    });

    testWidgets('Edit Profile is still the way in to the photo', (tester) async {
      await _pumpAt(tester, AppRoutes.myProfile);

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
    });
  });

  group('Avatar', () {
    testWidgets('a new photo reaches My Profile without a reload', (tester) async {
      await _pumpAt(tester, AppRoutes.myProfile);
      expect(tester.widget<Image>(_avatarImage.first).image, isA<AssetImage>());

      profile.setAvatar(_tempAvatar().path);
      await tester.pumpAndSettle();

      expect(tester.widget<Image>(_avatarImage.first).image, isA<FileImage>(),
          reason: 'the profile screen should follow the controller');
    });

    testWidgets('and reaches the side menu too', (tester) async {
      await _pumpAt(tester, AppRoutes.main);
      profile.setAvatar(_tempAvatar().path);
      await tester.pumpAndSettle();

      expect(profile.hasCustomAvatar, isTrue);
      expect(profile.avatar, isA<FileImage>());
    });

    testWidgets('"Remove photo" puts the seeded asset back', (tester) async {
      await _pumpAt(tester, AppRoutes.myProfile);

      profile.setAvatar(_tempAvatar().path);
      await tester.pumpAndSettle();
      expect(tester.widget<Image>(_avatarImage.first).image, isA<FileImage>());

      profile.setAvatar('');   // what the sheet returns for "Remove photo"
      await tester.pumpAndSettle();

      expect(tester.widget<Image>(_avatarImage.first).image, isA<AssetImage>());
      expect(profile.hasCustomAvatar, isFalse);
    });
  });
}
