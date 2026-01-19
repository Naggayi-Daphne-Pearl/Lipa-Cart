import 'package:flutter/material.dart';

class AppSizes {
  AppSizes._();

  // Padding & Margin - More generous spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Border Radius - Larger, softer corners
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusFull = 100;

  // Icon Sizes
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 28;
  static const double iconXl = 32;

  // Button Heights
  static const double buttonHeightSm = 40;
  static const double buttonHeightMd = 48;
  static const double buttonHeightLg = 56;

  // Touch Targets
  static const double touchTargetMin = 44;

  // Card Dimensions
  static const double productCardWidth = 165;
  static const double productCardHeight = 240;
  static const double categoryCardSize = 85;

  // Image Dimensions
  static const double productImageSm = 70;
  static const double productImageMd = 100;
  static const double productImageLg = 180;

  // Bottom Navigation
  static const double bottomNavHeight = 80;

  // App Bar
  static const double appBarHeight = 56;

  // Screen Padding
  static EdgeInsets get screenPadding => const EdgeInsets.all(md);
  static EdgeInsets get screenPaddingHorizontal =>
      const EdgeInsets.symmetric(horizontal: md);

  // Card Padding
  static EdgeInsets get cardPadding => const EdgeInsets.all(md);
  static EdgeInsets get cardPaddingSmall => const EdgeInsets.all(sm);
}
