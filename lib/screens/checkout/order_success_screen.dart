import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/shopping_list.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../widgets/custom_button.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Order? order;
  final bool isGuest;

  const OrderSuccessScreen({super.key, this.order, this.isGuest = false});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Order _order;
  late bool _isGuest;

  @override
  void initState() {
    super.initState();
    _isGuest = widget.isGuest;

    // Handle both direct Order and Map<String, dynamic> formats
    if (widget.order != null) {
      _order = widget.order!;
    } else {
      // Fallback - should not happen in normal flow
      _order = Order(
        id: 'unknown',
        orderNumber: 'N/A',
        items: [],
        deliveryAddress: Address(
          id: '',
          label: '',
          fullAddress: '',
          latitude: 0,
          longitude: 0,
          isDefault: false,
        ),
        subtotal: 0,
        serviceFee: 0,
        deliveryFee: 0,
        total: 0,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        paymentMethod: PaymentMethod.mobileMoney,
        isPaid: false,
      );
    }

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Order get order => _order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                const Spacer(),
                // Animated Success icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Iconsax.tick_circle5,
                            size: 64,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSizes.xl),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text('Order Placed!', style: AppTextStyles.h2),
                ),
                const SizedBox(height: AppSizes.sm),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Your order has been successfully placed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Order details card
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Order Number', order.orderNumber),
                      const SizedBox(height: AppSizes.sm),
                      _buildDetailRow(
                        'Estimated Delivery',
                        order.estimatedDelivery != null
                            ? Formatters.formatDateTime(
                                order.estimatedDelivery!,
                              )
                            : 'Calculating...',
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _buildDetailRow(
                        'Total Amount',
                        Formatters.formatCurrency(order.total),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _buildDetailRow(
                        'Payment',
                        order.paymentMethod.displayName,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Save as shopping list
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final listProvider = context.read<ShoppingListProvider>();
                      final authToken = context.read<AuthProvider>().token;
                      // Create a new list from order items
                      listProvider.createList(
                        name: 'Order #${order.orderNumber}',
                        emoji: '🛒',
                        color: '#15874B',
                        authToken: authToken,
                      );
                      // Get the newly created list
                      final newList = listProvider.lists.last;
                      for (final item in order.items) {
                        final listItem = ShoppingListItem(
                          id: '${DateTime.now().millisecondsSinceEpoch}_${item.product.name}',
                          name: item.product.name,
                          quantity: item.quantity.toInt(),
                          unit: item.product.unit,
                          unitPrice: item.product.price,
                          linkedProduct: item.product,
                        );
                        listProvider.addItemToList(newList.id, listItem, authToken: authToken);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saved as shopping list for easy reordering!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Iconsax.clipboard_text, size: 18),
                    label: const Text('Save as Shopping List'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const Spacer(),

                // Buttons
                if (_isGuest)
                  // Guest: Show sign-in option
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomButton(
                        text: 'Sign In to Track Your Order',
                        onPressed: () => context.go('/login'),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      CustomButton(
                        text: 'Continue Shopping',
                        isOutlined: true,
                        onPressed: () => context.go('/customer/home'),
                      ),
                    ],
                  )
                else
                  // Authenticated: Show tracking and home buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomButton(
                        text: 'Track Order',
                        onPressed: () => context.go(
                          '/customer/order-tracking',
                          extra: order,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      CustomButton(
                        text: 'Back to Home',
                        isOutlined: true,
                        onPressed: () => context.go('/customer/home'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.labelMedium),
      ],
    );
  }
}
