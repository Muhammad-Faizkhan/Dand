import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/collections_controller.dart';
import '../../controllers/user_controller.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_assets.dart';
import '../../models/models.dart';
import '../../widgets/chip_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/layout.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/responsive_layout.dart';
import '../../core/utils/responsive.dart';

const _events = [
  AppAssets.event1,
  AppAssets.event2,
  AppAssets.event3,
  AppAssets.event4,
  AppAssets.event5,
];

const _eventChips = <(String, String)>[
  (AppAssets.chipParadisePt, 'Yankee · Bristol CT'),
  (AppAssets.chipAlmostHeavenC, 'Paradise · Portland'),
  (AppAssets.chipOzarks, 'Classic · Reading PA'),
  (AppAssets.chipPowderKeg, 'Powder Keg'),
  (AppAssets.chipGrizzlyC, 'Buckeye · Ohio'),
];

/// Collection and chip grids: two across on a phone, as drawn, and up to six
/// on a wide tablet or landscape screen (the client asked for 5–6 across).
SliverGridDelegate _grid(BuildContext context) => responsiveGridDelegate(
  context,
  tileDesign: const Size(155, 196),
  spacing: 16,
  runSpacing: 18,
  mode: ContentWidth.full,
  maxColumns: 6,
);

/// "Tom / Collections" — the event poster grid.
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CollectionsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CollectionsController>();
    final live = ctrl.client != null;
    final cols = ctrl.collections;
    final count = live ? cols.length : _events.length;
    final primary = [for (final c in cols) if (c.isDefault) c];
    final mine = [for (final c in cols) if (!c.isDefault) c];
    return AppScaffold(
      contentWidth: ContentWidth.full,
      bottomNavigationBar: const _CollectionsNav(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppLayout.top(64)),
                  _Header(onAdd: () => Navigator.pushNamed(context, AppRoutes.createCategory)),
                  Padding(
                    padding: EdgeInsets.only(left: 58.w),
                    child: Text('Collections', style: AppText.bodyDim.copyWith(fontSize: 13.6.sp)),
                  ),
                  SizedBox(height: 20.h),
                  if (live && cols.isEmpty && ctrl.loading)
                    Text('Loading…', style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5)),
                ],
              ),
            ),
          ),
          if (live) ...[
            if (primary.isNotEmpty) ...[
              _SectionTitle('Primary'),
              _CollectionGrid(collections: primary),
            ],
            _SectionTitle('My collections'),
            if (mine.isEmpty && !ctrl.loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
                  child: Text(
                    'None of your own yet. Tap + to create one, like "Sturgis 2024".',
                    style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5),
                  ),
                ),
              )
            else
              _CollectionGrid(collections: mine),
          ] else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            sliver: SliverGrid(
              gridDelegate: _grid(context),
              delegate: SliverChildBuilderDelegate((context, i) {
                final col = live ? cols[i] : null;
                final poster = Image.asset(_events[i % _events.length], fit: BoxFit.cover);
                final cover = col?.coverImageUrl;
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.eventDetail,
                    arguments: col ?? 'Event ${i + 1}',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.red.withValues(alpha: 0.7)),
                          ),
                          child: cover == null
                              ? poster
                              : Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, _, _) => poster),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        col == null ? 'Event ${i + 1}' : '${col.name} · ${col.itemCount}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.h4.copyWith(fontSize: 14.4.sp),
                      ),
                    ],
                  ),
                );
              }, childCount: count),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppBottomNav.heightOf(context) + 20.h)),
        ],
      ),
    );
  }
}

