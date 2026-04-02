import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_loading_indicator.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const double _freeDeliveryThreshold = 50000;

  void _handleProceedToCheckout(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAuthenticated) {
      // User is authenticated, proceed to checkout
      context.go('/customer/checkout');
    } else {
      // User is not authenticated, show Sign In / Guest options
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        builder: (context) => _GuestOrSignInSheet(),
      );
    }
  }

  Color _getProductBgColor(String categoryName) => Formatters.getProductBgColor(categoryName);

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final deliveryProgress = (cartProvider.subtotal / _freeDeliveryThreshold)
        .clamp(0.0, 1.0);
    final amountToFreeDelivery = _freeDeliveryThreshold - cartProvider.subtotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: cartProvider.isEmpty
              ? _buildEmptyCart(context)
              : Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.pop(context);
                              } else {
                                GoRouter.of(context).go('/customer/home');
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                                border: Border.all(
                                  color: AppColors.grey200,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(Iconsax.arrow_left, size: 20),
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cart',
                                  style: AppTextStyles.h3.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${cartProvider.itemCount} items in your cart',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                _showClearCartDialog(context, cartProvider),
                            child: Text(
                              'Clear All',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cart items
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                        ),
                        itemCount: cartProvider.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSizes.md),
                        itemBuilder: (context, index) {
                          final item = cartProvider.items[index];
                          return _buildCartItem(context, item, cartProvider);
                        },
                      ),
                    ),

                    // Free delivery progress
                    if (amountToFreeDelivery > 0)
                      Container(
                        margin: const EdgeInsets.all(AppSizes.lg),
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.truck_fast,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Text(
                                    deliveryProgress > 0.8
                                        ? '🎉 Almost there! Just ${Formatters.formatCurrency(amountToFreeDelivery)} more for free delivery'
                                        : 'Add ${Formatters.formatCurrency(amountToFreeDelivery)} more for free delivery',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: deliveryProgress > 0.8 ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.sm),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull,
                              ),
                              child: LinearProgressIndicator(
                                value: deliveryProgress,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Order summary
                    Container(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppSizes.radiusXl),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSummaryRow(
                              'Subtotal',
                              Formatters.formatCurrency(cartProvider.subtotal),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            _buildSummaryRow(
                              'Service Fee',
                              Formatters.formatCurrency(
                                cartProvider.serviceFee,
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            _buildSummaryRow(
                              'Delivery',
                              cartProvider.subtotal >= _freeDeliveryThreshold
                                  ? 'FREE'
                                  : Formatters.formatCurrency(
                                      cartProvider.deliveryFee,
                                    ),
                              isFree:
                                  cartProvider.subtotal >=
                                  _freeDeliveryThreshold,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSizes.md,
                              ),
                              child: Divider(color: AppColors.grey200),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: AppTextStyles.h5.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  Formatters.formatCurrency(cartProvider.total),
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.lg),
                            GestureDetector(
                              onTap: () => _handleProceedToCheckout(context),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.md,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusFull,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.card,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSizes.sm),
                                    Text(
                                      'Proceed to Checkout',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.xs),
                                    Icon(
                                      Iconsax.arrow_right_3,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Continue Shopping button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSizes.lg, 0, AppSizes.lg, AppSizes.lg),
                      child: TextButton.icon(
                        onPressed: () => GoRouter.of(context).go('/customer/categories'),
                        icon: const Icon(Iconsax.arrow_left_2, size: 16),
                        label: const Text('Continue Shopping'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: AppColors.shadowSm,
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getProductBgColor(item.product.categoryName),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: CachedNetworkImage(
                imageUrl: item.product.image,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: AppLoadingIndicator.small(),
                ),
                errorWidget: (context, url, error) =>
                    Icon(Iconsax.image, color: AppColors.grey400),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'per ${item.product.unit}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete button
                    GestureDetector(
                      onTap: () => cartProvider.removeFromCart(item.product.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Iconsax.trash,
                          color: AppColors.error,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      Formatters.formatCurrency(item.totalPrice),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                cartProvider.decrementQuantity(item.product.id),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                            ),
                            child: Text(
                              item.quantity.toInt().toString(),
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                cartProvider.incrementQuantity(item.product.id),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusSm,
                                ),
                              ),
                              child: const Icon(
                                Iconsax.add,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.bag_2,
                size: 56,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Your cart is empty',
              style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Add some fresh groceries to get started',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xl,
                  vertical: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  'Start Shopping',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: isFree ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isFree ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text('Clear Cart', style: AppTextStyles.h5),
        content: Text(
          'Are you sure you want to remove all items?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal sheet offering Sign In or Guest checkout options
class _GuestOrSignInSheet extends StatelessWidget {
  const _GuestOrSignInSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proceed to Checkout', style: AppTextStyles.h4),
          const SizedBox(height: AppSizes.md),
          Text(
            'Sign in to save order history and track deliveries',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          // Sign In button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final returnRoute = Uri.encodeComponent('/customer/checkout');
                context.go('/login?return=$returnRoute');
              },
              icon: const Icon(Iconsax.login),
              label: const Text('Sign In / Register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
