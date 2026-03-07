import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

enum _Step { phone, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _Step _currentStep = _Step.phone;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _resendSeconds = 0;
  Timer? _timer;

  String get _fullPhoneNumber => '+256${_phoneController.text}';

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = AppConstants.otpResendDelay.inSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  // Step 1: Send OTP via forgot password endpoint (validates user exists)
  Future<void> _sendOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(_fullPhoneNumber);

    setState(() => _isLoading = false);

    if (success) {
      _startResendTimer();
      setState(() => _currentStep = _Step.otp);
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

  // Step 2: OTP verified + password set in one call via reset endpoint
  Future<void> _verifyOtp() async {
    if (_otpController.text.length != AppConstants.otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Move to password step — OTP will be verified together with password reset
    setState(() => _currentStep = _Step.newPassword);
  }

  // Step 3: Reset password (sends OTP + new password to backend in one call)
  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      phoneNumber: _fullPhoneNumber,
      otp: _otpController.text,
      newPassword: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please sign in.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/login');
    } else if (authProvider.errorMessage != null) {
      if (!mounted) return;
      // If OTP was invalid, go back to OTP step
      if (authProvider.errorMessage!.contains('Invalid') ||
          authProvider.errorMessage!.contains('expired')) {
        setState(() {
          _currentStep = _Step.otp;
          _otpController.clear();
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(_fullPhoneNumber);

    if (success) {
      _startResendTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code sent successfully'),
          backgroundColor: AppColors.success,
        ),
      );
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
                        if (_currentStep == _Step.phone) {
                          context.canPop()
                              ? context.pop()
                              : context.go('/login');
                        } else if (_currentStep == _Step.otp) {
                          setState(() {
                            _currentStep = _Step.phone;
                            _otpController.clear();
                          });
                        } else {
                          // On password step, go back to OTP isn't useful
                          // Just go back to login
                          context.go('/login');
                        }
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
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizes.md),
                      // Logo
                      SvgPicture.asset(
                        'assets/images/logos/logo-on-white.svg',
                        height: 32,
                      ),
                      const SizedBox(height: AppSizes.xl),
                      // Step indicator
                      _buildStepIndicator(),
                      const SizedBox(height: AppSizes.xl),
                      // Step content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildStepContent(),
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),
                      // Back to login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remember your password?',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
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
                      const SizedBox(height: AppSizes.lg),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      ('Phone', _Step.phone),
      ('Verify', _Step.otp),
      ('Reset', _Step.newPassword),
    ];
    final currentIndex = _currentStep.index;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          final isCompleted = stepIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? AppColors.primary
                  : AppColors.grey300,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isActive = stepIndex == currentIndex;
        final isCompleted = stepIndex < currentIndex;

        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary
                : isActive
                    ? AppColors.primary
                    : AppColors.grey200,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${stepIndex + 1}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case _Step.phone:
        return _buildPhoneStep();
      case _Step.otp:
        return _buildOtpStep();
      case _Step.newPassword:
        return _buildPasswordStep();
    }
  }

  // Step 1: Enter phone number
  Widget _buildPhoneStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        key: const ValueKey('phone'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Iconsax.lock_1,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Center(
            child: Text(
              'Reset Password',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Center(
            child: Text(
              'Enter your phone number and we\'ll send\nyou a verification code',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
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
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
          CustomButton(
            text: 'Send Code',
            isLoading: _isLoading,
            onPressed: _sendOtp,
          ),
        ],
      ),
    );
  }

  // Step 2: Enter OTP
  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Iconsax.sms,
            color: AppColors.accent,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          'Enter Verification Code',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'We sent a 6-digit code to\n$_fullPhoneNumber',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.lg),
        PinCodeTextField(
          appContext: context,
          controller: _otpController,
          length: AppConstants.otpLength,
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          textStyle: AppTextStyles.h4,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            fieldHeight: 52,
            fieldWidth: 46,
            activeFillColor: AppColors.grey100,
            inactiveFillColor: AppColors.grey100,
            selectedFillColor: AppColors.grey100,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.grey200,
            selectedColor: AppColors.primary,
          ),
          enableActiveFill: true,
          onCompleted: (value) => _verifyOtp(),
          onChanged: (value) {},
        ),
        const SizedBox(height: AppSizes.sm),
        _resendSeconds > 0
            ? Text(
                'Resend code in ${_resendSeconds}s',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : TextButton(
                onPressed: _resendOtp,
                child: Text(
                  'Resend Code',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        const SizedBox(height: AppSizes.lg),
        CustomButton(
          text: 'Verify Code',
          isLoading: _isLoading,
          onPressed: _verifyOtp,
        ),
      ],
    );
  }

  // Step 3: Set new password
  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        key: const ValueKey('password'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Iconsax.shield_tick,
                color: AppColors.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Center(
            child: Text(
              'Create New Password',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Center(
            child: Text(
              'Your new password must be at least\n6 characters long',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(
            'New Password',
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
              hintText: 'Enter new password',
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
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Confirm Password',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
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
              hintText: 'Confirm new password',
              prefixIcon: const Icon(
                Iconsax.lock,
                color: AppColors.primary,
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textLight,
                  size: 22,
                ),
                onPressed: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          CustomButton(
            text: 'Reset Password',
            isLoading: _isLoading,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }
}
