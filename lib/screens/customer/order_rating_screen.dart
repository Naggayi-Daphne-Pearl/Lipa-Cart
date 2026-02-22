import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/smooth_transition_wrapper.dart';

class OrderRatingScreen extends StatefulWidget {
  final Order order;

  const OrderRatingScreen({super.key, required this.order});

  @override
  State<OrderRatingScreen> createState() => _OrderRatingScreenState();
}

class _OrderRatingScreenState extends State<OrderRatingScreen> {
  double _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final orderService = context.read<OrderService>();

      final success = await orderService.submitRating(
        token: authProvider.token ?? '',
        orderId: widget.order.id,
        stars: _selectedRating,
        comment: _commentController.text.isEmpty ? null : _commentController.text,
      );

      setState(() => _isSubmitting = false);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your rating!'),
              backgroundColor: AppColors.success,
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) context.go('/customer/orders');
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit rating. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmoothTransitionWrapper(
      transitionType: TransitionType.slideFromBottom,
      child: Scaffold(
        backgroundColor: AppColors.backgroundGrey,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left),
            onPressed: () => context.pop(),
          ),
          title: const Text('Rate Your Order'),
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusXs),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${widget.order.orderNumber}',
                      style: AppTextStyles.h5),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Delivered on ${widget.order.deliveredAt?.toString().split(' ')[0] ?? 'Recently'}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Rating instruction
            Text('How was your delivery experience?',
                style: AppTextStyles.h4),
            const SizedBox(height: AppSizes.md),

            // Star rating widget
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusXs),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final rating = index + 1;
                      final isSelected = _selectedRating >= rating;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedRating = rating.toDouble());
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            isSelected ? Iconsax.star1 : Iconsax.star,
                            size: 48,
                            color: isSelected
                                ? AppColors.primaryOrange
                                : AppColors.lightGrey,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (_selectedRating > 0)
                    Text(
                      _getRatingLabel(_selectedRating),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primaryOrange,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Comment section
            Text('Additional Comments (Optional)', style: AppTextStyles.h5),
            const SizedBox(height: AppSizes.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your feedback about the delivery...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppSizes.md),
                  counterStyle: AppTextStyles.caption,
                ),
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Submit button
            CustomButton(
              text: 'Submit Rating',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitRating,
            ),
            const SizedBox(height: AppSizes.md),

            // Skip button
            OutlinedButton(
              onPressed: _isSubmitting ? null : () => context.go('/customer/orders'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.primaryOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                ),
              ),
              child: Text(
                'Skip for Now',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _getRatingLabel(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
