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

  final allowed = allowedPrefixes.any(
    (prefix) => path == prefix || path.startsWith(prefix),
  );
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
  final baseHost = host
      .replaceFirst(RegExp(r'^(shopper|rider|admin|www)\.'), '');
  final isLipaHost =
      baseHost == 'lipacart.com' || baseHost.endsWith('.lipacart.com');
  if (!isLipaHost) return null;

  final role = sanitizeRoleName(expectedRole);
  final expectedHost = role == 'customer' ? baseHost : '$role.$baseHost';
  if (host != expectedHost) return null;

  return uri.toString();
}
