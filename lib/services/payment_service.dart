import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class PaymentService {
  static String get _baseUrl => AppConstants.baseUrl;
  static String? lastError;

  static String _extractErrorMessage(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;

    final error = body['error'];
    if (error is String && error.isNotEmpty) return error;
    if (error is Map<String, dynamic>) {
      final nested = error['message'];
      if (nested is String && nested.isNotEmpty) return nested;
    }

    return fallback;
  }

  static Map<String, String?> _extractFailureReason(Map<String, dynamic> payment) {
    final providerResponse = payment['provider_response'];

    Map<String, dynamic>? payload;
    if (providerResponse is List && providerResponse.isNotEmpty) {
      final first = providerResponse.first;
      if (first is Map<String, dynamic>) payload = first;
    } else if (providerResponse is Map<String, dynamic>) {
      payload = providerResponse;
    }

    final failureReason = payload?['failureReason'];
    if (failureReason is Map<String, dynamic>) {
      return {
        'failureCode': failureReason['failureCode'] as String?,
        'failureMessage': failureReason['failureMessage'] as String?,
      };
    }

    final rejectionReason = payload?['rejectionReason'];
    if (rejectionReason is Map<String, dynamic>) {
      return {
        'failureCode': rejectionReason['rejectionCode'] as String?,
        'failureMessage': rejectionReason['rejectionMessage'] as String?,
      };
    }

    return {'failureCode': null, 'failureMessage': null};
  }

  static Future<Map<String, dynamic>> initiateFlutterwaveMobileMoney({
    required String token,
    required String orderId,
    required String phoneNumber,
    String? correspondent,
    bool rollbackOrderOnFailure = false,
    bool forceRetry = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/payments/mobile-money/initiate'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'orderId': orderId,
            'phoneNumber': phoneNumber,
            if (correspondent != null) 'correspondent': correspondent,
            'rollbackOrderOnFailure': rollbackOrderOnFailure,
            'forceRetry': forceRetry,
          }),
        )
        .timeout(AppConstants.apiTimeout);

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

  static Future<Map<String, dynamic>> validateMobileMoneyDetails({
    required String token,
    required String phoneNumber,
    String? correspondent,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/payments/validate-details'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'phoneNumber': phoneNumber,
            if (correspondent != null) 'correspondent': correspondent,
          }),
        )
        .timeout(AppConstants.apiTimeout);

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
        'Failed to validate mobile money details';
    throw Exception(message);
  }

  /// Polls the backend for the current status of a PawaPay payment.
  /// Returns a map with keys: paymentStatus, orderStatus, providerStatus.
  /// On network timeout, returns paymentStatus='processing' instead of throwing.
  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String token,
    required String paymentId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/payments/$paymentId/status'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(AppConstants.apiTimeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = body['data'] as Map<String, dynamic>? ?? {};
        final payment = data['payment'] as Map<String, dynamic>? ?? {};
        final failure = _extractFailureReason(payment);
        return {
          'paymentStatus': payment['status'] as String? ?? 'processing',
          'orderStatus': data['orderStatus'] as String? ?? 'payment_processing',
          'providerStatus': data['providerStatus'] as String? ?? '',
          'failureCode': failure['failureCode'] ?? '',
          'failureMessage': failure['failureMessage'] ?? '',
        };
      }

      final error = body['error'] as Map<String, dynamic>?;
      final message =
          (error?['message'] as String?) ??
          (body['message'] as String?) ??
          'Failed to check payment status';
      throw Exception(message);
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return {
          'paymentStatus': 'processing',
          'orderStatus': 'payment_processing',
          'providerStatus': '',
          'failureCode': '',
          'failureMessage': '',
        };
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> switchToCashOnDelivery({
    required String token,
    required String orderId,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$_baseUrl/api/orders/$orderId/switch-to-cod'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(AppConstants.apiTimeout);

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
        'Failed to switch to cash on delivery';
    throw Exception(message);
  }

  /// Verify delivery code for an order
  /// Rider enters the 4-digit code to confirm delivery
  static Future<bool> verifyDeliveryCode(
    String orderId,
    String code, {
    double? gpsLat,
    double? gpsLng,
    String? photoUrl,
  }) async {
    try {
      lastError = null;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/orders/$orderId/verify-delivery-code'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'code': code,
              if (gpsLat != null) 'gps_lat': gpsLat,
              if (gpsLng != null) 'gps_lng': gpsLng,
              if (photoUrl != null) 'photo_url': photoUrl,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      lastError = _extractErrorMessage(
        body,
        fallback: 'Code verification failed',
      );

      // Extract attempt info if available
      final attemptsRemaining = body['attempts_remaining'];
      if (attemptsRemaining != null) {
        lastError = '$lastError (${attemptsRemaining} attempts remaining)';
      }

      return false;
    } catch (e) {
      lastError = 'Failed to verify code: ${e.toString()}';
      return false;
    }
  }

  /// Resend delivery code to customer
  /// Method can be 'sms', 'push', or 'whatsapp'
  static Future<bool> resendDeliveryCode(
    String orderId,
    String method,
    {String? token}
  ) async {
    try {
      lastError = null;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/orders/$orderId/resend-delivery-code'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'method': method,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      lastError = _extractErrorMessage(
        body,
        fallback: 'Failed to resend code',
      );
      return false;
    } catch (e) {
      lastError = 'Failed to resend code: ${e.toString()}';
      return false;
    }
  }

  /// Forward delivery code to third party (gift scenario)
  static Future<bool> forwardDeliveryCode(
    String orderId,
    String recipientPhone,
    {String? token}
  ) async {
    try {
      lastError = null;

      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/orders/$orderId/forward-delivery-code'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'recipient_phone': recipientPhone,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      lastError = _extractErrorMessage(
        body,
        fallback: 'Failed to forward code',
      );
      return false;
    } catch (e) {
      lastError = 'Failed to forward code: ${e.toString()}';
      return false;
    }
  }
}
