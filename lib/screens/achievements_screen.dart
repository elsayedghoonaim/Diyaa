import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/shared/islamic_pattern.dart';
import '../widgets/shared/bottom_nav_bar.dart';
import 'main_screen.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<AppProvider>();
    final dark        = provider.darkMode;
    final arabic      = provider.arabicMode;

    final bg          = dark ? AppColors.bgDark          : AppColors.bgLight;
    final textPrimary = dark ? AppColors.textPrimaryDark  : AppColors.textPrimaryLight;
    final secondary   = dark ? AppColors.textSecondaryDark: AppColors.textSecondaryLight;
    final teal        = dark ? AppColors.accentTealDark   : AppColors.accentTealLight;
    final gold        = dark ? AppColors.accentGoldDark   : AppColors.accentGoldLight;
    final cardBg      = dark ? AppColors.cardBgDark       : AppColors.cardBgLight;
    final border      = dark ? AppColors.borderDark       : AppColors.borderLight;

    // completedTeal is a unique shade per the plan
    final completedTeal = dark ? const Color(0xFF2E7D60) : const Color(0xFF4DB6AC);
    final dotColor      = dark ? AppColors.textPrimaryDark : Colors.white;

    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          const IslamicPatternOverlay(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 8),
                    child: Column(
                      children: [
                        Text(
                          provider.t('Achievements', 'إنجازاتك'),
                          style: GoogleFonts.amiri(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: gold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!arabic)
                          Text(
                            'Spiritual Milestones',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Streak Card ─────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: _StreakCard(
                      provider: provider,
                      dark: dark,
                      arabic: arabic,
                      textPrimary: textPrimary,
                      secondary: secondary,
                      gold: gold,
                      cardBg: cardBg,
                      border: border,
                      completedTeal: completedTeal,
                      dotColor: dotColor,
                    ),
                  ),
                ),

                // ── Stats Row ──────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: _StatsRow(
                      provider: provider,
                      dark: dark,
                      textPrimary: textPrimary,
                      secondary: secondary,
                      teal: teal,
                      gold: gold,
                      cardBg: cardBg,
                      border: border,
                    ),
                  ),
                ),

                // ── Badges Section ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Text(
                      provider.t('BADGES', 'الأوسمة'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: teal,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),

                // Unlocked badges
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final badge = provider.unlockedBadges[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: _BadgeCard(
                          badge: badge,
                          arabic: arabic,
                          textPrimary: textPrimary,
                          secondary: secondary,
                          teal: teal,
                          gold: gold,
                          cardBg: cardBg,
                          border: border,
                          isLocked: false,
                        ),
                      );
                    },
                    childCount: provider.unlockedBadges.length,
                  ),
                ),

                // Locked divider
                if (provider.lockedBadges.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: border, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              provider.t(
                                'Locked (${provider.lockedBadges.length})',
                                'مقفل (${provider.lockedBadges.length})',
                              ),
                              style: TextStyle(fontSize: 12, color: secondary),
                            ),
                          ),
                          Expanded(child: Divider(color: border, thickness: 1)),
                        ],
                      ),
                    ),
                  ),

                // Locked badges (dimmed)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final badge = provider.lockedBadges[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: Opacity(
                          opacity: 0.45,
                          child: _BadgeCard(
                            badge: badge,
                            arabic: arabic,
                            textPrimary: textPrimary,
                            secondary: secondary,
                            teal: teal,
                            gold: gold,
                            cardBg: cardBg,
                            border: border,
                            isLocked: true,
                          ),
                        ),
                      );
                    },
                    childCount: provider.lockedBadges.length,
                  ),
                ),

                // ── Rewards Shop Teaser ────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: _RewardTeaser(
                      provider: provider,
                      arabic: arabic,
                      secondary: secondary,
                      gold: gold,
                      cardBg: cardBg,
                      border: border,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 112)),
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
// Streak Card
// ─────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final AppProvider provider;
  final bool dark, arabic;
  final Color textPrimary, secondary, gold, cardBg, border, completedTeal, dotColor;

  const _StreakCard({
    required this.provider,
    required this.dark,
    required this.arabic,
    required this.textPrimary,
    required this.secondary,
    required this.gold,
    required this.cardBg,
    required this.border,
    required this.completedTeal,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    final days    = provider.weeklyCompletion; // 7 booleans Mon–Sun
    final today   = DateTime.now().weekday - 1; // 0=Mon … 6=Sun
    final streak  = provider.streak;

    final dayLabelsEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final dayLabelsAr = ['إ', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.15 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.local_fire_department, color: gold, size: 22),
              const SizedBox(width: 8),
              Text(
                provider.t(
                  '$streak-day streak',
                  'سلسلة $streak يوم',
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 7-day tracker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isDone  = days[i] && i < today;
              final isToday = i == today;
              final isFuture = i > today;

              return _DayDot(
                label: arabic ? dayLabelsAr[i] : dayLabelsEn[i],
                isDone: isDone,
                isToday: isToday,
                isFuture: isFuture,
                secondary: secondary,
                completedTeal: completedTeal,
                gold: gold,
                border: border,
                dotColor: dotColor,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatefulWidget {
  final String label;
  final bool isDone, isToday, isFuture;
  final Color secondary, completedTeal, gold, border, dotColor;

  const _DayDot({
    required this.label,
    required this.isDone,
    required this.isToday,
    required this.isFuture,
    required this.secondary,
    required this.completedTeal,
    required this.gold,
    required this.border,
    required this.dotColor,
  });

  @override
  State<_DayDot> createState() => _DayDotState();
}

class _DayDotState extends State<_DayDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.isToday) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: widget.secondary,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 6),
        widget.isToday
            ? ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.gold, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.gold,
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDone ? widget.completedTeal : Colors.transparent,
                  border: widget.isFuture
                      ? Border.all(color: widget.border, width: 1.5)
                      : widget.isDone
                          ? null
                          : Border.all(color: widget.border, width: 1.5),
                ),
                child: widget.isDone
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.dotColor,
                          ),
                        ),
                      )
                    : null,
              ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final AppProvider provider;
  final bool dark;
  final Color textPrimary, secondary, teal, gold, cardBg, border;

  const _StatsRow({
    required this.provider,
    required this.dark,
    required this.textPrimary,
    required this.secondary,
    required this.teal,
    required this.gold,
    required this.cardBg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final pts      = provider.totalPoints;
    final sessions = provider.totalSessions;
    // We count the streak as "days active"
    final days     = provider.streak;

    final ptsStr      = _fmt(pts);
    final sessionStr  = sessions.toString();
    final daysStr     = days.toString();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(
            value: ptsStr,
            label: provider.t('PTS', 'نقاط'),
            color: gold,
            textPrimary: textPrimary,
            secondary: secondary,
          ),
          Container(width: 1, height: 32, color: border),
          _Stat(
            value: sessionStr,
            label: provider.t('Sessions', 'جلسات'),
            color: teal,
            textPrimary: textPrimary,
            secondary: secondary,
          ),
          Container(width: 1, height: 32, color: border),
          _Stat(
            value: daysStr,
            label: provider.t('Day Streak', 'أيام'),
            color: textPrimary,
            textPrimary: textPrimary,
            secondary: secondary,
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Color color, textPrimary, secondary;

  const _Stat({
    required this.value,
    required this.label,
    required this.color,
    required this.textPrimary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: secondary,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Badge Card
// ─────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final AzkarBadge badge;
  final bool arabic, isLocked;
  final Color textPrimary, secondary, teal, gold, cardBg, border;

  const _BadgeCard({
    required this.badge,
    required this.arabic,
    required this.isLocked,
    required this.textPrimary,
    required this.secondary,
    required this.teal,
    required this.gold,
    required this.cardBg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final accent = badge.color == 'gold' ? gold : teal;
    final bgTint = accent.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLocked ? border : accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgTint,
            ),
            child: Center(
              child: isLocked
                  ? Icon(Icons.lock_outline, size: 22, color: secondary)
                  : Text(badge.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabic ? badge.nameAr : badge.nameEn,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  arabic ? badge.descAr : badge.descEn,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Star icon (unlocked) or lock
          if (!isLocked)
            Icon(Icons.star_rounded, size: 20, color: gold.withOpacity(0.25)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Rewards Shop Teaser
// ─────────────────────────────────────────────
class _RewardTeaser extends StatelessWidget {
  final AppProvider provider;
  final bool arabic;
  final Color secondary, gold, cardBg, border;

  const _RewardTeaser({
    required this.provider,
    required this.arabic,
    required this.secondary,
    required this.gold,
    required this.cardBg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    final pts = provider.totalPoints;

    return GestureDetector(
      onTap: () {
        MainScreen.switchToTab(NavTab.rewards);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gold.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.t('Rewards Shop', 'متجر المكافآت'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.t(
                      'Spend your ${_fmt(pts)} PTS on themes & more',
                      'اصرف ${_fmt(pts)} نقطة على سمات وأكثر',
                    ),
                    style: TextStyle(fontSize: 13, color: secondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: gold.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
}
