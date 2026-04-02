import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/custom_button.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.elegantBgGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.search_status, size: 48, color: AppColors.accent),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Text('Page Not Found', style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'The page you\'re looking for doesn\'t exist or has been moved.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  CustomButton(
                    text: 'Go Home',
                    onPressed: () => context.go('/customer/home'),
                    icon: Iconsax.home,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
