import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../widgets/custom_button.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String? returnRoute;

  const OtpScreen({super.key, required this.phoneNumber, this.returnRoute});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendSeconds = 60;
  Timer? _timer;

  static const double _desktopBreakpoint = 800;
  static const double _formMaxWidth = 440;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
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

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != AppConstants.otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(
      _otpController.text,
      widget.phoneNumber,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      final user = authProvider.user;
      if (user?.name == null || user?.name?.isEmpty == true) {
        context.push('/profile-completion', extra: widget.phoneNumber);
      } else {
        await _handlePostLogin(authProvider);
      }
    } else if (authProvider.errorMessage != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      _otpController.clear();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.sendOtp(widget.phoneNumber);

    if (authProvider.status == AuthStatus.otpSent) {
      _startResendTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: AppColors.success,
        ),
      );
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
        Expanded(
          flex: 5,
          child: _buildBrandPanel(),
        ),
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
          Positioned.fill(
            child: CustomPaint(painter: _CirclePatternPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/images/logos/logo-on-green-1.svg',
                  height: 32,
                ),
                const Spacer(),
                const Text(
                  'Almost there!\nVerify your number.',
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
                  'We sent a verification code to your phone.\nEnter it below to continue.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    _buildTrustBadge(
                        Iconsax.shield_tick, 'Secure', 'Verification'),
                    const SizedBox(width: 32),
                    _buildTrustBadge(Iconsax.timer_1, '60s', 'Auto-resend'),
                    const SizedBox(width: 32),
                    _buildTrustBadge(Iconsax.sms, 'SMS', 'Delivery'),
                  ],
                ),
                const Spacer(flex: 1),
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
          // Top nav bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Iconsax.arrow_left, size: 18),
                  label: Text(
                    'Back',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Need help?',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.go('/login'),
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

  // ─── Mobile: Original layout ───────────────────────────────────
  Widget _buildMobileLayout() {
    return Container(
      color: AppColors.background,
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
                      if (context.canPop()) {
                        context.pop();
                      } else {
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
                padding: const EdgeInsets.all(AppSizes.lg),
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
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: [
        if (!isDesktop) const SizedBox(height: AppSizes.lg),
        Text(
          'Verify Your Number',
          style: (isDesktop ? AppTextStyles.h1 : AppTextStyles.h3).copyWith(
            color: AppColors.primaryDark,
          ),
          textAlign: isDesktop ? TextAlign.left : null,
        ),
        const SizedBox(height: AppSizes.sm),
        Text.rich(
          TextSpan(
            text: 'We\'ve sent a 6-digit code to ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
            children: [
              TextSpan(
                text: Formatters.formatPhoneNumber(widget.phoneNumber),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xxl),
        // OTP Input card
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
            children: [
              PinCodeTextField(
                appContext: context,
                controller: _otpController,
                length: AppConstants.otpLength,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                textStyle: AppTextStyles.h4,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  fieldHeight: isDesktop ? 50 : 56,
                  fieldWidth: isDesktop ? 44 : 50,
                  activeFillColor: AppColors.lightGrey,
                  inactiveFillColor: AppColors.lightGrey,
                  selectedFillColor: AppColors.lightGrey,
                  activeColor: AppColors.primaryOrange,
                  inactiveColor: AppColors.lightGrey,
                  selectedColor: AppColors.primaryOrange,
                ),
                enableActiveFill: true,
                onCompleted: (value) => _verifyOtp(),
                onChanged: (value) {},
              ),
              const SizedBox(height: AppSizes.lg),
              // Resend timer
              _resendSeconds > 0
                  ? Text(
                      'Resend code in ${_resendSeconds}s',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    )
                  : TextButton(
                      onPressed: _resendOtp,
                      child: Text(
                        'Resend Code',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
              const SizedBox(height: AppSizes.xl),
              // Verify button
              CustomButton(
                text: 'Verify',
                isLoading: _isLoading,
                onPressed: _verifyOtp,
                height: isDesktop
                    ? AppSizes.buttonHeightMd
                    : AppSizes.buttonHeightLg,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        // Demo hint
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(
                Iconsax.info_circle,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  'Dev: Check backend console for OTP',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
      ],
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

      if (!mounted) return;
      final hasAddress = authProvider.user?.addresses.isNotEmpty == true;
      if (!hasAddress) {
        final encoded = Uri.encodeComponent(returnRoute);
        context.go('/customer/addresses?return=$encoded');
        return;
      }
    }

    if (!mounted) return;
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
