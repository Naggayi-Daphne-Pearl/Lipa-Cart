import 'package:flutter/material.dart';

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({Key? key}) : super(key: key);

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
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
                  colors: [Colors.green.shade700, Colors.green.shade500],
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
              label: 'Completed Deliveries',
              amount: 'KES 0',
              count: '0 deliveries',
            ),
            const SizedBox(height: 8),
            _EarningsCard(label: 'Bonus', amount: 'KES 0', count: ''),
            const SizedBox(height: 24),

            // Recent Earnings
            Text(
              'Recent Earnings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No earnings yet',
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
