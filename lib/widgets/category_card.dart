import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
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
          mobile: 80.0,
          tablet: 72.0,
          desktop: 80.0,
        );

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const labelHeight = 20.0;
              const gap = 6.0;

              final imageSize = constraints.hasBoundedHeight
                  ? (constraints.maxHeight - labelHeight - gap)
                        .clamp(42.0, cardSize)
                        .toDouble()
                  : cardSize;

              return SizedBox(
                width: cardSize + 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Keep 80px target when space allows, shrink in tight rows.
                    ClipOval(
                      child: SizedBox(
                        width: imageSize,
                        height: imageSize,
                        child: CachedNetworkImage(
                          imageUrl: category.image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.grey100,
                            alignment: Alignment.center,
                            child: const AppLoadingIndicator.small(),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.grey100,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.category_outlined,
                              color: AppColors.textTertiary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: gap),
                    SizedBox(
                      height: labelHeight,
                      child: Text(
                        category.name,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
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
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: AppLoadingIndicator.small()),
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
                padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.black.withValues(alpha: 0.76),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.name,
                            style: AppTextStyles.cardTitle.copyWith(
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.1,
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
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
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 13,
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
