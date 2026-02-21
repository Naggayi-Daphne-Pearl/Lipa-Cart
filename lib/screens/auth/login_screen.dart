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
  bool _usePassword = true; // true = password login, false = OTP login
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Format phone number with +256 prefix
    final phoneNumber = '+256${_phoneController.text}';

    final authProvider = context.read<AuthProvider>();

    if (_usePassword) {
      // Login with password
      final success = await authProvider.login(
        phoneNumber: phoneNumber,
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;
        // Navigate based on role
        final role = authProvider.user?.role.name ?? 'customer';
        context.go('/$role/home');
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
      // Send OTP
      await authProvider.sendOtp(phoneNumber);

      setState(() => _isLoading = false);

      if (authProvider.status == AuthStatus.otpSent) {
        if (!mounted) return;
        context.push('/otp', extra: phoneNumber);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.xxl),
                // Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1B7F4E), Color(0xFF15874B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SvgPicture.asset(
                        'assets/images/logos/logo-on-green-1.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),
                // Welcome text
                Text('Welcome to LipaCart', style: AppTextStyles.h3),
                const SizedBox(height: AppSizes.sm),
                Text(
                  _usePassword
                      ? 'Enter your phone number and password to login.'
                      : 'Enter your phone number. We\'ll send you a verification code.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                // Phone input
                Text('Phone Number', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: Validators.validatePhoneNumber,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '7XX XXX XXX',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.call,
                            color: AppColors.textLight,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+256',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 24,
                            color: AppColors.mediumGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Password field (conditional)
                if (_usePassword) ...[
                  const SizedBox(height: AppSizes.lg),
                  Text('Password', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (_usePassword && (value == null || value.isEmpty)) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(
                        Iconsax.lock,
                        color: AppColors.textLight,
                        size: 22,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
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
                ],
                const SizedBox(height: AppSizes.xl),
                // Login/Continue button
                CustomButton(
                  text: _usePassword ? 'Login' : 'Continue',
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: AppSizes.md),
                // Toggle login method
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
                          ? 'Login with OTP instead'
                          : 'Login with password instead',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                // Sign up link
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.push('/signup');
                    },
                    child: Text.rich(
                      TextSpan(
                        text: 'Don\'t have an account? ',
                        style: AppTextStyles.bodyMedium,
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                // Terms text
                Center(
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
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
