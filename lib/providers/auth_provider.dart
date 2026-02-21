import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/constants/app_constants.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  error,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _errorMessage;
  bool _isFirstLaunch = true;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isFirstLaunch => _isFirstLaunch;

  /// Check for existing session and restore if valid
  /// Called on app startup
  Future<bool> tryAutoLogin() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(AppConstants.tokenKey);
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
      await prefs.remove(AppConstants.tokenKey);
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

      // Save JWT to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, jwt);

      // Create User object
      _token = jwt;
      _user = User(
        id: userData['id'] ?? userData['documentId'] ?? '',
        phoneNumber: userData['phone'] ?? phoneNumber,
        email: userData['email'],
        role: UserRoleExtension.fromString(userData['user_type'] ?? userType),
        name: userData['name'],
        profileImage: userData['profile_photo'],
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

      // Save JWT to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, jwt);

      // Create User object
      _token = jwt;
      _user = User(
        id: userData['id'] ?? userData['documentId'] ?? '',
        phoneNumber: userData['phone'] ?? phoneNumber,
        email: userData['email'],
        role: UserRoleExtension.fromString(userData['user_type'] ?? 'customer'),
        name: userData['name'],
        profileImage: userData['profile_photo'],
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

      // Save JWT to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, jwt);

      // Create User object with role from response
      _token = jwt;
      _user = User(
        id: userData['id'] ?? userData['documentId'] ?? '',
        phoneNumber: userData['phone'] ?? phoneNumber,
        email: userData['email'],
        role: UserRoleExtension.fromString(userData['user_type'] ?? 'customer'),
        name: userData['name'],
        profileImage: userData['profile_photo'],
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
    notifyListeners();
  }

  Future<void> removeAddress(String addressId) async {
    if (_user == null) return;

    final addresses = _user!.addresses.where((a) => a.id != addressId).toList();
    _user = _user!.copyWith(addresses: addresses);
    notifyListeners();
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (_user == null) return;

    final addresses = _user!.addresses.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();
    _user = _user!.copyWith(addresses: addresses);
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
    await prefs.remove(AppConstants.tokenKey);
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

      // Save new JWT to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, jwt);

      // Update token
      _token = jwt;

      // Update user if data changed
      if (userData['name'] != _user?.name ||
          userData['email'] != _user?.email ||
          userData['profile_photo'] != _user?.profileImage) {
        _user = _user!.copyWith(
          name: userData['name'],
          email: userData['email'],
          profileImage: userData['profile_photo'],
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
