import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/api_feedback.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/image_source_sheet.dart';
import '../../widgets/settings_widgets.dart';
import 'dart:io';

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final _extra = <String>[];
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final client = context.read<UserController>().client;
    if (client == null) {
      Navigator.pushNamed(context, AppRoutes.thankYouFeedback);
      return;
    }
    final text = _message.text.trim();
    if (text.isEmpty) {
      showAppMessage(context, 'Tell us a little about it first.');
      return;
    }
    setState(() => _sending = true);
    try {
      final urls = _extra.isEmpty ? const <String>[] : await client.upload(_extra);
      await client.post('/api/feedback', body: {'message': text, if (urls.isNotEmpty) 'imageUrls': urls});
      if (!mounted) return;
      _message.clear();
      setState(_extra.clear);
      Navigator.pushNamed(context, AppRoutes.thankYouFeedback);
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _addImage() async {
    final path = await ImageSourceSheet.capture(context, ImageSource.gallery);
    if (path != null && mounted) setState(() => _extra.add(path));
  }

  @override
  Widget build(BuildContext context) {
    final live = context.read<UserController>().live;
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(64)),
            SettingsHeader(title: 'Help & Feedback'),
            SizedBox(height: 26.h),
            Text('Can you share more about it?', style: AppText.h3.copyWith(fontSize: 16.8.sp)),
            SizedBox(height: 14.h),
            AppTextField(hint: 'Write Description', maxLines: 4, controller: _message),
            SizedBox(height: 18.h),
            SizedBox(
              height: 118.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // The design's sample screenshots, shown only in the offline build.
                  if (!live) ...[
                    _thumb(child: Image.asset(AppAssets.feedback1, fit: BoxFit.cover)),
                    SizedBox(width: 12.w),
                    _thumb(child: Image.asset(AppAssets.feedback2, fit: BoxFit.cover)),
                    SizedBox(width: 12.w),
                  ],
                  for (final p in _extra) ...[
                    GestureDetector(
                      onLongPress: () => setState(() => _extra.remove(p)),
                      child: _thumb(child: Image.file(File(p), fit: BoxFit.cover)),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  GestureDetector(
                    onTap: _addImage,
                    child: DottedBorderBox(
                      width: 107.w,
                      height: 118.h,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 20.8.sp, color: AppColors.white),
                          SizedBox(height: 6.h),
                          Text('Add more', style: AppText.body.copyWith(fontSize: 12.8.sp)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 22.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w),
              child: PrimaryButton(
                label: 'Publish Feedback',
                height: 56.h,
                radius: 15.r,
                enabled: !_sending,
                onTap: _publish,
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _thumb({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(12.r),
    child: SizedBox(width: 107.w, height: 118.h, child: child),
  );
}

/// Dashed red outline used for the "Add more" tile.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    required this.width,
    required this.height,
  });

  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(radius: 12.r),
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.red.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + dash).clamp(0, metric.length)),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter oldDelegate) => false;
}
