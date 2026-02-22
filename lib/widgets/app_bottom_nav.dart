import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_sizes.dart';
import '../providers/cart_provider.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, this.currentIndex = 0});

  void _onNavTap(BuildContext context, int index) {
    // Avoid navigating to the same page
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        // Home
        context.go('/customer/home');
        break;
      case 1:
        // Browse - navigate to categories
        context.go('/customer/categories');
        break;
      case 2:
        // Lists
        context.go('/customer/shopping-lists');
        break;
      case 3:
        // Cart
        context.go('/customer/cart');
        break;
      case 4:
        // Orders
        context.go('/customer/orders');
        break;
      case 5:
        // Profile
        context.go('/customer/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Container(
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
                context: context,
                icon: Iconsax.home_2,
                activeIcon: Iconsax.home_15,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                context: context,
                icon: Iconsax.search_normal,
                activeIcon: Iconsax.search_normal_1,
                label: 'Browse',
                index: 1,
              ),
              _buildNavItem(
                context: context,
                icon: Iconsax.clipboard_text,
                activeIcon: Iconsax.clipboard_text,
                label: 'Lists',
                index: 2,
              ),
              _buildCartNavItem(context, cartProvider.itemCount),
              _buildNavItem(
                context: context,
                icon: Iconsax.receipt_item,
                activeIcon: Iconsax.receipt_item,
                label: 'Orders',
                index: 4,
              ),
              _buildNavItem(
                context: context,
                icon: Iconsax.user,
                activeIcon: Iconsax.user,
                label: 'Profile',
                index: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _onNavTap(context, index),
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

  Widget _buildCartNavItem(BuildContext context, int itemCount) {
    final isSelected = currentIndex == 3;

    return GestureDetector(
      onTap: () => _onNavTap(context, 3),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? Iconsax.bag_25 : Iconsax.bag_2,
                color: isSelected ? AppColors.accent : AppColors.grey400,
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
              color: isSelected ? AppColors.accent : AppColors.grey400,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
