import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/training_links.dart';
import '../../widgets/rider_button.dart';

class RiderPendingApprovalScreen extends StatefulWidget {
  const RiderPendingApprovalScreen({super.key});

  @override
  State<RiderPendingApprovalScreen> createState() =>
      _RiderPendingApprovalScreenState();
}

class _RiderPendingApprovalScreenState
    extends State<RiderPendingApprovalScreen> {
  bool _isChecking = false;
  bool _isApproved = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshProfile();

      if (mounted) {
        final kycStatus = authProvider.user?.kycStatus;
        debugPrint(
            'Rider Check Status - kycStatus: $kycStatus, riderId: ${authProvider.user?.riderId}');
        if (kycStatus == 'approved') {
          setState(() => _isApproved = true);
        } else if (kycStatus == 'rejected') {
          context.go('/rider/kyc?rejected=true');
        } else if (kycStatus == null || kycStatus == 'not_submitted') {
          context.go('/rider/kyc');
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

  Future<void> _openTrainingQuiz() async {
    final uri = Uri.parse(TrainingLinks.riderQuizUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the quiz. Please try again.')),
      );
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
          child: _isApproved ? _buildApprovedView() : _buildPendingView(),
        ),
      ),
    );
  }

  Widget _buildPendingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.hourglass_empty_rounded,
            size: 40,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Application Under Review',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Your KYC documents have been submitted successfully. We\'ll review them and notify you shortly.',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Review typically takes 24-48 hours',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        RiderButton.primary(
          text: 'Check Status',
          icon: Icons.refresh_rounded,
          isLoading: _isChecking,
          onPressed: _isChecking ? null : _checkStatus,
        ),
        const SizedBox(height: 12),
        RiderButton.secondary(
          text: 'Update Documents',
          icon: Icons.edit_document,
          onPressed: () => context.go('/rider/kyc'),
        ),
        const SizedBox(height: 12),
        RiderButton.outlined(
          text: 'Logout',
          icon: Icons.logout_rounded,
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildApprovedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 40,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'You are approved!',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Welcome to the LipaCart team. Before you start, please take a short training quiz on safe riding and order handling. It only takes about 3 minutes.',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey.shade700,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.school_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '5 questions • Pass mark: 4 of 5 • You can retake',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        RiderButton.primary(
          text: 'Take the Training Quiz',
          icon: Icons.open_in_new_rounded,
          onPressed: _openTrainingQuiz,
        ),
        const SizedBox(height: 12),
        RiderButton.secondary(
          text: 'I\'ve done the quiz — Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.go('/rider/home'),
        ),
      ],
    );
  }
}
