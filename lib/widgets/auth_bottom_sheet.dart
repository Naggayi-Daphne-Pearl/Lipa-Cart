import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_sizes.dart';
import '../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../services/google_oauth_service.dart';
import 'custom_button.dart';

/// Shows the auth bottom sheet modal. Returns `true` if the user
/// successfully authenticated, `false` / `null` if dismissed.
Future<bool?> showAuthBottomSheet(
  BuildContext context, {
  bool startOnSignUp = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AuthBottomSheet(startOnSignUp: startOnSignUp),
  );
}

class _AuthBottomSheet extends StatefulWidget {
  final bool startOnSignUp;
  const _AuthBottomSheet({this.startOnSignUp = false});

  @override
  State<_AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<_AuthBottomSheet> {
  late bool _isSignUp;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.startOnSignUp;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phoneNumber = '+256${_phoneController.text}';
    final authProvider = context.read<AuthProvider>();

    bool success;
    if (_isSignUp) {
      success = await authProvider.signup(
        phoneNumber: phoneNumber,
        password: _passwordController.text,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        userType: 'customer',
        rememberMe: true,
      );
    } else {
      success = await authProvider.login(
        phoneNumber: phoneNumber,
        password: _passwordController.text,
        rememberMe: true,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _continueWithGoogle() async {
    if (!kIsWeb) return;
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
      queryParameters: {'role': 'customer', 'source': _isSignUp ? 'signup' : 'login'},
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSizes.lg, 0, AppSizes.lg, AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header row: logo + close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SvgPicture.asset('assets/images/logos/logo-on-white.svg', height: 24),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.of(context).pop(false),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.grey100,
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _isSignUp ? 'Create Account' : 'Sign in to LipaCart',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 4),
            Text(
              _isSignUp
                  ? 'Set up your account to start ordering.'
                  : 'Access your orders, addresses and more',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Sign In / Sign Up tabs
            Container(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTab('Sign In', isActive: !_isSignUp, onTap: _isSignUp ? _switchMode : null),
                  _buildTab('Sign Up', isActive: _isSignUp, onTap: _isSignUp ? null : _switchMode),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Google button (web only)
            if (kIsWeb) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _continueWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.grey300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  icon: SvgPicture.asset('assets/images/logos/google-g.svg', width: 18, height: 18),
                  label: const Text('Google'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR PASSWORD',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    validator: Validators.validatePhoneNumber,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: '7XX XXX XXX',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Iconsax.call, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '+256',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 20,
                              color: AppColors.grey300,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Name + Email (sign up only)
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: AppTextStyles.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'Full name (optional)',
                        prefixIcon: Icon(Iconsax.user, color: AppColors.primary, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Enter a valid email';
                          }
                        }
                        return null;
                      },
                      style: AppTextStyles.bodyMedium,
                      decoration: const InputDecoration(
                        hintText: 'Email (optional)',
                        prefixIcon: Icon(Iconsax.sms, color: AppColors.primary, size: 18),
                      ),
                    ),
                  ],

                  // Password
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password is required';
                      if (_isSignUp && value.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Iconsax.lock, color: AppColors.primary, size: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  // Confirm password (sign up only)
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Confirm password',
                        prefixIcon: const Icon(Iconsax.lock, color: AppColors.primary, size: 18),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textLight,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                  ],

                  // Forgot password (sign in only)
                  if (!_isSignUp) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                          context.push('/forgot-password');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

                  const SizedBox(height: 16),

                  // Submit button
                  CustomButton(
                    text: _isSignUp ? 'Create Account' : 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Toggle link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSignUp ? 'Already have an account?' : 'No account?',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: _switchMode,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _isSignUp ? 'Sign In' : 'Create one free',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, {required bool isActive, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
