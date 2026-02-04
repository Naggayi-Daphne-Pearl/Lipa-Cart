import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/address.dart';
import '../core/constants/app_constants.dart';

class AddressService extends ChangeNotifier {
  static String get baseUrl => AppConstants.baseUrl;

  List<Address> _addresses = [];
  Address? _defaultAddress;
  bool _isLoading = false;
  String? _error;

  List<Address> get addresses => _addresses;
  Address? get defaultAddress => _defaultAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all addresses for current user
  Future<bool> fetchAddresses(String token, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/addresses?filters[user][id][\$eq]=$userId&populate=*',
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
          orElse: () =>
              _addresses.isNotEmpty ? _addresses.first : Address.empty(),
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
    required String userId,
    required String label,
    required String addressLine,
    required String city,
    String? landmark,
    String? deliveryInstructions,
    bool isDefault = false,
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
            'user': userId,
            'label': label,
            'address_line': addressLine,
            'city': city,
            'landmark': landmark,
            'delivery_instructions': deliveryInstructions,
            'is_default': isDefault,
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
    required String label,
    required String addressLine,
    required String city,
    String? landmark,
    String? deliveryInstructions,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/addresses/$addressId'),
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
  Future<bool> deleteAddress(String token, int addressId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/addresses/$addressId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _addresses.removeWhere((a) => a.id == addressId);
        if (_defaultAddress?.id == addressId) {
          _defaultAddress = _addresses.isNotEmpty ? _addresses.first : null;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error deleting address: $e';
      notifyListeners();
      return false;
    }
  }

  /// Set address as default
  Future<bool> setDefaultAddress(String token, int addressId) async {
    try {
      // Unset previous default
      if (_defaultAddress != null) {
        await http.put(
          Uri.parse('$baseUrl/api/addresses/${_defaultAddress!.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'data': {'is_default': false},
          }),
        );
      }

      // Set new default
      final response = await http.put(
        Uri.parse('$baseUrl/api/addresses/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {'is_default': true},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final index = _addresses.indexWhere((a) => a.id == addressId);
        if (index != -1) {
          _addresses[index] = Address.fromJson(data['data']);
          _defaultAddress = _addresses[index];
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error setting default address: $e';
      notifyListeners();
      return false;
    }
  }
}
