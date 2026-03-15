import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class OrderRatingScreen extends StatefulWidget {
  final Order order;

  const OrderRatingScreen({super.key, required this.order});

  @override
  State<OrderRatingScreen> createState() => _OrderRatingScreenState();
}

class _OrderRatingScreenState extends State<OrderRatingScreen> {
  int _shopperRating = 0;
  int _riderRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_shopperRating == 0 && _riderRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate at least the shopper or rider')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final orderService = context.read<OrderService>();

      final success = await orderService.submitRating(
        token: authProvider.token ?? '',
        orderId: widget.order.documentId ?? widget.order.id,
        overallRating: ((_shopperRating + _riderRating) / 2).round().clamp(1, 5),
        shopperRating: _shopperRating > 0 ? _shopperRating : null,
        riderRating: _riderRating > 0 ? _riderRating : null,
        comment: _commentController.text.isEmpty ? null : _commentController.text,
        customerId: authProvider.user?.id,
      );

      setState(() => _isSubmitting = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your rating!'), backgroundColor: AppColors.success),
        );
        context.go('/customer/orders');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(orderService.error ?? 'Failed to submit rating'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              context.go('/customer/orders');
            }
          },
        ),
        title: const Text(
          'Rate Your Order',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Iconsax.receipt_1, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${widget.order.orderNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Delivered on ${widget.order.deliveredAt?.toString().split(' ')[0] ?? 'Recently'}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Shopper rating
            if (widget.order.shopperName != null) ...[
              _buildRatingCard(
                icon: Iconsax.shopping_bag,
                iconColor: AppColors.primary,
                title: 'How was the shopping?',
                subtitle: widget.order.shopperName!,
                rating: _shopperRating,
                onChanged: (r) => setState(() => _shopperRating = r),
              ),
              const SizedBox(height: 20),
            ],

            // Rider rating
            if (widget.order.riderName != null) ...[
              _buildRatingCard(
                icon: Iconsax.truck_fast,
                iconColor: Colors.deepPurple,
                title: 'How was the delivery?',
                subtitle: widget.order.riderName!,
                rating: _riderRating,
                onChanged: (r) => setState(() => _riderRating = r),
              ),
              const SizedBox(height: 20),
            ],

            // Fallback if no names
            if (widget.order.shopperName == null && widget.order.riderName == null) ...[
              _buildRatingCard(
                icon: Iconsax.star,
                iconColor: AppColors.primaryOrange,
                title: 'How was your experience?',
                subtitle: 'Rate the overall delivery',
                rating: _shopperRating,
                onChanged: (r) => setState(() {
                  _shopperRating = r;
                  _riderRating = r;
                }),
              ),
              const SizedBox(height: 20),
            ],

            // Comment
            const Text(
              'ADDITIONAL COMMENTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              maxLength: 500,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'What did you like the most about it?',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
                counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Rating', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 10),

            // Skip
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: _isSubmitting ? null : () => context.go('/customer/orders'),
                child: Text('Skip for Now', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int rating,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Person info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.grey[200], height: 1),

          const SizedBox(height: 16),

          // Stars
          Text(
            'Tap the stars to rate',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return GestureDetector(
                onTap: () => onChanged(star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 36,
                    color: rating >= star ? const Color(0xFFFFA726) : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
          if (rating > 0) ...[
            const SizedBox(height: 8),
            Text(
              _getRatingLabel(rating),
              style: const TextStyle(
                color: Color(0xFFFFA726),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent!';
      default: return '';
    }
  }
}
