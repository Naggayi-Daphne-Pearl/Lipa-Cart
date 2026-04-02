import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../models/user.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  final String? returnRoute;

  const LoginScreen({super.key, this.returnRoute});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _usePassword = true;
  bool _obscurePassword = true;

  bool _biometricsAvailable = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const double _desktopBreakpoint = 800;
  static const double _formMaxWidth = 440;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    if (kIsWeb) return;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricsAvailable = canCheck && isDeviceSupported);
      }
    } catch (_) {
      // Biometrics not available
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in with biometrics',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated && mounted) {
        // Try auto-login with saved credentials
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.tryAutoLogin();
        if (success && mounted) {
          await _handlePostLogin(authProvider);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No saved session. Please log in with phone number first.'), backgroundColor: AppColors.warning),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication failed'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phoneNumber = '+256${_phoneController.text}';
    final authProvider = context.read<AuthProvider>();

    if (_usePassword) {
      final success = await authProvider.login(
        phoneNumber: phoneNumber,
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;
        await _handlePostLogin(authProvider);
      } else if (authProvider.errorMessage != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      await authProvider.sendOtp(phoneNumber);

      setState(() => _isLoading = false);

      if (authProvider.status == AuthStatus.otpSent) {
        if (!mounted) return;
        context.push(
          '/otp',
          extra: {
            'phoneNumber': phoneNumber,
            'returnRoute': widget.returnRoute,
          },
        );
      } else if (authProvider.errorMessage != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _desktopBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Scaffold(
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ─── Desktop: Two-column split layout ───────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left brand panel
        Expanded(
          flex: 5,
          child: _buildBrandPanel(),
        ),
        // Right form panel
        Expanded(
          flex: 5,
          child: _buildDesktopFormPanel(),
        ),
      ],
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D6B3A),
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle circle pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _CirclePatternPainter()),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                SvgPicture.asset(
                  'assets/images/logos/logo-on-green-1.svg',
                  height: 32,
                ),
                const Spacer(),
                // Headline
                const Text(
                  'Fresh groceries,\ndelivered fast.',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Get quality produce from local markets\ndelivered right to your doorstep in Kampala.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                // Trust signals
                Row(
                  children: [
                    _buildTrustBadge(
                        Iconsax.people, '10,000+', 'Happy customers'),
                    const SizedBox(width: 32),
                    _buildTrustBadge(Iconsax.star_1, '4.8', 'App rating'),
                    const SizedBox(width: 32),
                    _buildTrustBadge(
                        Iconsax.timer_1, '30 min', 'Avg delivery'),
                  ],
                ),
                const Spacer(flex: 1),
                // Footer
                Text(
                  '${DateTime.now().year} LipaCart. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopFormPanel() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Top nav bar with Sign Up link
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Don\'t have an account?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  child: Text(
                    'Sign Up',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Centered form
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _formMaxWidth),
                  child: _buildFormContent(isDesktop: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mobile: Original single-column layout ─────────────────────
  Widget _buildMobileLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F5E9),
            Color(0xFFF1F8E9),
            Color(0xFFFAFAFA),
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          child: _buildFormContent(isDesktop: false),
        ),
      ),
    );
  }

  // ─── Shared form content ────────────────────────────────────────
  Widget _buildFormContent({required bool isDesktop}) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment:
            isDesktop ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
        children: [
          if (!isDesktop) ...[
            const SizedBox(height: AppSizes.xxl),
            SvgPicture.asset(
              'assets/images/logos/logo-on-white.svg',
              height: 36,
            ),
            const SizedBox(height: AppSizes.xl),
          ],
          // Welcome text
          Text(
            'Welcome back',
            style: (isDesktop ? AppTextStyles.h1 : AppTextStyles.h2).copyWith(
              color: AppColors.primaryDark,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            _usePassword
                ? 'Sign in to get fresh groceries delivered'
                : 'We\'ll send a verification code to your phone',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),

          // Form card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                  isDesktop ? AppSizes.radiusMd : AppSizes.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phone input
                Text(
                  'Phone Number',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isDesktop ? 13 : null,
                  ),
                  semanticsLabel: 'Phone number input field',
                ),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: Validators.validatePhoneNumber,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: isDesktop
                      ? AppTextStyles.bodyMedium
                      : AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '7XX XXX XXX',
                    helperText: 'Uganda mobile number',
                    helperStyle: AppTextStyles.caption,
                    contentPadding: isDesktop
                        ? const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12)
                        : null,
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.call,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+256',
                            style: (isDesktop
                                    ? AppTextStyles.bodyMedium
                                    : AppTextStyles.bodyLarge)
                                .copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1.5,
                            height: 24,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Password field
                if (_usePassword) ...[
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    'Password',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: isDesktop ? 13 : null,
                    ),
                    semanticsLabel: 'Password input field',
                  ),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (_usePassword &&
                          (value == null || value.isEmpty)) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    style: isDesktop
                        ? AppTextStyles.bodyMedium
                        : AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      contentPadding: isDesktop
                          ? const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12)
                          : null,
                      prefixIcon: const Icon(
                        Iconsax.lock,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textLight,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.xs,
                        ),
                        minimumSize: const Size(
                          AppSizes.touchTargetMin,
                          36,
                        ),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(
                  height: _usePassword ? AppSizes.md : AppSizes.lg,
                ),
                // Login button
                CustomButton(
                  text: _usePassword ? 'Sign In' : 'Send Code',
                  isLoading: _isLoading,
                  onPressed: _login,
                  height: isDesktop
                      ? AppSizes.buttonHeightMd
                      : AppSizes.buttonHeightLg,
                ),
                // Biometric login
                if (_biometricsAvailable) ...[
                  const SizedBox(height: AppSizes.md),
                  Center(
                    child: IconButton(
                      onPressed: _authenticateWithBiometrics,
                      icon: const Icon(Icons.fingerprint, size: 40, color: AppColors.primary),
                      tooltip: 'Sign in with biometrics',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // OTP toggle - text link on desktop, outlined button on mobile
          if (isDesktop)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _usePassword = !_usePassword;
                    _passwordController.clear();
                  });
                },
                child: Text(
                  _usePassword
                      ? 'Sign in with OTP instead'
                      : 'Sign in with password instead',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            CustomButton(
              text: _usePassword
                  ? 'Sign in with OTP instead'
                  : 'Sign in with password instead',
              isOutlined: true,
              height: AppSizes.buttonHeightMd,
              onPressed: () {
                setState(() {
                  _usePassword = !_usePassword;
                  _passwordController.clear();
                });
              },
            ),

          if (!isDesktop) ...[
            const SizedBox(height: AppSizes.xl),
            // Sign up link (mobile only - desktop has it in top nav)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(
                      AppSizes.touchTargetMin,
                      AppSizes.touchTargetMin,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                    ),
                  ),
                  child: Text(
                    'Sign Up',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.sm),
          // Terms text
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 0 : AppSizes.lg,
            ),
            child: Text.rich(
              TextSpan(
                text: 'By continuing, you agree to our ',
                style: AppTextStyles.caption,
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/terms-of-service'),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/privacy-policy'),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }

  Future<void> _handlePostLogin(AuthProvider authProvider) async {
    if (!mounted) return;

    final user = authProvider.user;
    final role = user?.role ?? UserRole.customer;

    if (role == UserRole.shopper) {
      final kycStatus = user?.kycStatus ?? 'not_submitted';
      if (kycStatus == 'approved') {
        context.go('/shopper/home');
      } else if (kycStatus == 'pending_review') {
        context.go('/shopper/pending-approval');
      } else if (kycStatus == 'rejected') {
        context.go('/shopper/kyc?rejected=true');
      } else {
        context.go('/shopper/kyc');
      }
      return;
    }

    if (role == UserRole.admin) {
      context.go('/admin/dashboard');
      return;
    }

    if (role != UserRole.customer) {
      context.go('/${role.name}/home');
      return;
    }

    final returnRoute = widget.returnRoute;
    if (returnRoute == null || returnRoute.isEmpty) {
      context.go('/customer/home');
      return;
    }

    if (returnRoute.startsWith('/customer/checkout')) {
      final token = authProvider.token;
      if (token != null && user != null && user.addresses.isEmpty) {
        final addressService = context.read<AddressService>();
        final customerId = user.customerId ?? user.id;
        final success =
            await addressService.fetchAddresses(token, customerId);
        if (success) {
          await authProvider.setAddresses(addressService.userAddresses);
        }
      }

      final hasAddress = authProvider.user?.addresses.isNotEmpty == true;
      if (!hasAddress) {
        final encoded = Uri.encodeComponent(returnRoute);
        context.go('/customer/addresses?return=$encoded');
        return;
      }
    }

    context.go(returnRoute);
  }
}

/// Paints subtle decorative circles on the brand panel background
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      size.width * 0.3,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.75),
      size.width * 0.25,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.85),
      size.width * 0.15,
      paint..color = Colors.white.withValues(alpha: 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
