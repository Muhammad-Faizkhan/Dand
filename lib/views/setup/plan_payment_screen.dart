import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../models/models.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/payment_widgets.dart';

class PlanPaymentScreen extends StatefulWidget {
  const PlanPaymentScreen({super.key, this.plan});

  /// The API plan being bought; null shows the seeded Silver checkout.
  final PlanModel? plan;

  @override
  State<PlanPaymentScreen> createState() => _PlanPaymentScreenState();
}

class _PlanPaymentScreenState extends State<PlanPaymentScreen> {
  int _selected = 0;
  bool _paying = false;

  Future<void> _pay() async {
    final plan = widget.plan;
    final client = context.read<UserController>().client;
    if (plan == null || client == null) {
      Navigator.pushNamed(context, AppRoutes.subscribed);
      return;
    }
    setState(() => _paying = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await client.post('/api/subscriptions', body: {'planId': plan.id});
      if (!mounted) return;
      // New limits apply straight away: refresh the plan, bid counter and profile.
      context.read<UserController>().load();
      context.read<AuctionController>().loadPlan();
      Navigator.pushNamed(context, AppRoutes.subscribed);
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceAlt,
          content: Text(e.message, style: AppText.body.copyWith(fontSize: 12.8.sp)),
        ),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final price = plan?.price ?? '\$4.99';
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
                    style: AppText.captionBold.copyWith(fontSize: 11.2.sp, letterSpacing: 0.9),
                  ),
                  SizedBox(height: 14.h),
                  if (plan == null) ...[
                    PaymentMethodTile(
                      brand: 'VISA',
                      last4: '4827',
                      selected: _selected == 0,
                      onTap: () => setState(() => _selected = 0),
                    ),
                    SizedBox(height: 14.h),
                    PaymentMethodTile(
                      brand: 'MC',
                      last4: '1195',
                      selected: _selected == 1,
                      onTap: () => setState(() => _selected = 1),
                    ),
                    SizedBox(height: 14.h),
                    const AddPaymentMethodTile(),
                  ] else
                    // Store builds will charge through Apple / Google (RevenueCat); until then nothing is charged.
                    Text(
                      'Test mode: no money is charged yet. In the store release this goes through the App Store or Google Play.',
                      style: AppText.bodyDim.copyWith(fontSize: 12.8.sp, height: 1.5),
                    ),
                  SizedBox(height: 22.h),
                  SummaryCard(
                    rows: [MapEntry('${plan?.name ?? 'Silver'} Subscription', plan == null ? '\$4.99/Month' : '$price${plan.period}')],
                    total: price,
                    totalColor: AppColors.planBlue,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 30.h),
            child: PrimaryButton(
              label: _paying ? 'Subscribing…' : 'Pay Now · $price',
              height: 54.h,
              radius: 16.r,
              onTap: _paying ? null : _pay,
            ),
          ),
        ],
      ),
    );
  }
}
