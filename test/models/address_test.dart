import 'package:flutter_test/flutter_test.dart';
import 'package:lipa_cart/models/address.dart';

void main() {
  group('Address (API model)', () {
    test('fromJson creates address with all fields', () {
      final json = {
        'id': 42,
        'documentId': 'doc-42',
        'customer': {'id': 10},
        'label': 'Home',
        'address_line': 'Plot 42, Kampala Road',
        'city': 'Kampala',
        'landmark': 'Near mosque',
        'delivery_instructions': 'Call on arrival',
        'gps_lat': '0.347596',
        'gps_lng': '32.582520',
        'is_default': true,
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final address = Address.fromJson(json);

      expect(address.id, 42);
      expect(address.documentId, 'doc-42');
      expect(address.customerId, 10);
      expect(address.label, 'Home');
      expect(address.addressLine, 'Plot 42, Kampala Road');
      expect(address.city, 'Kampala');
      expect(address.landmark, 'Near mosque');
      expect(address.deliveryInstructions, 'Call on arrival');
      expect(address.gpsLat, closeTo(0.347596, 0.001));
      expect(address.gpsLng, closeTo(32.582520, 0.001));
      expect(address.isDefault, true);
    });

    test('fromJson handles customer as int', () {
      final json = {
        'id': 1,
        'documentId': 'd-1',
        'customer': 5,
        'label': 'Office',
        'address_line': 'Test St',
        'city': 'Nairobi',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final address = Address.fromJson(json);
      expect(address.customerId, 5);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 1,
        'documentId': 'd-1',
        'label': 'Test',
        'address_line': 'Street',
        'city': 'City',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final address = Address.fromJson(json);
      expect(address.landmark, isNull);
      expect(address.deliveryInstructions, isNull);
      expect(address.gpsLat, isNull);
      expect(address.gpsLng, isNull);
      expect(address.isDefault, false);
    });

    test('fullAddress concatenates correctly', () {
      final address = Address(
        id: 1,
        documentId: 'd-1',
        customerId: 1,
        label: 'Home',
        addressLine: 'Plot 42',
        city: 'Kampala',
        landmark: 'Near mosque',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      expect(address.fullAddress, 'Plot 42, Kampala, Near mosque');
    });

    test('fullAddress without landmark', () {
      final address = Address(
        id: 1,
        documentId: 'd-1',
        customerId: 1,
        label: 'Home',
        addressLine: 'Plot 42',
        city: 'Kampala',
        isDefault: false,
        createdAt: DateTime.now(),
      );

      expect(address.fullAddress, 'Plot 42, Kampala');
    });

    test('empty factory creates zeroed address', () {
      final address = Address.empty();
      expect(address.id, 0);
      expect(address.documentId, '');
      expect(address.label, '');
      expect(address.addressLine, '');
      expect(address.isDefault, false);
    });
  });
}
