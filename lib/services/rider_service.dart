import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class RiderService {
  static String get _apiUrl => AppConstants.apiUrl;

  static Map<String, dynamic> _normalizeSingle(dynamic body) {
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(
        body['data'] as Map<String, dynamic>,
      );
      final attributes = data['attributes'];
      if (attributes is Map<String, dynamic>) {
        return {...data, ...attributes};
      }
      return data;
    }
    if (body is Map<String, dynamic>) return body;
    return {};
  }

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

      // Flatten nested attributes structure if present
      return data
          .map((item) {
            if (item is Map<String, dynamic>) {
              final attributes = item['attributes'] as Map<String, dynamic>?;
              if (attributes != null) {
                return {
                  'id': item['id'],
                  'documentId': item['documentId'],
                  ...attributes,
                };
              }
              return item;
            }
            return item;
          })
          .cast<Map<String, dynamic>>()
          .toList();
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
      final url =
          '$_apiUrl/admin/users?filters[documentId][\$eq]=$riderId&populate=*';

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

      final item = data.first as Map<String, dynamic>;
      final attributes = item['attributes'] as Map<String, dynamic>?;
      if (attributes != null) {
        return {
          'id': item['id'],
          'documentId': item['documentId'],
          ...attributes,
        };
      }
      return item;
    } catch (e) {
      throw Exception('Error loading rider: $e');
    }
  }

  /// Source-of-truth rider profile endpoint.
  /// Uses GET /api/riders/:id and expects profile + KYC + activity fields.
  static Future<Map<String, dynamic>> getRiderProfileById(
    String riderId, {
    required String token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/riders/$riderId?populate=*'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 401) {
        throw Exception('Unauthorized - Admin access required');
      }

      if (response.statusCode == 404) {
        throw Exception('Rider profile not found');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load rider profile: ${response.statusCode}');
      }

      final parsed = jsonDecode(response.body);
      final profile = _normalizeSingle(parsed);
      if (profile.isEmpty) {
        throw Exception('Empty rider profile response');
      }
      return profile;
    } catch (e) {
      throw Exception('Error loading rider profile: $e');
    }
  }

  static Future<Map<String, dynamic>?> getRiderProfileByUser({
    required String token,
    String? userDocumentId,
    dynamic userId,
  }) async {
    Future<Map<String, dynamic>?> queryByUser(String url) async {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode != 200) return null;
      final parsed = jsonDecode(response.body);
      final data = parsed is Map<String, dynamic> ? parsed['data'] : null;
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) {
          final attrs = first['attributes'];
          if (attrs is Map<String, dynamic>) {
            return {...first, ...attrs};
          }
          return first;
        }
      }
      return null;
    }

    if (userDocumentId != null && userDocumentId.isNotEmpty) {
      final byDoc = await queryByUser(
        '$_apiUrl/riders?filters[user][documentId][\$eq]=$userDocumentId&populate=*',
      );
      if (byDoc != null) return byDoc;
    }

    final uid = userId?.toString();
    final numericUid = uid != null ? int.tryParse(uid) : null;
    if (numericUid != null) {
      final byId = await queryByUser(
        '$_apiUrl/riders?filters[user][id][\$eq]=$numericUid&populate=*',
      );
      if (byId != null) return byId;
    }

    return null;
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
          .put(Uri.parse(url), headers: headers, body: jsonEncode(data))
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

  /// Approve rider KYC. [riderDocumentId] must be the Strapi v5 documentId.
  static Future<void> verifyRider(
    String riderDocumentId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/riders/$riderDocumentId/kyc';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({'action': 'approve'});

      final response = await http
          .patch(Uri.parse(url), headers: headers, body: body)
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

  /// Unified KYC decision call. Mirrors ShopperService.submitKycDecision.
  static Future<void> submitKycDecision(
    String riderDocumentId, {
    required String token,
    required String decision,
    String? reason,
    String? adminNotes,
    List<String>? fieldsToResubmit,
  }) async {
    final url = '$_apiUrl/riders/$riderDocumentId/kyc';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'action': decision,
      if (reason != null && reason.isNotEmpty) 'rejection_reason': reason,
      if (adminNotes != null && adminNotes.isNotEmpty)
        'admin_notes': adminNotes,
      if (fieldsToResubmit != null && fieldsToResubmit.isNotEmpty)
        'fields_to_resubmit': fieldsToResubmit,
    });

    final response = await http
        .patch(Uri.parse(url), headers: headers, body: body)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 401) {
      throw Exception('Unauthorized - Admin access required');
    }
    if (response.statusCode != 200) {
      String message = 'Failed to submit decision: ${response.statusCode}';
      try {
        final parsed = jsonDecode(response.body);
        message = parsed['error']?['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Reject rider KYC. [riderDocumentId] must be the Strapi v5 documentId.
  static Future<void> unverifyRider(
    String riderDocumentId, {
    required String token,
    String? reason,
  }) async {
    try {
      final url = '$_apiUrl/riders/$riderDocumentId/kyc';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'action': 'reject',
        if (reason != null && reason.isNotEmpty) 'rejection_reason': reason,
      });

      final response = await http
          .patch(Uri.parse(url), headers: headers, body: body)
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
