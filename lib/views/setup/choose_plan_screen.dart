import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({super.key, this.showBack = true});

  final bool showBack;

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  List<PlanModel>? _plans;

  bool get showBack => widget.showBack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<UserController>().client;
    if (client == null) return;
    try {
      final results = await Future.wait([client.get('/api/plans', auth: false), client.get('/api/subscriptions/me')]);
      final rows = (results[0] as List<dynamic>).cast<Map<String, dynamic>>();
      final currentId = ((results[1] as Map<String, dynamic>)['plan'] as Map<String, dynamic>?)?['id'];
      if (!mounted) return;
      setState(() {
        _plans = [
          for (var i = 0; i < rows.length; i++) PlanModel.fromJson(rows[i], current: rows[i]['id'] == currentId, index: i),
        ];
      });
    } on ApiException {
      // The seeded tiers stay up; the upgrade itself will report any error.
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = _plans ?? AppData.plans;
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(77)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBack) ...[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: EdgeInsets.only(top: 6.h, right: 14.w),
                      child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                    ),
                  ),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose your plan', style: AppText.h1.copyWith(fontSize: 21.5.sp)),
                    SizedBox(height: 6.h),
                    Text(
                      'Upgrade to grow your collection',
                      style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 26.h),
            for (final plan in plans) ...[_PlanCard(plan: plan), SizedBox(height: 24.h)],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final gold = plan.highlighted;
    final tinted = !plan.isCurrent;

    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(26.w, 24.h, 26.w, 22.h),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        gradient: tinted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF161618),
                  plan.accent.withValues(alpha: gold ? 0.13 : 0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(20.r),
        border: plan.isCurrent
            ? null
            : Border.all(color: plan.accent.withValues(alpha: gold ? 0.75 : 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!plan.isCurrent) ...[
                Container(
                  width: 40.w,
                  height: 40.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: plan.accent,
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    size: 19.2.sp,
                    color: gold ? AppColors.black : AppColors.white,
                  ),
                ),
                SizedBox(width: 14.w),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: AppText.h2.copyWith(fontSize: 17.6.sp)),
                  SizedBox(height: 2.h),
                  Text(plan.tier, style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
                ],
              ),
              const Spacer(),
              if (plan.isCurrent)
                StatusBadge(
                  label: 'Current',
                  background: AppColors.planBlue.withValues(alpha: 0.28),
                  textColor: const Color(0xFF7E97F0),
                  radius: 9.r,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                  fontSize: 15,
                ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.price,
                style: AppText.display.copyWith(fontSize: 26.4.sp, letterSpacing: -1),
              ),
              SizedBox(width: 4.w),
              Text(plan.period, style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(
                Icons.check_rounded,
                size: 16.sp,
                color: plan.isCurrent
                    ? AppColors.planBlue
                    : (gold ? AppColors.planGold : AppColors.white),
              ),
              SizedBox(width: 10.w),
              Text.rich(
                TextSpan(
                  style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                  children: [
                    const TextSpan(text: 'Upload up to '),
                    TextSpan(
                      text: plan.items,
                      style: AppText.body.copyWith(fontSize: 12.8.sp, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (plan.buttonLabel != null) ...[
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.planPayment, arguments: plan.id == null ? null : plan),
                child: Container(
                  height: 52.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: gold ? null : const Color(0xFF232326),
                    gradient: gold
                        ? const LinearGradient(colors: [Color(0xFFE9B21E), Color(0xFFD79E12)])
                        : null,
                    borderRadius: BorderRadius.circular(14.r),
                    border: gold ? null : Border.all(color: AppColors.borderStrong),
                  ),
                  child: Text(
                    plan.buttonLabel!,
                    style: AppText.button.copyWith(
                      fontSize: 13.6.sp,
                      color: gold ? AppColors.black : AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (plan.badge == null) return card;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: card,
        ),
        Positioned(
          right: 8.w,
          top: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.planGold,
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Text(
              plan.badge!,
              style: AppText.captionBold.copyWith(
                fontSize: 10.4.sp,
                color: AppColors.black,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
