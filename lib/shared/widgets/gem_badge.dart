import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/settings/presentation/manager/settings_cubit.dart';
import '../../features/settings/presentation/manager/settings_state.dart';
import '../../core/utils/arabic_utils.dart' as ar;
import '../../theme/app_colors.dart';

class GemBadge extends StatelessWidget {
  final int value;
  final bool isSmall;

  const GemBadge({
    super.key,
    required this.value,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final settings = settingsState is SettingsLoaded ? settingsState.settings : null;
    final dark = settings?.darkMode ?? false;
    final arabic = settings?.arabicMode ?? false;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    
    // Background tint is slightly darker in dark mode vs light mode to contrast the gem
    final bgTint = dark ? const Color(0xFF1E2530) : const Color(0xFFF9F5EE);

    final double px = isSmall ? 8 : 12;
    final double py = isSmall ? 3 : 5;
    final double iconSize = isSmall ? 11 : 14;
    final double fontSize = isSmall ? 11 : 13;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: px, vertical: py),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_outlined, color: AppColors.accentTealLight, size: iconSize),
          const SizedBox(width: 4),
          Text(
            ar.toArabicDigits(_fmt(value), isArabic: arabic),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: gold,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
}
