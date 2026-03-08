import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/shopper_button.dart';

class ShopperActiveTasksScreen extends StatefulWidget {
  const ShopperActiveTasksScreen({super.key});

  @override
  State<ShopperActiveTasksScreen> createState() =>
      _ShopperActiveTasksScreenState();
}

class _ShopperActiveTasksScreenState extends State<ShopperActiveTasksScreen> {
  @override
  void initState() {
    super.initState();
    _validateRoleAndLoad();
  }

  void _validateRoleAndLoad() {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user?.role != UserRole.shopper) {
      Future.microtask(() {
        GoRouter.of(context).go(
          authProvider.user?.role == UserRole.admin
              ? '/admin/dashboard'
              : authProvider.user?.role == UserRole.rider
                  ? '/rider/home'
                  : '/customer/home',
        );
      });
      return;
    }

    // Load active tasks
    final shopperProvider = context.read<ShopperProvider>();
    final token = authProvider.token;
    final userDocId = authProvider.user?.documentId;
    if (token != null && userDocId != null) {
      shopperProvider.fetchActiveTasks(token, userDocId);
    }
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final shopper = context.read<ShopperProvider>();
    final token = auth.token;
    final userDocId = auth.user?.documentId;
    if (token != null && userDocId != null) {
      await shopper.fetchActiveTasks(token, userDocId);
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.shopping:
        return Colors.blue;
      case OrderStatus.readyForDelivery:
        return Colors.green;
      case OrderStatus.confirmed:
        return AppColors.accent;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Assigned';
      case OrderStatus.shopping:
        return 'Shopping';
      case OrderStatus.readyForDelivery:
        return 'Ready for Pickup';
      default:
        return status.displayName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Tasks')),
      body: Consumer<ShopperProvider>(
        builder: (context, shopper, _) {
          if (shopper.isLoading) {
            return const AppLoadingPage();
          }

          if (shopper.activeTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No active tasks',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accept a task from available orders',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ShopperButton.primary(
                      text: 'Browse Available Tasks',
                      icon: Icons.search_rounded,
                      onPressed: () => context.go('/shopper/available-tasks'),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shopper.activeTasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(shopper.activeTasks[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(Order order) {
    final itemCount = order.items.length;
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/shopper/shopping-checklist', extra: order),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.orderNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Delivery address
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddress.fullAddress,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Items summary
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '$itemCount items',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    Formatters.formatCurrency(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action button
              SizedBox(
                width: double.infinity,
                child: order.status == OrderStatus.readyForDelivery
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Awaiting Rider Pickup'),
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.green.withValues(alpha: 0.3),
                          disabledForegroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        icon: Icon(
                          order.status == OrderStatus.shopping
                              ? Icons.checklist
                              : Icons.shopping_cart,
                        ),
                        label: Text(
                          order.status == OrderStatus.shopping
                              ? 'Continue Shopping'
                              : 'Start Shopping',
                        ),
                        onPressed: () => context.go(
                          '/shopper/shopping-checklist',
                          extra: order,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: order.status == OrderStatus.shopping
                              ? Colors.blue
                              : AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
