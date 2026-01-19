import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_sizes.dart';
import '../models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final bool isCompact;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.isCompact = false,
  });

  Color get categoryColor {
    try {
      return Color(
        int.parse(category.color.replaceFirst('#', '0xFF')),
      );
    } catch (_) {
      return AppColors.primary;
    }
  }

  // Get a softer background color based on category
  Color get categoryBgColor {
    final baseColor = categoryColor;
    return Color.lerp(baseColor, AppColors.white, 0.85) ?? baseColor.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard();
    }
    return _buildFullCard();
  }

  Widget _buildCompactCard() {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular container with soft background
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: categoryBgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: categoryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CachedNetworkImage(
                    imageUrl: category.image,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: categoryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.category_outlined,
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            // Category name
            Text(
              category.name,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: categoryBgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        child: Stack(
          children: [
            // Image with padding
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: CachedNetworkImage(
                    imageUrl: category.image,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: categoryBgColor,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: categoryBgColor,
                      child: Icon(
                        Icons.category_outlined,
                        color: categoryColor,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Soft gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSizes.radiusXl),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${category.productCount} items',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
