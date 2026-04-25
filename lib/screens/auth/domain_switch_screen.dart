import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/safe_navigation.dart';
import '../../core/utils/web_location.dart';
import '../../providers/auth_provider.dart';

class DomainSwitchScreen extends StatefulWidget {
  final String targetUrl;
  final String? roleName;
  final String currentHost;

  const DomainSwitchScreen({
    super.key,
    required this.targetUrl,
    required this.currentHost,
    this.roleName,
  });

  @override
  State<DomainSwitchScreen> createState() => _DomainSwitchScreenState();
}

class _DomainSwitchScreenState extends State<DomainSwitchScreen> {
  bool _isLoggingOut = false;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final hasSession = await auth.ensureSessionAvailableForSwitch();
      if (!mounted) return;
      if (!hasSession) {
        context.go('/login');
      }
    });
  }

  String get _roleLabel {
    switch (sanitizeRoleName(widget.roleName)) {
      case 'shopper':
        return 'Shopper';
      case 'rider':
        return 'Rider';
      case 'admin':
        return 'Admin';
      default:
        return 'Customer';
    }
  }

  Future<void> _switchDomain() async {
    if (_isSwitching || widget.targetUrl.isEmpty) return;

    setState(() => _isSwitching = true);
    final auth = context.read<AuthProvider>();
    final hasSession = await auth.ensureSessionAvailableForSwitch();
    if (!mounted) return;

    if (!hasSession) {
      setState(() => _isSwitching = false);
      context.go('/login');
      return;
    }

    final refreshed = await auth.refreshSessionIfNeeded(force: true);
    if (!mounted) return;

    if (!refreshed) {
      setState(() => _isSwitching = false);
      context.go('/login');
      return;
    }

    final role = sanitizeRoleName(widget.roleName);
    if (role == 'admin') {
      final targetUri = Uri.parse(widget.targetUrl);
      final returnPath = StringBuffer(targetUri.path);
      if (targetUri.query.isNotEmpty) {
        returnPath.write('?${targetUri.query}');
      }
      if (targetUri.fragment.isNotEmpty) {
        returnPath.write('#${targetUri.fragment}');
      }

      final adminLoginUri = targetUri.replace(
        path: '/login',
        queryParameters: {
          'stepup': '1',
          'return': returnPath.toString(),
        },
      );
      await auth.logout();
      if (!mounted) return;
      setState(() => _isSwitching = false);
      assignWebLocation(adminLoginUri.toString());
      return;
    }

    setState(() => _isSwitching = false);
    assignWebLocation(widget.targetUrl);
  }

  Future<void> _logoutHere() async {
    setState(() => _isLoggingOut = true);
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Switch Domain')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This account belongs on the $_roleLabel domain.',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You are currently on ${widget.currentHost}. To continue with this session, switch to the correct domain.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        widget.targetUrl,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.targetUrl.isEmpty || _isSwitching
                            ? null
                            : _switchDomain,
                        child: Text(
                          _isSwitching
                              ? 'Checking Session...'
                              : 'Switch To Correct Domain',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoggingOut ? null : _logoutHere,
                        child: Text(
                          _isLoggingOut
                              ? 'Signing Out...'
                              : 'Sign Out And Stay Here',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
