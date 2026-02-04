import 'package:flutter/material.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final List<Map<String, dynamic>> orders = [
    // Mock data - will be replaced with API calls
    {
      'id': 'ORD001',
      'customer': 'John Doe',
      'amount': 15000,
      'status': 'delivered',
      'date': '2024-02-01',
    },
    {
      'id': 'ORD002',
      'customer': 'Jane Smith',
      'amount': 8500,
      'status': 'pending',
      'date': '2024-02-03',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Orders')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(order['id']),
              subtitle: Text(order['customer']),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'KES ${order['amount']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order['status'].toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(order['status']),
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                // Navigate to order details
              },
            ),
          );
        },
      ),
    );
  }
}
