import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/arabic_utils.dart' as ar;
import '../../../../features/settings/presentation/manager/settings_cubit.dart';
import '../../../../features/settings/presentation/manager/settings_state.dart';
import '../../../../features/progress/presentation/manager/progress_cubit.dart';
import '../../../../features/progress/presentation/manager/progress_state.dart';
import 'package:diyaa_app/theme/app_colors.dart';
import 'package:diyaa_app/shared/widgets/islamic_pattern.dart';
import 'package:diyaa_app/shared/widgets/gem_badge.dart';
import 'package:diyaa_app/shared/widgets/error_fallback.dart';

class _ThemeItem {
  final String id;
  final String nameEn, nameAr;
  final int cost;
  final List<Color> colors;

  const _ThemeItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.cost,
    required this.colors,
  });
}

class _AudioItem {
  final String id;
  final String nameEn, nameAr;
  final String descEn, descAr;
  final int cost;

  const _AudioItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descEn,
    required this.descAr,
    required this.cost,
  });
}

const List<_ThemeItem> _themes = <_ThemeItem>[
  _ThemeItem(id: 'desert_dunes', nameEn: 'Desert Dunes', nameAr: 'كثبان الصحراء', cost: 800, colors: <Color>[Color(0xFFC4A35A), Color(0xFFE8C97A), Color(0xFF8B6914)]),
  _ThemeItem(id: 'medina_night', nameEn: 'Medina Night', nameAr: 'ليل المدينة', cost: 1200, colors: <Color>[Color(0xFF0B2545), Color(0xFF1A4A6E), Color(0xFF4DB6AC)]),
  _ThemeItem(id: 'emerald_oasis', nameEn: 'Emerald Oasis', nameAr: 'واحة الزمرد', cost: 1500, colors: <Color>[Color(0xFF0D3B2E), Color(0xFF1B6B4A), Color(0xFFA3D9A5)]),
  _ThemeItem(id: 'rose_ivory', nameEn: 'Rose Ivory', nameAr: 'عاج وردي', cost: 600, colors: <Color>[Color(0xFFF5E6E8), Color(0xFFD4A0A8), Color(0xFF8B3A4A)]),
];

const List<_AudioItem> _audios = <_AudioItem>[
  _AudioItem(id: 'prayer_bell', nameEn: 'Prayer Bell', nameAr: 'جرس الصلاة', descEn: 'Soft, traditional chime', descAr: 'رنين تقليدي هادئ', cost: 0),
  _AudioItem(id: 'crystal_chime', nameEn: 'Crystal Chime', nameAr: 'رنين الكريستال', descEn: 'Clear, echoing notification', descAr: 'إشعار بصدى واضح', cost: 200),
  _AudioItem(id: 'soft_reminder', nameEn: 'Soft Reminder', nameAr: 'تذكير لطيف', descEn: 'Gentle, non-intrusive sound', descAr: 'صوت لطيف غير مزعج', cost: 200),
];

class RewardsShopScreen extends StatefulWidget {
  const RewardsShopScreen({super.key});

  @override
  State<RewardsShopScreen> createState() => _RewardsShopScreenState();
}

class _RewardsShopScreenState extends State<RewardsShopScreen> {
  int _activeTab = 0; // 0: Themes, 1: Audio

