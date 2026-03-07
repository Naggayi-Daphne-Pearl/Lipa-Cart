import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../../models/recipe.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/adaptive_product_section.dart';
import '../../widgets/adaptive_category_section.dart';
import '../../widgets/app_loading_indicator.dart';

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
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => productProvider.refreshProducts(),
        color: AppColors.accent,
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            centerContent: true,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section with Gradient Background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE8F5E9), // Light green at top
                        Color(0xFFF1F8E9), // Softer green
                        Color(0xFFFAFAFA), // Fade to near white
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Enhanced Header Bar - Desktop optimized
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalPadding,
                            context.responsive<double>(
                              mobile: AppSizes.sm,
                              tablet: AppSizes.md,
                              desktop: AppSizes.lg,
                            ),
                            context.horizontalPadding,
                            context.responsive<double>(
                              mobile: AppSizes.xs,
                              tablet: AppSizes.sm,
                              desktop: AppSizes.md,
                            ),
                          ),
                          child: Row(
                            children: [
                              // App Logo (mobile only) or Greeting (desktop)
                              if (context.isMobile)
                                SvgPicture.asset(
                                  'assets/images/logos/logo-on-white.svg',
                                  height: context.responsive<double>(
                                    mobile: 20.0,
                                    tablet: 24.0,
                                    desktop: 28.0,
                                  ),
                                  fit: BoxFit.contain,
                                )
                              else
                                Text(
                                  'Hi, ${authProvider.user?.name ?? 'there'}',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),

                              const Spacer(),

                              // Notifications Bell (always on the right)
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    const Center(
                                      child: Icon(
                                        Iconsax.notification,
                                        color: AppColors.textPrimary,
                                        size: 22,
                                      ),
                                    ),
                                    // Notification badge
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Mobile greeting section
                        if (context.isMobile)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.horizontalPadding,
                              vertical: AppSizes.md,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
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
                                                'G',
                                            style: AppTextStyles.h4.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _getGreeting(
                                          authProvider.user?.name
                                                  ?.split(' ')
                                                  .first ??
                                              'there',
                                        ),
                                        style: AppTextStyles.h5.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'What would you buy today?',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Enhanced Search Bar
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalPadding,
                            context.responsive<double>(
                              mobile: AppSizes.md,
                              tablet: AppSizes.sm,
                              desktop: 0.0,
                            ),
                            context.horizontalPadding,
                            context.responsive<double>(
                              mobile: AppSizes.sm,
                              tablet: AppSizes.md,
                              desktop: AppSizes.lg,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              context.go('/customer/search');
                            },
                            child: Container(
                              height: context.responsive<double>(
                                mobile: 52.0,
                                tablet: 56.0,
                                desktop: 60.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: context.responsive<double>(
                                      mobile: AppSizes.md,
                                      tablet: AppSizes.lg,
                                      desktop: 20.0,
                                    ),
                                  ),
                                  Icon(
                                    Iconsax.search_normal,
                                    color: AppColors.textSecondary,
                                    size: context.responsive<double>(
                                      mobile: 22.0,
                                      tablet: 24.0,
                                      desktop: 26.0,
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.md),
                                  Expanded(
                                    child: Text(
                                      'Search products, recipes...',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: context.responsive<double>(
                                          mobile: 14.0,
                                          tablet: 15.0,
                                          desktop: 16.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    width: context.responsive<double>(
                                      mobile: 40.0,
                                      tablet: 44.0,
                                      desktop: 48.0,
                                    ),
                                    height: context.responsive<double>(
                                      mobile: 40.0,
                                      tablet: 44.0,
                                      desktop: 48.0,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1B7F4E),
                                          Color(0xFF15874B),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusFull,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Iconsax.setting_4,
                                      color: Colors.white,
                                      size: context.responsive<double>(
                                        mobile: 20.0,
                                        tablet: 22.0,
                                        desktop: 24.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Enhanced Hero Banner with CTA
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalPadding,
                            AppSizes.md,
                            context.horizontalPadding,
                            AppSizes.sm,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Background card with vibrant gradient
                              Container(
                                height: context.responsive(
                                  mobile: 140.0,
                                  tablet: 150.0,
                                  desktop: 160.0,
                                ),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFE8CC), // Vibrant cream
                                      Color(0xFFFFD699), // Rich amber
                                      Color(0xFFFFB347), // Orange accent
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    stops: [0.0, 0.5, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF8C42,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Pattern overlay for texture
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          gradient: RadialGradient(
                                            center: Alignment.topRight,
                                            radius: 1.5,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Content
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Text(
                                              '🔥 SPECIAL OFFER',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFEA7702),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Main text with better contrast
                                          const Text(
                                            'Fresh Groceries',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF2C2C2C),
                                              height: 1.0,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white,
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Text(
                                            'Up to 30% OFF',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFFEA7702),
                                              height: 1.0,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // Shop Now CTA Button
                                          GestureDetector(
                                            onTap: () {
                                              context.go(
                                                '/customer/categories',
                                              );
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF1B7F4E),
                                                    Color(0xFF15874B),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF15874B,
                                                    ).withValues(alpha: 0.4),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Shop Now',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Icon(
                                                    Iconsax.arrow_right_3,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // High-quality overlapping image
                              Positioned(
                                right: context.responsive<double>(
                                  mobile: -10.0,
                                  tablet: 20.0,
                                  desktop: 40.0,
                                ),
                                top: -25,
                                bottom: -15,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=600&q=90',
                                  width: context.responsive<double>(
                                    mobile: 160.0,
                                    tablet: 200.0,
                                    desktop: 240.0,
                                  ),
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Container(
                                    width: 160,
                                    color: Colors.transparent,
                                    child: const Center(
                                      child: AppLoadingIndicator.small(
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 160,
                                        color: Colors.transparent,
                                        child: const Icon(
                                          Iconsax.gallery,
                                          size: 48,
                                          color: Color(0xFFEA7702),
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Page indicators
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.md),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPageIndicator(isActive: true),
                              const SizedBox(width: 6),
                              _buildPageIndicator(isActive: false),
                              const SizedBox(width: 6),
                              _buildPageIndicator(isActive: false),
                              const SizedBox(width: 6),
                              _buildPageIndicator(isActive: false),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),

                // Categories section
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    AppSizes.sm,
                    context.horizontalPadding,
                    AppSizes.sm,
                  ),
                  child: _buildSectionHeader(
                    'Categories',
                    onSeeAll: () => context.go('/customer/categories'),
                  ),
                ),
                AdaptiveCategorySection(
                  categories: productProvider.categories,
                  onCategoryTap: (category) =>
                      context.push('/customer/category', extra: category),
                ),
                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.md,
                    tablet: AppSizes.xl,
                    desktop: AppSizes.xxl,
                  ),
                ),

                // Enhanced Quick Actions - Shopping Lists & Recipes
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    0,
                    context.horizontalPadding,
                    AppSizes.md,
                  ),
                  child: Row(
                    children: [
                      // Shopping Lists Card - Enhanced
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/customer/shopping-lists'),
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1B7F4E),
                                        Color(0xFF15874B),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Iconsax.clipboard_text5,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Text(
                                  'My Lists',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Personalized lists',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      // Recipes Card - Enhanced
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/customer/recipes'),
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.08,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFF8C42),
                                        Color(0xFFEA7702),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Iconsax.book5,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Text(
                                  'Recipes',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2C2C2C),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Shop ingredients',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
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
                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xxl,
                    desktop: 48,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    0,
                    context.horizontalPadding,
                    AppSizes.lg,
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
                      child: AppLoadingIndicator.small(),
                    ),
                  )
                else
                  AdaptiveProductSection(
                    itemWidth: context.responsive<double>(
                      mobile: 160,
                      tablet: 150,
                      desktop: 145,
                    ),
                    itemHeight: context.responsive<double>(
                      mobile: 220,
                      tablet: 210,
                      desktop: 205,
                    ),
                    products:
                        (productProvider.featuredProducts.isNotEmpty
                                ? productProvider.featuredProducts
                                : productProvider.products.take(12))
                            .map(
                              (product) => _buildHorizontalProductCard(
                                product,
                                cartProvider,
                              ),
                            )
                            .toList(),
                  ),

                // Popular This Week section
                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xxl,
                    desktop: 48,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    0,
                    context.horizontalPadding,
                    AppSizes.lg,
                  ),
                  child: _buildSectionHeader(
                    'Popular This Week',
                    onSeeAll: () {},
                  ),
                ),
                if (!productProvider.isLoading)
                  AdaptiveProductSection(
                    itemWidth: context.responsive<double>(
                      mobile: 160,
                      tablet: 150,
                      desktop: 145,
                    ),
                    itemHeight: context.responsive<double>(
                      mobile: 220,
                      tablet: 210,
                      desktop: 205,
                    ),
                    products: productProvider.products.reversed
                        .take(12)
                        .map(
                          (product) => _buildHorizontalProductCard(
                            product,
                            cartProvider,
                          ),
                        )
                        .toList(),
                  ),

                // Popular Recipes section
                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xxl,
                    desktop: 48,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    0,
                    context.horizontalPadding,
                    AppSizes.lg,
                  ),
                  child: _buildSectionHeader(
                    'Popular Recipes',
                    onSeeAll: () => context.go('/customer/recipes'),
                  ),
                ),
                if (!recipeProvider.isLoading &&
                    recipeProvider.popularRecipes.isNotEmpty)
                  AdaptiveProductSection(
                    itemWidth: 200,
                    products: recipeProvider.popularRecipes
                        .take(12)
                        .map((recipe) => _buildRecipeCard(recipe))
                        .toList(),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning, $name';
    } else if (hour < 17) {
      return 'Afternoon, $name';
    } else {
      return 'Evening, $name';
    }
  }

  Widget _buildPageIndicator({required bool isActive}) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : AppColors.grey300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C2C2C),
            letterSpacing: -0.5,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'See All',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFFFF8C42),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: Color(0xFFFF8C42),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalProductCard(
    Product product,
    CartProvider cartProvider,
  ) {
    final isInCart = cartProvider.isInCart(product.id);

    return GestureDetector(
      onTap: () => context.push('/customer/product', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                    top: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: AppLoadingIndicator.small(),
                    ),
                    errorWidget: (context, url, error) => const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.gallery,
                            color: Color(0xFFB8B3AB),
                            size: 20,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'No image',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFFB8B3AB),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Product Info - Enhanced
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C2C2C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'per ${product.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
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
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF8C42),
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
                                  content: Text(
                                    '${product.name} added to cart',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMd,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: isInCart
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF1B7F4E),
                                        Color(0xFF15874B),
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFFF8C42),
                                        Color(0xFFEA7702),
                                      ],
                                    ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isInCart
                                              ? const Color(0xFF15874B)
                                              : const Color(0xFFEA7702))
                                          .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              isInCart ? Iconsax.tick_circle5 : Iconsax.add,
                              color: Colors.white,
                              size: 18,
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
      onTap: () => context.push('/customer/recipe-detail', extra: recipe.id),
      child: Container(
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
                          child: AppLoadingIndicator.small(),
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
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
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
                        borderRadius: BorderRadius.circular(
                          AppSizes.radiusFull,
                        ),
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
