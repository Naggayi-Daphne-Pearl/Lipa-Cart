import 'package:flutter_test/flutter_test.dart';
import 'package:lipa_cart/core/utils/safe_navigation.dart';

void main() {
  group('sanitizeInternalReturnRoute', () {
    test('accepts known internal route', () {
      expect(
        sanitizeInternalReturnRoute('/customer/checkout?guest=true'),
        '/customer/checkout?guest=true',
      );
    });

    test('rejects external absolute URL', () {
      expect(
        sanitizeInternalReturnRoute('https://evil.example/phish'),
        isNull,
      );
    });

    test('rejects protocol-relative URL', () {
      expect(sanitizeInternalReturnRoute('//evil.example'), isNull);
    });

    test('rejects unknown internal route', () {
      expect(sanitizeInternalReturnRoute('/some-random-path'), isNull);
    });
  });

  group('sanitizeRoleName', () {
    test('normalizes known roles', () {
      expect(sanitizeRoleName('ADMIN'), 'admin');
      expect(sanitizeRoleName('shopper'), 'shopper');
      expect(sanitizeRoleName('rider'), 'rider');
    });

    test('falls back to customer', () {
      expect(sanitizeRoleName('unknown'), 'customer');
      expect(sanitizeRoleName(null), 'customer');
    });
  });

  group('sanitizeDomainSwitchTarget', () {
    test('accepts matching role host target', () {
      expect(
        sanitizeDomainSwitchTarget('https://shopper.lipacart.com/shopper/home', 'shopper'),
        'https://shopper.lipacart.com/shopper/home',
      );
    });

    test('rejects mismatched role host target', () {
      expect(
        sanitizeDomainSwitchTarget('https://customer.lipacart.com/customer/home', 'shopper'),
        isNull,
      );
    });

    test('rejects non-lipacart host target', () {
      expect(
        sanitizeDomainSwitchTarget('https://example.com/admin/dashboard', 'admin'),
        isNull,
      );
    });
  });
}
