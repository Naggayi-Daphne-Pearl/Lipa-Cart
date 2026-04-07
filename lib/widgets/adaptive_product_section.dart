import 'package:flutter/material.dart';

import '../core/constants/app_sizes.dart';
import '../core/utils/responsive.dart';

/// Keeps mobile and desktop product layouts separated for easier maintenance.
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
    if (context.isMobile) {
      return _MobileProductScroller(
        products: products,
        itemWidth: itemWidth,
        itemHeight: itemHeight,
        padding: padding,
      );
    }

    return _DesktopProductGrid(
      products: products,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      padding: padding,
    );
  }
}

class _MobileProductScroller extends StatelessWidget {
  final List<Widget> products;
  final double itemWidth;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const _MobileProductScroller({
    required this.products,
    required this.itemWidth,
    required this.itemHeight,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            padding ??
            EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
        itemBuilder: (context, index) =>
            SizedBox(width: itemWidth, child: products[index]),
      ),
    );
  }
}

class _DesktopProductGrid extends StatelessWidget {
  final List<Widget> products;
  final double itemWidth;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const _DesktopProductGrid({
    required this.products,
    required this.itemWidth,
    required this.itemHeight,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final maxCrossAxisExtent = context.responsive<double>(
      mobile: itemWidth,
      tablet: 210,
      desktop: 230,
      largeDesktop: 240,
    );
    final childAspectRatio = itemWidth / itemHeight;

    return Padding(
      padding:
          padding ??
          EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: context.isDesktop ? AppSizes.xl : AppSizes.lg,
          mainAxisSpacing: context.isDesktop ? AppSizes.xl : AppSizes.lg,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => products[index],
      ),
    );
  }
}
