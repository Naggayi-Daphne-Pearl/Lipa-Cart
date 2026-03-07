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

class RiderAvailableDeliveriesScreen extends StatefulWidget {
  const RiderAvailableDeliveriesScreen({super.key});

  @override
  State<RiderAvailableDeliveriesScreen> createState() =>
      _RiderAvailableDeliveriesScreenState();
}

class _RiderAvailableDeliveriesScreenState
    extends State<RiderAvailableDeliveriesScreen> {
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

    _refreshDeliveries();
  }

  void _refreshDeliveries() {
    final authProvider = context.read<AuthProvider>();
    final riderProvider = context.read<RiderProvider>();

    if (authProvider.token != null) {
      riderProvider.fetchAvailableDeliveries(authProvider.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Available Deliveries'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _refreshDeliveries,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer2<AuthProvider, RiderProvider>(
        builder: (context, authProvider, riderProvider, _) {
          if (riderProvider.isLoading) {
            return const AppLoadingPage();
          }

          if (riderProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.warning_2, size: 48, color: AppColors.grey300),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    riderProvider.error!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.md),
                  ElevatedButton(
                    onPressed: _refreshDeliveries,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final deliveries = riderProvider.availableDeliveries;

          if (deliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.truck_fast,
                      size: 48,
                      color: _brandColor,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  const Text(
                    'No deliveries available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  const Text(
                    'Check back later for new delivery requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  ElevatedButton.icon(
                    onPressed: _refreshDeliveries,
                    icon: const Icon(Iconsax.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshDeliveries(),
            color: _brandColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final delivery = deliveries[index];
                return _buildDeliveryCard(
                  context,
                  delivery,
                  authProvider.token!,
                  authProvider.user!.id,
                  riderProvider,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context,
    Order delivery,
    String token,
    String riderId,
    RiderProvider riderProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID + Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ${delivery.orderNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready for pickup',
                      style: TextStyle(
                        fontSize: 12,
                        color: _brandColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: _brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // Customer info
            if (delivery.customer != null)
              _buildInfoRow(
                icon: Iconsax.profile_circle,
                label: 'Customer',
                value: delivery.customer!.name ?? 'Unknown',
              ),
            const SizedBox(height: AppSizes.sm),

            // Items count
            _buildInfoRow(
              icon: Iconsax.box_1,
              label: 'Items',
              value: '${delivery.items.length} items',
            ),
            const SizedBox(height: AppSizes.sm),

            // Delivery location
            _buildInfoRow(
              icon: Iconsax.location,
              label: 'Delivery',
              value: delivery.deliveryAddress.fullAddress,
              maxLines: 2,
            ),
            const SizedBox(height: AppSizes.sm),

            // Delivery fee
            _buildInfoRow(
              icon: Iconsax.wallet_2,
              label: 'Delivery Fee',
              value: Formatters.formatCurrency(delivery.deliveryFee),
              valueColor: _brandColor,
            ),
            const SizedBox(height: AppSizes.md),

            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      title: const Text('Accept Delivery?'),
                      content: Text(
                        'Accept this delivery of ${delivery.items.length} items? You\'ll earn ${Formatters.formatCurrency(delivery.deliveryFee)}.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            final success =
                                await riderProvider.acceptDelivery(
                              token,
                              delivery.id,
                              riderId,
                            );
                            if (success && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Delivery accepted! Start your route.',
                                  ),
                                  backgroundColor: _brandColor,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
                child: const Text(
                  'Accept Delivery',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
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
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
