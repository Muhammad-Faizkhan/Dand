import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/responsive.dart';
import 'app_text_field.dart';
import 'buttons.dart';

/// Asks for an offer amount in whole dollars. Returns cents, or null if the
/// buyer backed out.
class OfferDialog extends StatefulWidget {
  const OfferDialog({super.key, required this.itemName, required this.askingPrice});

  final String itemName;
  final double askingPrice;

  static Future<int?> ask(BuildContext context, {required String itemName, required double askingPrice}) {
    return showDialog<int>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.62),
      builder: (_) => OfferDialog(itemName: itemName, askingPrice: askingPrice),
    );
  }

  @override
  State<OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends State<OfferDialog> {
  late final _amount = TextEditingController(text: widget.askingPrice.toStringAsFixed(0));

  int? get _cents {
    final v = double.tryParse(_amount.text.trim());
    return v == null || v <= 0 ? null : (v * 100).round();
  }

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppResponsive.overlayMaxWidth(context)),
        child: Container(
          padding: EdgeInsets.fromLTRB(22.w, 26.h, 22.w, 20.h),
          decoration: BoxDecoration(
            color: AppColors.sheet,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Make an offer',
                textAlign: TextAlign.center,
                style: AppText.h2.copyWith(fontSize: 17.6.sp),
              ),
              SizedBox(height: 10.h),
              Text(
                '${widget.itemName} · asking \$${widget.askingPrice.toStringAsFixed(0)}\n'
                'If the seller accepts, you agree payment and shipping with them in Messages.',
                textAlign: TextAlign.center,
                style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.45),
              ),
              SizedBox(height: 20.h),
              AppTextField(
                label: 'Your offer (USD)',
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: Padding(
                  padding: EdgeInsets.only(left: 14.w, right: 4.w),
                  child: Text('\$', style: AppText.body.copyWith(fontSize: 14.sp)),
                ),
              ),
              SizedBox(height: 22.h),
              PrimaryButton(
                label: 'Send Offer',
                height: 50.h,
                radius: 14.r,
                enabled: _cents != null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context, _cents);
                },
              ),
              SizedBox(height: 12.h),
              SecondaryButton(
                label: 'Cancel',
                height: 50.h,
                radius: 14.r,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
