import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
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
    final provider = context.watch<AppProvider>();
    final dark = provider.darkMode;
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
        border: Border.all(color: gold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_outlined, color: AppColors.accentTealLight, size: iconSize),
          const SizedBox(width: 4),
          Text(
            provider.toArabicDigits(_fmt(value)),
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
