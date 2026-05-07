import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:diyaa/providers/app_provider.dart';
import 'package:diyaa/theme/app_colors.dart';
import 'package:diyaa/widgets/shared/islamic_pattern.dart';
import 'celebration_screen.dart';

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────
String _getEnglishCategoryName(String arName) {
  final map = {
    'أذكار الصباح والمساء': 'Morning & Evening Azkar',
    'أذكار النوم': 'Sleep Azkar',
    'أذكار الاستيقاظ من النوم': 'Waking Up Azkar',
    'دعاء دخول الخلاء': 'Entering Restroom',
    'دعاء الخروج من الخلاء': 'Leaving Restroom',
    'الذكر قبل الوضوء': 'Before Wudu',
    'الذكر بعد الفراغ من الوضوء': 'After Wudu',
    'الذكر عند الخروج من المنزل': 'Leaving Home',
    'الذكر عند دخول المنزل': 'Entering Home',
    'دعاء الذهاب إلى المسجد': 'Going to Mosque',
    'دعاء دخول المسجد': 'Entering Mosque',
    'دعاء الخروج من المسجد': 'Leaving Mosque',
    'أذكار الآذان': 'Call to Prayer (Azan)',
    'دعاء ُلبْس الثوب': 'Wearing Clothes',
    'دعاء ُلبْس الثوب الجديد': 'Wearing New Clothes',
    'الدعاء لمن لبس ثوبا جديدا': 'Supplication for New Clothes',
    'ما يقول إذا وضع ثوبه': 'Undressing',
    'دعاء الاستفتاح': 'Opening Supplication',
    'دعاء الركوع': 'Bowing (Ruku)',
    'دعاء الرفع من الركوع': 'Rising from Bowing',
    'دعاء السجود': 'Prostration (Sujud)',
    'دعاء الجلسة بين السجدتين': 'Sitting between Prostrations',
    'دعاء سجود التلاوة': 'Prostration of Recitation',
    'التشهد': 'Tashahhud',
    'الصلاة على النبي بعد التشهد': 'Sending Blessings on Prophet',
    'الدعاء بعد التشهد الأخير قبل السلام': 'Before Tasleem',
    'الأذكار بعد السلام من الصلاة': 'Azkar after Prayer',
    'دعاء صلاة الاستخارة': 'Istikhara Prayer',
    'دعاء الهم والحزن': 'Anxiety and Sorrow',
    'دعاء الكرب': 'Distress',
    'دعاء لقاء العدو و ذي السلطان': 'Meeting Enemy or Ruler',
    'دعاء من خاف ظلم السلطان': 'Fear of Oppression',
    'الدعاء على العدو': 'Against the Enemy',
    'ما يقول من خاف قوما': 'Fear of a People',
    'دعاء قضاء الدين': 'Settling Debt',
    'دعاء من استصعب عليه أمر': 'Facing Difficulties',
    'دعاء طرد الشيطان و وساوسه': 'Expelling Satan',
    'الدعاء للمريض في عيادته': 'Visiting the Sick',
    'دعاء التعزية': 'Condolence',
    'دعاء الريح': 'During Wind',
    'دعاء الرعد': 'During Thunder',
    'من أدعية الاستسقاء': 'Praying for Rain',
    'الدعاء إذا نزل المطر': 'When it Rains',
    'الدعاء قبل الطعام': 'Before Eating',
    'الدعاء عند الفراغ من الطعام': 'After Eating',
  };
  return map[arName] ?? 'Hisn al-Muslim';
}
class ZikrItem {
  final String arabic;
  final int repeat;
  final String description; // Added description

  const ZikrItem({
    required this.arabic,
    required this.repeat,
    this.description = '',
  });
}

class AzkarSession {
  final String id, nameAr;
  final List<ZikrItem> zikrs;

  const AzkarSession({
    required this.id,
    required this.nameAr,
    required this.zikrs,
  });
}

// ─────────────────────────────────────────────
// ZikrScreen
// ─────────────────────────────────────────────
class ZikrScreen extends StatefulWidget {
  final String sessionId;

  const ZikrScreen({super.key, this.sessionId = '1'}); // Use string ID from adhkar_source

  @override
  State<ZikrScreen> createState() => _ZikrScreenState();
}

class _ZikrScreenState extends State<ZikrScreen> {
  AzkarSession? _session;
  int _zikrIdx = 0;
  List<int> _counts = []; // Per-zikr counts — preserved when navigating
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. First, attempt to load from azkar.txt for structured sessions (Morning, Sleep, Wakeup, etc)
      bool loadedFromTxt = false;
      String targetCategoryName = '';
      
