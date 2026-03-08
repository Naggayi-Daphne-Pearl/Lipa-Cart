import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/user.dart';

/// Admin service for managing users
/// Requires admin authentication token
class AdminUserService {
  static String get _apiUrl => AppConstants.apiUrl;

  /// Get all users (admin only)
  /// Returns list of all users in the system
  static Future<List<Map<String, dynamic>>> getAllUsers(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/admin/users'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode == 403) {
        throw Exception('Forbidden - Admin access required');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load users: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(body);
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  /// Update user role (admin only)
  /// Changes a user's role to customer, shopper, rider, or admin
  static Future<void> updateUserRole(
    String userId,
    UserRole newRole,
    String token,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_apiUrl/admin/users/$userId/role'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'user_type': newRole.value}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode == 403) {
        throw Exception('Forbidden - Admin access required');
      }

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to update user role');
      }
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  /// Toggle user active status (admin only)
  /// Activates or deactivates a user account
  static Future<void> toggleUserStatus(String userId, String token) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_apiUrl/admin/users/$userId/status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode == 403) {
        throw Exception('Forbidden - Admin access required');
      }

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Failed to toggle user status');
      }
    } catch (e) {
      throw Exception('Error toggling user status: $e');
    }
  }

  /// Get dashboard statistics (admin only)
  /// Returns counts of total users, orders, products, shoppers, and riders
  static Future<Map<String, dynamic>> getStats(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/admin/stats'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode == 403) {
        throw Exception('Forbidden - Admin access required');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      return body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error loading statistics: $e');
    }
  }

  /// Confirm payment for a pending order (admin only)
  /// Transitions order from 'pending' to 'payment_confirmed'
  static Future<bool> confirmOrderPayment(
    String orderDocumentId,
    String token,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_apiUrl/orders/$orderDocumentId/confirm-payment'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) return true;

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }
      if (response.statusCode == 403) {
        throw Exception('Forbidden - Admin access required');
      }

      final body = jsonDecode(response.body);
      throw Exception(body['error']?['message'] ?? 'Failed to confirm payment');
    } catch (e) {
      throw Exception('Error confirming payment: $e');
    }
  }

  /// Get pending orders awaiting payment confirmation (admin only)
  static Future<List<Map<String, dynamic>>> getPendingOrders(
    String token,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_apiUrl/orders?filters[status][\$eq]=pending&sort=createdAt:desc',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create staff account (shopper or rider) - admin only
  /// Requires phone, password, name, and userType
  static Future<bool> createStaff({
    required String phone,
    required String password,
    required String name,
    required String userType,
    String? email,
    required String token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/admin/create-staff'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'phone': phone,
              'password': password,
              'name': name,
              'email': email,
              'userType': userType,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode == 403) {
        throw Exception('Forbidden - Admin access required');
      }

      if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Invalid request');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to create staff account: ${response.statusCode}');
      }

      return true;
    } catch (e) {
      throw Exception('Error creating staff account: $e');
    }
  }
}
