import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/adaptive_page_scaffold.dart';
import '../../widgets/category_card.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_filter_sheet.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return AdaptivePageScaffold(
      title: 'Browse by Category',
      subtitle:
          'Explore fresh aisles and jump into the section you want faster.',
      currentIndex: 1,
      desktopActiveSection: 'browse',
      mobileBody: _buildCategoriesGrid(context, productProvider),
      desktopBody: _buildCategoriesGrid(
        context,
        productProvider,
        isDesktop: true,
      ),
    );
  }

  Widget _buildCategoriesGrid(
    BuildContext context,
    ProductProvider productProvider, {
    bool isDesktop = false,
  }) {
    final columns = context.responsive<int>(
      mobile: 2,
      tablet: 3,
      desktop: 5,
      largeDesktop: 6,
    );

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        0,
        context.horizontalPadding,
        context.responsive<double>(
          mobile: AppSizes.xl,
          tablet: AppSizes.xl,
          desktop: AppSizes.xxl,
        ),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: isDesktop ? AppSizes.lg : AppSizes.md,
        crossAxisSpacing: isDesktop ? AppSizes.lg : AppSizes.md,
        childAspectRatio: context.responsive<double>(
          mobile: 0.84,
          tablet: 0.92,
          desktop: 0.94,
          largeDesktop: 0.98,
        ),
      ),
      itemCount: productProvider.categories.length,
      itemBuilder: (context, index) {
        final category = productProvider.categories[index];
        return CategoryCard(
          category: category,
          onTap: () => context.push('/customer/category', extra: category),
        );
      },
    );
  }
}

class CategoryProductsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();
    final products = productProvider.getFilteredProductsByCategory(categoryId);

    void showFilterSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => ProductFilterSheet(
            scrollController: scrollController,
            productProvider: productProvider,
          ),
        ),
      );
    }

    return AdaptivePageScaffold(
      title: categoryName,
      subtitle:
          'Scan products faster with a wider desktop grid and easier filter access.',
      currentIndex: 1,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/customer/categories');
        }
      },
      actions: [
        OutlinedButton.icon(
          onPressed: showFilterSheet,
          icon: const Icon(Iconsax.filter, size: 16),
          label: const Text('Filters'),
        ),
      ],
      mobileBody: _buildProductsBody(
        context,
        productProvider,
        cartProvider,
        products,
        showFilterSheet,
      ),
      desktopBody: _buildProductsBody(
        context,
        productProvider,
        cartProvider,
        products,
        showFilterSheet,
        isDesktop: true,
      ),
    );
  }

  Widget _buildProductsBody(
    BuildContext context,
    ProductProvider productProvider,
    CartProvider cartProvider,
    List<Product> products,
    VoidCallback showFilterSheet, {
    bool isDesktop = false,
  }) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.box_1, size: 64, color: AppColors.neutralGrey),
            const SizedBox(height: AppSizes.md),
            Text(
              'No products in this category',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.horizontalPadding,
            vertical: AppSizes.sm,
          ),
          child: Row(
            children: [
              Text(
                '${products.length} product${products.length == 1 ? '' : 's'}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const Spacer(),
              if (productProvider.hasActiveFilters)
                TextButton.icon(
                  onPressed: () => productProvider.resetFilters(),
                  icon: const Icon(
                    Iconsax.close_circle,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  label: Text(
                    'Clear filters',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (!isDesktop)
                TextButton.icon(
                  onPressed: showFilterSheet,
                  icon: const Icon(
                    Iconsax.filter,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  label: Text(
                    'Filters',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              0,
              context.horizontalPadding,
              context.responsive<double>(
                mobile: AppSizes.lg,
                tablet: AppSizes.xl,
                desktop: AppSizes.xxl,
              ),
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.responsive<int>(
                mobile: 2,
                tablet: 3,
                desktop: 5,
                largeDesktop: 6,
              ),
              mainAxisSpacing: isDesktop ? AppSizes.lg : AppSizes.md,
              crossAxisSpacing: isDesktop ? AppSizes.lg : AppSizes.md,
              childAspectRatio: context.responsive<double>(
                mobile: 0.72,
                tablet: 0.74,
                desktop: 0.84,
                largeDesktop: 0.88,
              ),
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                isInCart: cartProvider.isInCart(product.id),
                onTap: () => context.push('/customer/product', extra: product),
                onAddToCart: () {
                  if (cartProvider.isInCart(product.id)) {
                    cartProvider.removeFromCart(product.id);
                  } else {
                    cartProvider.addToCart(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
