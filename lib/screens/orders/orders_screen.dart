import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_loading_indicator.dart';

class OrdersScreen extends StatefulWidget {
  final bool showBottomNav;

  const OrdersScreen({super.key, this.showBottomNav = true});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

enum OrderTab { active, delivered, cancelled }

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoadingOrders = false;
  OrderTab _selectedTab = OrderTab.active;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
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
        authProvider.user!.id.toString(),
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

    // Filter orders by tab
    final activeOrders = orderProvider.orders
        .where((o) => o.status != OrderStatus.cancelled && o.status != OrderStatus.delivered)
        .toList();
    final deliveredOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.delivered)
        .toList();
    final cancelledOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(currentIndex: 4)
          : null,
      body: ResponsiveContainer(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchOrders,
            child: _isLoadingOrders && orderProvider.orders.isEmpty
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
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.responsive<double>(
                              mobile: AppSizes.lg,
                              tablet: AppSizes.xl,
                              desktop: 24.0,
                            ),
                            AppSizes.md,
                            context.responsive<double>(
                              mobile: AppSizes.lg,
                              tablet: AppSizes.xl,
                              desktop: 24.0,
                            ),
                            context.responsive<double>(
                              mobile: AppSizes.lg,
                              tablet: AppSizes.xl,
                              desktop: 24.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Orders',
                                style: AppTextStyles.h3.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: context.responsive<double>(
                                    mobile: 26.0,
                                    tablet: 30.0,
                                    desktop: 34.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tab Bar
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.horizontalPadding,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.grey200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildTabButton(
                                    context,
                                    'Active',
                                    OrderTab.active,
                                  ),
                                ),
                                Expanded(
                                  child: _buildTabButton(
                                    context,
                                    'Delivered',
                                    OrderTab.delivered,
                                  ),
                                ),
                                Expanded(
                                  child: _buildTabButton(
                                    context,
                                    'Cancelled',
                                    OrderTab.cancelled,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(
                          height: context.responsive<double>(
                            mobile: AppSizes.md,
                            tablet: AppSizes.lg,
                            desktop: AppSizes.lg,
                          ),
                        ),

                        // Orders List
                        if (_selectedTab == OrderTab.active)
                          _buildOrdersList(context, activeOrders)
                        else if (_selectedTab == OrderTab.delivered)
                          _buildOrdersList(context, deliveredOrders)
                        else
                          _buildOrdersList(context, cancelledOrders),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String label, OrderTab tab) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          if (isSelected)
            Container(height: 3, color: AppColors.primary)
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Order> orders) {
    if (orders.isEmpty) {
      final message = switch (_selectedTab) {
        OrderTab.active => 'No active orders yet',
        OrderTab.delivered => 'No delivered orders yet',
        OrderTab.cancelled => 'No cancelled orders',
      };
      return _buildEmptyState(context, message);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
      child: Column(
        children: orders
            .map((order) => _buildCleanOrderCard(context, order))
            .toList(),
      ),
    );
  }

  Widget _buildCleanOrderCard(BuildContext context, Order order) {
    // Get the first product image from the order
    final firstProduct = order.items.isNotEmpty ? order.items.first : null;
    final imageUrl = firstProduct?.product.image;

    return GestureDetector(
      onTap: () => context.push('/customer/order-tracking', extra: order),
      child: Container(
        margin: EdgeInsets.only(
          bottom: context.responsive<double>(
            mobile: AppSizes.md,
            tablet: AppSizes.lg,
            desktop: AppSizes.lg,
          ),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            context.responsive<double>(
              mobile: AppSizes.radiusMd,
              tablet: AppSizes.radiusLg,
              desktop: 12.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(
            context.responsive<double>(
              mobile: AppSizes.md,
              tablet: AppSizes.lg,
              desktop: 16.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: context.responsive<double>(
                  mobile: 70.0,
                  tablet: 80.0,
                  desktop: 90.0,
                ),
                height: context.responsive<double>(
                  mobile: 70.0,
                  tablet: 80.0,
                  desktop: 90.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Iconsax.image,
                              color: AppColors.textTertiary,
                              size: 32,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Iconsax.image,
                        color: AppColors.textTertiary,
                        size: 32,
                      ),
              ),

              const SizedBox(width: AppSizes.lg),

              // Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      firstProduct?.product.name ?? 'Order',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsive<double>(
                          mobile: 14.0,
                          tablet: 15.0,
                          desktop: 15.0,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppSizes.xs),

                    // Order Number
                    Text(
                      'Order #${order.orderNumber}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: context.responsive<double>(
                          mobile: 12.0,
                          tablet: 12.0,
                          desktop: 13.0,
                        ),
                      ),
                    ),

                    SizedBox(
                      height: context.responsive<double>(
                        mobile: AppSizes.sm,
                        tablet: AppSizes.md,
                        desktop: AppSizes.md,
                      ),
                    ),

                    // Status and Date Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status Badge
                        _buildStatusBadge(order.status),

                        // Date
                        Text(
                          Formatters.formatDate(order.createdAt),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: context.responsive<double>(
                              mobile: 11.0,
                              tablet: 12.0,
                              desktop: 12.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSizes.md),

              // Arrow Icon
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
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
    switch (status) {
      case OrderStatus.pending:
        return (const Color(0xFFFFF4E6), const Color(0xFFFF9800), 'Processing');
      case OrderStatus.confirmed:
        return (const Color(0xFFE3F2FD), const Color(0xFF1976D2), 'Confirmed');
      case OrderStatus.shopperAssigned:
        return (const Color(0xFFE0F2F1), const Color(0xFF00897B), 'Shopper Assigned');
      case OrderStatus.shopping:
        return (const Color(0xFFE3F2FD), const Color(0xFF1976D2), 'Shopping');
      case OrderStatus.readyForDelivery:
        return (const Color(0xFFE3F2FD), const Color(0xFF1976D2), 'Ready');
      case OrderStatus.riderAssigned:
        return (Colors.deepPurple[100]!, Colors.deepPurple, 'Rider Assigned');
      case OrderStatus.inTransit:
        return (const Color(0xFFFFF4E6), const Color(0xFFFF9800), 'On the way');
      case OrderStatus.delivered:
        return (const Color(0xFFE8F5E9), const Color(0xFF388E3C), 'Delivered');
      case OrderStatus.cancelled:
        return (const Color(0xFFFFEBEE), const Color(0xFFD32F2F), 'Cancelled');
    }
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Padding(
      padding: EdgeInsets.all(
        context.responsive<double>(
          mobile: AppSizes.xl,
          tablet: AppSizes.xl,
          desktop: AppSizes.xl,
        ),
      ),
      child: Center(
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
              decoration: BoxDecoration(
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
                fontSize: context.responsive<double>(
                  mobile: 14.0,
                  tablet: 15.0,
                  desktop: 16.0,
                ),
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
      ),
    );
  }
}
