import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rider_provider.dart';
import '../../models/user.dart';
import '../../widgets/error_boundary.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_sizes.dart';


class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  int _currentNavIndex = 0;

  // Rider orange theme colors
  static const Color _brandColor = AppColors.accent;

  static const Color _brandColorSoft = AppColors.accentSoft;
  static const Color _brandColorMuted = AppColors.accentMuted;

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
      GoRouter.of(context).go(
        authProvider.user?.role == UserRole.admin
            ? '/admin/dashboard'
            : authProvider.user?.role == UserRole.shopper
                ? '/shopper/home'
                : '/customer/home',
      );
      return;
    }

    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final riderProvider = context.read<RiderProvider>();

    if (authProvider.token != null && authProvider.user?.id != null) {
      if (authProvider.user!.riderId != null) {
        riderProvider.loadRiderProfile(
          authProvider.token!,
          authProvider.user!.riderId!,
        );
      }
      riderProvider.fetchAvailableDeliveries(authProvider.token!);
      final userDocId = authProvider.user!.documentId ?? authProvider.user!.id;
      riderProvider.fetchActiveDeliveries(authProvider.token!, userDocId);
      riderProvider.fetchCompletedDeliveries(authProvider.token!, userDocId);
    }
  }

  Future<void> _onRefresh() async {
    _loadData();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'R';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getDisplayName(String? name) {
    if (name == null || name.isEmpty) return 'Rider';
    return name
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  String _formatEarnings(double amount) {
    if (amount == 0) return 'UGX 0';
    if (amount >= 1000000) {
      return 'UGX ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return 'UGX ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'UGX ${amount.toStringAsFixed(0)}';
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/rider/available-deliveries');
        setState(() => _currentNavIndex = 0);
        break;
      case 2:
        context.push('/rider/earnings');
        setState(() => _currentNavIndex = 0);
        break;
      case 3:
        context.push('/rider/profile');
        setState(() => _currentNavIndex = 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<AuthProvider, RiderProvider>(
        builder: (context, authProvider, riderProvider, _) {
          final user = authProvider.user;
          final isOnline = riderProvider.isOnline;

          return ErrorBoundary(
            onRetry: () => setState(() {}),
            child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: _brandColor,
            child: CustomScrollView(
              slivers: [
                // Custom App Bar
                SliverAppBar(
                  expandedHeight: 0,
                  floating: true,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Online status indicator
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          if (authProvider.token != null &&
                              user?.id != null) {
                            riderProvider.toggleOnlineStatus(
                              authProvider.token!,
                              user!.id,
                              !isOnline,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? _brandColorSoft
                                : AppColors.grey100,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                            border: Border.all(
                              color: isOnline
                                  ? _brandColor
                                  : AppColors.grey300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? _brandColor
                                      : AppColors.grey400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOnline
                                      ? _brandColor
                                      : AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),

                // Body content
                SliverPadding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Welcome Card
                      _buildWelcomeCard(user, isOnline),
                      const SizedBox(height: AppSizes.lg),

                      // Today's Summary
                      _buildSectionHeader(
                        'Today\'s Summary',
                        icon: Iconsax.chart_1,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _buildStatsGrid(riderProvider),
                      const SizedBox(height: AppSizes.lg),

                      // Performance Section
                      _buildSectionHeader(
                        'Your Performance',
                        icon: Iconsax.star_1,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _buildPerformanceCard(riderProvider),
                      const SizedBox(height: AppSizes.lg),

                      // Quick Actions
                      _buildSectionHeader(
                        'Quick Actions',
                        icon: Iconsax.flash_1,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _buildQuickActions(context),
                      const SizedBox(height: AppSizes.lg),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildWelcomeCard(User? user, bool isOnline) {
    final initials = _getInitials(user?.name);
    final displayName = _getDisplayName(user?.name);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOnline
                      ? 'You\'re visible for deliveries'
                      : 'Go online to receive deliveries',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(RiderProvider riderProvider) {
    final availableCount = riderProvider.availableDeliveries.length;
    final activeCount = riderProvider.activeDeliveries.length;
    final completedCount = riderProvider.completedDeliveries.isNotEmpty
        ? riderProvider.completedDeliveries.length
        : riderProvider.completedOrders;
    final earnings = riderProvider.totalEarnings;

    final allZero =
        availableCount == 0 && activeCount == 0 && completedCount == 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Iconsax.truck,
                title: 'Available',
                value: '$availableCount',
                color: AppColors.info,
                bgColor: AppColors.cardBlue,
                onTap: () => context.push('/rider/available-deliveries'),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildStatCard(
                icon: Iconsax.timer_1,
                title: 'Active',
                value: '$activeCount',
                color: _brandColor,
                bgColor: AppColors.cardOrange,
                onTap: () => context.push('/rider/active-deliveries'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Iconsax.tick_circle,
                title: 'Completed',
                value: '$completedCount',
                color: AppColors.success,
                bgColor: AppColors.cardGreen,
                onTap: () => context.push('/rider/ratings'),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildStatCard(
                icon: Iconsax.wallet_2,
                title: 'Earnings',
                value: _formatEarnings(earnings),
                color: _brandColor,
                bgColor: AppColors.cardYellow,
                onTap: () => context.push('/rider/earnings'),
              ),
            ),
          ],
        ),
        if (allZero) ...[
          const SizedBox(height: AppSizes.md),
          GestureDetector(
            onTap: () => context.push('/rider/available-deliveries'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: _brandColorSoft,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: _brandColorMuted),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _brandColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Icon(Iconsax.truck_fast,
                        color: _brandColor, size: 20),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start delivering today!',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _brandColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Browse available deliveries and pick your first order',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: _brandColor),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.grey200),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: AppColors.grey400),
              ],
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
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(RiderProvider riderProvider) {
    final rating = riderProvider.averageRating;
    final reviews = riderProvider.totalReviews;
    final hasData = reviews > 0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowSm,
      ),
      child: hasData
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Average Rating',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          if (i < rating.floor()) {
                            return const Icon(Icons.star_rounded,
                                size: 18, color: Colors.amber);
                          } else if (i < rating) {
                            return const Icon(Icons.star_half_rounded,
                                size: 18, color: Colors.amber);
                          }
                          return Icon(Icons.star_outline_rounded,
                              size: 18, color: AppColors.grey300);
                        }),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: AppColors.grey200,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$reviews',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'customer ratings',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Icon(Iconsax.star_1, size: 36, color: AppColors.grey300),
                const SizedBox(height: AppSizes.sm),
                const Text(
                  'No ratings yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete your first delivery to start building your reputation!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionTile(
                icon: Iconsax.truck_fast,
                label: 'Browse Deliveries',
                color: AppColors.info,
                bgColor: AppColors.cardBlue,
                onTap: () => context.push('/rider/available-deliveries'),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildQuickActionTile(
                icon: Iconsax.task_square,
                label: 'Active Orders',
                color: _brandColor,
                bgColor: AppColors.cardOrange,
                onTap: () => context.push('/rider/active-deliveries'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionTile(
                icon: Iconsax.chart_2,
                label: 'Earnings History',
                color: _brandColor,
                bgColor: AppColors.cardYellow,
                onTap: () => context.push('/rider/earnings'),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildQuickActionTile(
                icon: Iconsax.star_1,
                label: 'My Ratings',
                color: AppColors.success,
                bgColor: AppColors.cardGreen,
                onTap: () => context.push('/rider/ratings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSizes.md, horizontal: AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.grey200),
          boxShadow: AppColors.shadowSm,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Iconsax.home_2,
                activeIcon: Iconsax.home_25,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Iconsax.truck,
                activeIcon: Iconsax.truck_tick,
                label: 'Deliveries',
                index: 1,
              ),
              _buildNavItem(
                icon: Iconsax.wallet_2,
                activeIcon: Iconsax.wallet_25,
                label: 'Earnings',
                index: 2,
              ),
              _buildNavItem(
                icon: Iconsax.profile_circle,
                activeIcon: Iconsax.profile_circle5,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive ? _brandColor : AppColors.grey500,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? _brandColor : AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
