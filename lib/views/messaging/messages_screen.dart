import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ChatController>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final threads = chat.threads;
    return AppScaffold(
      body: SingleChildScrollView(
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
                Text('Messages', style: AppText.h1.copyWith(fontSize: 26.sp)),
              ],
            ),
            SizedBox(height: 22.h),
            if (chat.live && threads.isEmpty)
              chat.loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary))
                  : Text(
                      'No messages yet. Open a listing and message the seller to start a conversation.',
                      style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5),
                    ),
            for (final t in threads) ...[
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.chat, arguments: chat.live ? t : t.name),
                child: Container(
                  height: 90.h,
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60.w,
                        height: 60.w,
                        child: Stack(
                          children: [
                            InitialsAvatar(initials: t.initials, size: 60.w, fontSize: 14),
                            if (t.online)
                              Positioned(
                                right: 1.w,
                                bottom: 1.h,
                                child: Container(
                                  width: 13.w,
                                  height: 13.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.surface, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(t.name, style: AppText.h4.copyWith(fontSize: 15.2.sp)),
                            SizedBox(height: 4.h),
                            Text(
                              t.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(t.time, style: AppText.bodyDim.copyWith(fontSize: 12.sp)),
                          SizedBox(height: 6.h),
                          if (t.unread > 0)
                            Container(
                              width: 24.w,
                              height: 24.w,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.redSolid,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${t.unread}',
                                style: AppText.captionBold.copyWith(fontSize: 10.4.sp),
                              ),
                            )
                          else
                            SizedBox(height: 24.w),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
            ],
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
