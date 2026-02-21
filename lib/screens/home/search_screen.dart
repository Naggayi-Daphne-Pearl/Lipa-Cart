import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/app_bottom_nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(
    BuildContext context,
    ProductProvider productProvider,
  ) {
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
        builder: (context, scrollController) => _FilterSheet(
          scrollController: scrollController,
          productProvider: productProvider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            productProvider.clearSearch();
            Navigator.pop(context);
          },
        ),
        title: const Text('Search'),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Iconsax.filter),
              onPressed: () => _showFilterBottomSheet(context, productProvider),
              tooltip: 'Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: SearchBarWidget(
              controller: _searchController,
              autofocus: true,
              hintText: 'Search for groceries...',
              onChanged: (value) => productProvider.search(value),
              onClear: () => productProvider.clearSearch(),
            ),
          ),

          // Results
          Expanded(child: _buildContent(productProvider, cartProvider)),
        ],
      ),
    );
  }

  Widget _buildContent(
    ProductProvider productProvider,
    CartProvider cartProvider,
  ) {
    if (_searchController.text.isEmpty) {
      // Show recent searches or popular items
      return _buildSuggestions(productProvider);
    }

    if (productProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.search_normal,
              size: 64,
              color: AppColors.neutralGrey,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No products found',
              style: AppTextStyles.h5.copyWith(color: AppColors.textMedium),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Try a different search term',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSizes.md,
        crossAxisSpacing: AppSizes.md,
        childAspectRatio: 0.72,
      ),
      itemCount: productProvider.searchResults.length,
      itemBuilder: (context, index) {
        final product = productProvider.searchResults[index];
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
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSuggestions(ProductProvider productProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular Searches', style: AppTextStyles.h5),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                  'Tomatoes',
                  'Milk',
                  'Eggs',
                  'Rice',
                  'Bananas',
                  'Onions',
                  'Fish',
                  'Avocado',
                ].map((term) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = term;
                      productProvider.search(term);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
                        border: Border.all(color: AppColors.lightGrey),
                      ),
                      child: Text(term, style: AppTextStyles.labelMedium),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: AppSizes.xl),
          Text('Browse Categories', style: AppTextStyles.h5),
          const SizedBox(height: AppSizes.md),
          ...productProvider.categories.map((category) {
            return ListTile(
              onTap: () => context.push('/customer/category', extra: category),
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  Iconsax.category,
                  color: AppColors.primaryOrange,
                ),
              ),
              title: Text(category.name, style: AppTextStyles.labelMedium),
              subtitle: Text(
                '${category.productCount} items',
                style: AppTextStyles.caption,
              ),
              trailing: const Icon(
                Iconsax.arrow_right_3,
                size: 20,
                color: AppColors.textLight,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ScrollController scrollController;
  final ProductProvider productProvider;

  const _FilterSheet({
    required this.scrollController,
    required this.productProvider,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _minPrice;
  late double _maxPrice;
  late double _minRating;
  late bool _inStockOnly;

  @override
  void initState() {
    super.initState();
    _minPrice = widget.productProvider.selectedMinPrice;
    _maxPrice = widget.productProvider.selectedMaxPrice;
    _minRating = widget.productProvider.minRating;
    _inStockOnly = widget.productProvider.inStockOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.lightGrey),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: AppTextStyles.h4),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = widget.productProvider.minPrice;
                      _maxPrice = widget.productProvider.maxPrice;
                      _minRating = 0;
                      _inStockOnly = false;
                    });
                    widget.productProvider.resetFilters();
                  },
                  child: Text(
                    'Reset',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Filters content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                // Price Range Filter
                Text('Price Range', style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'UGX ${_minPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.labelSmall,
                          ),
                          Text(
                            'UGX ${_maxPrice.toStringAsFixed(0)}',
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      RangeSlider(
                        values: RangeValues(_minPrice, _maxPrice),
                        min: 0,
                        max: 1000000,
                        divisions: 100,
                        labels: RangeLabels(
                          'UGX ${_minPrice.toStringAsFixed(0)}',
                          'UGX ${_maxPrice.toStringAsFixed(0)}',
                        ),
                        activeColor: AppColors.primaryOrange,
                        inactiveColor: AppColors.lightGrey,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _minPrice = values.start;
                            _maxPrice = values.end;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Rating Filter
                Text('Minimum Rating', style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          final rating = index.toDouble();
                          final isSelected = _minRating == rating;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _minRating = rating);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: AppSizes.xs,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusXs),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : AppColors.lightGrey,
                                ),
                              ),
                              child: Text(
                                index == 0 ? 'All' : '$index★',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isSelected
                                      ? AppColors.surface
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Stock Only Filter
                Text('Availability', style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                  child: CheckboxListTile(
                    value: _inStockOnly,
                    onChanged: (value) {
                      setState(() => _inStockOnly = value ?? false);
                    },
                    title: Text(
                      'In Stock Only',
                      style: AppTextStyles.labelMedium,
                    ),
                    activeColor: AppColors.primaryOrange,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Apply button
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.lightGrey),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.productProvider.setPriceRange(_minPrice, _maxPrice);
                  widget.productProvider.setMinRating(_minRating);
                  widget.productProvider.setInStockOnly(_inStockOnly);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
