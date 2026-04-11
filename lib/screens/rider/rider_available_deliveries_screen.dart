import 'dart:math' as math;
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
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/rider_button.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _validateRoleAndLoad();
    });
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
                  RiderButton.primary(
                    text: 'Retry',
                    onPressed: _refreshDeliveries,
                    width: 120,
                    height: 44,
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
                  RiderButton.primary(
                    text: 'Refresh',
                    icon: Iconsax.refresh,
                    onPressed: _refreshDeliveries,
                    width: 160,
                    height: 44,
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
                  authProvider.user!.documentId ?? authProvider.user!.id,
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
                _buildUrgencyBadge(delivery.createdAt),
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

            // Distance & ETA
            if (_getDistanceAndEta(delivery).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _buildInfoRow(
                  icon: Iconsax.routing_2,
                  label: 'Distance & ETA',
                  value: _getDistanceAndEta(delivery),
                  valueColor: AppColors.info,
                ),
              ),

            // Payment method badge + order total
            Row(
              children: [
                Icon(Iconsax.wallet_2, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: delivery.paymentMethod == PaymentMethod.cashOnDelivery
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    delivery.paymentMethod == PaymentMethod.cashOnDelivery ? 'COD' : 'Paid',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: delivery.paymentMethod == PaymentMethod.cashOnDelivery
                          ? AppColors.accent
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Total: ${Formatters.formatCurrency(delivery.total)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            // Delivery fee (your earning)
            _buildInfoRow(
              icon: Iconsax.money_recive,
              label: 'Your Earning',
              value: Formatters.formatCurrency(delivery.deliveryFee),
              valueColor: _brandColor,
            ),
            const SizedBox(height: AppSizes.md),

            // Accept button
            RiderButton.primary(
              text: 'Accept Delivery',
              height: 48,
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
                            delivery.documentId ?? delivery.id,
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
                            // Navigate directly to active deliveries
                            if (context.mounted) {
                              context.go('/rider/active-deliveries');
                            }
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
      color = _brandColor;
      bgColor = AppColors.accentSoft;
    } else if (minutesAgo < 15) {
      label = '${minutesAgo}m ago';
      color = AppColors.info;
      bgColor = AppColors.info.withValues(alpha: 0.1);
    } else if (minutesAgo < 30) {
      label = '${minutesAgo}m ago';
      color = AppColors.warning;
      bgColor = AppColors.warning.withValues(alpha: 0.1);
    } else {
      final display = minutesAgo < 60 ? '${minutesAgo}m' : '${minutesAgo ~/ 60}h';
      label = 'Urgent · $display';
      color = AppColors.error;
      bgColor = AppColors.error.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Distance from Kampala center (rider hub) to delivery address
  String _getDistanceAndEta(Order delivery) {
    final lat = delivery.deliveryAddress.latitude;
    final lng = delivery.deliveryAddress.longitude;
    if (lat == 0 && lng == 0) {
      return '';
    }
    final km = _haversineDistance(
      AppConstants.serviceAreaCenterLat,
      AppConstants.serviceAreaCenterLng,
      lat,
      lng,
    );
    // Estimate: ~20 km/h average in Kampala traffic
    final minutes = (km / 20 * 60).round();
    return '${km.toStringAsFixed(1)} km · ~$minutes min';
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
