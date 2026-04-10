import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_sizes.dart';

/// Shared layout shell for login and signup screens.
///
/// Desktop: two-column split with a branded left panel.
/// Mobile: gradient background with centered content.
class AuthShell extends StatelessWidget {
  /// The form content to display.
  final Widget child;

  /// Headline on the brand panel (desktop only).
  final String brandHeadline;

  /// Sub-headline on the brand panel (desktop only).
  final String brandSubheadline;

  /// Label for the secondary-action link in the top-right (desktop)
  /// or bottom (mobile). e.g. "Sign Up" or "Sign In".
  final String altActionLabel;

  /// Prompt before the alt action link. e.g. "Don't have an account?"
  final String altActionPrompt;

  /// Route for the alt action link.
  final String altActionRoute;

  /// Whether to show a back button on mobile.
  final bool showBackButton;

  /// Terms prefix, e.g. "By continuing" or "By signing up".
  final String termsPrefix;

  static const double _desktopBreakpoint = 800;
  static const double _formMaxWidth = 440;

  const AuthShell({
    super.key,
    required this.child,
    this.brandHeadline = 'Fresh groceries,\ndelivered fast.',
    this.brandSubheadline =
        'Get quality produce from local markets\ndelivered right to your doorstep in Kampala.',
    this.altActionLabel = 'Sign Up',
    this.altActionPrompt = 'Don\'t have an account?',
    this.altActionRoute = '/signup',
    this.showBackButton = false,
    this.termsPrefix = 'By continuing, you agree to our ',
  });

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isDesktop(context)
          ? _buildDesktop(context)
          : _buildMobile(context),
    );
  }

  // ─── Desktop ──────────────────────────────────────────────────────
  Widget _buildDesktop(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 5, child: _BrandPanel(headline: brandHeadline, subheadline: brandSubheadline)),
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.background,
            child: Column(
              children: [
                // Top nav
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        altActionPrompt,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => context.push(altActionRoute),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        child: Text(
                          altActionLabel,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            child,
                            const SizedBox(height: AppSizes.md),
                            _buildTerms(context, isDesktop: true),
                            const SizedBox(height: AppSizes.lg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mobile ───────────────────────────────────────────────────────
  Widget _buildMobile(BuildContext context) {
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
            if (showBackButton)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    child,
                    const SizedBox(height: AppSizes.xl),
                    // Alt-action link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          altActionPrompt,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.push(altActionRoute),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(AppSizes.touchTargetMin, AppSizes.touchTargetMin),
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                          ),
                          child: Text(
                            altActionLabel,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    _buildTerms(context, isDesktop: false),
                    const SizedBox(height: AppSizes.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerms(BuildContext context, {required bool isDesktop}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : AppSizes.lg),
      child: Text.rich(
        TextSpan(
          text: termsPrefix,
          style: AppTextStyles.caption,
          children: [
            TextSpan(
              text: 'Terms of Service',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms-of-service'),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              recognizer: TapGestureRecognizer()..onTap = () => context.push('/privacy-policy'),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Brand panel (desktop left column) ─────────────────────────────
class _BrandPanel extends StatelessWidget {
  final String headline;
  final String subheadline;

  const _BrandPanel({required this.headline, required this.subheadline});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
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
                SvgPicture.asset('assets/images/logos/logo-on-green-1.svg', height: 36),
                const Spacer(),
                Text(headline, style: AppTextStyles.heroTitle),
                const SizedBox(height: 16),
                Text(subheadline, style: AppTextStyles.heroBody),
                const SizedBox(height: 40),
                Row(
                  children: [
                    _trustBadge(Iconsax.people, '10,000+', 'Happy customers'),
                    const SizedBox(width: 32),
                    _trustBadge(Iconsax.star_1, '4.8', 'App rating'),
                    const SizedBox(width: 32),
                    _trustBadge(Iconsax.timer_1, '30 min', 'Avg delivery'),
                  ],
                ),
                const Spacer(flex: 1),
                Text(
                  '${DateTime.now().year} LipaCart. All rights reserved.',
                  style: AppTextStyles.heroMeta.copyWith(color: const Color(0x73FFFFFF)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _trustBadge(IconData icon, String value, String label) {
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
}

class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), size.width * 0.3, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.75), size.width * 0.25, paint);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.85),
      size.width * 0.15,
      paint..color = Colors.white.withValues(alpha: 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
