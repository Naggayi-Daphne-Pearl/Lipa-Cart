import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../core/constants/app_constants.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;
  final _uuid = const Uuid();
  bool _didBootstrap = false;

  OrderProvider() {
    _bootstrap();
  }

  List<Order> get orders => List.unmodifiable(_orders);
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Order> get activeOrders => _orders
      .where(
        (o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled,
      )
      .toList();

  List<Order> get pastOrders => _orders
      .where(
        (o) =>
            o.status == OrderStatus.delivered ||
            o.status == OrderStatus.cancelled,
      )
      .toList();

  List<Product> get frequentlyOrderedProducts {
    final counts = <String, int>{};
    final productById = <String, Product>{};

    for (final order in pastOrders) {
      for (final item in order.items) {
        final productId = item.product.id;
        counts[productId] = (counts[productId] ?? 0) + item.quantity.toInt();
        productById[productId] = item.product;
      }
    }

    final sortedProductIds = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedProductIds
        .map((entry) => productById[entry.key]!)
        .take(4)
        .toList();
  }

  Future<void> _bootstrap() async {
    if (_didBootstrap) return;
    _didBootstrap = true;
    await _restoreOrders();
  }

  Future<void> _restoreOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawOrders = prefs.getString(AppConstants.ordersKey);
      if (rawOrders != null && rawOrders.isNotEmpty) {
        final data = jsonDecode(rawOrders) as List<dynamic>;
        _orders
          ..clear()
          ..addAll(
            data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList(),
          );
      }

      final rawCurrent = prefs.getString(AppConstants.currentOrderKey);
      if (rawCurrent != null && rawCurrent.isNotEmpty) {
        _currentOrder = Order.fromJson(
          jsonDecode(rawCurrent) as Map<String, dynamic>,
        );
      }

      notifyListeners();
    } catch (_) {
      // Ignore corrupted cache
    }
  }

  Future<void> _persistOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersPayload = jsonEncode(_orders.map((o) => o.toJson()).toList());
      await prefs.setString(AppConstants.ordersKey, ordersPayload);

      if (_currentOrder != null) {
        await prefs.setString(
          AppConstants.currentOrderKey,
          jsonEncode(_currentOrder!.toJson()),
        );
      } else {
        await prefs.remove(AppConstants.currentOrderKey);
      }
    } catch (_) {
      // Ignore persistence errors
    }
  }

  Future<Order?> createOrder({
    required List<CartItem> items,
    required Address deliveryAddress,
    required double subtotal,
    required double serviceFee,
    required double deliveryFee,
    required PaymentMethod paymentMethod,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      final order = Order(
        id: _uuid.v4(),
        orderNumber:
            'LC${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        items: items,
        deliveryAddress: deliveryAddress,
        subtotal: subtotal,
        serviceFee: serviceFee,
        deliveryFee: deliveryFee,
        total: subtotal + serviceFee + deliveryFee,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        estimatedDelivery: DateTime.now().add(const Duration(hours: 2)),
        paymentMethod: paymentMethod,
        isPaid: paymentMethod != PaymentMethod.cashOnDelivery,
      );

      _orders.insert(0, order);
      _currentOrder = order;
      _persistOrders();
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = 'Failed to create order. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _errorMessage = 'Failed to load orders.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Sync orders from backend service
  void syncOrdersFromService(List<Order> backendOrders) {
    _orders
      ..clear()
      ..addAll(backendOrders);
    _persistOrders();
    notifyListeners();
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  void setCurrentOrder(Order? order) {
    _currentOrder = order;
    _persistOrders();
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(status: status);
      if (_currentOrder?.id == orderId) {
        _currentOrder = _orders[index];
      }
      _persistOrders();
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(
        status: OrderStatus.cancelled,
        cancellationReason: reason,
      );
      if (_currentOrder?.id == orderId) {
        _currentOrder = _orders[index];
      }
      _persistOrders();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> clearAll() async {
    _orders.clear();
    _currentOrder = null;
    _isLoading = false;
    _errorMessage = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.ordersKey);
      await prefs.remove(AppConstants.currentOrderKey);
    } catch (_) {
      // Ignore persistence errors
    }
    notifyListeners();
  }
}
