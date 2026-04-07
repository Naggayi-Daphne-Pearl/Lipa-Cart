import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../core/constants/app_sizes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class FeatureSpotlightCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final List<String> highlights;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onDismiss;
  final Color accentColor;

  const FeatureSpotlightCard({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.highlights,
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
    this.onDismiss,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, accentColor.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow, style: AppTextStyles.overlineAccent),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppTextStyles.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Iconsax.close_circle, size: 20),
                  color: AppColors.textSecondary,
                  tooltip: 'Dismiss',
                ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: highlights
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.tick_circle, size: 14, color: accentColor),
                        const SizedBox(width: 6),
                        Text(
                          item,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              ElevatedButton.icon(
                onPressed: onPrimaryTap,
                icon: const Icon(Iconsax.arrow_right_3, size: 16),
                label: Text(primaryLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
              if (secondaryLabel != null && onSecondaryTap != null)
                OutlinedButton(
                  onPressed: onSecondaryTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.22),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                  ),
                  child: Text(secondaryLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
