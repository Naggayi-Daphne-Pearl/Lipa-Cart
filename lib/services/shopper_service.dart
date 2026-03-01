import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class ShopperService {
  static String get _apiUrl => AppConstants.apiUrl;

  /// Get all shoppers with filters
  static Future<List<Map<String, dynamic>>> getShoppers({
    required String token,
    int page = 1,
    int pageSize = 20,
    String? kycStatus, // 'not_submitted', 'pending_review', 'approved', 'rejected'
    bool? isActive,
    String? search, // Search by name or phone
  }) async {
    try {
      String url =
          '$_apiUrl/admin/users?pagination[page]=$page&pagination[pageSize]=$pageSize&filters[user_type][\$eq]=shopper&populate=*';

      if (kycStatus != null && kycStatus.isNotEmpty) {
        url += '&filters[shopper][kyc_status][\$eq]=$kycStatus';
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
        throw Exception('Failed to load shoppers: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = body is List ? body : body['data'] ?? [];

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error loading shoppers: $e');
    }
  }

  /// Get single shopper by ID with full details
  static Future<Map<String, dynamic>> getShopper(
    String shopperId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/admin/users?filters[documentId][\$eq]=$shopperId&populate=*';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load shopper: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = body is List ? body : body['data'] ?? [];

      if (data.isEmpty) {
        throw Exception('Shopper not found');
      }

      return Map<String, dynamic>.from(data.first);
    } catch (e) {
      throw Exception('Error loading shopper: $e');
    }
  }

  /// Update shopper details
  static Future<Map<String, dynamic>> updateShopper(
    String shopperId,
    Map<String, dynamic> data, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/admin/users/$shopperId';

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
        throw Exception('Failed to update shopper: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      return Map<String, dynamic>.from(body);
    } catch (e) {
      throw Exception('Error updating shopper: $e');
    }
  }

  /// Get shopper's KYC details
  static Future<Map<String, dynamic>> getShopperKyc(
    String shopperId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/shoppers?filters[user][id][\$eq]=$shopperId&populate=*';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load KYC details: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? [];

      if (data.isEmpty) {
        return {};
      }

      return Map<String, dynamic>.from(data.first);
    } catch (e) {
      throw Exception('Error loading KYC details: $e');
    }
  }

  /// Approve KYC for shopper (admin endpoint)
  static Future<void> approveKyc(
    String shopperId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/admin/shoppers/$shopperId/kyc-approve';

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
        throw Exception('Failed to approve KYC: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving KYC: $e');
    }
  }

  /// Reject KYC for shopper (admin endpoint)
  static Future<void> rejectKyc(
    String shopperId, {
    required String token,
    String? reason,
  }) async {
    try {
      final url = '$_apiUrl/admin/shoppers/$shopperId/kyc-reject';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({'reason': reason});

      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to reject KYC: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error rejecting KYC: $e');
    }
  }
}
