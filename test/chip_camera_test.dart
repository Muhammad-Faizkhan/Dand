import 'dart:async';
import 'dart:io';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:dandcollection/controllers/app_controller.dart';
import 'package:dandcollection/controllers/auth_controller.dart';
import 'package:dandcollection/controllers/collections_controller.dart';
import 'package:dandcollection/controllers/notifications_controller.dart';
import 'package:dandcollection/controllers/rewards_controller.dart';
import 'package:dandcollection/controllers/user_controller.dart';
import 'package:dandcollection/core/routes/app_routes.dart';
import 'package:dandcollection/core/routes/route_generator.dart';
import 'package:dandcollection/core/theme/app_theme.dart';
import 'package:dandcollection/views/sell/chip_camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart' as picker;
import 'package:provider/provider.dart';

/// A camera that answers like a phone: one back lens, 1-4x zoom, and a
/// 1200x1600 upright photo when the shutter is pressed.
class _FakeCamera extends CameraPlatform {
  _FakeCamera({this.cameras = const [_back], this.error, this.photoPath});

  static const _back = CameraDescription(
    name: 'back',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );

  final List<CameraDescription> cameras;
  final CameraException? error;
  final String? photoPath;
  final zooms = <double>[];
  var shots = 0;

  @override
  Future<List<CameraDescription>> availableCameras() async {
    if (error != null) throw error!;
    return cameras;
  }

  @override
  Future<int> createCameraWithSettings(CameraDescription d, MediaSettings s) async => 1;

  @override
  Future<void> initializeCamera(int id, {ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown}) async {}

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int id) => Stream.value(
        const CameraInitializedEvent(1, 1600, 1200, ExposureMode.auto, true, FocusMode.auto, true),
      );

  @override
  // Stays open like a real camera's: the controller waits on `.first`.
  Stream<CameraErrorEvent> onCameraError(int id) => StreamController<CameraErrorEvent>().stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() => const Stream.empty();

  @override
  Widget buildPreview(int id) => const ColoredBox(color: Colors.grey);

  @override
  Future<void> lockCaptureOrientation(int id, DeviceOrientation o) async {}

  @override
  Future<double> getMinZoomLevel(int id) async => 1;

  @override
  Future<double> getMaxZoomLevel(int id) async => 4;

  @override
  Future<void> setZoomLevel(int id, double zoom) async => zooms.add(zoom);

  @override
  Future<XFile> takePicture(int id) async {
    shots++;
    return XFile(photoPath!);
  }

  @override
  Future<void> dispose(int id) async {}
}

class _FakePicker extends picker.ImagePickerPlatform {
  _FakePicker(this.path);

  final String? path;
  final calls = <picker.ImageSource>[];

  @override
  Future<picker.XFile?> getImageFromSource({
    required picker.ImageSource source,
    picker.ImagePickerOptions options = const picker.ImagePickerOptions(),
  }) async {
    calls.add(source);
    return path == null ? null : picker.XFile(path!);
  }
}

Widget _app() => MultiProvider(
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
          initialRoute: AppRoutes.addItem,
          onGenerateRoute: RouteGenerator.generate,
        ),
      ),
    );

Future<void> _openCamera(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Take Photo'));
  await tester.pumpAndSettle();
}

