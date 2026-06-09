import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:diyaa_app/core/utils/arabic_utils.dart' as ar;
import 'package:diyaa_app/features/settings/presentation/manager/settings_cubit.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_state.dart';
import 'package:diyaa_app/features/prayer_times/presentation/manager/prayer_times_cubit.dart';
import 'package:diyaa_app/features/prayer_times/presentation/manager/prayer_times_state.dart';
import 'package:diyaa_app/features/prayer_times/domain/entities/prayer_info.dart';
import 'package:diyaa_app/features/progress/presentation/manager/progress_cubit.dart';
import 'package:diyaa_app/features/progress/presentation/manager/progress_state.dart';
import 'package:diyaa_app/theme/app_colors.dart';
import 'package:diyaa_app/shared/widgets/islamic_pattern.dart';
import 'package:diyaa_app/features/azkar/presentation/screens/zikr_screen.dart';

// ─────────────────────────────────────────────
// Session Model
// ─────────────────────────────────────────────
class _Session {
  final String nameEn;
  final String nameAr;
  final String descEn;
  final String descAr;
  final String actionEn;
  final String actionAr;
  final String jsonId;
  final double progress;
  final String state;

  const _Session({
    required this.nameEn,
    required this.nameAr,
    required this.descEn,
    required this.descAr,
    required this.actionEn,
    required this.actionAr,
    required this.jsonId,
    required this.progress,
    required this.state,
  });
}

