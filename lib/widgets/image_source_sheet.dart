import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/responsive.dart';

/// "Camera or gallery?" sheet, styled like the other bottom sheets in the
/// design. [pick] shows it and returns the chosen file's path, or null if the
/// sheet was dismissed or the picker cancelled.
class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key, required this.title, this.onRemove});

  /// Re-encodes picked photos to ~200-400 KB so the 5 GB Railway volume lasts.
  static const int uploadQuality = 75;
  static const double uploadMaxSide = 1600;

  final String title;

  /// Shown as a third, destructive row when there is already an image.
  final VoidCallback? onRemove;

  /// Asks for a source, then runs the picker. Returns the picked path, or an
  /// empty string when the user chose "Remove photo".
  static Future<String?> pick(
    BuildContext context, {
    String title = 'Profile photo',
    bool canRemove = false,
    int imageQuality = uploadQuality,
  }) async {
    final source = await showModalBottomSheet<_SourceChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      constraints: BoxConstraints(maxWidth: AppResponsive.overlayMaxWidth(context)),
      builder: (_) => _SourceOptions(title: title, canRemove: canRemove),
    );
    if (source == null) return null;
    if (source == _SourceChoice.remove) return '';
    if (!context.mounted) return null;

    return capture(
      context,
      source == _SourceChoice.camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: imageQuality,
    );
  }

  /// Runs the picker and handles the failures a camera actually produces —
  /// permission refused, no camera, an unsupported platform — instead of
  /// letting them throw past the caller and leaving the button looking dead.
  ///
  /// Returns the picked file's path, null if the user cancelled or the source
  /// was unavailable. Failures (never a plain cancel) get a message.
  /// [onGalleryFallback] adds a "Choose from gallery" action to that message
  /// when the camera itself is the thing that is unavailable.
  static Future<String?> capture(
    BuildContext context,
    ImageSource source, {
    int imageQuality = uploadQuality,
    VoidCallback? onGalleryFallback,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: uploadMaxSide,
        maxHeight: uploadMaxSide,
      );
      return picked?.path;
    } on PlatformException catch (e) {
      // A second tap while the picker is already up: not a failure, and the
      // first one is still going to answer.
      if (e.code == 'already_active') return null;
      _report(messenger, _messageFor(e.code, source), e.code, onGalleryFallback);
      return null;
    } on MissingPluginException {
      // Desktop and other platforms without an image_picker implementation.
      _report(
        messenger,
        'Taking photos is not supported on this device.',
        'no_available_camera',
        onGalleryFallback,
      );
      return null;
    }
  }

  static String _messageFor(String code, ImageSource source) => switch (code) {
    'camera_access_denied' => 'Camera access is off. Turn it on in Settings to take a photo.',
    'photo_access_denied' => 'Photo access is off. Turn it on in Settings to choose an image.',
    'no_available_camera' => 'No camera is available on this device.',
    _ => source == ImageSource.camera ? "Couldn't open the camera." : "Couldn't open your photos.",
  };

  static void _report(
    ScaffoldMessengerState messenger,
    String message,
    String code,
    VoidCallback? onGalleryFallback,
  ) {
    // Only offer the gallery when it is the camera that is missing — if
    // permissions are the problem, the gallery is likely blocked as well.
    final canFallBack = onGalleryFallback != null && code == 'no_available_camera';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceAlt,
          content: Text(message, style: AppText.body.copyWith(fontSize: 12.8.sp)),
          action: canFallBack
              ? SnackBarAction(
                  label: 'Choose from gallery',
                  textColor: AppColors.redSolid,
                  onPressed: onGalleryFallback,
                )
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => _SourceOptions(title: title, canRemove: onRemove != null);
}

enum _SourceChoice { camera, gallery, remove }

class _SourceOptions extends StatelessWidget {
  const _SourceOptions({required this.title, required this.canRemove});

  final String title;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 24.h),
        decoration: BoxDecoration(
          color: AppColors.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A4E),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            SizedBox(height: 22.h),
            Text(title, style: AppText.h2.copyWith(fontSize: 17.6.sp)),
            SizedBox(height: 18.h),
            _Option(
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              onTap: () => Navigator.pop(context, _SourceChoice.camera),
            ),
            SizedBox(height: 12.h),
            _Option(
              icon: Icons.photo_library_outlined,
              label: 'Choose from gallery',
              onTap: () => Navigator.pop(context, _SourceChoice.gallery),
            ),
            if (canRemove) ...[
              SizedBox(height: 12.h),
              _Option(
                icon: Icons.delete_outline_rounded,
                label: 'Remove photo',
                tint: AppColors.redSolid,
                onTap: () => Navigator.pop(context, _SourceChoice.remove),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.label, required this.onTap, this.tint});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AppColors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19.2.sp, color: color),
            SizedBox(width: 16.w),
            Text(
              label,
              style: AppText.h4.copyWith(fontSize: 14.4.sp, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
