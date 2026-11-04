import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../models/models.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user, this.thread});

  final String user;

  /// A real conversation (or one to start with [ChatThread.userId]); null for the seeded chat.
  final ChatThread? thread;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  late ChatThread? _thread = widget.thread;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final t = _thread;
    if (t != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ChatController>().openThread(t);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(ChatController chat) async {
    final text = _input.text;
    final t = _thread;
    if (t == null) {
      chat.send(widget.user, text);
      _input.clear();
      return;
    }
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final next = await chat.sendTo(t, text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (next != null) {
        _thread = next;
        _input.clear();
      }
    });
    if (next == null) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceAlt,
          content: Text("Message didn't send. Try again.", style: AppText.body.copyWith(fontSize: 12.8.sp)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final live = _thread;
    final messages = live == null ? chat.messagesFor(widget.user) : chat.messagesIn(live);
    final thread = live ??
        AppData.threads.firstWhere(
          (t) => t.name == widget.user,
          orElse: () => AppData.threads.first,
        );

    return AppScaffold(
      safeAreaTop: false,
      body: Column(
        children: [
          Container(
            color: const Color(0xFF101012),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 14.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back, size: 20.sp, color: AppColors.white),
                    ),
                    SizedBox(width: 14.w),
                    InitialsAvatar(initials: thread.initials, size: 46.w, fontSize: 15),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user, style: AppText.h3.copyWith(fontSize: 16.sp)),
                        // Presence isn't tracked by the API, so only the seeded chat shows it.
                        if (live == null) ...[
                          SizedBox(height: 3.h),
                          Row(
                            children: [
                              Container(
                                width: 9.w,
                                height: 9.w,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Online',
                                style: AppText.body.copyWith(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF3CCB84),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.more_vert, size: 18.4.sp, color: AppColors.white),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 16.h),
              children: [
                if (live != null && messages.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Text(
                      live.conversationId == null ? 'Say hello to ${widget.user}.' : 'Loading messages…',
                      textAlign: TextAlign.center,
                      style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                    ),
                  ),
                for (final m in messages) _Bubble(mine: m.mine, text: m.text),
                SizedBox(height: 8.h),
                if (live == null)
                Container(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                  decoration: BoxDecoration(
                    color: AppColors.redTint,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.proposeTrade),
                              child: Container(
                                height: 52.h,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: AppColors.redGradient,
                                  borderRadius: BorderRadius.circular(11.r),
                                ),
                                child: Text(
                                  'Propose Trade',
                                  style: AppText.button.copyWith(fontSize: 13.6.sp),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.itemDetail),
                              child: Container(
                                height: 52.h,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(11.r),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  'View Listing',
                                  style: AppText.button.copyWith(fontSize: 13.6.sp),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFF101012),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 12.h),
                child: Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(Icons.image_outlined, size: 17.6.sp, color: AppColors.white),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Container(
                        height: 48.h,
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: TextField(
                          controller: _input,
                          style: AppText.field,
                          cursorColor: AppColors.red,
                          onSubmitted: (_) => _send(chat),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                            hintText: 'Type a message...',
                            hintStyle: AppText.field.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    GestureDetector(
                      onTap: () => _send(chat),
                      child: Container(
                        width: 48.w,
                        height: 48.w,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.redSolid,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.send_rounded, size: 17.6.sp, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.mine, required this.text});

  final bool mine;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 265.w),
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: mine ? AppColors.redGradient : null,
          color: mine ? null : const Color(0xFF1E1E20),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(text, style: AppText.body.copyWith(fontSize: 13.6.sp, height: 1.4)),
      ),
    );
  }
}
