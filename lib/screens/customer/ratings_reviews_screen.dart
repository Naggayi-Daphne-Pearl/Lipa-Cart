import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class RatingsReviewsScreen extends StatefulWidget {
  const RatingsReviewsScreen({super.key});

  @override
  State<RatingsReviewsScreen> createState() => _RatingsReviewsScreenState();
}

class _RatingsReviewsScreenState extends State<RatingsReviewsScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final auth = context.read<AuthProvider>();
    final orderService = context.read<OrderService>();
    if (auth.token != null && auth.user != null) {
      await orderService.fetchOrders(
        auth.token!,
        auth.user!.documentId ?? auth.user!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderService = context.watch<OrderService>();

    final deliveredOrders = orderService.orders
        .where((o) => o.status == OrderStatus.delivered)
        .toList();

    final ratedOrders = deliveredOrders.where((o) => o.hasBeenRated).toList();
    final unratedOrders = deliveredOrders.where((o) => !o.hasBeenRated).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black87),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer/profile');
            }
          },
        ),
        title: const Text(
          'Ratings & Reviews',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: deliveredOrders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Iconsax.star1, color: AppColors.primaryOrange, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ratedOrders.length} of ${deliveredOrders.length} orders rated',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unratedOrders.isEmpty
                                  ? 'All orders rated!'
                                  : '${unratedOrders.length} order${unratedOrders.length != 1 ? 's' : ''} waiting for your review',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Unrated section
                  if (unratedOrders.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'PENDING REVIEWS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    ...unratedOrders.map((order) => _buildOrderCard(order, rated: false)),
                  ],

                  // Rated section
                  if (ratedOrders.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'COMPLETED REVIEWS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    ...ratedOrders.map((order) => _buildOrderCard(order, rated: true)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.star, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No reviews yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Your reviews will appear here after delivery', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, {required bool rated}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Delivered ${Formatters.formatDate(order.deliveredAt ?? order.createdAt)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (rated && order.rating != null)
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFA726)),
                    const SizedBox(width: 4),
                    Text(
                      order.rating!.stars.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
            ],
          ),

          // Items preview
          const SizedBox(height: 8),
          Text(
            '${order.items.length} item${order.items.length != 1 ? 's' : ''} · ${Formatters.formatCurrency(order.total)}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),

          // Rating stars or Rate button
          const SizedBox(height: 12),
          if (rated && order.rating != null) ...[
            // Show the rating
            Row(
              children: [
                if (order.shopperName != null) ...[
                  _buildMiniRating(Iconsax.shopping_bag, order.shopperName!, order.rating!.stars.toInt()),
                  const SizedBox(width: 16),
                ],
                if (order.riderName != null)
                  _buildMiniRating(Iconsax.truck_fast, order.riderName!, order.rating!.stars.toInt()),
              ],
            ),
            if (order.rating!.comment != null && order.rating!.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.quote_up, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.rating!.comment!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else
            // Rate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/customer/order-rating', extra: order),
                icon: const Icon(Icons.star_rounded, size: 18),
                label: const Text('Rate this order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniRating(IconData icon, String name, int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(name, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(width: 6),
        ...List.generate(5, (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: i < rating ? const Color(0xFFFFA726) : Colors.grey[300],
        )),
      ],
    );
  }
}
