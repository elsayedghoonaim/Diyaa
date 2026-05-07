import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hijri/hijri_calendar.dart';
import '../providers/app_provider.dart';
import '../services/prayer_times_service.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/islamic_pattern.dart';
import 'zikr_screen.dart';

// ─────────────────────────────────────────────
// Session Model
// ─────────────────────────────────────────────
class _Session {
  final String nameEn, nameAr, descEn, descAr, actionEn, actionAr;
  final String jsonId;   // maps to azkar.txt session id
  final double progress;
  final String state;   // 'active' | 'ready' | 'locked'
  
  const _Session({
    required this.nameEn, required this.nameAr,
    required this.descEn, required this.descAr,
    required this.actionEn, required this.actionAr,
    required this.jsonId,
    required this.progress, required this.state,
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
  List<_Session> _dailySessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final raw = await rootBundle.loadString('assets/azkar.txt');
      final data = json.decode(raw) as Map<String, dynamic>;
      
      // Order of the day
      final chronologicalKeys = [
        'أذكار الاستيقاظ',
        'أذكار الصباح',
        'أذكار بعد السلام من الصلاة المفروضة',
        'أذكار المساء',
        'أذكار النوم'
      ];

      List<_Session> loadedSessions = [];

      for (String key in chronologicalKeys) {
        if (data.containsKey(key)) {
          final items = data[key] as List;
          int count = 0;
          for (var item in items) {
             if (item is List) {
               count += item.length;
             } else if (item is Map && item['category'] != 'stop') {
               count++;
             }
          }

          String nameEn = _getEnglishCategoryName(key);
          String jsonId = _getJsonIdForCategory(key);
          
          loadedSessions.add(_Session(
            nameEn: nameEn, 
            nameAr: key,
            descEn: '$count Adhkar', 
            descAr: '${_toArabicNumber(count.toString())} ذكراً',
            actionEn: 'Start', 
            actionAr: 'ابدأ',
            jsonId: jsonId, 
            progress: 0, 
            state: 'ready', // State will be determined dynamically in build
          ));
        }
      }

      if (mounted) {
        setState(() {
          _dailySessions = loadedSessions;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading sessions in Home: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getEnglishCategoryName(String arName) {
    switch (arName) {
      case 'أذكار الاستيقاظ': return 'Waking Up';
      case 'أذكار الصباح': return 'Morning Azkar';
      case 'أذكار بعد السلام من الصلاة المفروضة': return 'Post-Prayer Dhikr';
      case 'أذكار المساء': return 'Evening Azkar';
      case 'أذكار النوم': return 'Sleep Azkar';
      default: return 'Azkar';
    }
  }

  String _getJsonIdForCategory(String arName) {
    switch (arName) {
      case 'أذكار الاستيقاظ': return 'wakeup';
      case 'أذكار الصباح': return 'morning';
      case 'أذكار بعد السلام من الصلاة المفروضة': return 'cat_7';
      case 'أذكار المساء': return 'evening';
      case 'أذكار النوم': return 'sleep';
      default: return '1';
    }
  }

  String _toArabicNumber(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < english.length; i++) {
      number = number.replaceAll(english[i], arabic[i]);
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<AppProvider>();
    final dark      = provider.darkMode;
    final arabic    = provider.arabicMode;
    final t         = provider.t;
    final prayers   = provider.prayerInfo;
    final suggested = provider.suggestedSession;

    // Color palette
    final bg          = dark ? AppColors.bgDark          : AppColors.bgLight;
    final textPrimary = dark ? AppColors.textPrimaryDark  : AppColors.textPrimaryLight;
    final secondary   = dark ? AppColors.textSecondaryDark: AppColors.textSecondaryLight;
    final teal        = dark ? AppColors.accentTealDark   : AppColors.accentTealLight;
    final gold        = dark ? AppColors.accentGoldDark   : AppColors.accentGoldLight;
    final cardBg      = dark ? AppColors.cardBgDark       : AppColors.cardBgLight;
    final border      = dark ? AppColors.borderDark       : AppColors.borderLight;
    final progressBg  = dark ? AppColors.progressBgDark   : AppColors.progressBgLight;

    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // Islamic background pattern (HomeScreen uses 0.07 in light)
            const IslamicPatternOverlay(lightOpacity: 0.07),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ── Header ──
                  _buildHeader(context, dark, arabic, provider.hijriDates, t, gold, secondary, cardBg, border, teal),

                  // ── Scrollable body ──
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
                          if (_loading)
                             const Center(child: Padding(
                               padding: EdgeInsets.all(20.0),
                               child: CircularProgressIndicator(),
                             ))
                          else
                            _buildSessionCards(dark, arabic, t, teal, gold, cardBg, border, progressBg, secondary, textPrimary, context, suggested),
                          const SizedBox(height: 16),
                          _buildVerseCard(dark, arabic, t, gold, secondary, textPrimary),
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

  // ── Header ──────────────────────────────────
  Widget _buildHeader(BuildContext context, bool dark, bool arabic, bool showHijri,
      String Function(String, String) t,
      Color gold, Color secondary, Color cardBg, Color border, Color teal) {
    
    // Generate dynamic date strings
    final now = DateTime.now();
    final hijriNow = HijriCalendar.now();
    
    HijriCalendar.setLocal('en');
    String gregorianEn = DateFormat('EEEE, d MMMM', 'en_US').format(now);
    String hijriEn = '${hijriNow.hDay} ${hijriNow.getLongMonthName()} ${hijriNow.hYear}';
    String dateStrEn = showHijri ? hijriEn : gregorianEn;
    
    // Quick Arabic translation for Gregorian
    final arDays = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final arMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    
    String dayName = arDays[now.weekday - 1];
    String monthName = arMonths[now.month - 1];
    String gregorianAr = '$dayName ${_toArabicNumber(now.day.toString())} $monthName';
    
    HijriCalendar.setLocal('ar');
    String hijriAr = '${_toArabicNumber(hijriNow.hDay.toString())} ${hijriNow.getLongMonthName()} ${_toArabicNumber(hijriNow.hYear.toString())}';
    String dateStrAr = showHijri ? hijriAr : gregorianAr;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السلام عليكم',
                  style: GoogleFonts.amiri(
                    fontSize: 32, color: gold, height: 1.1,
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
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      color: secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Stat pills
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatPill(
                  icon: Icons.local_fire_department,
                  value: context.read<AppProvider>().toArabicDigits(context.read<AppProvider>().streak.toString()),
                  color: gold,
                  cardBg: cardBg,
                  border: border,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.diamond_outlined,
                  value: context.read<AppProvider>().toArabicDigits(_formatNumber(context.read<AppProvider>().totalPoints)),
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

  // ── Prayer Card ─────────────────────────────
  Widget _buildPrayerCard(bool dark, bool arabic,
      String Function(String, String) t, PrayerInfo? prayers) {
    final gradientColors = dark
        ? AppColors.prayerCardDark
        : AppColors.prayerCardLight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: dark ? const [0, 0.5, 1] : const [0, 0.55, 1],
          colors: gradientColors,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Star pattern overlay inside card
            Positioned.fill(
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

  // ── Sessions Header ──────────────────────────
  Widget _buildSessionsHeader(bool arabic,
      String Function(String, String) t,
      Color teal, Color gold) {
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
      bool dark, bool arabic, String Function(String, String) t,
      Color teal, Color gold, Color cardBg, Color border,
      Color progressBg, Color secondary, Color textPrimary,
      BuildContext context, SuggestedSession suggested) {
    
    final provider = context.watch<AppProvider>();
    final prayers = provider.prayerInfo;

    // 1. Filter: only show sessions that are in their time window
    final visibleSessions = _dailySessions.where((s) {
      final state = _determineState(s.jsonId, prayers, provider);
      return state != 'hidden';
    }).toList();

    // 2. Sort by priority for the current moment
    visibleSessions.sort((a, b) {
      final pa = _priority(a.jsonId, prayers);
      final pb = _priority(b.jsonId, prayers);
      return pa.compareTo(pb);
    });

    return Column(
      children: visibleSessions.map((s) {
        String dynamicState = _determineState(s.jsonId, prayers, provider);

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
                MaterialPageRoute(builder: (_) => ZikrScreen(sessionId: s.jsonId)),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  /// Priority order (lower = higher in the list).
  /// Post-prayer is always first when within 1 hour of a prayer.
  /// After Isha: Sleep before Evening.
  /// Before Dhuhr: Wakeup before Morning.
  int _priority(String jsonId, PrayerInfo? prayers) {
    final now = DateTime.now();
    final bool postPrayerActive = prayers != null && (
      _isWithinHourAfter(now, prayers.fajr) ||
      _isWithinHourAfter(now, prayers.dhuhr) ||
      _isWithinHourAfter(now, prayers.asr) ||
      _isWithinHourAfter(now, prayers.maghrib) ||
      _isWithinHourAfter(now, prayers.isha)
    );
    final bool afterIsha = prayers != null && now.isAfter(prayers.isha);

    switch (jsonId) {
      case 'cat_7': // post prayer — first when active
        return postPrayerActive ? 0 : 5;
      case 'wakeup':
        return 1; // before morning
      case 'morning':
        return 2;
      case 'sleep':
        return afterIsha ? 3 : 6; // before evening after Isha
      case 'evening':
        return afterIsha ? 4 : 3; // after sleep when post-Isha
      default:
        return 10;
    }
  }

  String _determineState(String jsonId, PrayerInfo? prayers, AppProvider provider) {
    if (prayers == null) return 'active';
    
    final now = DateTime.now();
    bool isInTime = false;
    
    switch (jsonId) {
      case 'wakeup':
        // Fajr to Dhuhr
        if (now.isAfter(prayers.fajr) && now.isBefore(prayers.dhuhr)) isInTime = true;
        break;
      case 'morning':
        // Fajr to Dhuhr
        if (now.isAfter(prayers.fajr) && now.isBefore(prayers.dhuhr)) isInTime = true;
        break;
      case 'cat_7': // post prayer — 1 hour after each prayer
        if (_isWithinHourAfter(now, prayers.fajr) ||
            _isWithinHourAfter(now, prayers.dhuhr) ||
            _isWithinHourAfter(now, prayers.asr) ||
            _isWithinHourAfter(now, prayers.maghrib) ||
            _isWithinHourAfter(now, prayers.isha)) {
          isInTime = true;
        }
        break;
      case 'evening':
        // Dhuhr to midnight
        if (now.isAfter(prayers.dhuhr) && now.hour < 24) isInTime = true;
        break;
      case 'sleep':
        // Isha to Fajr
        if (now.isAfter(prayers.isha) || now.isBefore(prayers.fajr)) isInTime = true;
        break;
    }

    if (!isInTime) return 'hidden';
    if (provider.isSessionCompleted(jsonId)) return 'done';
    return 'active';
  }

  bool _isWithinHourAfter(DateTime now, DateTime prayerTime) {
    return now.isAfter(prayerTime) && now.isBefore(prayerTime.add(const Duration(hours: 1)));
  }

  // ── Verse of the Day ─────────────────────────
  Widget _buildVerseCard(bool dark, bool arabic,
      String Function(String, String) t,
      Color gold, Color secondary, Color textPrimary) {
    final bgColor = dark
        ? const Color(0xFFB8973A).withOpacity(0.06)
        : const Color(0xFFB8973A).withOpacity(0.05);
    final borderColor = dark
        ? const Color(0xFFD4A84B).withOpacity(0.15)
        : const Color(0xFFB8973A).withOpacity(0.18);

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
                // Arabic Quranic text — always RTL, always right-aligned
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
          const SizedBox(width: 8),
          Transform.scale(
            scaleX: arabic ? -1 : 1,
            child: Icon(Icons.chevron_right, size: 16, color: secondary),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(int n) {
  if (n < 1000) return n.toString();
  if (n < 1000000) {
    final s = n.toString();
    final thousands = s.substring(0, s.length - 3);
    final rest = s.substring(s.length - 3);
    return '$thousands,$rest';
  }
  return n.toString();
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
    required this.icon, required this.value,
    required this.color, required this.cardBg, required this.border,
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


/// Session card
class _SessionCard extends StatelessWidget {
  final _Session session;
  final String dynamicState;
  final bool dark, arabic;
  final Color teal, gold, cardBg, border, progressBg, secondary, textPrimary;
  final VoidCallback? onTap;

  final bool isSuggested;

  const _SessionCard({
    required this.session, required this.dynamicState, required this.dark, required this.arabic,
    required this.teal, required this.gold, required this.cardBg,
    required this.border, required this.progressBg,
    required this.secondary, required this.textPrimary,
    required this.isSuggested,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = dynamicState == 'active';
    final isReady  = dynamicState == 'ready';
    final isLocked = dynamicState == 'locked';

    final cardBorder = isSuggested
        ? Border.all(color: teal, width: 1.5)
        : isActive
            ? Border.all(color: teal, width: 1)
            : isReady
                ? Border.all(color: gold.withOpacity(0.4), width: 1)
                : Border.all(color: border, width: 1);

    final iconBg = isLocked
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
              // Left icon
              Container(
                width: 44, height: 44,
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

              // Center: name + desc + progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            arabic ? session.nameAr : session.nameEn,
                            style: arabic
                                ? GoogleFonts.amiri(
                                    fontSize: 18, fontWeight: FontWeight.w600,
                                    color: textPrimary, height: 1.3)
                                : TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600,
                                    color: textPrimary),
                          ),
                        ),
                        if (isSuggested)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: teal.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                  color: teal.withOpacity(0.4), width: 1),
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
                      builder: (context) {
                        if (dynamicState == 'done') {
                          final phrases = [
                            (en: "May Allah Accept 🤍", ar: "تقبل الله 🤍"),
                            (en: "Alhamdulillah 🌟", ar: "الحمد لله 🌟"),
                            (en: "Reward Written 📜", ar: "كُتب الأجر 📜"),
                          ];
                          // Use sessionId hash to pick a consistent phrase for this session
                          final idx = session.jsonId.hashCode % phrases.length;
                          final p = phrases[idx];
                          return Text(
                            arabic ? p.ar : p.en,
                            style: arabic
                                ? GoogleFonts.amiri(fontSize: 14, color: gold, fontWeight: FontWeight.bold)
                                : TextStyle(fontSize: 14, color: gold, fontWeight: FontWeight.bold),
                          );
                        }
                        return Text(
                          arabic ? session.descAr : session.descEn,
                          style: arabic
                              ? GoogleFonts.amiri(fontSize: 14, color: secondary, height: 1.4)
                              : TextStyle(fontSize: 14, color: secondary),
                        );
                      }
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 8),
                      // Progress bar: gradient teal→gold
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
                                gradient: LinearGradient(colors: [teal, gold]),
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

              // Right: action button
              if (!isLocked) ...[
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? teal : gold,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    arabic ? session.actionAr : session.actionEn,
                    style: arabic
                        ? GoogleFonts.amiri(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: Colors.white)
                        : const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: Colors.white),
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

/// Star/polygon icon used inside session cards
/// Path: M12 2L9 9H2L8 14L6 21L12 17L18 21L16 14L22 9H15L12 2Z
class _StarIconPainter extends CustomPainter {
  final Color color;
  _StarIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(12 * s, 2 * s)
      ..lineTo(9 * s,  9 * s)
      ..lineTo(2 * s,  9 * s)
      ..lineTo(8 * s,  14 * s)
      ..lineTo(6 * s,  21 * s)
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

/// 40×40 star pattern inside prayer card
/// Path: M20 4L22 14L32 12L25 19L32 22L25 25L32 32L22 30L20 40L18 30L8 32L15 25L8 22L15 19L8 12L18 14Z
class _CardStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileW = 40.0;
    const tileH = 40.0;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (double y = 0; y < size.height + tileH; y += tileH) {
      for (double x = 0; x < size.width + tileW; x += tileW) {
        canvas.save();
        canvas.translate(x, y);
        final path = Path()
          ..moveTo(20, 4)  ..lineTo(22, 14) ..lineTo(32, 12) ..lineTo(25, 19)
          ..lineTo(32, 22) ..lineTo(25, 25) ..lineTo(32, 32) ..lineTo(22, 30)
          ..lineTo(20, 40) ..lineTo(18, 30) ..lineTo(8,  32) ..lineTo(15, 25)
          ..lineTo(8,  22) ..lineTo(15, 19) ..lineTo(8,  12) ..lineTo(18, 14)
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
// Prayer Card Content — real or fallback data
// ─────────────────────────────────────────────
class _PrayerCardContent extends StatefulWidget {
  final bool dark, arabic;
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
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Returns the next upcoming prayer name/time from real data
  ({String nameAr, String nameEn, String time}) _nextPrayer() {
    if (widget.prayers == null) return (nameAr: 'الظهر', nameEn: 'Dhuhr', time: '--:--');
    final now = DateTime.now();
    final fmt = DateFormat('h:mm a');
    final list = [
      (nameAr: 'الفجر',    nameEn: 'Fajr',    dt: widget.prayers!.fajr),
      (nameAr: 'الظهر',    nameEn: 'Dhuhr',   dt: widget.prayers!.dhuhr),
      (nameAr: 'العصر',    nameEn: 'Asr',     dt: widget.prayers!.asr),
      (nameAr: 'المغرب',   nameEn: 'Maghrib', dt: widget.prayers!.maghrib),
      (nameAr: 'العشاء',   nameEn: 'Isha',    dt: widget.prayers!.isha),
    ];
    for (final p in list) {
      if (p.dt.isAfter(now)) {
        return (nameAr: p.nameAr, nameEn: p.nameEn, time: fmt.format(p.dt));
      }
    }
    // All passed — next is tomorrow's Fajr (approximate)
    final tomorrowFajr = widget.prayers!.fajr.add(const Duration(days: 1));
    return (nameAr: 'الفجر', nameEn: 'Fajr', time: fmt.format(tomorrowFajr));
  }

  String _countdown() {
    if (widget.prayers == null) return '--:--';
    final now = DateTime.now();
    final list = [widget.prayers!.fajr, widget.prayers!.dhuhr, widget.prayers!.asr, widget.prayers!.maghrib, widget.prayers!.isha];
    for (final dt in list) {
      if (dt.isAfter(now)) {
        final diff = dt.difference(now);
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        return h > 0 ? '$h:${m.toString().padLeft(2, '0')}' : '0:${m.toString().padLeft(2, '0')}';
      }
    }
    // If all passed, countdown to tomorrow's fajr
    final tomorrowFajr = widget.prayers!.fajr.add(const Duration(days: 1));
    final diff = tomorrowFajr.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}' : '0:${m.toString().padLeft(2, '0')}';
  }

  List<({String nameAr, String nameEn, String time, String status})> _prayerDots() {
    if (widget.prayers == null) {
      return [
        (nameAr: 'الفجر',  nameEn: 'Fajr',    time: '--:--', status: 'upcoming'),
        (nameAr: 'الظهر',  nameEn: 'Dhuhr',   time: '--:--', status: 'next'),
        (nameAr: 'العصر',  nameEn: 'Asr',     time: '--:--', status: 'upcoming'),
        (nameAr: 'المغرب', nameEn: 'Maghrib', time: '--:--', status: 'upcoming'),
        (nameAr: 'العشاء', nameEn: 'Isha',    time: '--:--', status: 'upcoming'),
      ];
    }
    final now = DateTime.now();
    final fmt = DateFormat('h:mm');
    bool nextFound = false;
    final raw = [
      (nameAr: 'الفجر',  nameEn: 'Fajr',    dt: widget.prayers!.fajr),
      (nameAr: 'الظهر',  nameEn: 'Dhuhr',   dt: widget.prayers!.dhuhr),
      (nameAr: 'العصر',  nameEn: 'Asr',     dt: widget.prayers!.asr),
      (nameAr: 'المغرب', nameEn: 'Maghrib', dt: widget.prayers!.maghrib),
      (nameAr: 'العشاء', nameEn: 'Isha',    dt: widget.prayers!.isha),
    ];
    return raw.map((p) {
      String status;
      if (p.dt.isBefore(now)) {
        status = 'done';
      } else if (!nextFound) {
        status = 'next';
        nextFound = true;
      } else {
        status = 'upcoming';
      }
      return (nameAr: p.nameAr, nameEn: p.nameEn, time: fmt.format(p.dt), status: status);
    }).toList();
  }

  String _toArabic(String num) {
    if (!widget.arabic) return num;
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String res = num;
    for (int i = 0; i < english.length; i++) {
      res = res.replaceAll(english[i], arabic[i]);
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextPrayer();
    final countdown = _toArabic(_countdown());
    final dots = _prayerDots();

    final nextTime = _toArabic(next.time);

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
                    fontSize: 12, fontWeight: FontWeight.w700,
                    letterSpacing: 1.2, color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  next.nameAr,
                  style: GoogleFonts.amiri(
                    fontSize: 34, color: AppColors.prayerCardGold, height: 1.0,
                  ),
                ),
                if (!widget.arabic)
                  Text(
                    next.nameEn,
                    style: TextStyle(
                      fontSize: 16, color: Colors.white.withOpacity(0.7),
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: widget.arabic ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(
                  widget.t('in', 'خلال').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10, color: Colors.white.withOpacity(0.5), letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countdown,
                  style: const TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w200,
                    color: Colors.white, letterSpacing: -1, height: 1.0,
                  ),
                ),
                Text(
                  widget.t('h · min', 'ساعة · دقيقة'),
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(color: Colors.white.withOpacity(0.1), height: 1, thickness: 1),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dots.map((p) => _LivePrayerDot(prayer: p, arabic: widget.arabic)).toList(),
        ),
      ],
    );
  }
}

class _LivePrayerDot extends StatelessWidget {
  final ({String nameAr, String nameEn, String time, String status}) prayer;
  final bool arabic;
  const _LivePrayerDot({required this.prayer, required this.arabic});

  @override
  Widget build(BuildContext context) {
    final isDone = prayer.status == 'done';
    final isNext = prayer.status == 'next';
    final dotSize = isNext ? 32.0 : 26.0;
    final dotColor = isDone
        ? const Color(0x664DB6AC)
        : isNext ? AppColors.prayerCardGold : Colors.white.withOpacity(0.1);
    final dotBorder = isDone
        ? Border.all(color: const Color(0xB34DB6AC), width: 1.5)
        : isNext ? null : Border.all(color: Colors.white.withOpacity(0.2), width: 1.5);
    final nameColor = isNext
        ? AppColors.prayerCardGold
        : isDone ? const Color(0xB3C8F5F0) : Colors.white.withOpacity(0.4);

    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: dotSize, height: dotSize,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor, border: dotBorder),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 11, color: Color(0xE6C8FFF5))
                : isNext
                    ? Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF0B5050),
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
              ? GoogleFonts.amiri(fontSize: 12, color: nameColor,
                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w400)
              : TextStyle(fontSize: 12, color: nameColor,
                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w400),
        ),
        const SizedBox(height: 2),
        Text(
          arabic ? context.read<AppProvider>().toArabicDigits(prayer.time) : prayer.time,
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35), letterSpacing: 0.2),
        ),
      ]),
    );
  }
}
