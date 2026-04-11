import 'package:flutter/material.dart';

import '../../models/order.dart';
import 'app_colors.dart';

/// Shared order-status presentation for customer, shopper, rider, and admin.
abstract final class AppOrderStatusColors {
  AppOrderStatusColors._();

  static (Color background, Color foreground, String shortLabel) triple(
    OrderStatus status,
  ) {
    switch (status) {
      case OrderStatus.pending:
        return (
          AppColors.accentSoft,
          AppColors.accent,
          'Processing',
        );
      case OrderStatus.confirmed:
        return (
          AppColors.primarySoft,
          AppColors.primaryDark,
          'Confirmed',
        );
      case OrderStatus.shopperAssigned:
        return (
          AppColors.primaryMuted,
          AppColors.primary,
          'Shopper assigned',
        );
      case OrderStatus.shopping:
        return (
          AppColors.cardGreen,
          AppColors.primary,
          'Shopping',
        );
      case OrderStatus.readyForDelivery:
        return (
          AppColors.accentMuted,
          AppColors.accent,
          'Ready',
        );
      case OrderStatus.riderAssigned:
        return (
          AppColors.cardBlue,
          AppColors.info,
          'Rider assigned',
        );
      case OrderStatus.inTransit:
        return (
          AppColors.accentSoft,
          AppColors.accent,
          'On the way',
        );
      case OrderStatus.delivered:
        return (
          AppColors.primarySoft,
          AppColors.primary,
          'Delivered',
        );
      case OrderStatus.cancelled:
        return (
          AppColors.errorSoft,
          AppColors.error,
          'Cancelled',
        );
      case OrderStatus.paymentProcessing:
        return (
          AppColors.accentSoft,
          AppColors.accent,
          'Processing',
        );
      case OrderStatus.refunded:
        return (
          AppColors.errorSoft,
          AppColors.error,
          'Refunded',
        );
    }
  }

  /// Foreground color for dots, chips, and table indicators.
  static Color foreground(OrderStatus status) => triple(status).$2;

  /// Badge colors when only [OrderStatus.name] is available.
  static (Color background, Color foreground, String label) tripleForName(
    String statusName,
  ) {
    for (final v in OrderStatus.values) {
      if (v.name == statusName) {
        return triple(v);
      }
    }
    return (
      AppColors.grey100,
      AppColors.textSecondary,
      statusName,
    );
  }
}
