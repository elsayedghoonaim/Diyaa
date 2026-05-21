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
  static const Color bgDark           = Color(0xFF05070C);
  static const Color textPrimaryDark  = Color(0xFFE8E4DD);
  static const Color textSecondaryDark = Color(0xFF8A8790);
  static const Color accentTealDark   = Color(0xFF4DB6AC);
  static const Color accentGoldDark   = Color(0xFFD4A84B);
  static const Color cardBgDark       = Color(0xFF11141B);
  static const Color borderDark       = Color(0xFF1D222E);
  static const Color progressBgDark   = Color(0xFF1D222E);
  static const Color completedTealDark = Color(0xFF2E7D60);

  // ZikrScreen specific Dark
  static const Color borderZikrDark     = Color(0xFF1D222E);
  static const Color progressBgZikrDark = Color(0xFF1D222E);
  static const Color ringTrackDark      = Color(0xFF1D222E);
  static const Color counterBgDark      = Color(0xFF11141B);
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
    final baseTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentTealLight,
        secondary: AppColors.accentGoldLight,
      ),
      useMaterial3: true,
    );
    final interTextTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);
    
    return baseTheme.copyWith(
      textTheme: interTextTheme.copyWith(
        displayLarge: interTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight),
        displayMedium: interTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight),
        displaySmall: interTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight),
        headlineLarge: interTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
        headlineMedium: interTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
        headlineSmall: interTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
        titleLarge: interTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
        titleMedium: interTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight),
        titleSmall: interTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textSecondaryLight),
        bodyLarge: interTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight),
        bodySmall: interTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textSecondaryLight),
        labelLarge: interTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight),
        labelMedium: interTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textSecondaryLight),
        labelSmall: interTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textSecondaryLight),
      ),
    );
  }

  static ThemeData dark() {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentTealDark,
        secondary: AppColors.accentGoldDark,
      ),
      useMaterial3: true,
    );
    
    // To counteract the irradiation illusion (white text visually bleeding and looking bolder on dark backgrounds),
    // we thin out the font weights in dark mode (e.g. w600 -> w500, w400 -> w300) so they look visually identical.
    final interTextTheme = GoogleFonts.interTextTheme(baseTheme.textTheme);
    
    return baseTheme.copyWith(
      textTheme: interTextTheme.copyWith(
        displayLarge: interTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w300, color: AppColors.textPrimaryDark),
        displayMedium: interTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w300, color: AppColors.textPrimaryDark),
        displaySmall: interTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w300, color: AppColors.textPrimaryDark),
        headlineLarge: interTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),
        headlineMedium: interTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),
        headlineSmall: interTextTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),
        titleLarge: interTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),
        titleMedium: interTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimaryDark),
        titleSmall: interTextTheme.titleSmall?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textSecondaryDark),
        bodyLarge: interTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w300, color: AppColors.textPrimaryDark),
        bodyMedium: interTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w300, color: AppColors.textPrimaryDark),
        bodySmall: interTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.w300, color: AppColors.textSecondaryDark),
        labelLarge: interTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimaryDark),
        labelMedium: interTextTheme.labelMedium?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textSecondaryDark),
        labelSmall: interTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: AppColors.textSecondaryDark),
      ),
    );
  }
}
