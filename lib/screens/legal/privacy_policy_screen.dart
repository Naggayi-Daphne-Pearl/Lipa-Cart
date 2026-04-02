import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const Text('Privacy Policy'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Policy', style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(
                  'Last updated: April 2, 2026',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.lg),
                _section('1. Information We Collect',
                    'We collect information you provide directly: name, phone number, email address, delivery addresses, and GPS location. We also collect order history, payment information, and device information (including FCM tokens for push notifications).'),
                _section('2. How We Use Your Information',
                    'We use your information to: process and deliver orders, send order status notifications and updates, improve our services, communicate promotions (with your consent), verify identity for shoppers and riders (KYC), and comply with legal obligations.'),
                _section('3. Information Sharing',
                    'We share your delivery address and name with assigned shoppers and riders to fulfill orders. We do not sell your personal information to third parties. We may share data with payment processors (Mobile Money providers, card networks) to process transactions.'),
                _section('4. Data Storage and Security',
                    'Your data is stored securely on our servers. We use encryption for data in transit and at rest. Authentication tokens are stored securely on your device. We retain your data for as long as your account is active or as needed to provide services.'),
                _section('5. Push Notifications',
                    'We use Firebase Cloud Messaging to send push notifications about order status changes, delivery updates, and promotional offers. You can disable push notifications in your device settings at any time.'),
                _section('6. Location Data',
                    'We collect GPS location to verify delivery addresses and calculate delivery distances. Location data is only collected when you actively use the address selection feature. We do not track your location in the background.'),
                _section('7. SMS Communications',
                    'We send OTP codes via SMS for account verification. Standard messaging rates from your carrier may apply.'),
                _section('8. Your Rights',
                    'You have the right to: access your personal data, correct inaccurate data, request deletion of your account and data, opt out of promotional communications, and export your data. To exercise these rights, contact us at daphnepearl101@gmail.com.'),
                _section('9. Account Deletion',
                    'You may request account deletion at any time through the app settings or by contacting support. Upon deletion, we will remove your personal data within 30 days, except where retention is required by law.'),
                _section('10. Children\'s Privacy',
                    'Our service is not directed to individuals under 18. We do not knowingly collect personal information from children.'),
                _section('11. Changes to This Policy',
                    'We may update this Privacy Policy periodically. We will notify you of material changes through the app or via email.'),
                _section('12. Contact Us',
                    'For privacy-related questions, contact us at daphnepearl101@gmail.com.'),
                const SizedBox(height: AppSizes.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSizes.xs),
          Text(body, style: AppTextStyles.bodyMedium.copyWith(height: 1.6, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
