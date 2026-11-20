import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/image_source_sheet.dart';

/// Live camera with a circular guide, used only when adding a chip (Add Item /
/// Add to Marketplace). The chip is lined up inside the circle and the saved
/// photo is the square around that circle, so the chip fills the image.
///
/// Every other photo in the app (profile, covers, feedback) keeps the normal
/// system camera via [ImageSourceSheet].
///
/// Pops with the path of the photo to use (cropped camera shot, or a gallery
/// pick), or null if the user closed it.
class ChipCameraScreen extends StatefulWidget {
  const ChipCameraScreen({super.key});

  static Route<String> route() => MaterialPageRoute<String>(builder: (_) => const ChipCameraScreen());

  /// Circle diameter in design units, and where its centre sits as a fraction
  /// of the screen height.
  static const double circleDesign = 300;
  static const double circleCenterY = 0.44;

  /// Zoom changes by this much per +/- tap.
  static const double zoomStep = 0.5;

  /// The part of a photo (already upright) that sits under the circle, when
  /// the photo is shown like the preview: centred and covering [view].
  /// Returns the square around the circle in photo pixels, kept inside the photo.
  static Rect cropRectFor({
    required Size view,
    required Offset circleCenter,
    required double circleRadius,
    required Size photo,
  }) {
    final k = math.max(view.width / photo.width, view.height / photo.height);
    final dx = (photo.width * k - view.width) / 2;
    final dy = (photo.height * k - view.height) / 2;
    var side = (circleRadius * 2) / k;
    side = math.min(side, math.min(photo.width, photo.height));
    final cx = (circleCenter.dx + dx) / k;
    final cy = (circleCenter.dy + dy) / k;
    final left = (cx - side / 2).clamp(0.0, photo.width - side);
    final top = (cy - side / 2).clamp(0.0, photo.height - side);
    return Rect.fromLTWH(left, top, side, side);
  }

  @override
  State<ChipCameraScreen> createState() => _ChipCameraScreenState();
}

