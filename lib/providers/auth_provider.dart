import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
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

  Future<void> _writeToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      WebCookieStorage.write(AppConstants.tokenKey, token);
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

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _errorMessage;
  bool _isFirstLaunch = true;
  bool _didBootstrap = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isFirstLaunch => _isFirstLaunch;

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

  Future<void> _persistUser() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));
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

      if (savedToken == null || savedUserJson == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      // Restore user data from SharedPreferences
      _token = savedToken;
      final userJson = jsonDecode(savedUserJson) as Map<String, dynamic>;
      _user = User.fromJson(userJson);

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      // Token invalid or session data corrupted
      final prefs = await SharedPreferences.getInstance();
      await _deleteToken();
      await prefs.remove(AppConstants.userKey);

      _token = null;
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Session expired. Please login again.';
      notifyListeners();
      return false;
    }
  }

  /// Sign up with phone number and password
  Future<bool> signup({
    required String phoneNumber,
    required String password,
    String? name,
    String? email,
    String userType = 'customer',
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
      );

      final jwt = response['jwt'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      // Save JWT to secure storage
      final prefs = await SharedPreferences.getInstance();
      await _writeToken(jwt);

      // Create User object
      _token = jwt;
      _user = User(
        id: (userData['id'] ?? userData['documentId'] ?? '').toString(),
        documentId: userData['document_id']?.toString(),
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

      _status = AuthStatus.authenticated;
      notifyListeners();
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
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.login(
        phoneNumber: phoneNumber,
        password: password,
      );

      final jwt = response['jwt'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      // Save JWT to secure storage
      final prefs = await SharedPreferences.getInstance();
      await _writeToken(jwt);

      // Create User object
      _token = jwt;
      _user = User(
        id: (userData['id'] ?? userData['documentId'] ?? '').toString(),
        documentId: userData['document_id']?.toString(),
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

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
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
  Future<bool> verifyOtp(String otp, String phoneNumber) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.verifyOtp(phoneNumber, otp);

      final jwt = response['jwt'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      // Save JWT to secure storage
      final prefs = await SharedPreferences.getInstance();
      await _writeToken(jwt);

      // Create User object with role from response
      _token = jwt;
      _user = User(
        id: (userData['id'] ?? userData['documentId'] ?? '').toString(),
        documentId: userData['document_id']?.toString(),
        phoneNumber: (userData['phone'] ?? phoneNumber).toString(),
        email: userData['email'],
        role: UserRoleExtension.fromString(userData['user_type'] ?? 'customer'),
        name: userData['name'],
        profileImage: userData['profile_photo'],
        isPremium:
            userData['isPremium'] as bool? ??
            userData['is_premium'] as bool? ??
            false,
        shopperId: userData['shopper_id']?.toString(),
        riderId: userData['rider_id']?.toString(),
        kycStatus: userData['kyc_status'] as String?,
        kycRejectionReason: userData['kyc_rejection_reason'] as String?,
        createdAt: DateTime.now(),
      );

      // Save user data to SharedPreferences
      await prefs.setString(AppConstants.userKey, jsonEncode(_user!.toJson()));

      _status = AuthStatus.authenticated;
      notifyListeners();
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
          documentId: response['document_id']?.toString(),
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
          documentId: response['document_id']?.toString() ?? _user!.documentId,
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
          kycRejectionReason: (response['kyc_rejection_reason'] as String?) ?? _user!.kycRejectionReason,
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

  Future<void> addAddress(Address address) async {
    if (_user == null) return;

    final addresses = List<Address>.from(_user!.addresses);
    if (address.isDefault) {
      for (int i = 0; i < addresses.length; i++) {
        addresses[i] = addresses[i].copyWith(isDefault: false);
      }
    }
    addresses.add(address);
    _user = _user!.copyWith(addresses: addresses);
    await _persistUser();
    notifyListeners();
  }

  Future<void> removeAddress(String addressId) async {
    if (_user == null) return;

    final addresses = _user!.addresses.where((a) => a.id != addressId).toList();
    _user = _user!.copyWith(addresses: addresses);
    await _persistUser();
    notifyListeners();
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (_user == null) return;

    final addresses = _user!.addresses.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();
    _user = _user!.copyWith(addresses: addresses);
    await _persistUser();
    notifyListeners();
  }

  Future<void> setAddresses(List<Address> addresses) async {
    if (_user == null) return;
    _user = _user!.copyWith(addresses: addresses);
    await _persistUser();
    notifyListeners();
  }

  Address? get defaultAddress {
    if (_user == null || _user!.addresses.isEmpty) return null;
    return _user!.addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _user!.addresses.first,
    );
  }

  /// Logout and clear stored session
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _deleteToken();
    await prefs.remove(AppConstants.userKey);

    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Refresh JWT token
  /// Call this when token is about to expire or after receiving 401
  Future<bool> refreshToken() async {
    try {
      if (_token == null) return false;

      final response = await AuthService.refreshToken(_token!);

      final jwt = response['jwt'] as String;
      final userData = response['user'] as Map<String, dynamic>;

      // Save new JWT to secure storage
      final prefs = await SharedPreferences.getInstance();
      await _writeToken(jwt);

      // Update token
      _token = jwt;

      // Update user if data changed
      if (userData['name'] != _user?.name ||
          userData['email'] != _user?.email ||
          userData['profile_photo'] != _user?.profileImage ||
          userData['isPremium'] != _user?.isPremium ||
          userData['is_premium'] != _user?.isPremium) {
        _user = _user!.copyWith(
          name: userData['name'],
          email: userData['email'],
          profileImage: userData['profile_photo'],
          isPremium:
              userData['isPremium'] as bool? ??
              userData['is_premium'] as bool? ??
              _user!.isPremium,
        );

        // Save updated user data
        await prefs.setString(
          AppConstants.userKey,
          jsonEncode(_user!.toJson()),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      // Token refresh failed - logout user
      _errorMessage = 'Session expired. Please login again.';
      await logout();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
