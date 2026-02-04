import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../widgets/custom_button.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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

  Order get order => widget.order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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

                const Spacer(),

                // Buttons
                CustomButton(
                  text: 'Track Order',
                  onPressed: () =>
                      context.go('/customer/order-tracking', extra: order),
                ),
                const SizedBox(height: AppSizes.sm),
                CustomButton(
                  text: 'Back to Home',
                  isOutlined: true,
                  onPressed: () => context.go('/customer/home'),
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
