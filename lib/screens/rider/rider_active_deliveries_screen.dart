import 'package:flutter/material.dart';

class RiderActiveDeliveriesScreen extends StatefulWidget {
  const RiderActiveDeliveriesScreen({Key? key}) : super(key: key);

  @override
  State<RiderActiveDeliveriesScreen> createState() =>
      _RiderActiveDeliveriesScreenState();
}

class _RiderActiveDeliveriesScreenState
    extends State<RiderActiveDeliveriesScreen> {
  final List<Map<String, dynamic>> deliveries = [
    {
      'id': 'DEL101',
      'customer': 'Alice Johnson',
      'status': 'in_transit',
      'progress': 0.65,
      'items': 4,
      'pickupLocation': 'Parklands',
      'deliveryLocation': 'Runda',
    },
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;
      case 'arrived':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_transit':
        return 'In Transit';
      case 'arrived':
        return 'Arrived';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Deliveries')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
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
                            delivery['id'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            delivery['customer'],
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
                            delivery['status'],
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(delivery['status']),
                          style: TextStyle(
                            color: _getStatusColor(delivery['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: delivery['progress'],
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Items', value: '${delivery['items']} items'),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Pickup', value: delivery['pickupLocation']),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: 'Delivery',
                    value: delivery['deliveryLocation'],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.navigation),
                          label: const Text('Navigate'),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Delivered'),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Delivery marked as complete!'),
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
