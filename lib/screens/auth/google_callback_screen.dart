import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/google_oauth_service.dart';

class GoogleCallbackScreen extends StatefulWidget {
  final String? returnRoute;
  final String? source;

  const GoogleCallbackScreen({
    super.key,
    this.returnRoute,
    this.source,
  });

  @override
  State<GoogleCallbackScreen> createState() => _GoogleCallbackScreenState();
}

class _GoogleCallbackScreenState extends State<GoogleCallbackScreen> {
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processGoogleCallback();
    });
  }

  Future<void> _processGoogleCallback() async {
    final profile = GoogleOAuthService.readProfileFromCurrentUrl();
    if (profile == null || !mounted) {
      _redirectToLogin();
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final stateParams = profile.stateParams;
    final returnRoute = stateParams['return'] ?? widget.returnRoute;

    final result = await authProvider.signInWithGoogle(
      profile.idToken,
      rememberMe: true,
      userType: 'customer',
    );

    if (!mounted) return;

    if (result.success || authProvider.isAuthenticated) {
      context.go(returnRoute != null && returnRoute.isNotEmpty
          ? returnRoute
          : '/customer/home');
      return;
    }

    if (result.needsSignup) {
      final signupUri = Uri(
        path: '/signup',
        queryParameters: {
          'oauth': 'google',
          'role': 'customer',
          'email': result.email ?? profile.email,
          if ((result.name ?? profile.name)?.trim().isNotEmpty == true)
            'name': (result.name ?? profile.name)!.trim(),
          if (returnRoute != null && returnRoute.isNotEmpty)
            'return': returnRoute,
        },
      );

      context.go(signupUri.toString());
      return;
    }

    setState(() => _isProcessing = false);

    final message = authProvider.errorMessage ??
        'Google sign-in could not be completed right now.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );

    _redirectToLogin();
  }

  void _redirectToLogin() {
    if (!mounted) return;
    final fallbackUri = Uri(
      path: '/login',
      queryParameters: {
        if (widget.returnRoute != null && widget.returnRoute!.isNotEmpty)
          'return': widget.returnRoute,
      },
    );
    context.go(fallbackUri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _isProcessing
                  ? 'Signing you in with Google...'
                  : 'Returning to sign in...',
            ),
          ],
        ),
      ),
    );
  }
}
