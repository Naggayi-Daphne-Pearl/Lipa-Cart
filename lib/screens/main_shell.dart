import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_sizes.dart';
import '../core/utils/responsive.dart';
import '../providers/cart_provider.dart';
import 'home/home_screen.dart';
import 'browse/browse_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Tab indices: 0=Home, 1=Browse, 2=Cart(external), 3=Orders, 4=Profile
  int _selectedTab = 0;

  // Screens for IndexedStack (excludes Cart which navigates externally)
  final List<Widget> _screens = const [
    HomeScreen(),     // stack index 0
    BrowseScreen(),   // stack index 1
    OrdersScreen(),   // stack index 2
    ProfileScreen(),  // stack index 3
  ];

  // Maps tab index to stack index
  int _getStackIndex() {
    if (_selectedTab <= 1) return _selectedTab;      // Home=0, Browse=1
    if (_selectedTab >= 3) return _selectedTab - 1;  // Orders=2, Profile=3
    return 0; // Fallback (Cart tab shouldn't reach here)
  }

  void _onNavTap(int tabIndex) {
    if (tabIndex == 2) {
      // Cart - navigate to cart screen instead of switching tab
      Navigator.pushNamed(context, '/cart');
    } else {
      setState(() => _selectedTab = tabIndex);
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
              child: IndexedStack(
                index: _getStackIndex(),
                children: _screens,
              ),
            ),
          ),
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
                    horizontal: AppSizes.sm,
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
                      _buildCartNavItem(cartProvider.itemCount),
                      _buildNavItem(
                        icon: Iconsax.receipt_item,
                        activeIcon: Iconsax.receipt_item,
                        label: 'Orders',
                        index: 3,
                      ),
                      _buildNavItem(
                        icon: Iconsax.user,
                        activeIcon: Iconsax.user,
                        label: 'Profile',
                        index: 4,
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
      onTap: () => _onNavTap(2),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Iconsax.bag_2,
                color: AppColors.grey400,
                size: 24,
              ),
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
            // App logo/name
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'LC',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  const Text(
                    'LipaCart',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: AppSizes.md),
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
            _buildSideCartNavItem(cartItemCount),
            _buildSideNavItem(
              icon: Iconsax.receipt_item,
              activeIcon: Iconsax.receipt_item,
              label: 'Orders',
              index: 3,
            ),
            _buildSideNavItem(
              icon: Iconsax.user,
              activeIcon: Iconsax.user,
              label: 'Profile',
              index: 4,
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
      onTap: () => _onNavTap(2),
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
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Iconsax.bag_2,
                  color: AppColors.grey400,
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
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
