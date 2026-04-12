import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/upload_service.dart';
import '../services/strapi_service.dart';

class RiderProvider extends ChangeNotifier {
  Map<String, dynamic>? _riderProfile;
  List<Map<String, dynamic>> _ratings = [];
  List<Order> _availableDeliveries = [];
  List<Order> _activeDeliveries = [];
  List<Order> _completedDeliveries = [];

  bool _isLoading = false;
  bool _hasLoadedRatings = false;
  String? _error;

  Map<String, dynamic>? get riderProfile => _riderProfile;
  List<Map<String, dynamic>> get ratings => _ratings;
  List<Order> get availableDeliveries => _availableDeliveries;
  List<Order> get activeDeliveries => _activeDeliveries;
  List<Order> get completedDeliveries => _completedDeliveries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalReviews {
    if (_hasLoadedRatings) {
      return _ratings.length;
    }
    return (_riderProfile?['total_ratings'] as num? ?? 0).toInt();
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
    return (_riderProfile?['rating'] as num? ?? 0).toDouble();
  }

  int get completedOrders =>
      _riderProfile?['total_deliveries_completed'] ??
      _riderProfile?['total_orders_completed'] ??
      0;
  double get totalEarnings =>
      (_riderProfile?['total_earnings'] ?? 0).toDouble();
  bool get isOnline => _riderProfile?['is_online'] ?? false;

  Future<bool> loadRiderProfile(
    String token,
    String riderId, {
    String? userDocumentId,
    String? userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ratingsOwnerId = userDocumentId ?? userId ?? riderId;
      final responses = await Future.wait([
        StrapiService.getRiderProfile(riderId, token),
        StrapiService.getRiderRatings(
          ratingsOwnerId,
          token,
        ),
      ]);
      final response = responses[0] as Map<String, dynamic>?;
      final ratings = responses[1] as List<Map<String, dynamic>>;
      _hasLoadedRatings = true;
      if (response != null) {
        _riderProfile = response;
        _ratings = ratings;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _riderProfile = {
        'total_ratings': 0,
        'rating': 0.0,
        'total_orders_completed': 0,
        'total_earnings': 0.0,
        'is_online': false,
      };
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

  Future<bool> cancelDelivery(
    String token,
    String orderId,
    String riderId,
  ) async {
    try {
      final result = await StrapiService.unclaimDelivery(orderId, token);
      if (result != null) {
        await fetchActiveDeliveries(token, riderId);
        await fetchAvailableDeliveries(token);
        notifyListeners();
        return true;
      }
      _error = 'Failed to cancel delivery';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeDelivery(
    String token,
    String orderId,
    String riderId, {
    Uint8List? proofPhotoBytes,
  }) async {
    try {
      String? proofUrl;
      if (proofPhotoBytes != null) {
        proofUrl = await UploadService.uploadImageBytes(
          proofPhotoBytes,
          'delivery_proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
          token,
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

  Future<void> clearAll() async {
    _riderProfile = null;
    _ratings = [];
    _availableDeliveries = [];
    _activeDeliveries = [];
    _completedDeliveries = [];
    _isLoading = false;
    _hasLoadedRatings = false;
    _error = null;
    notifyListeners();
  }
}
