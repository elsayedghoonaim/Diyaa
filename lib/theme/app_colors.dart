import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Light Mode ──
  static const Color bgLight          = Color(0xFFFAFAF5);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B6872);
  static const Color accentTealLight  = Color(0xFF0B6E6E);
  static const Color accentGoldLight  = Color(0xFFB8973A);
  static const Color cardBgLight      = Color(0xFFFFFFFF);
  static const Color borderLight      = Color(0xFFF0EDE6);
  static const Color progressBgLight  = Color(0xFFE8E4DD);
  static const Color completedTealLight = Color(0xFF0B6E6E);
  
  // ZikrScreen specific Light
  static const Color borderZikrLight    = Color(0xFFE8E4DD);
  static const Color progressBgZikrLight= Color(0xFFE0DCD4);
  static const Color ringTrackLight     = Color(0xFFE8E4DD);
  static const Color counterBgLight     = Color(0xFFFFFFFF);
  static const Color arrowBgLight       = Color(0x0A000000);

  // ── Dark Mode ──
  static const Color bgDark           = Color(0xFF0D1117);
  static const Color textPrimaryDark  = Color(0xFFE8E4DD);
  static const Color textSecondaryDark = Color(0xFF8A8790);
  static const Color accentTealDark   = Color(0xFF4DB6AC);
  static const Color accentGoldDark   = Color(0xFFD4A84B);
  static const Color cardBgDark       = Color(0xFF161B22);
  static const Color borderDark       = Color(0xFF2A2F3A);
  static const Color progressBgDark   = Color(0xFF2A2F3A);
  static const Color completedTealDark = Color(0xFF2E7D60);

  // ZikrScreen specific Dark
  static const Color borderZikrDark     = Color(0xFF2A2F3A);
  static const Color progressBgZikrDark = Color(0xFF2A2F3A);
  static const Color ringTrackDark      = Color(0xFF2A2F3A);
  static const Color counterBgDark      = Color(0xFF161B22);
  static const Color arrowBgDark        = Color(0x0CFFFFFF);

  // ── Prayer Card Gradients ──
  static const List<Color> prayerCardLight = [
    Color(0xFF0B5050), Color(0xFF0B6E6E), Color(0xFF0A5530),
  ];
  static const List<Color> prayerCardDark = [
    Color(0xFF0A3D3D), Color(0xFF0B5E5E), Color(0xFF0B4A2E),
  ];

  // ── Fixed colors inside prayer card ──
  static const Color prayerCardGold   = Color(0xFFF5D78A);
  static const Color prayerCardWhite  = Colors.white;

  // ── Notification amber ──
  static const Color notifAmber       = Color(0xFFD97706);

  // ── Featured card gradient ──
  static const List<Color> featuredCardColors = [
    Color(0xFF0B2545), Color(0xFF1A4A6E), Color(0xFF0B6E6E),
  ];
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentTealLight,
        secondary: AppColors.accentGoldLight,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentTealDark,
        secondary: AppColors.accentGoldDark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }
}