      if (widget.sessionId == 'morning' || widget.sessionId == '1') {
        targetCategoryName = 'أذكار الصباح';
      } else if (widget.sessionId == 'evening') {
        targetCategoryName = 'أذكار المساء';
      } else if (widget.sessionId == 'sleep' || widget.sessionId == '2') {
        targetCategoryName = 'أذكار النوم';
      } else if (widget.sessionId == 'wakeup' || widget.sessionId == '3') {
        targetCategoryName = 'أذكار الاستيقاظ';
      } else if (widget.sessionId == 'cat_7' || widget.sessionId == '27') {
        targetCategoryName = 'أذكار بعد السلام من الصلاة المفروضة';
      }

      if (targetCategoryName.isNotEmpty) {
        try {
          final txtRaw = await rootBundle.loadString('assets/azkar.txt');
          final txtData = json.decode(txtRaw) as Map<String, dynamic>;
          
          if (txtData.containsKey(targetCategoryName)) {
            final categoryData = txtData[targetCategoryName] as List;
            
            List<ZikrItem> parsedZikrs = [];
            
            for (var item in categoryData) {
              // azkar.txt has a weird structure where the first item is sometimes an array itself
              if (item is List) {
                for (var subItem in item) {
                  parsedZikrs.add(_parseTxtZikr(subItem));
                }
              } else if (item is Map<String, dynamic> && item['category'] != 'stop') {
                 parsedZikrs.add(_parseTxtZikr(item));
              }
            }

            if (parsedZikrs.isNotEmpty) {
              final session = AzkarSession(
                id: widget.sessionId,
                nameAr: targetCategoryName,
                zikrs: parsedZikrs,
              );
              if (mounted) {
                setState(() {
                  _session = session;
                  _counts = List.filled(parsedZikrs.length, 0);
                  _loading = false;
                });
              }
              loadedFromTxt = true;
            }
          }
        } catch (e) {
          // Fallback to json if txt parsing fails
          debugPrint('Error loading from azkar.txt: $e');
        }
      }

