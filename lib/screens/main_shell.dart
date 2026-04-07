import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_sizes.dart';
import '../providers/cart_provider.dart';
import '../core/utils/responsive.dart';
import 'home/home_screen.dart';
import 'browse/browse_screen.dart';
import 'shopping_lists/shopping_lists_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;

  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Tab indices: 0=Home, 1=Browse, 2=Lists, 3=Cart(external on mobile, sidebar on web), 4=Profile
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab < 0
        ? 0
        : widget.initialTab > 4
        ? 4
        : widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() {
        _selectedTab = widget.initialTab < 0
            ? 0
            : widget.initialTab > 4
            ? 4
            : widget.initialTab;
      });
    }
  }

  // Screens for IndexedStack
  List<Widget> get _screens => [
    const HomeScreen(),
    const BrowseScreen(),
    const ShoppingListsScreen(showBottomNav: false),
    const ProfileScreen(showBottomNav: false),
  ];

  // Maps tab index to stack index
  int _getStackIndex() {
    if (_selectedTab <= 2) return _selectedTab; // Home=0, Browse=1, Lists=2
    if (_selectedTab >= 4) return _selectedTab - 1; // Profile=3
    return 0; // Fallback (Cart tab shouldn't reach here)
  }

  void _onNavTap(int tabIndex) {
    if (tabIndex == 3) {
      // Cart: always navigate to cart screen
      context.go('/customer/cart');
    } else {
      setState(() {
        _selectedTab = tabIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedTab != 0) {
          setState(() => _selectedTab = 0);
        } else {
          // On mobile, exit the app. On web, this is a no-op (canPop: false blocks it).
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.elegantBgGradient,
          ),
          child: IndexedStack(index: _getStackIndex(), children: _screens),
        ),
        bottomNavigationBar: context.isMobile
            ? Container(
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
                          icon: Iconsax.user,
                          activeIcon: Iconsax.user,
                          label: 'Profile',
                          index: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: isSelected
              ? Border.all(color: AppColors.accent.withValues(alpha: 0.15))
              : null,
        ),
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
              style: AppTextStyles.navLabel.copyWith(
                color: isSelected ? AppColors.accent : AppColors.grey400,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
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
            style: AppTextStyles.navLabel.copyWith(
              color: AppColors.grey400,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
