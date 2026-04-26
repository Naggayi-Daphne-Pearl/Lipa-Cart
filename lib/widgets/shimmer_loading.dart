import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_sizes.dart';

/// Shimmer placeholder for a product card in a horizontal scroll.
class ShimmerProductCard extends StatelessWidget {
  final double width;
  final double height;
  const ShimmerProductCard({super.key, this.width = 160, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: AppSizes.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a product grid.
class ShimmerProductGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  const ShimmerProductGrid({super.key, this.itemCount = 6, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSizes.md,
        mainAxisSpacing: AppSizes.md,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.grey200,
          highlightColor: AppColors.grey100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer placeholder for a horizontal product row.
class ShimmerHorizontalRow extends StatelessWidget {
  final int itemCount;
  final double cardWidth;
  final double cardHeight;
  const ShimmerHorizontalRow({super.key, this.itemCount = 4, this.cardWidth = 160, this.cardHeight = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) => ShimmerProductCard(width: cardWidth, height: cardHeight),
      ),
    );
  }
}

/// Shimmer placeholder for one row in an admin desktop table
/// (image thumb + name/sub + price + action buttons).
class ShimmerAdminTableRow extends StatelessWidget {
  const ShimmerAdminTableRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 14, width: 180, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, color: Colors.white),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(height: 14, width: 80, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical list of admin table row skeletons.
class ShimmerAdminTable extends StatelessWidget {
  final int count;
  const ShimmerAdminTable({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (_, __) => const ShimmerAdminTableRow(),
    );
  }
}

/// Shimmer placeholder for one admin recipe card (image header + title).
class ShimmerAdminRecipeCard extends StatelessWidget {
  const ShimmerAdminRecipeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 140, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a list item (e.g., cart item, order item).
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 120, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
