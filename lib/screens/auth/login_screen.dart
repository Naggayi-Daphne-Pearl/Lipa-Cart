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
import '../../core/utils/safe_navigation.dart';
import '../../core/utils/signup_domain_utils.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/web_location.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../services/google_oauth_service.dart';
import '../../models/user.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/auth_shell.dart';

class LoginScreen extends StatefulWidget {
  final String? returnRoute;
  final bool stepUpRequired;

  const LoginScreen({
    super.key,
    this.returnRoute,
    this.stepUpRequired = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String _selectedRole = 'customer';

  bool _biometricsAvailable = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _selectedRole = _roleForCurrentHost();
    if (kIsWeb) {
      final queryRole = Uri.base.queryParameters['role'];
      if (queryRole != null && queryRole.isNotEmpty) {
        _selectedRole = normalizeRoleName(queryRole);
      }
      final queryPhone = Uri.base.queryParameters['phone'];
      if (queryPhone != null && queryPhone.isNotEmpty) {
        _phoneController.text = queryPhone;
      }
    }
    _checkBiometrics();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();

      if (widget.stepUpRequired) {
        setState(() => _isLoading = true);
        await authProvider.logout();
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please re-enter your password to continue.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      if (authProvider.isAuthenticated) {
        await _handlePostLogin(authProvider);
        return;
      }
      await _handleGoogleOAuthCallback();
    });
  }

  String _roleForCurrentHost() {
    final host = Uri.base.host.toLowerCase();
    if (host == 'shopper.lipacart.com') return 'shopper';
    if (host == 'rider.lipacart.com') return 'rider';
    if (host == 'admin.lipacart.com') return 'admin';
    return 'customer';
  }

  void _selectRole(String role) {
    final normalizedRole = normalizeRoleName(role);
    if (kIsWeb && needsDomainSwitch(normalizedRole, Uri.base.host)) {
      final scheme = Uri.base.scheme;
      var targetUrl = buildSignupUrlForDomain(
        normalizedRole,
        scheme: scheme,
      ).replaceFirst('/signup', '/login');

      final queryParams = <String, String>{
        'role': normalizedRole,
      };
      if (_phoneController.text.isNotEmpty) {
        queryParams['phone'] = _phoneController.text;
      }
      final safeReturnRoute = sanitizeInternalReturnRoute(widget.returnRoute);
      if (safeReturnRoute != null) {
        queryParams['return'] = safeReturnRoute;
      }
      if (widget.stepUpRequired) {
        queryParams['stepup'] = '1';
      }

      final separator = targetUrl.contains('?') ? '&' : '?';
      targetUrl += separator + Uri(queryParameters: queryParams).query;

      assignWebLocation(targetUrl);
      return;
    }

    setState(() => _selectedRole = normalizedRole);
  }

