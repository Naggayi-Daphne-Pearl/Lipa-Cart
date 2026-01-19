import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/user.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;
  final _uuid = const Uuid();

  List<Order> get orders => List.unmodifiable(_orders);
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Order> get activeOrders => _orders
      .where((o) =>
          o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled)
      .toList();

  List<Order> get pastOrders => _orders
      .where((o) =>
          o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
      .toList();

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
        orderNumber: 'LC${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
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

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  void setCurrentOrder(Order? order) {
    _currentOrder = order;
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _orders[index] = _orders[index].copyWith(status: status);
      if (_currentOrder?.id == orderId) {
        _currentOrder = _orders[index];
      }
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
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
