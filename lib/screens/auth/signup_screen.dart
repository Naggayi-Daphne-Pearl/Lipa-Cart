import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../services/google_oauth_service.dart';
import '../../models/user.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/auth_shell.dart';

class SignupScreen extends StatefulWidget {
  final String? initialRole;
  final String? initialName;
  final String? initialEmail;
  final String? oauthProvider;

  const SignupScreen({
    super.key,
    this.initialRole,
    this.initialName,
    this.initialEmail,
    this.oauthProvider,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  double _passwordStrength = 0;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;
  String _selectedRole = 'customer';
  bool _googlePrefillActive = false;

  @override
  void initState() {
    super.initState();
    _googlePrefillActive = widget.oauthProvider == 'google';
    final role = widget.initialRole;
    if (_googlePrefillActive) {
      _selectedRole = 'customer';
    } else if (role == 'customer' || role == 'shopper' || role == 'rider') {
      _selectedRole = role!;
    }
    _nameController.text = widget.initialName?.trim() ?? '';
    _emailController.text = widget.initialEmail?.trim() ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        _handlePostSignup(authProvider);
        return;
      }
      await _handleGoogleOAuthCallback();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleOAuthCallback() async {
    final profile = GoogleOAuthService.readProfileFromCurrentUrl();
    if (profile == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _googlePrefillActive = true;
      _selectedRole = 'customer';
    });

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.signInWithGoogle(
      profile.idToken,
      rememberMe: _rememberMe,
      userType: 'customer',
    );

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      _handlePostSignup(authProvider);
      return;
    }

    if (result.success) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.needsPhoneNumber
                ? 'Your customer account is ready. Add your phone number when you place your first order.'
                : 'Signed in with Google as ${profile.email}.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/customer/home');
      return;
    }

    if (result.needsSignup) {
      setState(() {
        _isLoading = false;
        _googlePrefillActive = true;
        _selectedRole = 'customer';
        _nameController.text = (result.name ?? profile.name ?? '').trim();
        _emailController.text = (result.email ?? profile.email).trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Almost there — add your phone number and password to finish.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isLoading = false);
    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _continueWithGoogle() async {
    if (_selectedRole != 'customer') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-up is available for customers only.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

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
      queryParameters: {'role': 'customer', 'source': 'signup'},
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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phoneNumber = '+256${_phoneController.text}';

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signup(
      phoneNumber: phoneNumber,
      password: _passwordController.text,
      name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      userType: _selectedRole,
      rememberMe: _rememberMe,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      _handlePostSignup(authProvider);
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

  void _handlePostSignup(AuthProvider authProvider) {
    final user = authProvider.user;
    final role = user?.role ?? UserRole.customer;

    switch (role) {
      case UserRole.shopper:
        context.go('/shopper/kyc');
        break;
      case UserRole.rider:
        context.go('/rider/kyc');
        break;
      case UserRole.admin:
        context.go('/admin/dashboard');
        break;
      case UserRole.customer:
        context.go('/customer/home');
        break;
    }
  }

  double _calcPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.1;
    if (password.length >= 12) strength += 0.1;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#\$%\^&\*\(\)_\+\-=]').hasMatch(password)) strength += 0.2;
    return strength.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      brandHeadline: 'Join the\nLipaCart family.',
      brandSubheadline: 'Sign up as a customer, shopper, or rider\nand be part of Kampala\'s freshest delivery network.',
      altActionLabel: 'Sign In',
      altActionPrompt: 'Already have an account?',
      altActionRoute: '/login',
      showBackButton: true,
      termsPrefix: 'By signing up, you agree to our ',
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
            const SizedBox(height: AppSizes.sm),
            SvgPicture.asset('assets/images/logos/logo-on-white.svg', height: 32),
            const SizedBox(height: AppSizes.lg),
          ],
          Text(
            'Create Account',
            style: (isDesktop ? AppTextStyles.h1 : AppTextStyles.h2).copyWith(color: AppColors.primaryDark),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Set up your account to start ordering.',
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
                // Account type
                Text('Account Type', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSizes.sm),
                if (_googlePrefillActive)
                  _RoleChip(label: 'Customer', icon: Iconsax.shopping_bag, isSelected: true, onTap: () {})
                else
                  Row(
                    children: [
                      Expanded(
                        child: _RoleChip(
                          label: 'Customer',
                          icon: Iconsax.shopping_bag,
                          isSelected: _selectedRole == 'customer',
                          onTap: () => setState(() => _selectedRole = 'customer'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RoleChip(
                          label: 'Shopper',
                          icon: Iconsax.bag_happy,
                          isSelected: _selectedRole == 'shopper',
                          onTap: () => setState(() => _selectedRole = 'shopper'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RoleChip(
                          label: 'Rider',
                          icon: Iconsax.truck_fast,
                          isSelected: _selectedRole == 'rider',
                          onTap: () => setState(() => _selectedRole = 'rider'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSizes.lg),

                // Google sign-up (customers on web only)
                if (kIsWeb && _selectedRole == 'customer') ...[
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
                  const SizedBox(height: AppSizes.lg),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],

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
                          const Icon(Iconsax.call, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
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

                // Name
                Text('Full Name', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: AppTextStyles.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'John Doe (optional)',
                    prefixIcon: Icon(Iconsax.user, color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Email
                Text(
                  _selectedRole == 'customer' ? 'Email' : 'Email (optional)',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (_selectedRole == 'customer') {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required for customers';
                      }
                    }
                    if (value != null && value.isNotEmpty) {
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Enter a valid email';
                      }
                    }
                    return null;
                  },
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: _selectedRole == 'customer' ? 'you@example.com' : 'john@example.com (optional)',
                    prefixIcon: const Icon(Iconsax.sms, color: AppColors.primary, size: 20),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Password
                Text('Password', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (value) => setState(() => _passwordStrength = _calcPasswordStrength(value)),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Password is required';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Minimum 6 characters',
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
                // Password strength
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      minHeight: 4,
                      backgroundColor: AppColors.grey200,
                      valueColor: AlwaysStoppedAnimation(
                        _passwordStrength < 0.3
                            ? AppColors.error
                            : _passwordStrength < 0.6
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _passwordStrength < 0.3
                        ? 'Weak'
                        : _passwordStrength < 0.6
                            ? 'Fair'
                            : _passwordStrength < 0.8
                                ? 'Good'
                                : 'Strong',
                    style: AppTextStyles.caption.copyWith(
                      color: _passwordStrength < 0.3
                          ? AppColors.error
                          : _passwordStrength < 0.6
                              ? AppColors.warning
                              : AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.lg),

                // Confirm password
                Text('Confirm Password', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Iconsax.lock, color: AppColors.primary, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textLight,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Remember me
                InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
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
                const SizedBox(height: AppSizes.md),

                // Sign up button
                CustomButton(
                  text: 'Create My Account',
                  isLoading: _isLoading,
                  onPressed: _signup,
                  height: AppSizes.buttonHeightLg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
