import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive.dart';
import '../models/category.dart';
import 'app_loading_indicator.dart';

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
      return Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  // Get a softer background color based on category
  Color get categoryBgColor {
    final baseColor = categoryColor;
    return Color.lerp(baseColor, AppColors.white, 0.85) ??
        baseColor.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard();
    }
    return _buildFullCard();
  }

  Widget _buildCompactCard() {
    return Builder(
      builder: (context) {
        final cardSize = context.responsive<double>(
          mobile: 52.0,
          tablet: 60.0,
          desktop: 68.0,
        );

        return GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: cardSize + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced circular container with gradient and shadow
                Container(
                  width: cardSize,
                  height: cardSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryBgColor,
                        Color.lerp(categoryBgColor, categoryColor, 0.1)!,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.15),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: CachedNetworkImage(
                        imageUrl: category.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: AppLoadingIndicator.small(),
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
                const SizedBox(height: 6),
                // Category name with better typography
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: context.responsive<double>(
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C2C2C),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryBgColor,
              Color.lerp(categoryBgColor, categoryColor, 0.08)!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image with padding
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: category.image,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: AppLoadingIndicator.small(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: categoryBgColor,
                      child: Icon(
                        Icons.category_outlined,
                        color: categoryColor,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Enhanced gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${category.productCount} items',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 14,
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
