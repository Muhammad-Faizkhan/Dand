import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/image_source_sheet.dart';
import '../../widgets/settings_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final UserController _user = context.read<UserController>();
  late final bool _live = _user.live;
  late final _name = TextEditingController(text: _live ? (_user.user?.fullName ?? '') : 'Rider Mike');
  late final _location = TextEditingController(text: _live ? (_user.user?.address ?? '') : 'Sturgis, SD');
  late final _email = TextEditingController(text: _live ? (_user.user?.email ?? '') : 'rider@example.com');
  late final _phone = TextEditingController(text: _live ? (_user.user?.phone ?? '') : '+1 (605) 555-0142');
  late final _bio = TextEditingController(
    text: _live ? (_user.user?.bio ?? '') : 'Passionate Harley collector since 2010. Always looking for rare CT & SD chips!',
  );

  String? _newPhoto;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _location, _email, _phone, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final profile = context.read<ProfileController>();
    final path = await ImageSourceSheet.pick(
      context,
      title: 'Profile photo',
      canRemove: profile.hasCustomAvatar,
    );
    // null is a cancel; '' is "Remove photo", which setAvatar reads as a reset.
    if (path == null) return;
    // Shown at once; uploaded when the user taps Save.
    profile.setAvatar(path);
    _newPhoto = path.isEmpty ? null : path;
  }

  Future<void> _save() async {
    if (!_live) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final profile = context.read<ProfileController>();
    String? trimmed(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    var ok = await _user.updateProfile(
      fullName: trimmed(_name),
      address: trimmed(_location),
      phone: trimmed(_phone),
      bio: trimmed(_bio),
    );
    final photo = _newPhoto;
    if (ok && photo != null) ok = await profile.uploadAvatar(photo);
    if (ok) await _user.load();
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceAlt,
          content: Text(_user.error ?? "Couldn't save your profile.", style: AppText.body.copyWith(fontSize: 12.8.sp)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.top(64)),
            SettingsHeader(
              title: 'Edit Profile',
              trailing: GestureDetector(
                onTap: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save', style: AppText.link.copyWith(fontSize: 15.2.sp)),
              ),
            ),
            SizedBox(height: 24.h),
            Center(
              child: SizedBox(
                width: 108.w,
                height: 108.w,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipOval(
                      child: Builder(
                        builder: (context) {
                          final local = context.watch<ProfileController>();
                          final url = context.watch<UserController>().avatarUrl;
                          return Image(
                            image: !local.hasCustomAvatar && url != null ? NetworkImage(url) : local.avatar,
                            width: 108.w,
                            height: 108.w,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image(image: local.avatar, width: 108.w, height: 108.w, fit: BoxFit.cover),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 6.h,
                      child: GestureDetector(
                        onTap: _pick,
                        child: Container(
                          width: 34.w,
                          height: 34.w,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.redSolid,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.photo_camera, size: 13.6.sp, color: AppColors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 26.h),
            _field(icon: Icons.person_outline, label: 'Full Name', controller: _name),
            SizedBox(height: 18.h),
            _field(icon: Icons.place_outlined, label: 'Location', controller: _location),
            SizedBox(height: 18.h),
            // The API has no email change, so it's shown but not editable.
            _field(label: 'Email', controller: _email, readOnly: _live),
            SizedBox(height: 18.h),
            _field(label: 'Phone', controller: _phone),
            SizedBox(height: 18.h),
            _field(icon: Icons.menu_book_outlined, label: 'Bio', controller: _bio, maxLines: 3),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _field({
    IconData? icon,
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13.6.sp, color: AppColors.textSecondary),
              SizedBox(width: 8.w),
            ],
            Text(label, style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
          ],
        ),
        SizedBox(height: 10.h),
        AppTextField(
          controller: controller,
          height: 60.h,
          maxLines: maxLines,
          readOnly: readOnly,
        ),
      ],
    );
  }
}
