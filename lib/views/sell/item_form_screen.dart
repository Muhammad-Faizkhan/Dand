import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../controllers/app_controller.dart';
import '../../controllers/collections_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dealer_picker.dart';
import '../../widgets/scan_frame.dart';
import '../../widgets/settings_widgets.dart';
import '../../widgets/image_source_sheet.dart';
import '../../widgets/upgrade_prompt.dart';
import '../../core/api/api_client.dart';
import '../../models/models.dart';

/// Step 2 of the add-item flow: confirm what the scan detected and list it.
class ItemFormScreen extends StatelessWidget {
  const ItemFormScreen({super.key});

  static const _listAs = ['For Trade', 'For Sale', 'Auction'];

  @override
  Widget build(BuildContext context) {
    return Consumer<SellController>(
      builder: (context, sell, _) => AppScaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppLayout.top(62)),
                    SettingsHeader(title: 'Item Details'),
                    SizedBox(height: 24.h),
                    const StepProgress(step: 1),
                    SizedBox(height: 22.h),
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 66.w,
                            height: 66.w,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: sell.photoPath == null
                                ? Image.asset(AppAssets.chipYankeeBristol, fit: BoxFit.cover)
                                : Image.file(File(sell.photoPath!), fit: BoxFit.cover),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(child: _ScanSummary(sell: sell)),
                        ],
                      ),
                    ),
                    if (_warning(sell) case final warning?) ...[
                      SizedBox(height: 12.h),
                      Text(
                        warning,
                        style: AppText.bodyDim.copyWith(fontSize: 12.sp, color: AppColors.red, height: 1.4),
                      ),
                    ],
                    SizedBox(height: 20.h),
                    AppTextField(label: 'Title', controller: sell.titleCtrl, height: 58.h),
                    if (sell.client != null) ...[
                      SizedBox(height: 18.h),
                      DealerPickerField(
                        dealer: sell.dealer,
                        typed: sell.dealerCtrl.text,
                        search: sell.searchDealers,
                        onChanged: (choice) {
                          sell.dealerCtrl.text = choice.typed;
                          sell.setDealer(choice.dealer);
                        },
                      ),
                      SizedBox(height: 18.h),
                      AppTextField(
                        label: 'Year',
                        hint: 'If printed on the chip',
                        controller: sell.yearCtrl,
                        height: 58.h,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownField(
                            label: 'Rarity',
                            value: sell.rarity,
                            items: SellController.rarities,
                            onChanged: sell.setRarity,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: DropdownField(
                            label: 'Condition',
                            value: sell.condition,
                            items: SellController.conditions,
                            onChanged: sell.setCondition,
                          ),
                        ),
                      ],
                    ),
                    if (sell.client != null) ...[
                      SizedBox(height: 18.h),
                      AppTextField(label: 'Description', hint: 'Add description', controller: sell.descCtrl, maxLines: 4),
                    ],
                    SizedBox(height: 20.h),
                    Text('List as', style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        for (var i = 0; i < _listAs.length; i++) ...[
                          if (i > 0) SizedBox(width: 12.w),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => sell.setListingType(i),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
                                decoration: BoxDecoration(
                                  gradient: sell.listingType == i ? AppColors.redGradient : null,
                                  color: sell.listingType == i ? null : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: sell.listingType == i
                                        ? Colors.transparent
                                        : AppColors.border,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _listAs[i],
                                  style: AppText.body.copyWith(
                                    fontSize: 13.6.sp,
                                    fontWeight: sell.listingType == i
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: sell.listingType == i
                                        ? AppColors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(25.w, 0, 25.w, 30.h),
              child: PrimaryButton(
                label: sell.client == null
                    ? 'List'
                    : sell.saving
                    ? 'Saving…'
                    : 'Confirm & Save',
                height: 58.h,
                radius: 15.r,
                onTap: sell.client == null
                    ? () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false)
                    : sell.canSave
                    ? () => _save(context, sell)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _warning(SellController sell) {
    final scan = sell.scan;
    if (sell.scanError != null) return '${sell.scanError} Fill in the details below.';
    if (scan == null) return null;
    if (!scan.isChip) return "This doesn't look like a chip. Check the photo or fill in the details yourself.";
    final check = scan.unreadable;
    if (scan.confidence == 'low' || check != null) {
      return 'Please double-check these details${check == null ? '.' : ': $check'}';
    }
    return null;
  }

  Future<void> _save(BuildContext context, SellController sell) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await sell.save();
    if (!context.mounted) return;
    switch (result.status) {
      case SaveStatus.saved:
        context.read<CollectionsController>().load();
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false);
      case SaveStatus.upgradeRequired:
        await showUpgradePrompt(context, result.message);
      case SaveStatus.failed:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.surfaceAlt,
              content: Text(
                result.message ?? "Couldn't save the chip. Try again.",
                style: AppText.body.copyWith(fontSize: 12.8.sp),
              ),
            ),
          );
    }
  }
}

/// The card beside the photo: a spinner while Claude reads the chip, then what it found.
class _ScanSummary extends StatelessWidget {
  const _ScanSummary({required this.sell});

  final SellController sell;

  static const _green = Color(0xFF3CCB84);

