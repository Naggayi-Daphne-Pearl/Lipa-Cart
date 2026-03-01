import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../core/utils/logout_helper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _validateRole();
  }

  void _validateRole() {
    final authProvider = context.read<AuthProvider>();

    // Validate user role - only admins can access this screen
    if (authProvider.user?.role != UserRole.admin) {
      Future.microtask(() {
        GoRouter.of(context).go(
          authProvider.user?.role == UserRole.shopper
              ? '/shopper/home'
              : authProvider.user?.role == UserRole.rider
              ? '/rider/home'
              : '/customer/home',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.name ?? 'Admin'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.email ?? 'admin@lipacart.com',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Stats
                Text(
                  'Quick Stats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _StatCard(
                      title: 'Total Users',
                      value: '0',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Total Orders',
                      value: '0',
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'Total Products',
                      value: '0',
                      icon: Icons.inventory,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'Revenue',
                      value: 'KES 0',
                      icon: Icons.attach_money,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Admin Actions
                Text(
                  'Admin Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: const Text('Manage Products'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/admin/products'),
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Manage Users'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/admin/users'),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('View Orders'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/admin/orders'),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Analytics'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/admin/analytics'),
                ),
              ],
            ),
          );
        },
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
