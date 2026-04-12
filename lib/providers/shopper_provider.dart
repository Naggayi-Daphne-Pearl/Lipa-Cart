import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/strapi_service.dart';

class ShopperProvider extends ChangeNotifier {
  Map<String, dynamic>? _shopperProfile;
  List<Map<String, dynamic>> _ratings = [];
  List<Order> _availableTasks = [];
  List<Order> _activeTasks = [];
  List<Order> _completedTasks = [];

  bool _isLoading = false;
  bool _hasLoadedRatings = false;
  String? _error;

  Map<String, dynamic>? get shopperProfile => _shopperProfile;
  List<Map<String, dynamic>> get ratings => _ratings;
  List<Order> get availableTasks => _availableTasks;
  List<Order> get activeTasks => _activeTasks;
  List<Order> get completedTasks => _completedTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalReviews {
    if (_hasLoadedRatings) {
      return _ratings.length;
    }
    return (_shopperProfile?['total_ratings'] as num? ?? 0).toInt();
  }

  double get averageRating {
    if (_hasLoadedRatings) {
      final stars = _ratings
          .map((r) => (r['stars'] as num?)?.toDouble() ?? 0)
          .where((s) => s > 0)
          .toList();
      if (stars.isEmpty) return 0;
      final sum = stars.reduce((a, b) => a + b);
      return sum / stars.length;
    }
    return (_shopperProfile?['rating'] as num? ?? 0).toDouble();
  }

  int get completedOrders => _shopperProfile?['total_orders_completed'] ?? 0;
  double get totalEarnings =>
      (_shopperProfile?['total_earnings'] ?? 0).toDouble();
  bool get isOnline => _shopperProfile?['is_online'] ?? false;

  Future<bool> loadShopperProfile(
    String token,
    String shopperId, {
    String? userDocumentId,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ratingsOwnerId = userDocumentId ?? userId ?? shopperId;
      final responses = await Future.wait([
        StrapiService.getShopperProfile(shopperId, token),
        StrapiService.getShopperRatings(
          ratingsOwnerId,
          token,
        ),
      ]);
      final response = responses[0] as Map<String, dynamic>?;
      final ratings = responses[1] as List<Map<String, dynamic>>;
      _hasLoadedRatings = true;
      if (response != null) {
        _shopperProfile = response;
        _ratings = ratings;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _ratings = ratings;
      _error = 'Failed to load profile';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _hasLoadedRatings = true;
      _ratings = [];
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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

  Future<bool> unclaimTask(String token, String orderId, String userDocId) async {
    try {
      final success = await StrapiService.unclaimOrder(orderId, token);
      if (success) {
        _activeTasks.removeWhere((o) => o.id == orderId || o.documentId == orderId);
        await fetchAvailableTasks(token);
        notifyListeners();
        return true;
      }
      _error = 'Failed to cancel task';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error cancelling task: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptTask(
    String token,
    String orderId,
    String userDocumentId,
  ) async {
    try {
      final success = await StrapiService.assignOrderToShopper(
        orderId,
        userDocumentId,
        token,
      );

      if (success) {
        _availableTasks.removeWhere((o) => o.id == orderId || o.documentId == orderId);
        await fetchActiveTasks(token, userDocumentId);
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

  Future<bool> startShopping(String token, String orderId) async {
    try {
      final result = await StrapiService.updateShopperOrderStatus(
        orderId,
        'shopping',
        token,
      );
      if (result != null) {
        final idx = _activeTasks.indexWhere(
          (o) => o.documentId == orderId || o.id == orderId,
        );
        if (idx >= 0) {
          _activeTasks[idx] = _activeTasks[idx].copyWith(
            status: OrderStatus.shopping,
          );
        }
        notifyListeners();
        return true;
      }
      _error = 'Failed to start shopping';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error starting shopping: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markOrderReady(String token, String orderId) async {
    try {
      final result = await StrapiService.updateShopperOrderStatus(
        orderId,
        'ready_for_pickup',
        token,
      );
      if (result != null) {
        _activeTasks.removeWhere(
          (o) => o.documentId == orderId || o.id == orderId,
        );
        notifyListeners();
        return true;
      }
      _error = 'Failed to mark order ready';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error marking order ready: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderItems(
    String token,
    List<Map<String, dynamic>> itemUpdates,
  ) async {
    try {
      return await StrapiService.batchUpdateOrderItems(itemUpdates, token);
    } catch (e) {
      _error = 'Error updating items: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Map<int, int> get ratingBreakdown {
    final map = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _ratings) {
      final stars = (r['stars'] as num?)?.toInt();
      if (stars != null && map.containsKey(stars)) {
        map[stars] = map[stars]! + 1;
      }
    }
    return map;
  }

  Future<void> clearAll() async {
    _shopperProfile = null;
    _ratings = [];
    _availableTasks = [];
    _activeTasks = [];
    _completedTasks = [];
    _isLoading = false;
    _hasLoadedRatings = false;
    _error = null;
    notifyListeners();
  }
}
