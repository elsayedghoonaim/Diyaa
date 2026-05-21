import '../../domain/entities/zikr.dart';

/// Data model that extends [Zikr] with JSON parsing capability.
class ZikrModel extends Zikr {
  const ZikrModel({
    required super.arabic,
    super.transliteration,
    super.translation,
    super.source,
    super.sourceAr,
    required super.repeat,
    super.repeatAr,
    super.description,
  });

  /// Creates a [ZikrModel] from an adhkar_source.json entry.
  factory ZikrModel.fromSourceJson(Map<String, dynamic> json) {
    return ZikrModel(
      arabic: json['text'] as String? ?? '',
      repeat: (json['count'] as int?) ?? 1,
      description: json['description'] as String? ?? '',
    );
  }

  /// Creates a [ZikrModel] from an azkar.txt entry (structured daily sessions).
  factory ZikrModel.fromTxtJson(Map<String, dynamic> json) {
    int count = 1;
    if (json['count'] != null) {
      count = int.tryParse(json['count'].toString()) ?? 1;
    }
    String content = json['content'] as String? ?? '';
    content = content
        .replaceAll(r'\n', '')
        .replaceAll(r"', '", '')
        .replaceAll(r'"', '')
        .trim();
    return ZikrModel(
      arabic: content,
      repeat: count,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'arabic': arabic,
        'repeat': repeat,
        'description': description,
      };
}

/// Data model that extends [AzkarSession] with factory helpers.
class AzkarSessionModel extends AzkarSession {
  const AzkarSessionModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.zikrs,
  });

  /// Creates an [AzkarSessionModel] from an adhkar_source.json category object.
  factory AzkarSessionModel.fromSourceJson(Map<String, dynamic> json) {
    return AzkarSessionModel(
      id: (json['id'] as int).toString(),
      nameAr: json['category'] as String,
      nameEn: getEnglishName(json['category'] as String),
      zikrs: (json['array'] as List)
          .map((z) => ZikrModel.fromSourceJson(z as Map<String, dynamic>))
          .toList(),
    );
  }

  static String getEnglishName(String arName) {
    // Mirrors the map in zikr_screen.dart for consistency.
    const map = {
      'أذكار الصباح': 'Morning Azkar',
      'أذكار المساء': 'Evening Azkar',
      'أذكار النوم': 'Sleep Azkar',
      'أذكار الاستيقاظ': 'Waking Up Azkar',
      'أذكار بعد السلام من الصلاة المفروضة': 'Post-Prayer Azkar',
    };
    return map[arName] ?? 'Hisn al-Muslim';
  }
}
