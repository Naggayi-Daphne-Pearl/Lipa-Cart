import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_loading_indicator.dart';

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  static const Color _brandColor = AppColors.accent;

  @override
  void initState() {
    super.initState();
    _validateRoleAndLoad();
  }

  void _validateRoleAndLoad() {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user?.role != UserRole.rider) {
      Future.microtask(() {
        GoRouter.of(context).go(
          authProvider.user?.role == UserRole.admin
              ? '/admin/dashboard'
              : authProvider.user?.role == UserRole.shopper
                  ? '/shopper/home'
                  : '/customer/home',
        );
      });
      return;
    }

    final riderProvider = context.read<RiderProvider>();
    final token = authProvider.token;
    final riderId = authProvider.user?.riderId;
    final userDocId = authProvider.user?.documentId;
    if (token != null && riderId != null) {
      riderProvider.loadRiderProfile(token, riderId);
      riderProvider.fetchCompletedDeliveries(token, userDocId ?? riderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<RiderProvider>(
        builder: (context, rider, _) {
          if (rider.isLoading) {
            return const AppLoadingPage();
          }

          final totalEarnings = rider.totalEarnings;
          final completedCount = rider.completedOrders;
          final recentDeliveries = rider.completedDeliveries.take(5).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Earnings Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentLight],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: _brandColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Earnings',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
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
                            Iconsax.tick_circle,
                            '$completedCount deliveries',
                          ),
                          const SizedBox(width: 16),
                          _buildStatChip(
                            Iconsax.star_1,
                            '${rider.averageRating.toStringAsFixed(1)} rating',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Earnings Breakdown
                Text(
                  'Earnings Breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSizes.sm),
                _EarningsCard(
                  icon: Iconsax.truck_fast,
                  label: 'Completed Deliveries',
                  amount: Formatters.formatCurrency(totalEarnings),
                  count: '$completedCount deliveries',
                ),
                const SizedBox(height: AppSizes.sm),
                _EarningsCard(
                  icon: Iconsax.star_1,
                  label: 'Reviews',
                  amount: '${rider.totalReviews}',
                  count:
                      '${rider.averageRating.toStringAsFixed(1)} avg rating',
                ),
                const SizedBox(height: AppSizes.lg),

                // Recent Deliveries
                Text(
                  'Recent Deliveries',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSizes.sm),
                if (recentDeliveries.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      children: [
                        Icon(Iconsax.truck,
                            size: 36, color: AppColors.grey300),
                        const SizedBox(height: AppSizes.sm),
                        const Text(
                          'No completed deliveries yet',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...recentDeliveries.map(_buildRecentDeliveryTile),
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

  Widget _buildRecentDeliveryTile(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(AppSizes.radiusXs),
          ),
          child: const Icon(Iconsax.truck_fast,
              color: AppColors.accent, size: 20),
        ),
        title: Text(
          '#${order.orderNumber}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${order.items.length} items  |  ${Formatters.formatDate(order.createdAt)}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
        trailing: Text(
          Formatters.formatCurrency(order.deliveryFee),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppSizes.radiusXs),
              ),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      )),
                  if (count.isNotEmpty)
                    Text(
                      count,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
