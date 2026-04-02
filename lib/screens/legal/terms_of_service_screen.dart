import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
        title: const Text('Terms of Service'),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Terms of Service', style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(
                  'Last updated: April 2, 2026',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSizes.lg),
                _section('1. Acceptance of Terms',
                    'By downloading, installing, or using the LipaCart application, you agree to be bound by these Terms of Service. If you do not agree, do not use the application.'),
                _section('2. Description of Service',
                    'LipaCart is a grocery delivery platform connecting customers with personal shoppers and delivery riders. We facilitate the ordering, shopping, and delivery of grocery items in Uganda and Kenya.'),
                _section('3. User Accounts',
                    'You must provide accurate and complete information when creating an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities under your account. You must be at least 18 years old to use our services.'),
                _section('4. Orders and Payments',
                    'All orders are subject to product availability. Prices displayed are in Uganda Shillings (UGX) and may change without notice. A 5% service fee applies to all orders. Delivery fees are calculated based on distance; orders above UGX 50,000 qualify for free delivery. We accept Mobile Money, card payments, and cash on delivery.'),
                _section('5. Cancellations and Refunds',
                    'Orders may be cancelled before a shopper begins shopping. Once shopping has commenced, cancellation may not be possible. Refunds for cancelled orders are processed within 3-5 business days to your original payment method. Cash on delivery orders that are cancelled incur no charge.'),
                _section('6. Delivery',
                    'Delivery times are estimated and not guaranteed. We deliver within designated service areas in Kampala and select Kenyan cities. You must provide accurate delivery address information and be available to receive your order.'),
                _section('7. Product Quality',
                    'Our shoppers select the freshest available items. If you receive damaged, expired, or incorrect items, you may report the issue within 24 hours of delivery for a replacement or refund.'),
                _section('8. User Conduct',
                    'You agree not to misuse the platform, engage in fraudulent activity, harass shoppers or riders, or use the service for any unlawful purpose. We reserve the right to suspend or terminate accounts that violate these terms.'),
                _section('9. Shoppers and Riders',
                    'Shoppers and riders are independent contractors, not employees of LipaCart. They must complete KYC verification before operating on the platform. LipaCart facilitates payment but is not responsible for the independent actions of shoppers and riders.'),
                _section('10. Limitation of Liability',
                    'LipaCart is not liable for indirect, incidental, or consequential damages arising from your use of the service. Our total liability shall not exceed the value of the relevant order.'),
                _section('11. Changes to Terms',
                    'We may update these terms at any time. Continued use of the application after changes constitutes acceptance of the updated terms.'),
                _section('12. Contact',
                    'For questions about these terms, contact us at support@lipacart.com.'),
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
