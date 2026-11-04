import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/routes/app_routes.dart';
import '../models/models.dart';
import 'common.dart';

/// The white-topped listing tile used by Marketplace, Wishlist, Search and
/// the profile grids.
class ChipGridCard extends StatelessWidget {
  const ChipGridCard({
    super.key,
    required this.item,
    this.showDistance = true,
    this.showTypeBadge = true,
    this.showOwner = true,
    this.favourite = false,
    this.onFavourite,
    this.rarityBadge,
    this.onTap,
  });

  final ChipItem item;
  final bool showDistance;
  final bool showTypeBadge;
  final bool showOwner;
  final bool favourite;
  final VoidCallback? onFavourite;
  final String? rarityBadge;
  final VoidCallback? onTap;

  Color get _typeColor => switch (item.type) {
    ListingType.trade => AppColors.redSolid,
    _ => AppColors.green,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.pushNamed(
            context,
            item.isAuction ? AppRoutes.auctionDetail : AppRoutes.itemDetail,
            arguments: item,
          ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: AppColors.surface,
                      child: item.imageUrl != null
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Image.asset(item.image, fit: BoxFit.cover),
                            )
                          : Image.asset(item.image, fit: BoxFit.cover),
                    ),
                  ),
                  if (showDistance)
                    Positioned(
                      left: 8.w,
                      top: 8.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place, size: 9.6.sp, color: AppColors.redSolid),
                            SizedBox(width: 3.w),
                            Text(
                              item.distance,
                              style: AppText.captionBold.copyWith(fontSize: 10.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (showTypeBadge)
                    Positioned(
                      right: 0,
                      top: 8.h,
                      child: StatusBadge(
                        label: item.type.label,
                        background: _typeColor,
                        radius: 8.r,
                        fontSize: 12.5,
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      ),
                    ),
                  if (rarityBadge != null)
                    Positioned(
                      left: 8.w,
                      bottom: 8.h,
                      child: StatusBadge(
                        label: rarityBadge!,
                        background: AppColors.black.withValues(alpha: 0.6),
                        radius: 8.r,
                        fontSize: 12,
                        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                      ),
                    ),
                  if (onFavourite != null)
                    Positioned(
                      right: 8.w,
                      top: 8.h,
                      child: GestureDetector(
                        onTap: onFavourite,
                        child: Container(
                          width: 34.w,
                          height: 34.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            favourite ? Icons.favorite : Icons.favorite_border,
                            size: 14.4.sp,
                            color: favourite ? AppColors.redSolid : AppColors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 9.h, 12.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.h4.copyWith(fontSize: 13.2.sp),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showOwner)
                        Expanded(
                          child: Text(
                            item.owner,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyDim.copyWith(fontSize: 12.sp),
                          ),
                        ),
                      Text(
                        item.isAuction && !showOwner
                            ? '${item.priceLabel} · ${item.bids} bids'
                            : item.priceLabel,
                        style: AppText.price.copyWith(fontSize: 12.8.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
