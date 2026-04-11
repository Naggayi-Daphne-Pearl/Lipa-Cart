import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../models/order.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../services/strapi_service.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/rider_button.dart';

class RiderActiveDeliveriesScreen extends StatefulWidget {
  final String? focusDeliveryId;

  const RiderActiveDeliveriesScreen({super.key, this.focusDeliveryId});

  @override
  State<RiderActiveDeliveriesScreen> createState() =>
      _RiderActiveDeliveriesScreenState();
}

class _RiderActiveDeliveriesScreenState
    extends State<RiderActiveDeliveriesScreen> {
  static const Color _brandColor = AppColors.accent;
  StreamSubscription<Position>? _locationSubscription;
  Position? _lastSyncedPosition;
  DateTime? _lastLocationSyncAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _validateRoleAndLoad();
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
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
      final riderId = authProvider.user?.riderId;
      if (riderId != null) {
        _startLocationTracking(token, riderId);
      }
    }
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final rider = context.read<RiderProvider>();
    final token = auth.token;
    final userDocId = auth.user?.documentId ?? auth.user?.id;
    if (token != null && userDocId != null) {
      await rider.fetchActiveDeliveries(token, userDocId);
      final riderId = auth.user?.riderId;
      if (riderId != null) {
        await _startLocationTracking(token, riderId);
      }
    }
  }

  Future<void> _startLocationTracking(String token, String riderId) async {
    if (_locationSubscription != null) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      await _syncRiderLocation(token, riderId, currentPosition, force: true);
    } catch (_) {
      // Ignore one-off GPS failures.
    }

    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 20,
          ),
        ).listen((position) {
          _syncRiderLocation(token, riderId, position);
        });
  }

  Future<void> _syncRiderLocation(
    String token,
    String riderId,
    Position position, {
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force && _lastSyncedPosition != null && _lastLocationSyncAt != null) {
      final distanceMoved = Geolocator.distanceBetween(
        _lastSyncedPosition!.latitude,
        _lastSyncedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      final secondsSinceLastSync = now
          .difference(_lastLocationSyncAt!)
          .inSeconds;
      if (distanceMoved < 15 && secondsSinceLastSync < 10) {
        return;
      }
    }

    final success = await StrapiService.updateRiderProfile(riderId, {
      'current_gps_lat': position.latitude,
      'current_gps_lng': position.longitude,
    }, token);

    if (success) {
      _lastSyncedPosition = position;
      _lastLocationSyncAt = now;
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
                    child: Icon(Iconsax.truck, size: 48, color: _brandColor),
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
                    onPressed: () => context.go('/rider/available-deliveries'),
                  ),
                ],
              ),
            );
          }

          final focusId = widget.focusDeliveryId;
          final deliveries = [...rider.activeDeliveries];
          if (focusId != null && focusId.isNotEmpty) {
            deliveries.sort((a, b) {
              final aFocused = (a.documentId ?? a.id) == focusId;
              final bFocused = (b.documentId ?? b.id) == focusId;
              if (aFocused == bFocused) return 0;
              return aFocused ? -1 : 1;
            });
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: _brandColor,
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                if (focusId != null && focusId.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Iconsax.flash_1, size: 16, color: AppColors.accent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Newly accepted delivery is pinned at the top. Start pickup to begin route.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ...deliveries.map((delivery) {
                  final isFocused = focusId != null && (delivery.documentId ?? delivery.id) == focusId;
                  return _buildDeliveryCard(delivery, isFocused: isFocused);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(Order order, {bool isFocused = false}) {
    final itemCount = order.items.length;
    final statusColor = _getStatusColor(order.status);
    final statusText = _getStatusText(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isFocused ? AppColors.accent : AppColors.grey200,
          width: isFocused ? 1.4 : 1,
        ),
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
                Icon(Iconsax.location, size: 16, color: AppColors.textTertiary),
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
            // COD banner — prominent at the top
            if (order.paymentMethod == PaymentMethod.cashOnDelivery)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.money_recive, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'COLLECT ${Formatters.formatCurrency(order.total)} CASH',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Items summary + your earning
            Row(
              children: [
                Icon(Iconsax.box_1, size: 16, color: AppColors.textTertiary),
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
                  'Your Earning: ${Formatters.formatCurrency(order.deliveryFee)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            _buildStageIndicator(order.status),
            // Expandable item list
            if (order.items.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    'View items',
                    style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                  iconColor: AppColors.accent,
                  collapsedIconColor: AppColors.accent,
                  children: order.items.map((item) {
                    final substituted = item.substituteName != null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${substituted ? item.substituteName! : item.product.name}  x${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} ${item.product.unit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                decoration: substituted ? TextDecoration.none : null,
                              ),
                            ),
                          ),
                          if (substituted)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.swap_horiz, size: 14, color: AppColors.accent),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showNavigationOptions(order),
                icon: const Icon(Iconsax.route_square, size: 16),
                label: const Text('Navigate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: const BorderSide(color: AppColors.info),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            // Action buttons based on status
            if (order.status == OrderStatus.readyForDelivery ||
                order.status == OrderStatus.riderAssigned)
              // Rider has claimed but not yet picked up
              Column(
                children: [
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
                              content: const Text(
                                'Order picked up — delivering now!',
                              ),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (order.customer != null &&
                            order.customer!.phoneNumber.isNotEmpty) {
                          _showCallDialog(
                            'Customer',
                            order.customer!.name ?? 'Customer',
                            order.customer!.phoneNumber,
                          );
                        }
                      },
                      icon: const Icon(Iconsax.call, size: 16),
                      label: const Text('Call Customer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (order.status == OrderStatus.inTransit) ...[
              // Rider is delivering — require delivery proof photo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.camera, size: 18),
                  label: Text(
                    order.paymentMethod == PaymentMethod.cashOnDelivery
                        ? 'Cash Collected — Take Photo'
                        : 'Take Photo & Complete',
                  ),
                  onPressed: () => _showDeliveryProofDialog(context, order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              if (order.customer != null && order.customer!.phoneNumber.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCallDialog(
                      'Customer',
                      order.customer!.name ?? 'Customer',
                      order.customer!.phoneNumber,
                    ),
                    icon: const Icon(Iconsax.call, size: 16),
                    label: const Text('Call Customer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: AppSizes.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showMoreActionsSheet(order),
                icon: const Icon(Iconsax.more, size: 16),
                label: const Text('More actions'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Open the device's map app with directions to the shopper's pickup location.
  void _openPickupNavigation(Order order) {
    final shopperName = order.shopperName;
    if (shopperName != null && shopperName.isNotEmpty) {
      final query = Uri.encodeComponent('$shopperName market Kampala');
      final url = 'https://www.google.com/maps/search/?api=1&query=$query';
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shopper pickup location not available')),
      );
    }
  }

  void _showNavigationOptions(Order order) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Pickup location'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openPickupNavigation(order);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.gps),
              title: const Text('Delivery location'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openNavigation(order);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreActionsSheet(Order order) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (order.shopperName != null &&
                order.shopperPhone != null &&
                order.shopperPhone!.isNotEmpty)
              ListTile(
                leading: const Icon(Iconsax.shopping_bag),
                title: const Text('Call shopper'),
                subtitle: Text(order.shopperName!),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showCallDialog('Shopper', order.shopperName!, order.shopperPhone!);
                },
              ),
            if (order.status == OrderStatus.readyForDelivery ||
                order.status == OrderStatus.riderAssigned)
              ListTile(
                leading: const Icon(Iconsax.close_circle, color: AppColors.error),
                title: const Text(
                  'Cancel delivery',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmCancelDelivery(order);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageIndicator(OrderStatus status) {
    int stageIndex;
    switch (status) {
      case OrderStatus.riderAssigned:
      case OrderStatus.readyForDelivery:
        stageIndex = 0;
        break;
      case OrderStatus.inTransit:
        stageIndex = 1;
        break;
      case OrderStatus.delivered:
        stageIndex = 2;
        break;
      default:
        stageIndex = 0;
    }

    Widget stageChip(String label, bool active) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.accentSoft : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.accent : AppColors.textTertiary,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        stageChip('Assigned', stageIndex >= 0),
        stageChip('In Transit', stageIndex >= 1),
        stageChip('Delivered', stageIndex >= 2),
      ],
    );
  }

  /// Open the device's map app with directions to the delivery address.
  void _openNavigation(Order order) {
    final lat = order.deliveryAddress.latitude;
    final lng = order.deliveryAddress.longitude;
    final address = order.deliveryAddress.fullAddress;

    if (lat != 0 && lng != 0) {
      // Open Google Maps with coordinates
      final url =
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (address.isNotEmpty && address != 'No address provided') {
      // Fallback: search by address name
      final encodedAddress = Uri.encodeComponent(address);
      final url =
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No delivery location available')),
      );
    }
  }

  void _showDeliveryProofDialog(BuildContext context, Order order) {
    XFile? proofPhoto;
    Uint8List? proofBytes;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delivery Proof'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Take a photo of the delivered order at the customer\'s door for verification.',
              ),
              const SizedBox(height: 16),
              if (proofPhoto != null && proofBytes != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(proofBytes!, fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setDialogState(() {
                            proofPhoto = null;
                            proofBytes = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (photo != null) {
                      final bytes = await photo.readAsBytes();
                      setDialogState(() {
                        proofPhoto = photo;
                        proofBytes = bytes;
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.grey300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.camera,
                          size: 36,
                          color: AppColors.grey500,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to take photo',
                          style: TextStyle(
                            color: AppColors.grey500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isUploading) ...[
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Uploading photo & completing...',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: proofPhoto == null || isUploading
                  ? null
                  : () async {
                      setDialogState(() => isUploading = true);
                      final auth = context.read<AuthProvider>();
                      final rider = context.read<RiderProvider>();
                      final success = await rider.completeDelivery(
                        auth.token!,
                        order.documentId ?? order.id,
                        auth.user!.documentId ?? auth.user!.id,
                        proofPhotoBytes: proofBytes,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Delivery completed with proof photo!',
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              rider.error ?? 'Failed to complete delivery',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete Delivery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancelDelivery(Order order) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Delivery?'),
        content: const Text(
          'This will unassign you and return the order to available deliveries for other riders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Delivery'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Delivery'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final rider = context.read<RiderProvider>();
    final success = await rider.cancelDelivery(
      auth.token!,
      order.documentId ?? order.id,
      auth.user!.documentId ?? auth.user!.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Delivery cancelled successfully' : 'Failed to cancel delivery'),
        backgroundColor: success ? AppColors.warning : AppColors.error,
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
                child: const Icon(
                  Icons.person,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
