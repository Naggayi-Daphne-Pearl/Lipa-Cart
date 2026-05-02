import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/delivery_route_service.dart';
import '../../widgets/error_boundary.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../widgets/custom_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/responsive.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Order order;

  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  final DeliveryRouteService _deliveryRouteService = DeliveryRouteService();
  final MapController _trackingMapController = MapController();

  late final AnimationController _riderAnimationController;
  late Order order;
  late final Timer? _pollTimer;
  List<LatLng> _routePoints = const [];
  double? _routeDistanceKm;
  Duration? _routeDuration;
  bool _isEstimatedRoute = false;
  String? _routeSourceLabel;
  String? _lastRouteSignature;
  LatLng? _displayRiderPoint;
  LatLng? _animationStartPoint;
  LatLng? _animationEndPoint;
  bool _isTrackingMapReady = false;
  bool _isRetryingPayment = false;

  @override
  void initState() {
    super.initState();
    _riderAnimationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )..addListener(() {
          final start = _animationStartPoint;
          final end = _animationEndPoint;
          if (!mounted || start == null || end == null) return;

          final t = Curves.easeInOut.transform(_riderAnimationController.value);
          final latitude =
              start.latitude + ((end.latitude - start.latitude) * t);
          final longitude =
              start.longitude + ((end.longitude - start.longitude) * t);

          setState(() {
            _displayRiderPoint = LatLng(latitude, longitude);
          });
        });
    order = widget.order;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _updateTrackingRoute(order);
      await _refreshOrder();
    });
    // Auto-refresh every 8 seconds for active orders
    if (!order.isDelivered && !order.isCancelled) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 8),
        (_) => _refreshOrder(),
      );
    } else {
      _pollTimer = null;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _riderAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrder() async {
    final auth = context.read<AuthProvider>();
    final orderService = context.read<OrderService>();
    if (auth.token == null) return;

    final success = await orderService.getOrder(
      auth.token!,
      order.documentId ?? order.id,
    );
    if (success && orderService.currentOrder != null && mounted) {
      final refreshedOrder = orderService.currentOrder!;
      setState(() => order = refreshedOrder);
      await _updateTrackingRoute(refreshedOrder);
      // Stop polling if order is now complete
      if (order.isDelivered || order.isCancelled) {
        _pollTimer?.cancel();
      }
    }
  }

  Future<void> _updateTrackingRoute(Order currentOrder) async {
    final isTrackable =
        currentOrder.status == OrderStatus.riderAssigned ||
        currentOrder.status == OrderStatus.inTransit;
    final hasClientLocation = currentOrder.deliveryAddress.hasCoordinates;
    final hasRiderLocation =
        currentOrder.riderLatitude != null &&
        currentOrder.riderLongitude != null &&
        currentOrder.riderLatitude != 0 &&
        currentOrder.riderLongitude != 0;

    if (!isTrackable || !hasClientLocation || !hasRiderLocation) {
      if (!mounted) return;
      _riderAnimationController.stop();
      setState(() {
        _routePoints = const [];
        _routeDistanceKm = null;
        _routeDuration = null;
        _isEstimatedRoute = false;
        _routeSourceLabel = null;
        _lastRouteSignature = null;
        _displayRiderPoint = null;
        _animationStartPoint = null;
        _animationEndPoint = null;
      });
      return;
    }

    final clientLat = currentOrder.deliveryAddress.latitude;
    final clientLng = currentOrder.deliveryAddress.longitude;
    if (clientLat == null || clientLng == null) {
      return;
    }
    final riderPoint = LatLng(
      currentOrder.riderLatitude!,
      currentOrder.riderLongitude!,
    );
    final clientPoint = LatLng(clientLat, clientLng);

    final routeSignature =
        '${riderPoint.latitude.toStringAsFixed(5)},${riderPoint.longitude.toStringAsFixed(5)}|'
        '${clientPoint.latitude.toStringAsFixed(5)},${clientPoint.longitude.toStringAsFixed(5)}';

    _syncDisplayedRiderPoint(riderPoint);

    if (routeSignature == _lastRouteSignature && _routePoints.isNotEmpty) {
      return;
    }

    final route = await _deliveryRouteService.getRoute(
      riderPoint: riderPoint,
      clientPoint: clientPoint,
    );

    if (!mounted) return;

    setState(() {
      _lastRouteSignature = routeSignature;
      _routePoints = route.points;
      _routeDistanceKm = route.distanceKm;
      _routeDuration = route.duration;
      _isEstimatedRoute = route.isEstimated;
      _routeSourceLabel = route.sourceLabel;
    });

    _fitTrackingRoute(
      clientPoint: clientPoint,
      riderPoint: _displayRiderPoint ?? riderPoint,
      routePoints: route.points,
    );
  }

  void _syncDisplayedRiderPoint(LatLng newPoint) {
    if (_displayRiderPoint == null) {
      setState(() {
        _displayRiderPoint = newPoint;
      });
      return;
    }

    final hasMoved =
        (_displayRiderPoint!.latitude - newPoint.latitude).abs() > 0.00001 ||
        (_displayRiderPoint!.longitude - newPoint.longitude).abs() > 0.00001;

    if (!hasMoved) {
      _displayRiderPoint = newPoint;
      return;
    }

    _animationStartPoint = _displayRiderPoint;
    _animationEndPoint = newPoint;
    _riderAnimationController.forward(from: 0);
  }

  void _fitTrackingRoute({
    required LatLng clientPoint,
    LatLng? riderPoint,
    List<LatLng>? routePoints,
  }) {
    if (!_isTrackingMapReady) return;

    final points = routePoints != null && routePoints.length >= 2
        ? routePoints
        : <LatLng>[if (riderPoint != null) riderPoint, clientPoint];

    if (points.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isTrackingMapReady) return;

      if (points.length == 1) {
        _trackingMapController.move(points.first, 15);
        return;
      }

      _trackingMapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(36),
        ),
      );
    });
  }

  Future<void> _openTrackingInMaps() async {
    final hasClientCoordinates = order.deliveryAddress.hasCoordinates;
    final hasRiderCoordinates =
        order.riderLatitude != null &&
        order.riderLongitude != null &&
        order.riderLatitude != 0 &&
        order.riderLongitude != 0;

    Uri uri;
    if (hasClientCoordinates && hasRiderCoordinates) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${order.riderLatitude},${order.riderLongitude}&destination=${order.deliveryAddress.latitude!},${order.deliveryAddress.longitude!}&travelmode=driving',
      );
    } else if (hasClientCoordinates) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${order.deliveryAddress.latitude!},${order.deliveryAddress.longitude!}',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(order.deliveryAddress.fullAddress)}',
      );
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the route in Maps.')),
      );
    }
  }

  Future<void> _copyDeliveryAddress() async {
    final addressText = [
      order.deliveryAddress.label,
      order.deliveryAddress.fullAddress,
      if (order.deliveryAddress.landmark != null &&
          order.deliveryAddress.landmark!.isNotEmpty)
        'Near ${order.deliveryAddress.landmark}',
    ].join(', ');

    await Clipboard.setData(ClipboardData(text: addressText));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Delivery address copied.')));
  }

  Future<void> _respondToSubstitution(
    CartItem item,
    bool approved, {
    String? rejectionReason,
    String? counterSuggestion,
  }) async {
    final auth = context.read<AuthProvider>();
    final orderService = context.read<OrderService>();
    if (auth.token == null) return;

    final success = await orderService.respondToSubstitution(
      auth.token!,
      item.id,
      approved,
      rejectionReason: counterSuggestion != null
          ? 'Counter-suggestion: $counterSuggestion'
          : rejectionReason,
    );

    if (!mounted) return;

    if (success) {
      await _refreshOrder();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Substitute approved. Your shopper can buy it now.'
                : 'Substitute rejected. Your shopper will skip it.',
          ),
          backgroundColor: approved ? AppColors.success : AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderService.error ?? 'Failed to update substitute response',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showRejectSubstituteSheet(CartItem item) {
    final counterController = TextEditingController();
    // Two-page state: null = choose action, false = skip item, true = suggest alternative
    bool? _mode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (_mode == null) {
            // Step 1: choose path
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text('Not what you wanted?', style: AppTextStyles.h3),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your shopper suggested ${item.substituteName ?? "a substitute"} for ${item.product.name}.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Option A: suggest alternative
                  _negotiationOptionTile(
                    icon: Iconsax.edit,
                    iconColor: AppColors.primaryOrange,
                    title: 'Suggest a different product',
                    subtitle: 'Tell your shopper exactly what you want',
                    onTap: () => setSheetState(() => _mode = true),
                  ),
                  const SizedBox(height: 12),
                  // Option B: skip item
                  _negotiationOptionTile(
                    icon: Iconsax.close_circle,
                    iconColor: AppColors.error,
                    title: 'Skip this item',
                    subtitle: 'Remove it from the order entirely',
                    onTap: () {
                      Navigator.pop(ctx);
                      _respondToSubstitution(
                        item,
                        false,
                        rejectionReason: 'Skip item',
                      );
                    },
                  ),
                ],
              ),
            );
          } else {
            // Step 2: counter-suggest input
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => setSheetState(() => _mode = null),
                    child: Row(
                      children: [
                        const Icon(Iconsax.arrow_left, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Back',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('What would you like instead?', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text(
                    'Your shopper will look for this specific product.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: counterController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'e.g. Wee Milk 500ml',
                      prefixIcon: const Icon(Iconsax.shopping_bag, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final suggestion = counterController.text.trim();
                        Navigator.pop(ctx);
                        _respondToSubstitution(
                          item,
                          false,
                          counterSuggestion: suggestion.isNotEmpty
                              ? suggestion
                              : null,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Send to Shopper'),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _negotiationOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Iconsax.arrow_right_3,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer/home');
            }
          },
        ),
        title: const Text('Order Details & Tracking'),
      ),
      body: ErrorBoundary(
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.elegantBgGradient,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order header card
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order number and status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${order.orderNumber}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.h5.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Placed on ${Formatters.formatDateTime(order.createdAt)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      order.status,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    order.status.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: _getStatusColor(order.status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),

                          // Delivery time estimate
                          if (!order.isCancelled && !order.isDelivered)
                            Builder(
                              builder: (context) {
                                // Calculate dynamic estimate based on status
                                String estimate;
                                if (order.estimatedDelivery != null) {
                                  estimate =
                                      'Est. delivery: ${Formatters.formatDateTime(order.estimatedDelivery!)}';
                                } else {
                                  switch (order.status) {
                                    case OrderStatus.pending:
                                    case OrderStatus.confirmed:
                                      estimate =
                                          'Est. delivery: 45-60 min after shopping starts';
                                    case OrderStatus.shopperAssigned:
                                    case OrderStatus.shopping:
                                      estimate = 'Est. delivery: 30-45 min';
                                    case OrderStatus.readyForDelivery:
                                    case OrderStatus.riderAssigned:
                                      estimate = 'Est. delivery: 15-25 min';
                                    case OrderStatus.inTransit:
                                      estimate = 'Arriving soon — 5-15 min';
                                    default:
                                      estimate = '';
                                  }
                                }
                                if (estimate.isEmpty)
                                  return const SizedBox.shrink();
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.sm,
                                    vertical: AppSizes.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusSm,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Iconsax.clock,
                                        color: AppColors.primaryGreen,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        estimate,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Status timeline
                    _buildStatusTimeline(),

                    const SizedBox(height: AppSizes.lg),

                    // Rider + client tracking map
                    if ((order.status == OrderStatus.riderAssigned ||
                            order.status == OrderStatus.inTransit) &&
                        order.deliveryAddress.hasCoordinates)
                      Builder(
                        builder: (context) {
                          final clientPoint = LatLng(
                            order.deliveryAddress.latitude!,
                            order.deliveryAddress.longitude!,
                          );
                          final hasRiderLocation =
                              order.riderLatitude != null &&
                              order.riderLongitude != null &&
                              order.riderLatitude != 0 &&
                              order.riderLongitude != 0;
                          final rawRiderPoint = hasRiderLocation
                              ? LatLng(
                                  order.riderLatitude!,
                                  order.riderLongitude!,
                                )
                              : null;
                          final riderPoint = hasRiderLocation
                              ? (_displayRiderPoint ?? rawRiderPoint)
                              : null;
                          final mapCenter = riderPoint != null
                              ? LatLng(
                                  (riderPoint.latitude + clientPoint.latitude) /
                                      2,
                                  (riderPoint.longitude +
                                          clientPoint.longitude) /
                                      2,
                                )
                              : clientPoint;
                          final straightLineDistanceKm = rawRiderPoint != null
                              ? Distance().as(
                                  LengthUnit.Kilometer,
                                  rawRiderPoint,
                                  clientPoint,
                                )
                              : null;
                          final displayDistanceKm =
                              _routeDistanceKm ?? straightLineDistanceKm;
                          final routePoints = riderPoint != null
                              ? (_routePoints.length >= 2
                                    ? _routePoints
                                    : [riderPoint, clientPoint])
                              : const <LatLng>[];

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSizes.lg),
                            padding: const EdgeInsets.all(AppSizes.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      riderPoint != null
                                          ? Iconsax.routing
                                          : Iconsax.location,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        riderPoint != null
                                            ? 'Client and rider locations'
                                            : 'Client location ready',
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  riderPoint != null
                                      ? 'The blue truck is the rider. The red pin marks your delivery location.'
                                      : 'Your delivery pin is ready. The rider pin appears here once GPS updates are available.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildTrackingLegendItem(
                                      icon: Icons.local_shipping,
                                      label: 'Rider',
                                      color: AppColors.primary,
                                    ),
                                    _buildTrackingLegendItem(
                                      icon: Icons.location_on,
                                      label: 'Client',
                                      color: AppColors.error,
                                    ),
                                    if (displayDistanceKm != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.info.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusFull,
                                          ),
                                        ),
                                        child: Text(
                                          '${_formatTrackingDistance(displayDistanceKm)} away',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.info,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (_routeDuration != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusFull,
                                          ),
                                        ),
                                        child: Text(
                                          'ETA ${_formatTrackingEta(_routeDuration!)}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    if (riderPoint != null &&
                                        _routeSourceLabel != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              (_isEstimatedRoute
                                                      ? AppColors.warning
                                                      : AppColors.primary)
                                                  .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusFull,
                                          ),
                                        ),
                                        child: Text(
                                          _routeSourceLabel!,
                                          style: AppTextStyles.caption.copyWith(
                                            color: _isEstimatedRoute
                                                ? AppColors.warning
                                                : AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSizes.sm),
                                SizedBox(
                                  height: 240,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusMd,
                                    ),
                                    child: Stack(
                                      children: [
                                        FlutterMap(
                                          mapController: _trackingMapController,
                                          options: MapOptions(
                                            initialCenter: mapCenter,
                                            initialZoom: riderPoint != null
                                                ? _calculateTrackingZoom(
                                                    riderPoint,
                                                    clientPoint,
                                                  )
                                                : 15,
                                            onTap: (_, __) =>
                                                _openTrackingInMaps(),
                                            onMapReady: () {
                                              _isTrackingMapReady = true;
                                              _fitTrackingRoute(
                                                clientPoint: clientPoint,
                                                riderPoint: riderPoint,
                                                routePoints: routePoints,
                                              );
                                            },
                                            interactionOptions:
                                                const InteractionOptions(
                                                  flags:
                                                      InteractiveFlag
                                                          .pinchZoom |
                                                      InteractiveFlag.drag,
                                                ),
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName:
                                                  'com.lipacart.lipa_cart',
                                            ),
                                            if (riderPoint != null)
                                              PolylineLayer(
                                                polylines: [
                                                  Polyline(
                                                    points: routePoints,
                                                    strokeWidth: 8,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.6),
                                                  ),
                                                  Polyline(
                                                    points: routePoints,
                                                    strokeWidth: 4,
                                                    color: AppColors.primary
                                                        .withValues(
                                                          alpha: 0.75,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: clientPoint,
                                                  width: 88,
                                                  height: 82,
                                                  child: _buildTrackingMarker(
                                                    label: 'Client',
                                                    icon: Icons.location_on,
                                                    color: AppColors.error,
                                                  ),
                                                ),
                                                if (riderPoint != null)
                                                  Marker(
                                                    point: riderPoint,
                                                    width: 88,
                                                    height: 82,
                                                    child: _buildTrackingMarker(
                                                      label: 'Rider',
                                                      icon:
                                                          Icons.local_shipping,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: _buildMapActionChip(
                                            icon: Iconsax.map_1,
                                            label: riderPoint != null
                                                ? 'Open route'
                                                : 'Open in Maps',
                                            onTap: _openTrackingInMaps,
                                          ),
                                        ),
                                        if (riderPoint != null)
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: _buildMapActionChip(
                                              icon: Icons.my_location,
                                              label: 'Recenter',
                                              onTap: () => _fitTrackingRoute(
                                                clientPoint: clientPoint,
                                                riderPoint: riderPoint,
                                                routePoints: routePoints,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSizes.sm),
                                Text(
                                  riderPoint != null
                                      ? _isEstimatedRoute
                                            ? 'Showing an estimated route and ETA while live road data refreshes. Tap the map to open full directions.'
                                            : 'Showing the rider’s road route, distance, and ETA to the client location. Tap the map to open full directions.'
                                      : 'The rider has been assigned. Once their live GPS updates, the map will show both pins connected by a route line. You can still tap to open the address in Maps.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // Tracking timeline
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Iconsax.routing,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text('Order Timeline', style: AppTextStyles.h5),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          _buildTrackingTimeline(context),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Order items details
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Iconsax.shopping_bag,
                                color: AppColors.primaryOrange,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text(
                                'Items Ordered (${order.itemCount})',
                                style: AppTextStyles.h5,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          ...order.items.asMap().entries.map((entry) {
                            final isLast = entry.key == order.items.length - 1;
                            final item = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: isLast ? 0 : AppSizes.md,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryOrange
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusSm,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${item.quantity.toInt()}x',
                                            style: AppTextStyles.labelSmall
                                                .copyWith(
                                                  color:
                                                      AppColors.primaryOrange,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSizes.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${Formatters.formatCurrency(item.product.price)} per unit',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                            if (item.specialInstructions !=
                                                    null &&
                                                item
                                                    .specialInstructions!
                                                    .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors
                                                        .primaryOrange
                                                        .withValues(
                                                          alpha: 0.05,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSizes.radiusXs,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Note: ${item.specialInstructions}',
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            // Shopper feedback (found status + notes)
                                            if (item.found != null) ...[
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      item.found!
                                                          ? Icons.check_circle
                                                          : Icons.cancel,
                                                      size: 14,
                                                      color: item.found!
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      item.found!
                                                          ? 'Found'
                                                          : 'Not found',
                                                      style: AppTextStyles
                                                          .caption
                                                          .copyWith(
                                                            color: item.found!
                                                                ? Colors.green
                                                                : Colors.red,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                    if (item.actualPrice !=
                                                            null &&
                                                        item.actualPrice !=
                                                            item
                                                                .product
                                                                .price) ...[
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Actual: ${Formatters.formatCurrency(item.actualPrice!)}',
                                                        style: AppTextStyles
                                                            .caption
                                                            .copyWith(
                                                              color: AppColors
                                                                  .textSecondary,
                                                            ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                            // Structured substitution UI
                                            if (item.substituteName != null ||
                                                item.isSubstituted == true)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accent
                                                        .withValues(
                                                          alpha: 0.08,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSizes.radiusSm,
                                                        ),
                                                    border: Border.all(
                                                      color: AppColors.accent
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.swap_horiz,
                                                            size: 16,
                                                            color: AppColors
                                                                .accent,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: AppColors
                                                                  .accent,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              'Substituted',
                                                              style: AppTextStyles
                                                                  .caption
                                                                  .copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              item.substitutionApproved ==
                                                                      null
                                                                  ? 'Shopper suggests a substitute'
                                                                  : item.isPendingShopperResponse
                                                                  ? 'Negotiating with shopper'
                                                                  : 'Substitute resolved',
                                                              style: AppTextStyles
                                                                  .caption
                                                                  .copyWith(
                                                                    color: AppColors
                                                                        .accent,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        item.product.name,
                                                        style: AppTextStyles
                                                            .caption
                                                            .copyWith(
                                                              color: AppColors
                                                                  .textSecondary,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      // Substitute name
                                                      Text(
                                                        item.substituteName ??
                                                            'Substitute',
                                                        style: AppTextStyles
                                                            .caption
                                                            .copyWith(
                                                              color: AppColors
                                                                  .textPrimary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                      // Price comparison
                                                      if (item.substitutePrice !=
                                                          null)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 4,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                'Original: ${Formatters.formatCurrency(item.product.price)}',
                                                                style: AppTextStyles
                                                                    .caption
                                                                    .copyWith(
                                                                      color: AppColors
                                                                          .textSecondary,
                                                                      fontSize:
                                                                          11,
                                                                    ),
                                                              ),
                                                              const Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          6,
                                                                    ),
                                                                child: Icon(
                                                                  Icons
                                                                      .arrow_forward,
                                                                  size: 12,
                                                                  color: AppColors
                                                                      .textSecondary,
                                                                ),
                                                              ),
                                                              Text(
                                                                Formatters.formatCurrency(
                                                                  item.substitutePrice!,
                                                                ),
                                                                style: AppTextStyles.caption.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 11,
                                                                  color:
                                                                      item.substitutePrice! <=
                                                                          item
                                                                              .product
                                                                              .price
                                                                      ? AppColors
                                                                            .success
                                                                      : AppColors
                                                                            .accent,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      // Substitute photo thumbnail
                                                      if (item.substitutePhotoUrl !=
                                                          null)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 8,
                                                              ),
                                                          child: GestureDetector(
                                                            onTap: () => showDialog(
                                                              context: context,
                                                              builder: (_) => Dialog(
                                                                child: ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                  child: Image.network(
                                                                    item.substitutePhotoUrl!,
                                                                    fit: BoxFit
                                                                        .contain,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              child: Image.network(
                                                                item.substitutePhotoUrl!,
                                                                height: 80,
                                                                width: double
                                                                    .infinity,
                                                                fit: BoxFit
                                                                    .cover,
                                                                errorBuilder:
                                                                    (
                                                                      _,
                                                                      __,
                                                                      ___,
                                                                    ) =>
                                                                        const SizedBox.shrink(),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      const SizedBox(height: 8),
                                                      // Accept/Reject/Waiting or confirmed status
                                                      if (item.substitutionApproved ==
                                                          null)
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: SizedBox(
                                                                height: 30,
                                                                child: OutlinedButton(
                                                                  onPressed: () =>
                                                                      _respondToSubstitution(
                                                                        item,
                                                                        true,
                                                                      ),
                                                                  style: OutlinedButton.styleFrom(
                                                                    foregroundColor:
                                                                        AppColors
                                                                            .success,
                                                                    side: const BorderSide(
                                                                      color: AppColors
                                                                          .success,
                                                                    ),
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            6,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  child: const Text(
                                                                    'Accept',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Expanded(
                                                              child: SizedBox(
                                                                height: 30,
                                                                child: OutlinedButton(
                                                                  onPressed: () =>
                                                                      _showRejectSubstituteSheet(
                                                                        item,
                                                                      ),
                                                                  style: OutlinedButton.styleFrom(
                                                                    foregroundColor:
                                                                        AppColors
                                                                            .error,
                                                                    side: const BorderSide(
                                                                      color: AppColors
                                                                          .error,
                                                                    ),
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            6,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                  child: const Text(
                                                                    'Not this one',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      else if (item
                                                          .isPendingShopperResponse)
                                                        // Customer rejected and counter-suggested — waiting for shopper
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 10,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppColors
                                                                .primaryOrange
                                                                .withValues(
                                                                  alpha: 0.08,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            border: Border.all(
                                                              color: AppColors
                                                                  .primaryOrange
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  const SizedBox(
                                                                    width: 14,
                                                                    height: 14,
                                                                    child: CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                      color: AppColors
                                                                          .primaryOrange,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Text(
                                                                    'Waiting for your shopper…',
                                                                    style: AppTextStyles.caption.copyWith(
                                                                      color: AppColors
                                                                          .primaryOrange,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      fontSize:
                                                                          11,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              if (item.customerCounterSuggestion !=
                                                                  null) ...[
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  'You asked for: ${item.customerCounterSuggestion}',
                                                                  style: AppTextStyles
                                                                      .caption
                                                                      .copyWith(
                                                                        color: AppColors
                                                                            .textSecondary,
                                                                        fontSize:
                                                                            11,
                                                                      ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        )
                                                      else
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 6,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color:
                                                                (item.substitutionApproved ==
                                                                            true
                                                                        ? AppColors
                                                                              .success
                                                                        : AppColors
                                                                              .error)
                                                                    .withValues(
                                                                      alpha:
                                                                          0.08,
                                                                    ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                item.substitutionApproved ==
                                                                        true
                                                                    ? Icons
                                                                          .check_circle
                                                                    : Icons
                                                                          .cancel,
                                                                size: 14,
                                                                color:
                                                                    item.substitutionApproved ==
                                                                        true
                                                                    ? AppColors
                                                                          .success
                                                                    : AppColors
                                                                          .error,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  item.substitutionApproved ==
                                                                          true
                                                                      ? 'Approved — your shopper can buy this substitute.'
                                                                      : 'Rejected — your shopper will skip this substitute.',
                                                                  style: AppTextStyles.caption.copyWith(
                                                                    color:
                                                                        item.substitutionApproved ==
                                                                            true
                                                                        ? AppColors
                                                                              .success
                                                                        : AppColors
                                                                              .error,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            // Regular shopper notes (non-substitution)
                                            else if (item.shopperNotes !=
                                                    null &&
                                                item.shopperNotes!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.info
                                                        .withValues(
                                                          alpha: 0.08,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSizes.radiusXs,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Shopper: ${item.shopperNotes}',
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color: AppColors.info,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSizes.sm),
                                      Text(
                                        Formatters.formatCurrency(
                                          item.found == false
                                              ? 0
                                              : (item.actualPrice ??
                                                        item.product.price) *
                                                    item.quantity,
                                        ),
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              decoration: item.found == false
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: item.found == false
                                                  ? AppColors.textTertiary
                                                  : null,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (!isLast)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSizes.md,
                                      ),
                                      child: Divider(
                                        color: AppColors.lightGrey.withValues(
                                          alpha: 0.5,
                                        ),
                                        height: 1,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Pricing breakdown
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Iconsax.calculator,
                                color: AppColors.primaryOrange,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text('Price Breakdown', style: AppTextStyles.h5),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          _buildPricingRow('Subtotal', order.subtotal),
                          const SizedBox(height: AppSizes.sm),
                          _buildPricingRow(
                            'Service Fee (5%)',
                            order.serviceFee,
                          ),
                          const SizedBox(height: AppSizes.sm),
                          if (order.pawaPayCharge > 0) ...[
                            _buildPricingRow('PawaPay Charge', order.pawaPayCharge),
                            const SizedBox(height: AppSizes.sm),
                          ],
                          if (order.deliveryFee > 0)
                            _buildPricingRow('Delivery Fee', order.deliveryFee)
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Delivery Fee',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.radiusXs,
                                      ),
                                    ),
                                    child: Text(
                                      'FREE',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          Divider(
                            color: AppColors.lightGrey.withValues(alpha: 0.5),
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          // Show adjusted total if items have been shopped
                          Builder(
                            builder: (context) {
                              final hasShoppedItems = order.items.any(
                                (i) => i.found != null,
                              );
                              final hasUnfoundItems = order.items.any(
                                (i) => i.found == false,
                              );

                              if (!hasShoppedItems) {
                                // Not yet shopped — show simple total
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: AppTextStyles.h5.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatCurrency(order.total),
                                      style: AppTextStyles.h4.copyWith(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              if (hasUnfoundItems) {
                                // Calculate original total from ALL items (including not-found)
                                double originalSubtotal = 0;
                                double adjustedSubtotal = 0;
                                for (final item in order.items) {
                                  final price =
                                      item.product.price * item.quantity;
                                  originalSubtotal += price;
                                  if (item.found != false) {
                                    adjustedSubtotal +=
                                        (item.actualPrice ??
                                            item.product.price) *
                                        item.quantity;
                                  }
                                }
                                final originalServiceFee =
                                    originalSubtotal * 0.05;
                                final originalTotal =
                                    originalSubtotal +
                                    originalServiceFee +
                                    order.deliveryFee;
                                final adjustedServiceFee =
                                    adjustedSubtotal * 0.05;
                                final adjustedTotal =
                                    adjustedSubtotal +
                                    adjustedServiceFee +
                                    order.deliveryFee;

                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Original Total',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                        Text(
                                          Formatters.formatCurrency(
                                            originalTotal,
                                          ),
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Adjusted Total',
                                          style: AppTextStyles.h5.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          Formatters.formatCurrency(
                                            adjustedTotal,
                                          ),
                                          style: AppTextStyles.h4.copyWith(
                                            color: AppColors.primaryGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${order.items.where((i) => i.found == false).length} item(s) not available — total adjusted',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              // All items found — show normal total
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: AppTextStyles.h5.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(order.total),
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSizes.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm,
                              vertical: AppSizes.xs,
                            ),
                            decoration: BoxDecoration(
                              color: order.isPaid
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  order.isPaid ? Iconsax.verify : Iconsax.clock,
                                  color: order.isPaid
                                      ? AppColors.success
                                      : AppColors.warning,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  order.isPaid ? 'Paid' : 'Pending Payment',
                                  style: AppTextStyles.caption.copyWith(
                                    color: order.isPaid
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment method',
                                style: AppTextStyles.bodyMedium,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  order.paymentMethod.displayName,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Delivery address
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Iconsax.location,
                                color: AppColors.primaryOrange,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text('Delivery Address', style: AppTextStyles.h5),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _openTrackingInMaps,
                              onLongPress: _copyDeliveryAddress,
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusSm,
                              ),
                              child: Ink(
                                padding: const EdgeInsets.all(AppSizes.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primaryOrange.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            order.deliveryAddress.label,
                                            style: AppTextStyles.labelMedium
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        const Icon(
                                          Iconsax.arrow_right_3,
                                          size: 16,
                                          color: AppColors.primaryOrange,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      order.deliveryAddress.fullAddress,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    if (order.deliveryAddress.landmark !=
                                        null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Iconsax.map,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Near: ${order.deliveryAddress.landmark}',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to open in Maps • Long press to copy',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primaryOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      height: 84,
                                      decoration: BoxDecoration(
                                        color: AppColors.grey100,
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.radiusSm,
                                        ),
                                        border: Border.all(
                                          color: AppColors.grey200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              child: Text(
                                                'Map thumbnail',
                                                style: AppTextStyles.labelSmall
                                                    .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 84,
                                            height: 84,
                                            decoration: BoxDecoration(
                                              color: AppColors.primarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppSizes.radiusSm,
                                                  ),
                                            ),
                                            child: const Icon(
                                              Iconsax.map_1,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Shopper & Rider info
                    if (order.shopperName != null ||
                        order.riderName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.people,
                                  color: AppColors.primaryOrange,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Text('Your Team', style: AppTextStyles.h5),
                              ],
                            ),
                            const SizedBox(height: AppSizes.md),
                            if (order.shopperName != null)
                              _buildPersonRow(
                                context: context,
                                icon: Iconsax.shopping_bag,
                                role: 'Shopper',
                                name: order.shopperName!,
                                phone: order.shopperPhone,
                                photoUrl: order.shopperPhotoUrl,
                              ),
                            if (order.shopperName != null &&
                                order.riderName != null)
                              const Divider(height: AppSizes.lg),
                            if (order.riderName != null)
                              _buildPersonRow(
                                context: context,
                                icon: Iconsax.truck_fast,
                                role: 'Rider',
                                name: order.riderName!,
                                phone: order.riderPhone,
                                photoUrl: order.riderPhotoUrl,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                    ],

                    // Edit order (only for pending — before shopping starts)
                    if (order.status == OrderStatus.pending)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Add items to cart and navigate to checkout for modification
                            final cartProvider = Provider.of<CartProvider>(
                              context,
                              listen: false,
                            );
                            for (final item in order.items) {
                              cartProvider.addToCart(
                                item.product,
                                quantity: item.quantity,
                              );
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Order items added to cart. Modify and place a new order, then cancel this one.',
                                ),
                                backgroundColor: AppColors.info,
                                duration: Duration(seconds: 4),
                              ),
                            );
                            GoRouter.of(context).go('/customer/cart');
                          },
                          icon: const Icon(Iconsax.edit, size: 18),
                          label: const Text('Edit Order'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.info,
                            side: const BorderSide(color: AppColors.info),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Complete Payment button (for unpaid mobile money orders)
                    if ((order.status == OrderStatus.pending ||
                            order.status == OrderStatus.paymentProcessing) &&
                        order.paymentMethod == PaymentMethod.mobileMoney)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: ElevatedButton.icon(
                          onPressed: _isRetryingPayment ? null : _retryPayment,
                          icon: _isRetryingPayment
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Icon(Iconsax.money_send, size: 18),
                          label: Text(
                            _isRetryingPayment
                                ? 'Sending...'
                                : 'Complete Payment',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                    // Cancel order button (only for early statuses)
                    if (order.status == OrderStatus.pending ||
                        order.status == OrderStatus.paymentProcessing ||
                        order.status == OrderStatus.confirmed ||
                        order.status == OrderStatus.shopperAssigned)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: OutlinedButton.icon(
                          onPressed: () => _showCancelDialog(context),
                          icon: const Icon(Iconsax.close_circle, size: 18),
                          label: const Text('Cancel Order'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Refund tracking for cancelled orders
                    if (order.isCancelled) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Iconsax.close_circle,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Text(
                                  'Order Cancelled',
                                  style: AppTextStyles.h5.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            if (order.cancellationReason != null &&
                                order.cancellationReason!.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                'Reason: ${order.cancellationReason}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const Divider(height: AppSizes.lg),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.money_recive,
                                  color: AppColors.primaryGreen,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Text(
                                  'Refund Status',
                                  style: AppTextStyles.labelLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.md),
                            // Refund timeline
                            _buildRefundStep(
                              'Cancellation confirmed',
                              'Your order has been cancelled',
                              true,
                              isFirst: true,
                            ),
                            _buildRefundStep(
                              'Refund initiated',
                              order.paymentMethod ==
                                      PaymentMethod.cashOnDelivery
                                  ? 'No charge — Cash on Delivery'
                                  : 'Refund of ${Formatters.formatCurrency(order.total)} is being processed',
                              true,
                            ),
                            _buildRefundStep(
                              'Refund completed',
                              order.paymentMethod ==
                                      PaymentMethod.cashOnDelivery
                                  ? 'No payment was collected'
                                  : 'Expect ${order.paymentMethod == PaymentMethod.mobileMoney ? '1-2' : '3-5'} business days to ${order.paymentMethod.displayName}',
                              order.paymentMethod ==
                                  PaymentMethod.cashOnDelivery,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                    ],

                    // Delivery proof photo
                    if (order.status == OrderStatus.delivered &&
                        order.deliveryProofUrl != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Iconsax.camera,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.sm),
                                Text('Delivery Proof', style: AppTextStyles.h5),
                              ],
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Photo taken by rider at delivery',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),
                            GestureDetector(
                              onTap: () => _showFullScreenPhoto(
                                context,
                                order.deliveryProofUrl!,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusSm,
                                ),
                                child: Image.network(
                                  order.deliveryProofUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          height: 200,
                                          color: AppColors.grey100,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 100,
                                        color: AppColors.grey100,
                                        child: const Center(
                                          child: Text('Photo unavailable'),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                    ],

                    // Reorder button for delivered orders
                    if (order.status == OrderStatus.delivered) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final cartProvider = Provider.of<CartProvider>(
                              context,
                              listen: false,
                            );
                            int added = 0;
                            for (final item in order.items) {
                              final product = item.product.id == 'unknown'
                                  ? Product(
                                      id: 'reorder_${item.product.name}_$added',
                                      name: item.product.name,
                                      description: item.product.description,
                                      image: item.product.image,
                                      price:
                                          item.actualPrice ??
                                          item.product.price,
                                      unit: item.product.unit,
                                      categoryId: item.product.categoryId,
                                      categoryName: item.product.categoryName,
                                      isAvailable: true,
                                    )
                                  : item.product;
                              cartProvider.addToCart(
                                product,
                                quantity: item.quantity,
                              );
                              added++;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$added items added to cart'),
                                backgroundColor: AppColors.success,
                                action: SnackBarAction(
                                  label: 'Checkout',
                                  textColor: Colors.white,
                                  onPressed: () => GoRouter.of(
                                    context,
                                  ).go('/customer/checkout'),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Iconsax.refresh_2, size: 18),
                          label: const Text('Reorder'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                    ],

                    // Rate This Order button (delivered, unrated)
                    if (order.status == OrderStatus.delivered &&
                        order.rating == null &&
                        !order.hasBeenRated)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: ElevatedButton.icon(
                          onPressed: () => context.push(
                            '/customer/order-rating',
                            extra: order,
                          ),
                          icon: const Icon(Iconsax.star, size: 18),
                          label: const Text('Rate This Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Rating display (delivered, already rated)
                    if (order.status == OrderStatus.delivered &&
                        order.rating != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Your Rating',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (order.rating!.shopperRating != null)
                                _ratingTrackingRow(
                                  'Shopper',
                                  order.rating!.shopperRating!,
                                ),
                              if (order.rating!.riderRating != null)
                                _ratingTrackingRow(
                                  'Rider',
                                  order.rating!.riderRating!,
                                ),
                              if (order.rating!.overallRating != null)
                                _ratingTrackingRow(
                                  'Overall',
                                  order.rating!.overallRating!,
                                ),
                              if (order.rating!.comment != null &&
                                  order.rating!.comment!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '"${order.rating!.comment}"',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    // Report Issue button (delivered orders)
                    if (order.status == OrderStatus.delivered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: OutlinedButton.icon(
                          onPressed: () => _showReportIssueBottomSheet(context),
                          icon: const Icon(Iconsax.warning_2, size: 18),
                          label: const Text('Report Issue'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Help button
                    CustomButton(
                      text: 'Need Help?',
                      isOutlined: true,
                      icon: Iconsax.message_question,
                      onPressed: () {
                        launchUrl(
                          Uri.parse(
                            'https://wa.me/256785796401?text=Hi%2C%20I%20need%20help%20with%20order%20%23${order.orderNumber}',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSizes.md),
                    if (order.status == OrderStatus.delivered)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                final cartProvider = Provider.of<CartProvider>(
                                  context,
                                  listen: false,
                                );
                                for (final item in order.items) {
                                  cartProvider.addToCart(
                                    item.product,
                                    quantity: item.quantity,
                                  );
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reorder all added to cart'),
                                  ),
                                );
                              },
                              child: const Text('Reorder all'),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _downloadReceipt,
                              child: const Text('Download receipt'),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSizes.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ratingTrackingRow(String label, int stars) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTrackingZoom(LatLng from, LatLng to) {
    final distanceKm = Distance().as(LengthUnit.Kilometer, from, to);

    if (distanceKm > 30) return 9.5;
    if (distanceKm > 15) return 10.5;
    if (distanceKm > 8) return 11.2;
    if (distanceKm > 4) return 12.0;
    if (distanceKm > 2) return 12.8;
    return 13.8;
  }

  String _formatTrackingDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(distanceKm >= 10 ? 0 : 1)} km';
  }

  String _formatTrackingEta(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'under 1 min';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    }

    final hours = duration.inHours;
    final remainingMinutes = duration.inMinutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  Widget _buildTrackingMarker({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildMapActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingLegendItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          Formatters.formatCurrency(amount),
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String? _resolvePaymentPhone() {
    final authProvider = context.read<AuthProvider>();
    final raw = authProvider.user?.phoneNumber.trim() ?? '';
    if (raw.isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('256') && digits.length == 12) return '+$digits';
    if (digits.startsWith('0') && digits.length == 10) {
      return '+256${digits.substring(1)}';
    }
    if (digits.length == 9) return '+256$digits';
    return null;
  }

  Future<void> _retryPayment() async {
    if (_isRetryingPayment || !mounted) return;
    setState(() => _isRetryingPayment = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;
      if (token == null) return;

      final paymentPhone = _resolvePaymentPhone();
      if (paymentPhone == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No phone number found on your account.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final orderRef = order.documentId ?? order.id;
      final result = await PaymentService.initiateFlutterwaveMobileMoney(
        token: token,
        orderId: orderRef,
        phoneNumber: paymentPhone,
      );

      if (!mounted) return;

      final data = result['data'] as Map<String, dynamic>? ?? {};
      final payment = data['payment'] as Map<String, dynamic>? ?? {};
      final paymentId =
          payment['documentId'] as String? ?? payment['id']?.toString() ?? '';

      context.push(
        '/customer/payment-pending',
        extra: {
          'order': order,
          'paymentId': paymentId,
          'phoneNumber': paymentPhone,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send payment prompt. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetryingPayment = false);
    }
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Changed my mind, ordered wrong items...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cancelling order...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final orderService = Provider.of<OrderService>(
                context,
                listen: false,
              );
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final token = authProvider.token;

              if (token != null) {
                final reason = reasonController.text.trim();
                final success = await orderService.cancelOrder(
                  token,
                  order.documentId ?? order.id,
                  reason: reason,
                );

                // Refresh orders list so it's updated immediately
                await orderService.fetchOrders(
                  token,
                  authProvider.user!.documentId ??
                      authProvider.user!.id.toString(),
                );

                // Dismiss loading
                Navigator.of(context).pop();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order cancelled'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  GoRouter.of(context).go('/customer/orders');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        orderService.error ?? 'Failed to cancel order',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(
    BuildContext context,
    String role,
    String name,
    String phone,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  role == 'Rider' ? Iconsax.truck_fast : Iconsax.shopping_bag,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: AppTextStyles.h5),
              const SizedBox(height: 4),
              Text(
                role,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              // Call button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    try {
                      launchUrl(Uri(scheme: 'tel', path: phone));
                    } catch (_) {
                      Clipboard.setData(ClipboardData(text: phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$phone copied — open your phone app to call',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: Text('Call $role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Copy button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$phone copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Number'),
                  style: OutlinedButton.styleFrom(
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

  Widget _buildTrackingTimeline(BuildContext context) {
    final steps = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.shopperAssigned,
      OrderStatus.shopping,
      OrderStatus.readyForDelivery,
      OrderStatus.riderAssigned,
      OrderStatus.inTransit,
      OrderStatus.delivered,
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isCompleted = order.status.stepIndex >= status.stepIndex;
        final isCurrent = order.status == status;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primaryGreen
                        : isCurrent
                        ? AppColors.primaryGreen.withValues(alpha: 0.2)
                        : AppColors.lightGrey,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: AppColors.primaryGreen, width: 2)
                        : null,
                  ),
                  child: isCompleted
                      ? Icon(
                          _getStatusIcon(status),
                          size: 14,
                          color: Colors.white,
                        )
                      : isCurrent
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted
                        ? AppColors.primaryGreen
                        : AppColors.lightGrey,
                  ),
              ],
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.displayName,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isCompleted
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                    ),
                    // Show person name + call button on relevant steps
                    if (status == OrderStatus.shopperAssigned &&
                        order.shopperName != null &&
                        isCompleted)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${order.shopperName} is your shopper',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          if (order.shopperPhone != null)
                            GestureDetector(
                              onTap: () => _showCallDialog(
                                context,
                                'Shopper',
                                order.shopperName!,
                                order.shopperPhone!,
                              ),
                              child: const Icon(
                                Iconsax.call,
                                size: 16,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                        ],
                      )
                    else if (status == OrderStatus.riderAssigned &&
                        order.riderName != null &&
                        isCompleted)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${order.riderName} is your rider',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          if (order.riderPhone != null)
                            GestureDetector(
                              onTap: () => _showCallDialog(
                                context,
                                'Rider',
                                order.riderName!,
                                order.riderPhone!,
                              ),
                              child: const Icon(
                                Iconsax.call,
                                size: 16,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                        ],
                      )
                    else if (status == OrderStatus.inTransit &&
                        order.riderName != null &&
                        isCompleted)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${order.riderName} is delivering',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          if (order.riderPhone != null)
                            GestureDetector(
                              onTap: () => _showCallDialog(
                                context,
                                'Rider',
                                order.riderName!,
                                order.riderPhone!,
                              ),
                              child: const Icon(
                                Iconsax.call,
                                size: 16,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                        ],
                      )
                    else
                      Text(status.description, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPersonRow({
    required BuildContext context,
    required IconData icon,
    required String role,
    required String name,
    String? phone,
    String? photoUrl,
  }) {
    Widget avatar;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (_, __) => _personInitialAvatar(name, icon),
          errorWidget: (_, __, ___) => _personInitialAvatar(name, icon),
        ),
      );
    } else {
      avatar = _personInitialAvatar(name, icon);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(name, style: AppTextStyles.labelMedium),
                if (phone != null && phone.isNotEmpty)
                  Text(
                    phone,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(
              onPressed: () => _showCallDialog(context, role, name, phone),
              icon: const Icon(
                Iconsax.call,
                color: AppColors.primaryGreen,
                size: 22,
              ),
              tooltip: 'Call $role',
            ),
        ],
      ),
    );
  }

  Widget _personInitialAvatar(String name, IconData icon) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : null;
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
      child: initial != null
          ? Text(
              initial,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w700,
              ),
            )
          : Icon(icon, color: AppColors.primaryOrange, size: 20),
    );
  }

  Widget _buildRefundStep(
    String title,
    String subtitle,
    bool isComplete, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete ? AppColors.primaryGreen : AppColors.grey300,
              ),
              child: Icon(
                isComplete ? Icons.check : Icons.circle_outlined,
                size: 14,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isComplete ? AppColors.primaryGreen : AppColors.grey300,
              ),
          ],
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isComplete
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showReportIssueBottomSheet(BuildContext context) {
    String? selectedIssue;
    final detailsController = TextEditingController();
    final issues = [
      'Missing item',
      'Damaged item',
      'Wrong item',
      'Late delivery',
      'Rider issue',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              MediaQuery.of(ctx).viewInsets.bottom + AppSizes.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report an issue', style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: issues.map((issue) {
                    final selected = selectedIssue == issue;
                    return ChoiceChip(
                      label: Text(issue),
                      selected: selected,
                      onSelected: (_) =>
                          setSheetState(() => selectedIssue = issue),
                      selectedColor: AppColors.primarySoft,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.camera, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add photo (camera first on mobile)',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Describe what happened',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Refunds via Mobile Money within 24 hrs.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedIssue == null
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Issue submitted. We will follow up shortly.',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                    child: const Text('Submit issue'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _downloadReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt download will start shortly.')),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.access_time;
      case OrderStatus.confirmed:
        return Icons.payment;
      case OrderStatus.shopperAssigned:
        return Icons.person;
      case OrderStatus.shopping:
        return Iconsax.shopping_bag;
      case OrderStatus.readyForDelivery:
        return Icons.inventory_2;
      case OrderStatus.riderAssigned:
        return Iconsax.truck_fast;
      case OrderStatus.inTransit:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.paymentProcessing:
        return Icons.hourglass_top;
      case OrderStatus.refunded:
        return Icons.currency_exchange;
    }
  }

  /// Vertical timeline: Confirmed → Packed → Rider assigned → On the way → Delivered.
  Widget _buildStatusTimeline() {
    // Don't show the happy-path timeline for terminal error states.
    if (order.isCancelled || order.status == OrderStatus.refunded) {
      return const SizedBox.shrink();
    }

    // Use stepIndex (0-7 on the happy path) so cancelled/refunded (-1) can't
    // accidentally satisfy a ">=" comparison against a mid-flow step.
    final step = order.status.stepIndex;
    final isConfirmed = step >= 1; // paymentConfirmed and above
    final isPacked = step >= OrderStatus.readyForDelivery.stepIndex;
    final isRiderDone = step >= OrderStatus.inTransit.stepIndex;

    final steps = [
      _TimelineStep(
        label: 'Order Confirmed',
        subLabel: 'We received your order',
        icon: Iconsax.tick_circle,
        done: isConfirmed,
        active:
            order.status == OrderStatus.pending ||
            order.status == OrderStatus.paymentProcessing ||
            order.status == OrderStatus.confirmed,
      ),
      _TimelineStep(
        label: 'Packed',
        subLabel: 'Your items are being packed',
        icon: Iconsax.box,
        done: isPacked,
        active:
            order.status == OrderStatus.shopperAssigned ||
            order.status == OrderStatus.shopping,
      ),
      _TimelineStep(
        label: 'Rider Assigned',
        subLabel: order.riderName != null
            ? '${order.riderName} is on it'
            : 'A rider will be assigned soon',
        icon: Iconsax.personalcard,
        done: isRiderDone,
        active:
            order.status == OrderStatus.riderAssigned ||
            order.status == OrderStatus.readyForDelivery,
        riderPhone: order.riderPhone,
      ),
      _TimelineStep(
        label: 'On the Way',
        subLabel: _routeDuration != null
            ? 'ETA ~${_routeDuration!.inMinutes} min'
            : 'Your order is on the way',
        icon: Iconsax.truck_fast,
        done: order.isDelivered,
        active: order.status == OrderStatus.inTransit,
      ),
      _TimelineStep(
        label: 'Delivered',
        subLabel: 'Enjoy your fresh groceries!',
        icon: Iconsax.verify5,
        done: order.isDelivered,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            final dotColor = step.done
                ? AppColors.success
                : step.active
                ? AppColors.primary
                : AppColors.grey300;
            final lineColor = step.done ? AppColors.success : AppColors.grey200;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: step.done
                            ? AppColors.success
                            : step.active
                            ? AppColors.primarySoft
                            : AppColors.grey100,
                        shape: BoxShape.circle,
                        border: Border.all(color: dotColor, width: 2),
                      ),
                      child: Icon(
                        step.icon,
                        size: 15,
                        color: step.done
                            ? Colors.white
                            : step.active
                            ? AppColors.primary
                            : AppColors.grey400,
                      ),
                    ),
                    if (!isLast)
                      Container(width: 2, height: 32, color: lineColor),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: step.done || step.active
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                            fontWeight: step.active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.subLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: step.done || step.active
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
                          ),
                        ),
                        if (step.active && step.riderPhone != null) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse('tel:${step.riderPhone}');
                              await launchUrl(uri);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.sm,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusFull,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Iconsax.call,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Call rider',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.paymentProcessing:
        return AppColors.warning;
      case OrderStatus.confirmed:
      case OrderStatus.shopperAssigned:
      case OrderStatus.shopping:
      case OrderStatus.readyForDelivery:
      case OrderStatus.riderAssigned:
      case OrderStatus.inTransit:
        return AppColors.info;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return AppColors.error;
    }
  }
}

class _TimelineStep {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool done;
  final bool active;
  final String? riderPhone;

  const _TimelineStep({
    required this.label,
    required this.subLabel,
    required this.icon,
    this.done = false,
    this.active = false,
    this.riderPhone,
  });
}
