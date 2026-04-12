import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopper_provider.dart';
import '../../services/order_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/app_loading_indicator.dart';

/// Item state tracked locally during the shopping session
class _ChecklistItem {
  final CartItem cartItem;
  bool found;
  double? actualPrice;
  final TextEditingController priceController;
  final TextEditingController notesController;

  _ChecklistItem({required this.cartItem, this.actualPrice})
    : found = cartItem.found ?? false,
      priceController = TextEditingController(
        text: (cartItem.actualPrice ?? actualPrice)?.toStringAsFixed(0) ?? '',
      ),
      notesController = TextEditingController(
        text: cartItem.shopperNotes ?? '',
      );

  void dispose() {
    priceController.dispose();
    notesController.dispose();
  }
}

class ShoppingChecklistScreen extends StatefulWidget {
  final Order order;
  const ShoppingChecklistScreen({super.key, required this.order});

  @override
  State<ShoppingChecklistScreen> createState() =>
      _ShoppingChecklistScreenState();
}

class _ShoppingChecklistScreenState extends State<ShoppingChecklistScreen> {
  late Order _currentOrder;
  late List<_ChecklistItem> _items;
  bool _isSaving = false;
  bool _hasStartedShopping = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _items = _currentOrder.items
        .map(
          (item) =>
              _ChecklistItem(cartItem: item, actualPrice: item.product.price),
        )
        .toList();

