import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class PaymentService {
  static String get _baseUrl => AppConstants.baseUrl;

  static Future<Map<String, dynamic>> initiatePawaPayMobileMoney({
    required String token,
    required String orderId,
    required String phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/payments/mobile-money/initiate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'orderId': orderId,
        'phoneNumber': phoneNumber,
      }),
    );

    final body = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = body['error'] as Map<String, dynamic>?;
    final message =
        (error?['message'] as String?) ??
        (body['message'] as String?) ??
        'Failed to initiate mobile money payment';
    throw Exception(message);
  }
}
