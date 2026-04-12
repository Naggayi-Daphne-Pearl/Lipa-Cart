import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_order_status_colors.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _validateRoleAndLoad();
    });
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
    return AppOrderStatusColors.foreground(status);
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
      case OrderStatus.shopperAssigned:
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/shopper/home'),
        ),
        title: const Text('Active Tasks'),
      ),
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
              itemCount: shopper.activeTasks.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSummaryHeader(shopper.activeTasks);
                }
                return _buildTaskCard(shopper.activeTasks[index - 1]);
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
    final estimatedEarning = order.total * 0.10;

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
                  Expanded(
                    child: Text(
                      '#${order.orderNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
              const SizedBox(height: 6),
              Text(
                Formatters.formatDate(order.createdAt),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 15, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    'Estimated earning: ${Formatters.formatCurrency(estimatedEarning)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
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
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.3),
                          disabledForegroundColor: AppColors.primary,
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
                              ? AppColors.primary
                              : AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ),
              // Cancel Task button for assigned (not yet shopping) orders
              if (order.status == OrderStatus.confirmed || order.status == OrderStatus.shopperAssigned) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Task'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: () => _showCancelDialog(order),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(List<Order> tasks) {
    final assignedCount = tasks
        .where((o) => o.status == OrderStatus.confirmed || o.status == OrderStatus.shopperAssigned)
        .length;
    final shoppingCount = tasks.where((o) => o.status == OrderStatus.shopping).length;
    final readyCount = tasks.where((o) => o.status == OrderStatus.readyForDelivery).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _summaryChip('Assigned', assignedCount, AppColors.info),
          _summaryChip('Shopping', shoppingCount, AppColors.primary),
          _summaryChip('Ready', readyCount, AppColors.accent),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Task?'),
        content: const Text(
          'Are you sure you want to cancel this task? It will be returned to the available tasks pool.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Task'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final shopper = context.read<ShopperProvider>();
    final token = auth.token;
    final userDocId = auth.user?.documentId ?? auth.user?.id ?? '';

    if (token == null) return;

    final success = await shopper.unclaimTask(
      token,
      order.documentId ?? order.id,
      userDocId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Task cancelled successfully' : (shopper.error ?? 'Failed to cancel task'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
