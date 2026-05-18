import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/islamic_pattern.dart';
import '../widgets/settings/section_widget.dart';
import '../widgets/settings/setting_row.dart';
import '../widgets/settings/city_sheet.dart';
import '../widgets/settings/privacy_sheet.dart';
import '../widgets/settings/sound_sheet.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark = provider.darkMode;
    final arabic = provider.arabicMode;
    final hijriDates = provider.hijriDates;
    final t = provider.t;

    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final textSecondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    
    final locationLabel = provider.prayerInfo?.cityLabel ?? t('Locating...', 'جاري التحديد...');

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
                            alignment: arabic ? Alignment.centerRight : Alignment.centerLeft,
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
                                icon: Icons.translate,
                                iconColor: gold,
                                iconBgMode: 'gold',
                                label: 'Full Arabic Mode',
                                arLabel: 'الوضع العربي الكامل',
                                sublabel: t('Switch entire UI to Arabic', 'تحويل كامل واجهة التطبيق إلى العربية'),
                                rightWidget: _Toggle(on: arabic, onToggle: () => provider.setArabicMode(!arabic), teal: teal),
                              ),
                              if (arabic)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: dark ? const Color(0x14D4A84B) : const Color(0x11B8973A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: dark ? const Color(0x33D4A84B) : const Color(0x33B8973A)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'تم تفعيل الوضع العربي الكامل',
                                          textAlign: TextAlign.right,
                                          style: GoogleFonts.amiri(
                                            fontSize: 16,
                                            color: gold,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'جميع الشاشات تظهر الآن باللغة العربية',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                iconBgMode: provider.useGps ? 'teal_active' : 'teal',
                                label: 'Use GPS Location',
                                arLabel: 'استخدام GPS',
                                sublabel: provider.useGps
                                    ? t('Automatic · Updates with your position', 'تلقائي · يتحدث حسب موقعك')
                                    : t('Tap to enable GPS', 'اضغط لتفعيل GPS'),
                                rightWidget: _Toggle(
                                  on: provider.useGps,
                                  onToggle: () => provider.setUseGps(!provider.useGps),
                                  teal: teal,
                                ),
                                isLast: provider.useGps,
                              ),

                              if (!provider.useGps)
                                SettingRow(
                                  icon: Icons.location_city,
                                  iconColor: gold,
                                  iconBgMode: 'gold',
                                  label: 'Choose City',
                                  arLabel: 'اختر المدينة',
                                  sublabel: provider.manualCityName.isNotEmpty
                                      ? provider.manualCityName
                                      : t('Tap to select your city', 'اضغط لاختيار مدينتك'),
                                  rightWidget: Icon(
                                    arabic ? Icons.chevron_left : Icons.chevron_right,
                                    size: 16, color: textSecondary,
                                  ),
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => const CitySheet(),
                                  ),
                                  isLast: true,
                                ),

                              if (provider.prayerInfo != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: dark ? const Color(0x144DB6AC) : const Color(0x0F0B6E6E),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: dark ? const Color(0x334DB6AC) : const Color(0x260B6E6E)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on, size: 13, color: teal),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            locationLabel,
                                            style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.w500),
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
                                icon: dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                                iconColor: dark ? teal : gold,
                                iconBgMode: dark ? 'teal' : 'gold',
                                label: 'Dark Mode',
                                arLabel: 'الوضع الداكن',
                                rightWidget: _Toggle(on: dark, onToggle: () => provider.setDarkMode(!dark), teal: teal),
                              ),
                              SettingRow(
                                icon: Icons.calendar_month_outlined,
                                iconColor: teal,
                                iconBgMode: 'teal',
                                label: 'Hijri Date Display',
                                arLabel: 'عرض التاريخ الهجري',
                                rightWidget: _Toggle(on: hijriDates, onToggle: () => provider.setHijriDates(!hijriDates), teal: teal),
                                isLast: true,
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
                                rightWidget: _Toggle(on: provider.notifPrayer, onToggle: () => provider.setNotifPrayer(!provider.notifPrayer), teal: teal),
                              ),
                              SettingRow(
                                icon: Icons.auto_awesome,
                                iconColor: teal,
                                iconBgMode: 'teal',
                                label: 'Azkar Reminders',
                                arLabel: 'تذكيرات الأذكار',
                                sublabel: t('Morning, evening & post-prayer azkar', 'أذكار الصباح والمساء وما بعد الصلاة'),
                                rightWidget: _Toggle(on: provider.notifAzkar, onToggle: () => provider.setNotifAzkar(!provider.notifAzkar), teal: teal),
                              ),
                              SettingRow(
                                icon: Icons.notifications_none_outlined,
                                iconColor: gold,
                                iconBgMode: 'gold',
                                label: 'Streak Warnings',
                                arLabel: 'تحذيرات السلسلة',
                                rightWidget: _Toggle(on: provider.notifStreak, onToggle: () => provider.setNotifStreak(!provider.notifStreak), teal: teal),
                              ),
                              SettingRow(
                                icon: Icons.notifications_none_outlined,
                                iconColor: teal,
                                iconBgMode: 'teal',
                                label: 'Milestone Celebrations',
                                arLabel: 'اشعارات الانجازات',
                                rightWidget: _Toggle(on: provider.notifMilestone, onToggle: () => provider.setNotifMilestone(!provider.notifMilestone), teal: teal),
                              ),
                              SettingRow(
                                icon: Icons.vibration,
                                iconColor: textSecondary,
                                iconBgMode: 'default',
                                label: 'Sound & Haptics',
                                arLabel: 'الصوت والاهتزاز',
                                rightWidget: _Toggle(on: provider.soundEnabled, onToggle: () => provider.setSoundEnabled(!provider.soundEnabled), teal: teal),
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
                            provider: provider,
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
                                rightWidget: Icon(arabic ? Icons.chevron_left : Icons.chevron_right, size: 16, color: textSecondary),
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
                                rightWidget: Icon(arabic ? Icons.chevron_left : Icons.chevron_right, size: 16, color: textSecondary),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t('Thank you for your support!', 'شكراً لدعمك!')))
                                  );
                                },
                              ),
                              SettingRow(
                                icon: Icons.info_outline,
                                iconColor: gold,
                                iconBgMode: 'default',
                                label: 'Diyaa v1.0.0',
                                arLabel: provider.toArabicDigits('ضياء v1.0.0'),
                                sublabel: t('Made with care for the Ummah', 'صُنع بعناية للأمة الإسلامية'),
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
  final AppProvider provider;

  const _SalahNabiSection({
    required this.dark,
    required this.arabic,
    required this.teal,
    required this.gold,
    required this.textSecondary,
    required this.t,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final on = provider.salahNotif;

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
            onToggle: () => provider.setSalahNotif(!on),
            teal: teal,
          ),
        ),

        // Sub-options — only shown when enabled
        if (on) ...[
          // Sound picker — opens bottom sheet
          Builder(builder: (ctx) {
            final selected = kSalahSounds.firstWhere(
              (s) => s.id == provider.salahSound,
              orElse: () => kSalahSounds.first,
            );
            return SettingRow(
              icon: Icons.music_note_outlined,
              iconColor: gold,
              iconBgMode: 'gold',
              label: 'Reminder Sound',
              arLabel: 'صوت التذكير',
              sublabel: arabic ? selected.nameAr : selected.nameEn,
              rightWidget: Icon(arabic ? Icons.chevron_left : Icons.chevron_right, size: 16, color: textSecondary),
              onTap: () => showModalBottomSheet(
                context: ctx,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SoundSheet(),
              ),
              isLast: false,
            );
          }),

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
                provider: provider,
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
              on: provider.salahOverrideSilent,
              onToggle: () => provider.setSalahOverrideSilent(!provider.salahOverrideSilent),
              teal: teal,
            ),
            isLast: false,
          ),

          // Test button
          SettingRow(
            icon: Icons.bug_report_outlined,
            iconColor: gold,
            iconBgMode: 'gold',
            label: 'Test Salah Audio',
            arLabel: 'اختبار صوت الصلاة',
            sublabel: t('Tap to test the audio right now', 'اضغط لاختبار الصوت الآن'),
            rightWidget: Icon(arabic ? Icons.chevron_left : Icons.chevron_right, size: 16, color: textSecondary),
            onTap: () async {
              try {
                await NotificationService.sendTestSalahNotification(
                  isArabic: arabic,
                  soundAsset: provider.salahSound,
                  overrideSilent: provider.salahOverrideSilent,
                  soundEnabled: provider.soundEnabled, // FIX: now passed through
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('Test notification sent! ✅', 'تم إرسال إشعار تجريبي! ✅'))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('Failed: $e', 'فشل: $e'))),
                  );
                }
              }
            },
            isLast: true,
          ),
        ],

        if (!on)
          const SizedBox(height: 6),
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
  final AppProvider provider;
  final String Function(String, String) t;

  const _IntervalRow({
    required this.dark,
    required this.teal,
    required this.textSecondary,
    required this.provider,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final min = provider.salahInterval;
    final label = min < 60
        ? t('$min min', '${provider.toArabicDigits(min.toString())} دقيقة')
        : t('${min ~/ 60}h ${min % 60 != 0 ? '${min % 60}m' : ''}', 
            '${provider.toArabicDigits((min ~/ 60).toString())} ساعة ${min % 60 != 0 ? '${provider.toArabicDigits((min % 60).toString())} دقيقة' : ''}');

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
                  provider.arabicMode ? Icons.chevron_left : Icons.chevron_right,
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
    final controller = TextEditingController(text: provider.salahInterval.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: provider.arabicMode ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: dark ? AppColors.bgDark : AppColors.bgLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  t('Enter interval in minutes (e.g. 45 for 45 minutes)', 'أدخل الوقت بالدقائق (مثلاً 45 لمدة 45 دقيقة)'),
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: dark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    suffixText: t('min', 'دقيقة'),
                    suffixStyle: TextStyle(color: textSecondary),
                    filled: true,
                    fillColor: dark ? const Color(0x11FFFFFF) : const Color(0x08000000),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t('Cancel', 'إلغاء'), style: TextStyle(color: textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  final val = int.tryParse(controller.text.trim());
                  if (val != null && val > 0) {
                    provider.setSalahInterval(val);
                    Navigator.pop(ctx);
                  }
                },
                child: Text(t('Save', 'حفظ'), style: TextStyle(color: teal, fontWeight: FontWeight.bold)),
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
              left: on ? 21 : 3,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
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
