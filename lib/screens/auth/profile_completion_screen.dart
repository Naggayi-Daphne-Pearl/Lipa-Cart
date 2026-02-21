import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final String phoneNumber;

  const ProfileCompletionScreen({super.key, required this.phoneNumber});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    // Update user profile with name, email, password, and user_type
    await authProvider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      userType: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      // Navigate based on user role
      if (authProvider.user != null) {
        final role = authProvider.user?.role;
        final route = _homeForRole(role);
        context.go(route);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete profile. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  String _homeForRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return '/admin/dashboard';
      case UserRole.rider:
        return '/rider/home';
      case UserRole.shopper:
        return '/shopper/home';
      case UserRole.customer:
      default:
        return '/customer/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.md),
                // Header
                Text('Complete Your Profile', style: AppTextStyles.h3),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Tell us a bit about yourself to get started.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),

                // Phone number display (read-only)
                Text('Phone Number', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSizes.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey200),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    color: AppColors.grey50,
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.call, color: AppColors.textLight),
                      const SizedBox(width: AppSizes.md),
                      Text(widget.phoneNumber, style: AppTextStyles.bodyLarge),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Full Name (required)
                Text('Full Name *', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'e.g., John Doe',
                    prefixIcon: const Icon(
                      Iconsax.user,
                      color: AppColors.textLight,
                    ),
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Email (optional)
                Text(
                  'Email Address (Optional)',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return Validators.validateEmail(value);
                    }
                    return null;
                  },
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'e.g., john@example.com',
                    prefixIcon: const Icon(
                      Iconsax.sms,
                      color: AppColors.textLight,
                    ),
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Password (required)
                Text('Password *', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(
                      Iconsax.lock,
                      color: AppColors.textLight,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                        color: AppColors.textLight,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Confirm Password (required)
                Text('Confirm Password *', style: AppTextStyles.labelMedium),
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
                      color: AppColors.textLight,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Iconsax.eye_slash
                            : Iconsax.eye,
                        color: AppColors.textLight,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // User Type (required)
                Text('I am a *', style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSizes.sm),
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Iconsax.briefcase,
                      color: AppColors.textLight,
                    ),
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: UserRole.customer,
                      child: Row(
                        children: [
                          const Icon(Iconsax.shopping_bag, size: 18),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Customer - Buy groceries',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: UserRole.shopper,
                      child: Row(
                        children: [
                          const Icon(Iconsax.shopping_cart, size: 18),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Shopper - Shop for others',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: UserRole.rider,
                      child: Row(
                        children: [
                          const Icon(Iconsax.driving, size: 18),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Rider - Deliver orders',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (UserRole? value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a user type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.xl),

                // Info text
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.info_circle,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Text(
                          'You can change your role later in settings.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),

                // Complete button
                CustomButton(
                  text: 'Continue',
                  isLoading: _isLoading,
                  onPressed: _completeProfile,
                ),
                const SizedBox(height: AppSizes.xl),

                // Skip option
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            context.go('/customer/home');
                          },
                    child: Text(
                      'Skip for now',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
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
