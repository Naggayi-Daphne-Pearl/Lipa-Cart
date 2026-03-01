import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../models/user.dart';
import '../../core/utils/logout_helper.dart';

class ShopperHomeScreen extends StatefulWidget {
  const ShopperHomeScreen({super.key});

  @override
  State<ShopperHomeScreen> createState() => _ShopperHomeScreenState();
}

class _ShopperHomeScreenState extends State<ShopperHomeScreen> {
  @override
  void initState() {
    super.initState();
    _validateRoleAndLoad();
  }

  void _validateRoleAndLoad() {
    final authProvider = context.read<AuthProvider>();

    // Validate user role - only shoppers can access this screen
    if (authProvider.user?.role != UserRole.shopper) {
      // Redirect to appropriate home based on role
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

    if (authProvider.token != null && authProvider.user?.id != null) {
      shopperProvider.loadShopperProfile(
        authProvider.token!,
        authProvider.user!.id,
      );
      shopperProvider.fetchAvailableTasks(authProvider.token!);
      shopperProvider.fetchActiveTasks(
        authProvider.token!,
        authProvider.user!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopper Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ShopperProvider>(
        builder: (context, authProvider, shopperProvider, _) {
          final user = authProvider.user;
          final isOnline = shopperProvider.isOnline;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header with Online Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.name ?? 'Shopper'}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find and complete shopping tasks',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // Online Status Toggle
                      GestureDetector(
                        onTap: () {
                          if (authProvider.token != null && user?.id != null) {
                            shopperProvider.toggleOnlineStatus(
                              authProvider.token!,
                              user!.id,
                              !isOnline,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOnline
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Stats
                Text(
                  'Today\'s Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildStatsGrid(shopperProvider),
                const SizedBox(height: 24),

                // Rating & Reviews
                Text(
                  'Your Performance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildRatingCard(shopperProvider),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildActionButtons(context, shopperProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(ShopperProvider shopperProvider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.shopping_bag_outlined,
          title: 'Available Tasks',
          value: '${shopperProvider.availableTasks.length}',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.hourglass_empty,
          title: 'Active Tasks',
          value: '${shopperProvider.activeTasks.length}',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.check_circle_outline,
          title: 'Completed',
          value: '${shopperProvider.completedOrders}',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.wallet_outlined,
          title: 'Earnings',
          value:
              'UGX ${(shopperProvider.totalEarnings / 1000).toStringAsFixed(1)}K',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(ShopperProvider shopperProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Rating',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      shopperProvider.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    ...List.generate(5, (i) {
                      return Icon(
                        i < shopperProvider.averageRating.toInt()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: Colors.amber,
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          // Reviews count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reviews',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${shopperProvider.totalReviews} customer ratings',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ShopperProvider shopperProvider,
  ) {
    return Column(
      children: [
        _buildActionButton(
          context,
          icon: Icons.search,
          title: 'Available Tasks',
          subtitle: '${shopperProvider.availableTasks.length} waiting',
          color: Colors.blue,
          onTap: () => context.push('/shopper/available-tasks'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          icon: Icons.timer,
          title: 'Active Tasks',
          subtitle: '${shopperProvider.activeTasks.length} in progress',
          color: Colors.orange,
          onTap: () => context.push('/shopper/active-tasks'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          icon: Icons.check,
          title: 'Completed Tasks',
          subtitle: '${shopperProvider.completedOrders} completed',
          color: Colors.green,
          onTap: () => context.push('/shopper/completed-tasks'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          icon: Icons.wallet,
          title: 'Earnings',
          subtitle: 'View commission history',
          color: Colors.purple,
          onTap: () => context.push('/shopper/earnings'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await LogoutHelper.logoutAndClear(context);
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              GoRouter.of(context).go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
