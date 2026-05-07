import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/islamic_pattern.dart';
import '../widgets/shared/gem_badge.dart';

class _ThemeItem {
  final String id;
  final String nameEn, nameAr;
  final int cost;
  final List<Color> colors;

  const _ThemeItem({
    required this.id, required this.nameEn, required this.nameAr,
    required this.cost, required this.colors,
  });
}

class _AudioItem {
  final String id;
  final String nameEn, nameAr;
  final String descEn, descAr;
  final int cost;

  const _AudioItem({
    required this.id, required this.nameEn, required this.nameAr,
    required this.descEn, required this.descAr, required this.cost,
  });
}

const _themes = [
  _ThemeItem(id: 'desert_dunes', nameEn: 'Desert Dunes', nameAr: 'كثبان الصحراء', cost: 800, colors: [Color(0xFFC4A35A), Color(0xFFE8C97A), Color(0xFF8B6914)]),
  _ThemeItem(id: 'medina_night', nameEn: 'Medina Night', nameAr: 'ليل المدينة', cost: 1200, colors: [Color(0xFF0B2545), Color(0xFF1A4A6E), Color(0xFF4DB6AC)]),
  _ThemeItem(id: 'emerald_oasis', nameEn: 'Emerald Oasis', nameAr: 'واحة الزمرد', cost: 1500, colors: [Color(0xFF0D3B2E), Color(0xFF1B6B4A), Color(0xFFA3D9A5)]),
  _ThemeItem(id: 'rose_ivory', nameEn: 'Rose Ivory', nameAr: 'عاج وردي', cost: 600, colors: [Color(0xFFF5E6E8), Color(0xFFD4A0A8), Color(0xFF8B3A4A)]),
];

