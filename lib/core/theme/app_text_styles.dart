import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';

  // Display face (Fraunces). Reserve for hero headlines ≥ 24px.
  // One weight in use (600). See .claude/standards/design_direction.md.
  static const String displayFontFamily = 'Fraunces';

  // Display styles — editorial hero headlines. Use sparingly.
  // Fraunces is a variable font with wght/opsz/SOFT/WONK axes. We pin them
  // explicitly so rendering is identical across every context (mobile, web,
  // different platforms). Without fontVariations the default axis values can
  // differ, which made the same fontWeight look slightly different in hero
  // vs section headers.
  static const List<FontVariation> _displayVariations = [
    FontVariation('wght', 600),
    FontVariation('SOFT', 50), // midway soft — warm but not mushy
    FontVariation('WONK', 0),
  ];

  static const TextStyle displayXl = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    fontVariations: [..._displayVariations, FontVariation('opsz', 44)],
    color: AppColors.textPrimary,
    height: 1.08,
    letterSpacing: -0.8,
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    fontVariations: [..._displayVariations, FontVariation('opsz', 36)],
    color: AppColors.textPrimary,
    height: 1.12,
    letterSpacing: -0.6,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    fontVariations: [..._displayVariations, FontVariation('opsz', 28)],
    color: AppColors.textPrimary,
    height: 1.18,
    letterSpacing: -0.4,
  );

  // displaySm — for in-page section titles (Fresh Picks Today, Popular,
  // etc.). Smaller than displayMd so it doesn't compete with the hero.
  static const TextStyle displaySm = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontVariations: [..._displayVariations, FontVariation('opsz', 22)],
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.2,
  );

  // Headings - Clean, modern weights
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle heroTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.12,
    letterSpacing: -0.6,
  );

  static const TextStyle heroBody = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xD9FFFFFF),
    height: 1.6,
  );

  static const TextStyle heroMetric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
  );

  static const TextStyle heroMeta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Color(0x99FFFFFF),
    height: 1.4,
  );

  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle screenSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static const TextStyle overlineAccent = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Labels & Buttons
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
    letterSpacing: 0.2,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Price - Using primary green for fresh feel
  static const TextStyle priceLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  );

  static const TextStyle priceMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  );

  static const TextStyle priceSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    height: 1.2,
  );

  // Special Styles
  static const TextStyle tag = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.2,
    letterSpacing: 0.3,
  );

  static const TextStyle strikethrough = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    decoration: TextDecoration.lineThrough,
    height: 1.2,
  );
}
