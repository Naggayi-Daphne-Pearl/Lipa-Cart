import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import 'http_client_factory.dart';

/// Extracts a user-friendly message from any exception.
String _friendlyError(Object e, String fallback) {
  if (e is http.ClientException) return 'Could not reach the server. Please try again.';
  if (e is TimeoutException) return 'Request timed out. Please try again.';
  final msg = e.toString().replaceAll(RegExp(r'Exception:\s*'), '');
  return msg.isNotEmpty ? msg : fallback;
}

/// Authentication Service
/// Handles phone + password authentication, OTP fallback, and JWT token management
class AuthService {
  static final http.Client _client = createHttpClient();
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
    bool rememberMe = true,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_apiUrl/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phoneNumber,
              'password': password,
              'name': name,
              'email': email,
              'userType': userType,
              'rememberMe': rememberMe,
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
      throw Exception(_friendlyError(e, 'Failed to sign up'));
    }
  }

  /// Login with phone number and password
  /// Phone format: +256XXXXXXXXX (Uganda)
  /// Returns { jwt, user: { id, phone, name, email, user_type, profile_photo } }
  /// Throws exception if login fails
  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_apiUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phoneNumber,
              'password': password,
              'rememberMe': rememberMe,
            }),
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
      throw Exception(_friendlyError(e, 'Failed to sign in'));
    }
  }

  /// Sign in with a Google ID token from the web consent flow.
  /// Returns either a normal auth payload or { needsSignup: true, profile: {...} }
  static Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
    bool rememberMe = true,
    String userType = 'customer',
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_apiUrl/google-auth/signin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
              'rememberMe': rememberMe,
              'userType': userType,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      final body = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
          body['error']?['message'] ??
              body['message'] ??
              'Failed to sign in with Google',
        );
      }

      return body as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_friendlyError(e, 'Failed to sign in with Google'));
    }
  }

  /// Complete a Google customer profile later by attaching a real phone number.
  static Future<Map<String, dynamic>> completeCustomerProfile({
    required String phoneNumber,
    String? name,
    String? email,
    required String jwtToken,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_apiUrl/google-auth/complete-profile'),
            headers: {
              'Authorization': 'Bearer $jwtToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'phone': phoneNumber,
              if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
              if (email != null && email.trim().isNotEmpty)
                'email': email.trim(),
            }),
          )
          .timeout(AppConstants.apiTimeout);

      final body = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(
          body['error']?['message'] ??
              body['message'] ??
              'Failed to complete customer profile',
        );
      }

      return body as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_friendlyError(e, 'Failed to complete profile'));
    }
  }

  /// Request OTP for phone number (Fallback authentication method)
  /// Phone format: +256XXXXXXXXX (Uganda)
  /// Throws exception if request fails
  static Future<void> sendOtp(String phoneNumber) async {
    try {
      final response = await _client
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
      throw Exception(_friendlyError(e, 'Failed to send verification code'));
    }
  }

  /// Verify OTP and get JWT token
  /// Returns { jwt, user: { id, username, email, role } }
  /// Throws if verification fails
  static Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp, {
    bool rememberMe = true,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_apiUrl/otp/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phoneNumber,
              'otp': otp,
              'rememberMe': rememberMe,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Invalid OTP');
      }

      final body = jsonDecode(response.body);
      return body as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_friendlyError(e, 'Failed to verify code'));
    }
  }

  /// Get current authenticated user profile from backend
  /// Requires valid JWT token
  /// Returns custom user data (id, phone, name, email, user_type, profile_photo)
  static Future<Map<String, dynamic>> getMe(String jwtToken) async {
    try {
      final response = await _client
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
      throw Exception(_friendlyError(e, 'Failed to load profile'));
    }
  }

  /// Refresh JWT token
  /// Takes existing token and requests a new one from backend
  /// Returns { jwt, user: { ... } }
  /// Throws if refresh fails (token invalid or expired)
  static Future<Map<String, dynamic>> refreshToken(
    String? jwtToken, {
    String? refreshToken,
    bool rememberMe = true,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (jwtToken != null && jwtToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwtToken';
      }

      final response = await _client
          .post(
            Uri.parse('$_apiUrl/auth/refresh'),
            headers: headers,
            body: jsonEncode({
              if (refreshToken != null && refreshToken.isNotEmpty)
                'refreshToken': refreshToken,
              'rememberMe': rememberMe,
            }),
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
      throw Exception(_friendlyError(e, 'Session expired — please sign in again'));
    }
  }

  /// Revoke the active refresh session and clear any server cookie.
  static Future<void> logout({String? jwtToken, String? refreshToken}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (jwtToken != null && jwtToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwtToken';
      }

      await _client
          .post(
            Uri.parse('$_apiUrl/auth/logout'),
            headers: headers,
            body: jsonEncode({
              if (refreshToken != null && refreshToken.isNotEmpty)
                'refreshToken': refreshToken,
            }),
          )
          .timeout(AppConstants.apiTimeout);
    } catch (_) {
      // Logout should still succeed locally even if the server revoke call fails.
    }
  }

  /// Request password reset OTP
  /// Verifies user exists and sends OTP to their phone
  static Future<void> forgotPassword(String phoneNumber) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_apiUrl/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phoneNumber}),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(
          body['error']?['message'] ?? 'No account found with this number',
        );
      }
    } catch (e) {
      throw Exception(_friendlyError(e, 'No account found with this number'));
    }
  }

  /// Reset password with OTP verification
  /// Takes phone, OTP code, and new password
  static Future<void> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_apiUrl/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phoneNumber,
              'otp': otp,
              'newPassword': newPassword,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(
          body['error']?['message'] ??
              body['error'] ??
              'Failed to reset password',
        );
      }
    } catch (e) {
      throw Exception(_friendlyError(e, 'Failed to reset password'));
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

      final response = await _client
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
      throw Exception(_friendlyError(e, 'Failed to update profile'));
    }
  }
}
