import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import '../core/constants/app_colors.dart';

/// The red camera viewfinder graphic used across the add-item flow.
class ScanFrame extends StatelessWidget {
  const ScanFrame({super.key, this.height, this.photoPath, this.imageUrl, this.onTap});

  final double? height;
  final String? photoPath;

  /// An already-uploaded image (e.g. a collection's current cover), shown
  /// when there is no local [photoPath].
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 296.h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
        ),
        clipBehavior: Clip.antiAlias,
        child: photoPath != null
            ? Image.file(File(photoPath!), fit: BoxFit.cover)
            : imageUrl != null
            ? Image.network(imageUrl!, fit: BoxFit.cover)
            : Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(14.w),
                      child: CustomPaint(painter: _CornersPainter()),
                    ),
                  ),
                  Container(
                    width: 196.w,
                    height: 196.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(56.r),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.55)),
                    ),
                  ),
                  Container(
                    width: 148.w,
                    height: 148.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(42.r),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.45)),
                    ),
                  ),
                  Container(
                    width: 74.w,
                    height: 74.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 27.2.sp,
                      color: AppColors.red.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.redSolid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.square;
    const len = 34.0;
    // top-left
    canvas.drawLine(const Offset(0, len), Offset.zero, paint);
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    // top-right
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // bottom-left (faint, as in the design)
    final faint = Paint()
      ..color = AppColors.redSolid.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height), faint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), faint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
