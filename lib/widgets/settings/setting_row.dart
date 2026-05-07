import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class SettingRow extends StatelessWidget {
  final dynamic icon; // Can be IconData or Widget (SVG)
  final Color iconColor;
  final String iconBgMode; // 'teal', 'gold', 'default', 'teal_active'
  final String label;
  final String arLabel;
  final String? sublabel;
  final Widget rightWidget;
  final bool isLast;
  final VoidCallback? onTap;
  final bool isTapped;

  const SettingRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgMode,
    required this.label,
    required this.arLabel,
    this.sublabel,
    required this.rightWidget,
    this.isLast = false,
    this.onTap,
    this.isTapped = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark = provider.darkMode;
    final arabic = provider.arabicMode;

    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    
    // Background colors based on mode
    Color iconBg;
    if (iconBgMode == 'teal') {
      iconBg = dark ? const Color(0x1A4DB6AC) : const Color(0x120B6E6E);
    } else if (iconBgMode == 'teal_active') {
      iconBg = dark ? const Color(0x264DB6AC) : const Color(0x1A0B6E6E);
    } else if (iconBgMode == 'gold') {
      iconBg = dark ? const Color(0x1FD4A84B) : const Color(0x14B8973A);
    } else {
      iconBg = Colors.transparent;
    }

    Color highlightBg = Colors.transparent;
    if (isTapped) {
      highlightBg = cardBg == const Color(0xFFFFFFFF) 
          ? const Color(0x0A0B6E6E) 
          : const Color(0x0F4DB6AC);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: highlightBg,
            border: Border(
              bottom: isLast ? BorderSide.none : BorderSide(color: border),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: icon is IconData 
                      ? Icon(icon, size: 17, color: iconColor)
                      : icon,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      arabic ? arLabel : label,
                      style: arabic 
                          ? GoogleFonts.amiri(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.2)
                          : TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
                    ),
                    if (sublabel != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        sublabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isTapped)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: arabic 
                        ? (dark ? const Color(0x1FD4A84B) : const Color(0x1FB8973A))
                        : (dark ? const Color(0x144DB6AC) : const Color(0x140B6E6E)),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    arabic ? 'قريباً' : 'Coming soon',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: arabic 
                          ? (dark ? AppColors.accentGoldDark : AppColors.accentGoldLight)
                          : (dark ? AppColors.accentTealDark : AppColors.accentTealLight),
                    ),
                  ),
                ),
              rightWidget,
            ],
          ),
        ),
      ),
    );
  }
}
