import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/shimmer_loading.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/recipe.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/adaptive_product_section.dart';
import '../../widgets/adaptive_category_section.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/desktop_top_nav_bar.dart';
import '../../widgets/desktop_footer.dart';
import '../../widgets/feature_spotlight_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _homeTourDismissedKey = 'home_quick_tour_dismissed';

  int _unreadNotifications = 0;
  bool _showQuickTour = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = context.read<ProductProvider>();
      await productProvider.loadProducts();
      if (mounted) {
        context.read<RecipeProvider>().loadRecipes(
          products: productProvider.products,
        );
      }
      await _fetchUnreadCount();
      await _loadQuickTourPreference();
    });
  }

  Future<void> _loadQuickTourPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_homeTourDismissedKey) ?? false;
    if (!mounted || dismissed) return;

    setState(() {
      _showQuickTour = true;
    });
  }

  Future<void> _dismissQuickTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeTourDismissedKey, true);

    if (!mounted) return;
    setState(() {
      _showQuickTour = false;
    });
  }

  Future<void> _fetchUnreadCount() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final response = await http
          .get(
            Uri.parse('${AppConstants.apiUrl}/notifications/mine?pageSize=1'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(response.body);
        setState(() {
          _unreadNotifications = body['meta']?['unreadCount'] ?? 0;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color _getProductBgColor(String categoryName) =>
      Formatters.getProductBgColor(categoryName);

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
                if (context.isDesktop)
                  const DesktopTopNavBar(activeSection: 'home'),
                // Hero Section with Gradient Background
                Container(
                  decoration: const BoxDecoration(
                    // Warm-grocer hero: green identity at top fading to cream.
                    // Palette-native — no cool greys. See design_direction.md.
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primarySoft,
                        AppColors.background,
                      ],
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
                        // Header Bar
                        if (!context.isDesktop)
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
                                _buildHeaderActionButton(
                                  context: context,
                                  icon: Iconsax.notification,
                                  badgeCount: _unreadNotifications,
                                  onTap: () async {
                                    await context.push(
                                      '/customer/notifications',
                                    );
                                    _fetchUnreadCount();
                                  },
                                ),
                              ],
                            ),
                          ),
                        // Greeting section
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
                                        style: AppTextStyles.displayMd,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'What would you buy today?',
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Search Bar
                        if (!context.isDesktop)
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
                            child: _buildSearchBar(context),
                          ),
                        // Trust strip — three quick credibility signals.
                        if (!context.isDesktop)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.horizontalPadding,
                              0,
                              context.horizontalPadding,
                              AppSizes.sm,
                            ),
                            child: _buildTrustStrip(),
                          ),
                        // Editorial hero — warm grocer positioning.
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalPadding,
                            AppSizes.md,
                            context.horizontalPadding,
                            AppSizes.md,
                          ),
                          child: _buildEditorialHero(context),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showQuickTour)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.horizontalPadding,
                      AppSizes.md,
                      context.horizontalPadding,
                      AppSizes.sm,
                    ),
                    child: FeatureSpotlightCard(
                      icon: Iconsax.routing_2,
                      eyebrow: 'QUICK START',
                      title: 'Take a quick tour of LipaCart',
                      description:
                          'Browse products, save repeat orders in Shopping Lists, and track deliveries without interrupting your flow.',
                      highlights: const [
                        'Browse fresh picks',
                        'Save lists for later',
                        'Track each order live',
                      ],
                      primaryLabel: 'Browse Products',
                      onPrimaryTap: () => context.push('/customer/browse'),
                      secondaryLabel: 'Open Lists',
                      onSecondaryTap: () =>
                          context.push('/customer/shopping-lists'),
                      onDismiss: _dismissQuickTour,
                      accentColor: AppColors.accent,
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
                    onSeeAll: () => context.push('/customer/categories'),
                  ),
                ),
                AdaptiveCategorySection(
                  categories: productProvider.categories,
                  onCategoryTap: (category) =>
                      context.push('/customer/category', extra: category),
                ),
                const SizedBox(height: AppSizes.xl),

                // Reorder section (for authenticated users with past orders)
                if (authProvider.isAuthenticated)
                  Builder(
                    builder: (context) {
                      final orderService = context.watch<OrderService>();
                      final recentOrders = orderService.orders
                          .where((o) => o.status == OrderStatus.delivered)
                          .take(3)
                          .toList();

                      if (recentOrders.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.horizontalPadding,
                            ),
                            child: _buildSectionHeader(
                              'Reorder',
                              onSeeAll: () => context.push('/customer/orders'),
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                horizontal: context.horizontalPadding,
                              ),
                              itemCount: recentOrders.length,
                              itemBuilder: (context, index) {
                                final order = recentOrders[index];
                                return GestureDetector(
                                  onTap: () {
                                    final cartProvider = context
                                        .read<CartProvider>();
                                    for (final item in order.items) {
                                      cartProvider.addToCart(
                                        item.product,
                                        quantity: item.quantity,
                                      );
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${order.items.length} items added to cart',
                                        ),
                                        backgroundColor: AppColors.success,
                                        action: SnackBarAction(
                                          label: 'Checkout',
                                          textColor: Colors.white,
                                          onPressed: () => context.push(
                                            '/customer/checkout',
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 220,
                                    margin: const EdgeInsets.only(
                                      right: AppSizes.md,
                                    ),
                                    padding: const EdgeInsets.all(AppSizes.sm),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusMd,
                                      ),
                                      border: Border.all(
                                        color: AppColors.grey200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySoft,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Iconsax.refresh_2,
                                            color: AppColors.primary,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: AppSizes.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '#${order.orderNumber}',
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${order.items.length} items • ${Formatters.formatCurrency(order.total)}',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Tap to reorder',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.xl),
                        ],
                      );
                    },
                  ),

                // Your Shopping Lists
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Your Lists', style: AppTextStyles.sectionTitle),
                      GestureDetector(
                        onTap: () => context.push('/customer/shopping-lists'),
                        child: Text(
                          'See All',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<ShoppingListProvider>(
                  builder: (context, listProvider, _) {
                    final lists = listProvider.lists;
                    if (lists.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalPadding,
                        ),
                        child: GestureDetector(
                          onTap: () => context.push('/customer/shopping-lists'),
                          child: Container(
                            padding: const EdgeInsets.all(AppSizes.lg),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg,
                              ),
                              border: Border.all(
                                color: AppColors.primaryMuted,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Stacked illustration — clipboard with plus badge.
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusMd,
                                          ),
                                          boxShadow: AppColors.shadowSm,
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Iconsax.clipboard_text,
                                          color: AppColors.primary,
                                          size: 30,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.surface,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Iconsax.add,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSizes.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start your grocery list',
                                        style: AppTextStyles.bodyLarge
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Plan your shopping and order in one tap',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Iconsax.arrow_right_3,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          final color = Color(
                            int.parse(
                              'FF${list.color.replaceAll('#', '')}',
                              radix: 16,
                            ),
                          );
                          return GestureDetector(
                            onTap: () => context.push(
                              '/customer/shopping-list-detail',
                              extra: list.id,
                            ),
                            child: Container(
                              width: 180,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        list.emoji ?? '🛒',
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          list.name,
                                          style: AppTextStyles.labelLarge
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${list.totalItems} items',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          'Shop',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Fresh Picks Today section
                const SizedBox(height: AppSizes.xl),
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
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.lg),
                    child: ShimmerHorizontalRow(),
                  )
                else
                  AdaptiveProductSection(
                    itemWidth: context.responsive<double>(
                      mobile: 160,
                      tablet: 150,
                      desktop: 145,
                    ),
                    itemHeight: context.responsive<double>(
                      mobile: 270,
                      tablet: 260,
                      desktop: 255,
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
                const SizedBox(height: AppSizes.xl),
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
                      mobile: 270,
                      tablet: 260,
                      desktop: 255,
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
                const SizedBox(height: AppSizes.xl),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    0,
                    context.horizontalPadding,
                    AppSizes.lg,
                  ),
                  child: _buildSectionHeader(
                    'Popular Recipes',
                    onSeeAll: () => context.push('/customer/recipes'),
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

                const SizedBox(height: AppSizes.xl),
                const DesktopFooter(),
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

  Widget _buildHeaderActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: AppColors.textPrimary, size: 22),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrustStrip() {
    return Row(
      children: [
        Expanded(
          child: _buildTrustPill(
            icon: Iconsax.truck_fast,
            stat: 'Free',
            label: 'over UGX 50k',
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _buildTrustPill(
            icon: Iconsax.timer_1,
            stat: '30 min',
            label: 'avg delivery',
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _buildTrustPill(
            icon: Iconsax.heart5,
            stat: '10k+',
            label: 'happy buyers',
          ),
        ),
      ],
    );
  }

  Widget _buildTrustPill({
    required IconData icon,
    required String stat,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primaryMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, {bool compact = false}) {
    return GestureDetector(
      onTap: () => context.push('/customer/search'),
      child: Container(
        height: compact
            ? 52
            : context.responsive<double>(
                mobile: 52.0,
                tablet: 56.0,
                desktop: 60.0,
              ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
              width: compact
                  ? AppSizes.md
                  : context.responsive<double>(
                      mobile: AppSizes.md,
                      tablet: AppSizes.lg,
                      desktop: 20.0,
                    ),
            ),
            Icon(
              Iconsax.search_normal,
              color: AppColors.textSecondary,
              size: compact
                  ? 20
                  : context.responsive<double>(
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
                  fontSize: compact
                      ? 14
                      : context.responsive<double>(
                          mobile: 14.0,
                          tablet: 15.0,
                          desktop: 16.0,
                        ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 6),
              width: compact
                  ? 40
                  : context.responsive<double>(
                      mobile: 40.0,
                      tablet: 44.0,
                      desktop: 48.0,
                    ),
              height: compact
                  ? 40
                  : context.responsive<double>(
                      mobile: 40.0,
                      tablet: 44.0,
                      desktop: 48.0,
                    ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B7F4E), Color(0xFF15874B)],
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Iconsax.setting_4,
                color: Colors.white,
                size: compact
                    ? 18
                    : context.responsive<double>(
                        mobile: 20.0,
                        tablet: 22.0,
                        desktop: 24.0,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialHero(BuildContext context) {
    final height = context.responsive<double>(
      mobile: 320,
      tablet: 340,
      desktop: 360,
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySoft, AppColors.primaryMuted],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: Stack(
          children: [
            // Decorative iconography — soft, low-opacity, no photo required.
            Positioned(
              top: -20,
              right: -10,
              child: Icon(
                Iconsax.tree,
                size: 160,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -20,
              child: Icon(
                Iconsax.shopping_bag,
                size: 140,
                color: AppColors.primaryDark.withValues(alpha: 0.06),
              ),
            ),
            Positioned(
              top: 60,
              left: 180,
              child: Icon(
                Iconsax.cake,
                size: 56,
                color: AppColors.accent.withValues(alpha: 0.14),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Eyebrow pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusFull,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.shield_tick5,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'FRESH · LOCAL · FAST',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Headline + sub
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fresh groceries,\nat your door.',
                        style: AppTextStyles.displayLg.copyWith(
                          color: AppColors.primaryDark,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'Shop from local markets — delivered in 30 minutes across Kampala.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Primary CTA
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/customer/categories'),
                        icon: const Icon(Iconsax.shop, size: 18),
                        label: const Text('Shop now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          textStyle: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      TextButton(
                        onPressed: () => context.push('/customer/browse'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          textStyle: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Browse all'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: AppTextStyles.displaySm)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  'See All',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: AppColors.accent,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.grey200, width: 1),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed 1:1 image ratio — all product photos align on the grid.
            AspectRatio(
              aspectRatio: 1,
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
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: AppLoadingIndicator.small()),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Iconsax.gallery,
                        color: AppColors.textTertiary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'per ${product.unit}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.rating > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Iconsax.star1,
                          size: 13,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          Formatters.formatCurrency(product.price),
                          style: AppTextStyles.priceMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Substantial add button — solid accent, tuned shadow.
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isInCart
                                ? AppColors.primary
                                : AppColors.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isInCart
                                            ? AppColors.primary
                                            : AppColors.accent)
                                        .withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isInCart ? Iconsax.tick_circle5 : Iconsax.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                        child: const Center(child: AppLoadingIndicator.small()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accentSoft,
                              AppColors.primarySoft,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(AppSizes.md),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.cake,
                              color: AppColors.primary.withValues(alpha: 0.7),
                              size: 32,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              recipe.name,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.shopping_bag,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${recipe.ingredients.length} ingredients',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
