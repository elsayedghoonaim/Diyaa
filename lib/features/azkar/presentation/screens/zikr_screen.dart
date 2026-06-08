import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diyaa_app/core/utils/arabic_utils.dart' as ar;
import 'package:diyaa_app/core/services/share_service.dart';
import 'package:diyaa_app/theme/app_colors.dart';
import 'package:diyaa_app/shared/widgets/islamic_pattern.dart';
import '../widgets/zikr_share_card.dart';
import '../../../settings/data/models/settings_model.dart';
import '../../../settings/presentation/manager/settings_cubit.dart';
import '../../../settings/presentation/manager/settings_state.dart';
import '../../../progress/presentation/manager/progress_cubit.dart';
import '../../../prayer_times/presentation/manager/prayer_times_cubit.dart';
import '../../../progress/presentation/screens/celebration_screen.dart';
import '../../domain/entities/zikr.dart';
import '../../data/repo/azkar_repository.dart';
import '../manager/azkar_state.dart';
import '../manager/zikr_cubit.dart';

String _getEnglishCategoryName(String arName) {
  final String normalized = arName
      .trim()
      .replaceAll('\u064B', '')
      .replaceAll('\u064C', '')
      .replaceAll('\u064D', '')
      .replaceAll('\u064E', '')
      .replaceAll('\u064F', '')
      .replaceAll('\u0650', '')
      .replaceAll('\u0651', '')
      .replaceAll('\u0652', '');
  final Map<String, String> map = {
    'أذكار الصباح والمساء': 'Morning & Evening Azkar',
    'أذكار الصباح': 'Morning Azkar',
    'أذكار المساء': 'Evening Azkar',
    'أذكار النوم': 'Sleep Azkar',
    'أذكار الاستيقاظ من النوم': 'Waking Up Azkar',
    'أذكار الاستيقاظ': 'Waking Up Azkar',
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
    'دعاء لبس الثوب': 'Wearing Clothes',
    'دعاء لبس الثوب الجديد': 'Wearing New Clothes',
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
    'أذكار بعد السلام من الصلاة المفروضة': 'Azkar after Obligatory Prayer',
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
    'الدعاء إذا تقلب ليلا': 'Turning Over During the Night',
    'دعاء الفزع في النوم و من بلي بالوحشة': 'Anxiety During Sleep',
    'ما يفعل من رأى الرؤيا أو الحلم': 'Seeing a Dream',
    'دعاء قنوت الوتر': 'Qunut in Witr Prayer',
    'الذكر عقب السلام من الوتر': 'Remembrance After Witr',
    'دعاء من أصابه وسوسة في الإيمان': 'Doubt in Faith',
    'دعاء الوسوسة في الصلاة و القراءة': 'Distraction During Prayer',
    'ما يقول ويفعل من أذنب ذنبا': 'If You Commit a Sin',
    'الدعاء حينما يقع ما لا يرضاه أو غلب على أمره':
        'When Something Disliked Happens',
    'تهنئة المولود له وجوابه': 'Congratulating for a Newborn',
    'ما يعوذ به الأولاد': 'Seeking Protection for Children',
    'فضل عيادة المريض': 'Excellence of Visiting the Sick',
    'دعاء المريض الذي يئس من حياته': 'Sick person nearing death',
    'تلقين المحتضر': 'Prompting the Dying',
    'دعاء من أصيب بمصيبة': 'In Times of Calamity',
    'الدعاء عند إغماض الميت': 'Closing the Eyes of the Deceased',
    'الدعاء للميت في الصلاة عليه': 'Supplication for the Deceased',
    'الدعاء للفرط in الصلاة عليه': 'Supplication for a Child',
    'الدعاء عند إدخل الميت القبر': 'Placing the Deceased in the Grave',
    'دعاء السفر': 'Travel Supplication',
    'دعاء دخول السوق': 'Entering the Market',
    'دعاء الركوب': 'Riding Supplication',
    'ذكر الرجوع من السفر': 'Returning from Travel',
    'دعاء المسافر للمقيم': 'Traveler to the Resident',
    'دعاء المقيم للمسافر': 'Resident to the Traveler',
    'دعاء رؤية الهلال': 'Sighting the Crescent',
    'الدعاء عند إفطار الصائم': 'Breaking the Fast',
    'دعاء الضيف لصاحب الطعام': 'Guest to the Host',
    'كفارة المجلس': 'Expiation of a Meeting',
    'الدعاء لمن قال بارك الله فيك': 'To someone who says Baraka Allahu Fik',
    'ما يقوله المسلم إذا زكي': 'If a Muslim is praised',
    'تلبية الحج أو العمرة': 'Talbiyah for Hajj or Umrah',
  };
  if (map.containsKey(normalized)) return map[normalized]!;
  if (normalized.contains('الصباح')) return 'Morning Azkar';
  if (normalized.contains('المساء')) return 'Evening Azkar';
  if (normalized.contains('النوم')) return 'Sleep Azkar';
  if (normalized.contains('الوضوء')) return 'Wudu Supplication';
  if (normalized.contains('المسجد')) return 'Mosque Supplication';
  return 'Hisn al-Muslim';
}

