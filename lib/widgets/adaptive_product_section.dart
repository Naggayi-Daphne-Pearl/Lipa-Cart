import 'package:flutter/material.dart';
import '../core/utils/responsive.dart';
import '../core/constants/app_sizes.dart';

/// Displays products in a horizontal list on mobile and grid on desktop/tablet
class AdaptiveProductSection extends StatelessWidget {
  final List<Widget> products;
  final double itemWidth;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const AdaptiveProductSection({
    super.key,
    required this.products,
    this.itemWidth = 170,
    this.itemHeight = 240,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Show horizontal list on mobile, grid on tablet/desktop
    if (context.isMobile) {
      return SizedBox(
        height: itemHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: padding ??
              EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
          itemBuilder: (context, index) => SizedBox(
            width: itemWidth,
            child: products[index],
          ),
        ),
      );
    }

    // Grid layout for tablet/desktop
    final columns = context.responsive<int>(
      mobile: 2,
      tablet: 3,
      desktop: 4,
      largeDesktop: 5,
    );

    return Padding(
      padding: padding ??
          EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSizes.lg,
          mainAxisSpacing: AppSizes.lg,
          childAspectRatio: itemWidth / itemHeight,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => products[index],
      ),
    );
  }
}
