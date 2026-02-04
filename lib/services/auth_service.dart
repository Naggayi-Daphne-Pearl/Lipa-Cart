import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../core/constants/app_constants.dart';

class AuthService extends ChangeNotifier {
  static String get baseUrl => AppConstants.baseUrl;

  String? _token;
  User? _user;

  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;

  /// Login with phone and password
  Future<bool> login({required String phone, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/local'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['jwt'];
        _user = User.fromJson(data['user']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String phone,
    required String password,
    required String name,
    required String userType,
  }) async {
    try {
      // First, register in Strapi auth
      final authResponse = await http.post(
        Uri.parse('$baseUrl/api/auth/local/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': phone,
          'email': phone,
          'password': password,
        }),
      );

      if (authResponse.statusCode != 200) return false;

      final authData = jsonDecode(authResponse.body);
      _token = authData['jwt'];

      // Then, create custom user profile
      final profileResponse = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'data': {
            'phone': phone,
            'name': name,
            'user_type': userType,
            'is_active': true,
          },
        }),
      );

      if (profileResponse.statusCode == 201) {
        final profileData = jsonDecode(profileResponse.body);
        _user = User.fromJson(profileData['data']);

        // Create customer profile if customer type
        if (_user!.role == UserRole.customer) {
          await _createCustomerProfile(_user!.phoneNumber);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  /// Create customer profile linked to user
  Future<void> _createCustomerProfile(String phoneNumber) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/customers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'data': {'phoneNumber': phoneNumber, 'total_orders': 0},
        }),
      );
    } catch (e) {
      print('Error creating customer profile: $e');
    }
  }

  /// Get current user
  Future<bool> getCurrentUser() async {
    if (_token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error getting current user: $e');
      return false;
    }
  }

  /// Logout
  void logout() {
    _token = null;
    _user = null;
    notifyListeners();
  }
}
