import 'package:flutter/material.dart';

import '../core/constants/app_sizes.dart';
import '../core/utils/responsive.dart';
import '../models/category.dart';
import 'category_card.dart';

/// Keeps mobile and desktop category layouts separated for easier maintenance.
class AdaptiveCategorySection extends StatelessWidget {
  final List<Category> categories;
  final Function(Category) onCategoryTap;

  const AdaptiveCategorySection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return _MobileCategoryScroller(
        categories: categories,
        onCategoryTap: onCategoryTap,
      );
    }

    return _DesktopCategoryGrid(
      categories: categories,
      onCategoryTap: onCategoryTap,
    );
  }
}

class _MobileCategoryScroller extends StatelessWidget {
  final List<Category> categories;
  final Function(Category) onCategoryTap;

  const _MobileCategoryScroller({
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryCard(
            category: category,
            isCompact: true,
            onTap: () => onCategoryTap(category),
          );
        },
      ),
    );
  }
}

class _DesktopCategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final Function(Category) onCategoryTap;

  const _DesktopCategoryGrid({
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxCrossAxisExtent = context.responsive<double>(
      mobile: 120,
      tablet: 150,
      desktop: 170,
      largeDesktop: 180,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          mainAxisExtent: context.isDesktop ? 122 : 110,
          crossAxisSpacing: context.isDesktop ? AppSizes.lg : AppSizes.md,
          mainAxisSpacing: context.isDesktop ? AppSizes.lg : AppSizes.md,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryCard(
            category: category,
            isCompact: true,
            onTap: () => onCategoryTap(category),
          );
        },
      ),
    );
  }
}
