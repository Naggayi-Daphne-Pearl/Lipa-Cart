import 'package:flutter/material.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({Key? key}) : super(key: key);

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final List<Map<String, dynamic>> products = [
    // Mock data - will be replaced with API calls
    {
      'id': '1',
      'name': 'Sample Product 1',
      'price': 5000,
      'stock': 50,
      'category': 'Electronics',
    },
    {
      'id': '2',
      'name': 'Sample Product 2',
      'price': 3000,
      'stock': 30,
      'category': 'Groceries',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Products')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(product['name']),
              subtitle: Text(
                '${product['category']} • Stock: ${product['stock']}',
              ),
              trailing: Text('KES ${product['price']}'),
              onTap: () {
                // Navigate to edit product
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create product
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
