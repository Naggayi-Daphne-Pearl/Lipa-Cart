import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class RiderRatingsScreen extends StatefulWidget {
  const RiderRatingsScreen({super.key});

  @override
  State<RiderRatingsScreen> createState() => _RiderRatingsScreenState();
}

class _RiderRatingsScreenState extends State<RiderRatingsScreen> {
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

    final riderProvider = context.read<RiderProvider>();
    final token = authProvider.token;
    final riderId = authProvider.user?.riderId;
    if (token != null && riderId != null) {
      riderProvider.loadRiderProfile(token, riderId);
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
      body: Consumer<RiderProvider>(
        builder: (context, rider, _) {
          final rating = rider.averageRating;
          final reviews = rider.totalReviews;
          final completedCount = rider.completedOrders;
          final hasData = reviews > 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating Summary Card
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
                                  return const Icon(Icons.star_rounded,
                                      size: 28, color: Colors.amber);
                                } else if (i < rating) {
                                  return const Icon(
                                      Icons.star_half_rounded,
                                      size: 28,
                                      color: Colors.amber);
                                }
                                return Icon(Icons.star_outline_rounded,
                                    size: 28, color: AppColors.grey300);
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
                                color: AppColors.accentSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Iconsax.star_1,
                                  size: 40, color: _brandColor),
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
                              'Complete deliveries to start receiving ratings from customers',
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

                // Performance Stats
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

                // Rating Breakdown
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
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.grey200),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: Column(
                      children: [
                        _buildRatingBar('5', 0.0),
                        _buildRatingBar('4', 0.0),
                        _buildRatingBar('3', 0.0),
                        _buildRatingBar('2', 0.0),
                        _buildRatingBar('1', 0.0),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],

                // Customer Reviews
                Text(
                  'Customer Reviews',
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
                  child: Column(
                    children: [
                      Icon(Iconsax.message_text_1,
                          size: 36, color: AppColors.grey300),
                      const SizedBox(height: AppSizes.sm),
                      const Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Customer feedback will appear here',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
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
              '$stars',
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
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
