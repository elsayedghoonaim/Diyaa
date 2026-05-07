import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class CitySheet extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const CitySheet({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<CitySheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Map<String, String>> _cities = [
    {'name': 'Riyadh', 'ar': 'الرياض', 'country': 'Saudi Arabia', 'countryAr': 'المملكة العربية السعودية'},
    {'name': 'Cairo', 'ar': 'القاهرة', 'country': 'Egypt', 'countryAr': 'مصر'},
    {'name': 'Dubai', 'ar': 'دبي', 'country': 'UAE', 'countryAr': 'الإمارات'},
    {'name': 'Istanbul', 'ar': 'إسطنبول', 'country': 'Turkey', 'countryAr': 'تركيا'},
    {'name': 'London', 'ar': 'لندن', 'country': 'UK', 'countryAr': 'المملكة المتحدة'},
    {'name': 'Toronto', 'ar': 'تورونتو', 'country': 'Canada', 'countryAr': 'كندا'},
    {'name': 'New York', 'ar': 'نيويورك', 'country': 'USA', 'countryAr': 'الولايات المتحدة'},
    {'name': 'Sydney', 'ar': 'سيدني', 'country': 'Australia', 'countryAr': 'أستراليا'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark = provider.darkMode;
    final arabic = provider.arabicMode;

    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;

    final filtered = _cities.where((c) {
      final q = _searchQuery.toLowerCase();
      return c['name']!.toLowerCase().contains(q) ||
          c['ar']!.contains(q) ||
          c['country']!.toLowerCase().contains(q);
    }).toList();

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
                        arabic ? 'اختر مدينتك' : 'Select Your City',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: gold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        arabic ? 'لحساب مواقيت الصلاة بدقة' : 'For accurate prayer times',
                        style: TextStyle(fontSize: 11, color: textSecondary),
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

            // Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: arabic ? GoogleFonts.amiri(fontSize: 14, color: textPrimary) : TextStyle(fontSize: 14, color: textPrimary),
                  decoration: InputDecoration(
                    hintText: arabic ? 'ابحث عن مدينة...' : 'Search cities...',
                    hintStyle: TextStyle(color: textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final city = filtered[i];
                  final isSelected = widget.selected == city['name'];
                  
                  return GestureDetector(
                    onTap: () {
                      widget.onSelect(city['name']!);
                      Navigator.of(context).pop();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                arabic ? city['ar']! : city['name']!,
                                style: arabic 
                                    ? GoogleFonts.amiri(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)
                                    : TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                arabic ? city['countryAr']! : city['country']!,
                                style: arabic 
                                    ? GoogleFonts.amiri(fontSize: 12, color: textSecondary)
                                    : TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                          if (isSelected)
                            Container(
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
