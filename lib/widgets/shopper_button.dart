import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_sizes.dart';

enum ShopperButtonVariant { primary, secondary, outlined, danger }

class ShopperButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ShopperButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;

  const ShopperButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ShopperButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 52,
  });

  const ShopperButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  }) : variant = ShopperButtonVariant.primary;

  const ShopperButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  }) : variant = ShopperButtonVariant.secondary;

  const ShopperButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  }) : variant = ShopperButtonVariant.outlined;

  const ShopperButton.danger({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
  }) : variant = ShopperButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (variant) {
      case ShopperButtonVariant.primary:
        return _buildPrimary();
      case ShopperButtonVariant.secondary:
        return _buildSecondary();
      case ShopperButtonVariant.outlined:
        return _buildOutlined();
      case ShopperButtonVariant.danger:
        return _buildDanger();
    }
  }

  Widget _buildPrimary() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildChild(Colors.white),
    );
  }

  Widget _buildSecondary() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primarySoft,
        foregroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primarySoft.withValues(alpha: 0.5),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildChild(AppColors.primary),
    );
  }

  Widget _buildOutlined() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.grey300, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildChild(AppColors.textSecondary),
    );
  }

  Widget _buildDanger() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
      child: _buildChild(AppColors.error),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          textWidget,
        ],
      );
    }

    return textWidget;
  }
}
