import 'package:flutter/foundation.dart';
import '../models/order.dart';

class RiderProvider extends ChangeNotifier {
  // Rider data
  Map<String, dynamic>? _riderProfile;
  List<Order> _availableDeliveries = [];
  List<Order> _activeDeliveries = [];
  List<Order> _completedDeliveries = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get riderProfile => _riderProfile;
  List<Order> get availableDeliveries => _availableDeliveries;
  List<Order> get activeDeliveries => _activeDeliveries;
  List<Order> get completedDeliveries => _completedDeliveries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Summary stats
  int get totalReviews => _riderProfile?['total_ratings'] ?? 0;
  double get averageRating => (_riderProfile?['rating'] ?? 0).toDouble();
  int get completedOrders => _riderProfile?['total_orders_completed'] ?? 0;
  double get totalEarnings =>
      (_riderProfile?['total_earnings'] ?? 0).toDouble();
  bool get isOnline => _riderProfile?['is_online'] ?? false;

  /// Load rider profile
  Future<bool> loadRiderProfile(String token, String riderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement rider profile API call
      _riderProfile = {
        'total_ratings': 0,
        'rating': 0.0,
        'total_orders_completed': 0,
        'total_earnings': 0.0,
        'is_online': false,
      };
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch available deliveries (orders ready for delivery)
  Future<bool> fetchAvailableDeliveries(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement available deliveries API call
      _availableDeliveries = [];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch active deliveries assigned to this rider
  Future<bool> fetchActiveDeliveries(String token, String riderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement active deliveries API call
      _activeDeliveries = [];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch completed deliveries
  Future<bool> fetchCompletedDeliveries(String token, String riderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Implement completed deliveries API call
      _completedDeliveries = [];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Accept a delivery
  Future<bool> acceptDelivery(
    String token,
    String orderId,
    String riderId,
  ) async {
    try {
      // TODO: Implement accept delivery API call
      await fetchAvailableDeliveries(token);
      await fetchActiveDeliveries(token, riderId);
      return true;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mark delivery as complete
  Future<bool> completeDelivery(
    String token,
    String orderId,
    String riderId,
  ) async {
    try {
      // TODO: Implement complete delivery API call
      await fetchActiveDeliveries(token, riderId);
      return true;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle online/offline status
  Future<bool> toggleOnlineStatus(
    String token,
    String riderId,
    bool online,
  ) async {
    try {
      _riderProfile?['is_online'] = online;
      notifyListeners();
      // TODO: Implement API call to update online status
      return true;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }
}