double _getStandardArabicFontSize(String preference) {
  switch (preference) {
    case 'small':
      return 22.0;
    case 'big':
      return 36.0;
    case 'medium':
    default:
      return 28.0;
  }
}

class ZikrScreen extends StatelessWidget {
  final String sessionId;

  const ZikrScreen({super.key, this.sessionId = '1'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ZikrCubit>(
      create: (context) =>
          ZikrCubit(repository: context.read<AzkarRepository>()),
      child: _ZikrScreenContent(sessionId: sessionId),
    );
  }
}

class _ZikrScreenContent extends StatefulWidget {
  final String sessionId;

  const _ZikrScreenContent({required this.sessionId});

  @override
  State<_ZikrScreenContent> createState() => _ZikrScreenContentState();
}

class _ZikrScreenContentState extends State<_ZikrScreenContent> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    final prayerInfo = context.read<PrayerTimesCubit>().currentPrayerInfo;
    context.read<ZikrCubit>().loadSession(
      widget.sessionId,
      prayerInfo: prayerInfo,
    );
  }

  void _shareZikr(
    BuildContext context,
    AzkarSession session,
    int zikrIdx,
    SettingsModel settings,
  ) {
    final dark = settings.darkMode;
    final arabic = settings.arabicMode;
    final zikr = session.zikrs[zikrIdx];
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final textPrimary = dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSec = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    bool isCardDark = dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: dark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: (dark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  arabic ? 'مشاركة الذكر' : 'Share this Zikr',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF161B22)
                        : const Color(0xFFF0EFEA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              isCardDark = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isCardDark
                                  ? (dark
                                        ? const Color(0xFF2D3238)
                                        : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !isCardDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: dark ? 0.2 : 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.wb_sunny_outlined,
                                  size: 16,
                                  color: !isCardDark
                                      ? (dark
                                            ? const Color(0xFFE8E4DD)
                                            : const Color(0xFF2C302E))
                                      : textSec,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  arabic ? 'بطاقة فاتحة' : 'Light Card',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: !isCardDark
                                        ? (dark
                                              ? const Color(0xFFE8E4DD)
                                              : const Color(0xFF2C302E))
                                        : textSec,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              isCardDark = true;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isCardDark
                                  ? (dark
                                        ? const Color(0xFF080A10)
                                        : const Color(0xFF1E2638))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isCardDark
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: dark ? 0.3 : 0.15,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.nightlight_round_outlined,
                                  size: 16,
                                  color: isCardDark
                                      ? const Color(0xFFF0EDE6)
                                      : textSec,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  arabic ? 'بطاقة داكنة' : 'Dark Card',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isCardDark
                                        ? const Color(0xFFF0EDE6)
                                        : textSec,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _ShareOptionTile(
                  icon: Icons.text_fields_rounded,
                  color: teal,
                  label: arabic ? 'مشاركة كنص' : 'Share as Text',
                  sublabel: arabic
                      ? 'نص عربي منسق مع المصدر'
                      : 'Formatted Arabic text with source',
                  dark: dark,
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    await ShareService.shareAsText(
                      arabicText: zikr.arabic,
                      repeatCount: zikr.repeat,
                      categoryAr: session.nameAr,
                      isArabic: arabic,
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ShareOptionTile(
                  icon: Icons.image_outlined,
                  color: gold,
                  label: arabic ? 'مشاركة كصورة' : 'Share as Image',
                  sublabel: arabic
                      ? 'بطاقة جميلة جاهزة للنشر'
                      : 'Beautiful branded card image',
                  dark: dark,
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    _captureAndShareImage(
                      context,
                      session,
                      zikr,
                      arabic,
                      isCardDark,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _captureAndShareImage(
    BuildContext context,
    AzkarSession session,
    Zikr zikr,
    bool arabic,
    bool isCardDark,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: -10000,
        child: RepaintBoundary(
          key: _shareCardKey,
          child: ZikrShareCard(
            arabicText: zikr.arabic,
            repeatCount: zikr.repeat,
            categoryAr: session.nameAr,
            categoryEn: _getEnglishCategoryName(session.nameAr),
            isArabic: arabic,
            isDark: isCardDark,
          ),
        ),
      ),
    );
    overlay.insert(entry);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!context.mounted) return;

      final File? file = await ShareService.captureAsFile(_shareCardKey);
      entry.remove();

      if (file != null) {
        await ShareService.shareImageFile(file);
      }
    });
  }

  double _fontSizeToValue(String size) {
    switch (size) {
      case 'small':
        return 0.0;
      case 'big':
        return 2.0;
      case 'medium':
      default:
        return 1.0;
    }
  }

  String _valueToFontSize(double value) {
    if (value < 0.5) return 'small';
    if (value > 1.5) return 'big';
    return 'medium';
  }

  void _showFontSizeSheet(BuildContext context, SettingsModel settings) {
    final dark = settings.darkMode;
    final arabic = settings.arabicMode;
    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final textPrimary = dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSec = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final border = dark ? AppColors.borderZikrDark : AppColors.borderZikrLight;
    final progressBg = dark
        ? AppColors.progressBgZikrDark
        : AppColors.progressBgZikrLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            final currentSettings = settingsState is SettingsLoaded
                ? settingsState.settings
                : settings;
            final activeSize = currentSettings.zikrFontSize;
            final sliderVal = _fontSizeToValue(activeSize);

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: dark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: (dark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    arabic ? 'حجم الخط' : 'Font Size',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF161B22)
                          : const Color(0xFFFBFBFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ضِيَاء · Diyaa',
                          style: GoogleFonts.amiri(
                            fontSize: _getStandardArabicFontSize(activeSize),
                            color: gold,
                            height: 1.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          arabic
                              ? 'معاينة حجم الخط المباشر'
                              : 'Live font size preview',
                          style: TextStyle(fontSize: 12, color: textSec),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: teal,
                      inactiveTrackColor: progressBg,
                      thumbColor: gold,
                      overlayColor: gold.withValues(alpha: 0.12),
                      activeTickMarkColor: Colors.transparent,
                      inactiveTickMarkColor: Colors.transparent,
                      trackHeight: 6.0,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 20.0,
                      ),
                    ),
                    child: Slider(
                      value: sliderVal,
                      min: 0.0,
                      max: 2.0,
                      divisions: 2,
                      onChanged: (double value) {
                        final size = _valueToFontSize(value);
                        context.read<SettingsCubit>().setZikrFontSize(size);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFontSizeLabel(
                          label: arabic ? 'صغير' : 'Small',
                          isActive: activeSize == 'small',
                          activeColor: gold,
                          inactiveColor: textSec,
                          onTap: () => context
                              .read<SettingsCubit>()
                              .setZikrFontSize('small'),
                        ),
                        _buildFontSizeLabel(
                          label: arabic ? 'وسط' : 'Medium',
                          isActive: activeSize == 'medium',
                          activeColor: gold,
                          inactiveColor: textSec,
                          onTap: () => context
                              .read<SettingsCubit>()
                              .setZikrFontSize('medium'),
                        ),
                        _buildFontSizeLabel(
                          label: arabic ? 'كبير' : 'Large',
                          isActive: activeSize == 'big',
                          activeColor: gold,
                          inactiveColor: textSec,
                          onTap: () => context
                              .read<SettingsCubit>()
                              .setZikrFontSize('big'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFontSizeLabel({
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? activeColor : inactiveColor,
        ),
      ),
    );
  }

  void _increment(SettingsModel settings, ZikrActive activeState) {
    if (_isAdvancing) return;
    final zikr = activeState.session.zikrs[activeState.currentIndex];
    final count = activeState.counts[activeState.currentIndex];
    if (count >= zikr.repeat) return;
    if (settings.soundEnabled) {
      HapticFeedback.lightImpact();
    }
    if (count + 1 >= zikr.repeat) {
      _isAdvancing = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _isAdvancing = false;
        }
      });
      if (settings.soundEnabled) {
        HapticFeedback.mediumImpact();
      }
    }
    context.read<ZikrCubit>().tap();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    if (settingsState is! SettingsLoaded) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final settings = settingsState.settings;
    final dark = settings.darkMode;
    final arabic = settings.arabicMode;

    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final textPrimary = dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSec = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final border = dark ? AppColors.borderZikrDark : AppColors.borderZikrLight;
    final progressBg = dark
        ? AppColors.progressBgZikrDark
        : AppColors.progressBgZikrLight;
    final ringTrack = dark ? AppColors.ringTrackDark : AppColors.ringTrackLight;
    final counterBg = dark ? AppColors.counterBgDark : AppColors.counterBgLight;
    final arrowBg = dark ? AppColors.arrowBgDark : AppColors.arrowBgLight;

    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: BlocListener<ZikrCubit, ZikrState>(
        listener: (context, state) {
          if (state is ZikrCompleted) {
            context.read<ProgressCubit>().completeSession(state.session.id);
            final sessionNameEn = _getEnglishCategoryName(state.session.nameAr);
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    CelebrationScreen(
                      sessionId: state.session.id,
                      sessionNameAr: state.session.nameAr,
                      sessionNameEn: sessionNameEn,
                      zikrCount: state.session.zikrs.length,
                    ),
                transitionsBuilder: (context, anim, secondaryAnim, child) {
                  return FadeTransition(opacity: anim, child: child);
                },
                transitionDuration: const Duration(milliseconds: 400),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: bg,
          body: Stack(
            children: [
              const IslamicPatternOverlay(lightOpacity: 0.07),
              SafeArea(
                child: BlocBuilder<ZikrCubit, ZikrState>(
                  builder: (context, state) {
                    if (state is ZikrLoading || state is ZikrInitial) {
                      return Center(
                        child: CircularProgressIndicator(color: teal),
                      );
                    }
                    if (state is ZikrError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyle(color: textPrimary, fontSize: 16),
                        ),
                      );
                    }
                    if (state is ZikrActive) {
                      final session = state.session;
                      final currentIndex = state.currentIndex;
                      final counts = state.counts;
                      final sessionNameAr = session.nameAr;
                      final sessionNameEn = _getEnglishCategoryName(
                        sessionNameAr,
                      );
                      final zikrCount = session.zikrs.length;
                      final zikr = session.zikrs[currentIndex];

                      return Column(
                        children: [
                          _Header(
                            arabic: arabic,
                            textSec: textSec,
                            teal: teal,
                            gold: gold,
                            nameAr: sessionNameAr,
                            nameEn: !arabic ? sessionNameEn : '',
                            onBack: () => Navigator.of(context).pop(),
                            onShare: () => _shareZikr(
                              context,
                              session,
                              currentIndex,
                              settings,
                            ),
                            onFontSizeTap: () =>
                                _showFontSizeSheet(context, settings),
                          ),
                          const SizedBox(height: 12),
                          _ProgressBar(
                            zikrIdx: currentIndex,
                            sessionTotal: zikrCount,
                            sessionCurrent: currentIndex,
                            teal: teal,
                            progressBg: progressBg,
                            textSec: textSec,
                            arabic: arabic,
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: IntrinsicHeight(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _ZikrContent(
                                            zikr: zikr,
                                            sessionNameEn:
                                                _getEnglishCategoryName(
                                                  sessionNameAr,
                                                ),
                                            dark: dark,
                                            arabic: arabic,
                                            teal: teal,
                                            gold: gold,
                                            border: border,
                                            textPrimary: textPrimary,
                                            textSec: textSec,
                                            fontSizePreference:
                                                settings.zikrFontSize,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          _InteractionZone(
                            zikr: zikr,
                            count: counts.isNotEmpty ? counts[currentIndex] : 0,
                            zikrIdx: currentIndex,
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
                            onTap: () => _increment(settings, state),
                            onPrev: () =>
                                context.read<ZikrCubit>().goToPrevious(),
                            onNext: () => context.read<ZikrCubit>().goToNext(),
                            onDotTap: (int i) =>
                                context.read<ZikrCubit>().goToIndex(i),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool arabic;
  final Color textSec;
  final Color teal;
  final Color gold;
  final String nameAr;
  final String nameEn;
  final VoidCallback onBack;
  final VoidCallback? onShare;
  final VoidCallback? onFontSizeTap;

  const _Header({
    required this.arabic,
    required this.textSec,
    required this.teal,
    required this.gold,
    required this.nameAr,
    required this.nameEn,
    required this.onBack,
    this.onShare,
    this.onFontSizeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.chevron_left, size: 26, color: textSec),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    nameAr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 24,
                      color: gold,
                      height: 1.2,
                    ),
                  ),
                  if (!arabic)
                    Text(
                      nameEn,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSec,
                        letterSpacing: 0.04,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onFontSizeTap != null)
                    GestureDetector(
                      onTap: onFontSizeTap,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.format_size_rounded,
                          size: 22,
                          color: textSec,
                        ),
                      ),
                    ),
                  if (onShare != null)
                    GestureDetector(
                      onTap: onShare,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.ios_share_rounded,
                          size: 22,
                          color: textSec,
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

class _ProgressBar extends StatelessWidget {
  final int zikrIdx;
  final int sessionTotal;
  final int sessionCurrent;
  final Color teal;
  final Color progressBg;
  final Color textSec;
  final bool arabic;

  const _ProgressBar({
    required this.zikrIdx,
    required this.sessionTotal,
    required this.sessionCurrent,
    required this.teal,
    required this.progressBg,
    required this.textSec,
    required this.arabic,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = sessionTotal > 0
        ? sessionCurrent / sessionTotal
        : 0.0;
    final String countLabel = ar.localise(
      'Zikr ${zikrIdx + 1} of $sessionTotal',
      'الذكر ${ar.toArabicDigits((zikrIdx + 1).toString(), isArabic: true)} من ${ar.toArabicDigits(sessionTotal.toString(), isArabic: true)}',
      isArabic: arabic,
    );
    final String progressRatio = ar.toArabicDigits(
      '$sessionCurrent/$sessionTotal',
      isArabic: arabic,
    );

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
                countLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textSec,
                ),
              ),
              Text(
                progressRatio,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZikrContent extends StatelessWidget {
  final Zikr zikr;
  final String sessionNameEn;
  final bool dark;
  final bool arabic;
  final Color teal;
  final Color gold;
  final Color border;
  final Color textPrimary;
  final Color textSec;
  final String fontSizePreference;

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
    required this.fontSizePreference,
  });

  @override
  Widget build(BuildContext context) {
    final sourceBg = dark
        ? const Color(0xFF4DB6AC).withValues(alpha: 0.10)
        : const Color(0xFF0B6E6E).withValues(alpha: 0.06);
    final repeatBorderColor = dark
        ? const Color(0xFFB8973A).withValues(alpha: 0.25)
        : const Color(0xFFB8973A).withValues(alpha: 0.30);
    final repeatBg = dark
        ? const Color(0xFFD4A84B).withValues(alpha: 0.07)
        : const Color(0xFFB8973A).withValues(alpha: 0.06);
    final repeatCountText = ar.localise(
      'Repeat ${zikr.repeat}×',
      'كرر ${ar.toArabicDigits(zikr.repeat.toString(), isArabic: true)} مرة',
      isArabic: arabic,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Text(
            zikr.arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              fontSize: _getStandardArabicFontSize(fontSizePreference),
              color: gold,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          _OrnamentalDivider(lineColor: border, dotColor: gold),
          const SizedBox(height: 16),
          if (zikr.description.isNotEmpty) ...[
            Text(
              zikr.description,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 14,
                color: textPrimary.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            decoration: BoxDecoration(
              color: repeatBg,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: repeatBorderColor, width: 1),
            ),
            child: Text(
              repeatCountText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: gold,
                letterSpacing: 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionZone extends StatelessWidget {
  final Zikr zikr;
  final int count;
  final int zikrIdx;
  final int zikrCount;
  final bool dark;
  final bool arabic;
  final Color teal;
  final Color textSec;
  final Color ringTrack;
  final Color counterBg;
  final Color arrowBg;
  final Color border;
  final Color progressBg;
  final Color textPrimary;
  final VoidCallback onTap;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onDotTap;

  const _InteractionZone({
    required this.zikr,
    required this.count,
    required this.zikrIdx,
    required this.zikrCount,
    required this.dark,
    required this.arabic,
    required this.teal,
    required this.textSec,
    required this.ringTrack,
    required this.counterBg,
    required this.arrowBg,
    required this.border,
    required this.progressBg,
    required this.textPrimary,
    required this.onTap,
    required this.onPrev,
    required this.onNext,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPrev = zikrIdx > 0;
    final bool canNext = zikrIdx < zikrCount - 1;
    final String tapLabel = ar.localise(
      'TAP TO COUNT',
      'اضغط للعد',
      isArabic: arabic,
    );
    final String currentCountLabel = ar.toArabicDigits(
      '$count',
      isArabic: arabic,
    );
    final String totalCountLabel = ar.toArabicDigits(
      '/ ${zikr.repeat}',
      isArabic: arabic,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ArrowBtn(
                  icon: Icons.chevron_left,
                  active: canPrev,
                  bg: arrowBg,
                  border: border,
                  color: canPrev ? textSec : progressBg,
                  onTap: canPrev ? onPrev : null,
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: onTap,
                  child: SizedBox(
                    width: 156,
                    height: 156,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(156, 156),
                          painter: _ArcRingPainter(
                            progress: zikr.repeat > 0 ? count / zikr.repeat : 0,
                            teal: teal,
                            track: ringTrack,
                          ),
                        ),
                        Container(
                          width: 124,
                          height: 124,
                          decoration: BoxDecoration(
                            color: counterBg,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: dark ? 0.4 : 0.08,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentCountLabel,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w200,
                                  color: textPrimary,
                                  height: 1.0,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                totalCountLabel,
                                style: TextStyle(fontSize: 12, color: textSec),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _ArrowBtn(
                  icon: Icons.chevron_right,
                  active: canNext,
                  bg: arrowBg,
                  border: border,
                  color: canNext ? textSec : progressBg,
                  onTap: canNext ? onNext : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(zikrCount, (int i) {
                final bool active = i == zikrIdx;
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
              tapLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
                color: textSec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color bg;
  final Color border;
  final Color color;
  final VoidCallback? onTap;

  const _ArrowBtn({
    required this.icon,
    required this.active,
    required this.bg,
    required this.border,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.5),
        ),
        child: Icon(icon, size: 26, color: color),
      ),
    );
  }
}

class _ArcRingPainter extends CustomPainter {
  final double progress;
  final Color teal;
  final Color track;

  const _ArcRingPainter({
    required this.progress,
    required this.teal,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 7.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - strokeW * 2) / 2;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
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

class _OrnamentalDivider extends StatelessWidget {
  final Color lineColor;
  final Color dotColor;

  const _OrnamentalDivider({required this.lineColor, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        children: [
          Expanded(child: _GradLine(toRight: true, color: lineColor)),
          const SizedBox(width: 10),
          CustomPaint(
            size: const Size(14, 14),
            painter: _StarDot(color: dotColor),
          ),
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
          begin: toRight ? Alignment.centerLeft : Alignment.centerRight,
          end: toRight ? Alignment.centerRight : Alignment.centerLeft,
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
      ..moveTo(7 * s, 1 * s)
      ..lineTo(8.2 * s, 5.8 * s)
      ..lineTo(13 * s, 7 * s)
      ..lineTo(8.2 * s, 8.2 * s)
      ..lineTo(7 * s, 13 * s)
      ..lineTo(5.8 * s, 8.2 * s)
      ..lineTo(1 * s, 7 * s)
      ..lineTo(5.8 * s, 5.8 * s)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_StarDot old) => old.color != color;
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sublabel;
  final bool dark;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.sublabel,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final borderCol = dark ? AppColors.borderDark : AppColors.borderLight;
    final textPri = dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSec = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPri,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 12, color: textSec),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: textSec),
          ],
        ),
      ),
    );
  }
}
