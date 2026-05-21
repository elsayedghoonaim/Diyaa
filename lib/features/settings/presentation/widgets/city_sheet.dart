import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../manager/settings_cubit.dart';
import '../manager/settings_state.dart';
import '../../data/models/settings_model.dart';
import '../../../../data/world_cities.dart';
import '../../../../theme/app_colors.dart';

class CitySheet extends StatefulWidget {
  const CitySheet({super.key});

  @override
  State<CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<CitySheet> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final settings = settingsState is SettingsLoaded ? settingsState.settings : const SettingsModel();
    final dark = settings.darkMode;
    final arabic = settings.arabicMode;

    final bg          = dark ? AppColors.bgDark          : AppColors.bgLight;
    final cardBg      = dark ? AppColors.cardBgDark      : AppColors.cardBgLight;
    final border      = dark ? AppColors.borderDark      : AppColors.borderLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSec     = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teal        = dark ? AppColors.accentTealDark  : AppColors.accentTealLight;
    final gold        = dark ? AppColors.accentGoldDark  : AppColors.accentGoldLight;

    final q = _query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? kWorldCities
        : kWorldCities.where((c) =>
            c.nameEn.toLowerCase().contains(q) ||
            c.nameAr.contains(q) ||
            c.countryEn.toLowerCase().contains(q) ||
            c.countryAr.contains(q)).toList();

    final selectedName = settings.manualCityName;

    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 40, offset: Offset(0, -8))],
        ),
        child: Column(
          children: [
            // ── Drag handle ──
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2))),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arabic ? 'اختر مدينتك' : 'Select Your City',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: gold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        arabic ? 'لحساب مواقيت الصلاة بدقة' : 'Prayer times auto-calculated by location',
                        style: TextStyle(fontSize: 13, color: textSec),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: cardBg, border: Border.all(color: border)),
                      child: Icon(Icons.close, size: 14, color: textSec),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search, size: 18, color: textSec),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: arabic ? 'ابحث عن مدينة...' : 'Search cities...',
                          hintStyle: TextStyle(color: textSec, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () { _ctrl.clear(); setState(() => _query = ''); },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.close, size: 16, color: textSec),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: border),

            // ── City list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 40, color: textSec.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            arabic ? 'لا توجد نتائج' : 'No cities found',
                            style: TextStyle(color: textSec, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final city = filtered[i];
                        final isSelected = selectedName == city.nameEn ||
                            selectedName == city.nameAr;

                        return GestureDetector(
                          onTap: () async {
                            Navigator.of(context).pop();
                            await context.read<SettingsCubit>().setManualCity(
                              cityName: arabic ? city.nameAr : city.nameEn,
                              lat: city.lat,
                              lng: city.lng,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? teal.withValues(alpha: dark ? 0.15 : 0.08)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? teal : border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Flag emoji via country code approximation — simple icon instead
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? teal.withValues(alpha: 0.15)
                                        : (dark ? const Color(0xFF1E2530) : const Color(0xFFF0EDE6)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_city,
                                    size: 18,
                                    color: isSelected ? teal : textSec,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        arabic ? city.nameAr : city.nameEn,
                                        style: arabic
                                            ? GoogleFonts.amiri(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected ? teal : textPrimary,
                                              )
                                            : TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected ? teal : textPrimary,
                                              ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        arabic ? city.countryAr : city.countryEn,
                                        style: TextStyle(fontSize: 13, color: textSec),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: teal),
                                    child: const Icon(Icons.check, size: 13, color: Colors.white),
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
