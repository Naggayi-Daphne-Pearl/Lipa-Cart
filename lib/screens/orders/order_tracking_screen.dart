import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer/home');
            }
          },
        ),
        title: const Text('Order Details & Tracking'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
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
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.1,
                            ),
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
                      _buildTrackingTimeline(context),
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
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
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
                                            item
                                                .specialInstructions!
                                                .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        // Shopper feedback (found status + notes)
                                        if (item.found != null) ...[
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  item.found! ? Icons.check_circle : Icons.cancel,
                                                  size: 14,
                                                  color: item.found! ? Colors.green : Colors.red,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  item.found! ? 'Found' : 'Not found',
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: item.found! ? Colors.green : Colors.red,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (item.actualPrice != null && item.actualPrice != item.product.price) ...[
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Actual: ${Formatters.formatCurrency(item.actualPrice!)}',
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (item.shopperNotes != null && item.shopperNotes!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                                              ),
                                              child: Text(
                                                'Shopper: ${item.shopperNotes}',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: Colors.blue[700],
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
                      // Show adjusted total if items have been shopped
                      Builder(builder: (context) {
                        final hasShoppedItems = order.items.any((i) => i.found != null);
                        if (!hasShoppedItems) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total', style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700)),
                              Text(Formatters.formatCurrency(order.total),
                                style: AppTextStyles.h4.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
                            ],
                          );
                        }

                        // Calculate actual subtotal from found items only
                        double actualSubtotal = 0;
                        for (final item in order.items) {
                          if (item.found == true) {
                            actualSubtotal += (item.actualPrice ?? item.product.price) * item.quantity;
                          }
                        }
                        final actualServiceFee = actualSubtotal * 0.05;
                        final actualTotal = actualSubtotal + actualServiceFee + order.deliveryFee;
                        final hasDifference = (actualTotal - order.total).abs() > 1;

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Estimated Total', style: AppTextStyles.bodyMedium.copyWith(
                                  decoration: hasDifference ? TextDecoration.lineThrough : null,
                                  color: hasDifference ? AppColors.textSecondary : AppColors.textDark,
                                )),
                                Text(Formatters.formatCurrency(order.total),
                                  style: AppTextStyles.labelMedium.copyWith(
                                    decoration: hasDifference ? TextDecoration.lineThrough : null,
                                    color: hasDifference ? AppColors.textSecondary : AppColors.textDark,
                                  )),
                              ],
                            ),
                            if (hasDifference) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Adjusted Total', style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700)),
                                  Text(Formatters.formatCurrency(actualTotal),
                                    style: AppTextStyles.h4.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Adjusted based on item availability',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ] else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total', style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w700)),
                                  Text(Formatters.formatCurrency(order.total),
                                    style: AppTextStyles.h4.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w700)),
                                ],
                              ),
                          ],
                        );
                      }),
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
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
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
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.2,
                            ),
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

                // Shopper & Rider info
                if (order.shopperName != null || order.riderName != null) ...[
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
                            const Icon(Iconsax.people, color: AppColors.primaryOrange, size: 20),
                            const SizedBox(width: AppSizes.sm),
                            Text('Your Team', style: AppTextStyles.h5),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        if (order.shopperName != null)
                          _buildPersonRow(
                            context: context,
                            icon: Iconsax.shopping_bag,
                            role: 'Shopper',
                            name: order.shopperName!,
                            phone: order.shopperPhone,
                          ),
                        if (order.shopperName != null && order.riderName != null)
                          const Divider(height: AppSizes.lg),
                        if (order.riderName != null)
                          _buildPersonRow(
                            context: context,
                            icon: Iconsax.truck_fast,
                            role: 'Rider',
                            name: order.riderName!,
                            phone: order.riderPhone,
                          ),
                      ],
                    ),
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

  void _showCallDialog(BuildContext context, String role, String name, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role == 'Rider' ? Iconsax.truck_fast : Iconsax.shopping_bag,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: AppTextStyles.h5),
              const SizedBox(height: 4),
              Text(role, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(phone, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              // Call button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    try {
                      launchUrl(Uri(scheme: 'tel', path: phone));
                    } catch (_) {
                      Clipboard.setData(ClipboardData(text: phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$phone copied — open your phone app to call')),
                      );
                    }
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: Text('Call $role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Copy button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$phone copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Number'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline(BuildContext context) {
    final steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.shopperAssigned,
      OrderStatus.shopping,
      OrderStatus.readyForDelivery,
      OrderStatus.riderAssigned,
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
                    // Show person name + call button on relevant steps
                    if (status == OrderStatus.shopperAssigned && order.shopperName != null && isCompleted)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${order.shopperName} is your shopper',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          if (order.shopperPhone != null)
                            GestureDetector(
                              onTap: () => _showCallDialog(context, 'Shopper', order.shopperName!, order.shopperPhone!),
                              child: const Icon(Iconsax.call, size: 16, color: AppColors.primaryGreen),
                            ),
                        ],
                      )
                    else if (status == OrderStatus.riderAssigned && order.riderName != null && isCompleted)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${order.riderName} is your rider',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          if (order.riderPhone != null)
                            GestureDetector(
                              onTap: () => _showCallDialog(context, 'Rider', order.riderName!, order.riderPhone!),
                              child: const Icon(Iconsax.call, size: 16, color: AppColors.primaryGreen),
                            ),
                        ],
                      )
                    else if (status == OrderStatus.inTransit && order.riderName != null && isCompleted)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${order.riderName} is delivering',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          if (order.riderPhone != null)
                            GestureDetector(
                              onTap: () => _showCallDialog(context, 'Rider', order.riderName!, order.riderPhone!),
                              child: const Icon(Iconsax.call, size: 16, color: AppColors.primaryGreen),
                            ),
                        ],
                      )
                    else
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

  Widget _buildPersonRow({
    required BuildContext context,
    required IconData icon,
    required String role,
    required String name,
    String? phone,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primaryOrange, size: 20),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(role, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              Text(name, style: AppTextStyles.labelMedium),
            ],
          ),
        ),
        if (phone != null && phone.isNotEmpty)
          IconButton(
            onPressed: () => _showCallDialog(context, role, name, phone),
            icon: const Icon(Iconsax.call, color: AppColors.primaryGreen, size: 20),
            tooltip: 'Call $role',
          ),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
      case OrderStatus.shopperAssigned:
      case OrderStatus.shopping:
      case OrderStatus.readyForDelivery:
      case OrderStatus.riderAssigned:
      case OrderStatus.inTransit:
        return AppColors.info;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }
}