  @override
  Widget build(BuildContext context) {
    final SettingsState settingsState = context.watch<SettingsCubit>().state;
    final ProgressState progressState = context.watch<ProgressCubit>().state;
    if (settingsState is SettingsError || progressState is ProgressError) {
      final String msg = settingsState is SettingsError
          ? settingsState.message
          : (progressState as ProgressError).message;
      final bool isArabic = settingsState is SettingsLoaded
          ? settingsState.settings.arabicMode
          : false;
      return ErrorFallback(
        message: msg,
        isArabic: isArabic,
        onRetry: () {
          if (settingsState is SettingsError) {
            context.read<SettingsCubit>().loadSettings();
          }
          if (progressState is ProgressError) {
            context.read<ProgressCubit>().loadProgress();
          }
        },
      );
    }
    if (settingsState is! SettingsLoaded || progressState is! ProgressLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool dark = settingsState.settings.darkMode;
    final bool arabic = settingsState.settings.arabicMode;
    final int points = progressState.progress.totalPoints;
    final Color bg = dark ? AppColors.bgDark : AppColors.bgLight;

    String t(String en, String arVal) => ar.localise(en, arVal, isArabic: arabic);

    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: <Widget>[
            const IslamicPatternOverlay(),
            SafeArea(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: _buildHeader(points, dark, arabic, t),
                  ),
                  SliverToBoxAdapter(
                    child: _buildFeaturedPack(dark, arabic, t),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: _buildCategoryTabs(dark, arabic, t),
                    ),
                  ),
                  if (_activeTab == 0)
                    _buildThemesGrid(dark, arabic, t)
                  else
                    _buildAudioList(dark, arabic, t),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
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
    int points,
    bool dark,
    bool arabic,
    String Function(String, String) t,
  ) {
    final Color gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final Color secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'المتجر',
                style: GoogleFonts.amiri(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: gold,
                ),
              ),
              if (!arabic)
                Text(
                  'Rewards Shop',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: secondary,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                t('Your balance', 'رصيدك الحالي'),
                style: TextStyle(
                  fontSize: 10,
                  color: secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              GemBadge(value: points),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPack(
    bool dark,
    bool arabic,
    String Function(String, String) t,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0B2545), Color(0xFF1A4A6E), Color(0xFF0B6E6E)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          t('✦ FEATURED PACK', '✦ باقة مميزة'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9ECFDA),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t('Ramadan Pack', 'باقة رمضان'),
                          style: arabic
                              ? GoogleFonts.amiri(fontSize: 24, color: const Color(0xFFF5D78A))
                              : const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF5D78A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t('Theme · Sounds · Special Azkar', 'سمة · أصوات · أذكار مخصصة'),
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A84B),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            t('Coming Soon', 'قريباً'),
                            style: const TextStyle(
                              color: Color(0xFF1A1A2E),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.nights_stay_outlined, size: 64, color: Color(0xFFF5D78A)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(
    bool dark,
    bool arabic,
    String Function(String, String) t,
  ) {
    final Color tabBg = dark ? const Color(0xFF1E2530) : const Color(0xFFF0EDE6);
    final Color cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final Color teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final Color secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tabBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          _buildTab(0, t('Themes', 'السمات'), cardBg, teal, secondary),
          _buildTab(1, t('Audio', 'الصوتيات'), cardBg, teal, secondary),
        ],
      ),
    );
  }

  Widget _buildTab(
    int index,
    String title,
    Color cardBg,
    Color teal,
    Color secondary,
  ) {
    final bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? teal : secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemesGrid(
    bool dark,
    bool arabic,
    String Function(String, String) t,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final _ThemeItem theme = _themes[index];
            return _ThemeCard(theme: theme, dark: dark, arabic: arabic, t: t);
          },
          childCount: _themes.length,
        ),
      ),
    );
  }

  Widget _buildAudioList(
    bool dark,
    bool arabic,
    String Function(String, String) t,
  ) {
    final Color secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (index == _audios.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border.fromBorderSide(BorderSide.none),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.star_rounded, size: 16, color: secondary.withValues(alpha: 0.5)),
                        const SizedBox(width: 8),
                        Text(
                          t('Complete daily Azkar to earn more gems', 'أكمل الأذكار اليومية لكسب المزيد من الجواهر'),
                          style: TextStyle(fontSize: 12, color: secondary.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final _AudioItem audio = _audios[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AudioCard(audio: audio, dark: dark, arabic: arabic, t: t),
            );
          },
          childCount: _audios.length + 1,
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final _ThemeItem theme;
  final bool dark;
  final bool arabic;
  final String Function(String, String) t;

  const _ThemeCard({
    required this.theme,
    required this.dark,
    required this.arabic,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final Color textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final Color border = dark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.colors,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      arabic ? theme.nameAr : theme.nameEn,
                      style: arabic
                          ? GoogleFonts.amiri(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            )
                          : TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('Coming Soon', 'قريباً'),
                    style: TextStyle(
                      fontSize: 11,
                      color: teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioCard extends StatelessWidget {
  final _AudioItem audio;
  final bool dark;
  final bool arabic;
  final String Function(String, String) t;

  const _AudioCard({
    required this.audio,
    required this.dark,
    required this.arabic,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final Color textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final Color border = dark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E2530) : const Color(0xFFF0EDE6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  arabic ? audio.nameAr : audio.nameEn,
                  style: arabic
                      ? GoogleFonts.amiri(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        )
                      : TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  arabic ? audio.descAr : audio.descEn,
                  style: TextStyle(fontSize: 12, color: secondary.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.accentGoldLight.withValues(alpha: 0.3)),
            ),
            child: Text(
              t('Coming Soon', 'قريباً'),
              style: TextStyle(
                color: dark ? AppColors.accentGoldDark : AppColors.accentGoldLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
