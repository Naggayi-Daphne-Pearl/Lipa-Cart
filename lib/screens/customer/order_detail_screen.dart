import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_order_status_colors.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/app_loading_indicator.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    final auth = context.read<AuthProvider>();
    final orderService = context.read<OrderService>();

    if (auth.token != null) {
      await orderService.getOrder(auth.token!, widget.orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Consumer2<AuthProvider, OrderService>(
        builder: (context, auth, orderService, _) {
          if (orderService.isLoading) {
            return const AppLoadingPage();
          }

          final order = orderService.currentOrder;
          if (order == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Order not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/customer/home');
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order status header
                Container(
                  color: AppColors.primarySoft,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order.orderNumber}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                order.createdAt.toString().split('.')[0],
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _getProgressValue(order.status),
                        minHeight: 4,
                        backgroundColor: AppColors.grey200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.statusLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Order items
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          title: const Text('Order items'),
                          subtitle: const Text('TODO: Load items from API'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Delivery address
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery address from API',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Expected delivery: ${order.deliveredAt?.toString() ?? 'TBD'}',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Shopper & Rider info
                if (order.shopperId != null || order.riderId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.shopperId != null) ...[
                          const Text(
                            'Your Shopper',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              leading: Icon(Icons.person_outline),
                              title: const Text('Shopper info'),
                              subtitle: const Text('Loading from API...'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (order.riderId != null) ...[
                          const Text(
                            'Your Rider',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              leading: Icon(Icons.local_shipping_outlined),
                              title: const Text('Rider info'),
                              subtitle: const Text('Loading from API...'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),

                // Price breakdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _priceRow('Subtotal', order.subtotal),
                          _priceRow('Service Fee', order.serviceFee),
                          _priceRow('Delivery Fee', order.deliveryFee),
                          if (order.pawaPayCharge > 0)
                            _priceRow('PawaPay Charge', order.pawaPayCharge),
                          if (order.discount > 0)
                            _priceRow('Discount', -order.discount),
                          const Divider(height: 16),
                          _priceRow(
                            'Total',
                            order.total,
                            isBold: true,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                if (order.isPending)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                _cancelOrder(context, auth, orderService),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Cancel Order'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                if (order.isDelivered && order.rating == null && !order.hasBeenRated)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.push(
                              '/customer/order-rating',
                              extra: order,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text('Rate This Order'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                // Rating summary (after rating is submitted)
                if (order.isDelivered && order.rating != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Your Rating',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (order.rating!.shopperRating != null)
                                _ratingRow('Shopper', order.rating!.shopperRating!),
                              if (order.rating!.riderRating != null)
                                _ratingRow('Rider', order.rating!.riderRating!),
                              if (order.rating!.overallRating != null)
                                _ratingRow('Overall', order.rating!.overallRating!),
                              if (order.rating!.comment != null &&
                                  order.rating!.comment!.isNotEmpty) ...
                                [
                                  const SizedBox(height: 8),
                                  Text(
                                    '"${order.rating!.comment}"',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _priceRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          'KES ${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _cancelOrder(
    BuildContext context,
    AuthProvider auth,
    OrderService orderService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('You will receive a refund for cancelled orders'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await orderService.cancelOrder(auth.token!, widget.orderId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order cancelled')));
      }
    }
  }

  Widget _ratingRow(String label, int stars) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    final t = AppOrderStatusColors.triple(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: t.$1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        t.$3,
        style: TextStyle(color: t.$2, fontWeight: FontWeight.w500),
      ),
    );
  }

  double _getProgressValue(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return 0.2;
      case OrderStatus.shopperAssigned:
        return 0.3;
      case OrderStatus.shopping:
        return 0.4;
      case OrderStatus.readyForDelivery:
        return 0.6;
      case OrderStatus.riderAssigned:
        return 0.7;
      case OrderStatus.inTransit:
        return 0.8;
      case OrderStatus.delivered:
        return 1.0;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return 0;
      case OrderStatus.paymentProcessing:
        return 0.1;
    }
  }
}
