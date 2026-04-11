import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_order_status_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../widgets/app_loading_indicator.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final auth = context.read<AuthProvider>();
    final orderService = context.read<OrderService>();

    final userId = auth.user?.id;
    if (auth.user != null && auth.token != null && userId != null) {
      await orderService.fetchOrders(
        auth.token!,
        auth.user?.documentId ?? userId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          if (orderService.isLoading) {
            return const AppLoadingPage();
          }

          if (orderService.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: AppColors.grey300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start shopping to place your first order',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/customer/categories'),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: orderService.orders.length,
            itemBuilder: (context, index) {
              final order = orderService.orders[index];
              return OrderCard(
                order: order,
                onTap: () => context.go('/customer/order/${order.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.createdAt.toString().split('.')[0],
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        'KES ${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, color: AppColors.grey400),
                ],
              ),
            ],
          ),
        ),
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
        style: TextStyle(
          color: t.$2,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

}
