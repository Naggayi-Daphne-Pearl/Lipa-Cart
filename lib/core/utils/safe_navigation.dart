String? sanitizeInternalReturnRoute(String? route) {
  if (route == null) return null;
  final trimmed = route.trim();
  if (trimmed.isEmpty) return null;

  if (!trimmed.startsWith('/')) return null;
  if (trimmed.startsWith('//')) return null;
  if (trimmed.contains('://')) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.hasScheme || uri.hasAuthority) return null;

  final path = uri.path;
  const allowedPrefixes = <String>[
    '/customer/',
    '/shopper/',
    '/rider/',
    '/admin/',
    '/forgot-password',
    '/profile-completion',
    '/onboarding',
  ];

  bool isAllowedPrefix(String prefix) {
    if (path == prefix) return true;
    if (prefix.endsWith('/')) return path.startsWith(prefix);
    return path.startsWith('$prefix/');
  }

  final allowed = allowedPrefixes.any(isAllowedPrefix);
  if (!allowed) return null;

  return uri.toString();
}

String sanitizeRoleName(String? role) {
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

String? sanitizeDomainSwitchTarget(
  String? rawTarget,
  String expectedRole,
) {
  if (rawTarget == null) return null;
  final trimmed = rawTarget.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (!uri.hasScheme || !uri.hasAuthority) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;

  final host = uri.host.toLowerCase();
  final role = sanitizeRoleName(expectedRole);

  final isCanonicalLipaHost =
      host == 'lipacart.com' ||
      host == 'www.lipacart.com' ||
      host == 'shopper.lipacart.com' ||
      host == 'rider.lipacart.com' ||
      host == 'admin.lipacart.com';
  if (!isCanonicalLipaHost) return null;

  if (role == 'customer') {
    if (host != 'lipacart.com' && host != 'www.lipacart.com') {
      return null;
    }
  } else {
    final expectedHost = '$role.lipacart.com';
    if (host != expectedHost) return null;
  }

  return uri.toString();
}
