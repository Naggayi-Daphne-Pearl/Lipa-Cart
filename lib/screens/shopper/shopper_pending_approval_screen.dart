import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/shopper_button.dart';

class ShopperPendingApprovalScreen extends StatefulWidget {
  const ShopperPendingApprovalScreen({super.key});

  @override
  State<ShopperPendingApprovalScreen> createState() =>
      _ShopperPendingApprovalScreenState();
}

class _ShopperPendingApprovalScreenState
    extends State<ShopperPendingApprovalScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshProfile();

      if (mounted) {
        final kycStatus = authProvider.user?.kycStatus;
        debugPrint('Check Status - kycStatus: $kycStatus, shopperId: ${authProvider.user?.shopperId}');
        if (kycStatus == 'approved') {
          context.go('/shopper/home');
        } else if (kycStatus == 'rejected') {
          context.go('/shopper/kyc?rejected=true');
        } else if (kycStatus == null || kycStatus == 'not_submitted') {
          // KYC was never completed — send them back to fill it out
          context.go('/shopper/kyc');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Still under review. Please check back later.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hourglass icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.hourglass_empty_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Application Under Review',
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Your KYC documents have been submitted successfully. We\'ll review them and notify you shortly.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Timeline info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Review typically takes 24-48 hours',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Check Status button
              ShopperButton.primary(
                text: 'Check Status',
                icon: Icons.refresh_rounded,
                isLoading: _isChecking,
                onPressed: _isChecking ? null : _checkStatus,
              ),
              const SizedBox(height: 12),

              // Update Documents button
              ShopperButton.secondary(
                text: 'Update Documents',
                icon: Icons.edit_document,
                onPressed: () => context.go('/shopper/kyc'),
              ),
              const SizedBox(height: 12),

              // Logout button
              ShopperButton.outlined(
                text: 'Logout',
                icon: Icons.logout_rounded,
                onPressed: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
