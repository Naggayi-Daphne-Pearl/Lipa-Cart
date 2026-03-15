import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/shopper_button.dart';

class ShopperCompletedTasksScreen extends StatefulWidget {
  const ShopperCompletedTasksScreen({super.key});

  @override
  State<ShopperCompletedTasksScreen> createState() =>
      _ShopperCompletedTasksScreenState();
}

class _ShopperCompletedTasksScreenState
    extends State<ShopperCompletedTasksScreen> {
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

    final shopperProvider = context.read<ShopperProvider>();
    final token = authProvider.token;
    final userDocId = authProvider.user?.documentId;
    if (token != null && userDocId != null) {
      shopperProvider.fetchCompletedTasks(token, userDocId);
    }
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final shopper = context.read<ShopperProvider>();
    final token = auth.token;
    final userDocId = auth.user?.documentId;
    if (token != null && userDocId != null) {
      await shopper.fetchCompletedTasks(token, userDocId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completed Tasks')),
      body: Consumer<ShopperProvider>(
        builder: (context, shopper, _) {
          if (shopper.isLoading) {
            return const AppLoadingPage();
          }

          if (shopper.completedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No completed tasks yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
              itemCount: shopper.completedTasks.length,
              itemBuilder: (context, index) {
                return _buildCompletedCard(shopper.completedTasks[index]);
              },
            ),
          );
        },
      ),
    );
  }

  void _showCallDialog(String role, String name, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role == 'Rider' ? Icons.local_shipping : Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(role, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    launchUrl(Uri(scheme: 'tel', path: phone));
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: Text('Call $role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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

  Widget _buildCompletedCard(Order order) {
    final isCancelled = order.status == OrderStatus.cancelled;
    final isDelivered = order.status == OrderStatus.delivered;

    final String badgeText;
    final Color badgeColor;
    final IconData badgeIcon;

    if (isCancelled) {
      badgeText = 'Cancelled';
      badgeColor = Colors.red;
      badgeIcon = Icons.cancel;
    } else if (isDelivered) {
      badgeText = 'Delivered';
      badgeColor = AppColors.primary;
      badgeIcon = Icons.check_circle;
    } else if (order.status == OrderStatus.inTransit) {
      badgeText = 'In Transit';
      badgeColor = Colors.purple;
      badgeIcon = Icons.local_shipping;
    } else if (order.status == OrderStatus.readyForDelivery) {
      badgeText = 'Awaiting Rider';
      badgeColor = Colors.orange;
      badgeIcon = Icons.timer;
    } else if (order.status == OrderStatus.riderAssigned) {
      badgeText = 'Rider Assigned';
      badgeColor = Colors.deepPurple;
      badgeIcon = Icons.local_shipping;
    } else {
      badgeText = order.status.displayName;
      badgeColor = Colors.blue;
      badgeIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(badgeIcon, color: badgeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.items.length} items',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        Formatters.formatDate(order.createdAt),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Call buttons for rider and customer
            if (!isCancelled && !isDelivered) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.riderName != null && order.riderPhone != null && order.riderPhone!.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCallDialog('Rider', order.riderName!, order.riderPhone!),
                        icon: const Icon(Icons.local_shipping, size: 16),
                        label: Text('Call ${order.riderName}', overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: const BorderSide(color: Colors.purple),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                      ),
                    ),
                  if (order.riderName != null && order.customer != null)
                    const SizedBox(width: 8),
                  if (order.customer != null && order.customer!.phoneNumber.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCallDialog('Customer', order.customer!.name ?? 'Customer', order.customer!.phoneNumber),
                        icon: const Icon(Icons.person, size: 16),
                        label: const Text('Call Customer', overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
