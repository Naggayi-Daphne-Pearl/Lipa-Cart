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

class ShopperEarningsScreen extends StatefulWidget {
  const ShopperEarningsScreen({super.key});

  @override
  State<ShopperEarningsScreen> createState() => _ShopperEarningsScreenState();
}

class _ShopperEarningsScreenState extends State<ShopperEarningsScreen> {
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
    final shopperId = authProvider.user?.shopperId;
    final userDocId = authProvider.user?.documentId;
    if (token != null && shopperId != null) {
      shopperProvider.loadShopperProfile(token, shopperId);
    }
    if (token != null && userDocId != null) {
      shopperProvider.fetchCompletedTasks(token, userDocId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: Consumer<ShopperProvider>(
        builder: (context, shopper, _) {
          if (shopper.isLoading) {
            return const AppLoadingPage();
          }

          final totalEarnings = shopper.totalEarnings;
          final completedCount = shopper.completedOrders;
          final recentTasks = shopper.completedTasks.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Earnings Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Earnings',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.formatCurrency(totalEarnings),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatChip(
                            Icons.check_circle_outline,
                            '$completedCount orders',
                          ),
                          const SizedBox(width: 16),
                          _buildStatChip(
                            Icons.star_outline,
                            '${shopper.averageRating.toStringAsFixed(1)} rating',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Earnings Breakdown
                Text(
                  'Earnings Breakdown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _EarningsCard(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Completed Tasks',
                  amount: Formatters.formatCurrency(totalEarnings),
                  count: '$completedCount tasks',
                ),
                const SizedBox(height: 8),
                _EarningsCard(
                  icon: Icons.reviews_outlined,
                  label: 'Reviews',
                  amount: '${shopper.totalReviews}',
                  count: '${shopper.averageRating.toStringAsFixed(1)} avg',
                ),
                const SizedBox(height: 24),

                // Recent Tasks
                Text(
                  'Recent Tasks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (recentTasks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No completed tasks yet',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  )
                else
                  ...recentTasks.map(_buildRecentTaskTile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildRecentTaskTile(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: const Icon(Icons.receipt_long, color: AppColors.primary),
        ),
        title: Text(
          '#${order.orderNumber}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${order.items.length} items  |  ${Formatters.formatDate(order.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          Formatters.formatCurrency(order.total),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final String count;

  const _EarningsCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (count.isNotEmpty)
                    Text(
                      count,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ),
            Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
