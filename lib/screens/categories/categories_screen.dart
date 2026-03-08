import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/category_card.dart';
import '../../widgets/product_card.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/product_filter_sheet.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer/home');
            }
          },
        ),
        title: const Text('Categories'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSizes.md,
          crossAxisSpacing: AppSizes.md,
          childAspectRatio: 1.1,
        ),
        itemCount: productProvider.categories.length,
        itemBuilder: (context, index) {
          final category = productProvider.categories[index];
          return CategoryCard(
            category: category,
            onTap: () => context.push('/customer/category', extra: category),
          );
        },
      ),
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

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer/categories');
            }
          },
        ),
        title: Text(categoryName),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: showFilterSheet,
            tooltip: 'Filters',
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.box_1,
                    size: 64,
                    color: AppColors.neutralGrey,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'No products in this category',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Results count header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
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
                      else
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
                // Product grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      0,
                      AppSizes.md,
                      AppSizes.md,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSizes.md,
                          crossAxisSpacing: AppSizes.md,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        isInCart: cartProvider.isInCart(product.id),
                        onTap: () =>
                            context.push('/customer/product', extra: product),
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
            ),
    );
  }
}
