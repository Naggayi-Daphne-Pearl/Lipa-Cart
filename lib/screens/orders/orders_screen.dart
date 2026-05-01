import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_order_status_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/error_boundary.dart';
import '../../widgets/desktop_top_nav_bar.dart';

class OrdersScreen extends StatefulWidget {
  final bool showBottomNav;

  const OrdersScreen({super.key, this.showBottomNav = true});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoadingOrders = false;
  Timer? _pollTimer;
  late final AnimationController _pulseController;
  final Set<String> _expandedOrderIds = <String>{};
  final Map<String, Set<String>> _selectedReorderItems = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted) {
        _fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (_isLoadingOrders) return;
    final authProvider = context.read<AuthProvider>();
    final orderService = context.read<OrderService>();
    final orderProvider = context.read<OrderProvider>();

    if (authProvider.user == null || authProvider.token == null) {
      return;
    }

    if (mounted) {
      setState(() => _isLoadingOrders = true);
    }

    try {
      final success = await orderService.fetchOrders(
        authProvider.token!,
        authProvider.user!.documentId ?? authProvider.user!.id.toString(),
      );

      if (success && mounted) {
        orderProvider.syncOrdersFromService(orderService.orders);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = [...orderProvider.orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final activeOrders = orders
        .where(
          (o) =>
              o.status != OrderStatus.cancelled &&
              o.status != OrderStatus.refunded &&
              o.status != OrderStatus.delivered,
        )
        .toList();
    final activeOrder = activeOrders.isNotEmpty ? activeOrders.first : null;

    final pastOrders = orders
        .where(
          (o) =>
              o.status == OrderStatus.delivered ||
              o.status == OrderStatus.cancelled ||
              o.status == OrderStatus.refunded,
        )
        .toList();

    final grouped = _groupByMonth(pastOrders);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: null,
      body: ErrorBoundary(
        onRetry: () => setState(() {
          _fetchOrders();
        }),
        child: ResponsiveContainer(
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchOrders,
              child: _isLoadingOrders && orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppLoadingIndicator(),
                          const SizedBox(height: AppSizes.md),
                          Text(
                            'Loading orders...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        const SliverToBoxAdapter(
                          child: DesktopTopNavBar(activeSection: 'orders'),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSizes.lg,
                              AppSizes.sm,
                              AppSizes.lg,
                              AppSizes.md,
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.pop(context);
                                    } else {
                                      GoRouter.of(context).go('/customer/home');
                                    }
                                  },
                                  child: const Icon(Iconsax.arrow_left, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'My Orders',
                                  style: AppTextStyles.h3.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (activeOrder != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                context.horizontalPadding,
                                0,
                                context.horizontalPadding,
                                AppSizes.lg,
                              ),
                              child: _buildActiveOrderCard(context, activeOrder),
                            ),
                          ),
                        if (grouped.isEmpty)
                          SliverToBoxAdapter(
                            child: _buildEmptyState(
                              context,
                              activeOrder == null
                                  ? 'No orders yet'
                                  : 'No past orders yet',
                            ),
                          )
                        else
                          ..._buildPastOrderSlivers(context, grouped),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 100),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPastOrderSlivers(
    BuildContext context,
    Map<String, List<Order>> grouped,
  ) {
    final slivers = <Widget>[];
    grouped.forEach((month, orders) {
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _MonthHeaderDelegate(month: month),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            context.horizontalPadding,
            AppSizes.sm,
            context.horizontalPadding,
            AppSizes.md,
          ),
          sliver: SliverList.separated(
            itemBuilder: (_, index) {
              final order = orders[index];
              return _buildPastOrderCard(context, order);
            },
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
            itemCount: orders.length,
          ),
        ),
      );
    });
    return slivers;
  }

  Widget _buildActiveOrderCard(BuildContext context, Order order) {
    final eta = _etaLabel(order);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Active order #${order.orderNumber}',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) {
                  final scale = 1 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: _buildLiveStatusPill(order.status, eta),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  _initials(order.riderName ?? 'Rider'),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.riderName ?? 'Rider will be assigned',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      order.riderPhone ?? 'Phone unavailable',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (order.riderPhone != null)
                GestureDetector(
                  onTap: () => _showCallSnack(order.riderPhone!),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const Icon(Iconsax.call, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/customer/order-tracking', extra: order),
              icon: const Icon(Iconsax.location, size: 18),
              label: const Text('Track on map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastOrderCard(BuildContext context, Order order) {
    final expanded = _expandedOrderIds.contains(order.id);
    final selected = _selectedReorderItems.putIfAbsent(
      order.id,
      () => order.items.map((item) => item.id).toSet(),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedOrderIds.remove(order.id);
                } else {
                  _expandedOrderIds.add(order.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemThumbStack(order),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dateTimeLabel(order.createdAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatCurrency(order.total),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildStatusBadge(order.status),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  ElevatedButton(
                    onPressed: () => _reorderSelected(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    child: const Text('Reorder'),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                0,
                AppSizes.md,
                AppSizes.md,
              ),
              child: Column(
                children: order.items.map((item) {
                  final isSelected = selected.contains(item.id);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Switch.adaptive(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v) {
                                selected.add(item.id);
                              } else {
                                selected.remove(item.id);
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            '${item.product.name} x${item.quantity.toInt()}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(item.totalPrice),
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemThumbStack(Order order) {
    final items = order.items.take(3).toList();
    final more = order.items.length - 3;

    return SizedBox(
      width: 62,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < items.length; i++)
            Positioned(
              left: i * 14,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    items[i].product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Iconsax.box,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          if (more > 0)
            Positioned(
              right: -2,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.grey800,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '+$more more',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusPill(OrderStatus status, String eta) {
    final (bgColor, textColor, label) = _getStatusColors(status);
    final display = eta.isEmpty ? label : '$label • $eta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        display,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    final (bgColor, textColor, label) = _getStatusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  (Color bgColor, Color textColor, String label) _getStatusColors(
    OrderStatus status,
  ) {
    final t = AppOrderStatusColors.triple(status);
    return (t.$1, t.$2, t.$3);
  }

  Map<String, List<Order>> _groupByMonth(List<Order> orders) {
    final map = <String, List<Order>>{};
    for (final order in orders) {
      final key = _monthYear(order.createdAt);
      map.putIfAbsent(key, () => []).add(order);
    }
    return map;
  }

  String _monthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _dateTimeLabel(DateTime dt) {
    final date = Formatters.formatDate(dt);
    final time = TimeOfDay.fromDateTime(dt).format(context);
    return '$date • $time';
  }

  String _etaLabel(Order order) {
    if (order.estimatedDelivery == null) return '';
    final mins = order.estimatedDelivery!.difference(DateTime.now()).inMinutes;
    if (mins <= 1) return 'Arriving soon';
    if (mins > 90) return '';
    return 'Arriving in $mins min';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'R';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  void _showCallSnack(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Call rider: $phone'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reorderSelected(Order order) {
    final selectedIds = _selectedReorderItems[order.id] ?? {};
    if (selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item to reorder')),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    var added = 0;
    for (final item in order.items) {
      if (selectedIds.contains(item.id)) {
        cartProvider.addToCart(item.product, quantity: item.quantity);
        added += item.quantity.toInt();
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $added items to cart')),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsive<double>(
          mobile: AppSizes.xl,
          tablet: AppSizes.xl,
          desktop: AppSizes.xl,
        ),
        0,
        context.responsive<double>(
          mobile: AppSizes.xl,
          tablet: AppSizes.xl,
          desktop: AppSizes.xl,
        ),
        context.responsive<double>(
          mobile: AppSizes.xl,
          tablet: AppSizes.xl,
          desktop: AppSizes.xl,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: context.responsive<double>(
              mobile: 80.0,
              tablet: 100.0,
              desktop: 120.0,
            ),
            height: context.responsive<double>(
              mobile: 80.0,
              tablet: 100.0,
              desktop: 120.0,
            ),
            decoration: const BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.receipt_item,
              size: context.responsive<double>(
                mobile: 40.0,
                tablet: 48.0,
                desktop: 56.0,
              ),
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          ElevatedButton(
            onPressed: () => context.go('/customer/categories'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            child: Text(
              'Browse Products',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String month;

  _MonthHeaderDelegate({required this.month});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: AppSizes.sm,
      ),
      child: Text(
        month,
        style: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 42;

  @override
  double get minExtent => 42;

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate oldDelegate) {
    return oldDelegate.month != month;
  }
}
