import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class ShopperActiveTasksScreen extends StatefulWidget {
  const ShopperActiveTasksScreen({super.key});

  @override
  State<ShopperActiveTasksScreen> createState() =>
      _ShopperActiveTasksScreenState();
}

class _ShopperActiveTasksScreenState extends State<ShopperActiveTasksScreen> {
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

  final List<Map<String, dynamic>> tasks = [
    {
      'id': 'TASK101',
      'customer': 'Alice Kipchoge',
      'items': 'Electronics from Jamburi',
      'checkedItems': 8,
      'totalItems': 12,
      'status': 'shopping',
      'startTime': '2:30 PM',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'shopping':
        return Colors.blue;
      case 'delivering':
        return Colors.orange;
      case 'complete':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'shopping':
        return 'Shopping';
      case 'delivering':
        return 'Delivering';
      case 'complete':
        return 'Complete';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Tasks')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final progress = task['checkedItems'] / task['totalItems'];

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['id'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            task['customer'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            task['status'],
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(task['status']),
                          style: TextStyle(
                            color: _getStatusColor(task['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task['items'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items: ${task['checkedItems']}/${task['totalItems']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Continue Shopping'),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Complete'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task marked as complete!'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
