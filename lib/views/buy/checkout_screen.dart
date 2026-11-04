import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/payment_widgets.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutController>(
      builder: (context, checkout, _) {
        String money(double v) => '\$${v.toStringAsFixed(2)}';
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
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                          ),
                          SizedBox(width: 16.w),
                          Text('Payment', style: AppText.h1.copyWith(fontSize: 20.5.sp)),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      const BluePlanProgress(step: 1),
                      SizedBox(height: 26.h),
                      Text(
                        'PAY WITH',
                        style: AppText.captionBold.copyWith(
                          fontSize: 11.2.sp,
                          letterSpacing: 0.9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      PaymentMethodTile(
                        brand: 'VISA',
                        last4: '4827',
                        selected: checkout.cardIndex == 0,
                        onTap: () => checkout.setCard(0),
                      ),
                      SizedBox(height: 14.h),
                      PaymentMethodTile(
                        brand: 'MC',
                        last4: '1195',
                        selected: checkout.cardIndex == 1,
                        onTap: () => checkout.setCard(1),
                      ),
                      SizedBox(height: 14.h),
                      AddPaymentMethodTile(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.addCard),
                      ),
                      SizedBox(height: 22.h),
                      SummaryCard(
                        rows: [
                          MapEntry('Item price', money(checkout.subtotal)),
                          MapEntry(
                            'Shipping (${checkout.shippingMethod == 0 ? 'standard' : 'express'})',
                            money(checkout.shippingCost),
                          ),
                          MapEntry('Buyer protection', money(CheckoutController.buyerProtection)),
                        ],
                        total: money(checkout.total),
                        totalColor: const Color(0xFF7E97F0),
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 30.h),
                child: PrimaryButton(
                  label: 'Place Order · ${money(checkout.total)}',
                  height: 56.h,
                  radius: 15.r,
                  gradient: AppColors.blueGradient,
                  glowColor: AppColors.planBlue,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.orderPlaced),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
