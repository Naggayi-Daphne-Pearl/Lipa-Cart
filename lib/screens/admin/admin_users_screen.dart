import 'package:flutter/material.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final List<Map<String, dynamic>> users = [
    // Mock data - will be replaced with API calls
    {
      'id': '1',
      'name': 'John Doe',
      'email': 'john@example.com',
      'role': 'customer',
      'joinDate': '2024-01-15',
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'role': 'rider',
      'joinDate': '2024-02-10',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(child: Text(user['name'].toString()[0])),
              title: Text(user['name']),
              subtitle: Text('${user['email']} • ${user['role']}'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('View Details'),
                    onTap: () {
                      // Navigate to user details
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Edit'),
                    onTap: () {
                      // Navigate to edit user
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Delete'),
                    onTap: () {
                      // Show delete confirmation
                    },
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
