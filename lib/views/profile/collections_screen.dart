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
    return AppScaffold(
      contentWidth: ContentWidth.wide,
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
                  if (live && cols.isEmpty)
                    Text(
                      ctrl.loading ? 'Loading…' : 'No collections yet. Tap + to create one, like "Sturgis 2024".',
                      style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            sliver: SliverGrid(
              gridDelegate: responsiveGridDelegate(
                context,
                tileDesign: const Size(155, 196),
                spacing: 16,
                runSpacing: 18,
              ),
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

  String get eventName => widget.collection?.name ?? widget.eventName;

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<CollectionsController>().client;
    final col = widget.collection;
    if (client == null || col == null) return;
    try {
      final data = await client.get('/api/collections/${col.id}', auth: false) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _items = [
          for (final i in (data['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>()) ChipItem.fromApiItem(i),
        ];
      });
    } on ApiException {
      if (mounted) setState(() => _items = const []);
    }
  }

  void _add() {
    final col = widget.collection;
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
    final live = widget.collection != null;
    final items = _items ?? const <ChipItem>[];
    final count = live ? items.length : _eventChips.length;
    return AppScaffold(
      contentWidth: ContentWidth.wide,
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
                  _Header(onAdd: _add),
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
                  if (live && items.isEmpty)
                    Text(
                      _items == null ? 'Loading…' : 'No chips in this collection yet. Tap + to scan one in.',
                      style: AppText.bodyDim.copyWith(fontSize: 13.6.sp, height: 1.5),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppLayout.gutter),
            sliver: SliverGrid(
              gridDelegate: responsiveGridDelegate(
                context,
                tileDesign: const Size(155, 196),
                spacing: 16,
                runSpacing: 18,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
                if (live) {
                  final item = items[i];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.itemDetail, arguments: item),
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
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

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
          child: _AddAction(onTap: onAdd),
        ),
      ],
    );
  }
}

/// The "+" in the collection headers, opening the matching form.
class _AddAction extends StatelessWidget {
  const _AddAction({required this.onTap});

  final VoidCallback onTap;

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
        child: Icon(Icons.add, size: 18.4.sp, color: AppColors.redSolid),
      ),
    );
  }
}
