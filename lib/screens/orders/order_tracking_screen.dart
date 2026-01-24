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

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Track Order'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.elegantBgGradient,
        ),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: AppTextStyles.h5,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          order.status.displayName,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Placed on ${Formatters.formatDateTime(order.createdAt)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  if (order.estimatedDelivery != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Est. delivery: ${Formatters.formatDateTime(order.estimatedDelivery!)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Tracking timeline
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Status', style: AppTextStyles.h5),
                  const SizedBox(height: AppSizes.md),
                  _buildTrackingTimeline(),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Shopper info (if assigned)
            if (order.shopperName != null) ...[
              _buildPersonCard(
                title: 'Your Shopper',
                name: order.shopperName!,
                phone: order.shopperPhone,
                icon: Iconsax.shopping_bag,
              ),
              const SizedBox(height: AppSizes.md),
            ],

            // Rider info (if assigned)
            if (order.riderName != null) ...[
              _buildPersonCard(
                title: 'Delivery Rider',
                name: order.riderName!,
                phone: order.riderPhone,
                icon: Iconsax.truck_fast,
              ),
              const SizedBox(height: AppSizes.md),
            ],

            // Delivery address
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    order.deliveryAddress.label,
                    style: AppTextStyles.labelMedium,
                  ),
                  Text(
                    order.deliveryAddress.fullAddress,
                    style: AppTextStyles.bodySmall,
                  ),
                  if (order.deliveryAddress.landmark != null)
                    Text(
                      'Near: ${order.deliveryAddress.landmark}',
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Order items
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Items', style: AppTextStyles.h5),
                  const SizedBox(height: AppSizes.md),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity.toInt()}x ${item.product.name}',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(item.totalPrice),
                              style: AppTextStyles.labelMedium,
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTextStyles.labelMedium),
                      Text(
                        Formatters.formatCurrency(order.total),
                        style: AppTextStyles.priceMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Help button
            CustomButton(
              text: 'Need Help?',
              isOutlined: true,
              icon: Iconsax.message_question,
              onPressed: () {},
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
        ),
      ),
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
                        ? Border.all(
                            color: AppColors.primaryGreen,
                            width: 2,
                          )
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
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
                        color:
                            isCompleted ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                    Text(
                      status.description,
                      style: AppTextStyles.caption,
                    ),
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
              icon: const Icon(
                Iconsax.call,
                color: AppColors.primaryGreen,
              ),
            ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Iconsax.message,
              color: AppColors.primaryOrange,
            ),
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