    _hasStartedShopping =
        _currentOrder.status == OrderStatus.shopping ||
        _currentOrder.status == OrderStatus.readyForDelivery;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshOrder(showFeedback: false);
      }
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && !_isSaving) {
        _refreshOrder();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  /// Extracts the customer's rejection reason from special_instructions.
  String? _rejectionReason(CartItem item) {
    final instructions = item.specialInstructions;
    if (instructions == null || !instructions.startsWith('REJECTION:')) return null;
    return instructions.replaceFirst('REJECTION: ', '').trim();
  }

  Future<void> _refreshOrder({bool showFeedback = true}) async {
    final auth = context.read<AuthProvider>();
    final orderService = context.read<OrderService>();
    if (auth.token == null) return;

    final success = await orderService.getOrder(
      auth.token!,
      _currentOrder.documentId ?? _currentOrder.id,
    );
    if (!success || orderService.currentOrder == null || !mounted) return;

    _syncItemsFromOrder(orderService.currentOrder!, showFeedback: showFeedback);
  }

  void _syncItemsFromOrder(Order latestOrder, {bool showFeedback = true}) {
    Map<String, dynamic>? feedback;

    for (final latestItem in latestOrder.items) {
      final index = _items.indexWhere(
        (item) => item.cartItem.id == latestItem.id,
      );
      if (index == -1) continue;

      final localItem = _items[index];
      final previousApproval = localItem.cartItem.substitutionApproved;
      final nextApproval = latestItem.substitutionApproved;

      localItem.cartItem.found = latestItem.found;
      localItem.cartItem.actualPrice = latestItem.actualPrice;
      localItem.cartItem.shopperNotes = latestItem.shopperNotes;
      localItem.cartItem.substitutionApproved = nextApproval;
      localItem.cartItem.isSubstituted = latestItem.isSubstituted;
      localItem.cartItem.substituteName = latestItem.substituteName;
      localItem.cartItem.substitutePrice = latestItem.substitutePrice;
      localItem.cartItem.substitutePhotoUrl = latestItem.substitutePhotoUrl;
      localItem.found = latestItem.found ?? localItem.found;
      localItem.actualPrice = latestItem.actualPrice ?? localItem.actualPrice;

      final latestNotes = latestItem.shopperNotes ?? '';
      if (localItem.notesController.text != latestNotes) {
        localItem.notesController.text = latestNotes;
      }

      if (latestItem.actualPrice != null) {
        final formattedPrice = latestItem.actualPrice!.toStringAsFixed(0);
        if (localItem.priceController.text != formattedPrice) {
          localItem.priceController.text = formattedPrice;
        }
      }

      if (showFeedback &&
          previousApproval != nextApproval &&
          nextApproval != null) {
        final label = latestItem.substituteName ?? latestItem.product.name;
        feedback = {
          'message': nextApproval
              ? 'Customer accepted $label. You can continue with the replacement.'
              : 'Customer rejected the substitute for ${latestItem.product.name}.',
          'color': nextApproval ? AppColors.success : AppColors.error,
        };
      }
    }

    setState(() {
      _currentOrder = latestOrder;
      _hasStartedShopping =
          latestOrder.status == OrderStatus.shopping ||
          latestOrder.status == OrderStatus.readyForDelivery;
    });

    if (feedback != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(feedback['message'] as String),
          backgroundColor: feedback['color'] as Color,
        ),
      );
    }
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

    // Validate prices
    for (final item in _items) {
      if (item.found) {
        final price = double.tryParse(item.priceController.text);
        if (price == null || price <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please enter a valid price for ${item.cartItem.product.name}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (price > item.cartItem.product.price * 5) {
          if (!mounted) return;
          final priceConfirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Price Warning'),
              content: Text(
                '${item.cartItem.product.name} price (${Formatters.formatCurrency(price)}) is much higher than estimated (${Formatters.formatCurrency(item.cartItem.product.price)}). Continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Review'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
          if (priceConfirm != true) return;
        }
      }
    }

    // Confirm with the shopper
    if (!mounted) return;
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
      final notes = item.notesController.text.trim();
      return {
        'documentId': item.cartItem.id,
        'found': item.found,
        if (price != null) 'actual_price': price,
        if (notes.isNotEmpty) 'shopper_notes': notes,
      };
    }).toList();

    // 1. Save item updates — abort if this fails
    final itemsUpdated = await shopper.updateOrderItems(
      auth.token!,
      itemUpdates,
    );

    if (!itemsUpdated) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              shopper.error ?? 'Failed to save item updates. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Mark order as ready for pickup (only if items saved successfully)
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

  void _showCallDialog(String role, String name, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    try {
                      launchUrl(Uri(scheme: 'tel', path: phone));
                    } catch (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$phone copied — open your phone app to call',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: Text('Call $role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_currentOrder.orderNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/shopper/active-tasks'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh order',
            onPressed: _isSaving ? null : () => _refreshOrder(),
          ),
        ],
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
          // Customer info with call button
          if (widget.order.customer != null) ...[
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.order.customer!.name ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (widget.order.customer!.phoneNumber.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _showCallDialog(
                      'Customer',
                      widget.order.customer!.name ?? 'Customer',
                      widget.order.customer!.phoneNumber,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Call',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final phone = widget.order.customer!.phoneNumber
                          .replaceAll('+', '');
                      launchUrl(
                        Uri.parse(
                          'https://wa.me/$phone?text=Hi%2C%20I%27m%20shopping%20your%20LipaCart%20order',
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat, size: 14, color: Color(0xFF25D366)),
                          SizedBox(width: 4),
                          Text(
                            'WhatsApp',
                            style: TextStyle(
                              color: Color(0xFF25D366),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
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
    final substituteLabel = item.cartItem.substituteName;
    final substituteApproved = item.cartItem.substitutionApproved;
    final hasSubstitute = substituteLabel != null || item.cartItem.isSubstituted == true;
    final approvedSubstitute =
        hasSubstitute && substituteApproved == true;
    final pendingSubstitute =
        hasSubstitute && substituteApproved == null;
    final rejectedSubstitute =
        hasSubstitute && substituteApproved == false;
    final rejectionReason = _rejectionReason(item.cartItem);
    final displayName = approvedSubstitute ? (substituteLabel ?? product.name) : product.name;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => setState(() => item.found = !item.found),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.found
                          ? AppColors.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: item.found
                            ? AppColors.primary
                            : AppColors.grey300,
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
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        approvedSubstitute
                            ? 'Replacing ${product.name}'
                            : '${item.cartItem.quantity} ${product.unit}  ~  ${Formatters.formatCurrency(estimatedLineTotal)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      if (approvedSubstitute)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${item.cartItem.quantity} ${product.unit}  •  approved by customer',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (item.cartItem.specialInstructions != null &&
                          item.cartItem.specialInstructions!.isNotEmpty &&
                          !item.cartItem.specialInstructions!.startsWith('REJECTION:'))
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
            // Shopper notes field
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: item.notesController,
                maxLines: 1,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: item.found
                      ? 'Add note (e.g. different brand)'
                      : 'Why not found? (e.g. out of stock)',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  prefixIcon: Icon(
                    Icons.note_alt_outlined,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.grey200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.grey200),
                  ),
                ),
              ),
            ),
            if (hasSubstitute)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: approvedSubstitute
                        ? AppColors.success.withValues(alpha: 0.08)
                        : rejectedSubstitute
                        ? AppColors.error.withValues(alpha: 0.08)
                        : AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: approvedSubstitute
                          ? AppColors.success.withValues(alpha: 0.35)
                          : rejectedSubstitute
                          ? AppColors.error.withValues(alpha: 0.35)
                          : AppColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        approvedSubstitute
                            ? Icons.check_circle
                            : rejectedSubstitute
                            ? Icons.cancel
                            : Icons.access_time,
                        size: 18,
                        color: approvedSubstitute
                            ? AppColors.success
                            : rejectedSubstitute
                            ? AppColors.error
                            : AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          approvedSubstitute
                              ? 'Customer allowed this substitute. Replace the original item with $substituteLabel and continue shopping.'
                              : rejectedSubstitute
                              ? 'Customer rejected this substitute.${rejectionReason != null ? ' They said: "$rejectionReason"' : ' Suggest another option or leave the item unavailable.'}'
                              : 'Waiting for customer approval for $substituteLabel.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: approvedSubstitute
                                ? AppColors.success
                                : rejectedSubstitute
                                ? AppColors.error
                                : AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Suggest/continue substitute action
            if (!item.found)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: approvedSubstitute
                      ? ElevatedButton.icon(
                          onPressed: () {
                            final approvedPrice = item.cartItem.substitutePrice;
                            setState(() {
                              item.found = true;
                              item.cartItem.found = true;
                              if (approvedPrice != null) {
                                item.actualPrice = approvedPrice;
                                item.cartItem.actualPrice = approvedPrice;
                                item.priceController.text = approvedPrice
                                    .toStringAsFixed(0);
                              }
                            });
                          },
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text(
                            'Customer allowed substitute — continue',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: pendingSubstitute
                              ? null
                              : () => _showSubstituteDialog(item),
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: Text(
                            rejectedSubstitute
                                ? 'Suggest Another Substitute'
                                : pendingSubstitute
                                ? 'Awaiting Customer Response'
                                : 'Suggest Substitute',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(
                              color: AppColors.accent.withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSubstituteDialog(_ChecklistItem item) {
    // Pre-fill with what the customer requested (from rejection reason)
    final reason = _rejectionReason(item.cartItem);
    final substituteController = TextEditingController(text: reason ?? '');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Suggest Substitute'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original: ${item.cartItem.product.name}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (reason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Customer asked: "$reason"',
                        style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: substituteController,
              decoration: InputDecoration(
                labelText: 'Substitute item name',
                hintText: 'e.g. Brand X Milk instead',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (UGX)',
                prefixText: 'UGX ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = substituteController.text.trim();
              if (name.isEmpty) return;
              final price = priceController.text.trim();
              final parsedPrice = double.tryParse(price);
              if (parsedPrice == null || parsedPrice <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              // Optimistically update local state
              setState(() {
                item.found = false;
                item.actualPrice = parsedPrice;
                item.cartItem.found = false;
                item.cartItem.actualPrice = parsedPrice;
                item.cartItem.isSubstituted = true;
                item.cartItem.substituteName = name;
                item.cartItem.substitutePrice = parsedPrice;
                item.cartItem.substitutionApproved = null;
              });

              final auth = context.read<AuthProvider>();
              final orderService = context.read<OrderService>();
              final token = auth.token;

              if (token != null) {
                final success = await orderService.suggestSubstitute(
                  token,
                  item.cartItem.id,
                  name: name,
                  price: parsedPrice,
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Substitute suggested — customer notified.'
                          : (orderService.error ??
                                'Failed to send substitute suggestion.'),
                    ),
                    backgroundColor: success
                        ? AppColors.primary
                        : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suggest'),
          ),
        ],
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
        child: _currentOrder.status == OrderStatus.readyForDelivery
            ? SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Shopping Complete — Awaiting Pickup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.green.withValues(
                      alpha: 0.3,
                    ),
                    disabledForegroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            : _hasStartedShopping
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
                  label: Text(_isSaving ? 'Starting...' : 'Start Shopping'),
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
