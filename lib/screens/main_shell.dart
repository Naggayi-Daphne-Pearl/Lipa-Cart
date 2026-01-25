import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_sizes.dart';
import '../core/utils/responsive.dart';
import '../core/utils/formatters.dart';
import '../providers/cart_provider.dart';
import 'home/home_screen.dart';
import 'browse/browse_screen.dart';
import 'shopping_lists/shopping_lists_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Tab indices: 0=Home, 1=Browse, 2=Lists, 3=Cart(external on mobile, sidebar on web), 4=Orders, 5=Profile
  int _selectedTab = 0;
  bool _showCartSidebar = false;

  // Screens for IndexedStack
  final List<Widget> _screens = const [
    HomeScreen(), // stack index 0
    BrowseScreen(), // stack index 1
    ShoppingListsScreen(), // stack index 2
    OrdersScreen(), // stack index 3
    ProfileScreen(), // stack index 4
  ];

  // Maps tab index to stack index
  int _getStackIndex() {
    if (_selectedTab <= 2) return _selectedTab; // Home=0, Browse=1, Lists=2
    if (_selectedTab >= 4) return _selectedTab - 1; // Orders=3, Profile=4
    return 0; // Fallback (Cart tab shouldn't reach here)
  }

  void _onNavTap(int tabIndex) {
    final isDesktopOrTablet = context.isTablet || context.isDesktop;

    if (tabIndex == 3) {
      // Cart handling
      if (isDesktopOrTablet) {
        // On web/tablet: toggle cart sidebar
        setState(() => _showCartSidebar = !_showCartSidebar);
      } else {
        // On mobile: navigate to cart screen
        Navigator.pushNamed(context, '/cart');
      }
    } else {
      setState(() {
        _selectedTab = tabIndex;
        if (isDesktopOrTablet) {
          _showCartSidebar = false; // Close cart sidebar when switching tabs
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final isDesktopOrTablet = context.isTablet || context.isDesktop;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation for tablet/desktop
          if (isDesktopOrTablet) _buildSideNavigation(cartProvider.itemCount),

          // Main content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.elegantBgGradient,
              ),
              child: IndexedStack(index: _getStackIndex(), children: _screens),
            ),
          ),

          // Cart sidebar for web/tablet
          if (isDesktopOrTablet && _showCartSidebar)
            _buildCartSidebar(cartProvider),
        ],
      ),
      // Bottom navigation for mobile
      bottomNavigationBar: isDesktopOrTablet
          ? null
          : Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusXl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xs,
                    vertical: AppSizes.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Iconsax.home_2,
                        activeIcon: Iconsax.home_15,
                        label: 'Home',
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Iconsax.search_normal,
                        activeIcon: Iconsax.search_normal_1,
                        label: 'Browse',
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: Iconsax.clipboard_text,
                        activeIcon: Iconsax.clipboard_text,
                        label: 'Lists',
                        index: 2,
                      ),
                      _buildCartNavItem(cartProvider.itemCount),
                      _buildNavItem(
                        icon: Iconsax.receipt_item,
                        activeIcon: Iconsax.receipt_item,
                        label: 'Orders',
                        index: 4,
                      ),
                      _buildNavItem(
                        icon: Iconsax.user,
                        activeIcon: Iconsax.user,
                        label: 'Profile',
                        index: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.accent : AppColors.grey400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? AppColors.accent : AppColors.grey400,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartNavItem(int itemCount) {
    return GestureDetector(
      onTap: () => _onNavTap(3),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Iconsax.bag_2, color: AppColors.grey400, size: 24),
              if (itemCount > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      itemCount > 9 ? '9+' : itemCount.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cart',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.grey400,
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigation(int cartItemCount) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSizes.xl),

            // App logo/name
            SvgPicture.asset(
              'assets/images/logos/logo-on-white.svg',
              height: context.responsive<double>(
                mobile: 20.0,
                tablet: 24.0,
                desktop: 20.0,
              ),
              fit: BoxFit.contain,
            ),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.lg),
            // Navigation items
            _buildSideNavItem(
              icon: Iconsax.home_2,
              activeIcon: Iconsax.home_15,
              label: 'Home',
              index: 0,
            ),
            _buildSideNavItem(
              icon: Iconsax.search_normal,
              activeIcon: Iconsax.search_normal_1,
              label: 'Browse',
              index: 1,
            ),
            _buildSideNavItem(
              icon: Iconsax.clipboard_text,
              activeIcon: Iconsax.clipboard_text,
              label: 'Shopping Lists',
              index: 2,
            ),
            _buildSideCartNavItem(cartItemCount),
            _buildSideNavItem(
              icon: Iconsax.receipt_item,
              activeIcon: Iconsax.receipt_item,
              label: 'Orders',
              index: 4,
            ),
            _buildSideNavItem(
              icon: Iconsax.user,
              activeIcon: Iconsax.user,
              label: 'Profile',
              index: 5,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedTab == index;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.accent : AppColors.grey400,
              size: 24,
            ),
            const SizedBox(width: AppSizes.md),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideCartNavItem(int itemCount) {
    return GestureDetector(
      onTap: () => _onNavTap(3),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: _showCartSidebar
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Iconsax.bag_2,
                  color: _showCartSidebar
                      ? AppColors.primary
                      : AppColors.grey400,
                  size: 24,
                ),
                if (itemCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        itemCount > 9 ? '9+' : itemCount.toString(),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSizes.md),
            Text(
              'Cart',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _showCartSidebar
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: _showCartSidebar
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSidebar(CartProvider cartProvider) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Cart header
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  const Icon(Iconsax.bag_2, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Shopping Cart',
                    style: AppTextStyles.h5.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _showCartSidebar = false),
                    icon: const Icon(
                      Iconsax.close_circle,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Cart items
            Expanded(
              child: cartProvider.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Iconsax.bag_cross,
                              size: 40,
                              color: AppColors.grey400,
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          Text(
                            'Your cart is empty',
                            style: AppTextStyles.h5.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Add items to get started',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.md),
                      itemCount: cartProvider.items.length,
                      itemBuilder: (context, index) {
                        final item = cartProvider.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.md),
                          child: Row(
                            children: [
                              // Product image
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                  child: Image.network(
                                    item.product.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Iconsax.image,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              // Product info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: AppTextStyles.labelMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.formatCurrency(
                                        item.product.price,
                                      ),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity controls
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (item.quantity > 1) {
                                        cartProvider.updateQuantity(
                                          item.product.id,
                                          item.quantity - 1,
                                        );
                                      } else {
                                        cartProvider.removeFromCart(
                                          item.product.id,
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.grey100,
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusSm,
                                        ),
                                      ),
                                      child: const Icon(
                                        Iconsax.minus,
                                        size: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.quantity.toInt().toString(),
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => cartProvider.updateQuantity(
                                      item.product.id,
                                      item.quantity + 1,
                                    ),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusSm,
                                        ),
                                      ),
                                      child: const Icon(
                                        Iconsax.add,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Cart footer with total
            if (cartProvider.items.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(cartProvider.subtotal),
                          style: AppTextStyles.h5.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _showCartSidebar = false);
                          Navigator.pushNamed(context, '/cart');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Cart & Checkout',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
