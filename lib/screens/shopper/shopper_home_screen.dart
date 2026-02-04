import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ShopperHomeScreen extends StatefulWidget {
  const ShopperHomeScreen({Key? key}) : super(key: key);

  @override
  State<ShopperHomeScreen> createState() => _ShopperHomeScreenState();
}

class _ShopperHomeScreenState extends State<ShopperHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopper Dashboard'), elevation: 0),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shopper Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.name ?? 'Shopper'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find shopping tasks and earn',
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _StatCard(
                      title: 'Completed',
                      value: '0',
                      color: Colors.green,
                    ),
                    _StatCard(title: 'Active', value: '0', color: Colors.blue),
                    _StatCard(
                      title: 'Earnings',
                      value: 'KES 0',
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Shopping Tasks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text('Available Tasks'),
                  subtitle: const Text('Browse shopping jobs'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/shopper/available-tasks'),
                ),
                ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: const Text('Active Tasks'),
                  subtitle: const Text('Tasks in progress'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/shopper/active-tasks'),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Completed Tasks'),
                  subtitle: const Text('Your history'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/shopper/completed-tasks'),
                ),
                ListTile(
                  leading: const Icon(Icons.money),
                  title: const Text('Earnings'),
                  subtitle: const Text('View your income'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/shopper/earnings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