void main() {
  late Directory tmp;
  late String photo;
  late CameraPlatform originalCamera;
  late picker.ImagePickerPlatform originalPicker;

  setUpAll(() async {
    // Real Inter, as in capture_flow_test: Ahem's wide glyphs overflow Add Item.
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      final loader = FontLoader('Inter')
        ..addFont(File('assets/fonts/Inter-$w.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
      await loader.load();
    }
    tmp =await Directory.systemTemp.createTemp('chip_camera_test');
    photo = '${tmp.path}/shot.jpg';
    // Upright 1200x1600 shot: grey, with a red disc where the circle sits.
    final image = img.Image(width: 1200, height: 1600)..clear(img.ColorRgb8(90, 90, 90));
    img.fillCircle(image, x: 600, y: 704, radius: 260, color: img.ColorRgb8(220, 30, 40));
    await File(photo).writeAsBytes(img.encodeJpg(image));
  });

  tearDownAll(() => tmp.delete(recursive: true));

  setUp(() {
    originalCamera = CameraPlatform.instance;
    originalPicker = picker.ImagePickerPlatform.instance;
  });

  tearDown(() {
    CameraPlatform.instance = originalCamera;
    picker.ImagePickerPlatform.instance = originalPicker;
  });

  group('cropRectFor', () {
    test('maps the circle onto a photo shown covering the screen', () {
      // 3:4 photo on a 390x844 screen is scaled by 844/1600 and cut at the sides.
      final r = ChipCameraScreen.cropRectFor(
        view: const Size(390, 844),
        circleCenter: const Offset(195, 371.36),
        circleRadius: 150,
        photo: const Size(1200, 1600),
      );
      expect(r.width, r.height);
      expect(r.width, closeTo(300 / (844 / 1600), 0.5));
      expect(r.center.dx, closeTo(600, 0.5));
      expect(r.center.dy, closeTo(704, 0.5));
    });

    test('never reaches outside the photo', () {
      final r = ChipCameraScreen.cropRectFor(
        view: const Size(390, 844),
        circleCenter: const Offset(20, 20),
        circleRadius: 300,
        photo: const Size(600, 800),
      );
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.top, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(600));
      expect(r.bottom, lessThanOrEqualTo(800));
    });
  });

  testWidgets('Take Photo opens the circular camera with zoom', (tester) async {
    final camera = _FakeCamera(photoPath: photo);
    CameraPlatform.instance = camera;

    await _openCamera(tester);

    expect(find.byType(ChipCameraScreen), findsOneWidget);
    expect(find.text('Fit the chip inside the circle'), findsOneWidget);
    expect(find.text('1.0×'), findsOneWidget);

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    expect(find.text('1.5×'), findsOneWidget);
    expect(camera.zooms, [1.5]);

    await tester.tap(find.byTooltip('Zoom out'));
    await tester.tap(find.byTooltip('Zoom out')); // already at 1x: no-op
    await tester.pumpAndSettle();
    expect(camera.zooms, [1.5, 1.0]);
  });

  testWidgets('the shutter saves the square under the circle and opens the form', (tester) async {
    final camera = _FakeCamera(photoPath: photo);
    CameraPlatform.instance = camera;

    await _openCamera(tester);
    // Cropping runs in a background isolate, which needs the real clock.
    await tester.runAsync(() async {
      await tester.tap(find.bySemanticsLabel('Take photo'));
      for (var i = 0; i < 100 && find.byType(ChipCameraScreen).evaluate().isNotEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();

    expect(camera.shots, 1);
    expect(find.byType(ChipCameraScreen), findsNothing);
    expect(find.text('Add Item'), findsNothing, reason: 'should be on the item form');

    final saved = tester.element(find.byType(Scaffold).last).read<SellController>().photoPath!;
    expect(saved, endsWith('.chip.jpg'));
    final out = (await tester.runAsync(() async => img.decodeJpg(await File(saved).readAsBytes())))!;
    expect(out.width, out.height, reason: 'square crop');
    // The middle of the crop is the red disc the circle was over.
    final mid = out.getPixel(out.width ~/ 2, out.height ~/ 2);
    expect(mid.r, greaterThan(150));
    expect(mid.g, lessThan(90));
  });

  testWidgets('a denied camera is explained and the gallery is offered', (tester) async {
    CameraPlatform.instance = _FakeCamera(error: CameraException('CameraAccessDenied', null));
    final gallery = _FakePicker(photo);
    picker.ImagePickerPlatform.instance = gallery;

    await _openCamera(tester);

    expect(find.textContaining('Camera access is off'), findsOneWidget);
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();

    expect(gallery.calls, [picker.ImageSource.gallery]);
    expect(find.byType(ChipCameraScreen), findsNothing);
    expect(find.text('Add Item'), findsNothing, reason: 'should be on the item form');
  });

  testWidgets('no camera on the device says so', (tester) async {
    CameraPlatform.instance = _FakeCamera(cameras: const []);

    await _openCamera(tester);

    expect(find.textContaining('No camera is available'), findsOneWidget);
  });

  testWidgets('closing the camera goes back to Add Item quietly', (tester) async {
    CameraPlatform.instance = _FakeCamera(photoPath: photo);

    await _openCamera(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Add Item'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
