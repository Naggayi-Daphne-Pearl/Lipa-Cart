import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help & Support'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.message_question, color: Colors.white, size: 36),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('How can we help?', style: AppTextStyles.h4.copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                              'We\'re here to assist you with your orders and account.',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                // Contact Options
                Text('Contact Us', style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.md),
                _buildContactTile(
                  icon: Iconsax.send_2,
                  title: 'WhatsApp',
                  subtitle: 'Chat with us on WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => launchUrl(Uri.parse('https://wa.me/256785796401?text=Hi%20LipaCart%2C%20I%20need%20help')),
                ),
                _buildContactTile(
                  icon: Iconsax.sms,
                  title: 'Email Support',
                  subtitle: 'daphnepearl101@gmail.com',
                  color: AppColors.accent,
                  onTap: () => launchUrl(Uri.parse('mailto:daphnepearl101@gmail.com')),
                ),
                _buildContactTile(
                  icon: Iconsax.call,
                  title: 'Call Us',
                  subtitle: '+256 7857896401',
                  color: AppColors.primary,
                  onTap: () => launchUrl(Uri(scheme: 'tel', path: '+256785796401')),
                ),

                const SizedBox(height: AppSizes.xl),

                // FAQ Section
                Text('Frequently Asked Questions', style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSizes.md),
                _buildFaqTile('How do I track my order?', 'Go to Orders from the bottom navigation or your profile. Tap on any active order to see real-time tracking.'),
                _buildFaqTile('What is the delivery fee?', 'Delivery fee is UGX 3,000. Orders above UGX 50,000 qualify for free delivery.'),
                _buildFaqTile('How do I cancel an order?', 'You can cancel an order before shopping begins. Go to order tracking and tap "Cancel Order".'),
                _buildFaqTile('What payment methods do you accept?', 'We accept Mobile Money (MTN MoMo, Airtel Money), debit/credit cards, and Cash on Delivery.'),
                _buildFaqTile('How do I report a problem with my order?', 'On your delivered order, tap "Report Issue" to select the problem type and submit details.'),
                _buildFaqTile('Can I change my delivery address?', 'You can manage your addresses from Profile → Addresses. Select a different address during checkout.'),

                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: AppTextStyles.labelMedium),
        subtitle: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        trailing: Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        tileColor: AppColors.surface,
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ExpansionTile(
        title: Text(question, style: AppTextStyles.labelMedium),
        collapsedBackgroundColor: AppColors.surface,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
