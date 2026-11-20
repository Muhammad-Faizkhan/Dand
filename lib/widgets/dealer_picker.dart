import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/api/api_client.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/responsive.dart';
import '../models/models.dart';

/// What the user chose in the dealer sheet: a dealer from the list, or "not
/// listed" with the name they typed ([dealer] null).
typedef DealerChoice = ({Dealer? dealer, String typed});

/// Add Item → "Dealership": shows the picked dealer and opens a searchable
/// list of every dealership when tapped.
class DealerPickerField extends StatelessWidget {
  const DealerPickerField({
    super.key,
    required this.dealer,
    required this.typed,
    required this.search,
    required this.onChanged,
  });

  final Dealer? dealer;

  /// The name read from the chip or typed by the user; the sheet starts
  /// searching with it.
  final String typed;
  final Future<List<Dealer>> Function(String query) search;
  final ValueChanged<DealerChoice> onChanged;

  Future<void> _open(BuildContext context) async {
    final choice = await showModalBottomSheet<DealerChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      constraints: BoxConstraints(maxWidth: AppResponsive.overlayMaxWidth(context)),
      builder: (_) => DealerPickerSheet(initialQuery: dealer?.name ?? typed, search: search),
    );
    if (choice != null) onChanged(choice);
  }

  @override
  Widget build(BuildContext context) {
    final d = dealer;
    final title = d?.displayName ?? (typed.trim().isEmpty ? 'Choose the dealership' : typed.trim());
    final detail = d?.address ?? (typed.trim().isEmpty ? null : 'Not matched to a dealer. Tap to pick one.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dealership', style: AppText.label),
        SizedBox(height: 8.h),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          child: InkWell(
            key: const Key('dealer-picker-field'),
            borderRadius: BorderRadius.circular(14.r),
            onTap: () => _open(context),
            child: Container(
              constraints: BoxConstraints(minHeight: 58.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront_outlined, size: 20.r, color: d == null ? AppColors.textSecondary : AppColors.red),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.field.copyWith(
                            color: d == null && typed.trim().isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
                          ),
                        ),
                        if (detail != null) ...[
                          SizedBox(height: 2.h),
                          Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodySmDim),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.search, size: 20.r, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet: type part of a dealer's name, city or state and pick it.
class DealerPickerSheet extends StatefulWidget {
  const DealerPickerSheet({super.key, required this.initialQuery, required this.search});

  final String initialQuery;
  final Future<List<Dealer>> Function(String query) search;

  @override
  State<DealerPickerSheet> createState() => _DealerPickerSheetState();
}

class _DealerPickerSheetState extends State<DealerPickerSheet> {
  late final _query = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  List<Dealer> _results = const [];
  bool _loading = false;
  String? _error;

  /// Drops answers to searches the user has already typed past.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _run(_query.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(text));
  }

  Future<void> _run(String text) async {
    final id = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final found = await widget.search(text);
      if (!mounted || id != _request) return;
      setState(() => _results = found);
    } on ApiException catch (e) {
      if (!mounted || id != _request) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted && id == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typed = _query.text.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.8,
        padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 12.h),
        decoration: BoxDecoration(
          color: AppColors.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 5.h,
                decoration: BoxDecoration(color: const Color(0xFF4A4A4E), borderRadius: BorderRadius.circular(3.r)),
              ),
            ),
            SizedBox(height: 22.h),
            Text('Which dealership is this chip from?', style: AppText.h2.copyWith(fontSize: 17.6.sp)),
            SizedBox(height: 14.h),
            Container(
              height: 50.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20.r, color: AppColors.textSecondary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      key: const Key('dealer-search'),
                      controller: _query,
                      autofocus: widget.initialQuery.isEmpty,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _run,
                      style: AppText.field,
                      cursorColor: AppColors.red,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Dealer name, city or state',
                        hintStyle: AppText.field.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                  if (_loading) SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.red)),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(child: _list(typed)),
          ],
        ),
      ),
    );
  }

  Widget _list(String typed) {
    final notListed = typed.isEmpty
        ? null
        : _Row(
            key: const Key('dealer-not-listed'),
            icon: Icons.edit_outlined,
            title: 'Not in the list? Keep "$typed"',
            detail: 'Saved as typed, without a dealer link',
            onTap: () => Navigator.pop(context, (dealer: null, typed: typed)),
          );

    if (_error != null) {
      return ListView(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Text("Couldn't load dealers. $_error", style: AppText.bodyDim.copyWith(color: AppColors.red)),
        ),
        ?notListed,
      ]);
    }
    if (!_loading && _results.isEmpty) {
      return ListView(children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Text('No dealership matches "$typed". Try just the city or part of the name.', style: AppText.bodyDim),
        ),
        ?notListed,
      ]);
    }
    return ListView.separated(
      itemCount: _results.length + (notListed == null ? 0 : 1),
      separatorBuilder: (_, _) => SizedBox(height: 8.h),
      itemBuilder: (context, i) {
        if (i == _results.length) return notListed!;
        final d = _results[i];
        return _Row(
          key: Key('dealer-${d.id}'),
          icon: Icons.storefront_outlined,
          title: d.displayName,
          detail: d.address,
          onTap: () => Navigator.pop(context, (dealer: d, typed: d.name)),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({super.key, required this.icon, required this.title, required this.detail, required this.onTap});

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, size: 20.r, color: AppColors.red),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.h4),
                    SizedBox(height: 2.h),
                    Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodySmDim),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