// ─────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<_Session> _dailySessions = <_Session>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final String raw = await rootBundle.loadString('assets/azkar.txt');
      final Map<String, dynamic> data =
          json.decode(raw) as Map<String, dynamic>;
      final List<String> chronologicalKeys = <String>[
        'أذكار الاستيقاظ',
        'أذكار الصباح',
        'أذكار بعد السلام من الصلاة المفروضة',
        'أذكار المساء',
        'أذكار النوم',
      ];
      final List<_Session> loadedSessions = <_Session>[];
      for (final String key in chronologicalKeys) {
        if (data.containsKey(key)) {
          final List<dynamic> items = data[key] as List<dynamic>;
          int count = 0;
          for (final dynamic item in items) {
            if (item is List) {
              count += item.length;
            } else if (item is Map && item['category'] != 'stop') {
              count++;
            }
          }
          final String nameEn = _getEnglishCategoryName(key);
          final String jsonId = _getJsonIdForCategory(key);
          loadedSessions.add(
            _Session(
              nameEn: nameEn,
              nameAr: key,
              descEn: '$count Adhkar',
              descAr:
                  '${ar.toArabicDigits(count.toString(), isArabic: true)} ذكراً',
              actionEn: 'Start',
              actionAr: 'ابدأ',
              jsonId: jsonId,
              progress: 0.0,
              state: 'ready',
            ),
          );
        }
      }
      if (mounted) {
        setState(() {
          _dailySessions = loadedSessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading sessions in Home: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getEnglishCategoryName(String arName) {
    switch (arName) {
      case 'أذكار الاستيقاظ':
        return 'Waking Up';
      case 'أذكار الصباح':
        return 'Morning Azkar';
      case 'أذكار بعد السلام من الصلاة المفروضة':
        return 'Post-Prayer Azkar';
      case 'أذكار المساء':
        return 'Evening Azkar';
      case 'أذكار النوم':
        return 'Sleep Azkar';
      default:
        return 'Azkar';
    }
  }

  String _getJsonIdForCategory(String arName) {
    switch (arName) {
      case 'أذكار الاستيقاظ':
        return 'wakeup';
      case 'أذكار الصباح':
        return 'morning';
      case 'أذكار بعد السلام من الصلاة المفروضة':
        return 'cat_7';
      case 'أذكار المساء':
        return 'evening';
      case 'أذكار النوم':
        return 'sleep';
      default:
        return '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settingsState = context.watch<SettingsCubit>().state;
    final PrayerTimesState prayerState = context
        .watch<PrayerTimesCubit>()
        .state;
    final ProgressState progressState = context.watch<ProgressCubit>().state;
    final bool dark = settingsState is SettingsLoaded
        ? settingsState.settings.darkMode
        : false;
    final bool arabic = settingsState is SettingsLoaded
        ? settingsState.settings.arabicMode
        : false;
    final bool hijriDates = settingsState is SettingsLoaded
        ? settingsState.settings.hijriDates
        : true;
    final PrayerInfo? prayers = prayerState is PrayerTimesLoaded
        ? prayerState.prayerInfo
        : null;
    final SuggestedSession? suggested = prayerState is PrayerTimesLoaded
        ? prayerState.suggestedSession
        : null;
    final List<String> completedSessions = progressState is ProgressLoaded
        ? progressState.progress.completedSessionsToday
        : <String>[];
    final int streak = progressState is ProgressLoaded
        ? progressState.progress.streak
        : 0;
    final int points = progressState is ProgressLoaded
        ? progressState.progress.totalPoints
        : 0;
    String t(String en, String arStr) =>
        ar.localise(en, arStr, isArabic: arabic);
    final Color bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final Color textPrimary = dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final Color secondary = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final Color teal = dark
        ? AppColors.accentTealDark
        : AppColors.accentTealLight;
    final Color gold = dark
        ? AppColors.accentGoldDark
        : AppColors.accentGoldLight;
    final Color cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final Color border = dark ? AppColors.borderDark : AppColors.borderLight;
    final Color progressBg = dark
        ? AppColors.progressBgDark
        : AppColors.progressBgLight;
    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            const IslamicPatternOverlay(lightOpacity: 0.07),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(
                    context,
                    dark,
                    arabic,
                    hijriDates,
                    t,
                    gold,
                    secondary,
                    cardBg,
                    border,
                    teal,
                    streak,
                    points,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPrayerCard(dark, arabic, t, prayers),
                          const SizedBox(height: 16),
                          _buildSessionsHeader(arabic, t, teal, gold),
                          const SizedBox(height: 12),
                          if (_isLoading || prayerState is PrayerTimesInitial || prayerState is PrayerTimesLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),

                            )
                          else
                            _buildSessionCards(
                              dark,
                              arabic,
                              t,
                              teal,
                              gold,
                              cardBg,
                              border,
                              progressBg,
                              secondary,
                              textPrimary,
                              context,
                              suggested,
                              completedSessions,
                              prayers,
                            ),
                          const SizedBox(height: 16),
                          _buildVerseCard(
                            dark,
                            arabic,
                            t,
                            gold,
                            secondary,
                            textPrimary,
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

  Widget _buildHeader(
    BuildContext context,
    bool dark,
    bool arabic,
    bool showHijri,
    String Function(String, String) t,
    Color gold,
    Color secondary,
    Color cardBg,
    Color border,
    Color teal,
    int streak,
    int points,
  ) {
    final DateTime now = DateTime.now();
    final HijriCalendar hijriNow = HijriCalendar.now();
    HijriCalendar.setLocal('en');
    final String gregorianEn = DateFormat('EEEE, d MMMM', 'en_US').format(now);
    final String hijriEn =
        '${hijriNow.hDay} ${hijriNow.getLongMonthName()} ${hijriNow.hYear}';
    final String dateStrEn = showHijri ? hijriEn : gregorianEn;
    final List<String> arDays = <String>[
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    final List<String> arMonths = <String>[
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final String dayName = arDays[now.weekday - 1];
    final String monthName = arMonths[now.month - 1];
    final String gregorianAr =
        '$dayName ${ar.toArabicDigits(now.day.toString(), isArabic: true)} $monthName';
    HijriCalendar.setLocal('ar');
    final String hijriAr =
        '${ar.toArabicDigits(hijriNow.hDay.toString(), isArabic: true)} ${hijriNow.getLongMonthName()} ${ar.toArabicDigits(hijriNow.hYear.toString(), isArabic: true)}';
    final String dateStrAr = showHijri ? hijriAr : gregorianAr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السلام عليكم',
                  style: GoogleFonts.amiri(
                    fontSize: 32,
                    color: gold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                if (!arabic)
                  Text(
                    dateStrEn,
                    style: TextStyle(
                      fontSize: 16,
                      color: secondary,
                      letterSpacing: 0.04,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    dateStrAr,
                    style: GoogleFonts.amiri(fontSize: 18, color: secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatPill(
                  icon: Icons.local_fire_department,
                  value: ar.toArabicDigits(streak.toString(), isArabic: arabic),
                  color: gold,
                  cardBg: cardBg,
                  border: border,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.diamond_outlined,
                  value: ar.toArabicDigits(
                    ar.formatNumber(points),
                    isArabic: arabic,
                  ),
                  color: teal,
                  cardBg: cardBg,
                  border: border,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(
    bool dark,
    bool arabic,
    String Function(String, String) t,
    PrayerInfo? prayers,
  ) {
    final List<Color> gradientColors = dark
        ? AppColors.prayerCardDark
        : AppColors.prayerCardLight;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: dark ? const [0.0, 0.5, 1.0] : const [0.0, 0.55, 1.0],
          colors: gradientColors,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: CustomPaint(painter: _CardStarPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: _PrayerCardContent(
                dark: dark,
                arabic: arabic,
                t: t,
                prayers: prayers,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsHeader(
    bool arabic,
    String Function(String, String) t,
    Color teal,
    Color gold,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          arabic ? 'جلسات اليوم' : "TODAY'S SESSIONS",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: teal,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCards(
    bool dark,
    bool arabic,
    String Function(String, String) t,
    Color teal,
    Color gold,
    Color cardBg,
    Color border,
    Color progressBg,
    Color secondary,
    Color textPrimary,
    BuildContext context,
    SuggestedSession? suggested,
    List<String> completedSessions,
    PrayerInfo? prayers,
  ) {
    final List<_Session> visibleSessions = _dailySessions.where((_Session s) {
      final String state = _determineState(
        s.jsonId,
        prayers,
        completedSessions,
      );
      return state != 'hidden';
    }).toList();
    visibleSessions.sort((_Session a, _Session b) {
      final int pa = _priority(a.jsonId, prayers);
      final int pb = _priority(b.jsonId, prayers);
      return pa.compareTo(pb);
    });
    return Column(
      children: visibleSessions.map((_Session s) {
        final String dynamicState = _determineState(
          s.jsonId,
          prayers,
          completedSessions,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SessionCard(
            session: s,
            dynamicState: dynamicState,
            dark: dark,
            arabic: arabic,
            teal: teal,
            gold: gold,
            cardBg: cardBg,
            border: border,
            progressBg: progressBg,
            secondary: secondary,
            textPrimary: textPrimary,
            isSuggested: dynamicState == 'active',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => ZikrScreen(sessionId: s.jsonId),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  int _priority(String jsonId, PrayerInfo? prayers) {
    final DateTime now = DateTime.now();
    final bool postPrayerActive =
        prayers != null &&
        (_isWithinHourAfter(now, prayers.fajr) ||
            _isWithinHourAfter(now, prayers.dhuhr) ||
            _isWithinHourAfter(now, prayers.asr) ||
            _isWithinHourAfter(now, prayers.maghrib) ||
            _isWithinHourAfter(now, prayers.isha));
    final bool afterIsha = prayers != null && now.isAfter(prayers.isha);
    switch (jsonId) {
      case 'cat_7':
        return postPrayerActive ? 0 : 5;
      case 'wakeup':
        return 1;
      case 'morning':
        return 2;
      case 'sleep':
        return afterIsha ? 3 : 6;
      case 'evening':
        return afterIsha ? 4 : 3;
      default:
        return 10;
    }
  }

  String _determineState(
    String jsonId,
    PrayerInfo? prayers,
    List<String> completedSessions,
  ) {
    if (prayers == null) {
      return 'active';
    }
    final DateTime now = DateTime.now();
    bool isInTime = false;
    switch (jsonId) {
      case 'wakeup':
        if (now.isAfter(prayers.fajr) && now.isBefore(prayers.dhuhr)) {
          isInTime = true;
        }
        break;
      case 'morning':
        if (now.isAfter(prayers.fajr) && now.isBefore(prayers.dhuhr)) {
          isInTime = true;
        }
        break;
      case 'cat_7':
        if (_isWithinHourAfter(now, prayers.fajr) ||
            _isWithinHourAfter(now, prayers.dhuhr) ||
            _isWithinHourAfter(now, prayers.asr) ||
            _isWithinHourAfter(now, prayers.maghrib) ||
            _isWithinHourAfter(now, prayers.isha)) {
          isInTime = true;
        }
        break;
      case 'evening':
        if (now.isAfter(prayers.dhuhr) && now.hour < 24) {
          isInTime = true;
        }
        break;
      case 'sleep':
        if (now.isAfter(prayers.isha) || now.isBefore(prayers.fajr)) {
          isInTime = true;
        }
        break;
    }
    if (!isInTime) {
      return 'hidden';
    }
    if (completedSessions.contains(jsonId)) {
      return 'done';
    }
    return 'active';
  }

  bool _isWithinHourAfter(DateTime now, DateTime prayerTime) =>
      now.isAfter(prayerTime) &&
      now.isBefore(prayerTime.add(const Duration(hours: 1)));

  Widget _buildVerseCard(
    bool dark,
    bool arabic,
    String Function(String, String) t,
    Color gold,
    Color secondary,
    Color textPrimary,
  ) {
    final Color bgColor = dark
        ? const Color(0xFFB8973A).withValues(alpha: 0.06)
        : const Color(0xFFB8973A).withValues(alpha: 0.05);
    final Color borderColor = dark
        ? const Color(0xFFD4A84B).withValues(alpha: 0.15)
        : const Color(0xFFB8973A).withValues(alpha: 0.18);
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Verse of the Day', 'آية اليوم').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'ٱذۡكُرُواْ ٱللَّهَ ذِكۡرٗا كَثِيرٗا',
                    textAlign: TextAlign.right,
                    textDirection: ui.TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      color: textPrimary,
                      height: 1.8,
                    ),
                  ),
                ),
                if (!arabic) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"Remember Allah with much remembrance" — Al-Ahzab 33:41',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondary,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Transform.scale(
            scaleX: arabic ? -1.0 : 1.0,
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: secondary,
              textDirection: ui.TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final Color cardBg;
  final Color border;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.color,
    required this.cardBg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final _Session session;
  final String dynamicState;
  final bool dark;
  final bool arabic;
  final Color teal;
  final Color gold;
  final Color cardBg;
  final Color border;
  final Color progressBg;
  final Color secondary;
  final Color textPrimary;
  final bool isSuggested;
  final VoidCallback? onTap;

  const _SessionCard({
    required this.session,
    required this.dynamicState,
    required this.dark,
    required this.arabic,
    required this.teal,
    required this.gold,
    required this.cardBg,
    required this.border,
    required this.progressBg,
    required this.secondary,
    required this.textPrimary,
    required this.isSuggested,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = dynamicState == 'active';
    final bool isReady = dynamicState == 'ready';
    final bool isLocked = dynamicState == 'locked';
    final Border cardBorder = isSuggested
        ? Border.all(color: teal, width: 1.5)
        : isActive
        ? Border.all(color: teal, width: 1)
        : isReady
        ? Border.all(color: gold.withValues(alpha: 0.4), width: 1)
        : Border.all(color: border, width: 1);
    final Color iconBg = isLocked
        ? progressBg
        : isActive
        ? (dark ? const Color(0x264DB6AC) : const Color(0x140B6E6E))
        : (dark ? const Color(0x1FD4A84B) : const Color(0x14B8973A));
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isLocked ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: cardBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: isLocked
                      ? Icon(Icons.lock_outline, size: 18, color: secondary)
                      : CustomPaint(
                          size: const Size(20, 20),
                          painter: _StarIconPainter(
                            color: isActive ? teal : gold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            arabic ? session.nameAr : session.nameEn,
                            style: arabic
                                ? GoogleFonts.amiri(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                    height: 1.3,
                                  )
                                : TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                          ),
                        ),
                        if (isSuggested)
                          Container(
                            margin: const EdgeInsetsDirectional.only(start: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: teal.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              arabic ? 'الآن' : 'Now',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: teal,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Builder(
                      builder: (BuildContext context) {
                        if (dynamicState == 'done') {
                          final List<({String en, String ar})> phrases =
                              <({String en, String ar})>[
                                (en: "May Allah Accept", ar: "تقبل الله"),
                                (en: "Alhamdulillah", ar: "الحمد لله"),
                                (
                                  en: "Reward Written Inshallah",
                                  ar: "كُتب الأجر إن شاء الله",
                                ),
                              ];
                          final int idx =
                              session.jsonId.hashCode % phrases.length;
                          final ({String en, String ar}) p = phrases[idx];
                          return Text(
                            arabic ? p.ar : p.en,
                            style: arabic
                                ? GoogleFonts.amiri(
                                    fontSize: 14,
                                    color: gold,
                                    fontWeight: FontWeight.bold,
                                  )
                                : TextStyle(
                                    fontSize: 14,
                                    color: gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                          );
                        }
                        return Text(
                          arabic ? session.descAr : session.descEn,
                          style: arabic
                              ? GoogleFonts.amiri(
                                  fontSize: 14,
                                  color: secondary,
                                  height: 1.4,
                                )
                              : TextStyle(fontSize: 14, color: secondary),
                        );
                      },
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          height: 4,
                          color: progressBg,
                          child: FractionallySizedBox(
                            widthFactor: session.progress,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[teal, gold],
                                ),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLocked) ...[
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? teal : gold,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    arabic ? session.actionAr : session.actionEn,
                    style: arabic
                        ? GoogleFonts.amiri(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )
                        : const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StarIconPainter extends CustomPainter {
  final Color color;

  const _StarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final Path path = Path()
      ..moveTo(12 * s, 2 * s)
      ..lineTo(9 * s, 9 * s)
      ..lineTo(2 * s, 9 * s)
      ..lineTo(8 * s, 14 * s)
      ..lineTo(6 * s, 21 * s)
      ..lineTo(12 * s, 17 * s)
      ..lineTo(18 * s, 21 * s)
      ..lineTo(16 * s, 14 * s)
      ..lineTo(22 * s, 9 * s)
      ..lineTo(15 * s, 9 * s)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarIconPainter old) => old.color != color;
}

class _CardStarPainter extends CustomPainter {
  const _CardStarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double tileW = 40.0;
    const double tileH = 40.0;
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (double y = 0.0; y < size.height + tileH; y += tileH) {
      for (double x = 0.0; x < size.width + tileW; x += tileW) {
        canvas.save();
        canvas.translate(x, y);
        final Path path = Path()
          ..moveTo(20, 4)
          ..lineTo(22, 14)
          ..lineTo(32, 12)
          ..lineTo(25, 19)
          ..lineTo(32, 22)
          ..lineTo(25, 25)
          ..lineTo(32, 32)
          ..lineTo(22, 30)
          ..lineTo(20, 40)
          ..lineTo(18, 30)
          ..lineTo(8, 32)
          ..lineTo(15, 25)
          ..lineTo(8, 22)
          ..lineTo(15, 19)
          ..lineTo(8, 12)
          ..lineTo(18, 14)
          ..close();
        canvas.drawPath(path, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_CardStarPainter old) => false;
}

// ─────────────────────────────────────────────
// Prayer Card Content
// ─────────────────────────────────────────────
class _PrayerCardContent extends StatefulWidget {
  final bool dark;
  final bool arabic;
  final String Function(String, String) t;
  final PrayerInfo? prayers;

  const _PrayerCardContent({
    required this.dark,
    required this.arabic,
    required this.t,
    required this.prayers,
  });

  @override
  State<_PrayerCardContent> createState() => _PrayerCardContentState();
}

class _PrayerCardContentState extends State<_PrayerCardContent> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ({String nameAr, String nameEn, String time}) _nextPrayer() {
    if (widget.prayers == null) {
      return (nameAr: 'الظهر', nameEn: 'Dhuhr', time: '--:--');
    }
    final DateTime now = DateTime.now();
    final DateFormat fmt = DateFormat('h:mm a');
    final List<({String nameAr, String nameEn, DateTime dt})> list =
        <({String nameAr, String nameEn, DateTime dt})>[
          (nameAr: 'الفجر', nameEn: 'Fajr', dt: widget.prayers!.fajr),
          (nameAr: 'الظهر', nameEn: 'Dhuhr', dt: widget.prayers!.dhuhr),
          (nameAr: 'العصر', nameEn: 'Asr', dt: widget.prayers!.asr),
          (nameAr: 'المغرب', nameEn: 'Maghrib', dt: widget.prayers!.maghrib),
          (nameAr: 'العشاء', nameEn: 'Isha', dt: widget.prayers!.isha),
        ];
    for (final ({String nameAr, String nameEn, DateTime dt}) p in list) {
      if (p.dt.isAfter(now)) {
        return (nameAr: p.nameAr, nameEn: p.nameEn, time: fmt.format(p.dt));
      }
    }
    final DateTime tomorrowFajr = widget.prayers!.fajr.add(
      const Duration(days: 1),
    );
    return (nameAr: 'الفجر', nameEn: 'Fajr', time: fmt.format(tomorrowFajr));
  }

  String _countdown() {
    if (widget.prayers == null) {
      return '--:--';
    }
    final DateTime now = DateTime.now();
    final List<DateTime> list = <DateTime>[
      widget.prayers!.fajr,
      widget.prayers!.dhuhr,
      widget.prayers!.asr,
      widget.prayers!.maghrib,
      widget.prayers!.isha,
    ];
    for (final DateTime dt in list) {
      if (dt.isAfter(now)) {
        final Duration diff = dt.difference(now);
        final int h = diff.inHours;
        final int m = diff.inMinutes % 60;
        return h > 0
            ? '$h:${m.toString().padLeft(2, '0')}'
            : '0:${m.toString().padLeft(2, '0')}';
      }
    }
    final DateTime tomorrowFajr = widget.prayers!.fajr.add(
      const Duration(days: 1),
    );
    final Duration diff = tomorrowFajr.difference(now);
    final int h = diff.inHours;
    final int m = diff.inMinutes % 60;
    return h > 0
        ? '$h:${m.toString().padLeft(2, '0')}'
        : '0:${m.toString().padLeft(2, '0')}';
  }

  List<({String nameAr, String nameEn, String time, String status})>
  _prayerDots() {
    if (widget.prayers == null) {
      return <({String nameAr, String nameEn, String time, String status})>[
        (nameAr: 'الفجر', nameEn: 'Fajr', time: '--:--', status: 'upcoming'),
        (nameAr: 'الظهر', nameEn: 'Dhuhr', time: '--:--', status: 'next'),
        (nameAr: 'العصر', nameEn: 'Asr', time: '--:--', status: 'upcoming'),
        (
          nameAr: 'المغرب',
          nameEn: 'Maghrib',
          time: '--:--',
          status: 'upcoming',
        ),
        (nameAr: 'العشاء', nameEn: 'Isha', time: '--:--', status: 'upcoming'),
      ];
    }
    final DateTime now = DateTime.now();
    final DateFormat fmt = DateFormat('h:mm');
    bool nextFound = false;
    final List<({String nameAr, String nameEn, DateTime dt})> raw =
        <({String nameAr, String nameEn, DateTime dt})>[
          (nameAr: 'الفجر', nameEn: 'Fajr', dt: widget.prayers!.fajr),
          (nameAr: 'الظهر', nameEn: 'Dhuhr', dt: widget.prayers!.dhuhr),
          (nameAr: 'العصر', nameEn: 'Asr', dt: widget.prayers!.asr),
          (nameAr: 'المغرب', nameEn: 'Maghrib', dt: widget.prayers!.maghrib),
          (nameAr: 'العشاء', nameEn: 'Isha', dt: widget.prayers!.isha),
        ];
    return raw.map((({String nameAr, String nameEn, DateTime dt}) p) {
      String status;
      if (p.dt.isBefore(now)) {
        status = 'done';
      } else if (!nextFound) {
        status = 'next';
        nextFound = true;
      } else {
        status = 'upcoming';
      }
      return (
        nameAr: p.nameAr,
        nameEn: p.nameEn,
        time: fmt.format(p.dt),
        status: status,
      );
    }).toList();
  }

  String _toArabic(String num) {
    if (!widget.arabic) {
      return num;
    }
    const List<String> english = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    ];
    const List<String> arabic = [
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
    ];
    String res = num;
    for (int i = 0; i < english.length; i++) {
      res = res.replaceAll(english[i], arabic[i]);
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final ({String nameAr, String nameEn, String time}) next = _nextPrayer();
    final String countdown = _toArabic(_countdown());
    final List<({String nameAr, String nameEn, String status, String time})>
    dots = _prayerDots();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.t('Next Prayer', 'الصلاة القادمة').toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next.nameAr,
                  style: GoogleFonts.amiri(
                    fontSize: 34,
                    color: AppColors.prayerCardGold,
                    height: 1.0,
                  ),
                ),
                if (!widget.arabic)
                  Text(
                    next.nameEn,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: widget.arabic
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  widget.t('in', 'خلال').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countdown,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.0,
                  ),
                ),
                Text(
                  widget.t('h · min', 'ساعة · دقيقة'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(
          color: Colors.white.withValues(alpha: 0.1),
          height: 1,
          thickness: 1,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dots
              .map(
                (
                  ({String nameAr, String nameEn, String status, String time})
                  p,
                ) => _LivePrayerDot(prayer: p, arabic: widget.arabic),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _LivePrayerDot extends StatelessWidget {
  final ({String nameAr, String nameEn, String status, String time}) prayer;
  final bool arabic;

  const _LivePrayerDot({required this.prayer, required this.arabic});

  @override
  Widget build(BuildContext context) {
    final bool isDone = prayer.status == 'done';
    final bool isNext = prayer.status == 'next';
    final double dotSize = isNext ? 32.0 : 26.0;
    final Color dotColor = isDone
        ? const Color(0x664DB6AC)
        : isNext
        ? AppColors.prayerCardGold
        : Colors.white.withValues(alpha: 0.1);
    final Border? dotBorder = isDone
        ? Border.all(color: const Color(0xB34DB6AC), width: 1.5)
        : isNext
        ? null
        : Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5);
    final Color nameColor = isNext
        ? AppColors.prayerCardGold
        : isDone
        ? const Color(0xB3C8F5F0)
        : Colors.white.withValues(alpha: 0.4);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              border: dotBorder,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 11, color: Color(0xE6C8FFF5))
                  : isNext
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0B5050),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            arabic ? prayer.nameAr : prayer.nameEn,
            textAlign: TextAlign.center,
            style: arabic
                ? GoogleFonts.amiri(
                    fontSize: 12,
                    color: nameColor,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
                  )
                : TextStyle(
                    fontSize: 12,
                    color: nameColor,
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            ar.toArabicDigits(prayer.time, isArabic: arabic),
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.35),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
