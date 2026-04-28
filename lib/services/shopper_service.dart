import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class ShopperService {
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

  /// Get all shoppers with filters
  static Future<List<Map<String, dynamic>>> getShoppers({
    required String token,
    int page = 1,
    int pageSize = 20,
    String?
    kycStatus, // 'not_submitted', 'pending_review', 'approved', 'rejected'
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
      throw Exception('Error loading shoppers: $e');
    }
  }

  /// Get single shopper by ID with full details
  static Future<Map<String, dynamic>> getShopper(
    String shopperId, {
    required String token,
  }) async {
    try {
      final url =
          '$_apiUrl/admin/users?filters[documentId][\$eq]=$shopperId&populate=*';

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
      throw Exception('Error loading shopper: $e');
    }
  }

  /// Source-of-truth shopper profile endpoint.
  /// Uses GET /api/shoppers/:id and expects profile + KYC + activity fields.
  static Future<Map<String, dynamic>> getShopperProfileById(
    String shopperId, {
    required String token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_apiUrl/shoppers/$shopperId?populate=*'),
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
        throw Exception('Shopper profile not found');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load shopper profile: ${response.statusCode}',
        );
      }

      final parsed = jsonDecode(response.body);
      final profile = _normalizeSingle(parsed);
      if (profile.isEmpty) {
        throw Exception('Empty shopper profile response');
      }
      return profile;
    } catch (e) {
      throw Exception('Error loading shopper profile: $e');
    }
  }

  static Future<Map<String, dynamic>?> getShopperProfileByUser({
    required String token,
    String? userDocumentId,
    dynamic userId,
    String? phone,
    String? email,
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

    Future<Map<String, dynamic>?> queryByUserDocId(String candidate) async {
      return queryByUser(
        '$_apiUrl/shoppers?filters[user][documentId][\$eq]=$candidate&populate=*',
      );
    }

    final docCandidates = <String>{};
    final userDoc = userDocumentId?.trim();
    if (userDoc != null && userDoc.isNotEmpty) {
      docCandidates.add(userDoc);
    }
    final uidText = userId?.toString().trim();
    if (uidText != null &&
        uidText.isNotEmpty &&
        int.tryParse(uidText) == null) {
      // Admin users list may expose user documentId in the id field.
      docCandidates.add(uidText);
    }
    for (final candidate in docCandidates) {
      final byDoc = await queryByUserDocId(candidate);
      if (byDoc != null) return byDoc;
    }

    final numericUid = uidText != null ? int.tryParse(uidText) : null;
    if (numericUid != null) {
      final byId = await queryByUser(
        '$_apiUrl/shoppers?filters[user][id][\$eq]=$numericUid&populate=*',
      );
      if (byId != null) return byId;
    }

    final phoneText = phone?.trim();
    if (phoneText != null && phoneText.isNotEmpty) {
      final byPhone = await queryByUser(
        '$_apiUrl/shoppers?filters[user][phone][\$eq]=$phoneText&populate=*',
      );
      if (byPhone != null) return byPhone;
    }

    final emailText = email?.trim();
    if (emailText != null && emailText.isNotEmpty) {
      final byEmail = await queryByUser(
        '$_apiUrl/shoppers?filters[user][email][\$eq]=$emailText&populate=*',
      );
      if (byEmail != null) return byEmail;
    }

    return null;
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
      final url =
          '$_apiUrl/shoppers?filters[user][id][\$eq]=$shopperId&populate=*';

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

  /// Approve shopper KYC. [shopperDocumentId] must be the Strapi v5 documentId.
  static Future<void> approveKyc(
    String shopperDocumentId, {
    required String token,
  }) async {
    try {
      final url = '$_apiUrl/shoppers/$shopperDocumentId/kyc';

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
        throw Exception('Failed to approve KYC: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving KYC: $e');
    }
  }

  /// Unified KYC decision call.
  /// [decision] = 'approve' | 'reject' | 'request_more_info'
  /// For 'request_more_info', [fieldsToResubmit] must be a non-empty list
  /// of field keys (e.g. 'id_photo', 'face_photo', 'license_photo').
  static Future<void> submitKycDecision(
    String shopperDocumentId, {
    required String token,
    required String decision,
    String? reason,
    String? adminNotes,
    List<String>? fieldsToResubmit,
  }) async {
    final url = '$_apiUrl/shoppers/$shopperDocumentId/kyc';
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

  /// Reject shopper KYC. [shopperDocumentId] must be the Strapi v5 documentId.
  static Future<void> rejectKyc(
    String shopperDocumentId, {
    required String token,
    String? reason,
  }) async {
    try {
      final url = '$_apiUrl/shoppers/$shopperDocumentId/kyc';

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
        throw Exception('Failed to reject KYC: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error rejecting KYC: $e');
    }
  }
}
