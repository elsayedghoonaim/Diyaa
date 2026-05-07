import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diyaa/providers/app_provider.dart';
import 'package:diyaa/theme/app_colors.dart';

enum NavTab { home, achievements, rewards, library, settings }

class DiyaaBottomNav extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab> onTap;

  const DiyaaBottomNav({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark = provider.darkMode;

    final navBg     = dark ? AppColors.cardBgDark   : AppColors.cardBgLight;
    final navBorder = dark ? AppColors.borderDark    : AppColors.borderLight;
    final teal      = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold      = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final secondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final tabs = [
      _NavItem(tab: NavTab.home,          icon: _homeIcon),
      _NavItem(tab: NavTab.achievements,  icon: _awardIcon),
      _NavItem(tab: NavTab.library,       icon: _bookIcon),
      _NavItem(tab: NavTab.rewards,       icon: _gemIcon),
      _NavItem(tab: NavTab.settings,      icon: _gearIcon),
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: navBorder, width: 1)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tabs.map((item) {
            final isActive = item.tab == active;
            final color = isActive ? teal : secondary;
            return GestureDetector(
              onTap: () => onTap(item.tab),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 52,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    item.tab == NavTab.settings
                        ? _GearSvg(color: color, size: 26)
                        : Icon(item.icon, color: color, size: 26),
                    const SizedBox(height: 5),
                    Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? gold : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Icons
  static const IconData _homeIcon          = Icons.home_outlined;
  static const IconData _awardIcon         = Icons.emoji_events_outlined;
  static const IconData _gemIcon           = Icons.storefront_outlined;
  static const IconData _bookIcon          = Icons.menu_book_outlined;
  static const IconData _gearIcon          = Icons.settings_outlined;
}

class _NavItem {
  final NavTab tab;
  final IconData icon;
  const _NavItem({required this.tab, required this.icon});
}

/// Custom gear SVG to match the design's exact gear icon
class _GearSvg extends StatelessWidget {
  final Color color;
  final double size;
  const _GearSvg({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GearPainter(color: color),
    );
  }
}

class _GearPainter extends CustomPainter {
  final Color color;
  _GearPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.width / 24;

    // Center circle r=3
    canvas.drawCircle(Offset(12 * s, 12 * s), 3 * s, paint);

    // 8 spokes from the design path
    final paths = [
      [19.07, 4.93, 17.66, 6.34],
      [4.93,  4.93, 6.34,  6.34],
      [4.93,  19.07, 6.34, 17.66],
      [19.07, 19.07, 17.66, 17.66],
      [12.0,  2.0,  12.0,  4.0],
      [12.0,  20.0, 12.0,  22.0],
      [2.0,   12.0, 4.0,   12.0],
      [20.0,  12.0, 22.0,  12.0],
    ];
    for (final p in paths) {
      canvas.drawLine(
        Offset(p[0] * s, p[1] * s),
        Offset(p[2] * s, p[3] * s),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GearPainter old) => old.color != color;
}
