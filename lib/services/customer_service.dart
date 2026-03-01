import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class CustomerService {
  static String get _apiUrl => AppConstants.apiUrl;

  /// Get all customers with filters
  static Future<List<Map<String, dynamic>>> getCustomers({
    required String token,
    int page = 1,
    int pageSize = 20,
    bool? isActive,
    String? search, // Search by name or phone
  }) async {
    try {
      String url =
          '$_apiUrl/admin/users?pagination[page]=$page&pagination[pageSize]=$pageSize&filters[user_type][\$eq]=customer&populate=*';

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
        throw Exception('Failed to load customers: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = body is List ? body : body['data'] ?? [];

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error loading customers: $e');
    }
  }

  /// Get single customer by ID with full details
  static Future<Map<String, dynamic>> getCustomer(
    String customerId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/admin/users?filters[documentId][\$eq]=$customerId&populate=*';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load customer: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      final List<dynamic> data = body is List ? body : body['data'] ?? [];

      if (data.isEmpty) {
        throw Exception('Customer not found');
      }

      return Map<String, dynamic>.from(data.first);
    } catch (e) {
      throw Exception('Error loading customer: $e');
    }
  }

  /// Update customer details
  static Future<Map<String, dynamic>> updateCustomer(
    String customerId,
    Map<String, dynamic> data, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/admin/users/$customerId';

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
        throw Exception('Failed to update customer: ${response.statusCode}');
      }

      final body = jsonDecode(response.body);
      return Map<String, dynamic>.from(body);
    } catch (e) {
      throw Exception('Error updating customer: $e');
    }
  }
}
