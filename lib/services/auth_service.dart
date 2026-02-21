import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// Authentication Service
/// Handles phone + password authentication, OTP fallback, and JWT token management
class AuthService {
  static String get _apiUrl => AppConstants.apiUrl;

  /// Sign up with phone number and password
  /// Phone format: +256XXXXXXXXX (Uganda)
  /// Optional: name, email
  /// Returns { jwt, user: { id, phone, name, email, user_type, profile_photo } }
  /// Throws exception if signup fails
  static Future<Map<String, dynamic>> signup({
    required String phoneNumber,
    required String password,
    String? name,
    String? email,
    String userType = 'customer',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phoneNumber,
              'password': password,
              'name': name,
              'email': email,
              'userType': userType,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error']?['message'] ?? 'Failed to sign up');
      }

      final body = jsonDecode(response.body);
      return body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error signing up: $e');
    }
  }

  /// Login with phone number and password
  /// Phone format: +256XXXXXXXXX (Uganda)
  /// Returns { jwt, user: { id, phone, name, email, user_type, profile_photo } }
  /// Throws exception if login fails
  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phoneNumber, 'password': password}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(
          body['error']?['message'] ?? 'Invalid phone or password',
        );
      }

      final body = jsonDecode(response.body);
      return body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }

  /// Request OTP for phone number (Fallback authentication method)
  /// Phone format: +256XXXXXXXXX (Uganda)
  /// Throws exception if request fails
  static Future<void> sendOtp(String phoneNumber) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/otp/request'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phoneNumber}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      throw Exception('Error sending OTP: $e');
    }
  }

  /// Verify OTP and get JWT token
  /// Returns { jwt, user: { id, username, email, role } }
  /// Throws if verification fails
  static Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/otp/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phoneNumber, 'otp': otp}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Invalid OTP');
      }

      final body = jsonDecode(response.body);
      return body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error verifying OTP: $e');
    }
  }

  /// Get current authenticated user profile from backend
  /// Requires valid JWT token
  /// Returns custom user data (id, phone, name, email, user_type, profile_photo)
  static Future<Map<String, dynamic>> getMe(String jwtToken) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/auth/me'),
            headers: {
              'Authorization': 'Bearer $jwtToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Token expired or invalid');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to get user: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      return body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  /// Refresh JWT token
  /// Takes existing token and requests a new one from backend
  /// Returns { jwt, user: { ... } }
  /// Throws if refresh fails (token invalid or expired)
  static Future<Map<String, dynamic>> refreshToken(String jwtToken) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl/auth/refresh'),
            headers: {
              'Authorization': 'Bearer $jwtToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Token expired - please login again');
      }

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Failed to refresh token');
      }

      final body = jsonDecode(response.body);
      return body as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error refreshing token: $e');
    }
  }

  /// Update user profile (name, email)
  /// Requires JWT token authentication
  static Future<Map<String, dynamic>> updateUserProfile(
    String userId,
    Map<String, dynamic> data, {
    required String? jwtToken,
  }) async {
    try {
      if (jwtToken == null) {
        throw Exception('No authentication token available');
      }

      final response = await http
          .put(
            Uri.parse('$_apiUrl/users/$userId'),
            headers: {
              'Authorization': 'Bearer $jwtToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      }

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Failed to update profile');
      }

      final body = jsonDecode(response.body);
      return body is Map ? body as Map<String, dynamic> : {};
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}
