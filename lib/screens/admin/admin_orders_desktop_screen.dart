import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/rider_service.dart';
import '../../services/shopper_service.dart';
import '../../models/order.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_order_status_colors.dart';
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

  // Derived from the enum so it stays in sync when new statuses are added.
  // Keep 'All' first. Filter comparison uses the raw enum name.
  static final List<String> _statuses = [
    'All',
    ...OrderStatus.values.map((s) => s.name),
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
    return AppOrderStatusColors.foreground(status);
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
                              final label = status == 'All'
                                  ? 'All'
                                  : OrderStatus.values
                                      .firstWhere((s) => s.name == status)
                                      .displayName;
                              return DropdownMenuItem(
                                value: status,
                                child: Text(label),
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
                                                  color: AppColors.textWhite,
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
                    : _OrderDetailsView(order: _selectedOrder!, onOrderUpdated: _loadOrders),
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
  final VoidCallback? onOrderUpdated;

  const _OrderDetailsView({required this.order, this.onOrderUpdated});

  Color _getStatusColor(OrderStatus status) {
    return AppOrderStatusColors.foreground(status);
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
      color: AppColors.background,
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
                      'Created: ${order.createdAt.toString().split(' ')[0]}',
                      style: TextStyle(color: AppColors.textSecondary),
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
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Admin action buttons
            _buildAdminActions(context),
            const SizedBox(height: 24),

            // Order Timeline
            _buildTimeline(),
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

            // Order Items with substitution details
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Qty: ${item.quantity.toStringAsFixed(0)} • ${item.found == true ? "Found" : item.found == false ? "Not found" : "Pending"}',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(item.actualPrice ?? item.totalPrice),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          // Substitution details
                          if (item.isSubstituted == true || item.substituteName != null)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.swap_horiz, size: 14, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text('Substitute: ${item.substituteName ?? "N/A"}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  if (item.substitutePrice != null)
                                    Text('Price: ${CurrencyFormatter.format(item.substitutePrice!)}',
                                      style: TextStyle(fontSize: 11, color: AppColors.grey700)),
                                  Text(
                                    'Status: ${item.substitutionApproved == true ? "Approved" : item.substitutionApproved == false ? "Rejected" : "Pending"}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: item.substitutionApproved == true
                                          ? AppColors.success
                                          : item.substitutionApproved == false
                                          ? AppColors.error
                                          : AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
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
                  CurrencyFormatter.format(order.subtotal),
                ),
                _buildInfoRow(
                  'Service Fee',
                  CurrencyFormatter.format(order.serviceFee),
                ),
                _buildInfoRow(
                  'Delivery Fee',
                  CurrencyFormatter.format(order.deliveryFee),
                ),
                _buildInfoRow(
                  'Discount',
                  CurrencyFormatter.format(order.discount),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.grey300),
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
                        CurrencyFormatter.format(order.total),
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

  Widget _buildAdminActions(BuildContext context) {
    final orderId = order.documentId ?? order.id;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (order.status == OrderStatus.pending)
          _buildActionButton(context, 'Confirm Payment', AppColors.primary, () async {
            final auth = context.read<AuthProvider>();
            final svc = context.read<OrderService>();
            final success = await svc.adminConfirmPayment(auth.token!, orderId);
            if (success) onOrderUpdated?.call();
          }),
        if (order.status == OrderStatus.confirmed)
          _buildActionButton(context, 'Assign Shopper', AppColors.primary, () async {
            await _openAssignDialog(
              context,
              role: _DispatchRole.shopper,
              orderId: orderId,
              onAssigned: () => onOrderUpdated?.call(),
            );
          }),
        if (order.status == OrderStatus.shopperAssigned || order.status == OrderStatus.shopping)
          _buildActionButton(context, 'Reassign Shopper', AppColors.accent, () async {
            final auth = context.read<AuthProvider>();
            final svc = context.read<OrderService>();
            final success = await svc.adminReassignShopper(auth.token!, orderId);
            if (success) onOrderUpdated?.call();
          }),
        if (order.status == OrderStatus.readyForDelivery)
          _buildActionButton(context, 'Assign Rider', AppColors.primary, () async {
            await _openAssignDialog(
              context,
              role: _DispatchRole.rider,
              orderId: orderId,
              onAssigned: () => onOrderUpdated?.call(),
            );
          }),
        if (order.status == OrderStatus.riderAssigned || order.status == OrderStatus.inTransit)
          _buildActionButton(context, 'Reassign Rider', AppColors.accent, () async {
            final auth = context.read<AuthProvider>();
            final svc = context.read<OrderService>();
            final success = await svc.adminReassignRider(auth.token!, orderId);
            if (success) onOrderUpdated?.call();
          }),
        if (order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled &&
            order.status != OrderStatus.refunded)
          _buildActionButton(context, 'Cancel Order', AppColors.error, () async {
            final reason = await showDialog<String>(
              context: context,
              builder: (ctx) {
                final controller = TextEditingController();
                return AlertDialog(
                  title: const Text('Cancel Order'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Reason for cancellation'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.textWhite),
                      child: const Text('Cancel Order'),
                    ),
                  ],
                );
              },
            );
            if (reason == null) return;
            final auth = context.read<AuthProvider>();
            final svc = context.read<OrderService>();
            final success = await svc.adminCancelOrder(auth.token!, orderId, reason.isEmpty ? 'Cancelled by admin' : reason);
            if (success) onOrderUpdated?.call();
          }),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.textWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Future<void> _openAssignDialog(
    BuildContext context, {
    required _DispatchRole role,
    required String orderId,
    required VoidCallback onAssigned,
  }) async {
    final assigned = await showDialog<bool>(
      context: context,
      builder: (_) => _AssignDispatchDialog(role: role, orderId: orderId),
    );
    if (assigned == true) onAssigned();
  }

  Widget _buildTimeline() {
    final events = <MapEntry<String, DateTime?>>[];
    events.add(MapEntry('Order Created', order.createdAt));
    events.add(MapEntry('Payment Confirmed', order.paymentConfirmedAt));
    events.add(MapEntry('Shopper Assigned', order.shopperAssignedAt));
    events.add(MapEntry('Shopping Started', order.shoppingStartedAt));
    events.add(MapEntry('Shopping Completed', order.shoppingCompletedAt));
    events.add(MapEntry('Rider Assigned', order.riderAssignedAt));
    events.add(MapEntry('Picked Up', order.pickedUpAt));
    events.add(MapEntry('Delivered', order.deliveredAt));
    if (order.cancelledAt != null) events.add(MapEntry('Cancelled', order.cancelledAt));

    return _buildSection(
      'Timeline',
      events.map((e) {
        final happened = e.value != null;
        final timeStr = e.value != null
            ? '${e.value!.toString().split('.')[0]}'
            : '—';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: happened ? AppColors.primary : AppColors.grey300,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: happened ? FontWeight.w600 : FontWeight.normal,
                    color: happened ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11,
                  color: happened ? AppColors.textSecondary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
            border: Border.all(color: AppColors.grey300),
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
            style: TextStyle(color: AppColors.textSecondary),
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

enum _DispatchRole { shopper, rider }

class _AssignDispatchDialog extends StatefulWidget {
  final _DispatchRole role;
  final String orderId;

  const _AssignDispatchDialog({required this.role, required this.orderId});

  @override
  State<_AssignDispatchDialog> createState() => _AssignDispatchDialogState();
}

class _AssignDispatchDialogState extends State<_AssignDispatchDialog> {
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Map<String, dynamic>> _candidates = [];
  String? _selectedDocumentId;

  bool get _isShopper => widget.role == _DispatchRole.shopper;
  String get _label => _isShopper ? 'Shopper' : 'Rider';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }

    try {
      final results = _isShopper
          ? await ShopperService.getShoppers(
              token: token,
              kycStatus: 'approved',
              isActive: true,
              pageSize: 100,
            )
          : await RiderService.getRiders(
              token: token,
              isVerified: true,
              isActive: true,
              pageSize: 100,
            );
      if (!mounted) return;
      // Drop candidates without a valid documentId — duplicate empty values
      // crash the DropdownButton's "exactly one item" assertion.
      final filtered = results
          .where((c) => _profileDocumentId(c).isNotEmpty)
          .toList();
      setState(() {
        _candidates = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _profileDocumentId(Map<String, dynamic> entry) {
    final nested = entry[_isShopper ? 'shopper' : 'rider'];
    if (nested is Map<String, dynamic>) {
      final id = nested['documentId'] ?? nested['document_id'];
      if (id != null) return id.toString();
    }
    final id = entry['documentId'] ?? entry['document_id'];
    return id?.toString() ?? '';
  }

  Future<void> _submit() async {
    final docId = _selectedDocumentId;
    if (docId == null || docId.isEmpty) {
      setState(() => _error = 'Pick a $_label first.');
      return;
    }
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() => _error = 'Not signed in');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final svc = context.read<OrderService>();
    final ok = _isShopper
        ? await svc.adminAssignShopper(token, widget.orderId, docId)
        : await svc.adminAssignRider(token, widget.orderId, docId);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _error = svc.error ?? 'Failed to assign $_label';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Assign $_label'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : _candidates.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No approved ${_label.toLowerCase()}s available.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDocumentId,
                        decoration: InputDecoration(
                          labelText: _label,
                          border: const OutlineInputBorder(),
                        ),
                        items: _candidates.map((c) {
                          final docId = _profileDocumentId(c);
                          final name = (c['name'] ?? 'Unknown').toString();
                          final phone = (c['phone'] ?? '').toString();
                          return DropdownMenuItem<String>(
                            value: docId,
                            child: Text(
                              phone.isEmpty ? name : '$name • $phone',
                            ),
                          );
                        }).toList(),
                        onChanged: _submitting
                            ? null
                            : (v) => setState(() => _selectedDocumentId = v),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting || _loading || _candidates.isEmpty ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textWhite,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textWhite,
                  ),
                )
              : Text('Assign $_label'),
        ),
      ],
    );
  }
}
