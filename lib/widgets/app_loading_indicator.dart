import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Consistent loading indicator used across the entire app.
/// Replaces all ad-hoc CircularProgressIndicator usages.
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.message,
  });

  /// Small inline loader (e.g. inside buttons, list items)
  const AppLoadingIndicator.small({
    super.key,
    this.color,
    this.message,
  }) : size = 24;

  /// Full-page centered loader with optional message
  const AppLoadingIndicator.page({
    super.key,
    this.color,
    this.message,
  }) : size = 48;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size <= 24 ? 2.5 : 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );

    if (message == null) return indicator;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: 16),
        Text(
          message!,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A full-page loading state — centered with optional message.
/// Use this as a direct replacement for `Center(child: CircularProgressIndicator())`.
class AppLoadingPage extends StatelessWidget {
  final String? message;

  const AppLoadingPage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppLoadingIndicator.page(message: message),
    );
  }
}
