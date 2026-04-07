import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_sizes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/responsive.dart';
import '../providers/cart_provider.dart';

class DesktopTopNavBar extends StatelessWidget {
  final String activeSection;
  final bool showSearch;

  const DesktopTopNavBar({
    super.key,
    required this.activeSection,
    this.showSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop) {
      return const SizedBox.shrink();
    }

    final cartCount = context.watch<CartProvider>().itemCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        AppSizes.md,
        context.horizontalPadding,
        AppSizes.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xl,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/customer/home'),
              child: SvgPicture.asset(
                'assets/images/logos/logo-on-white.svg',
                height: 34,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: AppSizes.xl),
            _buildNavLink(
              context,
              label: 'Home',
              route: '/customer/home',
              isSelected: activeSection == 'home',
            ),
            _buildNavLink(
              context,
              label: 'Categories',
              route: '/customer/categories',
              isSelected: activeSection == 'shop',
            ),
            _buildNavLink(
              context,
              label: 'Recipes',
              route: '/customer/recipes',
              isSelected: activeSection == 'recipes',
            ),
            _buildNavLink(
              context,
              label: 'My Lists',
              route: '/customer/shopping-lists',
              isSelected: activeSection == 'lists',
            ),
            _buildNavLink(
              context,
              label: 'Orders',
              route: '/customer/orders',
              isSelected: activeSection == 'orders',
            ),
            const Spacer(),
            if (showSearch) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: _buildSearchBar(context),
              ),
              const SizedBox(width: AppSizes.md),
            ],
            _buildIconButton(
              context,
              icon: Iconsax.notification,
              onTap: () => context.go('/customer/notifications'),
            ),
            const SizedBox(width: AppSizes.sm),
            _buildIconButton(
              context,
              icon: Iconsax.bag_2,
              onTap: () => context.go('/customer/cart'),
              badgeCount: cartCount,
              selected: activeSection == 'cart',
            ),
            const SizedBox(width: AppSizes.sm),
            _buildIconButton(
              context,
              icon: Iconsax.user,
              onTap: () => context.go('/customer/profile'),
              selected: activeSection == 'profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(
    BuildContext context, {
    required String label,
    required String route,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton(
        onPressed: () => context.go(route),
        style: TextButton.styleFrom(
          foregroundColor: isSelected
              ? AppColors.primary
              : AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          backgroundColor: isSelected
              ? AppColors.primarySoft
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            letterSpacing: -0.1,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/customer/search'),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            const Icon(
              Iconsax.search_normal,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                'Search products, recipes...',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: const Icon(
                Iconsax.setting_4,
                color: Colors.white,
                size: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
    bool selected = false,
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
              color: selected
                  ? AppColors.primarySoft
                  : AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.22)
                    : AppColors.grey200,
              ),
            ),
            child: Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textPrimary,
              size: 20,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