/// Chips that belong to one collection event.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, this.eventName = 'Event 5', this.collection});

  final String eventName;

  /// A real collection; null shows the seeded event.
  final ApiCollection? collection;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<ChipItem>? _items;

  /// The collection as last saved; replaced after an edit.
  late ApiCollection? _col = widget.collection;

  /// Sub-folders (Shirts / Hats / Cups in Merchandise), refreshed on every load for their counts.
  late List<ApiCollection> _children = widget.collection?.children ?? const [];

  String get eventName => _col?.name ?? widget.eventName;

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<CollectionsController>().client;
    final col = _col;
    if (client == null || col == null) return;
    try {
      final data = await client.get('/api/collections/${col.id}', auth: false) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _items = [
          for (final i in (data['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>()) ChipItem.fromApiItem(i),
        ];
        _children = ApiCollection.fromJson(data).children;
      });
    } on ApiException {
      if (mounted) setState(() => _items = const []);
    }
  }

  /// Edit / Delete for the user's own collections (default ones are locked).
  Future<void> _more() async {
    final col = _col;
    if (col == null) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.sheet,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26.r))),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('collection-edit'),
                leading: Icon(Icons.edit_outlined, color: AppColors.white, size: 22.r),
                title: Text('Edit name, description or cover', style: AppText.body.copyWith(fontSize: 14.sp)),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                key: const Key('collection-delete'),
                leading: Icon(Icons.delete_outline, color: AppColors.red, size: 22.r),
                title: Text('Delete collection', style: AppText.body.copyWith(fontSize: 14.sp, color: AppColors.red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'edit') {
      final saved = await Navigator.pushNamed(context, AppRoutes.createCategory, arguments: col);
      if (mounted && saved is ApiCollection) setState(() => _col = saved);
      return;
    }
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        title: Text('Delete "${col.name}"?', style: AppText.h3),
        content: Text(
          'The collection is removed. The chips in it stay in your profile.',
          style: AppText.bodyDim.copyWith(fontSize: 13.sp),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: AppText.body)),
          TextButton(
            key: const Key('collection-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: AppText.body.copyWith(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (!mounted || sure != true) return;
    final ctrl = context.read<CollectionsController>();
    final messenger = ScaffoldMessenger.of(context);
    if (await ctrl.delete(col.id)) {
      if (mounted) Navigator.pop(context);
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceAlt,
          content: Text(ctrl.error ?? "Couldn't delete the collection.", style: AppText.body.copyWith(fontSize: 12.8.sp)),
        ),
      );
    }
  }

  void _add() {
    final col = _col;
    if (col == null) {
      Navigator.pushNamed(context, AppRoutes.addToCollection);
      return;
    }
    // Same scan -> confirm flow as Add Item, saved into this collection.
    context.read<SellController>().collectionId = col.id;
    Navigator.pushNamed(context, AppRoutes.addItem).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final live = _col != null;
    final items = _items ?? const <ChipItem>[];
    final count = live ? items.length : _eventChips.length;
    // Merchandise holds folders, not chips: chips are added inside Shirts, Hats or Cups.
    final hasSubfolders = _children.isNotEmpty;
    return AppScaffold(
      contentWidth: ContentWidth.full,
      bottomNavigationBar: const _CollectionsNav(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppLayout.top(64)),
                  _Header(onAdd: hasSubfolders ? null : _add, onMore: live && !_col!.isDefault ? _more : null),
                  Padding(
                    padding: EdgeInsets.only(left: 58.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Collections', style: AppText.bodyDim.copyWith(fontSize: 13.6.sp)),
                        SizedBox(height: 3.h),
                        Text(
                          eventName,
                          style: AppText.h5.copyWith(fontSize: 13.6.sp, color: AppColors.red),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  if (live && items.isEmpty && !hasSubfolders)
                    Text(
                      _items == null ? 'Loading…' : _col!.emptyText,
                      style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5),
                    ),
                ],
              ),
            ),
          ),
          if (hasSubfolders) _CollectionGrid(collections: _children, onReturn: _load),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            sliver: SliverGrid(
              gridDelegate: _grid(context),
              delegate: SliverChildBuilderDelegate((context, i) {
                if (live) {
                  final item = items[i];
                  return GestureDetector(
                    // Closing the chip comes back here; reload in case it was deleted or changed.
                    onTap: () => Navigator.pushNamed(context, AppRoutes.itemDetail, arguments: item).then((_) => _load()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: SizedBox(width: double.infinity, child: ChipImage(item))),
                        SizedBox(height: 10.h),
                        Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h4.copyWith(fontSize: 13.6.sp)),
                      ],
                    ),
                  );
                }
                final (image, label) = _eventChips[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.asset(image, fit: BoxFit.cover, width: double.infinity),
                    ),
                    SizedBox(height: 10.h),
                    Text(label, style: AppText.h4.copyWith(fontSize: 13.6.sp)),
                  ],
                );
              }, childCount: count),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppBottomNav.heightOf(context) + 20.h)),
        ],
      ),
    );
  }
}

