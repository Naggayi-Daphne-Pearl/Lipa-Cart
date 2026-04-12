import 'package:flutter_test/flutter_test.dart';
import 'package:lipa_cart/models/user.dart';

void main() {
  group('UserRole', () {
    test('fromString returns correct role', () {
      expect(UserRoleExtension.fromString('customer'), UserRole.customer);
      expect(UserRoleExtension.fromString('admin'), UserRole.admin);
      expect(UserRoleExtension.fromString('rider'), UserRole.rider);
      expect(UserRoleExtension.fromString('shopper'), UserRole.shopper);
    });

    test('fromString defaults to customer for unknown values', () {
      expect(UserRoleExtension.fromString(null), UserRole.customer);
      expect(UserRoleExtension.fromString('unknown'), UserRole.customer);
      expect(UserRoleExtension.fromString(''), UserRole.customer);
    });

    test('displayName returns human-readable name', () {
      expect(UserRole.customer.displayName, 'Customer');
      expect(UserRole.admin.displayName, 'Admin');
      expect(UserRole.rider.displayName, 'Rider');
      expect(UserRole.shopper.displayName, 'Shopper');
    });
  });

  group('User', () {
    test('fromJson creates user with all fields', () {
      final json = {
        'id': '123',
        'documentId': 'doc-456',
        'phoneNumber': '+256700000000',
        'name': 'Test User',
        'email': 'test@example.com',
        'profileImage': 'https://example.com/photo.jpg',
        'isPremium': true,
        'role': 'customer',
        'customerId': 'c-1',
        'shopperId': null,
        'riderId': null,
        'kycStatus': 'approved',
        'kycRejectionReason': null,
        'addresses': [],
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, '123');
      expect(user.documentId, 'doc-456');
      expect(user.phoneNumber, '+256700000000');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.profileImage, 'https://example.com/photo.jpg');
      expect(user.isPremium, true);
      expect(user.role, UserRole.customer);
      expect(user.customerId, 'c-1');
      expect(user.kycStatus, 'approved');
      expect(user.addresses, isEmpty);
    });

    test('fromJson handles backend field name variants', () {
      final json = {
        'id': '123',
        'phone': '+256700000000',
        'user_type': 'rider',
        'profile_photo': 'https://example.com/photo.jpg',
        'is_premium': false,
        'customer_id': 'c-1',
        'shopper_id': 's-1',
        'rider_id': 'r-1',
        'document_id': 'doc-789',
        'kyc_status': 'pending_review',
        'kyc_rejection_reason': 'blurry photo',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.phoneNumber, '+256700000000');
      expect(user.role, UserRole.rider);
      expect(user.profileImage, 'https://example.com/photo.jpg');
      expect(user.isPremium, false);
      expect(user.customerId, 'c-1');
      expect(user.shopperId, 's-1');
      expect(user.riderId, 'r-1');
      expect(user.documentId, 'doc-789');
      expect(user.kycStatus, 'pending_review');
      expect(user.kycRejectionReason, 'blurry photo');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': '1',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.id, '1');
      expect(user.phoneNumber, '');
      expect(user.name, isNull);
      expect(user.email, isNull);
      expect(user.isPremium, false);
      expect(user.role, UserRole.customer);
      expect(user.addresses, isEmpty);
    });

    test('fromJson handles createdAt as int (milliseconds)', () {
      final millis = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      final json = {
        'id': '1',
        'createdAt': millis,
      };

      final user = User.fromJson(json);
      expect(user.createdAt.year, 2026);
    });

    test('toJson roundtrips correctly', () {
      final user = User(
        id: '42',
        documentId: 'doc-42',
        phoneNumber: '+256712345678',
        name: 'Jane',
        email: 'jane@test.com',
        role: UserRole.shopper,
        customerId: 'c-42',
        shopperId: 's-42',
        kycStatus: 'approved',
        createdAt: DateTime(2026, 3, 15),
      );

      final json = user.toJson();
      final restored = User.fromJson(json);

      expect(restored.id, user.id);
      expect(restored.documentId, user.documentId);
      expect(restored.phoneNumber, user.phoneNumber);
      expect(restored.name, user.name);
      expect(restored.email, user.email);
      expect(restored.role, user.role);
      expect(restored.customerId, user.customerId);
      expect(restored.shopperId, user.shopperId);
      expect(restored.kycStatus, user.kycStatus);
    });

    test('copyWith creates modified copy', () {
      final user = User(
        id: '1',
        phoneNumber: '+256700000000',
        role: UserRole.customer,
        createdAt: DateTime(2026),
      );

      final updated = user.copyWith(
        name: 'Updated Name',
        kycStatus: 'approved',
      );

      expect(updated.name, 'Updated Name');
      expect(updated.kycStatus, 'approved');
      expect(updated.id, '1'); // unchanged
      expect(updated.phoneNumber, '+256700000000'); // unchanged
    });
  });

  group('Address (user model)', () {
    test('fromJson creates address', () {
      final json = {
        'id': 'addr-1',
        'label': 'Home',
        'fullAddress': 'Plot 42, Kampala Road',
        'landmark': 'Near mosque',
        'latitude': 0.347596,
        'longitude': 32.582520,
        'isDefault': true,
      };

      final address = Address.fromJson(json);

      expect(address.id, 'addr-1');
      expect(address.label, 'Home');
      expect(address.fullAddress, 'Plot 42, Kampala Road');
      expect(address.landmark, 'Near mosque');
      expect(address.latitude, 0.347596);
      expect(address.longitude, 32.582520);
      expect(address.isDefault, true);
    });

    test('toJson roundtrips correctly', () {
      final address = Address(
        id: 'a-1',
        label: 'Office',
        fullAddress: '123 Test St',
        latitude: 1.0,
        longitude: 2.0,
        isDefault: false,
      );

      final json = address.toJson();
      final restored = Address.fromJson(json);

      expect(restored.id, address.id);
      expect(restored.label, address.label);
      expect(restored.fullAddress, address.fullAddress);
      expect(restored.isDefault, address.isDefault);
    });

    test('copyWith modifies specific fields', () {
      final address = Address(
        id: 'a-1',
        label: 'Home',
        fullAddress: '123 St',
        latitude: 0.0,
        longitude: 0.0,
      );

      final updated = address.copyWith(isDefault: true, label: 'Primary');

      expect(updated.isDefault, true);
      expect(updated.label, 'Primary');
      expect(updated.fullAddress, '123 St'); // unchanged
    });
  });
}
