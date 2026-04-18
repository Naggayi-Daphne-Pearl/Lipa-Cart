import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../core/constants/app_sizes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/responsive.dart';

/// Desktop/tablet footer. Renders nothing on mobile — bottom nav handles that.
/// Matches `DesktopTopNavBar`'s floating-card aesthetic but with a darker
/// primary surface to anchor the bottom of the page.
class DesktopFooter extends StatelessWidget {
  const DesktopFooter({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        AppSizes.xxl,
        context.horizontalPadding,
        AppSizes.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.xl),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        child: Column(
          children: [
            Wrap(
              spacing: AppSizes.xl,
              runSpacing: AppSizes.xl,
              children: [
                _BrandColumn(),
                _LinkColumn(
                  title: 'Shop',
                  links: const [
                    _FooterLink('Browse products', '/customer/browse'),
                    _FooterLink('Categories', '/customer/categories'),
                    _FooterLink('Recipes', '/customer/recipes'),
                    _FooterLink('My Lists', '/customer/shopping-lists'),
                  ],
                ),
                _LinkColumn(
                  title: 'Support',
                  links: const [
                    _FooterLink('My orders', '/customer/orders'),
                    _FooterLink('Profile', '/customer/profile'),
                    _FooterLink('Terms of service', '/terms-of-service'),
                    _FooterLink('Privacy policy', '/privacy-policy'),
                  ],
                ),
                _ConnectColumn(),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
            Divider(color: AppColors.white.withValues(alpha: 0.12)),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© ${DateTime.now().year} LipaCart · Made with ♥ in Kampala',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  'UGX · Uganda',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/images/logos/logo-on-green-1.svg',
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Fresh groceries from local Kampala markets — delivered to your door in 30 minutes.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.78),
              height: 1.55,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              _trustBadge(Iconsax.truck_fast, 'Free > UGX 50k'),
              const SizedBox(width: AppSizes.sm),
              _trustBadge(Iconsax.timer_1, '30 min avg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.white.withValues(alpha: 0.78)),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkColumn extends StatelessWidget {
  final String title;
  final List<_FooterLink> links;

  const _LinkColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          ...links.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => context.push(l.route),
                child: Text(
                  l.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.72),
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              _socialIcon(Iconsax.instagram),
              const SizedBox(width: AppSizes.sm),
              _socialIcon(Iconsax.global),
              const SizedBox(width: AppSizes.sm),
              _socialIcon(Iconsax.message_text1),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Payments',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              _PaymentBadge(label: 'MTN MoMo'),
              _PaymentBadge(label: 'Airtel'),
              _PaymentBadge(label: 'Cash'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Icon(icon, size: 16, color: AppColors.white.withValues(alpha: 0.82)),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String label;
  const _PaymentBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _FooterLink {
  final String label;
  final String route;
  const _FooterLink(this.label, this.route);
}
