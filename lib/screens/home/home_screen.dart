import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../models/recipe.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<RecipeProvider>().loadRecipes();
    });
  }

  Color _getProductBgColor(String categoryName) {
    final category = categoryName.toLowerCase();
    if (category.contains('fruit')) return const Color(0xFFFFF3C7);
    if (category.contains('vegetable')) return const Color(0xFFE8F5E9);
    if (category.contains('meat') || category.contains('fish')) {
      return const Color(0xFFFFEBEE);
    }
    if (category.contains('dairy')) return const Color(0xFFE3F2FD);
    if (category.contains('bakery')) return const Color(0xFFFFF8E1);
    if (category.contains('pantry')) return const Color(0xFFFFF3E0);
    return const Color(0xFFF5F5F5);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();
    final recipeProvider = context.watch<RecipeProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => productProvider.refreshProducts(),
          color: AppColors.accent,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.md,
                    AppSizes.lg,
                    AppSizes.sm,
                  ),
                  child: Row(
                    children: [
                      // User avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: authProvider.user?.profileImage != null
                            ? ClipOval(
                                child: Image.network(
                                  authProvider.user!.profileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Text(
                                  authProvider.user?.name
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      // Greeting text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${authProvider.user?.name?.split(' ').first ?? 'there'}!',
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'What would you like today?',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          border: Border.all(
                            color: AppColors.grey200,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Iconsax.notification,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/search'),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(
                          color: AppColors.grey200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.search_normal,
                            color: AppColors.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Search for groceries...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Promo Banner with Overlapping Image
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.lg + 25, // Extra top padding for overflow
                    AppSizes.lg,
                    AppSizes.lg,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Background card with gradient
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent,
                              AppColors.accentLight,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Fresh Deals',
                                style: AppTextStyles.h3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Up to 30% off on fruits',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: AppSizes.md),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.lg,
                                  vertical: AppSizes.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusFull),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Shop Now',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Overlapping image - extends right and top
                      Positioned(
                        right: -30,
                        top: -35,
                        child: Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: AppColors.accentSoft,
                                child: const Icon(
                                  Iconsax.image,
                                  size: 40,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Categories section
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.sm,
                    AppSizes.lg,
                    AppSizes.sm,
                  ),
                  child: _buildSectionHeader(
                    'Categories',
                    onSeeAll: () => Navigator.pushNamed(context, '/categories'),
                  ),
                ),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                    itemCount: productProvider.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                    itemBuilder: (context, index) {
                      final category = productProvider.categories[index];
                      return CategoryCard(
                        category: category,
                        isCompact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/category',
                          arguments: category,
                        ),
                      );
                    },
                  ),
                ),

                // Quick Actions - Shopping Lists & Recipes
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.sm,
                  ),
                  child: Row(
                    children: [
                      // Shopping Lists Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/shopping-lists'),
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                  ),
                                  child: const Icon(
                                    Iconsax.clipboard_text,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'My Lists',
                                        style: AppTextStyles.labelMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Create shopping lists',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      // Recipes Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/recipes'),
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                  ),
                                  child: const Icon(
                                    Iconsax.book,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recipes',
                                        style: AppTextStyles.labelMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Buy ingredients',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Fresh Picks Today section
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.sm,
                  ),
                  child: _buildSectionHeader(
                    'Fresh Picks Today',
                    onSeeAll: () {},
                  ),
                ),
                if (productProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(AppSizes.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                      itemCount: productProvider.featuredProducts.isNotEmpty
                          ? productProvider.featuredProducts.length
                          : productProvider.products.length.clamp(0, 6),
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSizes.md),
                      itemBuilder: (context, index) {
                        final product =
                            productProvider.featuredProducts.isNotEmpty
                                ? productProvider.featuredProducts[index]
                                : productProvider.products[index];
                        return _buildHorizontalProductCard(
                          product,
                          cartProvider,
                        );
                      },
                    ),
                  ),

                // Popular This Week section
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.sm,
                  ),
                  child: _buildSectionHeader(
                    'Popular This Week',
                    onSeeAll: () {},
                  ),
                ),
                if (!productProvider.isLoading)
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                      itemCount: productProvider.products.length.clamp(0, 6),
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSizes.md),
                      itemBuilder: (context, index) {
                        final product = productProvider.products[
                            (productProvider.products.length - 1 - index)
                                .clamp(0, productProvider.products.length - 1)];
                        return _buildHorizontalProductCard(
                          product,
                          cartProvider,
                        );
                      },
                    ),
                  ),

                // Popular Recipes section
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.lg,
                    AppSizes.sm,
                  ),
                  child: _buildSectionHeader(
                    'Popular Recipes',
                    onSeeAll: () => Navigator.pushNamed(context, '/recipes'),
                  ),
                ),
                if (!recipeProvider.isLoading &&
                    recipeProvider.popularRecipes.isNotEmpty)
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                      itemCount: recipeProvider.popularRecipes.length.clamp(0, 6),
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSizes.md),
                      itemBuilder: (context, index) {
                        final recipe = recipeProvider.popularRecipes[index];
                        return _buildRecipeCard(recipe);
                      },
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.h5.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalProductCard(Product product, CartProvider cartProvider) {
    final isInCart = cartProvider.isInCart(product.id);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/product',
        arguments: product,
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with colored background
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getProductBgColor(product.categoryName),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusLg),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.image,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Iconsax.image,
                      color: AppColors.grey400,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name and unit
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'per ${product.unit}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Price and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatCurrency(product.price),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
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
                                  content: Text('${product.name} added to cart'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppSizes.radiusMd),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isInCart
                                  ? AppColors.primary
                                  : AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInCart ? Iconsax.tick_circle5 : Iconsax.add,
                              color: Colors.white,
                              size: 16,
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

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/recipe-detail',
        arguments: recipe.id,
      ),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radiusLg),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: recipe.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.grey100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.grey100,
                        child: const Icon(
                          Iconsax.image,
                          color: AppColors.grey400,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  // Time badge
                  Positioned(
                    top: AppSizes.sm,
                    left: AppSizes.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.clock,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.totalTime} min',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: AppSizes.sm,
                    right: AppSizes.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            recipe.rating.toString(),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Recipe Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recipe.tags.take(2).join(' • '),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Iconsax.shopping_bag,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.ingredients.length} ingredients',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
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
}
