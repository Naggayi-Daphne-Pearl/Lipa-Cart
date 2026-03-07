import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.green,
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
                    onPressed: () => Navigator.pop(context),
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
                  color: Colors.green[50],
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
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          _buildStatusBadge(order.status.name),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _getProgressValue(order.status.name),
                        minHeight: 4,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.statusLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
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
                                style: TextStyle(color: Colors.grey[600]),
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
                          if (order.discount > 0)
                            _priceRow('Discount', -order.discount),
                          const Divider(height: 16),
                          _priceRow(
                            'Total',
                            order.total,
                            isBold: true,
                            color: Colors.green,
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

                if (order.isDelivered)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showRatingDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Rate This Order'),
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

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate This Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How satisfied are you with this order?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(Icons.star, color: Colors.amber, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
      case 'payment_confirmed':
        bgColor = Colors.yellow[100]!;
        textColor = Colors.orange;
        label = 'Pending';
        break;
      case 'shopping':
      case 'ready_for_pickup':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue;
        label = 'Shopping';
        break;
      case 'in_transit':
        bgColor = Colors.purple[100]!;
        textColor = Colors.purple;
        label = 'In Transit';
        break;
      case 'delivered':
        bgColor = Colors.green[100]!;
        textColor = Colors.green;
        label = 'Delivered';
        break;
      case 'cancelled':
        bgColor = Colors.red[100]!;
        textColor = Colors.red;
        label = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
    );
  }

  double _getProgressValue(String status) {
    switch (status) {
      case 'pending':
      case 'payment_confirmed':
        return 0.2;
      case 'shopping':
        return 0.4;
      case 'ready_for_pickup':
        return 0.6;
      case 'in_transit':
        return 0.8;
      case 'delivered':
        return 1.0;
      default:
        return 0;
    }
  }
}
