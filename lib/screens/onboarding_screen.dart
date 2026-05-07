import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/islamic_pattern.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark = provider.darkMode;
    final arabic = provider.arabicMode;

    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          const IslamicPatternOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Spacer(),
                  // Logo/Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: gold.withOpacity(0.3), width: 2),
                    ),
                    child: Icon(Icons.auto_awesome, size: 50, color: gold),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    arabic ? 'مرحباً بك في ضياء' : 'Welcome to Diyaa',
                    style: GoogleFonts.amiri(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    arabic 
                        ? 'اختر لغتك ونظام الألوان المفضل'
                        : 'Choose your language and theme',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Language Selection
                  _buildOptionTitle(arabic ? 'اللغة' : 'Language', gold),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceCard(
                          label: 'English',
                          selected: !arabic,
                          onTap: () => provider.setArabicMode(false),
                          teal: teal,
                          dark: dark,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _ChoiceCard(
                          label: 'العربية',
                          selected: arabic,
                          onTap: () => provider.setArabicMode(true),
                          teal: teal,
                          dark: dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Theme Selection
                  _buildOptionTitle(arabic ? 'المظهر' : 'Theme', gold),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceCard(
                          label: arabic ? 'فاتح' : 'Light',
                          selected: !dark,
                          onTap: () => provider.setDarkMode(false),
                          teal: teal,
                          dark: dark,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _ChoiceCard(
                          label: arabic ? 'داكن' : 'Dark',
                          selected: dark,
                          onTap: () => provider.setDarkMode(true),
                          teal: teal,
                          dark: dark,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => provider.completeOnboarding(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        arabic ? 'ابدأ الآن' : 'Get Started',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color teal;
  final bool dark;

  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.teal,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected 
              ? teal.withOpacity(0.1) 
              : (dark ? const Color(0xFF1E2530) : const Color(0xFFF9F5EE)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? teal : (dark ? Colors.white10 : Colors.black12),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? teal : (dark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
