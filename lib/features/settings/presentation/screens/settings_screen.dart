import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diyaa_app/core/services/notification_service.dart';
import 'package:diyaa_app/core/utils/arabic_utils.dart' as ar;
import 'package:diyaa_app/features/settings/data/models/settings_model.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_cubit.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_state.dart';
import 'package:diyaa_app/features/progress/presentation/manager/progress_cubit.dart';
import 'package:diyaa_app/features/progress/presentation/manager/progress_state.dart';
import 'package:diyaa_app/theme/app_colors.dart';
import 'package:diyaa_app/shared/widgets/islamic_pattern.dart';
import 'package:diyaa_app/shared/widgets/error_fallback.dart';
import 'package:diyaa_app/features/settings/presentation/widgets/section_widget.dart';
import 'package:diyaa_app/features/settings/presentation/widgets/setting_row.dart';
import 'package:diyaa_app/features/settings/presentation/widgets/city_sheet.dart';
import 'package:diyaa_app/features/settings/presentation/widgets/privacy_sheet.dart';
import 'package:diyaa_app/features/settings/presentation/widgets/sound_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    if (settingsState is SettingsError) {
      return ErrorFallback(
        message: settingsState.message,
        isArabic: false,
        onRetry: () {
          context.read<SettingsCubit>().loadSettings();
        },
      );
    }
    if (settingsState is! SettingsLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final settings = settingsState.settings;
    final cubit = context.read<SettingsCubit>();
    final dark = settings.darkMode;
    final arabic = settings.arabicMode;
    final hijriDates = settings.hijriDates;
    String t(String en, String arStr) =>
        ar.localise(en, arStr, isArabic: arabic);

    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final textSecondary = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;

    final locationLabel = settings.manualCityName.isNotEmpty
        ? settings.manualCityName
        : t('Locating...', 'جاري التحديد...');

    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            const IslamicPatternOverlay(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          child: Align(
                            alignment: arabic
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: const SizedBox.shrink(),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'الإعدادات',
                              style: GoogleFonts.amiri(
                                fontSize: 26,
                                color: gold,
                                height: 1.1,
                              ),
                            ),
                            if (!arabic)
                              Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      child: Column(
                        children: [
                          // Language Section
                          SettingsSection(
                            title: 'Language',
                            ar: 'اللغة',
                            children: [
                              SettingRow(
                                icon: Text(
                                  arabic ? 'EN' : 'ع',
                                  style: arabic
                                      ? TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: gold,
                                        )
                                      : GoogleFonts.amiri(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: gold,
                                          height: 1.1,
                                        ),
                                ),
                                iconColor: gold,
                                iconBgMode: 'gold',
                                label: 'Full Arabic Mode',
                                arLabel: 'الوضع العربي الكامل',
                                sublabel: t(
                                  'Switch entire UI to Arabic',
                                  'تحويل كامل واجهة التطبيق إلى العربية',
                                ),
                                rightWidget: _Toggle(
                                  on: arabic,
                                  onToggle: () => cubit.setArabicMode(!arabic),
                                  teal: teal,
                                ),
                                isLast: true,
                              ),
                            ],
                          ),

                          // Location Section
                          SettingsSection(
                            title: 'Location & Prayer Times',
                            ar: 'الموقع ومواقيت الصلاة',
                            children: [
                              SettingRow(
                                icon: Icons.near_me_outlined,
                                iconColor: teal,
                                iconBgMode: settings.useGps
                                    ? 'teal_active'
                                    : 'teal',
                                label: 'Use GPS Location',
                                arLabel: 'استخدام GPS',
                                sublabel: settings.useGps
                                    ? t(
                                        'Automatic · Updates with your position',
                                        'تلقائي · يتحدث حسب موقعك',
                                      )
                                    : t('Tap to enable GPS', 'اضغط لتفعيل GPS'),
                                rightWidget: _Toggle(
                                  on: settings.useGps,
                                  onToggle: () =>
                                      cubit.setUseGps(!settings.useGps),
                                  teal: teal,
                                ),
                                isLast: settings.useGps,
                              ),

                              if (!settings.useGps)
                                SettingRow(
                                  icon: Icons.location_city,
                                  iconColor: gold,
                                  iconBgMode: 'gold',
                                  label: 'Choose City',
                                  arLabel: 'اختر المدينة',
                                  sublabel: settings.manualCityName.isNotEmpty
                                      ? settings.manualCityName
                                      : t(
                                          'Tap to select your city',
                                          'اضغط لاختيار مدينتك',
                                        ),
                                  rightWidget: Icon(
                                    arabic
                                        ? Icons.chevron_left
                                        : Icons.chevron_right,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => const CitySheet(),
                                  ),
                                  isLast: true,
                                ),

                              if (settings.latitude != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    0,
                                    18,
                                    14,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: dark
                                          ? const Color(0x144DB6AC)
                                          : const Color(0x0F0B6E6E),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: dark
                                            ? const Color(0x334DB6AC)
                                            : const Color(0x260B6E6E),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 13,
                                          color: teal,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            locationLabel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: teal,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Appearance Section
                          SettingsSection(
                            title: 'Appearance',
                            ar: 'المظهر',
                            children: [
                              SettingRow(
                                icon: dark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                                iconColor: dark ? teal : gold,
                                iconBgMode: dark ? 'teal' : 'gold',
                                label: 'Dark Mode',
                                arLabel: 'الوضع الداكن',
                                rightWidget: _Toggle(
                                  on: dark,
                                  onToggle: () => cubit.setDarkMode(!dark),
                                  teal: teal,
                                ),
                              ),
                              SettingRow(
                                icon: Icons.calendar_month_outlined,
                                iconColor: teal,
                                iconBgMode: 'teal',
                                label: 'Hijri Date Display',
                                arLabel: 'عرض التاريخ الهجري',
                                rightWidget: _Toggle(
                                  on: hijriDates,
                                  onToggle: () =>
                                      cubit.setHijriDates(!hijriDates),
                                  teal: teal,
                                ),
                                isLast: true,
                              ),
                            ],
                          ),

                          // Text Size Section
                          SettingsSection(
                            title: 'Text Size',
                            ar: 'حجم الخط',
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  4,
                                  18,
                                  16,
                                ),
                                child: Column(
                                  children: [
                                    // Size labels row
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            t('Small', 'صغير'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  settings.appTextScale <= 0.82
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color:
                                                  settings.appTextScale <= 0.82
                                                  ? gold
                                                  : textSecondary,
                                            ),
                                          ),
                                          Text(
                                            t('Medium', 'متوسط'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  (settings.appTextScale >
                                                          0.82 &&
                                                      settings.appTextScale <
                                                          1.02)
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color:
                                                  (settings.appTextScale >
                                                          0.82 &&
                                                      settings.appTextScale <
                                                          1.02)
                                                  ? gold
                                                  : textSecondary,
                                            ),
                                          ),
                                          Text(
                                            t('Large', 'كبير'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  settings.appTextScale >= 1.02
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color:
                                                  settings.appTextScale >= 1.02
                                                  ? gold
                                                  : textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Slider
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: teal,
                                        inactiveTrackColor: dark
                                            ? AppColors.progressBgDark
                                            : AppColors.progressBgLight,
                                        thumbColor: gold,
                                        overlayColor: gold.withValues(
                                          alpha: 0.12,
                                        ),
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 7,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 16,
                                            ),
                                      ),
                                      child: Slider(
                                        value: settings.appTextScale <= 0.82
                                            ? 0.0
                                            : (settings.appTextScale >= 1.02
                                                  ? 2.0
                                                  : 1.0),
                                        min: 0.0,
                                        max: 2.0,
                                        divisions: 2,
                                        onChanged: (v) {
                                          if (v == 0.0) {
                                            cubit.setAppTextScale(0.78);
                                          } else if (v == 2.0) {
                                            cubit.setAppTextScale(1.12);
                                          } else {
                                            cubit.setAppTextScale(0.92);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Preview text
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: dark
                                            ? const Color(0x144DB6AC)
                                            : const Color(0x0F0B6E6E),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: dark
                                              ? const Color(0x334DB6AC)
                                              : const Color(0x260B6E6E),
                                        ),
                                      ),
                                      child: Text(
                                        t(
                                          'Preview: This is how text will appear',
                                          'معاينة: هكذا سيظهر النص في التطبيق',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: teal,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Notifications Section
                          SettingsSection(
                            title: 'Notifications',
                            ar: 'الإشعارات',
                            children: [
                              SettingRow(
                                icon: Icons.notifications_none_outlined,
                                iconColor: teal,
                                iconBgMode: 'teal',
                                label: 'Prayer Time Reminders',
                                arLabel: 'تذكيرات أوقات الصلاة',
                                rightWidget: _Toggle(
                                  on: settings.notifPrayer,
                                  onToggle: () => cubit.setNotifPrayer(
                                    !settings.notifPrayer,
                                  ),
                                  teal: teal,
                                ),
                              ),
                              SettingRow(
                                icon: Icons.auto_awesome,
                                iconColor: teal,
                                iconBgMode: 'teal',
                                label: 'Azkar Reminders',
                                arLabel: 'تذكيرات الأذكار',
                                sublabel: t(
                                  'Morning, evening & post-prayer azkar',
                                  'أذكار الصباح والمساء وما بعد الصلاة',
                                ),
                                rightWidget: _Toggle(
                                  on: settings.notifAzkar,
                                  onToggle: () =>
                                      cubit.setNotifAzkar(!settings.notifAzkar),
                                  teal: teal,
                                ),
                              ),
                              SettingRow(
                                icon: Icons.notifications_none_outlined,
                                iconColor: gold,
                                iconBgMode: 'gold',
                                label: 'Streak Warnings',
                                arLabel: 'تحذيرات السلسلة',
                                rightWidget: _Toggle(
                                  on: settings.notifStreak,
                                  onToggle: () {
                                    final streak =
                                        context.read<ProgressCubit>().state
                                            is ProgressLoaded
                                        ? (context.read<ProgressCubit>().state
                                                  as ProgressLoaded)
                                              .progress
                                              .streak
                                        : 0;
                                    cubit.setNotifStreak(
                                      !settings.notifStreak,
                                      currentStreak: streak,
                                    );
                                  },
                                  teal: teal,
                                ),
                              ),
                              SettingRow(
                                icon: Icons.notifications_none_outlined,
                                iconColor: teal,
                                iconBgMode: 'teal',
                                label: 'Milestone Celebrations',
                                arLabel: 'اشعارات الانجازات',
                                rightWidget: _Toggle(
                                  on: settings.notifMilestone,
                                  onToggle: () => cubit.setNotifMilestone(
                                    !settings.notifMilestone,
                                  ),
                                  teal: teal,
                                ),
                              ),
                              SettingRow(
                                icon: Icons.vibration,
                                iconColor: textSecondary,
                                iconBgMode: 'default',
                                label: 'Sound & Haptics',
                                arLabel: 'الصوت والاهتزاز',
                                rightWidget: _Toggle(
                                  on: settings.soundEnabled,
                                  onToggle: () => cubit.setSoundEnabled(
                                    !settings.soundEnabled,
                                  ),
                                  teal: teal,
                                ),
                                isLast: true,
                              ),
                            ],
                          ),

                          // ── Al-Salah 'ala Al-Nabi Section ──────────────────
                          _SalahNabiSection(
                            dark: dark,
                            arabic: arabic,
                            teal: teal,
                            gold: gold,
                            textSecondary: textSecondary,
                            t: t,
                            settings: settings,
                            cubit: cubit,
                          ),

                          // ── Debug Notifications Section ─────────────────────
                          _DebugNotificationsSection(
                            dark: dark,
                            arabic: arabic,
                            teal: teal,
                            gold: gold,
                            textSecondary: textSecondary,
                            t: t,
                            settings: settings,
                          ),

                          // About Section
                          SettingsSection(
                            title: 'About',
                            ar: 'حول',
                            children: [
                              SettingRow(
                                icon: Icons.security_outlined,
                                iconColor: teal,
                                iconBgMode: 'teal',
                                label: 'Privacy Policy',
                                arLabel: 'سياسة الخصوصية',
                                rightWidget: Icon(
                                  arabic
                                      ? Icons.chevron_left
                                      : Icons.chevron_right,
                                  size: 16,
                                  color: textSecondary,
                                ),
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => const PrivacySheet(),
                                ),
                              ),
                              SettingRow(
                                icon: Icons.favorite_outline,
                                iconColor: gold,
                                iconBgMode: 'gold',
                                label: 'Rate Diyaa',
                                arLabel: 'قيّم التطبيق',
                                rightWidget: Icon(
                                  arabic
                                      ? Icons.chevron_left
                                      : Icons.chevron_right,
                                  size: 16,
                                  color: textSecondary,
                                ),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        t(
                                          'Thank you for your support!',
                                          'شكراً لدعمك!',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SettingRow(
                                icon: Icons.info_outline,
                                iconColor: gold,
                                iconBgMode: 'default',
                                label: 'Diyaa v1.0.0',
                                arLabel: ar.toArabicDigits(
                                  'ضياء v1.0.0',
                                  isArabic: arabic,
                                ),
                                sublabel: t(
                                  'Made with care for the Ummah',
                                  'صُنع بعناية للأمة الإسلامية',
                                ),
                                rightWidget: const SizedBox.shrink(),
                                isLast: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Al-Salah 'ala Al-Nabi Settings Section
// ─────────────────────────────────────────────
class _SalahNabiSection extends StatelessWidget {
  final bool dark, arabic;
  final Color teal, gold, textSecondary;
  final String Function(String, String) t;
  final SettingsModel settings;
  final SettingsCubit cubit;

  const _SalahNabiSection({
    required this.dark,
    required this.arabic,
    required this.teal,
    required this.gold,
    required this.textSecondary,
    required this.t,
    required this.settings,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final on = settings.salahNotif;

    return SettingsSection(
      title: "Salah 'ala Al-Nabi",
      ar: 'الصلاة على النبي',
      children: [
        // Master toggle
        SettingRow(
          icon: Icons.record_voice_over_outlined,
          iconColor: gold,
          iconBgMode: 'gold',
          label: "Salah 'ala Al-Nabi Reminder",
          arLabel: 'تذكير الصلاة على النبي',
          sublabel: on
              ? t(
                  'Periodic sound reminder — no banner shown',
                  'تذكير صوتي دوري — بدون اشعار ظاهر',
                )
              : null,
          isLast: !on,
          rightWidget: _Toggle(
            on: on,
            onToggle: () => cubit.setSalahNotif(!on),
            teal: teal,
          ),
        ),

        // Sub-options — only shown when enabled
        if (on) ...[
          // Sound picker — opens bottom sheet
          Builder(
            builder: (ctx) {
              final selected = kSalahSounds.firstWhere(
                (s) => s.id == settings.salahSound,
                orElse: () => kSalahSounds.first,
              );
              return SettingRow(
                icon: Icons.music_note_outlined,
                iconColor: gold,
                iconBgMode: 'gold',
                label: 'Reminder Sound',
                arLabel: 'صوت التذكير',
                sublabel: arabic ? selected.nameAr : selected.nameEn,
                rightWidget: Icon(
                  arabic ? Icons.chevron_left : Icons.chevron_right,
                  size: 16,
                  color: textSecondary,
                ),
                onTap: () => showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SoundSheet(),
                ),
                isLast: false,
              );
            },
          ),

          // Interval picker
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: _SubCard(
              dark: dark,
              gold: gold,
              teal: teal,
              textSecondary: textSecondary,
              child: _IntervalRow(
                dark: dark,
                teal: teal,
                textSecondary: textSecondary,
                settings: settings,
                cubit: cubit,
                t: t,
              ),
            ),
          ),

          const SizedBox(height: 2),

          // Override silent toggle
          SettingRow(
            icon: Icons.volume_up_outlined,
            iconColor: teal,
            iconBgMode: 'teal',
            label: 'Play Even When Silent',
            arLabel: 'يعمل في الصامت',
            sublabel: t(
              'Use alarm volume to bypass silent mode',
              'يستخدم صوت المنبّه لتجاوز وضع الصمت',
            ),
            rightWidget: _Toggle(
              on: settings.salahOverrideSilent,
              onToggle: () =>
                  cubit.setSalahOverrideSilent(!settings.salahOverrideSilent),
              teal: teal,
            ),
            isLast: true,
          ),
        ],

        if (!on) const SizedBox(height: 6),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Sub-card container
// ─────────────────────────────────────────────
class _SubCard extends StatelessWidget {
  final bool dark;
  final Color gold, teal, textSecondary;
  final Widget child;

  const _SubCard({
    required this.dark,
    required this.gold,
    required this.teal,
    required this.textSecondary,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: dark ? const Color(0x0FFFFFFF) : const Color(0x08000000),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? const Color(0x1AFFFFFF) : const Color(0x12000000),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Interval custom picker row
// ─────────────────────────────────────────────
class _IntervalRow extends StatelessWidget {
  final bool dark;
  final Color teal, textSecondary;
  final SettingsModel settings;
  final SettingsCubit cubit;
  final String Function(String, String) t;

  const _IntervalRow({
    required this.dark,
    required this.teal,
    required this.textSecondary,
    required this.settings,
    required this.cubit,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final min = settings.salahInterval;
    final isArabic = settings.arabicMode;
    final label = min < 60
        ? t(
            '$min min',
            '${ar.toArabicDigits(min.toString(), isArabic: isArabic)} دقيقة',
          )
        : t(
            '${min ~/ 60}h ${min % 60 != 0 ? '${min % 60}m' : ''}',
            '${ar.toArabicDigits((min ~/ 60).toString(), isArabic: isArabic)} ساعة ${min % 60 != 0 ? '${ar.toArabicDigits((min % 60).toString(), isArabic: isArabic)} دقيقة' : ''}',
          );

    return InkWell(
      onTap: () => _showIntervalDialog(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('Reminder Interval', 'وقت التذكير (كل كم دقيقة)'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: dark ? const Color(0xDDFFFFFF) : const Color(0xDD000000),
              ),
            ),
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: teal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  settings.arabicMode
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  size: 16,
                  color: textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showIntervalDialog(BuildContext context) {
    String toEnglishDigits(String input) {
      const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
      for (int i = 0; i < arabicDigits.length; i++) {
        input = input.replaceAll(arabicDigits[i], i.toString());
      }
      return input;
    }

    final controller = TextEditingController(
      text: ar.toArabicDigits(settings.salahInterval.toString(), isArabic: settings.arabicMode),
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: settings.arabicMode
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: dark ? AppColors.bgDark : AppColors.bgLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              t('Custom Interval', 'وقت مخصص'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: teal,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t(
                    'Enter interval in minutes (e.g. 45 for 45 minutes)',
                    'أدخل الوقت بالدقائق (مثلاً ٤٥ لمدة ٤٥ دقيقة)',
                  ),
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textDirection: ui.TextDirection.ltr,
                        textAlign: TextAlign.left,
                        onTap: () {
                          controller.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: controller.text.length,
                          );
                        },
                        style: TextStyle(
                          color: dark ? Colors.white : Colors.black,
                          fontSize: 18,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: dark
                              ? const Color(0x11FFFFFF)
                              : const Color(0x08000000),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      t('minutes', 'دقيقة'),
                      style: TextStyle(color: textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  t('Cancel', 'إلغاء'),
                  style: TextStyle(color: textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  final englishText = toEnglishDigits(controller.text.trim());
                  final val = int.tryParse(englishText);
                  if (val != null && val > 0) {
                    cubit.setSalahInterval(val);
                    Navigator.pop(ctx);
                  }
                },
                child: Text(
                  t('Save', 'حفظ'),
                  style: TextStyle(color: teal, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Custom Toggle Widget
// ─────────────────────────────────────────────
class _Toggle extends StatelessWidget {
  final bool on;
  final VoidCallback onToggle;
  final Color teal;

  const _Toggle({required this.on, required this.onToggle, required this.teal});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final leftPos = on ? (isRtl ? 3.0 : 21.0) : (isRtl ? 21.0 : 3.0);

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: on ? teal : const Color(0xFFD1CBC0),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              top: 3,
              left: leftPos,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Debug Notifications Section
// ─────────────────────────────────────────────
class _DebugNotificationsSection extends StatefulWidget {
  final bool dark, arabic;
  final Color teal, gold, textSecondary;
  final String Function(String, String) t;
  final SettingsModel settings;

  const _DebugNotificationsSection({
    required this.dark,
    required this.arabic,
    required this.teal,
    required this.gold,
    required this.textSecondary,
    required this.t,
    required this.settings,
  });

  @override
  State<_DebugNotificationsSection> createState() =>
      _DebugNotificationsSectionState();
}

class _DebugNotificationsSectionState
    extends State<_DebugNotificationsSection> {
  bool _expanded = false;
  String? _lastSent;

  Future<void> _fire(String label, Future<void> Function() action) async {
    await action();
    if (mounted) {
      setState(() => _lastSent = label);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.t(
              '$label notification sent — check your tray!',
              'تم إرسال إشعار "$label" — تحقق من الإشعارات!',
            ),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: widget.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final teal = widget.teal;
    final gold = widget.gold;
    final textSecondary = widget.textSecondary;
    final t = widget.t;
    final settings = widget.settings;

    return SettingsSection(
      title: 'Developer: Notifications Debug',
      ar: 'مطور: اختبار الإشعارات',
      children: [
        // Expandable header row
        SettingRow(
          icon: Icons.bug_report_outlined,
          iconColor: textSecondary,
          iconBgMode: 'default',
          label: 'Test Notifications',
          arLabel: 'اختبار الإشعارات',
          sublabel: t(
            'Tap to expand — trigger each notification type instantly',
            'اضغط للتوسيع — أرسل كل نوع إشعار فوراً',
          ),
          rightWidget: AnimatedRotation(
            turns: _expanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: textSecondary,
            ),
          ),
          onTap: () => setState(() => _expanded = !_expanded),
          isLast: !_expanded,
        ),

        if (_expanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status chip
                if (_lastSent != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0x144DB6AC)
                          : const Color(0x0F0B6E6E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: dark
                            ? const Color(0x334DB6AC)
                            : const Color(0x260B6E6E),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 14, color: teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t('Last sent: $_lastSent', 'آخر إرسال: $_lastSent'),
                            style: TextStyle(
                              fontSize: 12,
                              color: teal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Buttons grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DebugButton(
                      label: t('Prayer', 'صلاة'),
                      icon: Icons.access_time_outlined,
                      color: teal,
                      dark: dark,
                      onTap: () => _fire(
                        t('Prayer', 'صلاة'),
                        () => NotificationService.sendTestNotification(
                          isArabic: settings.arabicMode,
                        ),
                      ),
                    ),
                    _DebugButton(
                      label: t('Azkar', 'أذكار'),
                      icon: Icons.auto_awesome_outlined,
                      color: gold,
                      dark: dark,
                      onTap: () => _fire(
                        t('Azkar', 'أذكار'),
                        () => NotificationService.sendTestAzkarNotification(
                          isArabic: settings.arabicMode,
                          soundEnabled: settings.soundEnabled,
                        ),
                      ),
                    ),
                    _DebugButton(
                      label: t('Salah', 'صلاة النبي'),
                      icon: Icons.record_voice_over_outlined,
                      color: gold,
                      dark: dark,
                      onTap: () => _fire(
                        t('Salah Nabi', 'صلاة النبي'),
                        () => NotificationService.sendTestSalahNotification(
                          isArabic: settings.arabicMode,
                          soundAsset: settings.salahSound,
                          overrideSilent: settings.salahOverrideSilent,
                          soundEnabled: settings.soundEnabled,
                        ),
                      ),
                    ),
                    _DebugButton(
                      label: t('Streak', 'السلسلة'),
                      icon: Icons.local_fire_department_outlined,
                      color: teal,
                      dark: dark,
                      onTap: () {
                        final progressState = context
                            .read<ProgressCubit>()
                            .state;
                        final streakVal = progressState is ProgressLoaded
                            ? progressState.progress.streak
                            : 0;
                        _fire(
                          t('Streak', 'السلسلة'),
                          () => NotificationService.sendTestStreakNotification(
                            isArabic: settings.arabicMode,
                            currentStreak: streakVal,
                            soundEnabled: settings.soundEnabled,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text(
                  t(
                    'These fire immediately to verify your notification channels, icons, and sound are working correctly.',
                    'تُرسل هذه الإشعارات فوراً للتحقق من قنوات الإشعارات والأيقونات والصوت.',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Debug Button chip
// ─────────────────────────────────────────────
class _DebugButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool dark;
  final VoidCallback onTap;

  const _DebugButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: dark ? 0.12 : 0.09),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
