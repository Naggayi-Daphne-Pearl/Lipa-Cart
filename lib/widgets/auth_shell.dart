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
class AuthShell extends StatefulWidget {
  /// The form content to display.
  final Widget child;

  /// Optional headline override on the brand panel (desktop only).
  /// When null, the role-specific headline from the brand theme is used.
  final String? brandHeadline;

  /// Optional sub-headline override on the brand panel (desktop only).
  /// When null, the role-specific sub-headline from the brand theme is used.
  final String? brandSubheadline;

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

  /// The currently selected role — drives the brand panel theme.
  /// Accepts 'customer', 'shopper', or 'rider'. Null defaults to customer.
  final String? selectedRole;

  static const double _desktopBreakpoint = 800;
  static const double _formMaxWidth = 440;

  const AuthShell({
    super.key,
    required this.child,
    this.brandHeadline,
    this.brandSubheadline,
    this.altActionLabel = 'Sign Up',
    this.altActionPrompt = 'Don\'t have an account?',
    this.altActionRoute = '/signup',
    this.showBackButton = false,
    this.termsPrefix = 'By continuing, you agree to our ',
    this.selectedRole,
  });

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/terms-of-service');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/privacy-policy');
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AuthShell._desktopBreakpoint;

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
        Expanded(
          flex: 5,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: _BrandPanel(
              key: ValueKey(widget.selectedRole ?? 'customer'),
              headline: widget.brandHeadline,
              subheadline: widget.brandSubheadline,
              selectedRole: widget.selectedRole ?? 'customer',
            ),
          ),
        ),
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
                        widget.altActionPrompt,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => context.push(widget.altActionRoute),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        child: Text(
                          widget.altActionLabel,
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
                        constraints: const BoxConstraints(maxWidth: AuthShell._formMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            widget.child,
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
            if (widget.showBackButton)
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
                    widget.child,
                    const SizedBox(height: AppSizes.xl),
                    // Alt-action link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.altActionPrompt,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.push(widget.altActionRoute),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(AppSizes.touchTargetMin, AppSizes.touchTargetMin),
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                          ),
                          child: Text(
                            widget.altActionLabel,
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
          text: widget.termsPrefix,
          style: AppTextStyles.caption,
          children: [
            TextSpan(
              text: 'Terms of Service',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              recognizer: _termsRecognizer,
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              recognizer: _privacyRecognizer,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Brand panel (desktop left column) ─────────────────────────────

class _RoleTheme {
  final List<Color> gradientColors;
  final String headline;
  final String subheadline;
  final List<({IconData icon, String value, String label})> badges;
  final List<({IconData icon, double dx, double dy, double size, double opacity})> sceneIcons;
  final Color? metricAccent;

  const _RoleTheme({
    required this.gradientColors,
    required this.headline,
    required this.subheadline,
    required this.badges,
    required this.sceneIcons,
    this.metricAccent,
  });
}

class _BrandPanel extends StatelessWidget {
  final String? headline;
  final String? subheadline;
  final String selectedRole;

  const _BrandPanel({
    super.key,
    this.headline,
    this.subheadline,
    required this.selectedRole,
  });

  static const _themes = <String, _RoleTheme>{
    'customer': _RoleTheme(
      gradientColors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
      headline: 'Fresh groceries,\ndelivered fast.',
      subheadline: 'Order from local markets and get it delivered to your door.',
      badges: [
        (icon: Iconsax.people, value: '10,000+', label: 'Happy customers'),
        (icon: Iconsax.star_1, value: '4.8', label: 'App rating'),
        (icon: Iconsax.timer_1, value: '30 min', label: 'Avg delivery'),
      ],
      sceneIcons: [
        (icon: Iconsax.shopping_bag5, dx: 0.82, dy: 0.18, size: 220, opacity: 0.10),
        (icon: Iconsax.cake5, dx: 0.12, dy: 0.78, size: 160, opacity: 0.09),
        (icon: Iconsax.coffee5, dx: 0.68, dy: 0.86, size: 110, opacity: 0.08),
      ],
    ),
    'shopper': _RoleTheme(
      gradientColors: [Color(0xFF00796B), Color(0xFF26A69A), Color(0xFF4DB6AC)],
      headline: 'Pick & pack\nwith care.',
      subheadline: 'Help customers get exactly what they need, every single order.',
      badges: [
        (icon: Iconsax.bag_happy, value: '500+', label: 'Daily orders'),
        (icon: Iconsax.verify, value: '99%', label: 'Accuracy rate'),
        (icon: Iconsax.money, value: 'UGX 50K+', label: 'Avg earnings/day'),
      ],
      sceneIcons: [
        (icon: Iconsax.bag_25, dx: 0.84, dy: 0.20, size: 230, opacity: 0.11),
        (icon: Iconsax.box5, dx: 0.10, dy: 0.74, size: 170, opacity: 0.10),
        (icon: Iconsax.tick_circle5, dx: 0.72, dy: 0.88, size: 100, opacity: 0.08),
      ],
    ),
    'rider': _RoleTheme(
      gradientColors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
      headline: 'Deliver fast,\nearn more.',
      subheadline: 'Get deliveries right to your zone and grow your income daily.',
      badges: [
        (icon: Iconsax.truck_fast, value: '200+', label: 'Daily deliveries'),
        (icon: Iconsax.clock, value: '95%', label: 'On-time rate'),
        (icon: Iconsax.money, value: 'UGX 80K+', label: 'Top earner/day'),
      ],
      sceneIcons: [
        (icon: Iconsax.truck_fast, dx: 0.82, dy: 0.22, size: 240, opacity: 0.12),
        (icon: Iconsax.location5, dx: 0.14, dy: 0.76, size: 160, opacity: 0.10),
        (icon: Iconsax.routing5, dx: 0.68, dy: 0.88, size: 110, opacity: 0.09),
      ],
      metricAccent: Color(0xFFFF9100),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = _themes[selectedRole] ?? _themes['customer']!;
    final displayHeadline = (headline != null && headline!.isNotEmpty) ? headline! : theme.headline;
    final displaySubheadline = (subheadline != null && subheadline!.isNotEmpty) ? subheadline! : theme.subheadline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradientColors,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _CirclePatternPainter())),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (final s in theme.sceneIcons)
                      Positioned(
                        left: constraints.maxWidth * s.dx - s.size / 2,
                        top: constraints.maxHeight * s.dy - s.size / 2,
                        child: Icon(
                          s.icon,
                          size: s.size,
                          color: Colors.white.withValues(alpha: s.opacity),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset('assets/images/logos/logo-on-green-1.svg', height: 36),
                const Spacer(),
                Text(displayHeadline, style: AppTextStyles.heroTitle),
                const SizedBox(height: 16),
                Text(displaySubheadline, style: AppTextStyles.heroBody),
                const SizedBox(height: 40),
                Row(
                  children: [
                    for (var i = 0; i < theme.badges.length; i++) ...[
                      if (i > 0) const SizedBox(width: 32),
                      _trustBadge(
                        theme.badges[i].icon,
                        theme.badges[i].value,
                        theme.badges[i].label,
                        valueColor: theme.metricAccent,
                      ),
                    ],
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

  static Widget _trustBadge(IconData icon, String value, String label, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: valueColor ?? const Color(0xB3FFFFFF), size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: valueColor != null
                  ? AppTextStyles.heroMetric.copyWith(color: valueColor)
                  : AppTextStyles.heroMetric,
            ),
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
