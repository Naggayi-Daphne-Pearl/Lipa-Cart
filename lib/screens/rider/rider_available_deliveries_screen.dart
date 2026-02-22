import 'package:flutter/material.dart';

class RiderAvailableDeliveriesScreen extends StatefulWidget {
  const RiderAvailableDeliveriesScreen({super.key});

  @override
  State<RiderAvailableDeliveriesScreen> createState() =>
      _RiderAvailableDeliveriesScreenState();
}

class _RiderAvailableDeliveriesScreenState
    extends State<RiderAvailableDeliveriesScreen> {
  final List<Map<String, dynamic>> deliveries = [
    {
      'id': 'DEL001',
      'customer': 'John Doe',
      'distance': '2.5 km',
      'reward': 'KES 200',
      'items': 5,
      'pickupLocation': 'Downtown Nairobi',
      'deliveryLocation': 'Upper Hill',
    },
    {
      'id': 'DEL002',
      'customer': 'Jane Smith',
      'distance': '4.0 km',
      'reward': 'KES 350',
      'items': 3,
      'pickupLocation': 'Westlands',
      'deliveryLocation': 'Kilimani',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Deliveries')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(delivery['id']),
              subtitle: Text(delivery['customer']),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: 'Distance', value: delivery['distance']),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Items',
                        value: '${delivery['items']} items',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Pickup',
                        value: delivery['pickupLocation'],
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Delivery',
                        value: delivery['deliveryLocation'],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Delivery accepted!'),
                                  ),
                                );
                              },
                              child: const Text('Accept'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('Decline'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
