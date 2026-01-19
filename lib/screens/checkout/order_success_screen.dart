import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../widgets/custom_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              const Spacer(),
              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.tick_circle5,
                  size: 64,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Text(
                'Order Placed!',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Your order has been successfully placed',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
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
                          ? Formatters.formatDateTime(order.estimatedDelivery!)
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
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/order-tracking',
                  arguments: order,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              CustomButton(
                text: 'Back to Home',
                isOutlined: true,
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall,
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium,
        ),
      ],
    );
  }
}
