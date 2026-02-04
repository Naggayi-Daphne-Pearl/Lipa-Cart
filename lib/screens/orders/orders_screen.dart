import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveContainer(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: EdgeInsets.all(
                    context.responsive<double>(
                      mobile: AppSizes.lg,
                      tablet: AppSizes.xl,
                      desktop: 24.0,
                    ),
                  ),
                  child: Text(
                    'My Orders',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: context.responsive<double>(
                        mobile: 26.0,
                        tablet: 30.0,
                        desktop: 34.0,
                      ),
                    ),
                  ),
                ),

                // Active Orders Section
                if (orderProvider.activeOrders.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.horizontalPadding,
                    ),
                    child: Text(
                      'ACTIVE ORDERS',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: context.responsive<double>(
                      mobile: AppSizes.sm,
                      tablet: AppSizes.md,
                      desktop: AppSizes.md,
                    ),
                  ),
                  ...orderProvider.activeOrders.map(
                    (order) => _buildActiveOrderCard(context, order),
                  ),
                ],

                // Past Orders Section
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    context.responsive<double>(
                      mobile: AppSizes.lg,
                      tablet: AppSizes.xl,
                      desktop: 24.0,
                    ),
                    context.horizontalPadding,
                    AppSizes.sm,
                  ),
                  child: Text(
                    'PAST ORDERS',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (orderProvider.pastOrders.isEmpty)
                  _buildEmptyState(context, 'No past orders yet')
                else if (context.isMobile)
                  ...orderProvider.pastOrders.map(
                    (order) => _buildPastOrderCard(context, order),
                  )
                else
                  _buildPastOrdersGrid(context, orderProvider.pastOrders),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPastOrdersGrid(BuildContext context, List<Order> orders) {
    final columns = context.responsive<int>(
      mobile: 1,
      tablet: 2,
      desktop: 2,
      largeDesktop: 3,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: context.responsive<double>(
          mobile: AppSizes.md,
          tablet: AppSizes.lg,
          desktop: 24.0,
        ),
        mainAxisSpacing: context.responsive<double>(
          mobile: AppSizes.md,
          tablet: AppSizes.lg,
          desktop: 24.0,
        ),
        childAspectRatio: context.responsive<double>(
          mobile: 1.0,
          tablet: 2.0,
          desktop: 2.2,
        ),
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) =>
          _buildPastOrderCard(context, orders[index]),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context, Order order) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: context.responsive<double>(
          mobile: AppSizes.sm,
          tablet: AppSizes.md,
          desktop: AppSizes.md,
        ),
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(
          context.responsive<double>(
            mobile: AppSizes.radiusXl,
            tablet: 20.0,
            desktop: 24.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: context.responsive<double>(
              mobile: 8.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Info
          Padding(
            padding: EdgeInsets.all(
              context.responsive<double>(
                mobile: AppSizes.lg,
                tablet: AppSizes.xl,
                desktop: 24.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: context.responsive<double>(
                          mobile: 12.0,
                          tablet: 13.0,
                          desktop: 14.0,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(
                        '/customer/order-tracking',
                        extra: order,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive<double>(
                            mobile: AppSizes.md,
                            tablet: AppSizes.lg,
                            desktop: AppSizes.lg,
                          ),
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                        ),
                        child: Text(
                          'Track Order',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  _getEstimatedTime(order),
                  style: AppTextStyles.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: context.responsive<double>(
                      mobile: 22.0,
                      tablet: 26.0,
                      desktop: 28.0,
                    ),
                  ),
                ),
                SizedBox(
                  height: context.responsive<double>(
                    mobile: AppSizes.lg,
                    tablet: AppSizes.xl,
                    desktop: AppSizes.xl,
                  ),
                ),
                // Progress Indicator
                _buildProgressIndicator(context, order.status),
              ],
            ),
          ),
          // Rider Info
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSizes.radiusXl),
                bottomRight: Radius.circular(AppSizes.radiusXl),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(
                    Iconsax.truck_fast,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John K.',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Your delivery rider',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(Iconsax.call, color: AppColors.accent, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, OrderStatus status) {
    final stages = [
      ('Ordered', OrderStatus.pending),
      ('Shopping', OrderStatus.shopping),
      ('Ready', OrderStatus.readyForDelivery),
      ('On', OrderStatus.inTransit),
      ('Delivered', OrderStatus.delivered),
    ];

    final currentIndex = stages.indexWhere((s) => s.$2 == status);
    final dotSize = context.responsive<double>(
      mobile: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );
    final currentDotSize = context.responsive<double>(
      mobile: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );

    return Row(
      children: [
        // Progress line
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background line
              Container(
                height: context.responsive<double>(
                  mobile: 3.0,
                  tablet: 4.0,
                  desktop: 5.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Progress line
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: currentIndex >= 0
                      ? (currentIndex + 1) / stages.length
                      : 0.2,
                  child: Container(
                    height: context.responsive<double>(
                      mobile: 3.0,
                      tablet: 4.0,
                      desktop: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Stage dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: stages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stage = entry.value;
                  final isCompleted = currentIndex >= index;
                  final isCurrent = currentIndex == index;

                  return Column(
                    children: [
                      Container(
                        width: isCurrent ? currentDotSize : dotSize,
                        height: isCurrent ? currentDotSize : dotSize,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        stage.$1,
                        style: AppTextStyles.caption.copyWith(
                          color: isCompleted
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          fontSize: context.responsive<double>(
                            mobile: 10.0,
                            tablet: 11.0,
                            desktop: 12.0,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPastOrderCard(BuildContext context, Order order) {
    return Container(
      margin: EdgeInsets.only(
        left: context.isMobile ? context.horizontalPadding : 0,
        right: context.isMobile ? context.horizontalPadding : 0,
        bottom: context.isMobile ? AppSizes.md : 0,
      ),
      padding: EdgeInsets.all(
        context.responsive<double>(
          mobile: AppSizes.md,
          tablet: AppSizes.lg,
          desktop: 20.0,
        ),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          context.responsive<double>(
            mobile: AppSizes.radiusLg,
            tablet: AppSizes.radiusXl,
            desktop: 20.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: context.responsive<double>(
              mobile: 8.0,
              tablet: 12.0,
              desktop: 16.0,
            ),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order header
          Row(
            children: [
              Container(
                width: context.responsive<double>(
                  mobile: 40.0,
                  tablet: 44.0,
                  desktop: 48.0,
                ),
                height: context.responsive<double>(
                  mobile: 40.0,
                  tablet: 44.0,
                  desktop: 48.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  color: AppColors.primary,
                  size: context.responsive<double>(
                    mobile: 20.0,
                    tablet: 22.0,
                    desktop: 24.0,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsive<double>(
                          mobile: 14.0,
                          tablet: 15.0,
                          desktop: 16.0,
                        ),
                      ),
                    ),
                    Text(
                      Formatters.formatDate(order.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.tick_circle,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delivered',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          // Divider
          Divider(color: AppColors.grey200, height: 1),
          const SizedBox(height: AppSizes.md),
          // Order details
          Row(
            children: [
              Icon(Iconsax.location, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  order.deliveryAddress.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                Formatters.formatCurrency(order.total),
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: context.responsive<double>(
                    mobile: 14.0,
                    tablet: 15.0,
                    desktop: 16.0,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Icon(
                Iconsax.arrow_right_3,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          // Reorder button
          GestureDetector(
            onTap: () {
              // TODO: Implement reorder functionality
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.refresh, color: AppColors.accent, size: 18),
                const SizedBox(width: AppSizes.xs),
                Text(
                  'Reorder',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Center(
        child: Column(
          children: [
            Container(
              width: context.responsive<double>(
                mobile: 80.0,
                tablet: 100.0,
                desktop: 120.0,
              ),
              height: context.responsive<double>(
                mobile: 80.0,
                tablet: 100.0,
                desktop: 120.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.receipt_item,
                size: context.responsive<double>(
                  mobile: 40.0,
                  tablet: 48.0,
                  desktop: 56.0,
                ),
                color: AppColors.grey400,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: context.responsive<double>(
                  mobile: 14.0,
                  tablet: 15.0,
                  desktop: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEstimatedTime(Order order) {
    switch (order.status) {
      case OrderStatus.pending:
        return 'Processing...';
      case OrderStatus.confirmed:
        return '45-60 min away';
      case OrderStatus.shopping:
        return '35-45 min away';
      case OrderStatus.readyForDelivery:
        return '25-35 min away';
      case OrderStatus.inTransit:
        return '15-25 min away';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
