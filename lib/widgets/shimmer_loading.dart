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
  const ShimmerProductGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

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
  const ShimmerHorizontalRow({
    super.key,
    this.itemCount = 4,
    this.cardWidth = 160,
    this.cardHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) =>
            ShimmerProductCard(width: cardWidth, height: cardHeight),
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

/// Full homepage skeleton that mimics the real layout while products load.
/// Uses soft green shimmer tones (#E8F5E9 / #C8E6C9) for brand feel.
class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  static const _searchH = 52.0;
  static const _editorialH = 340.0; // matches real _buildEditorialHero height
  static const _catSize = 72.0;
  static const _catCount = 6;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8F5E9),
      highlightColor: const Color(0xFFC8E6C9),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting line
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 120, 0),
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 200, 0),
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 14),
            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: _searchH,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 16),
            // Trust strip (3 pills)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Editorial hero — tall card matching real layout
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: _editorialH,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            // Category circles row
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: List.generate(
                    _catCount,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            width: _catSize,
                            height: _catSize,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: _catSize * 0.7,
                            height: 10,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Section title
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 16,
              width: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            // Product grid 2-col
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
