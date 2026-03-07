import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_loading_indicator.dart';

/// Item state tracked locally during the shopping session
class _ChecklistItem {
  final CartItem cartItem;
  bool found;
  double? actualPrice;
  final TextEditingController priceController;

  _ChecklistItem({
    required this.cartItem,
    this.actualPrice,
  })  : found = false,
        priceController = TextEditingController(
          text: actualPrice?.toStringAsFixed(0) ?? '',
        );

  void dispose() => priceController.dispose();
}

class ShoppingChecklistScreen extends StatefulWidget {
  final Order order;
  const ShoppingChecklistScreen({super.key, required this.order});

  @override
  State<ShoppingChecklistScreen> createState() =>
      _ShoppingChecklistScreenState();
}

class _ShoppingChecklistScreenState extends State<ShoppingChecklistScreen> {
  late List<_ChecklistItem> _items;
  bool _isSaving = false;
  bool _hasStartedShopping = false;

  @override
  void initState() {
    super.initState();
    _items = widget.order.items.map((item) => _ChecklistItem(
      cartItem: item,
      actualPrice: item.product.price,
    )).toList();

    // Check if order is already in shopping status
    _hasStartedShopping = widget.order.status == OrderStatus.shopping;
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int get _foundCount => _items.where((i) => i.found).length;
  int get _totalCount => _items.length;
  double get _progress => _totalCount > 0 ? _foundCount / _totalCount : 0;

  double get _actualTotal {
    double total = 0;
    for (final item in _items) {
      if (item.found) {
        final price = item.actualPrice ?? item.cartItem.product.price;
        total += price * item.cartItem.quantity;
      }
    }
    return total;
  }

  Future<void> _startShopping() async {
    final auth = context.read<AuthProvider>();
    final shopper = context.read<ShopperProvider>();
    final orderId = widget.order.documentId ?? widget.order.id;

    setState(() => _isSaving = true);
    final success = await shopper.startShopping(auth.token!, orderId);
    setState(() {
      _isSaving = false;
      if (success) _hasStartedShopping = true;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shopper.error ?? 'Failed to start shopping'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAndMarkReady() async {
    final auth = context.read<AuthProvider>();
    final shopper = context.read<ShopperProvider>();
    final orderId = widget.order.documentId ?? widget.order.id;

    // Confirm with the shopper
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Shopping?'),
        content: Text(
          'You found $_foundCount of $_totalCount items.\n'
          'Actual total: ${Formatters.formatCurrency(_actualTotal)}\n\n'
          'Mark this order as ready for pickup?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    // 1. Batch update all items with found status and actual prices
    final itemUpdates = _items.map((item) {
      final price = double.tryParse(item.priceController.text);
      return {
        'documentId': item.cartItem.id,
        'found': item.found,
        if (price != null) 'actual_price': price,
      };
    }).toList();

    await shopper.updateOrderItems(auth.token!, itemUpdates);

    // 2. Mark order as ready for pickup
    final success = await shopper.markOrderReady(auth.token!, orderId);

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as ready for pickup!'),
            backgroundColor: AppColors.primary,
          ),
        );
        context.go('/shopper/active-tasks');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shopper.error ?? 'Failed to complete order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.orderNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/shopper/active-tasks'),
        ),
      ),
      body: Column(
        children: [
          // Progress header
          _buildProgressHeader(),
          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _items.length,
              itemBuilder: (context, index) => _buildItemCard(_items[index]),
            ),
          ),
          // Bottom action bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primarySoft,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_foundCount of $_totalCount items found',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: AppColors.grey200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated: ${Formatters.formatCurrency(widget.order.subtotal)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              Text(
                'Actual: ${Formatters.formatCurrency(_actualTotal)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(_ChecklistItem item) {
    final product = item.cartItem.product;
    final estimatedLineTotal = product.price * item.cartItem.quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.found ? AppColors.primary : AppColors.grey200,
          width: item.found ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => setState(() => item.found = !item.found),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.found ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: item.found ? AppColors.primary : AppColors.grey300,
                    width: 2,
                  ),
                ),
                child: item.found
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration: item.found ? null : null,
                      color: item.found ? AppColors.black : AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.cartItem.quantity} ${product.unit}  ~  ${Formatters.formatCurrency(estimatedLineTotal)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (item.cartItem.specialInstructions != null &&
                      item.cartItem.specialInstructions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Note: ${item.cartItem.specialInstructions}',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Actual price input (shown when found)
            if (item.found)
              SizedBox(
                width: 90,
                child: TextField(
                  controller: item.priceController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    labelStyle: const TextStyle(fontSize: 11),
                    prefixText: 'UGX ',
                    prefixStyle: const TextStyle(fontSize: 10),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      item.actualPrice = double.tryParse(val);
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: _hasStartedShopping
            ? SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAndMarkReady,
                  icon: _isSaving
                      ? const AppLoadingIndicator.small(color: Colors.white)
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Mark Ready for Pickup',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _startShopping,
                  icon: _isSaving
                      ? const AppLoadingIndicator.small(color: Colors.white)
                      : const Icon(Icons.shopping_cart),
                  label: Text(
                    _isSaving ? 'Starting...' : 'Start Shopping',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
