import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_cubit.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_state.dart';
import 'package:diyaa_app/theme/app_colors.dart';
import 'package:diyaa_app/shared/widgets/islamic_pattern.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    final SettingsState settingsState = context.watch<SettingsCubit>().state;
    final bool dark = settingsState is SettingsLoaded
        ? settingsState.settings.darkMode
        : false;
    final bool arabic = settingsState is SettingsLoaded
        ? settingsState.settings.arabicMode
        : false;
    final SettingsCubit cubit = context.read<SettingsCubit>();

    final Color bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final Color textSecondary = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final Color teal = dark
        ? AppColors.accentTealDark
        : AppColors.accentTealLight;
    final Color gold = dark
        ? AppColors.accentGoldDark
        : AppColors.accentGoldLight;

    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: <Widget>[
            const IslamicPatternOverlay(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Spacer(),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: gold.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        arabic ? 'مرحباً بك في ضياء' : 'Welcome to Diyaa',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: gold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        arabic
                            ? 'اختر لغتك ونظام الألوان المفضل'
                            : 'Choose your language and theme',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    _buildOptionTitle(
                      arabic ? 'اللغة' : 'Language',
                      gold,
                      arabic,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _ChoiceCard(
                            label: 'English',
                            selected: !arabic,
                            onTap: () => cubit.setArabicMode(false),
                            teal: teal,
                            dark: dark,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ChoiceCard(
                            label: 'العربية',
                            selected: arabic,
                            onTap: () => cubit.setArabicMode(true),
                            teal: teal,
                            dark: dark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    _buildOptionTitle(
                      arabic ? 'المظهر' : 'Theme',
                      gold,
                      arabic,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _ChoiceCard(
                            label: arabic ? 'فاتح' : 'Light',
                            selected: !dark,
                            onTap: () => cubit.setDarkMode(false),
                            teal: teal,
                            dark: dark,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _ChoiceCard(
                            label: arabic ? 'داكن' : 'Dark',
                            selected: dark,
                            onTap: () => cubit.setDarkMode(true),
                            teal: teal,
                            dark: dark,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => cubit.completeOnboarding(),
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
      ),
    );
  }

  Widget _buildOptionTitle(String title, Color color, bool arabic) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
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
              ? teal.withValues(alpha: 0.1)
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
