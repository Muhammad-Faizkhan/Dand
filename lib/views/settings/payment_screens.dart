import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/settings_widgets.dart';

/// The red gradient card artwork shown on the card screens.
class CreditCardVisual extends StatelessWidget {
  const CreditCardVisual({
    super.key,
    required this.number,
    this.holder = 'Daniel Dermaree',
    this.expiry = '08/27',
  });

  final String number;
  final String holder;
  final String expiry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176.h,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8242C), Color(0xFFC5171E)],
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withValues(alpha: 0.35),
            blurRadius: 26.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              const Spacer(),
              Text(
                'VISA',
                style: AppText.h3.copyWith(
                  fontSize: 16.8.sp,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 22.h),
          Text(number, style: AppText.h1.copyWith(fontSize: 19.2.sp, letterSpacing: 2)),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card holder',
                    style: AppText.caption.copyWith(
                      fontSize: 10.4.sp,
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(holder, style: AppText.h5.copyWith(fontSize: 13.6.sp)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Expires',
                    style: AppText.caption.copyWith(
                      fontSize: 10.4.sp,
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(expiry, style: AppText.h5.copyWith(fontSize: 13.6.sp)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(62)),
            SettingsHeader(title: 'Payment Methods'),
            SizedBox(height: 24.h),
            _CardRow(
              brand: 'VISA',
              last4: '4827',
              expires: '08/27',
              isDefault: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.manageCard),
            ),
            SizedBox(height: 14.h),
            _CardRow(
              brand: 'MC',
              last4: '1195',
              expires: '03/26',
              onTap: () => Navigator.pushNamed(context, AppRoutes.manageCard),
            ),
            SizedBox(height: 14.h),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.addCard),
              child: Container(
                height: 84.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '+ Add payment method',
                  style: AppText.h4.copyWith(fontSize: 14.4.sp, color: AppColors.red),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.brand,
    required this.last4,
    required this.expires,
    this.isDefault = false,
    this.onTap,
  });

  final String brand;
  final String last4;
  final String expires;
  final bool isDefault;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visa = brand == 'VISA';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isDefault ? AppColors.red.withValues(alpha: 0.6) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 42.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: visa ? AppColors.redSolid : const Color(0xFF2B2B2F),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                brand,
                style: AppText.captionBold.copyWith(fontSize: 11.2.sp, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('••••  $last4', style: AppText.h4.copyWith(fontSize: 15.2.sp)),
                  SizedBox(height: 4.h),
                  Text('Expires $expires', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                ],
              ),
            ),
            if (isDefault) ...[
              StatusBadge(
                label: 'Default',
                background: AppColors.red.withValues(alpha: 0.2),
                textColor: AppColors.red,
                radius: 8.r,
                fontSize: 15,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              ),
              SizedBox(width: 8.w),
            ],
            Icon(Icons.chevron_right_rounded, size: 19.2.sp, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool _default = true;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(62)),
            SettingsHeader(title: 'Add Card'),
            SizedBox(height: 22.h),
            const CreditCardVisual(number: '4827 1195  ••••  ••••'),
            SizedBox(height: 24.h),
            AppTextField(
              label: 'Card number',
              controller: TextEditingController(text: '4827 1195 0000 0000'),
              keyboardType: TextInputType.number,
              height: 56.h,
              suffix: Text(
                'VISA',
                style: AppText.h4.copyWith(
                  fontSize: 14.4.sp,
                  color: AppColors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            SizedBox(height: 18.h),
            AppTextField(
              label: 'Cardholder name',
              controller: TextEditingController(text: 'Daniel Dermaree'),
              height: 56.h,
            ),
            SizedBox(height: 18.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Expiry',
                    controller: TextEditingController(text: '08 / 27'),
                    height: 56.h,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: AppTextField(
                    label: 'CVC',
                    controller: TextEditingController(text: '123'),
                    obscure: true,
                    // No room for the eye in the three-up row, and the design
                    // does not show one here.
                    showToggle: false,
                    height: 56.h,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: AppTextField(
                    label: 'ZIP',
                    controller: TextEditingController(text: '57785'),
                    height: 56.h,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            ToggleGroup(
              rows: [
                ToggleRow(
                  title: 'Set as default card',
                  value: _default,
                  onChanged: (v) => setState(() => _default = v),
                ),
              ],
            ),
            SizedBox(height: 30.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w),
              child: PrimaryButton(
                label: 'Add Card',
                height: 56.h,
                radius: 15.r,
                onTap: () => Navigator.pushNamed(context, AppRoutes.cardAdded),
              ),
            ),
            SizedBox(height: 36.h),
          ],
        ),
      ),
    );
  }
}

class ManageCardScreen extends StatefulWidget {
  const ManageCardScreen({super.key});

  @override
  State<ManageCardScreen> createState() => _ManageCardScreenState();
}

class _ManageCardScreenState extends State<ManageCardScreen> {
  bool _default = true;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppLayout.top(62)),
                  SettingsHeader(title: 'Manage Card'),
                  SizedBox(height: 22.h),
                  const CreditCardVisual(number: '••••  ••••  ••••  4827'),
                  SizedBox(height: 24.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        ToggleRow(
                          title: 'Default payment method',
                          value: _default,
                          onChanged: (v) => setState(() => _default = v),
                        ),
                        Divider(height: 1, color: AppColors.border),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Edit card details',
                                  style: AppText.body.copyWith(fontSize: 14.4.sp),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 19.2.sp,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    height: 72.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, size: 17.6.sp, color: AppColors.red),
                        SizedBox(width: 10.w),
                        Text(
                          'Remove Card',
                          style: AppText.h4.copyWith(fontSize: 15.2.sp, color: AppColors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 0, 25.w, 26.h),
            child: SecondaryButton(
              label: 'Done',
              height: 56.h,
              radius: 15.r,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
