import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/imgbb_service.dart';
import '../services/strapi_service.dart';

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
  int get completedOrders =>
      _riderProfile?['total_deliveries_completed'] ??
      _riderProfile?['total_orders_completed'] ??
      0;
  double get totalEarnings =>
      (_riderProfile?['total_earnings'] ?? 0).toDouble();
  bool get isOnline => _riderProfile?['is_online'] ?? false;

  /// Load rider profile
  Future<bool> loadRiderProfile(String token, String riderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await StrapiService.getRiderProfile(riderId, token);
      if (response != null) {
        _riderProfile = response;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      // Fallback defaults if API returns null
      _riderProfile = {
        'total_ratings': 0,
        'rating': 0.0,
        'total_orders_completed': 0,
        'total_earnings': 0.0,
        'is_online': false,
      };
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

  /// Fetch available deliveries (orders ready for pickup)
  Future<bool> fetchAvailableDeliveries(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availableDeliveries = await StrapiService.getAvailableDeliveries(token);
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
      _activeDeliveries = await StrapiService.getActiveDeliveries(
        token,
        riderId,
      );
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
      _completedDeliveries = await StrapiService.getCompletedDeliveries(
        token,
        riderId,
      );
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
      final result = await StrapiService.claimDelivery(orderId, token);
      if (result != null) {
        _availableDeliveries.removeWhere(
          (o) => o.id == orderId || o.documentId == orderId,
        );
        await fetchActiveDeliveries(token, riderId);
        notifyListeners();
        return true;
      }
      _error = 'Failed to accept delivery';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mark delivery as in transit (picked up from shopper)
  Future<bool> markInTransit(
    String token,
    String orderId,
    String riderId,
  ) async {
    try {
      final result = await StrapiService.updateRiderOrderStatus(
        orderId,
        'in_transit',
        token,
      );
      if (result != null) {
        await fetchActiveDeliveries(token, riderId);
        notifyListeners();
        return true;
      }
      _error = 'Failed to update status';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mark delivery as complete (delivered to customer)
  Future<bool> completeDelivery(
    String token,
    String orderId,
    String riderId, {
    Uint8List? proofPhotoBytes,
  }) async {
    try {
      String? proofUrl;
      if (proofPhotoBytes != null) {
        proofUrl = await ImgBBService.uploadImageBytes(
          proofPhotoBytes,
          'delivery_proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
      final result = await StrapiService.updateRiderOrderStatus(
        orderId,
        'delivered',
        token,
        deliveryProofUrl: proofUrl,
      );
      if (result != null) {
        await fetchActiveDeliveries(token, riderId);
        notifyListeners();
        return true;
      }
      _error = 'Failed to complete delivery';
      notifyListeners();
      return false;
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
      final success = await StrapiService.updateRiderStatus(
        riderId,
        online,
        token,
      );

      if (success) {
        _riderProfile?['is_online'] = online;
        notifyListeners();
        return true;
      }

      _error = 'Failed to update online status';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }
}
