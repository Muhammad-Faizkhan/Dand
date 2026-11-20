import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../controllers/dealers_controller.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_data.dart';
import '../../core/utils/layout.dart';
import '../../models/models.dart';

/// Live dark-tiled map with the dealer pins from the design.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.showBack = true, this.showSearch = true});

  final bool showBack;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DealersController?>();
    final live = ctrl?.client != null;
    if (live) WidgetsBinding.instance.addPostFrameCallback((_) => ctrl!.load());
    final dealers = live ? ctrl!.dealers : AppData.dealers;
    final center = live ? ctrl!.center : const LatLng(40.6939, -74.2807);
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            // Re-centres once the phone's location comes in.
            key: ValueKey(center),
            options: MapOptions(
              initialCenter: center,
              initialZoom: live ? 9.5 : 11.2,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              // OpenStreetMap raster tiles (no API key) inverted to the dark
              // treatment used in the design.
              ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  -0.2126,
                  -0.7152,
                  -0.0722,
                  0,
                  255,
                  -0.2126,
                  -0.7152,
                  -0.0722,
                  0,
                  255,
                  -0.2126,
                  -0.7152,
                  -0.0722,
                  0,
                  255,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dandcollection.app',
                  maxNativeZoom: 19,
                  tileBuilder: (context, widget, tile) => widget,
                ),
              ),
              // Flattens the tiles toward the design's near-black basemap.
              IgnorePointer(child: Container(color: AppColors.black.withValues(alpha: 0.42))),
              MarkerLayer(
                markers: [
                  for (final d in dealers)
                    Marker(
                      point: LatLng(d.lat, d.lng),
                      width: 170.w,
                      height: 62.h,
                      alignment: Alignment.topCenter,
                      child: _DealerPin(dealer: d),
                    ),
                ],
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap',
                    textStyle: TextStyle(
                      fontSize: 9.sp,
                      color: AppColors.white.withValues(alpha: 0.45),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: AppLayout.gutter,
          right: AppLayout.gutter,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(top: AppLayout.top(96)),
              child: Row(
                children: [
                  if (showBack) ...[
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: 44.w,
                        height: 44.w,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back, size: 17.6.sp, color: AppColors.white),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  if (showSearch)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.mapDealers),
                        child: Container(
                          height: 48.h,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 16.sp, color: AppColors.textSecondary),
                              SizedBox(width: 10.w),
                              Text(
                                'Search dealers & shops',
                                style: AppText.bodyDim.copyWith(fontSize: 12.8.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DealerPin extends StatelessWidget {
  const _DealerPin({required this.dealer});

  final Dealer dealer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.mapDealers),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dealer.displayName,
            maxLines: 1,
            style: AppText.h5.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: dealer.closed ? AppColors.white.withValues(alpha: 0.55) : null,
              shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
            ),
          ),
          SizedBox(height: 4.h),
          // Closed dealerships stay on the map, greyed out.
          Icon(Icons.place, size: 24.sp, color: dealer.closed ? AppColors.white.withValues(alpha: 0.35) : AppColors.white),
        ],
      ),
    );
  }
}
