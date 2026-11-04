import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/image_source_sheet.dart';
import '../../widgets/scan_frame.dart';

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  Future<void> _capture(BuildContext context, ImageSource source) async {
    // Re-entered from the snackbar's gallery action, which outlives this screen.
    if (!context.mounted) return;
    final sell = context.read<SellController>();
    final path = await ImageSourceSheet.capture(
      context,
      source,
      onGalleryFallback: source == ImageSource.camera ? () => _capture(context, ImageSource.gallery) : null,
    );
    if (path == null || !context.mounted) return;
    // The form opens straight away and shows "Reading your chip…" until the scan lands.
    sell.scanPhoto(path);
    Navigator.pushNamed(context, AppRoutes.itemForm);
  }

  @override
  Widget build(BuildContext context) {
    final sell = context.watch<SellController>();
    // Fills the screen on a phone, scrolls when landscape is too short for the frame.
    return AppScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
        children: [
          SizedBox(height: AppLayout.top(62)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 21.6.sp, color: AppColors.white),
                ),
                Expanded(
                  child: Center(
                    child: Text('Add Item', style: AppText.h1.copyWith(fontSize: 20.sp)),
                  ),
                ),
                SizedBox(width: 27.sp),
              ],
            ),
          ),
          SizedBox(height: 38.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: ScanFrame(height: 296.h, photoPath: sell.photoPath, onTap: () => _capture(context, ImageSource.camera)),
          ),
          SizedBox(height: 32.h),
          //
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 16.sp, color: AppColors.redSolid),
              SizedBox(width: 10.w),
              Text('AI-Powered Recognition', style: AppText.h3.copyWith(fontSize: 16.8.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Text(
              "Position your collectible in the frame.\nWe'll auto-detect dealer, location & type.",
              textAlign: TextAlign.center,
              style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.5),
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(AppLayout.gutter, 0, AppLayout.gutter, 32.h),
            child: Row(
              children: [
                Expanded(
                  child: _StackedButton(
                    label: 'Take Photo',
                    glyph: Text('📷', style: TextStyle(fontSize: 16.sp)),
                    primary: true,
                    onTap: () => _capture(context, ImageSource.camera),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: _StackedButton(
                    label: 'Upload',
                    glyph: Icon(Icons.arrow_upward, size: 17.6.sp, color: AppColors.white),
                    onTap: () => _capture(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ),
        ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glyph stacked above the label, as drawn in the design.
class _StackedButton extends StatelessWidget {
  const _StackedButton({required this.label, required this.glyph, required this.onTap, this.primary = false});

  final String label;
  final Widget glyph;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 78.h,
        decoration: BoxDecoration(
          gradient: primary ? AppColors.redGradient : null,
          color: primary ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: primary ? null : Border.all(color: AppColors.border),
          boxShadow: primary ? [BoxShadow(color: AppColors.red.withValues(alpha: 0.35), blurRadius: 26.r, offset: Offset(0, 8.h))] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            glyph,
            SizedBox(height: 6.h),
            Text(label, style: AppText.button.copyWith(fontSize: 13.6.sp)),
          ],
        ),
      ),
    );
  }
}
