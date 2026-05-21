import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diyaa_app/core/utils/arabic_utils.dart' as ar;
import 'package:diyaa_app/features/settings/presentation/manager/settings_cubit.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_state.dart';
import 'package:diyaa_app/theme/app_colors.dart';
import 'package:diyaa_app/shared/widgets/islamic_pattern.dart';
import 'package:diyaa_app/features/azkar/presentation/screens/zikr_screen.dart';

// ─────────────────────────────────────────────
// Models for adhkar_source.json
// ─────────────────────────────────────────────
class LibraryCategory {
  final int id;
  final String category;
  final List<LibraryZikr> zikrs;

  LibraryCategory({required this.id, required this.category, required this.zikrs});

  factory LibraryCategory.fromJson(Map<String, dynamic> j) => LibraryCategory(
    id: j['id'] as int,
    category: j['category'] as String,
    zikrs: (j['array'] as List).map((e) => LibraryZikr.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class LibraryZikr {
  final int id;
  final String text;
  final int count;

  LibraryZikr({required this.id, required this.text, required this.count});

  factory LibraryZikr.fromJson(Map<String, dynamic> j) => LibraryZikr(
    id: j['id'] as int,
    text: j['text'] as String,
    count: j['count'] as int,
  );
}

// ─────────────────────────────────────────────
// LibraryScreen
// ─────────────────────────────────────────────
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<LibraryCategory> _allCategories = [];
  List<LibraryCategory> _filteredCategories = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final raw = await rootBundle.loadString('assets/adhkar_source.json');
      final List<dynamic> data = json.decode(raw);
      final list = data.map((e) => LibraryCategory.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _allCategories = list;
          _filteredCategories = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredCategories = _allCategories);
      return;
    }

    setState(() {
      _filteredCategories = _allCategories.where((cat) {
        final catMatch = cat.category.toLowerCase().contains(query);
        final zikrMatch = cat.zikrs.any((z) => z.text.toLowerCase().contains(query));
        return catMatch || zikrMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final dark   = settingsState is SettingsLoaded ? settingsState.settings.darkMode : false;
    final arabic = settingsState is SettingsLoaded ? settingsState.settings.arabicMode : false;

    final bg          = dark ? AppColors.bgDark      : AppColors.bgLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final gold        = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final cardBg      = dark ? AppColors.cardBgDark   : AppColors.cardBgLight;
    final border      = dark ? AppColors.borderDark    : AppColors.borderLight;

    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          const IslamicPatternOverlay(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 52, 24, 12),
                  child: Column(
                    children: [
                      Text(
                        'حصن المسلم',
                        style: GoogleFonts.amiri(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: gold,
                        ),
                      ),
                      if (!arabic)
                        Text(
                          'Hisn al-Muslim',
                          style: TextStyle(
                            fontSize: 11,
                            color: textPrimary.withValues(alpha: 0.5),
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: dark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      textAlign: arabic ? TextAlign.right : TextAlign.left,
                      decoration: InputDecoration(
                        hintText: ar.localise('Search Azkar...', 'بحث...', isArabic: arabic),
                        hintStyle: TextStyle(color: textPrimary.withValues(alpha: 0.3)),
                        prefixIcon: Icon(Icons.search, color: gold, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredCategories.isEmpty
                          ? Center(
                              child: Text(
                                ar.localise('No results found', 'لا توجد نتائج', isArabic: arabic),
                                style: TextStyle(
                                  color: textPrimary.withValues(alpha: 0.5),
                                  fontSize: 15,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final cat = _filteredCategories[index];
                                return _CategoryTile(
                                  category: cat,
                                  dark: dark,
                                  arabic: arabic,
                                  textPrimary: textPrimary,
                                  gold: gold,
                                  cardBg: cardBg,
                                  border: border,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final LibraryCategory category;
  final bool dark, arabic;
  final Color textPrimary, gold, cardBg, border;

  const _CategoryTile({
    required this.category,
    required this.dark,
    required this.arabic,
    required this.textPrimary,
    required this.gold,
    required this.cardBg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ZikrScreen(sessionId: category.id.toString()),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.category,
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ar.toArabicDigits(category.zikrs.length.toString(), isArabic: arabic)} ${ar.localise('items', 'أذكار', isArabic: arabic)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: textPrimary.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  arabic ? Icons.chevron_left : Icons.chevron_right,
                  color: gold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
