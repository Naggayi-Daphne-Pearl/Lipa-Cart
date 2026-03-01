import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class ShopperEarningsScreen extends StatefulWidget {
  const ShopperEarningsScreen({super.key});

  @override
  State<ShopperEarningsScreen> createState() => _ShopperEarningsScreenState();
}

class _ShopperEarningsScreenState extends State<ShopperEarningsScreen> {
  @override
  void initState() {
    super.initState();
    _validateRole();
  }

  void _validateRole() {
    final authProvider = context.read<AuthProvider>();

    // Validate user role - only shoppers can access this screen
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade700, Colors.purple.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Earnings',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'KES 0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'This Week',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'KES 0',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'This Month',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'KES 0',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Earnings Breakdown
            Text(
              'Earnings Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _EarningsCard(
              label: 'Completed Tasks',
              amount: 'KES 0',
              count: '0 tasks',
            ),
            const SizedBox(height: 8),
            _EarningsCard(label: 'Bonus', amount: 'KES 0', count: ''),
            const SizedBox(height: 24),

            // Recent Earnings
            Text('Recent Tasks', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No completed tasks yet',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String label;
  final String amount;
  final String count;

  const _EarningsCard({
    required this.label,
    required this.amount,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                if (count.isNotEmpty)
                  Text(
                    count,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            Text(
              amount,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
