import 'package:flutter_test/flutter_test.dart';
import 'package:lipa_cart/core/utils/signup_domain_utils.dart';

void main() {
  group('getTargetDomainForRole', () {
    test('returns shopper domain for shopper role', () {
      expect(getTargetDomainForRole('shopper'), 'shopper.lipacart.com');
    });

    test('returns rider domain for rider role', () {
      expect(getTargetDomainForRole('rider'), 'rider.lipacart.com');
    });

    test('returns admin domain for admin role', () {
      expect(getTargetDomainForRole('admin'), 'admin.lipacart.com');
    });

    test('returns customer domain for customer role', () {
      expect(getTargetDomainForRole('customer'), 'lipacart.com');
    });

    test('returns customer domain for default/unknown role', () {
      expect(getTargetDomainForRole('unknown'), 'lipacart.com');
      expect(getTargetDomainForRole(''), 'lipacart.com');
    });

    test('is case-insensitive', () {
      expect(getTargetDomainForRole('SHOPPER'), 'shopper.lipacart.com');
      expect(getTargetDomainForRole('Rider'), 'rider.lipacart.com');
      expect(getTargetDomainForRole('ADMIN'), 'admin.lipacart.com');
      expect(getTargetDomainForRole('Customer'), 'lipacart.com');
    });
  });

  group('needsDomainSwitch', () {
    group('customer role', () {
      test('no switch needed on lipacart.com', () {
        expect(needsDomainSwitch('customer', 'lipacart.com'), false);
      });

      test('no switch needed on www.lipacart.com', () {
        expect(needsDomainSwitch('customer', 'www.lipacart.com'), false);
      });

      test('switch needed on rider.lipacart.com', () {
        expect(needsDomainSwitch('customer', 'rider.lipacart.com'), true);
      });

      test('switch needed on shopper.lipacart.com', () {
        expect(needsDomainSwitch('customer', 'shopper.lipacart.com'), true);
      });

      test('switch needed on admin.lipacart.com', () {
        expect(needsDomainSwitch('customer', 'admin.lipacart.com'), true);
      });

      test('no switch needed on localhost (dev)', () {
        expect(needsDomainSwitch('customer', 'localhost'), false);
      });

      test('no switch needed on localhost with port (dev)', () {
        expect(needsDomainSwitch('customer', 'localhost:3000'), false);
      });

      test('no switch needed on 127.x.x.x (loopback)', () {
        expect(needsDomainSwitch('customer', '127.0.0.1'), false);
      });

      test('no switch needed on 192.x.x.x (private network)', () {
        expect(needsDomainSwitch('customer', '192.168.1.100'), false);
      });

      test('no switch needed on 10.x.x.x (private network)', () {
        expect(needsDomainSwitch('customer', '10.0.0.1'), false);
      });

      test('switch needed on evil.com', () {
        expect(needsDomainSwitch('customer', 'evil.com'), true);
      });

      test('switch needed on random subdomain', () {
        expect(needsDomainSwitch('customer', 'staging.lipacart.com'), true);
      });
    });

    group('shopper role', () {
      test('no switch needed on shopper.lipacart.com', () {
        expect(needsDomainSwitch('shopper', 'shopper.lipacart.com'), false);
      });

      test('switch needed on lipacart.com', () {
        expect(needsDomainSwitch('shopper', 'lipacart.com'), true);
      });

      test('switch needed on www.lipacart.com', () {
        expect(needsDomainSwitch('shopper', 'www.lipacart.com'), true);
      });

      test('switch needed on rider.lipacart.com', () {
        expect(needsDomainSwitch('shopper', 'rider.lipacart.com'), true);
      });

      test('switch needed on admin.lipacart.com', () {
        expect(needsDomainSwitch('shopper', 'admin.lipacart.com'), true);
      });

      test('no switch needed on localhost (dev)', () {
        expect(needsDomainSwitch('shopper', 'localhost'), false);
      });

      test('no switch needed on localhost with port (dev)', () {
        expect(needsDomainSwitch('shopper', 'localhost:8080'), false);
      });
    });

    group('rider role', () {
      test('no switch needed on rider.lipacart.com', () {
        expect(needsDomainSwitch('rider', 'rider.lipacart.com'), false);
      });

      test('switch needed on lipacart.com', () {
        expect(needsDomainSwitch('rider', 'lipacart.com'), true);
      });

      test('switch needed on www.lipacart.com', () {
        expect(needsDomainSwitch('rider', 'www.lipacart.com'), true);
      });

      test('switch needed on shopper.lipacart.com', () {
        expect(needsDomainSwitch('rider', 'shopper.lipacart.com'), true);
      });

      test('switch needed on admin.lipacart.com', () {
        expect(needsDomainSwitch('rider', 'admin.lipacart.com'), true);
      });

      test('no switch needed on localhost (dev)', () {
        expect(needsDomainSwitch('rider', 'localhost'), false);
      });
    });

    group('admin role', () {
      test('no switch needed on admin.lipacart.com', () {
        expect(needsDomainSwitch('admin', 'admin.lipacart.com'), false);
      });

      test('switch needed on lipacart.com', () {
        expect(needsDomainSwitch('admin', 'lipacart.com'), true);
      });

      test('switch needed on www.lipacart.com', () {
        expect(needsDomainSwitch('admin', 'www.lipacart.com'), true);
      });

      test('switch needed on shopper.lipacart.com', () {
        expect(needsDomainSwitch('admin', 'shopper.lipacart.com'), true);
      });

      test('switch needed on rider.lipacart.com', () {
        expect(needsDomainSwitch('admin', 'rider.lipacart.com'), true);
      });

      test('no switch needed on localhost (dev)', () {
        expect(needsDomainSwitch('admin', 'localhost'), false);
      });
    });

    group('edge cases', () {
      test('case-insensitive role comparison', () {
        expect(needsDomainSwitch('SHOPPER', 'shopper.lipacart.com'), false);
        expect(needsDomainSwitch('Rider', 'rider.lipacart.com'), false);
      });
    });
  });

  group('buildSignupUrlForDomain', () {
    group('customer role', () {
      test('builds https URL for customer', () {
        expect(
          buildSignupUrlForDomain('customer', scheme: 'https'),
          'https://lipacart.com/signup?role=customer',
        );
      });

      test('builds http URL for customer', () {
        expect(
          buildSignupUrlForDomain('customer', scheme: 'http'),
          'http://lipacart.com/signup?role=customer',
        );
      });
    });

    group('shopper role', () {
      test('builds https URL for shopper', () {
        expect(
          buildSignupUrlForDomain('shopper', scheme: 'https'),
          'https://shopper.lipacart.com/signup?role=shopper',
        );
      });

      test('builds http URL for shopper', () {
        expect(
          buildSignupUrlForDomain('shopper', scheme: 'http'),
          'http://shopper.lipacart.com/signup?role=shopper',
        );
      });
    });

    group('rider role', () {
      test('builds https URL for rider', () {
        expect(
          buildSignupUrlForDomain('rider', scheme: 'https'),
          'https://rider.lipacart.com/signup?role=rider',
        );
      });
    });

    group('admin role', () {
      test('builds https URL for admin', () {
        expect(
          buildSignupUrlForDomain('admin', scheme: 'https'),
          'https://admin.lipacart.com/signup?role=admin',
        );
      });
    });

    group('edge cases', () {
      test('case-insensitive role', () {
        expect(
          buildSignupUrlForDomain('SHOPPER', scheme: 'https'),
          'https://shopper.lipacart.com/signup?role=shopper',
        );
      });

      test('unknown role defaults to customer domain and normalized role', () {
        expect(
          buildSignupUrlForDomain('unknown', scheme: 'https'),
          'https://lipacart.com/signup?role=customer',
        );
      });
    });
  });

  group('normalizeRoleName', () {
    test('normalizes shopper', () {
      expect(normalizeRoleName('shopper'), 'shopper');
      expect(normalizeRoleName('SHOPPER'), 'shopper');
      expect(normalizeRoleName('Shopper'), 'shopper');
    });

    test('normalizes rider', () {
      expect(normalizeRoleName('rider'), 'rider');
      expect(normalizeRoleName('RIDER'), 'rider');
    });

    test('normalizes admin', () {
      expect(normalizeRoleName('admin'), 'admin');
      expect(normalizeRoleName('ADMIN'), 'admin');
    });

    test('defaults to customer for unknown', () {
      expect(normalizeRoleName('unknown'), 'customer');
      expect(normalizeRoleName(''), 'customer');
      expect(normalizeRoleName(null), 'customer');
    });

    test('normalizes customer', () {
      expect(normalizeRoleName('customer'), 'customer');
      expect(normalizeRoleName('CUSTOMER'), 'customer');
    });
  });

  group('End-to-end signup domain flow', () {
    test('Customer signup flow: no switch on lipacart.com', () {
      final role = 'customer';
      final host = 'lipacart.com';
      
      expect(needsDomainSwitch(role, host), false);
      expect(getTargetDomainForRole(role), 'lipacart.com');
    });

    test('Shopper signup flow: switch from lipacart.com to shopper subdomain', () {
      final role = 'shopper';
      final currentHost = 'lipacart.com';
      
      expect(needsDomainSwitch(role, currentHost), true);
      
      final targetDomain = getTargetDomainForRole(role);
      final url = buildSignupUrlForDomain(role, scheme: 'https');
      
      expect(targetDomain, 'shopper.lipacart.com');
      expect(url, 'https://shopper.lipacart.com/signup?role=shopper');
    });

    test('Rider signup flow: switch from lipacart.com to rider subdomain', () {
      final role = 'rider';
      final currentHost = 'lipacart.com';
      
      expect(needsDomainSwitch(role, currentHost), true);
      
      final targetDomain = getTargetDomainForRole(role);
      final url = buildSignupUrlForDomain(role, scheme: 'https');
      
      expect(targetDomain, 'rider.lipacart.com');
      expect(url, 'https://rider.lipacart.com/signup?role=rider');
    });

    test('Already on correct domain: no switch needed', () {
      final role = 'shopper';
      final host = 'shopper.lipacart.com';
      
      expect(needsDomainSwitch(role, host), false);
    });

    test('Wrong domain: switch needed with correct URL', () {
      final role = 'rider';
      final currentHost = 'shopper.lipacart.com';
      
      expect(needsDomainSwitch(role, currentHost), true);
      
      final url = buildSignupUrlForDomain(role, scheme: 'https');
      expect(url, 'https://rider.lipacart.com/signup?role=rider');
    });
  });

  group('Security: Domain isolation', () {
    test('customer cannot signup on shopper domain', () {
      expect(needsDomainSwitch('customer', 'shopper.lipacart.com'), true);
    });

    test('shopper cannot signup on rider domain', () {
      expect(needsDomainSwitch('shopper', 'rider.lipacart.com'), true);
    });

    test('non-lipacart domains are rejected', () {
      expect(needsDomainSwitch('customer', 'evil.com'), true);
      expect(needsDomainSwitch('shopper', 'evil.com'), true);
      expect(needsDomainSwitch('rider', 'evil.com'), true);
    });

    test('staging domains bypass dev detection for workers', () {
      // Staging domains should trigger redirect since they're not localhost
      expect(needsDomainSwitch('shopper', 'staging.lipacart.com'), true);
      expect(needsDomainSwitch('rider', 'staging.lipacart.com'), true);
    });
  });
}