class _ChipCameraScreenState extends State<ChipCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _busy = false;
  double _zoom = 1, _minZoom = 1, _maxZoom = 1, _pinchStartZoom = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The circle maths assumes an upright phone, so hold portrait while open.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(const []);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera has to be released when the app goes to the background and
    // opened again on return, or Android hands back a frozen preview.
    final c = _controller;
    if (state == AppLifecycleState.inactive && c != null) {
      _controller = null;
      c.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null && _error == null) {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return _fail('No camera is available on this device.');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final c = CameraController(back, ResolutionPreset.high, enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      try {
        await c.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } on CameraException {
        // Not every platform can lock it; the photo is still turned upright below.
      }
      double minZ = 1, maxZ = 1;
      try {
        minZ = await c.getMinZoomLevel();
        maxZ = math.min(await c.getMaxZoomLevel(), 8);
      } on CameraException {
        // No zoom on this camera: the buttons stay disabled.
      }
      setState(() {
        _controller = c;
        _minZoom = minZ;
        _maxZoom = math.max(minZ, maxZ);
        _zoom = minZ;
        _error = null;
      });
    } on CameraException catch (e) {
      _fail(_messageFor(e.code));
    } on MissingPluginException {
      _fail('Taking photos is not supported on this device.');
    }
  }

  static String _messageFor(String code) => switch (code) {
    'CameraAccessDenied' ||
    'CameraAccessDeniedWithoutPrompt' ||
    'CameraAccessRestricted' => 'Camera access is off. Turn it on in Settings to take a photo.',
    _ => "Couldn't open the camera.",
  };

  void _fail(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _setZoom(double z) async {
    final c = _controller;
    if (c == null) return;
    final next = z.clamp(_minZoom, _maxZoom);
    if (next == _zoom) return;
    setState(() => _zoom = next);
    try {
      await c.setZoomLevel(next);
    } on CameraException {
      // Ignore: the preview just stays at the old zoom.
    }
  }

  Future<void> _shoot(Size view, Offset center, double radius) async {
    final c = _controller;
    if (c == null || _busy || c.value.isTakingPicture) return;
    setState(() => _busy = true);
    try {
      final shot = await c.takePicture();
      final out = await compute(
        cropChipPhoto,
        ChipCropJob(
          source: shot.path,
          target: '${shot.path}.chip.jpg',
          view: view,
          circleCenter: center,
          circleRadius: radius,
        ),
      );
      if (mounted) Navigator.pop(context, out);
    } on CameraException catch (e) {
      _snack(_messageFor(e.code));
    } catch (_) {
      _snack("Couldn't save that photo. Try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _gallery() async {
    final path = await ImageSourceSheet.capture(context, ImageSource.gallery);
    if (path != null && mounted) Navigator.pop(context, path);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceAlt,
          content: Text(message, style: AppText.body.copyWith(fontSize: 12.8.sp)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: AppColors.black,
      body: LayoutBuilder(
        builder: (context, box) {
          final view = box.biggest;
          final diameter = math.min(ChipCameraScreen.circleDesign.w, view.width - 64.w);
          final radius = diameter / 2;
          final center = Offset(view.width / 2, view.height * ChipCameraScreen.circleCenterY);
          final c = _controller;
          final ready = c != null && c.value.isInitialized;

          return Stack(
            children: [
              if (ready)
                Positioned.fill(
                  child: GestureDetector(
                    onScaleStart: (_) => _pinchStartZoom = _zoom,
                    onScaleUpdate: (d) {
                      if (d.pointerCount > 1) _setZoom(_pinchStartZoom * d.scale);
                    },
                    child: _CoverPreview(controller: c),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _CircleMaskPainter(center: center, radius: radius)),
                ),
              ),
              if (_error != null)
                Positioned.fill(child: _Unavailable(message: _error!, onGallery: _gallery))
              else if (!ready)
                const Center(child: CircularProgressIndicator(color: AppColors.white)),
              // Close and hint.
              Positioned(
                top: pad.top + 12.h,
                left: 8.w,
                right: 8.w,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 24.sp, color: AppColors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Scan Chip',
                        textAlign: TextAlign.center,
                        style: AppText.h1.copyWith(fontSize: 20.sp),
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),
              if (_error == null)
                Positioned(
                  top: center.dy + radius + 22.h,
                  left: 30.w,
                  right: 30.w,
                  child: Text(
                    'Fit the chip inside the circle',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(fontSize: 14.sp, color: AppColors.white),
                  ),
                ),
              if (ready)
                Positioned(
                  left: center.dx + radius - 34.w,
                  top: center.dy - 82.h,
                  child: _ZoomControls(
                    zoom: _zoom,
                    canZoomIn: _zoom < _maxZoom,
                    canZoomOut: _zoom > _minZoom,
                    onIn: () => _setZoom(_zoom + ChipCameraScreen.zoomStep),
                    onOut: () => _setZoom(_zoom - ChipCameraScreen.zoomStep),
                  ),
                ),
              // Gallery, shutter.
              Positioned(
                left: 0,
                right: 0,
                bottom: pad.bottom + 28.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundButton(
                      tooltip: 'Choose from gallery',
                      icon: Icons.photo_library_outlined,
                      onTap: _gallery,
                    ),
                    _Shutter(
                      busy: _busy,
                      onTap: ready && _error == null ? () => _shoot(view, center, radius) : null,
                    ),
                    SizedBox(width: 52.w),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// What [cropChipPhoto] needs. Sent to a background isolate.
class ChipCropJob {
  const ChipCropJob({
    required this.source,
    required this.target,
    required this.view,
    required this.circleCenter,
    required this.circleRadius,
  });

  final String source;
  final String target;
  final Size view;
  final Offset circleCenter;
  final double circleRadius;
}

/// Turns the shot upright, cuts out the square under the circle, shrinks it to
/// the app's upload size and writes a JPEG. Returns the new file's path.
Future<String> cropChipPhoto(ChipCropJob job) async {
  final decoded = img.decodeImage(await File(job.source).readAsBytes());
  if (decoded == null) throw const FormatException('Unreadable photo');
  final upright = img.bakeOrientation(decoded);
  final r = ChipCameraScreen.cropRectFor(
    view: job.view,
    circleCenter: job.circleCenter,
    circleRadius: job.circleRadius,
    photo: Size(upright.width.toDouble(), upright.height.toDouble()),
  );
  var out = img.copyCrop(
    upright,
    x: r.left.round(),
    y: r.top.round(),
    width: r.width.floor(),
    height: r.height.floor(),
  );
  final maxSide = ImageSourceSheet.uploadMaxSide.toInt();
  if (out.width > maxSide) out = img.copyResize(out, width: maxSide, height: maxSide);
  await File(job.target).writeAsBytes(img.encodeJpg(out, quality: ImageSourceSheet.uploadQuality));
  return job.target;
}

/// The preview scaled to cover the whole screen, cropped at the edges, the
/// same way [ChipCameraScreen.cropRectFor] assumes.
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = controller.value.previewSize;
    // previewSize is reported landscape; on an upright phone it is shown turned.
    final w = size == null ? 3.0 : math.min(size.width, size.height);
    final h = size == null ? 4.0 : math.max(size.width, size.height);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: w, height: h, child: CameraPreview(controller)),
      ),
    );
  }
}

/// Darkens everything outside the circle and draws its white ring.
class _CircleMaskPainter extends CustomPainter {
  _CircleMaskPainter({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(hole, Paint()..color = AppColors.black.withValues(alpha: 0.6));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.white,
    );
  }

  @override
  bool shouldRepaint(_CircleMaskPainter old) => old.center != center || old.radius != radius;
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.zoom,
    required this.canZoomIn,
    required this.canZoomOut,
    required this.onIn,
    required this.onOut,
  });

  final double zoom;
  final bool canZoomIn, canZoomOut;
  final VoidCallback onIn, onOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RoundButton(tooltip: 'Zoom in', icon: Icons.add, onTap: canZoomIn ? onIn : null, size: 64),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2C),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            '${zoom.toStringAsFixed(1)}×',
            style: AppText.button.copyWith(fontSize: 13.sp),
          ),
        ),
        SizedBox(height: 10.h),
        _RoundButton(tooltip: 'Zoom out', icon: Icons.remove, onTap: canZoomOut ? onOut : null, size: 64),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.tooltip, required this.icon, required this.onTap, this.size = 52});

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size.w,
          height: size.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A2A2C).withValues(alpha: enabled ? 0.95 : 0.5),
          ),
          child: Icon(
            icon,
            size: (size * 0.42).sp,
            color: AppColors.white.withValues(alpha: enabled ? 1 : 0.35),
          ),
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take photo',
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          width: 78.w,
          height: 78.w,
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: onTap == null ? null : AppColors.redGradient,
              color: onTap == null ? AppColors.white.withValues(alpha: 0.25) : null,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Shown when the camera can't be used: says why and offers the gallery.
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message, required this.onGallery});

  final String message;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 36.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined, size: 40.sp, color: AppColors.white),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(fontSize: 14.sp, color: AppColors.white),
            ),
            SizedBox(height: 20.h),
            TextButton(
              onPressed: onGallery,
              child: Text(
                'Choose from gallery',
                style: AppText.button.copyWith(fontSize: 14.sp, color: AppColors.redSolid),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