  Future<void> _checkBiometrics() async {
    if (kIsWeb) return;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricsAvailable = canCheck && isDeviceSupported);
      }
    } catch (_) {}
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in with biometrics',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.tryAutoLogin();
        if (success && mounted) {
          await _handlePostLogin(authProvider);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No saved session. Please log in with phone number first.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication failed'),
            backgroundColor: AppColors.error,
          ),
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

  Future<void> _continueWithGoogle() async {
    if (!kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google OAuth is currently available on the web app.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!GoogleOAuthService.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google OAuth is not configured yet.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final launched = await GoogleOAuthService.launchConsentScreen(
      callbackPath: '/auth/google/callback',
      queryParameters: {
        'role': 'customer',
        'source': 'login',
        if (sanitizeInternalReturnRoute(widget.returnRoute) != null)
          'return': sanitizeInternalReturnRoute(widget.returnRoute),
      },
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open the Google consent screen right now.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGoogleOAuthCallback() async {
    final profile = GoogleOAuthService.readProfileFromCurrentUrl();
    if (profile == null || !mounted) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final stateParams = profile.stateParams;
    final returnRoute = sanitizeInternalReturnRoute(
      stateParams['return'] ?? widget.returnRoute,
    );
    final result = await authProvider.signInWithGoogle(
      profile.idToken,
      rememberMe: _rememberMe,
      userType: 'customer',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (authProvider.isAuthenticated) {
      await _handlePostLogin(authProvider);
      return;
    }

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.needsPhoneNumber
                ? 'Signed in with Google. You can add your phone number when you place your first order.'
                : 'Signed in with Google as ${profile.email}.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/customer/home');
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
          if (returnRoute != null) 'return': returnRoute,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google verified for ${result.email ?? profile.email}. Finish sign-up with your phone number.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      context.go(signupUri.toString());
      return;
    }

    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phoneNumber = '+256${_phoneController.text}';
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      phoneNumber: phoneNumber,
      password: _passwordController.text,
      rememberMe: _rememberMe,
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
  }

  @override
  Widget build(BuildContext context) {
    final altLabel = switch (_selectedRole) {
      'shopper' => 'Apply',
      'rider' => 'Apply',
      _ => 'Sign Up',
    };
    final altPrompt = switch (_selectedRole) {
      'shopper' => 'Want to shop for customers?',
      'rider' => 'Want to deliver with us?',
      _ => 'Don\'t have an account?',
    };

    return AuthShell(
      altActionLabel: altLabel,
      altActionPrompt: altPrompt,
      altActionRoute: '/signup',
      selectedRole: _selectedRole,
      child: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (!isDesktop) ...[
            const SizedBox(height: AppSizes.lg),
            SvgPicture.asset('assets/images/logos/logo-on-white.svg', height: 32),
            const SizedBox(height: AppSizes.lg),
          ],
          Text(
            'Welcome back',
            style: (isDesktop ? AppTextStyles.h1 : AppTextStyles.h2).copyWith(color: AppColors.primaryDark),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            switch (_selectedRole) {
              'shopper' => 'Sign in to pick up new orders',
              'rider' => 'Sign in to start your deliveries',
              _ => 'Sign in to continue shopping',
            },
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),

          // ─── Form card ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
                Text('Account Type', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: _RoleChip(
                        label: 'Customer',
                        icon: Iconsax.shopping_bag,
                        isSelected: _selectedRole == 'customer',
                        onTap: () => _selectRole('customer'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoleChip(
                        label: 'Shopper',
                        icon: Iconsax.bag_happy,
                        isSelected: _selectedRole == 'shopper',
                        onTap: () => _selectRole('shopper'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoleChip(
                        label: 'Rider',
                        icon: Iconsax.truck_fast,
                        isSelected: _selectedRole == 'rider',
                        onTap: () => _selectRole('rider'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),

                // Phone
                Text('Phone Number', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
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
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '7XX XXX XXX',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇺🇬', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '+256',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1.5,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.lg),
                Text('Password', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Iconsax.lock, color: AppColors.primary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textLight,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),

                // Remember me + forgot password
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.primary,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (value) => setState(() => _rememberMe = value ?? true),
                              ),
                              Expanded(
                                child: Text(
                                  'Keep me signed in',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
                          minimumSize: const Size(AppSizes.touchTargetMin, 36),
                        ),
                        child: Text(
                          'Forgot password?',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),

                // Sign in button
                CustomButton(
                  text: switch (_selectedRole) {
                    'shopper' => 'Sign in to Shopper Portal',
                    'rider' => 'Sign in to Rider Portal',
                    _ => 'Sign in to Customer Account',
                  },
                  isLoading: _isLoading,
                  onPressed: _login,
                  height: AppSizes.buttonHeightLg,
                ),

                // Google sign-in (customers only)
                if (kIsWeb && _selectedRole == 'customer') ...[
                  const SizedBox(height: AppSizes.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _continueWithGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.18)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      icon: SvgPicture.asset('assets/images/logos/google-g.svg', width: 18, height: 18),
                      label: Text(
                        'Continue with Google',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],

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
    final safeReturnRoute = sanitizeInternalReturnRoute(returnRoute);
    if (safeReturnRoute == null) {
      context.go('/customer/home');
      return;
    }

    if (safeReturnRoute.startsWith('/customer/checkout')) {
      final token = authProvider.token;
      final addressService = context.read<AddressService>();
      if (token != null && user != null && addressService.userAddresses.isEmpty) {
        final customerId = user.customerId ?? user.id;
        await addressService.fetchAddresses(token, customerId);
        if (!mounted) return;
      }

      final hasAddress = addressService.userAddresses.isNotEmpty;
      if (!hasAddress) {
        final encoded = Uri.encodeComponent(safeReturnRoute);
        context.go('/customer/addresses?return=$encoded');
        return;
      }
    }

    context.go(safeReturnRoute);
  }
}

// ─── Role chip (matches signup) ───────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

