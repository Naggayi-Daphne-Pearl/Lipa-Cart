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
}