const _audios = [
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
    final provider = context.watch<AppProvider>();
    final dark     = provider.darkMode;
    final arabic   = provider.arabicMode;
    final bg       = dark ? AppColors.bgDark : AppColors.bgLight;

    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            const IslamicPatternOverlay(),
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(provider, dark, arabic)),
                  SliverToBoxAdapter(child: _buildFeaturedPack(provider, dark, arabic)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: _buildCategoryTabs(provider, dark, arabic),
                    ),
                  ),
                  if (_activeTab == 0) _buildThemesGrid(provider, dark, arabic)
                  else _buildAudioList(provider, dark, arabic),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppProvider provider, bool dark, bool arabic) {
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final pts = provider.totalPoints;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            children: [
              Text(
                provider.t('Your balance', 'رصيدك الحالي'),
                style: TextStyle(
                  fontSize: 10,
                  color: secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              GemBadge(value: pts),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPack(AppProvider provider, bool dark, bool arabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B2545), Color(0xFF1A4A6E), Color(0xFF0B6E6E)],
          ),
        ),
        child: Stack(
          children: [
            // Star dots overlay could go here
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.t('✦ FEATURED PACK', '✦ باقة مميزة'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9ECFDA),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          provider.t('Ramadan Pack', 'باقة رمضان'),
                          style: arabic
                              ? GoogleFonts.amiri(fontSize: 24, color: const Color(0xFFF5D78A))
                              : const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF5D78A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.t('Theme · Sounds · Special Azkar', 'سمة · أصوات · أذكار مخصصة'),
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A84B),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.t('Get it', 'احصل عليها'),
                                style: const TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('·', style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.diamond_outlined, size: 14, color: Color(0xFF1A1A2E)),
                              const SizedBox(width: 2),
                              const Text(
                                '2,400',
                                style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
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

  Widget _buildCategoryTabs(AppProvider provider, bool dark, bool arabic) {
    final tabBg = dark ? const Color(0xFF1E2530) : const Color(0xFFF0EDE6);
    final cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tabBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildTab(0, provider.t('Themes', 'السمات'), cardBg, teal, secondary),
          _buildTab(1, provider.t('Audio', 'الصوتيات'), cardBg, teal, secondary),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, Color cardBg, Color teal, Color secondary) {
    final isActive = _activeTab == index;
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
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
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

  Widget _buildThemesGrid(AppProvider provider, bool dark, bool arabic) {
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
          (context, i) {
            final theme = _themes[i];
            return _ThemeCard(theme: theme, provider: provider, dark: dark, arabic: arabic);
          },
          childCount: _themes.length,
        ),
      ),
    );
  }

  Widget _buildAudioList(AppProvider provider, bool dark, bool arabic) {
    final secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == _audios.length) {
              // Earn tip card at the bottom
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: secondary.withOpacity(0.3), style: BorderStyle.none),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: secondary.withOpacity(0.5)),
                        const SizedBox(width: 8),
                        Text(
                          provider.t('Complete daily Azkar to earn more gems', 'أكمل الأذكار اليومية لكسب المزيد من الجواهر'),
                          style: TextStyle(fontSize: 12, color: secondary.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final audio = _audios[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AudioCard(audio: audio, provider: provider, dark: dark, arabic: arabic),
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
  final AppProvider provider;
  final bool dark, arabic;

  const _ThemeCard({required this.theme, required this.provider, required this.dark, required this.arabic});

  @override
  Widget build(BuildContext context) {
    final cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;

    final isUnlocked = provider.unlockedThemes.contains(theme.id);
    final isActive = provider.activeTheme == theme.id;

    return GestureDetector(
      onTap: () async {
        if (isActive) return;
        if (isUnlocked) {
          await provider.applyTheme(theme.id);
        } else {
          final success = await provider.purchaseTheme(theme.id, theme.cost);
          if (!context.mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.t('Theme unlocked!', 'تم فتح السمة!'))));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.t('Not enough gems.', 'لا تملك جواهر كافية.'))));
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? teal : border, width: isActive ? 1.5 : 1.0),
        ),
        child: Column(
          children: [
            // Top Swatch
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
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: arabic ? 8 : null,
                    right: arabic ? null : 8,
                    child: isUnlocked
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: const Icon(Icons.check, size: 12, color: Colors.green),
                          )
                        : Container(),
                  ),
                  if (!isUnlocked)
                    Positioned(
                      bottom: 8,
                      left: arabic ? 8 : null,
                      right: arabic ? null : 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.diamond_outlined, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(theme.cost.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Bottom Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arabic ? theme.nameAr : theme.nameEn,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked 
                          ? (isActive ? provider.t('Active', 'مفعل') : provider.t('Unlocked', 'مفتوح')) 
                          : provider.t('Locked', 'مغلق'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? teal : secondary,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
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

class _AudioCard extends StatelessWidget {
  final _AudioItem audio;
  final AppProvider provider;
  final bool dark, arabic;

  const _AudioCard({required this.audio, required this.provider, required this.dark, required this.arabic});

  @override
  Widget build(BuildContext context) {
    final cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;

    final isUnlocked = provider.unlockedAudios.contains(audio.id);
    final isActive = provider.activeAudio == audio.id;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? teal.withOpacity(0.1) : (dark ? const Color(0xFF1E2530) : const Color(0xFFF0EDE6)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUnlocked ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
              color: isActive ? teal : secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabic ? audio.nameAr : audio.nameEn,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  arabic ? audio.descAr : audio.descEn,
                  style: TextStyle(fontSize: 12, color: secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () async {
              if (isActive) return;
              if (isUnlocked) {
                await provider.applyAudio(audio.id);
              } else {
                final success = await provider.purchaseAudio(audio.id, audio.cost);
                if (!context.mounted) return;
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.t('Audio unlocked!', 'تم فتح الصوت!'))));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.t('Not enough gems.', 'لا تملك جواهر كافية.'))));
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? teal : (isUnlocked ? Colors.transparent : AppColors.accentGoldLight.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isActive ? teal : (isUnlocked ? border : AppColors.accentGoldLight.withOpacity(0.3))),
              ),
              child: isActive 
                ? Text(provider.t('Active', 'مفعل'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
                : (isUnlocked 
                    ? Text(provider.t('Use', 'استخدم'), style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond_outlined, size: 12, color: dark ? AppColors.accentGoldDark : AppColors.accentGoldLight),
                          const SizedBox(width: 4),
                          Text(
                            audio.cost.toString(),
                            style: TextStyle(color: dark ? AppColors.accentGoldDark : AppColors.accentGoldLight, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
