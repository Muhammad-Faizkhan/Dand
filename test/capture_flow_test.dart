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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';

/// Stands in for the real camera/gallery so the tests can drive the outcomes a
/// device produces: a picked file, a cancel, or a platform failure.
class _FakePicker extends ImagePickerPlatform {
  _FakePicker({this.path, this.error});

  final String? path;
  final PlatformException? error;
  final calls = <ImageSource>[];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    calls.add(source);
    if (error != null) throw error!;
    return path == null ? null : XFile(path!);
  }
}

Widget _app(String initialRoute) => MultiProvider(
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
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          initialRoute: initialRoute,
          onGenerateRoute: RouteGenerator.generate,
        ),
      ),
    );

/// These screens are laid out against the 390x844 design frame, so they need
/// the frame to hit-test where the design puts things.
Future<void> _pumpAt(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(route));
  await tester.pumpAndSettle();
}

void main() {
  // Without the real font the test renders in Ahem, whose square glyphs are far
  // wider than Inter's — rows overflow and taps land off their targets.
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

  late ImagePickerPlatform original;

  setUp(() => original = ImagePickerPlatform.instance);
  tearDown(() => ImagePickerPlatform.instance = original);

  group('Add Item — camera', () {
    testWidgets('Take Photo opens the camera and carries the shot into the form',
        (tester) async {
      final picker = _FakePicker(path: '/tmp/chip.jpg');
      ImagePickerPlatform.instance = picker;

      await _pumpAt(tester, AppRoutes.addItem);

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(picker.calls, [ImageSource.camera], reason: 'must ask for the camera, not the gallery');
      expect(find.text('Add Item'), findsNothing, reason: 'should have moved on to the item form');
    });

    testWidgets('the scan frame is a shutter too', (tester) async {
      final picker = _FakePicker(path: '/tmp/chip.jpg');
      ImagePickerPlatform.instance = picker;

      await _pumpAt(tester, AppRoutes.addItem);

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      await tester.pumpAndSettle();

      expect(picker.calls, [ImageSource.camera]);
    });

    testWidgets('Upload asks for the gallery', (tester) async {
      final picker = _FakePicker(path: '/tmp/chip.jpg');
      ImagePickerPlatform.instance = picker;

      await _pumpAt(tester, AppRoutes.addItem);

      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();

      expect(picker.calls, [ImageSource.gallery]);
    });

    testWidgets('cancelling the camera leaves the user on Add Item, silently', (tester) async {
      ImagePickerPlatform.instance = _FakePicker();

      await _pumpAt(tester, AppRoutes.addItem);

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    // Every one of these used to throw straight past the button, so the tap
    // looked like it did nothing at all.
    testWidgets('a denied camera permission is explained, not swallowed', (tester) async {
      ImagePickerPlatform.instance = _FakePicker(
        error: PlatformException(code: 'camera_access_denied'),
      );

      await _pumpAt(tester, AppRoutes.addItem);

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Camera access is off'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget, reason: 'no photo, so no navigation');
    });

    testWidgets('no camera on the device offers the gallery instead', (tester) async {
      ImagePickerPlatform.instance = _FakePicker(
        error: PlatformException(code: 'no_available_camera'),
      );

      await _pumpAt(tester, AppRoutes.addItem);

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No camera is available'), findsOneWidget);

      // Taking the offer runs the picker again, against the gallery.
      final gallery = _FakePicker(path: '/tmp/chip.jpg');
      ImagePickerPlatform.instance = gallery;
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

      expect(gallery.calls, [ImageSource.gallery]);
    });

    testWidgets('a double tap while the picker is up says nothing', (tester) async {
      ImagePickerPlatform.instance = _FakePicker(
        error: PlatformException(code: 'already_active'),
      );

      await _pumpAt(tester, AppRoutes.addItem);

      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('Onboarding', () {
    // The Skip button used to be declared before the full-bleed PageView in the
    // same Stack, so the PageView was hit-tested first and ate every tap.
    testWidgets('Skip leaves onboarding for login', (tester) async {
      await _pumpAt(tester, AppRoutes.onboarding);

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsNothing, reason: 'onboarding should be gone');
      expect(find.text('Catalog every chip'), findsNothing);
    });

    testWidgets('Skip works from the last page too', (tester) async {
      await _pumpAt(tester, AppRoutes.onboarding);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsNothing);
    });

    testWidgets('the pager still swipes with Skip on top of it', (tester) async {
      await _pumpAt(tester, AppRoutes.onboarding);

      expect(find.text('Catalog every chip'), findsOneWidget);
      await tester.drag(find.text('Catalog every chip'), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Trade with collectors'), findsOneWidget);
    });
  });
}
