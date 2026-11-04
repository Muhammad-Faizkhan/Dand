import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/responsive_layout.dart';

/// "What do you collect?" — used both in setup and from Settings.
class WhatYouCollectScreen extends StatefulWidget {
  const WhatYouCollectScreen({super.key, this.isEdit = false});

  final bool isEdit;

  @override
  State<WhatYouCollectScreen> createState() => _WhatYouCollectScreenState();
}

class _WhatYouCollectScreenState extends State<WhatYouCollectScreen> {
  bool _saving = false;

  bool get isEdit => widget.isEdit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserController>().loadCategories();
    });
  }

  Future<void> _continue(UserController user) async {
    void next() => isEdit ? Navigator.pop(context) : Navigator.pushNamed(context, AppRoutes.profileCompleted);
    if (!user.live) return next();
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await user.setInterests(user.interestIds.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) return next();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceAlt,
        content: Text(user.error ?? "Couldn't save your interests.", style: AppText.body.copyWith(fontSize: 12.8.sp)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserController>();
    // Real categories when signed in; the design's labels otherwise.
    final List<({Object key, String label})> options = user.live
        ? [for (final c in user.flatCategories) (key: c.id, label: c.name)]
        : [for (final c in AppData.categories) (key: c, label: c)];
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        return AppScaffold(
          body: FillOrScroll(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppLayout.top(isEdit ? 75 : 127)),
                if (isEdit) ...[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
                  ),
                  SizedBox(height: 26.h),
                ],
                Text('What do you collect?', style: AppText.h1.copyWith(fontSize: 26.sp)),
                SizedBox(height: 12.h),
                Text(
                  "Pick a few we'll tailor your feed & matches.",
                  style: AppText.bodyDim.copyWith(fontSize: 13.2.sp),
                ),
                SizedBox(height: 24.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 14.h,
                  children: options.map((o) {
                    final c = o.label;
                    final key = o.key;
                    final selected = key is int ? user.interestIds.contains(key) : auth.interests.contains(c);
                    return GestureDetector(
                      onTap: () => key is int ? user.toggleInterest(key) : auth.toggleInterest(c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.red.withValues(alpha: 0.16)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: selected ? AppColors.redSolid : AppColors.border,
                          ),
                        ),
                        child: Text(
                          c,
                          style: AppText.body.copyWith(
                            fontSize: 12.8.sp,
                            color: selected ? AppColors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: PrimaryButton(
                    label: _saving ? 'Saving…' : (isEdit ? 'Save Changes' : 'Continue'),
                    height: 54.h,
                    radius: 27.r,
                    onTap: _saving ? null : () => _continue(user),
                  ),
                ),
                SizedBox(height: 42.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
