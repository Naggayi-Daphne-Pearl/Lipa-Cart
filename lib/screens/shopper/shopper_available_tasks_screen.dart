import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/shopper_button.dart';
import '../../core/theme/app_colors.dart';

class ShopperAvailableTasksScreen extends StatefulWidget {
  const ShopperAvailableTasksScreen({super.key});

  @override
  State<ShopperAvailableTasksScreen> createState() =>
      _ShopperAvailableTasksScreenState();
}

class _ShopperAvailableTasksScreenState
    extends State<ShopperAvailableTasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _validateRoleAndLoad();
    });
  }

  void _validateRoleAndLoad() {
    final authProvider = context.read<AuthProvider>();

    // Validate user role - only shoppers can access this screen
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

    _refreshTasks();
  }

  void _refreshTasks() {
    final authProvider = context.read<AuthProvider>();
    final shopperProvider = context.read<ShopperProvider>();

    if (authProvider.token != null) {
      shopperProvider.fetchAvailableTasks(authProvider.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Tasks'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ShopperProvider>(
        builder: (context, authProvider, shopperProvider, _) {
          if (shopperProvider.isLoading) {
            return const AppLoadingPage();
          }

          if (shopperProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(shopperProvider.error!),
                  const SizedBox(height: 16),
                  ShopperButton.secondary(
                    text: 'Retry',
                    icon: Icons.refresh_rounded,
                    width: 200,
                    onPressed: _refreshTasks,
                  ),
                ],
              ),
            );
          }

          final tasks = shopperProvider.availableTasks;

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new shopping tasks',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: ShopperButton.primary(
                      text: 'Refresh',
                      icon: Icons.refresh_rounded,
                      onPressed: _refreshTasks,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshTasks(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskCard(
                  context,
                  task,
                  authProvider.token!,
                  authProvider.user!.documentId ?? authProvider.user!.id,
                  shopperProvider,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    Order task,
    String token,
    String shopperId,
    ShopperProvider shopperProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${task.orderNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to shop',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _buildUrgencyBadge(task.createdAt),
              ],
            ),
            const SizedBox(height: 16),

            // Customer info
            if (task.customer != null) ...[
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'Customer',
                value: task.customer!.name ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              if (task.customer!.phoneNumber.isNotEmpty) ...[
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: task.customer!.phoneNumber,
                ),
                const SizedBox(height: 8),
              ],
            ],

            // Items count
            _buildInfoRow(
              icon: Icons.shopping_bag_outlined,
              label: 'Items',
              value: '${task.items.length} items',
            ),
            const SizedBox(height: 8),

            // Budget
            _buildInfoRow(
              icon: Icons.wallet_outlined,
              label: 'Budget',
              value: Formatters.formatCurrency(task.total),
            ),
            const SizedBox(height: 8),

            // Location
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: task.deliveryAddress.fullAddress,
              maxLines: 2,
            ),

            // Commission (dummy for now)
            _buildInfoRow(
              icon: Icons.trending_up,
              label: 'Your Commission',
              value: 'UGX ${(task.total * 0.10).toStringAsFixed(0)}',
              valueColor: Colors.green,
            ),
            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Accept Task?'),
                      content: Text(
                        'Accept this order for ${task.items.length} items? You\'ll earn UGX ${(task.total * 0.10).toStringAsFixed(0)} commission.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(dialogContext);
                            final success = await shopperProvider.acceptTask(
                              token,
                              task.documentId ?? task.id,
                              shopperId,
                            );
                            if (success && mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Task accepted! Start shopping.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                          child: const Text('Accept Task'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Accept Task',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(DateTime createdAt) {
    final minutesAgo = DateTime.now().difference(createdAt).inMinutes;
    final String label;
    final Color color;
    final Color bgColor;

    if (minutesAgo < 5) {
      label = 'NEW';
      color = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else if (minutesAgo < 15) {
      label = '${minutesAgo}m ago';
      color = Colors.blue;
      bgColor = Colors.blue.withValues(alpha: 0.1);
    } else if (minutesAgo < 30) {
      label = '${minutesAgo}m ago';
      color = Colors.orange;
      bgColor = Colors.orange.withValues(alpha: 0.1);
    } else {
      final display = minutesAgo < 60 ? '${minutesAgo}m' : '${minutesAgo ~/ 60}h';
      label = 'Urgent · $display';
      color = Colors.red;
      bgColor = Colors.red.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
