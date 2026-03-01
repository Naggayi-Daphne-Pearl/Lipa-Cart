import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class RiderService {
  static String get _apiUrl => AppConstants.apiUrl;

  /// Get all riders with filters
  static Future<List<Map<String, dynamic>>> getRiders({
    required String token,
    int page = 1,
    int pageSize = 20,
    bool? isVerified,
    bool? isActive,
    String? search, // Search by name or phone
  }) async {
    try {
      String url =
          '$_apiUrl/admin/users?pagination[page]=$page&pagination[pageSize]=$pageSize&filters[user_type][\$eq]=rider&populate=*';

      if (isVerified != null) {
        url += '&filters[is_verified][\$eq]=${isVerified.toString()}';
      }

      if (isActive != null) {
        url += '&filters[is_active][\$eq]=${isActive.toString()}';
      }

      if (search != null && search.isNotEmpty) {
        url += '&filters[\$or][0][name][\$containsi]=$search';
        url += '&filters[\$or][1][phone][\$containsi]=$search';
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load riders: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = body is List ? body : body['data'] ?? [];

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error loading riders: $e');
    }
  }

  /// Get single rider by ID with full details
  static Future<Map<String, dynamic>> getRider(
    String riderId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/admin/users?filters[documentId][\$eq]=$riderId&populate=*';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load rider: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = body is List ? body : body['data'] ?? [];

      if (data.isEmpty) {
        throw Exception('Rider not found');
      }

      return Map<String, dynamic>.from(data.first);
    } catch (e) {
      throw Exception('Error loading rider: $e');
    }
  }

  /// Update rider details
  static Future<Map<String, dynamic>> updateRider(
    String riderId,
    Map<String, dynamic> data, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/admin/users/$riderId';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Validation error');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to update rider: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      return Map<String, dynamic>.from(body);
    } catch (e) {
      throw Exception('Error updating rider: $e');
    }
  }

  /// Verify rider
  static Future<void> verifyRider(
    String riderId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/admin/riders/$riderId/verify';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(Uri.parse(url), headers: headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to verify rider: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error verifying rider: $e');
    }
  }

  /// Unverify rider
  static Future<void> unverifyRider(
    String riderId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/admin/riders/$riderId/unverify';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(Uri.parse(url), headers: headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to unverify rider: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error unverifying rider: $e');
    }
  }
}
