import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/strapi_service.dart';

class ShopperProvider extends ChangeNotifier {
  // Shopper data
  Map<String, dynamic>? _shopperProfile;
  List<Order> _availableTasks = [];
  List<Order> _activeTasks = [];
  List<Order> _completedTasks = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get shopperProfile => _shopperProfile;
  List<Order> get availableTasks => _availableTasks;
  List<Order> get activeTasks => _activeTasks;
  List<Order> get completedTasks => _completedTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Summary stats
  int get totalReviews => _shopperProfile?['total_ratings'] ?? 0;
  double get averageRating => (_shopperProfile?['rating'] ?? 0).toDouble();
  int get completedOrders => _shopperProfile?['total_orders_completed'] ?? 0;
  double get totalEarnings =>
      (_shopperProfile?['total_earnings'] ?? 0).toDouble();
  bool get isOnline => _shopperProfile?['is_online'] ?? false;

  /// Load shopper profile
  Future<bool> loadShopperProfile(String token, String shopperId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await StrapiService.getShopperProfile(shopperId, token);
      if (response != null) {
        _shopperProfile = response;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Failed to load profile';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch available tasks (orders with status = payment_confirmed)
  Future<bool> fetchAvailableTasks(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orders = await StrapiService.getAvailableOrdersForShopper(token);
      _availableTasks = orders;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to fetch available tasks: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch active tasks (orders assigned to shopper)
  Future<bool> fetchActiveTasks(String token, String shopperId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orders = await StrapiService.getActiveOrdersForShopper(
        token,
        shopperId,
      );
      _activeTasks = orders;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to fetch active tasks: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch completed tasks (delivered/cancelled orders)
  Future<bool> fetchCompletedTasks(String token, String shopperId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final orders = await StrapiService.getCompletedOrdersForShopper(
        token,
        shopperId,
      );
      _completedTasks = orders;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to fetch completed tasks: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Accept an available task
  Future<bool> acceptTask(
    String token,
    String orderId,
    String shopperId,
  ) async {
    try {
      print('DEBUG: Accepting order $orderId for shopper $shopperId');

      final success = await StrapiService.assignOrderToShopper(
        orderId,
        shopperId,
        token,
      );

      if (success) {
        // Remove from available, add to active
        _availableTasks.removeWhere((o) => o.id == orderId);

        // Refresh active tasks
        await fetchActiveTasks(token, shopperId);

        notifyListeners();
        return true;
      }
      _error = 'Failed to accept task';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error accepting task: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update shopper online status
  Future<bool> toggleOnlineStatus(
    String token,
    String shopperId,
    bool isOnline,
  ) async {
    try {
      final success = await StrapiService.updateShopperStatus(
        shopperId,
        isOnline,
        token,
      );

      if (success) {
        _shopperProfile?['is_online'] = isOnline;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error updating status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mark order as ready for pickup
  Future<bool> markOrderReady(String token, String orderId) async {
    try {
      final success = await StrapiService.updateOrderStatus(
        orderId,
        'ready_for_pickup',
        token,
      );

      if (success) {
        // Move from active to completed
        final order = _activeTasks.firstWhere(
          (o) => o.id == orderId,
          orElse: () => Order(
            id: '',
            orderNumber: '',
            items: [],
            status: OrderStatus.pending,
            subtotal: 0,
            serviceFee: 0,
            deliveryFee: 0,
            total: 0,
            createdAt: DateTime.now(),
            deliveryAddress: Address(
              id: '',
              label: '',
              fullAddress: '',
              latitude: 0,
              longitude: 0,
            ),
            paymentMethod: PaymentMethod.mobileMoney,
          ),
        );

        if (order.id.isNotEmpty) {
          _activeTasks.remove(order);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error marking order ready: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all shopper data (for logout)
  Future<void> clearAll() async {
    _shopperProfile = null;
    _availableTasks = [];
    _activeTasks = [];
    _completedTasks = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
