import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import 'app_product_skeleton.dart';
import 'app_skeleton.dart';

/// Full Home Screen Shimmer Skeleton
class AppHomeSkeleton extends StatelessWidget {
  const AppHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeleton(width: 80, height: 12),
                  SizedBox(height: 6),
                  AppSkeleton(width: 140, height: 20),
                ],
              ),
              Row(
                children: const [
                  AppSkeleton.circle(size: 40),
                  SizedBox(width: 8),
                  AppSkeleton.circle(size: 40),
                ],
              ),
            ],
          ),
          AppSpacing.vSpaceLg,

          // Hero Banner Skeleton
          const AppSkeleton(
            height: 180,
            width: double.infinity,
            borderRadius: AppRadius.radiusLg,
          ),
          AppSpacing.vSpaceXl,

          // Filter Chips Skeleton
          Row(
            children: const [
              AppSkeleton(width: 70, height: 32, borderRadius: AppRadius.radiusPill),
              SizedBox(width: 8),
              AppSkeleton(width: 90, height: 32, borderRadius: AppRadius.radiusPill),
              SizedBox(width: 8),
              AppSkeleton(width: 80, height: 32, borderRadius: AppRadius.radiusPill),
            ],
          ),
          AppSpacing.vSpaceXl,

          // Featured Section Skeleton
          const AppSkeleton(width: 130, height: 18),
          AppSpacing.vSpaceMd,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: const [
                AppProductCardSkeleton(),
                SizedBox(width: 12),
                AppProductCardSkeleton(),
              ],
            ),
          ),
          AppSpacing.vSpaceXl,

          // Popular Section Skeleton
          const AppSkeleton(width: 150, height: 18),
          AppSpacing.vSpaceMd,
          const AppProductListCardSkeleton(),
          AppSpacing.vSpaceSm,
          const AppProductListCardSkeleton(),
        ],
      ),
    );
  }
}