/// The collection pages keep the tab bar visible, as in the design.
class _CollectionsNav extends StatelessWidget {
  const _CollectionsNav();

  @override
  Widget build(BuildContext context) => const ShellBottomNav(currentIndex: 3);
}

/// Back arrow, owner name and the "+" that opens the matching collection form.
///
/// The "+" is positioned rather than laid out in the row so that adding it
/// leaves the header at exactly the height it has in the design.
class _Header extends StatelessWidget {
  const _Header({this.onAdd, this.onMore});

  /// Null hides the "+" (a folder of sub-folders takes no chips itself).
  final VoidCallback? onAdd;

  /// Shows a "⋯" beside the "+" (Edit / Delete on the user's own collections).
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back, size: 20.8.sp, color: AppColors.white),
            ),
            SizedBox(width: 16.w),
            Text(
              context.select<UserController, String>((u) => u.live ? u.displayName : 'Tom'),
              style: AppText.h1.copyWith(fontSize: 20.5.sp),
            ),
          ],
        ),
        Positioned(
          right: 0,
          top: -6.h,
          child: Row(
            children: [
              if (onMore != null) ...[
                _AddAction(key: const Key('collection-more'), icon: Icons.more_horiz, onTap: onMore!),
                if (onAdd != null) SizedBox(width: 10.w),
              ],
              if (onAdd != null) _AddAction(key: const Key('collection-add'), onTap: onAdd!),
            ],
          ),
        ),
      ],
    );
  }
}

/// The "+" in the collection headers, opening the matching form.
class _AddAction extends StatelessWidget {
  const _AddAction({super.key, required this.onTap, this.icon = Icons.add});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18.4.sp, color: AppColors.redSolid),
      ),
    );
  }
}

/// "Primary" / "My collections" heading above each grid.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppLayout.gutter, 6.h, AppLayout.gutter, 12.h),
        child: Text(title, style: AppText.h3.copyWith(fontSize: 16.sp)),
      ),
    );
  }
}

/// Collection covers with "Name · count", opening the collection.
class _CollectionGrid extends StatelessWidget {
  const _CollectionGrid({required this.collections, this.onReturn});

  final List<ApiCollection> collections;

  /// Called after coming back from a collection, e.g. to refresh counts.
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppLayout.gutter, 0, AppLayout.gutter, 18.h),
      sliver: SliverGrid(
        gridDelegate: _grid(context),
        delegate: SliverChildBuilderDelegate((context, i) {
          final col = collections[i];
          final poster = Image.asset(_events[i % _events.length], fit: BoxFit.cover);
          final cover = col.coverImageUrl;
          return GestureDetector(
            key: Key('collection-${col.id}'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.eventDetail, arguments: col).then((_) => onReturn?.call()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.red.withValues(alpha: 0.7))),
                    child: cover == null
                        ? poster
                        : Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, _, _) => poster),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '${col.name} · ${col.itemCount}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h4.copyWith(fontSize: 14.4.sp),
                ),
              ],
            ),
          );
        }, childCount: collections.length),
      ),
    );
  }
}
