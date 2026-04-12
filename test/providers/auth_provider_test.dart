import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lipa_cart/providers/auth_provider.dart';
import 'package:lipa_cart/models/user.dart';
import 'package:lipa_cart/core/constants/app_constants.dart';

/// Mock FlutterSecureStorage method channel for unit tests.
/// Stores values in a simple map to simulate the plugin.
void setupSecureStorageMock({Map<String, String>? initialValues}) {
  final storage = <String, String>{};
  if (initialValues != null) storage.addAll(initialValues);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'read':
          final key = methodCall.arguments['key'] as String;
          return storage[key];
        case 'write':
          final key = methodCall.arguments['key'] as String;
          final value = methodCall.arguments['value'] as String;
          storage[key] = value;
          return null;
        case 'delete':
          final key = methodCall.arguments['key'] as String;
          storage.remove(key);
          return null;
        case 'deleteAll':
          storage.clear();
          return null;
        case 'readAll':
          return storage;
        default:
          return null;
      }
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset secure storage mock before each test
    setupSecureStorageMock();
  });

  group('AuthProvider - auto login from stored session', () {
    test('restores authenticated state from saved token and user', () async {
      final testUser = User(
        id: '1',
        phoneNumber: '+256700000000',
        name: 'Test',
        role: UserRole.customer,
        customerId: 'c-1',
        createdAt: DateTime(2026),
      );

      final sessionMetadata = {
        'rememberMe': true,
        'issuedAt': DateTime.now().toIso8601String(),
        'expiresAt':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'lastRefreshAt': DateTime.now().toIso8601String(),
      };

      // Store token in secure storage mock
      setupSecureStorageMock(initialValues: {
        AppConstants.tokenKey: 'test-jwt-token',
      });

      SharedPreferences.setMockInitialValues({
        AppConstants.userKey: jsonEncode(testUser.toJson()),
        AppConstants.sessionMetadataKey: jsonEncode(sessionMetadata),
      });

      final provider = AuthProvider();
      // Allow bootstrap to complete (tryAutoLogin is async)
      await Future.delayed(const Duration(seconds: 1));

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, isNotNull);
      expect(provider.user!.phoneNumber, '+256700000000');
      expect(provider.user!.role, UserRole.customer);
      expect(provider.token, 'test-jwt-token');
    });

    test('sets unauthenticated when no saved token', () async {
      SharedPreferences.setMockInitialValues({});

      final provider = AuthProvider();
      await Future.delayed(const Duration(seconds: 1));

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(provider.token, isNull);
    });

    test('sets unauthenticated when session is expired', () async {
      final testUser = User(
        id: '1',
        phoneNumber: '+256700000000',
        role: UserRole.customer,
        createdAt: DateTime(2026),
      );

      final expiredSession = {
        'rememberMe': true,
        'issuedAt':
            DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        'expiresAt':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'lastRefreshAt':
            DateTime.now().subtract(const Duration(days: 31)).toIso8601String(),
      };

      setupSecureStorageMock(initialValues: {
        AppConstants.tokenKey: 'expired-token',
      });

      SharedPreferences.setMockInitialValues({
        AppConstants.userKey: jsonEncode(testUser.toJson()),
        AppConstants.sessionMetadataKey: jsonEncode(expiredSession),
      });

      final provider = AuthProvider();
      await Future.delayed(const Duration(seconds: 1));

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.errorMessage, contains('expired'));
    });
  });

  group('AuthProvider - state helpers', () {
    test('isAuthenticated reflects status', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AuthProvider();
      await Future.delayed(const Duration(seconds: 1));

      expect(provider.isAuthenticated, false);
    });

    test('needsPhoneNumber returns true for invalid phone format', () async {
      final testUser = User(
        id: '1',
        phoneNumber: 'not-a-phone',
        role: UserRole.customer,
        createdAt: DateTime(2026),
      );

      setupSecureStorageMock(initialValues: {
        AppConstants.tokenKey: 'valid-token',
      });

      final session = {
        'rememberMe': true,
        'issuedAt': DateTime.now().toIso8601String(),
        'expiresAt':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'lastRefreshAt': DateTime.now().toIso8601String(),
      };

      SharedPreferences.setMockInitialValues({
        AppConstants.userKey: jsonEncode(testUser.toJson()),
        AppConstants.sessionMetadataKey: jsonEncode(session),
      });

      final provider = AuthProvider();
      await Future.delayed(const Duration(seconds: 1));

      expect(provider.needsPhoneNumber, true);
    });

    test('needsPhoneNumber returns false for valid +256 phone', () async {
      final testUser = User(
        id: '1',
        phoneNumber: '+256712345678',
        role: UserRole.customer,
        createdAt: DateTime(2026),
      );

      setupSecureStorageMock(initialValues: {
        AppConstants.tokenKey: 'valid-token',
      });

      final session = {
        'rememberMe': true,
        'issuedAt': DateTime.now().toIso8601String(),
        'expiresAt':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'lastRefreshAt': DateTime.now().toIso8601String(),
      };

      SharedPreferences.setMockInitialValues({
        AppConstants.userKey: jsonEncode(testUser.toJson()),
        AppConstants.sessionMetadataKey: jsonEncode(session),
      });

      final provider = AuthProvider();
      await Future.delayed(const Duration(seconds: 1));

      expect(provider.needsPhoneNumber, false);
    });

    test('updateKycStatus updates user KYC locally', () async {
      final testUser = User(
        id: '1',
        phoneNumber: '+256712345678',
        role: UserRole.shopper,
        kycStatus: 'not_submitted',
        createdAt: DateTime(2026),
      );

      setupSecureStorageMock(initialValues: {
        AppConstants.tokenKey: 'valid-token',
      });

      final session = {
        'rememberMe': true,
        'issuedAt': DateTime.now().toIso8601String(),
        'expiresAt':
            DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'lastRefreshAt': DateTime.now().toIso8601String(),
      };

      SharedPreferences.setMockInitialValues({
        AppConstants.userKey: jsonEncode(testUser.toJson()),
        AppConstants.sessionMetadataKey: jsonEncode(session),
      });

      final provider = AuthProvider();
      await Future.delayed(const Duration(seconds: 1));

      provider.updateKycStatus('pending_review');
      expect(provider.user!.kycStatus, 'pending_review');
    });
  });

  group('AuthProvider - first launch', () {
    test('detects first launch when onboarding key not set', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AuthProvider();
      await Future.delayed(const Duration(seconds: 1));

      expect(provider.isFirstLaunch, true);
    });

    test('detects returning user when onboarding key set', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.onboardingKey: true,
      });
      final provider = AuthProvider();
      await Future.delayed(const Duration(seconds: 1));

      expect(provider.isFirstLaunch, false);
    });
  });

  group('GoogleSignInResult', () {
    test('creates success result', () {
      const result = GoogleSignInResult(success: true);
      expect(result.success, true);
      expect(result.needsSignup, false);
    });

    test('creates needsSignup result with profile data', () {
      const result = GoogleSignInResult(
        success: false,
        needsSignup: true,
        email: 'test@gmail.com',
        name: 'Test User',
        pictureUrl: 'https://example.com/photo.jpg',
      );
      expect(result.needsSignup, true);
      expect(result.email, 'test@gmail.com');
    });
  });
}
