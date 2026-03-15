import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/rider_button.dart';

class RiderActiveDeliveriesScreen extends StatefulWidget {
  const RiderActiveDeliveriesScreen({super.key});

  @override
  State<RiderActiveDeliveriesScreen> createState() =>
      _RiderActiveDeliveriesScreenState();
}

class _RiderActiveDeliveriesScreenState
    extends State<RiderActiveDeliveriesScreen> {
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
    final userDocId = authProvider.user?.documentId ?? authProvider.user?.id;
    if (token != null && userDocId != null) {
      riderProvider.fetchActiveDeliveries(token, userDocId);
    }
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final rider = context.read<RiderProvider>();
    final token = auth.token;
    final userDocId = auth.user?.documentId ?? auth.user?.id;
    if (token != null && userDocId != null) {
      await rider.fetchActiveDeliveries(token, userDocId);
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.inTransit:
        return AppColors.info;
      case OrderStatus.readyForDelivery:
        return _brandColor;
      case OrderStatus.confirmed:
        return AppColors.accent;
      default:
        return AppColors.grey500;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.readyForDelivery:
        return 'Pickup Ready';
      case OrderStatus.inTransit:
        return 'In Transit';
      default:
        return status.displayName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Deliveries'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<RiderProvider>(
        builder: (context, rider, _) {
          if (rider.isLoading) {
            return const AppLoadingPage();
          }

          if (rider.activeDeliveries.isEmpty) {
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
                    child: Icon(Iconsax.truck,
                        size: 48, color: _brandColor),
                  ),
                  const SizedBox(height: AppSizes.md),
                  const Text(
                    'No active deliveries',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  const Text(
                    'Accept a delivery from available orders',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  RiderButton.primary(
                    text: 'Browse Available Deliveries',
                    icon: Iconsax.truck_fast,
                    width: 280,
                    height: 44,
                    onPressed: () =>
                        context.go('/rider/available-deliveries'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: _brandColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: rider.activeDeliveries.length,
              itemBuilder: (context, index) {
                return _buildDeliveryCard(rider.activeDeliveries[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(Order order) {
    final itemCount = order.items.length;
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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
            const SizedBox(height: AppSizes.sm),
            // Delivery address
            Row(
              children: [
                Icon(Iconsax.location,
                    size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress.fullAddress,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            // Items summary
            Row(
              children: [
                Icon(Iconsax.box_1,
                    size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '$itemCount items',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  Formatters.formatCurrency(order.deliveryFee),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            // Action buttons based on status
            if (order.status == OrderStatus.readyForDelivery ||
                order.status == OrderStatus.riderAssigned)
              // Rider has claimed but not yet picked up
              SizedBox(
                width: double.infinity,
                child: RiderButton.primary(
                  text: 'Picked Up — Start Delivery',
                  icon: Iconsax.truck_fast,
                  height: 44,
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final rider = context.read<RiderProvider>();
                    final success = await rider.markInTransit(
                      auth.token!,
                      order.documentId ?? order.id,
                      auth.user!.documentId ?? auth.user!.id,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Order picked up — delivering now!'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    }
                  },
                ),
              )
            else if (order.status == OrderStatus.inTransit)
              // Rider is delivering
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.tick_circle, size: 18),
                  label: const Text('Mark as Delivered'),
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final rider = context.read<RiderProvider>();
                    final success = await rider.completeDelivery(
                      auth.token!,
                      order.documentId ?? order.id,
                      auth.user!.documentId ?? auth.user!.id,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Delivery marked as complete!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              ),
            // Call buttons row
            if ((order.customer != null && order.customer!.phoneNumber.isNotEmpty) ||
                (order.shopperName != null && order.shopperPhone != null)) ...[
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  // Call Shopper
                  if (order.shopperName != null && order.shopperPhone != null && order.shopperPhone!.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCallDialog(
                          'Shopper',
                          order.shopperName!,
                          order.shopperPhone!,
                        ),
                        icon: const Icon(Iconsax.shopping_bag, size: 16),
                        label: const Text('Shopper', overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.info,
                          side: BorderSide(color: AppColors.info),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
                        ),
                      ),
                    ),
                  if (order.shopperName != null && order.customer != null)
                    const SizedBox(width: AppSizes.xs),
                  // Call Customer
                  if (order.customer != null && order.customer!.phoneNumber.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCallDialog(
                          'Customer',
                          order.customer!.name ?? 'Customer',
                          order.customer!.phoneNumber,
                        ),
                        icon: const Icon(Iconsax.call, size: 16),
                        label: const Text('Customer', overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: BorderSide(color: AppColors.accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          ),
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
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.accent, size: 24),
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
                    backgroundColor: AppColors.accent,
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
}
