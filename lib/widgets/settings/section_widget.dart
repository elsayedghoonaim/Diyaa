import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final String ar;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.ar,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark = provider.darkMode;
    final arabic = provider.arabicMode;

    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: arabic ? 0 : 4,
              right: arabic ? 4 : 0,
              bottom: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  arabic ? ar : title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: teal,
                  ),
                ),
                if (!arabic) ...[
                  const SizedBox(width: 8),
                  Text(
                    ar,
                    style: GoogleFonts.amiri(
                      fontSize: 13,
                      color: gold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
