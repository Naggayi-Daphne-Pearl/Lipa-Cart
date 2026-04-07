import 'package:flutter/gestures.dart';
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
  final String? initialRole;

  const SignupScreen({super.key, this.initialRole});

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
  static const double _desktopBreakpoint = 800;
  static const double _formMaxWidth = 440;

  @override
  void initState() {
    super.initState();
    final role = widget.initialRole;
    if (role == 'customer' || role == 'shopper' || role == 'rider') {
      _selectedRole = role!;
    }
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
        Expanded(flex: 5, child: _buildBrandPanel()),
        Expanded(flex: 5, child: _buildDesktopFormPanel()),
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
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CirclePatternPainter())),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/images/logos/logo-on-green-1.svg',
                  height: 36,
                ),
                const Spacer(),
                Text(
                  'Join the\nLipaCart family.',
                  style: AppTextStyles.heroTitle,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign up as a customer, shopper, or rider\nand be part of Kampala\'s freshest delivery network.',
                  style: AppTextStyles.heroBody,
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    _buildTrustBadge(
                      Iconsax.people,
                      '10,000+',
                      'Happy customers',
                    ),
                    const SizedBox(width: 32),
                    _buildTrustBadge(Iconsax.star_1, '4.8', 'App rating'),
                    const SizedBox(width: 32),
                    _buildTrustBadge(Iconsax.timer_1, '30 min', 'Avg delivery'),
                  ],
                ),
                const Spacer(flex: 1),
                Text(
                  '${DateTime.now().year} LipaCart. All rights reserved.',
                  style: AppTextStyles.heroMeta.copyWith(
                    color: const Color(0x73FFFFFF),
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
            Icon(icon, color: const Color(0xB3FFFFFF), size: 16),
            const SizedBox(width: 6),
            Text(value, style: AppTextStyles.heroMetric),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.heroMeta),
      ],
    );
  }

  Widget _buildSignupValueChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.primaryMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleGuidanceCard() {
    final isCustomer = _selectedRole == 'customer';
    final isShopper = _selectedRole == 'shopper';

    final message = isCustomer
        ? 'Best for grocery orders, saved addresses, and email receipts.'
        : isShopper
        ? 'Great for earning by picking and packing customer orders.'
        : 'Ideal for delivering orders and earning on your own schedule.';

    final icon = isCustomer
        ? Iconsax.shopping_bag
        : isShopper
        ? Iconsax.bag_happy
        : Iconsax.truck_fast;

    final accent = isCustomer
        ? AppColors.primaryDark
        : isShopper
        ? AppColors.info
        : AppColors.accent;

    final background = isCustomer
        ? AppColors.primarySoft
        : isShopper
        ? AppColors.cardBlue
        : AppColors.accentSoft;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFormPanel() {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Top nav bar with Sign In link
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Already have an account?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    context.canPop() ? context.pop() : context.go('/login');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  child: Text(
                    'Sign In',
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
          colors: [Color(0xFFE8F5E9), Color(0xFFF1F8E9), Color(0xFFFAFAFA)],
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
                      context.canPop() ? context.pop() : context.go('/login');
                    },
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: _buildFormContent(isDesktop: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared form content ────────────────────────────────────────
  Widget _buildFormContent({required bool isDesktop}) {
    final headerGap = isDesktop ? AppSizes.xl : AppSizes.lg;
    final cardPadding = isDesktop ? AppSizes.lg : AppSizes.md;
    final fieldGap = isDesktop ? AppSizes.lg : AppSizes.md;
    final phoneHelperText = isDesktop ? 'Uganda mobile number' : null;
    const signupBenefits = [
      {'icon': Iconsax.truck_fast, 'label': 'Track orders'},
      {'icon': Iconsax.location, 'label': 'Save addresses'},
      {'icon': Iconsax.clipboard_text, 'label': 'Reuse lists'},
    ];

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: isDesktop
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          if (!isDesktop) ...[
            const SizedBox(height: AppSizes.sm),
            SvgPicture.asset(
              'assets/images/logos/logo-on-white.svg',
              height: 32,
            ),
            const SizedBox(height: AppSizes.lg),
          ],
          // Welcome text
          Text(
            'Create Account',
            style: (isDesktop ? AppTextStyles.h1 : AppTextStyles.h2).copyWith(
              color: AppColors.primaryDark,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Save addresses, reuse shopping lists, and track every order in one place.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: signupBenefits
                .map(
                  (benefit) => _buildSignupValueChip(
                    icon: benefit['icon'] as IconData,
                    label: benefit['label'] as String,
                  ),
                )
                .toList(),
          ),
          SizedBox(height: headerGap),
          // Form card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                isDesktop ? AppSizes.radiusMd : AppSizes.radiusLg,
              ),
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
                // Account type selection
                Text(
                  'Account Type',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isDesktop ? 13 : null,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useCompactWrap =
                        !isDesktop && constraints.maxWidth < 380;

                    if (useCompactWrap) {
                      final chipWidth = (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: chipWidth,
                            child: _RoleChip(
                              label: 'Customer',
                              icon: Iconsax.shopping_bag,
                              isSelected: _selectedRole == 'customer',
                              onTap: () =>
                                  setState(() => _selectedRole = 'customer'),
                            ),
                          ),
                          SizedBox(
                            width: chipWidth,
                            child: _RoleChip(
                              label: 'Shopper',
                              icon: Iconsax.bag_happy,
                              isSelected: _selectedRole == 'shopper',
                              onTap: () =>
                                  setState(() => _selectedRole = 'shopper'),
                            ),
                          ),
                          SizedBox(
                            width: chipWidth,
                            child: _RoleChip(
                              label: 'Rider',
                              icon: Iconsax.truck_fast,
                              isSelected: _selectedRole == 'rider',
                              onTap: () =>
                                  setState(() => _selectedRole = 'rider'),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _RoleChip(
                            label: 'Customer',
                            icon: Iconsax.shopping_bag,
                            isSelected: _selectedRole == 'customer',
                            onTap: () =>
                                setState(() => _selectedRole = 'customer'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RoleChip(
                            label: 'Shopper',
                            icon: Iconsax.bag_happy,
                            isSelected: _selectedRole == 'shopper',
                            onTap: () =>
                                setState(() => _selectedRole = 'shopper'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _RoleChip(
                            label: 'Rider',
                            icon: Iconsax.truck_fast,
                            isSelected: _selectedRole == 'rider',
                            onTap: () =>
                                setState(() => _selectedRole = 'rider'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: fieldGap),
                _buildRoleGuidanceCard(),
                SizedBox(height: fieldGap),
                // Phone number
                Text(
                  'Phone Number',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isDesktop ? 13 : null,
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: isDesktop
                      ? AppTextStyles.bodyMedium
                      : AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '7XX XXX XXX',
                    helperText: phoneHelperText,
                    helperStyle: AppTextStyles.caption,
                    contentPadding: isDesktop
                        ? const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          )
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
                            style:
                                (isDesktop
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
                // Full Name
                Text(
                  'Full Name',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isDesktop ? 13 : null,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: isDesktop
                      ? AppTextStyles.bodyMedium
                      : AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'John Doe (optional)',
                    contentPadding: isDesktop
                        ? const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          )
                        : null,
                    prefixIcon: const Icon(
                      Iconsax.user,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                // Email
                Text(
                  _selectedRole == 'customer'
                      ? 'Email for receipts'
                      : 'Email (optional)',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isDesktop ? 13 : null,
                  ),
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
                  style: isDesktop
                      ? AppTextStyles.bodyMedium
                      : AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: _selectedRole == 'customer'
                        ? 'Where we send receipts and updates'
                        : 'john@example.com (optional)',
                    helperText: _selectedRole == 'customer'
                        ? 'We only use this for receipts and order updates.'
                        : null,
                    contentPadding: isDesktop
                        ? const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          )
                        : null,
                    prefixIcon: const Icon(
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
                    fontSize: isDesktop ? 13 : null,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (value) {
                    setState(
                      () => _passwordStrength = _calcPasswordStrength(value),
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  style: isDesktop
                      ? AppTextStyles.bodyMedium
                      : AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Minimum 6 characters',
                    contentPadding: isDesktop
                        ? const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          )
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
                // Password strength indicator
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
                // Confirm Password
                Text(
                  'Confirm Password',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isDesktop ? 13 : null,
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
                  style: isDesktop
                      ? AppTextStyles.bodyMedium
                      : AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    contentPadding: isDesktop
                        ? const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          )
                        : null,
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
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  onTap: () {
                    setState(() => _rememberMe = !_rememberMe);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? true);
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Keep me signed in on this device',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Recommended for your personal phone or laptop.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
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
                  height: isDesktop
                      ? AppSizes.buttonHeightMd
                      : AppSizes.buttonHeightLg,
                ),
                const SizedBox(height: AppSizes.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Iconsax.shield_tick,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedRole == 'customer'
                              ? 'Protected sign-up — we only use your email for receipts and important order updates.'
                              : 'Protected sign-up — we only use your details for account setup and important updates.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isDesktop) ...[
            const SizedBox(height: AppSizes.xl),
            // Login link (mobile only - desktop has it in top nav)
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
                    context.canPop() ? context.pop() : context.go('/login');
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
          ],
          const SizedBox(height: AppSizes.sm),
          // Terms text
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 0 : AppSizes.lg,
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
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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
