import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_cubit.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_state.dart';
import 'package:diyaa_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum NavTab { home, achievements, rewards, library, settings }

class DiyaaBottomNav extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab> onTap;

  const DiyaaBottomNav({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final dark = settingsState is SettingsLoaded
        ? settingsState.settings.darkMode
        : false;

    final navBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final navBorder = dark ? AppColors.borderDark : AppColors.borderLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final secondary = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final tabs = [
      _NavItem(tab: NavTab.home, icon: _homeIcon),
      _NavItem(tab: NavTab.achievements, icon: _awardIcon),
      _NavItem(tab: NavTab.library, icon: _bookIcon),
      _NavItem(tab: NavTab.rewards, icon: _gemIcon),
      _NavItem(tab: NavTab.settings, icon: _gearIcon),
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
                    Icon(item.icon, color: color, size: 26),
                    const SizedBox(height: 5),
                    Container(
                      width: 4,
                      height: 4,
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
  static const IconData _homeIcon = Icons.home_outlined;
  static const IconData _awardIcon = Icons.emoji_events_outlined;
  static const IconData _gemIcon = Icons.storefront_outlined;
  static const IconData _bookIcon = Icons.menu_book_outlined;
  static const IconData _gearIcon = Icons.settings_outlined;
}

class _NavItem {
  final NavTab tab;
  final IconData icon;
  const _NavItem({required this.tab, required this.icon});
}
