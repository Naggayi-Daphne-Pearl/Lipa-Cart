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
import '../../models/user.dart';
import '../../widgets/custom_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

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
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'customer';

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final phoneNumber = '+256${_phoneController.text}';

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signup(
      phoneNumber: phoneNumber,
      password: _passwordController.text,
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      userType: _selectedRole,
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
        context.go('/rider/home');
        break;
      case UserRole.admin:
        context.go('/admin/dashboard');
        break;
      case UserRole.customer:
        context.go('/customer/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.arrow_left),
                      onPressed: () {
                        context.canPop()
                            ? context.pop()
                            : context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSizes.md),
                        // Logo wordmark - matches login
                        SvgPicture.asset(
                          'assets/images/logos/logo-on-white.svg',
                          height: 36,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        // Welcome text - centered, professional
                        Text(
                          'Create Account',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primaryDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Sign up to get fresh groceries delivered',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        // Form card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.lg),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusLg),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Account type selection
                              Text(
                                'Account Type',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RoleChip(
                                      label: 'Customer',
                                      icon: Iconsax.shopping_bag,
                                      isSelected:
                                          _selectedRole == 'customer',
                                      onTap: () => setState(
                                        () => _selectedRole = 'customer',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _RoleChip(
                                      label: 'Shopper',
                                      icon: Iconsax.bag_happy,
                                      isSelected:
                                          _selectedRole == 'shopper',
                                      onTap: () => setState(
                                        () => _selectedRole = 'shopper',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _RoleChip(
                                      label: 'Rider',
                                      icon: Iconsax.truck_fast,
                                      isSelected: _selectedRole == 'rider',
                                      onTap: () => setState(
                                        () => _selectedRole = 'rider',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.lg),
                              // Phone number
                              Text(
                                'Phone Number',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
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
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                style: AppTextStyles.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: '7XX XXX XXX',
                                  helperText: 'Uganda mobile number',
                                  helperStyle: AppTextStyles.caption,
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
                                          style: AppTextStyles.bodyLarge
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
                                            color: AppColors.primary
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),
                              // Full Name
                              Text(
                                'Full Name',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              TextFormField(
                                controller: _nameController,
                                keyboardType: TextInputType.name,
                                textCapitalization:
                                    TextCapitalization.words,
                                style: AppTextStyles.bodyLarge,
                                decoration: const InputDecoration(
                                  hintText: 'John Doe (optional)',
                                  prefixIcon: Icon(
                                    Iconsax.user,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),
                              // Email
                              Text(
                                'Email',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value != null &&
                                      value.isNotEmpty) {
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return 'Enter a valid email';
                                    }
                                  }
                                  return null;
                                },
                                style: AppTextStyles.bodyLarge,
                                decoration: const InputDecoration(
                                  hintText: 'john@example.com (optional)',
                                  prefixIcon: Icon(
                                    Iconsax.sms,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),
                              // Password
                              Text(
                                'Password',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                style: AppTextStyles.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: 'Minimum 6 characters',
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
                                        _obscurePassword =
                                            !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),
                              // Confirm Password
                              Text(
                                'Confirm Password',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                style: AppTextStyles.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: 'Re-enter your password',
                                  prefixIcon: const Icon(
                                    Iconsax.lock,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textLight,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSizes.lg),
                              // Sign up button
                              CustomButton(
                                text: 'Sign Up',
                                isLoading: _isLoading,
                                onPressed: _signup,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.xl),
                        // Login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.canPop()
                                    ? context.pop()
                                    : context.go('/login');
                              },
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
                                'Sign In',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.sm),
                        // Terms text
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                          ),
                          child: Text.rich(
                            TextSpan(
                              text: 'By signing up, you agree to our ',
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
                        const SizedBox(height: AppSizes.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
            color: isSelected
                ? AppColors.primary
                : AppColors.grey300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
