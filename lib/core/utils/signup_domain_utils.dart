/// Utilities for domain-aware signup flow.
///
/// Ensures users sign up on the correct domain for their role:
/// - Customer: lipacart.com, www.lipacart.com
/// - Shopper: shopper.lipacart.com
/// - Rider: rider.lipacart.com
/// - Admin: admin.lipacart.com
library;

/// Maps role to its canonical domain
String getTargetDomainForRole(String role) {
  switch (role.toLowerCase()) {
    case 'shopper':
      return 'shopper.lipacart.com';
    case 'rider':
      return 'rider.lipacart.com';
    case 'admin':
      return 'admin.lipacart.com';
    default:
      return 'lipacart.com';
  }
}

/// Check if a host is a development environment (localhost, loopback, private IP).
bool _isDevHost(String host) {
  return host == 'localhost' ||
      host.startsWith('127.') ||
      host.startsWith('192.') ||
      host.startsWith('10.') ||
      host.contains(':'); // localhost:PORT or IPv6
}

/// Checks if the current host matches the expected domain for a role.
///
/// Returns true if a domain switch is needed, false otherwise.
bool needsDomainSwitch(String role, String currentHost) {
  final targetDomain = getTargetDomainForRole(role);

  // Dev/test environments never need to switch
  if (_isDevHost(currentHost)) {
    return false;
  }

  // For customer role, accept lipacart.com and www.lipacart.com
  if (role.toLowerCase() == 'customer') {
    return currentHost != 'lipacart.com' && currentHost != 'www.lipacart.com';
  }

  // For worker roles, must be on the exact domain
  return currentHost != targetDomain;
}

/// Builds a signup URL on the specified domain for a role.
String buildSignupUrlForDomain(String role, {required String scheme}) {
  final normalizedRole = normalizeRoleName(role);
  final targetDomain = getTargetDomainForRole(role);
  return '$scheme://$targetDomain/signup?role=$normalizedRole';
}

/// Validates a role name.
String normalizeRoleName(String? role) {
  switch ((role ?? '').toLowerCase()) {
    case 'shopper':
      return 'shopper';
    case 'rider':
      return 'rider';
    case 'admin':
      return 'admin';
    default:
      return 'customer';
  }
}
