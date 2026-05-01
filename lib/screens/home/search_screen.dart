import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/adaptive_page_scaffold.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_filter_sheet.dart';
import '../../widgets/search_bar_widget.dart';

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

    return AdaptivePageScaffold(
      title: 'Search',
      subtitle:
          'Find groceries quickly with a dedicated mobile and desktop search layout.',
      currentIndex: 1,
      desktopActiveSection: 'browse',
      onBack: () {
        productProvider.clearSearch();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/customer/home');
        }
      },
      actions: [
        if (_searchController.text.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _showFilterBottomSheet(context, productProvider),
            icon: const Icon(Iconsax.filter, size: 16),
            label: const Text('Filters'),
          ),
      ],
      mobileBody: _buildPageBody(
        context,
        productProvider,
        cartProvider,
        isDesktop: false,
      ),
      desktopBody: _buildPageBody(
        context,
        productProvider,
        cartProvider,
        isDesktop: true,
      ),
    );
  }

  Widget _buildPageBody(
    BuildContext context,
    ProductProvider productProvider,
    CartProvider cartProvider, {
    required bool isDesktop,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.horizontalPadding,
            0,
            context.horizontalPadding,
            AppSizes.md,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 720 : double.infinity,
              ),
              child: SearchBarWidget(
                controller: _searchController,
                autofocus: true,
                hintText: 'Search for groceries...',
                onChanged: (value) {
                  productProvider.search(value);
                  setState(() {});
                },
                onSubmitted: (value) => _addToHistory(value),
                onClear: () {
                  productProvider.clearSearch();
                  setState(() {});
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildContent(
            context,
            productProvider,
            cartProvider,
            isDesktop: isDesktop,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProductProvider productProvider,
    CartProvider cartProvider, {
    required bool isDesktop,
  }) {
    if (_searchController.text.isEmpty) {
      return _buildSuggestions(productProvider, isDesktop: isDesktop);
    }

    if (productProvider.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
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
                'We couldn\'t find that',
                style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'We couldn\'t find that - try fresh fruit or rice',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.lg),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: ['fresh fruit', 'rice', 'eggs', 'milk', 'bread'].map((term) {
                  return GestureDetector(
                    onTap: () {
                      _performSearch(term, productProvider);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        term,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
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
          tablet: 0.75,
          desktop: 0.84,
          largeDesktop: 0.88,
        ),
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
    setState(() {});
  }

  List<String> _getTrendingSearches(ProductProvider productProvider) {
    final featured = productProvider.featuredProducts
        .take(4)
        .map((p) => p.name);
    final available = productProvider.products
        .where((p) => p.isAvailable && !p.isFeatured)
        .take(4)
        .map((p) => p.name);
    final combined = {...featured, ...available}.toList();
    return combined.take(8).toList();
  }

  Widget _buildSuggestions(
    ProductProvider productProvider, {
    bool isDesktop = false,
  }) {
    final trending = _getTrendingSearches(productProvider);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );

    if (!isDesktop) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          context.horizontalPadding,
          0,
          context.horizontalPadding,
          AppSizes.xl,
        ),
        child: content,
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        0,
        context.horizontalPadding,
        AppSizes.xxl,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: AppColors.shadowSm,
        ),
        child: content,
      ),
    );
  }
}
