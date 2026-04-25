import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/strapi_service.dart';
import '../core/constants/app_constants.dart';
import '../services/web_cookie_storage_stub.dart'
    if (dart.library.html) '../services/web_cookie_storage.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  error,
}

class GoogleSignInResult {
  final bool success;
  final bool needsSignup;
  final bool needsPhoneNumber;
  final String? email;
  final String? name;
  final String? pictureUrl;

  const GoogleSignInResult({
    required this.success,
    this.needsSignup = false,
    this.needsPhoneNumber = false,
    this.email,
    this.name,
    this.pictureUrl,
  });
}

class AuthProvider extends ChangeNotifier {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _legacyTokenKey = 'auth_token';

  AuthProvider() {
    _bootstrap();
  }

  Future<String?> _readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final cookieToken = WebCookieStorage.read(AppConstants.tokenKey);
      if (cookieToken != null && cookieToken.isNotEmpty) {
        return cookieToken;
      }

      final legacyToken = prefs.getString(_legacyTokenKey);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        WebCookieStorage.write(AppConstants.tokenKey, legacyToken);
        await prefs.remove(_legacyTokenKey);
        return legacyToken;
      }

      return null;
    }
    return _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<void> _writeToken(String token, {int maxAgeDays = 30}) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      WebCookieStorage.write(
        AppConstants.tokenKey,
        token,
        maxAgeDays: maxAgeDays,
      );
      await prefs.remove(_legacyTokenKey);
      return;
    }
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<void> _deleteToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      WebCookieStorage.delete(AppConstants.tokenKey);
      await prefs.remove(_legacyTokenKey);
      return;
    }
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  Future<String?> _readRefreshToken() async {
    if (kIsWeb) {
      return WebCookieStorage.read(AppConstants.refreshTokenKey);
    }
    return _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> _writeRefreshToken(String? token, {int maxAgeDays = 30}) async {
    if (token == null || token.isEmpty) return;

    if (kIsWeb) {
      return;
    }

    await _secureStorage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<void> _deleteRefreshToken() async {
    if (kIsWeb) {
      WebCookieStorage.delete(AppConstants.refreshTokenKey);
      return;
    }
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
  }

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _errorMessage;
  bool _isFirstLaunch = true;
  bool _didBootstrap = false;

  static const Duration _standardSessionLifetime = Duration(days: 14);
  static const Duration _rememberedSessionLifetime = Duration(days: 30);
  static const Duration _silentRefreshInterval = Duration(minutes: 45);

  Future<void> _persistSessionMetadata({
    bool rememberMe = true,
    DateTime? issuedAt,
    DateTime? lastRefreshAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final sessionStart = issuedAt ?? now;
    final expiry = sessionStart.add(
      rememberMe ? _rememberedSessionLifetime : _standardSessionLifetime,
    );

    await prefs.setString(
      AppConstants.sessionMetadataKey,
      jsonEncode({
        'rememberMe': rememberMe,
        'issuedAt': sessionStart.toIso8601String(),
        'expiresAt': expiry.toIso8601String(),
        'lastRefreshAt': (lastRefreshAt ?? now).toIso8601String(),
      }),
    );
  }

  Future<Map<String, dynamic>?> _readSessionMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.sessionMetadataKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }

  Future<void> _clearSessionMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.sessionMetadataKey);
  }

  bool _isSessionExpired(Map<String, dynamic>? metadata) {
    final expiresAtRaw = metadata?['expiresAt'] as String?;
    if (expiresAtRaw == null || expiresAtRaw.isEmpty) return false;

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) return false;

    return DateTime.now().isAfter(expiresAt);
  }

  bool _shouldSilentRefresh(Map<String, dynamic>? metadata) {
    if (metadata == null) return true;

    final lastRefreshRaw = metadata['lastRefreshAt'] as String?;
    final lastRefreshAt = lastRefreshRaw != null
        ? DateTime.tryParse(lastRefreshRaw)
        : null;

    if (lastRefreshAt == null) return true;

    return DateTime.now().difference(lastRefreshAt) >= _silentRefreshInterval;
  }

  Future<void> _clearLocalSession({
    String? errorMessage,
    bool notify = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _deleteToken();
    await _deleteRefreshToken();
    await prefs.remove(AppConstants.userKey);
    await _clearSessionMetadata();

    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = errorMessage;

    if (notify) {
      notifyListeners();
    }
  }

  Future<bool> ensureSessionAvailableForSwitch() async {
    if (_status != AuthStatus.authenticated || _user == null) {
      await _clearLocalSession(
        errorMessage: 'Session ended in another tab. Please sign in again.',
      );
      return false;
    }

    final token = await _readToken();
    final refreshToken = await _readRefreshToken();
    final hasToken = token != null && token.isNotEmpty;
    final hasRefreshToken = refreshToken != null && refreshToken.isNotEmpty;

    if (!hasToken && !hasRefreshToken) {
      await _clearLocalSession(
        errorMessage: 'Session ended in another tab. Please sign in again.',
      );
      return false;
    }

    return true;
  }

  Future<void> _enforceBackendRoleTruth() async {
    if (_token == null || _user == null) return;

    try {
      final me = await AuthService.getMe(_token!);
      final roleRaw = me['user_type'] ?? me['role'];
      if (roleRaw == null || roleRaw.toString().trim().isEmpty) {
        await _clearLocalSession(
          errorMessage: 'Unable to verify account role. Please sign in again.',
        );
        return;
      }

      final backendRole = UserRoleExtension.fromString(
        roleRaw.toString(),
      );

      if (backendRole != _user!.role) {
        await _clearLocalSession(
          errorMessage: 'Your account role changed. Please sign in again.',
        );
      }
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('401') ||
          text.contains('expired') ||
          text.contains('invalid') ||
          text.contains('unauthorized')) {
        await _clearLocalSession(
          errorMessage: 'Session expired. Please login again.',
        );
      }
    }
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get needsPhoneNumber {
    final phone = _user?.phoneNumber.trim() ?? '';
    return _user != null &&
        _user!.role == UserRole.customer &&
        !RegExp(r'^\+256\d{9}$').hasMatch(phone);
  }

  /// Update KYC status locally without a backend call
  void updateKycStatus(String kycStatus) {
    if (_user != null) {
      _user = _user!.copyWith(kycStatus: kycStatus);
      notifyListeners();
    }
  }

  Future<void> _bootstrap() async {
    if (_didBootstrap) return;
    _didBootstrap = true;
    await initializeFirstLaunch();
    await tryAutoLogin();
  }

  /// Register FCM device token with backend after successful authentication.
  /// Runs in the background — failures are non-blocking.
  Future<void> _registerPushToken() async {
    if (_token == null) return;
    try {
      final notificationService = NotificationService();
      final granted = await notificationService.requestPermission();
      if (!granted) return;
      await notificationService.registerTokenWithBackend(_token!);
      notificationService.listenForTokenRefresh(_token!);
    } catch (e) {
      debugPrint('[auth] FCM token registration failed: $e');
    }
  }

  /// Check for existing session and restore if valid
  /// Called on app startup
  Future<bool> tryAutoLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = await _readToken();
      final savedUserJson = prefs.getString(AppConstants.userKey);
      final sessionMetadata = await _readSessionMetadata();

      if (_isSessionExpired(sessionMetadata)) {
        await _clearLocalSession(errorMessage: 'Session expired. Please login again.');
        return false;
      }

      _token = savedToken;
      if (savedUserJson != null && savedUserJson.isNotEmpty) {
        final userJson = jsonDecode(savedUserJson) as Map<String, dynamic>;
        _user = User.fromJson(userJson);
      }

      if (_token == null || _user == null) {
        final refreshed = await refreshToken(silent: true);
        if (!refreshed || _token == null || _user == null) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return false;
        }
      }

      if (sessionMetadata == null) {
        await _persistSessionMetadata();
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      _registerPushToken(); // non-blocking
      Future.microtask(_enforceBackendRoleTruth);

      if (_shouldSilentRefresh(sessionMetadata)) {
        Future.microtask(() => refreshToken(silent: true));
      }

      return true;
    } catch (e) {
      await _clearLocalSession(errorMessage: 'Session expired. Please login again.');
      return false;
    }
  }

  Future<bool> refreshSessionIfNeeded({bool force = false}) async {
    if (_token == null || _user == null) return false;

    final sessionMetadata = await _readSessionMetadata();

    if (_isSessionExpired(sessionMetadata)) {
      _errorMessage = 'Session expired. Please login again.';
      await logout();
      return false;
    }

    if (!force && !_shouldSilentRefresh(sessionMetadata)) {
      return true;
    }

    return refreshToken(silent: true);
  }

  /// Sign up with phone number and password
  Future<bool> signup({
    required String phoneNumber,
    required String password,
    String? name,
    String? email,
    String userType = 'customer',
    bool rememberMe = true,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.signup(
        phoneNumber: phoneNumber,
        password: password,
        name: name,
        email: email,
        userType: userType,
        rememberMe: rememberMe,
      );

      final jwt = response['jwt'] as String;
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>;

      // Save JWT to secure storage
      final prefs = await SharedPreferences.getInstance();
      await _writeToken(jwt, maxAgeDays: rememberMe ? 30 : 14);
      await _writeRefreshToken(refreshToken, maxAgeDays: rememberMe ? 30 : 14);

      // Create User object
      _token = jwt;
      _user = User(
        id: (userData['id'] ?? userData['documentId'] ?? '').toString(),
        documentId: (userData['documentId'] ?? userData['document_id'])
            ?.toString(),
        phoneNumber: (userData['phone'] ?? phoneNumber).toString(),
        email: userData['email'],
        role: UserRoleExtension.fromString(userData['user_type'] ?? userType),
        name: userData['name'],
        profileImage: userData['profile_photo'],
        isPremium:
            userData['isPremium'] as bool? ??
            userData['is_premium'] as bool? ??
            false,
        customerId: userData['customer_id']?.toString(),
        shopperId: userData['shopper_id']?.toString(),
        riderId: userData['rider_id']?.toString(),
        kycStatus: userData['kyc_status'] as String?,
        kycRejectionReason: userData['kyc_rejection_reason'] as String?,
        createdAt: DateTime.now(),
      );

      // Save user data to SharedPreferences
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      await _persistSessionMetadata(rememberMe: rememberMe);

      _status = AuthStatus.authenticated;
      notifyListeners();
      _registerPushToken(); // non-blocking
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Login with phone number and password
  Future<bool> login({
    required String phoneNumber,
    required String password,
    bool rememberMe = true,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.login(
        phoneNumber: phoneNumber,
        password: password,
        rememberMe: rememberMe,
      );

      final jwt = response['jwt'] as String;
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>;

      // Save JWT to secure storage
      final prefs = await SharedPreferences.getInstance();
      await _writeToken(jwt, maxAgeDays: rememberMe ? 30 : 14);
      await _writeRefreshToken(refreshToken, maxAgeDays: rememberMe ? 30 : 14);

      // Create User object
      _token = jwt;
      _user = User(
        id: (userData['id'] ?? userData['documentId'] ?? '').toString(),
        documentId: (userData['documentId'] ?? userData['document_id'])
            ?.toString(),
        phoneNumber: (userData['phone'] ?? phoneNumber).toString(),
        email: userData['email'],
        role: UserRoleExtension.fromString(userData['user_type'] ?? 'customer'),
        name: userData['name'],
        profileImage: userData['profile_photo'],
        isPremium:
            userData['isPremium'] as bool? ??
            userData['is_premium'] as bool? ??
            false,
        customerId: userData['customer_id']?.toString(),
        shopperId: userData['shopper_id']?.toString(),
        riderId: userData['rider_id']?.toString(),
        kycStatus: userData['kyc_status'] as String?,
        kycRejectionReason: userData['kyc_rejection_reason'] as String?,
        createdAt: DateTime.now(),
      );

      // Save user data to SharedPreferences
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      await _persistSessionMetadata(rememberMe: rememberMe);

      _status = AuthStatus.authenticated;
      notifyListeners();
      _registerPushToken(); // non-blocking
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google on web and either restore a backend session or
  /// return prefill details for a new sign-up.
  Future<GoogleSignInResult> signInWithGoogle(
    String idToken, {
    bool rememberMe = true,
    String userType = 'customer',
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.googleSignIn(
        idToken: idToken,
        rememberMe: rememberMe,
        userType: userType,
      );

      if (response['needsSignup'] == true) {
        final profile = (response['profile'] as Map<String, dynamic>?) ?? {};
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        notifyListeners();
        return GoogleSignInResult(
          success: false,
          needsSignup: true,
          email: profile['email']?.toString(),
          name: profile['name']?.toString(),
          pictureUrl: profile['picture']?.toString(),
        );
      }

      final jwt = response['jwt'] as String;
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await _writeToken(jwt, maxAgeDays: rememberMe ? 30 : 14);
      await _writeRefreshToken(refreshToken, maxAgeDays: rememberMe ? 30 : 14);

      _token = jwt;
      _user = User(
        id: (userData['id'] ?? userData['documentId'] ?? '').toString(),
        documentId: (userData['documentId'] ?? userData['document_id'])
            ?.toString(),
        phoneNumber: (userData['phone'] ?? '').toString(),
        email: userData['email'],
        role: UserRoleExtension.fromString(userData['user_type'] ?? userType),
        name: userData['name'],
        profileImage: userData['profile_photo'],
        isPremium:
            userData['isPremium'] as bool? ??
            userData['is_premium'] as bool? ??
            false,
        customerId: userData['customer_id']?.toString(),
        shopperId: userData['shopper_id']?.toString(),
        riderId: userData['rider_id']?.toString(),
        kycStatus: userData['kyc_status'] as String?,
        kycRejectionReason: userData['kyc_rejection_reason'] as String?,
        createdAt: DateTime.now(),
      );

      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      await _persistSessionMetadata(rememberMe: rememberMe);

      _status = AuthStatus.authenticated;
      notifyListeners();
      _registerPushToken();
      return GoogleSignInResult(
        success: true,
        needsPhoneNumber: userData['needs_phone_number'] as bool? ?? false,
      );
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return const GoogleSignInResult(success: false);
    }
  }

  /// Save a real customer phone number after a Google-authenticated sign-in.
  Future<bool> completeCustomerProfile({
    required String phoneNumber,
    String? name,
    String? email,
  }) async {
    if (_token == null || _user == null) return false;

    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.completeCustomerProfile(
        phoneNumber: phoneNumber,
        name: name ?? _user!.name,
        email: email ?? _user!.email,
        jwtToken: _token!,
      );

      final userData = response['user'] as Map<String, dynamic>;
      _user = _user!.copyWith(
        phoneNumber: (userData['phone'] ?? phoneNumber).toString(),
        name: userData['name'] as String? ?? _user!.name,
        email: userData['email'] as String? ?? _user!.email,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Send OTP to phone number (Fallback authentication)
  Future<void> sendOtp(String phoneNumber) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.sendOtp(phoneNumber);
      _status = AuthStatus.otpSent;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  /// Verify OTP and authenticate user
  Future<bool> verifyOtp(
    String otp,
    String phoneNumber, {
    bool rememberMe = true,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.verifyOtp(
        phoneNumber,
        otp,
        rememberMe: rememberMe,
      );

      final jwt = response['jwt'] as String;
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>;

      // Save JWT to secure storage
      final prefs = await SharedPreferences.getInstance();
      await _writeToken(jwt, maxAgeDays: rememberMe ? 30 : 14);
      await _writeRefreshToken(refreshToken, maxAgeDays: rememberMe ? 30 : 14);

      // Create User object with role from response
      _token = jwt;
      _user = User(
        id: (userData['id'] ?? userData['documentId'] ?? '').toString(),
        documentId: (userData['documentId'] ?? userData['document_id'])
            ?.toString(),
        phoneNumber: (userData['phone'] ?? phoneNumber).toString(),
        email: userData['email'],
        role: UserRoleExtension.fromString(userData['user_type'] ?? 'customer'),
        name: userData['name'],
        profileImage: userData['profile_photo'],
        isPremium:
            userData['isPremium'] as bool? ??
            userData['is_premium'] as bool? ??
            false,
        customerId: userData['customer_id']?.toString(),
        shopperId: userData['shopper_id']?.toString(),
        riderId: userData['rider_id']?.toString(),
        kycStatus: userData['kyc_status'] as String?,
        kycRejectionReason: userData['kyc_rejection_reason'] as String?,
        createdAt: DateTime.now(),
      );

      // Save user data to SharedPreferences
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      await _persistSessionMetadata(rememberMe: rememberMe);

      _status = AuthStatus.authenticated;
      notifyListeners();
      _registerPushToken(); // non-blocking
      return true;
    } catch (e) {
      _status = AuthStatus.otpSent;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Request forgot password OTP (verifies user exists first)
  Future<bool> forgotPassword(String phoneNumber) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.forgotPassword(phoneNumber);
      _status = AuthStatus.otpSent;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Request forgot password by email (link/code delivery handled by backend)
  Future<bool> forgotPasswordByEmail(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.forgotPasswordByEmail(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Reset password with OTP + new password (no auth needed)
  Future<bool> resetPassword({
    required String phoneNumber,
    required String otp,
    required String newPassword,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.resetPassword(
        phoneNumber: phoneNumber,
        otp: otp,
        newPassword: newPassword,
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Reset password with email + OTP + new password (no auth needed)
  Future<bool> resetPasswordWithEmail({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthService.resetPasswordWithEmail(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Mark onboarding as complete and persist to SharedPreferences
  Future<void> setFirstLaunchComplete() async {
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    notifyListeners();
  }

  /// Restore isFirstLaunch from SharedPreferences
  Future<void> initializeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = !prefs.containsKey(AppConstants.onboardingKey);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? password,
    UserRole? userType,
  }) async {
    if (_user == null) return;

    try {
      // Update backend
      final userId = _user!.id;
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (password != null) updateData['password'] = password;
      if (userType != null) updateData['user_type'] = userType.name;

      if (updateData.isNotEmpty) {
        await AuthService.updateUserProfile(
          userId,
          updateData,
          jwtToken: _token,
        );
      }

      // Update local state
      _user = _user!.copyWith(
        name: name ?? _user!.name,
        email: email ?? _user!.email,
        role: userType ?? _user!.role,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (_token == null) return;

    try {
      final response = await AuthService.getMe(_token!);

      if (_user == null) {
        _user = User(
          id: (response['id'] ?? response['documentId'] ?? '').toString(),
          documentId: (response['documentId'] ?? response['document_id'])
              ?.toString(),
          phoneNumber: (response['phone'] ?? '').toString(),
          email: response['email'],
          role: UserRoleExtension.fromString(
            response['user_type'] ?? response['role'],
          ),
          name: response['name'],
          profileImage: response['profile_photo'],
          isPremium:
              response['isPremium'] as bool? ??
              response['is_premium'] as bool? ??
              false,
          customerId: response['customer_id']?.toString(),
          shopperId: response['shopper_id']?.toString(),
          riderId: response['rider_id']?.toString(),
          kycStatus: response['kyc_status'] as String?,
          kycRejectionReason: response['kyc_rejection_reason'] as String?,
          createdAt: DateTime.now(),
        );
      } else {
        _user = _user!.copyWith(
          id: (response['id'] ?? response['documentId'] ?? _user!.id)
              .toString(),
          documentId:
              (response['documentId'] ?? response['document_id'])?.toString() ??
              _user!.documentId,
          phoneNumber: (response['phone'] ?? _user!.phoneNumber).toString(),
          email: response['email'] ?? _user!.email,
          role: UserRoleExtension.fromString(
            response['user_type'] ?? response['role'] ?? _user!.role.name,
          ),
          name: response['name'] ?? _user!.name,
          profileImage: response['profile_photo'] ?? _user!.profileImage,
          isPremium:
              response['isPremium'] as bool? ??
              response['is_premium'] as bool? ??
              _user!.isPremium,
          customerId: response['customer_id']?.toString() ?? _user!.customerId,
          shopperId: response['shopper_id']?.toString() ?? _user!.shopperId,
          riderId: response['rider_id']?.toString() ?? _user!.riderId,
          kycStatus: (response['kyc_status'] as String?) ?? _user!.kycStatus,
          kycRejectionReason:
              (response['kyc_rejection_reason'] as String?) ??
              _user!.kycRejectionReason,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh profile: $e';
      notifyListeners();
    }
  }

  /// Logout and clear stored session
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final refreshToken = await _readRefreshToken();

      if (_token != null) {
        await NotificationService().unregisterTokenWithBackend(_token!);
      }

      if (_token != null && _user != null) {
        if (_user!.role == UserRole.shopper && _user!.shopperId != null) {
          await StrapiService.updateShopperStatus(
            _user!.shopperId!,
            false,
            _token!,
          );
        } else if (_user!.role == UserRole.rider && _user!.riderId != null) {
          await StrapiService.updateRiderStatus(
            _user!.riderId!,
            false,
            _token!,
          );
        }
      }

      await AuthService.logout(jwtToken: _token, refreshToken: refreshToken);
    } catch (e) {
      debugPrint('[auth] Failed to set worker offline during logout: $e');
    }

    await _deleteToken();
    await _deleteRefreshToken();
    await prefs.remove(AppConstants.userKey);
    await _clearSessionMetadata();

    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Refresh JWT token
  /// Call this when token is about to expire or after receiving 401
  Future<bool> refreshToken({bool silent = false}) async {
    try {
      final sessionMetadata = await _readSessionMetadata();
      final rememberMe = sessionMetadata?['rememberMe'] as bool? ?? true;
      final savedRefreshToken = await _readRefreshToken();
      final response = await AuthService.refreshToken(
        _token,
        refreshToken: savedRefreshToken,
        rememberMe: rememberMe,
      );

      final jwt = response['jwt'] as String;
      final rotatedRefreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>;
      final resolvedRole = UserRoleExtension.fromString(
        userData['user_type'] ?? userData['role'] ?? 'customer',
      );
      final prefs = await SharedPreferences.getInstance();
      final issuedAt =
          DateTime.tryParse(sessionMetadata?['issuedAt'] as String? ?? '') ??
          DateTime.now();

      if (_user != null && _user!.role != resolvedRole) {
        await _clearLocalSession(
          errorMessage: 'Your account role changed. Please sign in again.',
        );
        return false;
      }

      await _writeToken(jwt, maxAgeDays: rememberMe ? 30 : 14);
      await _writeRefreshToken(
        rotatedRefreshToken,
        maxAgeDays: rememberMe ? 30 : 14,
      );
      _token = jwt;

      if (_user == null) {
        _user = User(
          id: (userData['id'] ?? userData['documentId'] ?? '').toString(),
          documentId: (userData['documentId'] ?? userData['document_id'])
              ?.toString(),
          phoneNumber: (userData['phone'] ?? '').toString(),
          email: userData['email'],
          role: resolvedRole,
          name: userData['name'],
          profileImage: userData['profile_photo'],
          isPremium:
              userData['isPremium'] as bool? ??
              userData['is_premium'] as bool? ??
              false,
          customerId: userData['customer_id']?.toString(),
          shopperId: userData['shopper_id']?.toString(),
          riderId: userData['rider_id']?.toString(),
          kycStatus: userData['kyc_status'] as String?,
          kycRejectionReason: userData['kyc_rejection_reason'] as String?,
          createdAt: DateTime.now(),
        );

        await prefs.setString(
          AppConstants.userKey,
          jsonEncode(_user!.toJson()),
        );
      } else {
        _user = _user!.copyWith(
          role: resolvedRole,
          name: userData['name'] ?? _user!.name,
          email: userData['email'] ?? _user!.email,
          profileImage: userData['profile_photo'] ?? _user!.profileImage,
          isPremium:
              userData['isPremium'] as bool? ??
              userData['is_premium'] as bool? ??
              _user!.isPremium,
          customerId: userData['customer_id']?.toString() ?? _user!.customerId,
          shopperId: userData['shopper_id']?.toString() ?? _user!.shopperId,
          riderId: userData['rider_id']?.toString() ?? _user!.riderId,
          kycStatus: (userData['kyc_status'] as String?) ?? _user!.kycStatus,
        );

        await prefs.setString(
          AppConstants.userKey,
          jsonEncode(_user!.toJson()),
        );
      }

      await _persistSessionMetadata(
        rememberMe: rememberMe,
        issuedAt: issuedAt,
        lastRefreshAt: DateTime.now(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      final errorText = e.toString().toLowerCase();
      final looksLikeAuthFailure =
          errorText.contains('401') ||
          errorText.contains('expired') ||
          errorText.contains('invalid') ||
          errorText.contains('unauthorized');

      if (silent && !looksLikeAuthFailure) {
        debugPrint('[auth] Silent refresh skipped: $e');
        return false;
      }

      _errorMessage = silent ? null : 'Session expired. Please login again.';
      await logout();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
