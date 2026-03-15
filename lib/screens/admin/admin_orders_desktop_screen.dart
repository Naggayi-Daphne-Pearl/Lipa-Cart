import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/app_loading_indicator.dart';

class AdminOrdersDesktopScreen extends StatefulWidget {
  const AdminOrdersDesktopScreen({super.key});

  @override
  State<AdminOrdersDesktopScreen> createState() =>
      _AdminOrdersDesktopScreenState();
}

class _AdminOrdersDesktopScreenState extends State<AdminOrdersDesktopScreen> {
  Order? _selectedOrder;
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus;
  final _searchController = TextEditingController();

  final List<String> _statuses = [
    'All',
    'pending',
    'confirmed',
    'shopping',
    'readyForDelivery',
    'inTransit',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Missing auth token');
      }

      // Get ALL orders from OrderService (admin view, not customer-filtered)
      final orderService = context.read<OrderService>();
      await orderService.fetchAllOrders(token);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Order> _getFilteredOrders() {
    final orderService = context.read<OrderService>();
    var filtered = orderService.orders;

    // Filter by status
    if (_selectedStatus != null && _selectedStatus != 'All') {
      filtered = filtered.where((order) {
        return order.status.toString().split('.').last == _selectedStatus;
      }).toList();
    }

    // Filter by search (order number or customer name)
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((order) {
        final searchLower = _searchController.text.toLowerCase();
        return (order.orderNumber?.toLowerCase().contains(searchLower) ?? false) ||
            (order.customer?.name?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    return filtered;
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shopperAssigned:
        return Colors.teal;
      case OrderStatus.shopping:
        return Colors.cyan;
      case OrderStatus.readyForDelivery:
        return Colors.purple;
      case OrderStatus.riderAssigned:
        return Colors.deepPurple;
      case OrderStatus.inTransit:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatStatus(OrderStatus status) {
    return status.toString().split('.').last.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        ).trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        elevation: 0,
      ),
      body: Consumer<OrderService>(
        builder: (context, orderService, _) {
          final filteredOrders = _getFilteredOrders();

          return Row(
            children: [
              // Left: Orders List
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Filters
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        spacing: 12,
                        children: [
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search order #, customer...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          DropdownButtonFormField<String?>(
                            initialValue: _selectedStatus ?? 'All',
                            decoration: InputDecoration(
                              labelText: 'Filter by Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: _statuses.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(
                                  () => _selectedStatus = value ?? 'All');
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: _loadOrders,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                    // Orders list
                    Expanded(
                      child: _isLoading
                          ? const AppLoadingPage()
                          : _error != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text('Error: $_error'),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _loadOrders,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : filteredOrders.isEmpty
                                  ? const Center(
                                      child: Text('No orders found'))
                                  : ListView.builder(
                                      itemCount: filteredOrders.length,
                                      itemBuilder: (context, index) {
                                        final order = filteredOrders[index];
                                        final isSelected =
                                            _selectedOrder?.id == order.id;

                                        return Card(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          elevation: isSelected ? 4 : 1,
                                          color: isSelected
                                              ? AppColors.primary
                                                  .withValues(alpha: 0.1)
                                              : null,
                                          child: ListTile(
                                            onTap: () {
                                              setState(() =>
                                                  _selectedOrder = order);
                                            },
                                            title: Text(
                                              order.orderNumber ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${order.customer?.name ?? "Unknown"} • ${CurrencyFormatter.format(order.total ?? 0)}',
                                            ),
                                            trailing: Chip(
                                              label: Text(
                                                _formatStatus(order.status),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor:
                                                  _getStatusColor(
                                                      order.status),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                    ),
                  ],
                ),
              ),
              // Right: Order Details
              Expanded(
                flex: 1,
                child: _selectedOrder == null
                    ? const Center(
                        child: Text('Select an order to view details'))
                    : _OrderDetailsView(order: _selectedOrder!),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _OrderDetailsView extends StatelessWidget {
  final Order order;

  const _OrderDetailsView({required this.order});

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shopperAssigned:
        return Colors.teal;
      case OrderStatus.shopping:
        return Colors.cyan;
      case OrderStatus.readyForDelivery:
        return Colors.purple;
      case OrderStatus.riderAssigned:
        return Colors.deepPurple;
      case OrderStatus.inTransit:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatStatus(OrderStatus status) {
    return status.toString().split('.').last.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        ).trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Created: ${order.createdAt?.toString().split(' ')[0] ?? "N/A"}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatStatus(order.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Customer Info
            _buildSection(
              'Customer Information',
              [
                _buildInfoRow('Name', order.customer?.name ?? 'N/A'),
                _buildInfoRow('Phone', order.customer?.phoneNumber ?? 'N/A'),
                _buildInfoRow('Email', order.customer?.email ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 24),

            // Delivery Address
            _buildSection(
              'Delivery Address',
              [
                _buildInfoRow(
                  'Address',
                  order.deliveryAddress.fullAddress,
                ),
                if (order.deliveryAddress.landmark != null)
                  _buildInfoRow(
                    'Landmark',
                    order.deliveryAddress.landmark!,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Order Items
            _buildSection(
              'Items (${order.items.length})',
              [
                if (order.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No items'),
                  )
                else
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Qty: ${item.quantity.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Order Summary
            _buildSection(
              'Order Summary',
              [
                _buildInfoRow(
                  'Subtotal',
                  CurrencyFormatter.format(order.subtotal ?? 0),
                ),
                _buildInfoRow(
                  'Service Fee',
                  CurrencyFormatter.format(order.serviceFee ?? 0),
                ),
                _buildInfoRow(
                  'Delivery Fee',
                  CurrencyFormatter.format(order.deliveryFee ?? 0),
                ),
                _buildInfoRow(
                  'Discount',
                  CurrencyFormatter.format(order.discount ?? 0),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(order.total ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
