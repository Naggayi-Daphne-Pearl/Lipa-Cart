import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - Brand Green
  static const Color primary = Color(0xFF15874B);
  static const Color primaryLight = Color(0xFF2A9E5E);
  static const Color primaryDark = Color(0xFF106B3C);
  static const Color primarySoft = Color(0xFFE3F5EC);
  static const Color primaryMuted = Color(0xFFC7EBDA);

  // Accent Colors - Brand Orange for CTAs
  static const Color accent = Color(0xFFEA7702);
  static const Color accentLight = Color(0xFFFF9429);
  static const Color accentSoft = Color(0xFFFFF3E5);
  static const Color accentMuted = Color(0xFFFFE4C4);

  // Warm Neutral Colors (Cream/Beige tones)
  static const Color white = Color(0xFFFFFFFF);
  static const Color cream = Color(0xFFFAF8F5);
  static const Color beige = Color(0xFFF5F2ED);
  static const Color warmGrey = Color(0xFFEDE9E3);
  static const Color black = Color(0xFF2D2D2D);

  // Grey Scale (Warmer tones)
  static const Color grey50 = Color(0xFFFAF9F7);
  static const Color grey100 = Color(0xFFF5F3F0);
  static const Color grey200 = Color(0xFFEBE8E4);
  static const Color grey300 = Color(0xFFDDD9D3);
  static const Color grey400 = Color(0xFFB8B3AB);
  static const Color grey500 = Color(0xFF8F8A82);
  static const Color grey600 = Color(0xFF6B6660);
  static const Color grey700 = Color(0xFF4D4944);
  static const Color grey800 = Color(0xFF343230);
  static const Color grey900 = Color(0xFF1F1E1C);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6660);
  static const Color textTertiary = Color(0xFF8F8A82);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Background Colors (Warm, Cream-based)
  static const Color background = Color(0xFFFAF8F5);
  static const Color backgroundGrey = Color(0xFFF5F2ED);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F3F0);
  static const Color surfaceWarm = Color(0xFFFEFCF9);

  // Card Backgrounds (Subtle tinted)
  static const Color cardGreen = Color(0xFFF0F5F2);
  static const Color cardOrange = Color(0xFFFEF5F2);
  static const Color cardYellow = Color(0xFFFFFBF0);
  static const Color cardBlue = Color(0xFFF0F5F8);

  // Status Colors
  static const Color success = Color(0xFF15874B);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFEA7702);
  static const Color info = Color(0xFF0D6EFD);

  // Category Colors
  static const Color vegetables = Color(0xFF15874B);
  static const Color fruits = Color(0xFFEA7702);
  static const Color meat = Color(0xFFDC3545);
  static const Color dairy = Color(0xFF0D6EFD);
  static const Color bakery = Color(0xFFD4A574);
  static const Color beverages = Color(0xFF9B7BB8);
  static const Color snacks = Color(0xFFEA7702);
  static const Color eggs = Color(0xFFB8A88A);
  static const Color oils = Color(0xFF15874B);

  // Favorite/Heart Colors
  static const Color heartActive = Color(0xFFEA7702);
  static const Color heartInactive = Color(0xFFDDD9D3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF5F2ED), Color(0xFFFAF8F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Elegant background gradient (visible warm cream to soft beige)
  static const LinearGradient elegantBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFCF9), // Bright warm white at top
      Color(0xFFFAF6F1), // Soft warm cream middle
      Color(0xFFF5F0E8), // Warm beige at bottom
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Shadows (Very subtle for elegant feel)
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: black.withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // No shadow for flat design
  static List<BoxShadow> get shadowNone => [];

  // Legacy compatibility aliases
  static const Color primaryOrange = accent;
  static const Color primaryGreen = primary;
  static const Color secondaryOrange = accentLight;
  static const Color secondaryGreen = primaryLight;
  static const Color neutralGrey = grey500;
  static const Color lightGrey = grey100;
  static const Color mediumGrey = grey400;
  static const Color darkGrey = grey600;
  static const Color textDark = textPrimary;
  static const Color textMedium = textSecondary;
  static const Color textLight = textTertiary;
}
