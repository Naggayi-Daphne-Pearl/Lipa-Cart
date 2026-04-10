import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lipa_cart/services/address_service.dart';
import 'package:lipa_cart/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddressService - preferred address', () {
    test('saves and restores preferred address from SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});

      final service = AddressService();
      await Future.delayed(const Duration(milliseconds: 100));

      // Initially no address
      expect(service.defaultAddress, isNull);
      expect(service.hasSelectedAddress, false);

      // Save a preferred address
      await service.savePreferredAddress(
        label: 'Home',
        addressLine: 'Plot 42, Kampala Road',
        city: 'Kampala',
        landmark: 'Near mosque',
        gpsLat: 0.3476,
        gpsLng: 32.5825,
      );

      expect(service.defaultAddress, isNotNull);
      expect(service.defaultAddress!.label, 'Home');
      expect(service.defaultAddress!.addressLine, 'Plot 42, Kampala Road');
      expect(service.defaultAddress!.city, 'Kampala');
      expect(service.hasSelectedAddress, true);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(AppConstants.preferredDeliveryAddressKey);
      expect(saved, isNotNull);
      final decoded = jsonDecode(saved!);
      expect(decoded['label'], 'Home');
      expect(decoded['addressLine'], 'Plot 42, Kampala Road');
    });

    test('clears preferred address', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AddressService();
      await Future.delayed(const Duration(milliseconds: 100));

      await service.savePreferredAddress(
        label: 'Home',
        addressLine: 'Test St',
        city: 'Kampala',
      );
      expect(service.defaultAddress, isNotNull);

      await service.clearPreferredAddress();
      expect(service.defaultAddress, isNull);
    });

    test('loads preferred address from stored prefs on init', () async {
      final savedData = {
        'label': 'Office',
        'addressLine': 'Tower Rd',
        'city': 'Nairobi',
        'landmark': null,
        'deliveryInstructions': null,
        'gpsLat': -1.2921,
        'gpsLng': 36.8219,
        'isDefault': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      SharedPreferences.setMockInitialValues({
        AppConstants.preferredDeliveryAddressKey: jsonEncode(savedData),
      });

      final service = AddressService();
      // loadPreferredAddress runs in constructor
      await Future.delayed(const Duration(milliseconds: 200));

      expect(service.defaultAddress, isNotNull);
      expect(service.defaultAddress!.label, 'Office');
      expect(service.defaultAddress!.city, 'Nairobi');
    });
  });

  group('AddressService - defaultUserAddress', () {
    test('returns null when no addresses', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AddressService();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.defaultUserAddress, isNull);
    });

    test('converts default address to user model Address', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AddressService();
      await Future.delayed(const Duration(milliseconds: 100));

      await service.savePreferredAddress(
        label: 'Home',
        addressLine: 'Plot 42',
        city: 'Kampala',
        landmark: 'By the school',
        gpsLat: 0.3,
        gpsLng: 32.5,
      );

      final userAddr = service.defaultUserAddress;
      expect(userAddr, isNotNull);
      expect(userAddr!.label, 'Home');
      expect(userAddr.fullAddress, contains('Plot 42'));
      expect(userAddr.fullAddress, contains('Kampala'));
    });
  });

  group('AddressService - userAddresses conversion', () {
    test('returns empty list when no addresses', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AddressService();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.userAddresses, isEmpty);
    });
  });
}
