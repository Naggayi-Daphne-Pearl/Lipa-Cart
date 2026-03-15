import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../models/user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/logout_helper.dart';
import '../../widgets/shopper_button.dart';

class ShopperHomeScreen extends StatefulWidget {
  const ShopperHomeScreen({super.key});

  @override
  State<ShopperHomeScreen> createState() => _ShopperHomeScreenState();
}

class _ShopperHomeScreenState extends State<ShopperHomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _validateRoleAndLoad();
  }

  void _validateRoleAndLoad() {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.user?.role != UserRole.shopper) {
      Future.microtask(() {
        GoRouter.of(context).go(
          authProvider.user?.role == UserRole.admin
              ? '/admin/dashboard'
              : authProvider.user?.role == UserRole.rider
                  ? '/rider/home'
                  : '/customer/home',
        );
      });
      return;
    }

    _loadData();
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final shopperProvider = context.read<ShopperProvider>();

    final token = authProvider.token;
    final user = authProvider.user;
    if (token != null && user != null) {
      if (user.shopperId != null) {
        shopperProvider.loadShopperProfile(token, user.shopperId!);
      }
      shopperProvider.fetchAvailableTasks(token);
      if (user.documentId != null) {
        shopperProvider.fetchActiveTasks(token, user.documentId!);
        shopperProvider.fetchCompletedTasks(token, user.documentId!);
      }
    }
  }

  Future<void> _onRefresh() async {
    _loadData();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getDisplayName(String? name) {
    if (name == null || name.isEmpty) return 'Shopper';
    // Capitalize each word properly
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
        break; // Already on home
      case 1:
        context.push('/shopper/available-tasks');
        setState(() => _currentNavIndex = 0);
        break;
      case 2:
        context.push('/shopper/earnings');
        setState(() => _currentNavIndex = 0);
        break;
      case 3:
        context.push('/shopper/profile');
        setState(() => _currentNavIndex = 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<AuthProvider, ShopperProvider>(
        builder: (context, authProvider, shopperProvider, _) {
          final user = authProvider.user;
          final isOnline = shopperProvider.isOnline;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.primary,
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
                          final sid = user?.shopperId;
                          if (authProvider.token != null && sid != null) {
                            shopperProvider.toggleOnlineStatus(
                              authProvider.token!,
                              sid,
                              !isOnline,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppColors.primarySoft
                                : AppColors.grey100,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                            border: Border.all(
                              color: isOnline
                                  ? AppColors.primary
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
                                      ? AppColors.primary
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
                                      ? AppColors.primary
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

                      // Today's Summary header with date
                      _buildSectionHeader(
                        'Today\'s Summary',
                        icon: Iconsax.chart_1,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _buildStatsGrid(shopperProvider),
                      const SizedBox(height: AppSizes.lg),

                      // Performance Section
                      _buildSectionHeader(
                        'Your Performance',
                        icon: Iconsax.star_1,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _buildPerformanceCard(shopperProvider),
                      const SizedBox(height: AppSizes.lg),

                      // Quick Actions - now with different actions
                      _buildSectionHeader(
                        'Quick Actions',
                        icon: Iconsax.flash_1,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _buildQuickActions(context, shopperProvider),
                      const SizedBox(height: AppSizes.lg),
                    ]),
                  ),
                ),
              ],
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
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with initials
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
                      ? 'You\'re visible to customers'
                      : 'Go online to receive tasks',
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

  Widget _buildStatsGrid(ShopperProvider shopperProvider) {
    final availableCount = shopperProvider.availableTasks.length;
    final activeCount = shopperProvider.activeTasks.length;
    final completedCount = shopperProvider.completedTasks.isNotEmpty
        ? shopperProvider.completedTasks.length
        : shopperProvider.completedOrders;
    final earnings = shopperProvider.totalEarnings;

    // Show empty state CTA if all values are zero
    final allZero =
        availableCount == 0 && activeCount == 0 && completedCount == 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Iconsax.shopping_bag,
                title: 'Available',
                value: '$availableCount',
                color: AppColors.info,
                bgColor: AppColors.cardBlue,
                onTap: () => context.push('/shopper/available-tasks'),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildStatCard(
                icon: Iconsax.timer_1,
                title: 'Active',
                value: '$activeCount',
                color: AppColors.warning,
                bgColor: AppColors.cardOrange,
                onTap: () => context.push('/shopper/active-tasks'),
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
                onTap: () => context.push('/shopper/completed-tasks'),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildStatCard(
                icon: Iconsax.wallet_2,
                title: 'Earnings',
                value: _formatEarnings(earnings),
                color: AppColors.accent,
                bgColor: AppColors.cardYellow,
                onTap: () => context.push('/shopper/earnings'),
              ),
            ),
          ],
        ),
        // Empty state CTA
        if (allZero) ...[
          const SizedBox(height: AppSizes.md),
          GestureDetector(
            onTap: () => context.push('/shopper/available-tasks'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.primaryMuted),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(Iconsax.search_normal_1,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start earning today!',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Browse available tasks and pick your first order',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.primary),
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
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(ShopperProvider shopperProvider) {
    final rating = shopperProvider.averageRating;
    final reviews = shopperProvider.totalReviews;
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
                // Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
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
                // Reviews
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
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
                      Text(
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
          // Empty state for performance
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
                Text(
                  'Complete your first task to start building your reputation!',
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

  Widget _buildQuickActions(
    BuildContext context,
    ShopperProvider shopperProvider,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionTile(
                icon: Iconsax.search_normal_1,
                label: 'Browse Tasks',
                color: AppColors.info,
                bgColor: AppColors.cardBlue,
                onTap: () => context.push('/shopper/available-tasks'),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildQuickActionTile(
                icon: Iconsax.task_square,
                label: 'Active Orders',
                color: AppColors.warning,
                bgColor: AppColors.cardOrange,
                onTap: () => context.push('/shopper/active-tasks'),
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
                color: AppColors.accent,
                bgColor: AppColors.cardYellow,
                onTap: () => context.push('/shopper/earnings'),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: _buildQuickActionTile(
                icon: Iconsax.archive_tick,
                label: 'Completed',
                color: AppColors.success,
                bgColor: AppColors.cardGreen,
                onTap: () => context.push('/shopper/completed-tasks'),
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
                icon: Iconsax.shopping_bag,
                activeIcon: Iconsax.shopping_bag5,
                label: 'Tasks',
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
                color: isActive ? AppColors.primary : AppColors.grey500,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? AppColors.primary : AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (ctx) {
        final user = context.read<AuthProvider>().user;
        final kycStatus = user?.kycStatus ?? 'not_submitted';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Profile header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(user?.name),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDisplayName(user?.name),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Shopper',
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
                const SizedBox(height: AppSizes.md),

                // KYC Status Card
                _buildKycStatusCard(kycStatus, ctx),
                const SizedBox(height: AppSizes.sm),

                const Divider(height: 1, color: AppColors.grey200),
                const SizedBox(height: AppSizes.sm),
                _buildProfileMenuItem(
                  icon: Iconsax.shield_tick,
                  label: 'Verification',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (kycStatus == 'not_submitted' || kycStatus == 'rejected') {
                      context.push('/shopper/kyc');
                    } else if (kycStatus == 'pending_review') {
                      _showKycStatusDetail(kycStatus);
                    }
                  },
                  trailing: _buildKycBadge(kycStatus),
                ),
                _buildProfileMenuItem(
                  icon: Iconsax.logout,
                  label: 'Logout',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKycStatusCard(String kycStatus, BuildContext ctx) {
    final statusConfig = _getKycStatusConfig(kycStatus);

    return GestureDetector(
      onTap: () {
        Navigator.of(ctx).pop();
        if (kycStatus == 'not_submitted' || kycStatus == 'rejected') {
          context.push('/shopper/kyc');
        } else if (kycStatus == 'pending_review') {
          _showKycStatusDetail(kycStatus);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: statusConfig.bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: statusConfig.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusConfig.iconBgColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusXs),
              ),
              child: Icon(statusConfig.icon, color: statusConfig.color, size: 20),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusConfig.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusConfig.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusConfig.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (kycStatus != 'approved')
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: statusConfig.color),
          ],
        ),
      ),
    );
  }

  Widget _buildKycBadge(String kycStatus) {
    final config = _getKycStatusConfig(kycStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: config.borderColor),
      ),
      child: Text(
        config.badgeText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config.color,
        ),
      ),
    );
  }

  _KycStatusConfig _getKycStatusConfig(String status) {
    switch (status) {
      case 'approved':
        return _KycStatusConfig(
          icon: Iconsax.shield_tick,
          title: 'Identity Verified',
          subtitle: 'Your account is fully verified',
          badgeText: 'Verified',
          color: AppColors.success,
          bgColor: AppColors.primarySoft,
          borderColor: AppColors.primaryMuted,
          iconBgColor: AppColors.primary.withValues(alpha: 0.1),
        );
      case 'pending_review':
        return _KycStatusConfig(
          icon: Iconsax.clock,
          title: 'Verification In Progress',
          subtitle: 'Review typically takes 24-48 hours',
          badgeText: 'Pending',
          color: AppColors.warning,
          bgColor: AppColors.accentSoft,
          borderColor: AppColors.accentMuted,
          iconBgColor: AppColors.accent.withValues(alpha: 0.1),
        );
      case 'rejected':
        return _KycStatusConfig(
          icon: Iconsax.close_circle,
          title: 'Verification Failed',
          subtitle: 'Tap to resubmit your documents',
          badgeText: 'Rejected',
          color: AppColors.error,
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          iconBgColor: AppColors.error.withValues(alpha: 0.1),
        );
      default:
        return _KycStatusConfig(
          icon: Iconsax.shield_cross,
          title: 'Not Yet Verified',
          subtitle: 'Tap to submit your identity documents',
          badgeText: 'Required',
          color: AppColors.textSecondary,
          bgColor: AppColors.grey100,
          borderColor: AppColors.grey200,
          iconBgColor: AppColors.grey200,
        );
    }
  }

  void _showKycStatusDetail(String kycStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Animated hourglass icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.clock,
                    size: 36,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                const Text(
                  'Application Under Review',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Your KYC documents have been submitted successfully. '
                  'Our team is currently reviewing them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Timeline steps
                _buildTimelineStep(
                  title: 'Documents Submitted',
                  subtitle: 'Your ID and selfie were received',
                  isCompleted: true,
                ),
                _buildTimelineStep(
                  title: 'Under Review',
                  subtitle: 'Our team is verifying your identity',
                  isActive: true,
                ),
                _buildTimelineStep(
                  title: 'Verification Complete',
                  subtitle: 'You\'ll be notified of the result',
                  isCompleted: false,
                ),
                const SizedBox(height: AppSizes.lg),

                // Info box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(color: AppColors.primaryMuted),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.info_circle,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          'Review typically takes 24-48 hours',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Check status button
                ShopperButton.primary(
                  text: 'Check Status',
                  icon: Icons.refresh_rounded,
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final authProvider = context.read<AuthProvider>();
                    await authProvider.refreshProfile();
                    if (!mounted) return;
                    final newStatus = authProvider.user?.kycStatus;
                    if (newStatus == 'approved') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Your account has been verified!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.go('/shopper/home');
                    } else if (newStatus == 'rejected') {
                      context.push('/shopper/kyc?rejected=true');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Still under review. Please check back later.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isActive = false,
  }) {
    final color = isCompleted
        ? AppColors.success
        : isActive
            ? AppColors.warning
            : AppColors.grey300;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted || isActive
                      ? color.withValues(alpha: 0.15)
                      : AppColors.grey100,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: isCompleted
                    ? Icon(Icons.check, size: 14, color: color)
                    : isActive
                        ? Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
              ),
            ],
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted || isActive
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.textSecondary, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await LogoutHelper.logoutAndClear(context);
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              GoRouter.of(context).go('/login');
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _KycStatusConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final Color iconBgColor;

  const _KycStatusConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.iconBgColor,
  });
}
