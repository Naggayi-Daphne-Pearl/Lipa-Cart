import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/shimmer_loading.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  static const _bannerCount = 3;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _startBannerAutoScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = context.read<ProductProvider>();
      await productProvider.loadProducts();
      if (mounted) {
        context.read<RecipeProvider>().loadRecipes(products: productProvider.products);
      }
      _fetchUnreadCount();
    });
  }

  Future<void> _fetchUnreadCount() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiUrl}/notifications/mine?pageSize=1'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && mounted) {
        final body = jsonDecode(response.body);
        setState(() {
          _unreadNotifications = body['meta']?['unreadCount'] ?? 0;
        });
      }
    } catch (_) {}
  }

  void _startBannerAutoScroll() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = ((_bannerController.page?.round() ?? 0) + 1) % _bannerCount;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Color _getProductBgColor(String categoryName) => Formatters.getProductBgColor(categoryName);

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

                              // Notifications Bell with badge
                              GestureDetector(
                                onTap: () async {
                                  await context.push('/customer/notifications');
                                  // Refresh count when returning from inbox
                                  _fetchUnreadCount();
                                },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
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
                                      child: const Center(
                                        child: Icon(
                                          Iconsax.notification,
                                          color: AppColors.textPrimary,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    if (_unreadNotifications > 0)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          child: Text(
                                            _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
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

                        // Hero Banner Carousel
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.horizontalPadding,
                            AppSizes.md,
                            context.horizontalPadding,
                            AppSizes.sm,
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: context.responsive(
                                  mobile: 170.0,
                                  tablet: 180.0,
                                  desktop: 190.0,
                                ),
                                child: PageView(
                                  controller: _bannerController,
                                  children: [
                                    _buildBannerCard(
                                      title: 'SPECIAL OFFER',
                                      subtitle: 'Fresh Groceries\nUp to 30% OFF',
                                      cta: 'Shop Now',
                                      gradient: const [Color(0xFFFFE8CC), Color(0xFFFFD699), Color(0xFFFFB347)],
                                      shadowColor: const Color(0xFFFF8C42),
                                      onTap: () => context.go('/customer/categories'),
                                    ),
                                    _buildBannerCard(
                                      title: 'WEEKLY DEALS',
                                      subtitle: 'Fresh Fruits &\nVegetables',
                                      cta: 'Browse Deals',
                                      gradient: const [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFF81C784)],
                                      shadowColor: const Color(0xFF4CAF50),
                                      onTap: () => context.go('/customer/categories'),
                                    ),
                                    _buildBannerCard(
                                      title: 'FREE DELIVERY',
                                      subtitle: 'Orders above\nUGX 50,000',
                                      cta: 'Order Now',
                                      gradient: const [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF64B5F6)],
                                      shadowColor: const Color(0xFF2196F3),
                                      onTap: () => context.go('/customer/categories'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              SmoothPageIndicator(
                                controller: _bannerController,
                                count: 3,
                                effect: ExpandingDotsEffect(
                                  dotWidth: 8,
                                  dotHeight: 8,
                                  activeDotColor: AppColors.accent,
                                  dotColor: AppColors.grey300,
                                  expansionFactor: 3,
                                ),
                              ),
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

                // Featured category spotlight
                if (productProvider.categories.length >= 2)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/customer/category', extra: productProvider.categories[0]),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.heart5, color: AppColors.primary, size: 24),
                                  const SizedBox(height: 8),
                                  Text(
                                    productProvider.categories[0].name,
                                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Shop fresh',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/customer/category', extra: productProvider.categories[1]),
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.flash_1, color: AppColors.accent, size: 24),
                                  const SizedBox(height: 8),
                                  Text(
                                    productProvider.categories[1].name,
                                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Top picks',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.md,
                    tablet: AppSizes.lg,
                    desktop: AppSizes.xl,
                  ),
                ),

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
                            padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                            child: _buildSectionHeader('Reorder', onSeeAll: () => context.go('/customer/orders')),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                              itemCount: recentOrders.length,
                              itemBuilder: (context, index) {
                                final order = recentOrders[index];
                                return GestureDetector(
                                  onTap: () {
                                    final cartProvider = context.read<CartProvider>();
                                    for (final item in order.items) {
                                      cartProvider.addToCart(item.product, quantity: item.quantity);
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${order.items.length} items added to cart'),
                                        backgroundColor: AppColors.success,
                                        action: SnackBarAction(
                                          label: 'Checkout',
                                          textColor: Colors.white,
                                          onPressed: () => context.go('/customer/checkout'),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 220,
                                    margin: const EdgeInsets.only(right: AppSizes.md),
                                    padding: const EdgeInsets.all(AppSizes.sm),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                      border: Border.all(color: AppColors.grey200),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySoft,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Iconsax.refresh_2, color: AppColors.primary, size: 22),
                                        ),
                                        const SizedBox(width: AppSizes.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '#${order.orderNumber}',
                                                style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${order.items.length} items • ${Formatters.formatCurrency(order.total)}',
                                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Tap to reorder',
                                                style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 11),
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
                          SizedBox(
                            height: context.responsive<double>(
                              mobile: AppSizes.md,
                              tablet: AppSizes.xl,
                              desktop: AppSizes.xxl,
                            ),
                          ),
                        ],
                      );
                    },
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

                // Your Shopping Lists
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Lists', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => context.go('/customer/shopping-lists'),
                        child: Text('See All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: () => context.go('/customer/shopping-lists'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Iconsax.clipboard_text, color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Start your grocery list', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                      Text('Plan your shopping and order in one tap', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
                          final color = Color(int.parse('FF${list.color.replaceAll('#', '')}', radix: 16));
                          return GestureDetector(
                            onTap: () => context.push('/customer/shopping-list-detail', extra: list.id),
                            child: Container(
                              width: 180,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(list.emoji ?? '🛒', style: const TextStyle(fontSize: 22)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          list.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${list.totalItems} items',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('Shop', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
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

  Widget _buildBannerCard({
    required String title,
    required String subtitle,
    required String cta,
    required List<Color> gradient,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFEA7702), letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2C2C2C), height: 1.2),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1B7F4E), Color(0xFF15874B)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(cta, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
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
