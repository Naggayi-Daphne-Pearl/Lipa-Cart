import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_bottom_nav.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Order order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order Details & Tracking'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header card
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order number and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.orderNumber}',
                              style: AppTextStyles.h5.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Placed on ${Formatters.formatDateTime(order.createdAt)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              order.status,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: Text(
                            order.status.displayName,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Delivery time estimate
                    if (order.estimatedDelivery != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.clock,
                              color: AppColors.primaryGreen,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Est. delivery: ${Formatters.formatDateTime(order.estimatedDelivery!)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Tracking timeline
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.routing,
                          color: AppColors.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text('Order Timeline', style: AppTextStyles.h5),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    _buildTrackingTimeline(),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Order items details
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.shopping_bag,
                          color: AppColors.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          'Items Ordered (${order.itemCount})',
                          style: AppTextStyles.h5,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    ...order.items.asMap().entries.map((entry) {
                      final isLast = entry.key == order.items.length - 1;
                      final item = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: isLast ? 0 : AppSizes.md,
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusSm,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item.quantity.toInt()}x',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primaryOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${Formatters.formatCurrency(item.product.price)} per unit',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (item.specialInstructions != null &&
                                          item.specialInstructions!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryOrange
                                                  .withValues(alpha: 0.05),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppSizes.radiusXs,
                                                  ),
                                            ),
                                            child: Text(
                                              'Note: ${item.specialInstructions}',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Text(
                                  Formatters.formatCurrency(item.totalPrice),
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSizes.md,
                                ),
                                child: Divider(
                                  color: AppColors.lightGrey.withValues(
                                    alpha: 0.5,
                                  ),
                                  height: 1,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Pricing breakdown
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.calculator,
                          color: AppColors.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text('Price Breakdown', style: AppTextStyles.h5),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    _buildPricingRow('Subtotal', order.subtotal),
                    const SizedBox(height: AppSizes.sm),
                    _buildPricingRow('Service Fee (5%)', order.serviceFee),
                    const SizedBox(height: AppSizes.sm),
                    if (order.deliveryFee > 0)
                      _buildPricingRow('Delivery Fee', order.deliveryFee)
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery Fee',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusXs,
                                ),
                              ),
                              child: Text(
                                'FREE',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Divider(
                      color: AppColors.lightGrey.withValues(alpha: 0.5),
                      height: 1,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: AppTextStyles.h5.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(order.total),
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: order.isPaid
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            order.isPaid ? Iconsax.verify : Iconsax.clock,
                            color: order.isPaid
                                ? AppColors.success
                                : AppColors.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.isPaid ? 'Paid' : 'Pending Payment',
                            style: AppTextStyles.caption.copyWith(
                              color: order.isPaid
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Delivery address
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.location,
                          color: AppColors.primaryOrange,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text('Delivery Address', style: AppTextStyles.h5),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        border: Border.all(
                          color: AppColors.primaryOrange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.deliveryAddress.label,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            order.deliveryAddress.fullAddress,
                            style: AppTextStyles.bodySmall,
                          ),
                          if (order.deliveryAddress.landmark != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.map,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Near: ${order.deliveryAddress.landmark}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Shopper info (if assigned)
              if (order.shopperName != null) ...[
                _buildPersonCard(
                  title: 'Your Shopper',
                  name: order.shopperName!,
                  phone: order.shopperPhone,
                  icon: Iconsax.shopping_bag,
                ),
                const SizedBox(height: AppSizes.lg),
              ],

              // Rider info (if assigned)
              if (order.riderName != null) ...[
                _buildPersonCard(
                  title: 'Delivery Rider',
                  name: order.riderName!,
                  phone: order.riderPhone,
                  icon: Iconsax.truck_fast,
                ),
                const SizedBox(height: AppSizes.lg),
              ],

              // Help button
              CustomButton(
                text: 'Need Help?',
                isOutlined: true,
                icon: Iconsax.message_question,
                onPressed: () {},
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          Formatters.formatCurrency(amount),
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingTimeline() {
    final steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.shopping,
      OrderStatus.readyForDelivery,
      OrderStatus.inTransit,
      OrderStatus.delivered,
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = order.status.stepIndex >= status.stepIndex;
        final isCurrent = order.status == status;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primaryGreen
                        : AppColors.lightGrey,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: AppColors.primaryGreen, width: 2)
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted
                        ? AppColors.primaryGreen
                        : AppColors.lightGrey,
                  ),
              ],
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.displayName,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isCompleted
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                    ),
                    Text(status.description, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPersonCard({
    required String title,
    required String name,
    String? phone,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: AppColors.primaryOrange),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                Text(name, style: AppTextStyles.labelMedium),
              ],
            ),
          ),
          if (phone != null)
            IconButton(
              onPressed: () {},
              icon: const Icon(Iconsax.call, color: AppColors.primaryGreen),
            ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Iconsax.message, color: AppColors.primaryOrange),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
      case OrderStatus.shopping:
      case OrderStatus.readyForDelivery:
      case OrderStatus.inTransit:
        return AppColors.info;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }
}
