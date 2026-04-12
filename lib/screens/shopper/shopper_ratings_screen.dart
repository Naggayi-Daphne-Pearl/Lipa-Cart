import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class ShopperRatingsScreen extends StatefulWidget {
  const ShopperRatingsScreen({super.key});

  @override
  State<ShopperRatingsScreen> createState() => _ShopperRatingsScreenState();
}

class _ShopperRatingsScreenState extends State<ShopperRatingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _validateRoleAndLoad();
    });
  }

  void _validateRoleAndLoad() {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user?.role != UserRole.shopper) {
      if (!mounted) return;
      GoRouter.of(context).go(
        authProvider.user?.role == UserRole.admin
            ? '/admin/dashboard'
            : authProvider.user?.role == UserRole.rider
                ? '/rider/home'
                : '/customer/home',
      );
      return;
    }
    final shopperProvider = context.read<ShopperProvider>();
    final token = authProvider.token;
    final shopperId = authProvider.user?.shopperId;
    final userDocumentId = authProvider.user?.documentId;
    final userId = authProvider.user?.id;
    if (token != null && shopperId != null) {
      shopperProvider.loadShopperProfile(
        token,
        shopperId,
        userDocumentId: userDocumentId,
        userId: userId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ratings & Reviews'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ShopperProvider>(
        builder: (context, shopper, _) {
          final rating = shopper.averageRating;
          final reviews = shopper.totalReviews;
          final reviewItems = shopper.ratings;
          final allWrittenReviews = reviewItems.where((review) {
            final comment = (review['comment'] as String?) ?? '';
            return comment.trim().isNotEmpty;
          }).toList();
          final writtenReviews = allWrittenReviews.take(10).toList();
          final breakdown = shopper.ratingBreakdown;
          final completedCount = shopper.completedOrders;
          final hasData = reviews > 0;
          final ratingsWithoutComments = hasData
              ? (reviews - allWrittenReviews.length).clamp(0, reviews)
              : 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.grey200),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: hasData
                      ? Column(
                          children: [
                            const Text(
                              'Your Rating',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                if (i < rating.floor()) {
                                  return const Icon(
                                    Icons.star_rounded,
                                    size: 28,
                                    color: Colors.amber,
                                  );
                                } else if (i < rating) {
                                  return const Icon(
                                    Icons.star_half_rounded,
                                    size: 28,
                                    color: Colors.amber,
                                  );
                                }
                                return Icon(
                                  Icons.star_outline_rounded,
                                  size: 28,
                                  color: AppColors.grey300,
                                );
                              }),
                            ),
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Based on $reviews reviews',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.star_1,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.md),
                            const Text(
                              'No ratings yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSizes.xs),
                            const Text(
                              'Complete shopping tasks to start receiving ratings from customers',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  'Performance Stats',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: _buildPerfCard(
                        icon: Iconsax.tick_circle,
                        label: 'Completed',
                        value: '$completedCount',
                        color: AppColors.success,
                        bgColor: AppColors.cardGreen,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _buildPerfCard(
                        icon: Iconsax.star_1,
                        label: 'Avg Rating',
                        value: hasData ? rating.toStringAsFixed(1) : '--',
                        color: Colors.amber,
                        bgColor: AppColors.cardYellow,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _buildPerfCard(
                        icon: Iconsax.message_text_1,
                        label: 'Reviews',
                        value: '$reviews',
                        color: AppColors.info,
                        bgColor: AppColors.cardBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                if (hasData) ...[
                  Text(
                    'Rating Breakdown',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.grey200),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: Column(
                      children: _buildRatingBreakdown(breakdown, reviews),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
                Text(
                  'Written Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSizes.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: writtenReviews.isEmpty
                      ? _buildWrittenReviewEmptyState(hasData, ratingsWithoutComments)
                      : Column(
                          children: [
                            ...writtenReviews.map(_buildReviewCard),
                            if (ratingsWithoutComments > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: AppSizes.xs),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$ratingsWithoutComments more rating${ratingsWithoutComments == 1 ? '' : 's'} without written feedback.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildRatingBreakdown(Map<int, int> breakdown, int totalReviews) {
    return List.generate(5, (i) {
      final star = 5 - i;
      final count = breakdown[star] ?? 0;
      final fraction = totalReviews > 0 ? count / totalReviews : 0.0;
      return _buildRatingBar('$star', fraction);
    });
  }

  Widget _buildPerfCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusXs),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              stars,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 8,
                backgroundColor: AppColors.grey100,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${(percentage * 100).round()}%',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrittenReviewEmptyState(bool hasRatings, int ratingsWithoutComments) {
    return Column(
      children: [
        Icon(Iconsax.message_text_1, size: 36, color: AppColors.grey300),
        const SizedBox(height: AppSizes.sm),
        Text(
          hasRatings ? 'No written reviews yet' : 'No reviews yet',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasRatings
              ? 'Customers have rated your work, but they have not left written feedback yet.'
              : 'Customer feedback will appear here once orders are rated.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textTertiary,
          ),
        ),
        if (hasRatings && ratingsWithoutComments > 0) ...[
          const SizedBox(height: 6),
          Text(
            '$ratingsWithoutComments rating${ratingsWithoutComments == 1 ? '' : 's'} without comments so far.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final stars = (review['stars'] as int?) ?? 0;
    final comment = ((review['comment'] as String?) ?? '').trim();
    final customer = _maskReviewerName(
      (review['customerName'] as String?) ?? 'Customer',
    );
    final orderNumber = (review['orderNumber'] as String?) ?? '';
    final createdAt = _formatReviewDate((review['createdAt'] as String?) ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  customer,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (createdAt.isNotEmpty)
                Text(
                  createdAt,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
                color: Colors.amber,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (orderNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Order #$orderNumber',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
          const Divider(height: 20),
        ],
      ),
    );
  }

  String _maskReviewerName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Customer';

    final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'Customer';
    if (parts.length == 1) {
      return '${parts.first[0].toUpperCase()}.';
    }

    return '${parts.first[0].toUpperCase()}. ${parts.last[0].toUpperCase()}.';
  }

  String _formatReviewDate(String createdAt) {
    if (createdAt.isEmpty) return '';
    final date = DateTime.tryParse(createdAt);
    if (date == null) return createdAt.split('T').first;
    return '${date.day}/${date.month}/${date.year}';
  }
}
