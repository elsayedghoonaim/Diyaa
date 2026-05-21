import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/zikr.dart';
import '../models/zikr_model.dart';

/// Data source responsible for loading azkar from the bundled JSON assets.
/// Exposes two data sets:
///   - Daily sessions from `azkar.txt` (morning, evening, sleep, wakeup, post-prayer)
///   - Full library from `adhkar_source.json` (Hisn al-Muslim)
class AzkarLocalDataSource {
  const AzkarLocalDataSource();

  /// Session ID to Arabic category key mapping for azkar.txt.
  static const Map<String, String> _sessionToCategoryMap = {
    'morning':  'أذكار الصباح',
    '1':        'أذكار الصباح',
    'evening':  'أذكار المساء',
    'sleep':    'أذكار النوم',
    '2':        'أذكار النوم',
    'wakeup':   'أذكار الاستيقاظ',
    '3':        'أذكار الاستيقاظ',
    'cat_7':    'أذكار بعد السلام من الصلاة المفروضة',
    '27':       'أذكار بعد السلام من الصلاة المفروضة',
  };

  /// Returns ordered daily session list from `azkar.txt`.
  Future<List<AzkarSession>> loadDailySessions() async {
    final raw = await rootBundle.loadString('assets/azkar.txt');
    final data = json.decode(raw) as Map<String, dynamic>;

    const chronologicalKeys = [
      'أذكار الاستيقاظ',
      'أذكار الصباح',
      'أذكار بعد السلام من الصلاة المفروضة',
      'أذكار المساء',
      'أذكار النوم',
    ];

    const idMap = {
      'أذكار الاستيقاظ':                             'wakeup',
      'أذكار الصباح':                                 'morning',
      'أذكار بعد السلام من الصلاة المفروضة':        'cat_7',
      'أذكار المساء':                                'evening',
      'أذكار النوم':                                  'sleep',
    };

    final sessions = <AzkarSession>[];

    for (final key in chronologicalKeys) {
      if (!data.containsKey(key)) continue;
      final items = data[key] as List;
      final zikrs = <ZikrModel>[];

      for (final item in items) {
        if (item is List) {
          for (final sub in item) {
            zikrs.add(ZikrModel.fromTxtJson(sub as Map<String, dynamic>));
          }
        } else if (item is Map<String, dynamic> && item['category'] != 'stop') {
          zikrs.add(ZikrModel.fromTxtJson(item));
        }
      }

      if (zikrs.isNotEmpty) {
        sessions.add(AzkarSessionModel(
          id: idMap[key] ?? key,
          nameAr: key,
          nameEn: AzkarSessionModel.getEnglishName(key),
          zikrs: zikrs,
        ));
      }
    }

    return sessions;
  }

  /// Loads a single session from `azkar.txt` by session ID.
  /// Falls back to `adhkar_source.json` for library sessions (non-daily IDs).
  Future<AzkarSession?> loadSession(String sessionId) async {
    final categoryName = _sessionToCategoryMap[sessionId];

    if (categoryName != null) {
      final raw = await rootBundle.loadString('assets/azkar.txt');
      final data = json.decode(raw) as Map<String, dynamic>;

      if (data.containsKey(categoryName)) {
        final items = data[categoryName] as List;
        final zikrs = <ZikrModel>[];
        for (final item in items) {
          if (item is List) {
            for (final sub in item) {
              zikrs.add(ZikrModel.fromTxtJson(sub as Map<String, dynamic>));
            }
          } else if (item is Map<String, dynamic> && item['category'] != 'stop') {
            zikrs.add(ZikrModel.fromTxtJson(item));
          }
        }
        if (zikrs.isNotEmpty) {
          return AzkarSessionModel(
            id: sessionId,
            nameAr: categoryName,
            nameEn: AzkarSessionModel.getEnglishName(categoryName),
            zikrs: zikrs,
          );
        }
      }
    }

    // Fallback: adhkar_source.json (library sessions)
    return _loadFromSource(sessionId);
  }

  Future<List<AzkarSession>> loadLibrarySessions() async {
    final raw = await rootBundle.loadString('assets/adhkar_source.json');
    final data = json.decode(raw) as List<dynamic>;
    return data
        .map((e) => AzkarSessionModel.fromSourceJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AzkarSession?> _loadFromSource(String sessionId) async {
    final raw = await rootBundle.loadString('assets/adhkar_source.json');
    final data = json.decode(raw) as List<dynamic>;
    final sessions = data
        .map((e) => AzkarSessionModel.fromSourceJson(e as Map<String, dynamic>))
        .toList();
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (_) {
      return sessions.isNotEmpty ? sessions.first : null;
    }
  }
}