      // 2. If not loaded from txt, fallback to adhkar_source.json (Library use case)
      if (!loadedFromTxt) {
        final raw = await rootBundle.loadString('assets/adhkar_source.json');
        final data = json.decode(raw) as List<dynamic>;
        
        final sessions = data.map((cat) {
          return AzkarSession(
            id: cat['id'].toString(),
            nameAr: cat['category'] as String,
            zikrs: (cat['array'] as List).map((z) => ZikrItem(
              arabic: z['text'] as String,
              repeat: z['count'] as int,
            )).toList(),
          );
        }).toList();

        final session = sessions.firstWhere(
          (s) => s.id == widget.sessionId,
          orElse: () => sessions.first,
        );
        
        if (mounted) {
          setState(() {
            _session = session;
            _counts = List.filled(session.zikrs.length, 0);
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  ZikrItem _parseTxtZikr(Map<String, dynamic> map) {
    int count = 1;
    if (map['count'] != null) {
      count = int.tryParse(map['count'].toString()) ?? 1;
    }
    
    // Clean up content if it's full of \n strings (like in Quranic verses)
    String content = map['content'] as String? ?? '';
    // Simplify the replacement logic to avoid parsing errors
    content = content.replaceAll(r'\n', '').replaceAll(r"', '", '').replaceAll(r'"', '').trim();

    return ZikrItem(
      arabic: content,
      repeat: count,
      description: map['description'] as String? ?? '',
    );
  }

  void _increment() {
    if (_session == null) return;
    
    final provider = context.read<AppProvider>();
    if (provider.soundEnabled) {
      HapticFeedback.lightImpact();
    }
    
    final total = _session!.zikrs[_zikrIdx].repeat;
    setState(() {
      if (_counts[_zikrIdx] < total) {
        _counts[_zikrIdx]++;
      } else {
        if (provider.soundEnabled) {
          HapticFeedback.mediumImpact();
        }
        if (_zikrIdx < _session!.zikrs.length - 1) {
          _zikrIdx++;
          // Do NOT reset count — it was already at max for prev, and new zikr starts at 0
        } else {
          // All zikrs completed! Trigger celebration
          _completeSession();
        }
      }
    });
  }

  void _completeSession() {
    if (_session == null) return;
    final provider = context.read<AppProvider>();
    provider.completeSession(widget.sessionId);

    final sessionNameEn = _getEnglishCategoryName(_session!.nameAr);

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CelebrationScreen(
          sessionId: widget.sessionId,
          sessionNameAr: _session!.nameAr,
          sessionNameEn: sessionNameEn,
          zikrCount: _session!.zikrs.length,
        ),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goPrev() {
    if (_zikrIdx > 0) setState(() { _zikrIdx--; });
  }

  void _goNext() {
    if (_session == null) return;
    if (_zikrIdx < _session!.zikrs.length - 1) setState(() { _zikrIdx++; });
  }

  void _goToIndex(int i) => setState(() { _zikrIdx = i; });

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<AppProvider>();
    final dark   = prov.darkMode;
    final arabic = prov.arabicMode;
    final t      = prov.t;

    final bg          = dark ? AppColors.bgDark           : AppColors.bgLight;
    final textPrimary = dark ? AppColors.textPrimaryDark   : AppColors.textPrimaryLight;
    final textSec     = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teal        = dark ? AppColors.accentTealDark    : AppColors.accentTealLight;
    final gold        = dark ? AppColors.accentGoldDark    : AppColors.accentGoldLight;
    final border      = dark ? AppColors.borderZikrDark    : AppColors.borderZikrLight;
    final progressBg  = dark ? AppColors.progressBgZikrDark: AppColors.progressBgZikrLight;
    final ringTrack   = dark ? AppColors.ringTrackDark     : AppColors.ringTrackLight;
    final counterBg   = dark ? AppColors.counterBgDark     : AppColors.counterBgLight;
    final arrowBg     = dark ? AppColors.arrowBgDark       : AppColors.arrowBgLight;

    final sessionNameAr = _session?.nameAr ?? 'أذكار الصباح';
    final sessionNameEn = _getEnglishCategoryName(sessionNameAr);
    final zikrCount     = _session?.zikrs.length ?? 3;
    final zikr          = _session?.zikrs[_zikrIdx];

    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(children: [
          const IslamicPatternOverlay(lightOpacity: 0.07),
          SafeArea(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: teal))
                : Column(
                    children: [
                      // ── Header ─── pushed down via top padding 20→30
                      _Header(
                        arabic: arabic,
                        textSec: textSec,
                        teal: teal,
                        gold: gold,
                        nameAr: sessionNameAr,
                        nameEn: !arabic ? sessionNameEn : '',
                        onBack: () => Navigator.of(context).pop(),
                      ),

                      const SizedBox(height: 12), // Added space here

                      // ── Progress bar + labels ──
                      _ProgressBar(
                        zikrIdx: _zikrIdx,
                        sessionTotal: zikrCount,
                        sessionCurrent: _zikrIdx,
                        teal: teal,
                        progressBg: progressBg,
                        textSec: textSec,
                        arabic: arabic,
                        t: t,
                      ),

                      // ── Zikr text area: scrollable, centered when short ──────
                      Expanded(
                        child: zikr == null
                            ? const SizedBox.shrink()
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: IntrinsicHeight(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _ZikrContent(
                                              zikr: zikr,
                                              sessionNameEn: _getEnglishCategoryName(_session?.nameAr ?? ''),
                                              dark: dark,
                                              arabic: arabic,
                                              teal: teal,
                                              gold: gold,
                                              border: border,
                                              textPrimary: textPrimary,
                                              textSec: textSec,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // ── Interaction zone ─── moved up via smaller bottom padding
                      if (zikr != null)
                        _InteractionZone(
                          zikr: zikr,
                          count: _counts.isNotEmpty ? _counts[_zikrIdx] : 0,
                          zikrIdx: _zikrIdx,
                          zikrCount: zikrCount,
                          dark: dark,
                          arabic: arabic,
                          teal: teal,
                          textSec: textSec,
                          ringTrack: ringTrack,
                          counterBg: counterBg,
                          arrowBg: arrowBg,
                          border: border,
                          progressBg: progressBg,
                          textPrimary: textPrimary,
                          onTap: _increment,
                          onPrev: _goPrev,
                          onNext: _goNext,
                          onDotTap: _goToIndex,
                          t: t,
                        ),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header — title a size bigger, more top pad
// ─────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool arabic;
  final Color textSec, teal, gold;
  final String nameAr, nameEn;
  final VoidCallback onBack;

  const _Header({
    required this.arabic,
    required this.textSec,
    required this.teal,
    required this.gold,
    required this.nameAr,
    required this.nameEn,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Increased top from 14→24 to push header down slightly
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: SizedBox(
              width: 36, height: 36,
              child: Icon(
                arabic ? Icons.chevron_right : Icons.chevron_left,
                size: 26,
                color: textSec,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title: Amiri 24
                Text(
                  nameAr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(fontSize: 24, color: gold, height: 1.2),
                ),
                // Subtitle: 12px
                if (!arabic)
                  Text(
                    nameEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: textSec, letterSpacing: 0.04),
                  ),
              ],
            ),
          ),
          // Circular play button
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: teal, width: 1.5),
            ),
            child: Icon(Icons.play_arrow, size: 14, color: teal),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Progress Bar
// ─────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int zikrIdx, sessionTotal, sessionCurrent;
  final Color teal, progressBg, textSec;
  final bool arabic;
  final String Function(String, String) t;

  const _ProgressBar({
    required this.zikrIdx,
    required this.sessionTotal,
    required this.sessionCurrent,
    required this.teal,
    required this.progressBg,
    required this.textSec,
    required this.arabic,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final progress = sessionTotal > 0 ? sessionCurrent / sessionTotal : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              height: 3,
              color: progressBg,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(color: teal),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t('Zikr ${zikrIdx + 1} of $sessionTotal', 'الذكر ${zikrIdx + 1} من $sessionTotal'),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSec),
              ),
              Text(
                '$sessionCurrent/$sessionTotal',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: teal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Adaptive font size for Arabic texts of varying lengths
double _arabicFontSize(String text) {
  final len = text.length;
  if (len < 60)  return 36;
  if (len < 150) return 28;
  if (len < 300) return 22;
  return 18;
}

// ─────────────────────────────────────────────
// Zikr Content (the hero text block)
// ─────────────────────────────────────────────
class _ZikrContent extends StatelessWidget {
  final ZikrItem zikr;
  final String sessionNameEn;
  final bool dark, arabic;
  final Color teal, gold, border, textPrimary, textSec;

  const _ZikrContent({
    required this.zikr,
    required this.sessionNameEn,
    required this.dark,
    required this.arabic,
    required this.teal,
    required this.gold,
    required this.border,
    required this.textPrimary,
    required this.textSec,
  });

  @override
  Widget build(BuildContext context) {
    final sourceBg = dark
        ? const Color(0xFF4DB6AC).withOpacity(0.10)
        : const Color(0xFF0B6E6E).withOpacity(0.06);
    final repeatBorderColor = dark
        ? const Color(0xFFB8973A).withOpacity(0.25)
        : const Color(0xFFB8973A).withOpacity(0.30);
    final repeatBg = dark
        ? const Color(0xFFD4A84B).withOpacity(0.07)
        : const Color(0xFFB8973A).withOpacity(0.06);

    return Padding(
      // Matches original CSS: padding: '8px 28px 0'
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Source badge: show zikr description if it has one, else the session name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: sourceBg,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              arabic
                  ? 'حصن المسلم'
                  : (zikr.description.isNotEmpty ? zikr.description : sessionNameEn),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: teal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),

          // Arabic hero text — always RTL, adaptive font size
          Text(
            zikr.arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: _arabicFontSize(zikr.arabic),
              color: gold,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 8),

          // Ornamental divider
          _OrnamentalDivider(lineColor: border, dotColor: gold),
          const SizedBox(height: 16),

          if (zikr.description.isNotEmpty) ...[
            Text(
              zikr.description,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 14, color: textPrimary.withOpacity(0.8), height: 1.5),
            ),
            const SizedBox(height: 16),
          ],

          // Repeat pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            decoration: BoxDecoration(
              color: repeatBg,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: repeatBorderColor, width: 1),
            ),
            child: Text(
              arabic ? 'كرر ${zikr.repeat} مرة' : 'Repeat ${zikr.repeat}×',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: gold, letterSpacing: 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Interaction Zone — bottom padding reduced to 20 (was padBottom:8+extra)
// ─────────────────────────────────────────────
class _InteractionZone extends StatelessWidget {
  final ZikrItem zikr;
  final int count, zikrIdx, zikrCount;
  final bool dark, arabic;
  final Color teal, textSec, ringTrack, counterBg, arrowBg, border, progressBg, textPrimary;
  final VoidCallback onTap, onPrev, onNext;
  final ValueChanged<int> onDotTap;
  final String Function(String, String) t;

  const _InteractionZone({
    required this.zikr, required this.count, required this.zikrIdx,
    required this.zikrCount, required this.dark, required this.arabic,
    required this.teal, required this.textSec, required this.ringTrack,
    required this.counterBg, required this.arrowBg, required this.border,
    required this.progressBg, required this.textPrimary,
    required this.onTap, required this.onPrev, required this.onNext,
    required this.onDotTap, required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final canPrev = zikrIdx > 0;
    final canNext = zikrIdx < zikrCount - 1;

    return Padding(
      // top: 8 (tighter), bottom: 20 (was 16→reduced to pull zone up)
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prev / Ring / Next row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ArrowBtn(
                icon: arabic ? Icons.chevron_right : Icons.chevron_left,
                active: canPrev,
                bg: arrowBg, border: border,
                color: canPrev ? textSec : progressBg,
                onTap: canPrev ? onPrev : null,
              ),
              const SizedBox(width: 28),

              // Arc ring counter
              GestureDetector(
                onTap: onTap,
                child: SizedBox(
                  width: 148, height: 148,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(148, 148),
                        painter: _ArcRingPainter(
                          progress: zikr.repeat > 0 ? count / zikr.repeat : 0,
                          teal: teal,
                          track: ringTrack,
                        ),
                      ),
                      Container(
                        width: 112, height: 112,
                        decoration: BoxDecoration(
                          color: counterBg,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(dark ? 0.4 : 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 42, fontWeight: FontWeight.w200,
                                color: textPrimary, height: 1.0, letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '/ ${zikr.repeat}',
                              style: TextStyle(fontSize: 12, color: textSec),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 28),
              _ArrowBtn(
                icon: arabic ? Icons.chevron_left : Icons.chevron_right,
                active: canNext,
                bg: arrowBg, border: border,
                color: canNext ? textSec : progressBg,
                onTap: canNext ? onNext : null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Animated pill dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(zikrCount, (i) {
              final active = i == zikrIdx;
              return GestureDetector(
                onTap: () => onDotTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: active ? teal : progressBg,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          Text(
            t('TAP TO COUNT', 'اضغط للعد'),
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              letterSpacing: 1.4, color: textSec,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Arrow button
// ─────────────────────────────────────────────
class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color bg, border, color;
  final VoidCallback? onTap;

  const _ArrowBtn({
    required this.icon, required this.active,
    required this.bg, required this.border,
    required this.color, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.5),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Arc Ring Painter
// ─────────────────────────────────────────────
class _ArcRingPainter extends CustomPainter {
  final double progress;
  final Color teal, track;

  const _ArcRingPainter({required this.progress, required this.teal, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 7.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.width - strokeW * 2) / 2;

    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = strokeW,
    );

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..color = teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) =>
      old.progress != progress || old.teal != teal || old.track != track;
}

// ─────────────────────────────────────────────
// Ornamental Divider
// ─────────────────────────────────────────────
class _OrnamentalDivider extends StatelessWidget {
  final Color lineColor, dotColor;
  const _OrnamentalDivider({required this.lineColor, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        children: [
          Expanded(child: _GradLine(toRight: true,  color: lineColor)),
          const SizedBox(width: 10),
          CustomPaint(size: const Size(14, 14), painter: _StarDot(color: dotColor)),
          const SizedBox(width: 10),
          Expanded(child: _GradLine(toRight: false, color: lineColor)),
        ],
      ),
    );
  }
}

class _GradLine extends StatelessWidget {
  final bool toRight;
  final Color color;
  const _GradLine({required this.toRight, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: toRight ? Alignment.centerLeft  : Alignment.centerRight,
          end:   toRight ? Alignment.centerRight : Alignment.centerLeft,
          colors: [Colors.transparent, color],
        ),
      ),
    );
  }
}

class _StarDot extends CustomPainter {
  final Color color;
  const _StarDot({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 14;
    final path = Path()
      ..moveTo(7 * s,   1 * s)
      ..lineTo(8.2 * s, 5.8 * s)
      ..lineTo(13 * s,  7 * s)
      ..lineTo(8.2 * s, 8.2 * s)
      ..lineTo(7 * s,   13 * s)
      ..lineTo(5.8 * s, 8.2 * s)
      ..lineTo(1 * s,   7 * s)
      ..lineTo(5.8 * s, 5.8 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_StarDot old) => old.color != color;
}
