import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/app_loading_indicator.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  String? _selectedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // name, price_low, price_high

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredProducts(ProductProvider productProvider) {
    List<Product> products = productProvider.products;

    // Filter by category
    if (_selectedCategoryId != null) {
      products = products
          .where((p) => p.categoryId == _selectedCategoryId)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        products.sort((a, b) => a.name.compareTo(b.name));
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();
    final filteredProducts = _getFilteredProducts(productProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveContainer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.horizontalPadding,
                  context.responsive<double>(
                    mobile: AppSizes.md,
                    tablet: AppSizes.lg,
                    desktop: AppSizes.xl,
                  ),
                  context.horizontalPadding,
                  AppSizes.sm,
                ),
                child: Text(
                  'Browse Products',
                  style: AppTextStyles.screenTitle.copyWith(
                    fontSize: context.responsive<double>(
                      mobile: 26.0,
                      tablet: 30.0,
                      desktop: 34.0,
                    ),
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                ),
                child: Container(
                  height: context.responsive<double>(
                    mobile: 52.0,
                    tablet: 56.0,
                    desktop: 60.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      context.responsive<double>(
                        mobile: AppSizes.radiusLg,
                        tablet: 14.0,
                        desktop: 16.0,
                      ),
                    ),
                    border: Border.all(color: AppColors.grey200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: context.responsive<double>(
                        mobile: 14.0,
                        tablet: 15.0,
                        desktop: 16.0,
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search for groceries, fruits, vegetables...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: context.responsive<double>(
                          mobile: 14.0,
                          tablet: 15.0,
                          desktop: 16.0,
                        ),
                      ),
                      prefixIcon: Icon(
                        Iconsax.search_normal,
                        color: AppColors.textSecondary,
                        size: context.responsive<double>(
                          mobile: 20.0,
                          tablet: 22.0,
                          desktop: 24.0,
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Iconsax.close_circle5,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.responsive<double>(
                          mobile: AppSizes.md,
                          tablet: AppSizes.lg,
                          desktop: 20.0,
                        ),
                        vertical: AppSizes.md,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: context.responsive<double>(
                  mobile: AppSizes.md,
                  tablet: AppSizes.lg,
                  desktop: AppSizes.lg,
                ),
              ),

              // Category Pills
              SizedBox(
                height: context.responsive<double>(
                  mobile: 44.0,
                  tablet: 48.0,
                  desktop: 52.0,
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  itemCount: productProvider.categories.length + 1,
                  separatorBuilder: (_, __) => SizedBox(
                    width: context.responsive<double>(
                      mobile: AppSizes.sm,
                      tablet: AppSizes.md,
                      desktop: AppSizes.md,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final allItemsCount = productProvider.products.length;
                      return _buildCategoryPill(
                        context: context,
                        label: 'All Items',
                        icon: Iconsax.element_4,
                        count: allItemsCount,
                        isSelected: _selectedCategoryId == null,
                        onTap: () => setState(() => _selectedCategoryId = null),
                      );
                    }
                    final category = productProvider.categories[index - 1];
                    final categoryCount = productProvider.products
                        .where((p) => p.categoryId == category.id)
                        .length;
                    return _buildCategoryPill(
                      context: context,
                      label: category.name,
                      icon: _getCategoryIcon(category.name),
                      count: categoryCount,
                      isSelected: _selectedCategoryId == category.id,
                      onTap: () =>
                          setState(() => _selectedCategoryId = category.id),
                    );
                  },
                ),
              ),
              SizedBox(
                height: context.responsive<double>(
                  mobile: AppSizes.md,
                  tablet: AppSizes.lg,
                  desktop: AppSizes.xl,
                ),
              ),

              // Results count and sort
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredProducts.length} ${filteredProducts.length == 1 ? 'item' : 'items'} available',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: context.responsive<double>(
                          mobile: 13.0,
                          tablet: 14.0,
                          desktop: 15.0,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => setState(() => _sortBy = value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'name',
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.text,
                                size: 16,
                                color: _sortBy == 'name'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Name',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _sortBy == 'name'
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'price_low',
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.arrow_down,
                                size: 16,
                                color: _sortBy == 'price_low'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Price: Low to High',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _sortBy == 'price_low'
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'price_high',
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.arrow_up_1,
                                size: 16,
                                color: _sortBy == 'price_high'
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Price: High to Low',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _sortBy == 'price_high'
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.sort,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _sortBy == 'name'
                                  ? 'Name'
                                  : _sortBy == 'price_low'
                                  ? 'Price ↑'
                                  : 'Price ↓',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              // Products Grid
              Expanded(
                child: filteredProducts.isEmpty
                    ? _buildEmptyState(context)
                    : GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalPadding,
                          vertical: context.responsive<double>(
                            mobile: AppSizes.sm,
                            tablet: AppSizes.md,
                            desktop: AppSizes.lg,
                          ),
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: context.responsive<int>(
                            mobile: 2,
                            tablet: 3,
                            desktop: 5,
                            largeDesktop: 6,
                          ),
                          mainAxisSpacing: context.responsive<double>(
                            mobile: AppSizes.md,
                            tablet: AppSizes.lg,
                            desktop: 20.0,
                          ),
                          crossAxisSpacing: context.responsive<double>(
                            mobile: AppSizes.md,
                            tablet: AppSizes.lg,
                            desktop: 20.0,
                          ),
                          childAspectRatio: context.responsive<double>(
                            mobile: 0.68,
                            tablet: 0.73,
                            desktop: 0.78,
                          ),
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductCard(
                            context,
                            product,
                            cartProvider,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive<double>(
            mobile: AppSizes.md,
            tablet: AppSizes.lg,
            desktop: 18.0,
          ),
          vertical: context.responsive<double>(
            mobile: AppSizes.sm,
            tablet: 10.0,
            desktop: 12.0,
          ),
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFF8C42), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.grey200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.responsive<double>(
                mobile: 18.0,
                tablet: 20.0,
                desktop: 22.0,
              ),
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: context.responsive<double>(
                  mobile: 13.0,
                  tablet: 14.0,
                  desktop: 15.0,
                ),
              ),
            ),
            if (context.isTablet || context.isDesktop) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  count.toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Product product,
    CartProvider cartProvider,
  ) {
    final isInCart = cartProvider.isInCart(product.id);

    return GestureDetector(
      onTap: () => context.push('/customer/product', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            context.responsive<double>(
              mobile: AppSizes.radiusLg,
              tablet: AppSizes.radiusXl,
              desktop: 20.0,
            ),
          ),
          border: Border.all(
            color: AppColors.grey200.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: context.responsive<double>(
                mobile: 8.0,
                tablet: 12.0,
                desktop: 16.0,
              ),
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: context.responsive<double>(
                mobile: 4.0,
                tablet: 6.0,
                desktop: 8.0,
              ),
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(
                          context.responsive<double>(
                            mobile: AppSizes.radiusLg,
                            tablet: AppSizes.radiusXl,
                            desktop: 20.0,
                          ),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(
                          context.responsive<double>(
                            mobile: AppSizes.radiusLg,
                            tablet: AppSizes.radiusXl,
                            desktop: 20.0,
                          ),
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.grey100,
                          child: const Center(
                            child: AppLoadingIndicator.small(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.grey100,
                          child: Icon(
                            Iconsax.image,
                            color: AppColors.grey400,
                            size: context.responsive<double>(
                              mobile: 32.0,
                              tablet: 40.0,
                              desktop: 48.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive<double>(
                    mobile: 10.0,
                    tablet: AppSizes.lg,
                    desktop: 16.0,
                  ),
                  vertical: context.responsive<double>(
                    mobile: 8.0,
                    tablet: AppSizes.md,
                    desktop: 12.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: context.responsive<double>(
                          mobile: 13.0,
                          tablet: 15.0,
                          desktop: 16.0,
                        ),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'per ${product.unit}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.responsive<double>(
                          mobile: 11.0,
                          tablet: 13.0,
                          desktop: 13.0,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            Formatters.formatCurrency(product.price),
                            style: AppTextStyles.priceMedium.copyWith(
                              color: AppColors.primary,
                              fontSize: context.responsive<double>(
                                mobile: 14.0,
                                tablet: 17.0,
                                desktop: 18.0,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (isInCart) {
                              cartProvider.removeFromCart(product.id);
                            } else {
                              cartProvider.addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Iconsax.tick_circle5,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${product.name} added to cart',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMd,
                                    ),
                                  ),
                                  duration: const Duration(milliseconds: 1500),
                                ),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: context.responsive<double>(
                              mobile: 32.0,
                              tablet: 40.0,
                              desktop: 44.0,
                            ),
                            height: context.responsive<double>(
                              mobile: 32.0,
                              tablet: 40.0,
                              desktop: 44.0,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isInCart
                                    ? [
                                        AppColors.success,
                                        AppColors.success.withValues(
                                          alpha: 0.8,
                                        ),
                                      ]
                                    : [
                                        AppColors.primary,
                                        AppColors.primary.withValues(
                                          alpha: 0.85,
                                        ),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isInCart
                                              ? AppColors.success
                                              : AppColors.primary)
                                          .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              isInCart ? Iconsax.tick_circle5 : Iconsax.add,
                              color: Colors.white,
                              size: context.responsive<double>(
                                mobile: 18.0,
                                tablet: 20.0,
                                desktop: 22.0,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: context.responsive<double>(
                mobile: 100.0,
                tablet: 120.0,
                desktop: 140.0,
              ),
              height: context.responsive<double>(
                mobile: 100.0,
                tablet: 120.0,
                desktop: 140.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.box_search,
                size: context.responsive<double>(
                  mobile: 48.0,
                  tablet: 56.0,
                  desktop: 64.0,
                ),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              'No products found',
              style: AppTextStyles.h5.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: context.responsive<double>(
                  mobile: 20.0,
                  tablet: 22.0,
                  desktop: 24.0,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Try adjusting your search or filters',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('vegetable')) return Iconsax.drop;
    if (name.contains('fruit')) return Iconsax.heart;
    if (name.contains('meat') || name.contains('fish')) return Iconsax.box;
    if (name.contains('dairy')) return Iconsax.milk;
    if (name.contains('bakery')) return Iconsax.cake;
    if (name.contains('pantry') || name.contains('grain')) return Iconsax.box_1;
    if (name.contains('beverage')) return Iconsax.coffee;
    if (name.contains('snack')) return Iconsax.cake;
    return Iconsax.element_4;
  }
}
