import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final cleanedNumber = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanedNumber.length < 9 || cleanedNumber.length > 12) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    if (value.length != AppConstants.otpLength) {
      return 'Enter a ${AppConstants.otpLength}-digit OTP';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }

    if (value.length < 5) {
      return 'Please enter a more specific address';
    }

    return null;
  }

  static String? validateQuantity(String? value, double minQuantity) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }

    final quantity = double.tryParse(value);
    if (quantity == null) {
      return 'Enter a valid number';
    }

    if (quantity < minQuantity) {
      return 'Minimum quantity is $minQuantity';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
