import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../manager/settings_cubit.dart';
import '../manager/settings_state.dart';
import '../../data/models/settings_model.dart';
import '../../../../theme/app_colors.dart';

class PrayerMethodSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  static const List<Map<String, String>> _methods = [
    {'name': 'Muslim World League', 'ar': 'رابطة العالم الإسلامي', 'desc': 'Fajr 18°, Isha 17°'},
    {'name': 'Egyptian General Authority', 'ar': 'الهيئة المصرية العامة', 'desc': 'Fajr 19.5°, Isha 17.5°'},
    {'name': 'Umm Al-Qura University', 'ar': 'جامعة أم القرى', 'desc': 'Fajr 18.5°, Isha 90 min after Maghrib'},
    {'name': 'Kuwait Ministry of Awqaf', 'ar': 'وزارة الأوقاف الكويتية', 'desc': 'Fajr 18°, Isha 17.5°'},
    {'name': 'University of Islamic Sciences, Karachi', 'ar': 'جامعة العلوم الإسلامية، كراتشي', 'desc': 'Fajr 18°, Isha 18°'},
  ];

  const PrayerMethodSheet({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final settings = settingsState is SettingsLoaded ? settingsState.settings : const SettingsModel();
    final dark = settings.darkMode;
    final arabic = settings.arabicMode;

    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;

    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(color: Color(0x2E000000), blurRadius: 40, offset: Offset(0, -8)),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2))),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arabic ? 'طريقة الحساب' : 'Prayer Calculation Method',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: gold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        arabic ? 'لحساب مواقيت الصلاة' : 'How prayer times are calculated',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: cardBg, border: Border.all(color: border)),
                      child: Icon(Icons.close, size: 14, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: _methods.length,
                itemBuilder: (context, i) {
                  final method = _methods[i];
                  final isSelected = selected == method['name'];
                  
                  return GestureDetector(
                    onTap: () {
                      onSelect(method['name']!);
                      Navigator.of(context).pop();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (cardBg == const Color(0xFFFFFFFF) ? const Color(0x0F0B6E6E) : const Color(0x144DB6AC))
                            : cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? teal : border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  Text(
                                    arabic ? method['ar']! : method['name']!,
                                    style: arabic 
                                        ? GoogleFonts.amiri(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)
                                        : TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    method['desc']!,
                                    style: arabic 
                                        ? GoogleFonts.amiri(fontSize: 13.5, color: textSecondary, height: 1.5)
                                        : TextStyle(fontSize: 13.5, color: textSecondary, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                          if (isSelected)
                            Container(
                              margin: EdgeInsets.only(left: arabic ? 0 : 12, right: arabic ? 12 : 0),
                              width: 18, height: 18,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: teal),
                              child: const Icon(Icons.check, size: 12, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
