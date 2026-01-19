import 'package:flutter/foundation.dart';
import '../models/user.dart';

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
  String? _errorMessage;
  // Will be used for real OTP verification with Firebase/backend
  String? _verificationId; // ignore: unused_field
  bool _isFirstLaunch = true;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isFirstLaunch => _isFirstLaunch;

  void setFirstLaunchComplete() {
    _isFirstLaunch = false;
    notifyListeners();
  }

  Future<void> sendOtp(String phoneNumber) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));
      _verificationId = 'mock_verification_id';
      _status = AuthStatus.otpSent;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to send OTP. Please try again.';
    }
    notifyListeners();
  }

  Future<bool> verifyOtp(String otp, String phoneNumber) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (otp == '123456') {
        _user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.otpSent;
        _errorMessage = 'Invalid OTP. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Verification failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
  }) async {
    if (_user == null) return;

    _user = _user!.copyWith(
      name: name ?? _user!.name,
      email: email ?? _user!.email,
    );
    notifyListeners();
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

  Future<void> logout() async {
    _user = null;
    _status = AuthStatus.unauthenticated;
    _verificationId = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
