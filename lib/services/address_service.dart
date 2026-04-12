import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/address.dart';
import '../models/user.dart' as user_models;
import '../core/constants/app_constants.dart';

class AddressService extends ChangeNotifier {
  AddressService() {
    loadPreferredAddress();
  }

  static String get baseUrl => AppConstants.baseUrl;

  List<Address> _addresses = [];
  Address? _defaultAddress;
  Address? _preferredAddress;
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedPreferredAddress = false;

  List<Address> get addresses => _addresses;
  Address? get defaultAddress {
    final backendDefault = _defaultAddress;
    if (backendDefault != null && backendDefault.id != 0) {
      return backendDefault;
    }
    return _preferredAddress;
  }

  bool get hasSelectedAddress {
    final selectedAddress = defaultAddress;
    return selectedAddress != null &&
        selectedAddress.fullAddress.trim().isNotEmpty;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<user_models.Address> get userAddresses {
    return _addresses.map(_toUserAddress).toList();
  }

  user_models.Address? get defaultUserAddress {
    final addr = defaultAddress;
    if (addr == null) return null;
    return _toUserAddress(addr);
  }

  user_models.Address _toUserAddress(Address address) {
    final landmark = address.landmark;
    final fullAddress =
        '${address.addressLine}, ${address.city}${landmark != null && landmark.isNotEmpty ? ', $landmark' : ''}';

    return user_models.Address(
      id: address.id.toString(),
      label: address.label,
      fullAddress: fullAddress,
      landmark: landmark,
      // Pass through null instead of coercing missing GPS to (0, 0). The
      // backend service-area check will reject (0, 0), and downstream code
      // (route preview, dispatch) needs to know when we genuinely lack a pin.
      latitude: address.gpsLat,
      longitude: address.gpsLng,
      isDefault: address.isDefault,
    );
  }

  Future<void> loadPreferredAddress() async {
    if (_hasLoadedPreferredAddress) return;
    _hasLoadedPreferredAddress = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(AppConstants.preferredDeliveryAddressKey);
      if (saved == null || saved.isEmpty) return;

      final data = jsonDecode(saved) as Map<String, dynamic>;
      _preferredAddress = Address(
        id: -1,
        documentId: 'preferred-address',
        customerId: 0,
        label: (data['label'] ?? 'Delivery Address').toString(),
        addressLine: (data['addressLine'] ?? '').toString(),
        city: (data['city'] ?? 'Kampala').toString(),
        landmark: data['landmark'] as String?,
        deliveryInstructions: data['deliveryInstructions'] as String?,
        gpsLat: data['gpsLat'] is num
            ? (data['gpsLat'] as num).toDouble()
            : double.tryParse(data['gpsLat']?.toString() ?? ''),
        gpsLng: data['gpsLng'] is num
            ? (data['gpsLng'] as num).toDouble()
            : double.tryParse(data['gpsLng']?.toString() ?? ''),
        isDefault: data['isDefault'] as bool? ?? true,
        createdAt:
            DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );

      if (_defaultAddress == null || _defaultAddress!.id == 0) {
        _defaultAddress = _preferredAddress;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Could not restore saved delivery address';
      notifyListeners();
    }
  }

  Future<void> savePreferredAddress({
    required String label,
    required String addressLine,
    required String city,
    String? landmark,
    String? deliveryInstructions,
    bool isDefault = true,
    double? gpsLat,
    double? gpsLng,
  }) async {
    final address = Address(
      id: -1,
      documentId: 'preferred-address',
      customerId: 0,
      label: label,
      addressLine: addressLine,
      city: city,
      landmark: landmark,
      deliveryInstructions: deliveryInstructions,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );

    _preferredAddress = address;
    if (_defaultAddress == null || _defaultAddress!.id == 0) {
      _defaultAddress = address;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.preferredDeliveryAddressKey,
      jsonEncode({
        'label': address.label,
        'addressLine': address.addressLine,
        'city': address.city,
        'landmark': address.landmark,
        'deliveryInstructions': address.deliveryInstructions,
        'gpsLat': address.gpsLat,
        'gpsLng': address.gpsLng,
        'isDefault': address.isDefault,
        'createdAt': address.createdAt.toIso8601String(),
      }),
    );

    notifyListeners();
  }

  Future<void> clearPreferredAddress() async {
    _preferredAddress = null;
    if (_defaultAddress?.id == -1 || _defaultAddress?.id == 0) {
      _defaultAddress = null;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.preferredDeliveryAddressKey);
    notifyListeners();
  }

  /// Fetch all addresses for current customer
  Future<bool> fetchAddresses(String token, String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Strapi v5 syntax: filter by relation ID directly
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/addresses?filters[customer][\$eq]=$customerId&populate=customer',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _addresses = List<Address>.from(
          (data['data'] as List).map((addr) => Address.fromJson(addr)),
        );
        _defaultAddress = _addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () {
            if (_addresses.isNotEmpty) return _addresses.first;
            return _preferredAddress ?? Address.empty();
          },
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = 'Failed to fetch addresses';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error fetching addresses: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create new address
  Future<bool> createAddress({
    required String token,
    required String customerId,
    required String label,
    required String addressLine,
    required String city,
    String? landmark,
    String? deliveryInstructions,
    bool isDefault = false,
    double? gpsLat,
    double? gpsLng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {
            'customer': customerId,
            'label': label,
            'address_line': addressLine,
            'city': city,
            'landmark': landmark,
            'delivery_instructions': deliveryInstructions,
            'is_default': isDefault,
            if (gpsLat != null) 'gps_lat': gpsLat,
            if (gpsLng != null) 'gps_lng': gpsLng,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newAddress = Address.fromJson(data['data']);
        _addresses.add(newAddress);
        if (isDefault) {
          _defaultAddress = newAddress;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error creating address: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update existing address
  Future<bool> updateAddress({
    required String token,
    required int addressId,
    required String addressDocumentId,
    required String label,
    required String addressLine,
    required String city,
    String? landmark,
    String? deliveryInstructions,
    bool isDefault = false,
    double? gpsLat,
    double? gpsLng,
  }) async {
    try {
      final targetId = addressDocumentId.isNotEmpty
          ? addressDocumentId
          : addressId.toString();
      final response = await http.put(
        Uri.parse('$baseUrl/api/addresses/$targetId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {
            'label': label,
            'address_line': addressLine,
            'city': city,
            'landmark': landmark,
            'delivery_instructions': deliveryInstructions,
            'is_default': isDefault,
            if (gpsLat != null) 'gps_lat': gpsLat,
            if (gpsLng != null) 'gps_lng': gpsLng,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final index = _addresses.indexWhere((a) => a.id == addressId);
        if (index != -1) {
          _addresses[index] = Address.fromJson(data['data']);
          if (isDefault) {
            _defaultAddress = _addresses[index];
          }
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error updating address: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete address
  Future<bool> deleteAddress({
    required String token,
    required int addressId,
    required String addressDocumentId,
  }) async {
    try {
      final targetId = addressDocumentId.isNotEmpty
          ? addressDocumentId
          : addressId.toString();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/addresses/$targetId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _addresses.removeWhere((a) => a.id == addressId);
        if (_defaultAddress?.id == addressId) {
          _defaultAddress = _addresses.isNotEmpty ? _addresses.first : null;
        }
        notifyListeners();
        return true;
      }
      _error = 'Failed to delete address';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error deleting address: $e';
      notifyListeners();
      return false;
    }
  }

  /// Set address as default.
  ///
  /// Calls the atomic backend endpoint `POST /api/addresses/:id/set-default`,
  /// which clears all other defaults and sets the target inside a single DB
  /// transaction. The previous client-side implementation issued two separate
  /// PUTs and could leave the customer with zero or two defaults if the second
  /// call failed or interleaved with another setDefault.
  Future<bool> setDefaultAddress({
    required String token,
    required int addressId,
    required String addressDocumentId,
  }) async {
    try {
      final targetId = addressDocumentId.isNotEmpty
          ? addressDocumentId
          : addressId.toString();
      final response = await http.post(
        Uri.parse('$baseUrl/api/addresses/$targetId/set-default'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updated = Address.fromJson(data['data']);
        // Refresh local cache: the chosen one is the only default now.
        _addresses = _addresses
            .map((a) => a.id == updated.id ? updated : a.copyWith(isDefault: false))
            .toList();
        _defaultAddress = updated;
        notifyListeners();
        return true;
      }
      _error = 'Failed to set default address';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error setting default address: $e';
      notifyListeners();
      return false;
    }
  }
}