  @override
  Widget build(BuildContext context) {
    if (sell.scanning) {
      return Row(
        children: [
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: const CircularProgressIndicator(strokeWidth: 1.6, color: AppColors.textSecondary),
          ),
          SizedBox(width: 10.w),
          Text('Reading your chip…', style: AppText.bodyDim.copyWith(fontSize: 13.6.sp)),
        ],
      );
    }
    final scan = sell.scan;
    final failed = sell.client != null && scan == null;
    final name = scan == null ? 'Old School Harley-Davidson' : (scan.dealership ?? scan.title);
    final line = scan == null ? 'Ellington CT · Casino chip' : scan.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(failed ? Icons.edit_outlined : Icons.check, size: 13.6.sp, color: failed ? AppColors.textSecondary : _green),
            SizedBox(width: 6.w),
            Text(
              failed ? 'Enter details' : 'AI detected',
              style: AppText.h5.copyWith(fontSize: 13.6.sp, color: failed ? AppColors.textSecondary : _green),
            ),
          ],
        ),
        if (!failed) ...[
          SizedBox(height: 5.h),
          Text(name, style: AppText.h4.copyWith(fontSize: 14.4.sp)),
          if (line.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(line, style: AppText.bodyDim.copyWith(fontSize: 12.8.sp)),
          ],
        ],
      ],
    );
  }
}

/// Step 1 variants that create a collection or add an item to one.
class CollectionFormScreen extends StatefulWidget {
  const CollectionFormScreen({super.key, required this.isCategory, this.editing});

  final bool isCategory;

  /// The user's own collection to rename / re-cover; null creates a new one.
  final ApiCollection? editing;

  @override
  State<CollectionFormScreen> createState() => _CollectionFormScreenState();
}

class _CollectionFormScreenState extends State<CollectionFormScreen> {
  late final _title = TextEditingController(
    text: widget.editing?.name ?? (context.read<CollectionsController>().client == null ? 'Event 5' : ''),
  );
  late final _desc = TextEditingController(text: widget.editing?.description ?? '');
  String? _coverPath;
  bool _saving = false;

  bool get isCategory => widget.isCategory;
  bool get isEdit => widget.editing != null;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final path = await ImageSourceSheet.pick(context, title: 'Collection cover');
    if (path != null && path.isNotEmpty && mounted) setState(() => _coverPath = path);
  }

  Future<void> _submit() async {
    final ctrl = context.read<CollectionsController>();
    final client = ctrl.client;
    if (!isCategory || client == null) {
      Navigator.pop(context);
      return;
    }
    final name = _title.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    void say(String m) => messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceAlt,
        content: Text(m, style: AppText.body.copyWith(fontSize: 12.8.sp)),
      ),
    );
    if (name.isEmpty) return say('Give the collection a title.');
    setState(() => _saving = true);
    try {
      final cover = _coverPath == null ? null : (await client.upload([_coverPath!])).first;
      final editing = widget.editing;
      if (editing != null) {
        final saved = await ctrl.update(
          editing.id,
          name: name,
          description: _desc.text.trim(),
          coverImageUrl: cover,
        );
        if (!mounted) return;
        if (saved == null) return say(ctrl.error ?? "Couldn't save the collection.");
        Navigator.pop(context, saved);
        return;
      }
      final created = await ctrl.create(
        name: name,
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        coverImageUrl: cover,
      );
      if (!mounted) return;
      if (created == null) return say(ctrl.error ?? "Couldn't create the collection.");
      Navigator.pop(context);
    } on ApiException catch (e) {
      say(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sell = context.watch<SellController>();
    final live = context.read<CollectionsController>().client != null && isCategory;
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
                  SettingsHeader(title: isEdit ? 'Edit Collection' : (isCategory ? 'Create Category' : 'Add to Collection')),
                  SizedBox(height: 24.h),
                  if (!isEdit) ...[
                    const StepProgress(step: 0),
                    SizedBox(height: 22.h),
                  ],
                  ScanFrame(
                    height: 296.h,
                    photoPath: live ? _coverPath : sell.photoPath,
                    imageUrl: live ? widget.editing?.coverImageUrl : null,
                    onTap: live ? _pickCover : null,
                  ),
                  SizedBox(height: 26.h),
                  if (isCategory) ...[
                    AppTextField(
                      label: 'Collection Title',
                      hint: 'e.g. Sturgis 2024',
                      controller: _title,
                      height: 58.h,
                    ),
                    SizedBox(height: 18.h),
                    AppTextField(label: 'Description', hint: 'Add description', controller: _desc, maxLines: 4),
                  ] else ...[
                    AppTextField(label: 'Title', hint: 'Enter Title', height: 58.h),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownField(
                            label: 'Rarity',
                            value: 'Select',
                            items: const ['Select', 'Common', 'Rare', 'Ultra Rare', 'Legendary'],
                            onChanged: (_) {},
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: DropdownField(
                            label: 'Condition',
                            value: 'Select',
                            items: const ['Select', 'Mint', 'Near Mint', 'Good', 'Fair'],
                            onChanged: (_) {},
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(25.w, 0, 25.w, 30.h),
            child: GestureDetector(
              onTap: _saving ? null : _submit,
              child: Container(
                height: 58.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: live ? null : const Color(0xFF9A9A9E),
                  gradient: live ? AppColors.redGradient : null,
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Text(
                  isEdit
                      ? (_saving ? 'Saving…' : 'Save Changes')
                      : _saving
                      ? 'Creating…'
                      : (isCategory ? 'Create Collection Category' : 'Add to Collection'),
                  style: AppText.button.copyWith(fontSize: 14.4.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
