import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/product_filter_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  static const _historyKey = 'search_history';
  static const _maxHistory = 10;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList(_historyKey) ?? [];
    });
  }

  Future<void> _addToHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchHistory.remove(trimmed);
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > _maxHistory) {
      _searchHistory = _searchHistory.sublist(0, _maxHistory);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _searchHistory);
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    setState(() {
      _searchHistory = [];
    });
  }

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
        builder: (context, scrollController) => ProductFilterSheet(
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
              onSubmitted: (value) => _addToHistory(value),
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

  void _performSearch(String term, ProductProvider productProvider) {
    _searchController.text = term;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    productProvider.search(term);
    _addToHistory(term);
  }

  List<String> _getTrendingSearches(ProductProvider productProvider) {
    // Derive from featured products + top available products
    final featured = productProvider.featuredProducts.take(4).map((p) => p.name);
    final available = productProvider.products
        .where((p) => p.isAvailable && !p.isFeatured)
        .take(4)
        .map((p) => p.name);
    final combined = {...featured, ...available}.toList();
    return combined.take(8).toList();
  }

  Widget _buildSuggestions(ProductProvider productProvider) {
    final trending = _getTrendingSearches(productProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: AppTextStyles.h5),
                GestureDetector(
                  onTap: _clearHistory,
                  child: Text(
                    'Clear',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            ..._searchHistory.map((term) {
              return ListTile(
                onTap: () => _performSearch(term, productProvider),
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(
                  Iconsax.clock,
                  size: 18,
                  color: AppColors.textLight,
                ),
                title: Text(term, style: AppTextStyles.bodyMedium),
                trailing: GestureDetector(
                  onTap: () async {
                    setState(() => _searchHistory.remove(term));
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList(_historyKey, _searchHistory);
                  },
                  child: const Icon(
                    Iconsax.close_circle,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSizes.lg),
          ],

          // Trending searches (from actual products)
          Text('Trending', style: AppTextStyles.h5),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trending.map((term) {
              return GestureDetector(
                onTap: () => _performSearch(term, productProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.trend_up,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(term, style: AppTextStyles.labelMedium),
                    ],
                  ),
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
