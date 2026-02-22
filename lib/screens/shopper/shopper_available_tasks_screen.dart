import 'package:flutter/material.dart';

class ShopperAvailableTasksScreen extends StatefulWidget {
  const ShopperAvailableTasksScreen({super.key});

  @override
  State<ShopperAvailableTasksScreen> createState() =>
      _ShopperAvailableTasksScreenState();
}

class _ShopperAvailableTasksScreenState
    extends State<ShopperAvailableTasksScreen> {
  final List<Map<String, dynamic>> tasks = [
    {
      'id': 'TASK001',
      'customer': 'Sarah Mwangi',
      'items': 'Groceries from Nakumatt',
      'itemCount': 12,
      'budget': 'KES 5000',
      'reward': 'KES 500',
      'deadline': '2 hours',
      'location': 'Westlands',
    },
    {
      'id': 'TASK002',
      'customer': 'Mike Johnson',
      'items': 'Pharmacy items',
      'itemCount': 5,
      'budget': 'KES 2000',
      'reward': 'KES 300',
      'deadline': '1 hour',
      'location': 'Upper Hill',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Tasks')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        task['id'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Available',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For: ${task['customer']}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.shopping_bag,
                    label: task['items'],
                    value: '${task['itemCount']} items',
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.money,
                    label: 'Budget',
                    value: task['budget'],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.attach_money,
                    label: 'Your Reward',
                    value: task['reward'],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Deadline',
                    value: task['deadline'],
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: task['location'],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task accepted!')),
                        );
                      },
                      child: const Text('Accept Task'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
