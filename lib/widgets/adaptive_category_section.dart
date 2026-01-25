import 'package:flutter/material.dart';
import '../core/utils/responsive.dart';
import '../core/constants/app_sizes.dart';
import '../models/category.dart';
import 'category_card.dart';

/// Displays categories in a horizontal list on mobile and grid on desktop/tablet
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
    // Show horizontal list on mobile
    if (context.isMobile) {
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

    // Grid layout for tablet/desktop
    final columns = context.responsive<int>(
      mobile: 4,
      tablet: 6,
      desktop: 8,
      largeDesktop: 10,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSizes.md,
          mainAxisSpacing: AppSizes.md,
          childAspectRatio: 0.85,
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
