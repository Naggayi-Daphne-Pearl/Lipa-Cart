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

/// Checks if the current host matches the expected domain for a role.
///
/// Returns true if a domain switch is needed, false otherwise.
bool needsDomainSwitch(String role, String currentHost) {
  final targetDomain = getTargetDomainForRole(role);

  // For customer role, accept lipacart.com and www.lipacart.com
  if (role.toLowerCase() == 'customer') {
    // Dev/test environments (localhost, IPs) don't need switch
    if (currentHost == 'localhost' ||
        currentHost.startsWith('127.') ||
        currentHost.startsWith('192.') ||
        currentHost.startsWith('10.') ||
        currentHost.contains(':')) {
      return false;
    }

    return currentHost != 'lipacart.com' && currentHost != 'www.lipacart.com';
  }

  // For worker roles, must be on the exact domain
  // Allow localhost for development
  if (currentHost == 'localhost' || currentHost.contains(':')) {
    return false;
  }

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
