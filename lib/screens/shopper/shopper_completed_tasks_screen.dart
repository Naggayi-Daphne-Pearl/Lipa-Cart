import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class ShopperCompletedTasksScreen extends StatefulWidget {
  const ShopperCompletedTasksScreen({super.key});

  @override
  State<ShopperCompletedTasksScreen> createState() =>
      _ShopperCompletedTasksScreenState();
}

class _ShopperCompletedTasksScreenState
    extends State<ShopperCompletedTasksScreen> {
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

  final List<Map<String, dynamic>> completedTasks = [
    // Mock data - will be replaced with API calls
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completed Tasks')),
      body: completedTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No completed tasks yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/shopper/available-tasks'),
                    child: const Text('Browse Available Tasks'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: completedTasks.length,
              itemBuilder: (context, index) {
                final task = completedTasks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(task['id']),
                    subtitle: Text(task['customer']),
                    trailing: Text(
                      task['reward'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
