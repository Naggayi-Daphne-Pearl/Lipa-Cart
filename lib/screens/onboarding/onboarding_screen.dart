import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<void> _markOnboardingComplete() async {
    await context.read<AuthProvider>().setFirstLaunchComplete();
  }

  Future<void> _browseAsGuest() async {
    await _markOnboardingComplete();
    if (mounted) {
      context.go('/customer/home');
    }
  }

  Future<void> _goToLogin() async {
    await _markOnboardingComplete();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _goToSignup({String role = 'customer'}) async {
    await _markOnboardingComplete();
    if (mounted) {
      context.go('/signup?role=$role');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 980;
    final isTablet = size.width >= 700;
    final isSmall = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFCF7), Color(0xFFF6FAF7), Color(0xFFFFF6EC)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSizes.xl),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 11,
                            child: _buildHeroPanel(compact: false),
                          ),
                          const SizedBox(width: AppSizes.xl),
                          Expanded(
                            flex: 9,
                            child: _buildContentPanel(
                              isWide: isWide,
                              isTablet: isTablet,
                              isSmall: isSmall,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildHeroPanel(compact: isSmall),
                          const SizedBox(height: AppSizes.lg),
                          _buildContentPanel(
                            isWide: isWide,
                            isTablet: isTablet,
                            isSmall: isSmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/logos/logo-on-white.svg',
          height: 28,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        TextButton(
          onPressed: _goToLogin,
          child: Text(
            'Sign in',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        OutlinedButton(
          onPressed: _browseAsGuest,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.grey300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          ),
          child: const Text('Skip'),
        ),
      ],
    );
  }

  Widget _buildHeroPanel({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? AppSizes.md : AppSizes.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F6A3D), Color(0xFF1A8B54), Color(0xFF3BB56D)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: compact ? 84 : 120,
              height: compact ? 84 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: compact ? -18 : 40,
            left: -35,
            child: Container(
              width: compact ? 64 : 90,
              height: compact ? 64 : 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _GlassPill(
                icon: Iconsax.flash_1,
                label: 'Fresh picks in 15–30 min',
              ),
              SizedBox(height: compact ? AppSizes.md : AppSizes.lg),
              Text(
                'Fresh groceries made simple.',
                style: AppTextStyles.heroTitle.copyWith(
                  fontSize: compact ? 28 : 34,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Browse essentials, discover local favorites, and follow every order from checkout to doorstep.',
                style: AppTextStyles.heroBody.copyWith(
                  fontSize: compact ? 15 : 16,
                ),
              ),
              SizedBox(height: compact ? AppSizes.md : AppSizes.lg),
              if (compact)
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: const [
                    _GlassPill(
                      icon: Icons.storefront_outlined,
                      label: 'Browse first',
                    ),
                    _GlassPill(
                      icon: Icons.delivery_dining_outlined,
                      label: 'Fast delivery',
                    ),
                    _GlassPill(
                      icon: Iconsax.map_1,
                      label: 'Track live',
                    ),
                  ],
                )
              else ...[
                Wrap(
                  spacing: AppSizes.md,
                  runSpacing: AppSizes.md,
                  children: const [
                    _MetricTile(value: '400+', label: 'Fresh products'),
                    _MetricTile(value: '4.8★', label: 'Trusted shoppers'),
                    _MetricTile(value: 'Live', label: 'Order tracking'),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                Wrap(
                  spacing: AppSizes.md,
                  runSpacing: AppSizes.md,
                  children: const [
                    _ProduceTile(
                      icon: Icons.eco_outlined,
                      title: 'Leafy greens',
                      subtitle: 'Fresh today',
                    ),
                    _ProduceTile(
                      icon: Icons.local_florist_outlined,
                      title: 'Seasonal fruits',
                      subtitle: 'Sweet & ripe',
                    ),
                    _ProduceTile(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Pantry staples',
                      subtitle: 'Always handy',
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.delivery_dining_outlined,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live rider updates',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Know how far your order is and when it gets to you.',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Iconsax.arrow_right_3,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentPanel({
    required bool isWide,
    required bool isTablet,
    required bool isSmall,
  }) {
    final titleSize = isSmall ? 28.0 : (isWide ? 46.0 : (isTablet ? 38.0 : 32.0));

    return Container(
      padding: EdgeInsets.all(isSmall ? 20 : (isWide ? AppSizes.xl : AppSizes.lg)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.grey200),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WELCOME TO LIPACART', style: AppTextStyles.overlineAccent),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Everything you need to shop smarter.',
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: titleSize,
              height: 1.08,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'LipaCart helps you browse groceries, save time with lists, and track your order all the way home.',
            style: AppTextStyles.screenSubtitle.copyWith(
              fontSize: isSmall ? 15 : 16,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: const [
              _SoftFeaturePill(
                icon: Icons.storefront_outlined,
                label: 'Fresh groceries',
              ),
              _SoftFeaturePill(
                icon: Iconsax.note_1,
                label: 'Shopping lists',
              ),
              _SoftFeaturePill(
                icon: Iconsax.routing_2,
                label: 'Live tracking',
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.primarySoft),
            ),
            child: const Column(
              children: [
                _FeatureLine(
                  icon: Iconsax.shopping_bag,
                  title: 'Browse daily essentials',
                  subtitle: 'Shop produce, pantry items, and home basics in one place.',
                ),
                SizedBox(height: AppSizes.sm),
                _FeatureLine(
                  icon: Iconsax.note_21,
                  title: 'Save lists and reorder faster',
                  subtitle: 'Keep your regular picks close and shop again with less effort.',
                ),
                SizedBox(height: AppSizes.sm),
                _FeatureLine(
                  icon: Iconsax.location,
                  title: 'Track every order live',
                  subtitle: 'Follow your shopper or rider from pickup to doorstep.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _browseAsGuest,
              icon: const Icon(Iconsax.shopping_bag, size: 18),
              label: const Text('Get started'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, AppSizes.buttonHeightLg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _goToLogin,
              icon: const Icon(Iconsax.login, size: 18),
              label: const Text('Sign in'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.grey300),
                minimumSize: const Size(double.infinity, AppSizes.buttonHeightLg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Center(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.bodySmall,
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: _goToLogin,
                      child: Text(
                        'Sign in',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          Text('Want to earn with LipaCart?', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSizes.sm),
          _RoleEntry(
            icon: Iconsax.bag_happy,
            title: 'Become a shopper',
            subtitle: 'Pick and pack customer orders with care.',
            accent: const Color(0xFF1D7EDE),
            onTap: () => _goToSignup(role: 'shopper'),
          ),
          const SizedBox(height: AppSizes.sm),
          _RoleEntry(
            icon: Iconsax.truck_fast,
            title: 'Ride with us',
            subtitle: 'Deliver groceries fast and earn on your schedule.',
            accent: AppColors.accent,
            onTap: () => _goToSignup(role: 'rider'),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GlassPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String value;
  final String label;

  const _MetricTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.heroMetric),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.heroMeta),
        ],
      ),
    );
  }
}

class _ProduceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProduceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftFeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SoftFeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}

class _RoleEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _RoleEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Ink(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.cardSubtitle),
                  ],
                ),
              ),
              Icon(Iconsax.arrow_right_3, size: 18, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.cardTitle),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.cardSubtitle),
            ],
          ),
        ),
      ],
    );
  }
}
