import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({Key? key}) : super(key: key);

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rider Dashboard'), elevation: 0),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rider Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user?.name ?? 'Rider'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You are online',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Delivery Stats
                Text(
                  'Today\'s Stats',
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
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.local_shipping),
                  title: const Text('Available Deliveries'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/rider/available-deliveries'),
                ),
                ListTile(
                  leading: const Icon(Icons.local_activity),
                  title: const Text('Active Deliveries'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/rider/active-deliveries'),
                ),
                ListTile(
                  leading: const Icon(Icons.money),
                  title: const Text('Earnings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/rider/earnings'),
                ),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Ratings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go('/rider/ratings'),
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
